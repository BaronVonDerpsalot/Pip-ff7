class_name Cutout
extends RefCounted
## Cuts a foreground layer out of an ink-and-watercolour painting.
## Finds the ink lines inside a region, closes small gaps, fills enclosed shapes
## (leaves, reed heads), and keeps the painting's own colours, so the cut-out is
## invisible except where it covers a character.
##
## Run from execute_script or a tool script. Not used by the game at runtime.

## Options (all optional):
##   ink_drop: how much darker than its surroundings a pixel must be to count as ink (default 0.06)
##   ink_max: pixels lighter than this are never ink (default 0.5)
##   close_radius: gap size in pixels to bridge before filling shapes (default 2)
##   max_hole: largest enclosed area in pixels that gets filled (default 2500)
##   keep: "all", "tall" (drop flat marks like ground lines), or "top" (only shapes hanging from the region's top edge)
##   min_size: drop shapes smaller than this many pixels (default 40)
##   source_alpha: an Image whose alpha is used as the starting mask instead of ink detection
##   source_offset: where source_alpha's top-left sits on the painting (Vector2i)
##
## Returns {"image": Image (RGBA, cropped), "rect": Rect2i on the painting}.
static func cut(painting: Image, region: PackedVector2Array, opts := {}) -> Dictionary:
	var bounds := _bounds(region, painting.get_size())
	var w := bounds.size.x
	var h := bounds.size.y
	var close_r: int = opts.get("close_radius", 2)

	# 1. Starting mask: ink lines (or a supplied alpha) inside the region.
	var inside := PackedByteArray()
	inside.resize(w * h)
	for y in h:
		for x in w:
			var p := Vector2(bounds.position.x + x + 0.5, bounds.position.y + y + 0.5)
			inside[y * w + x] = 1 if Geometry2D.is_point_in_polygon(p, region) else 0

	var mask := PackedByteArray()
	mask.resize(w * h)
	if opts.has("source_alpha"):
		var src: Image = opts["source_alpha"]
		var off: Vector2i = opts.get("source_offset", Vector2i.ZERO)
		for y in h:
			for x in w:
				var sx := bounds.position.x + x - off.x
				var sy := bounds.position.y + y - off.y
				if inside[y * w + x] == 1 and sx >= 0 and sy >= 0 and sx < src.get_width() and sy < src.get_height():
					mask[y * w + x] = 1 if src.get_pixel(sx, sy).a > 0.5 else 0
	else:
		var lum := PackedFloat32Array()
		lum.resize(w * h)
		for y in h:
			for x in w:
				lum[y * w + x] = painting.get_pixel(bounds.position.x + x, bounds.position.y + y).get_luminance()
		var local := _box_blur(lum, w, h, 7)
		var drop: float = opts.get("ink_drop", 0.06)
		var ink_max: float = opts.get("ink_max", 0.5)
		for i in w * h:
			if inside[i] == 1 and lum[i] < ink_max and lum[i] < local[i] - drop:
				mask[i] = 1

	# 2. Close small gaps, fill enclosed shapes, then shrink back (a morphological close plus hole fill).
	var grown := _dilate(mask, w, h, close_r)
	var filled := _fill_holes(grown, w, h, opts.get("max_hole", 2500))
	var shape := _erode(filled, w, h, close_r)
	for i in w * h:
		shape[i] = 1 if (shape[i] == 1 or mask[i] == 1) and inside[i] == 1 else 0

	# 3. Keep only the shapes that belong in front.
	shape = _filter_shapes(shape, w, h, opts.get("keep", "all"), opts.get("min_size", 40))

	# 4. Soft one-pixel edge, colours from the painting, cropped to what's left.
	var soft := PackedFloat32Array()
	soft.resize(w * h)
	for i in w * h:
		soft[i] = shape[i]
	soft = _box_blur(soft, w, h, 1)
	var used := Rect2i()
	var first := true
	for y in h:
		for x in w:
			if shape[y * w + x] == 1:
				var r := Rect2i(x, y, 1, 1)
				used = r if first else used.merge(r)
				first = false
	if first:
		return {"image": null, "rect": Rect2i()}
	used = used.grow(2).intersection(Rect2i(0, 0, w, h))
	var out := Image.create(used.size.x, used.size.y, false, Image.FORMAT_RGBA8)
	for y in used.size.y:
		for x in used.size.x:
			var lx := used.position.x + x
			var ly := used.position.y + y
			var a := clampf(maxf(soft[ly * w + lx] * 1.5, float(shape[ly * w + lx])), 0.0, 1.0)
			var c := painting.get_pixel(bounds.position.x + lx, bounds.position.y + ly)
			c.a = a
			out.set_pixel(x, y, c)
	return {"image": out, "rect": Rect2i(bounds.position + used.position, used.size)}


