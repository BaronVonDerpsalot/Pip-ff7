'use strict';
// Pip FF7 -- "Send layers" (Affinity script; library title "Pip FF7 - Send layers v2").
// Run from Affinity's Scripts panel with a screen document open (marsh.afdesign, boardwalk.afdesign, ...).
// It writes every visible layer above the painting, cropped to its content, next to the document:
//   <screen>__layer<N>.rgba   raw RGBA8 pixels (cropped)
//   <screen>__manifest.json   what each layer is and where it sits
//   <screen>__READY           touched last; the agent's watcher fires on this
// No naming rules: the bottom layer is the painting, and every visible layer above it is an overlay
// that the game draws in front of Pip, whatever it's called (even "Background").
// Hidden layers are skipped. See docs/recipes/screens-layering.md.

const { Application } = require('/application.js');
const { Document } = require('/document.js');
const { File } = require('/fs.js');

function sendToGame(doc) {
    const say = (msg) => Application.alert(msg, 'Send layers');
    if (!doc) { say('Open a screen document first.'); return; }
    let path = '';
    try { path = String(doc.path || ''); } catch (e) {}
    if (!path) { say('Save this document first (marsh.afdesign, boardwalk.afdesign or stream.afdesign), in the PipFF7_layering folder.'); return; }
    path = path.replace(/\\/g, '/');
    const dir = path.substring(0, path.lastIndexOf('/'));
    const screen = path.substring(path.lastIndexOf('/') + 1).replace(/\.[^.]*$/, '');

    const kids = Array.from(doc.currentSpread.children);   // direct children only (.all would also list nested nodes)
    // No layers above the painting is a valid answer: "I looked, this screen needs none". It is sent as an empty set
    // and the screen is marked as layered.
    const layers = [], skipped = [];
    for (let i = 1; i < kids.length; i++) {                // kids[0] is the painting
        const k = kids[i];
        const raw = String(k.userDescription || '');
        if (k.isVisible === false) { skipped.push((raw || 'layer ' + i) + ' (hidden)'); continue; }
        if (typeof k.createCompatibleBuffer !== 'function') { skipped.push(raw + ' (not a pixel layer: rasterise it first)'); continue; }
        const buf = k.createCompatibleBuffer(true);
        const arr = new Uint8Array(buf.buffer);
        const bw = buf.width, bh = buf.height;
        // The buffer is laid out in canvas coordinates (checked: its content box matches rasterBoundingBox), so no offset is added.
        let x0 = bw, y0 = bh, x1 = -1, y1 = -1;
        for (let y = 0; y < bh; y++) {
            const row = y * bw * 4;
            for (let x = 0; x < bw; x++) if (arr[row + x * 4 + 3] > 0) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
        }
        if (x1 < 0) { skipped.push(raw + ' (empty)'); continue; }
        const w = x1 - x0 + 1, h = y1 - y0 + 1, out = new Uint8Array(w * h * 4);
        for (let y = 0; y < h; y++) out.set(arr.subarray(((y0 + y) * bw + x0) * 4, ((y0 + y) * bw + x0 + w) * 4), y * w * 4);
        const name = 'layer' + i;                              // by position, so it's stable between sends
        const file = screen + '__layer' + layers.length + '.rgba';
        const f = File.create(dir + '/' + file, 'wb'); f.write(out.buffer, out.length); f.close();
        layers.push({ name: name, role: 'OVERHEAD', file: file, x: x0, y: y0, w: w, h: h, buf_w: bw, buf_h: bh, base: null, source: raw });
    }
    // Layers exist but none could be sent (all hidden, empty or not pixel layers): that's probably a mistake, so don't mark the screen.
    if (kids.length > 1 && layers.length === 0) { say('No layers could be sent, so the screen was not marked.\nSkipped: ' + skipped.join('; ')); return; }
    const manifest = { screen: screen, doc_w: Math.round(doc.widthPixels), doc_h: Math.round(doc.heightPixels), layers: layers, skipped: skipped };
    const mf = File.create(dir + '/' + screen + '__manifest.json', 'wb'); mf.writeString(JSON.stringify(manifest, null, 1)); mf.close();
    const rf = File.create(dir + '/' + screen + '__READY', 'wb'); rf.writeString(String(Date.now())); rf.close();   // last, so the watcher sees a complete set
    say(layers.length === 0 ? screen + ' marked as needing no overlays.' : 'Sent ' + layers.length + ' layer(s) for ' + screen + ' to the game.' + (skipped.length ? '\nSkipped: ' + skipped.join('; ') : ''));
}

sendToGame(Document.current);