static func _bounds(region: PackedVector2Array, size: Vector2i) -> Rect2i:
	var r := Rect2(region[0], Vector2.ZERO)
	for p in region:
		r = r.expand(p)
	return Rect2i(r.position.floor(), r.size.ceil() + Vector2.ONE).intersection(Rect2i(Vector2i.ZERO, size))


static func _box_blur(src: PackedFloat32Array, w: int, h: int, r: int) -> PackedFloat32Array:
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			var s := 0.0
			var n := 0
			for k in range(maxi(0, x - r), mini(w, x + r + 1)):
				s += src[y * w + k]
				n += 1
			tmp[y * w + x] = s / n
	for y in h:
		for x in w:
			var s := 0.0
			var n := 0
			for k in range(maxi(0, y - r), mini(h, y + r + 1)):
				s += tmp[k * w + x]
				n += 1
			out[y * w + x] = s / n
	return out


static func _dilate(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	return _morph(m, w, h, r, true)


static func _erode(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	return _morph(m, w, h, r, false)


static func _morph(m: PackedByteArray, w: int, h: int, r: int, grow: bool) -> PackedByteArray:
	if r <= 0:
		return m.duplicate()
	var want := 1 if grow else 0
	var tmp := PackedByteArray()
	tmp.resize(w * h)
	var out := PackedByteArray()
	out.resize(w * h)
	for y in h:
		for x in w:
			var v := 1 - want
			for k in range(maxi(0, x - r), mini(w, x + r + 1)):
				if m[y * w + k] == want:
					v = want
					break
			tmp[y * w + x] = v
	for y in h:
		for x in w:
			var v := 1 - want
			for k in range(maxi(0, y - r), mini(h, y + r + 1)):
				if tmp[k * w + x] == want:
					v = want
					break
			out[y * w + x] = v
	return out


## Fills background pockets that are fully enclosed and no bigger than max_hole.
static func _fill_holes(m: PackedByteArray, w: int, h: int, max_hole: int) -> PackedByteArray:
	var out := m.duplicate()
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in w * h:
		if m[start] == 1 or seen[start] == 1:
			continue
		var pocket := PackedInt32Array([start])
		seen[start] = 1
		var touches_edge := false
		var i := 0
		while i < pocket.size():
			var p := pocket[i]
			i += 1
			var x := p % w
			var y := p / w
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				touches_edge = true
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var q := ny * w + nx
				if m[q] == 0 and seen[q] == 0:
					seen[q] = 1
					pocket.append(q)
		if not touches_edge and pocket.size() <= max_hole:
			for p in pocket:
				out[p] = 1
	return out


static func _filter_shapes(m: PackedByteArray, w: int, h: int, keep: String, min_size: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(w * h)
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in w * h:
		if m[start] == 0 or seen[start] == 1:
			continue
		var shape := PackedInt32Array([start])
		seen[start] = 1
		var minx := w
		var maxx := 0
		var miny := h
		var maxy := 0
		var i := 0
		while i < shape.size():
			var p := shape[i]
			i += 1
			var x := p % w
			var y := p / w
			minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var q := ny * w + nx
					if m[q] == 1 and seen[q] == 0:
						seen[q] = 1
						shape.append(q)
		var ok := shape.size() >= min_size
		if keep == "tall":
			ok = ok and (maxy - miny) >= 20 and (maxy - miny) >= (maxx - minx) * 0.6
		elif keep == "top":
			ok = ok and miny <= 12
		if ok:
			for p in shape:
				out[p] = 1
	return out
