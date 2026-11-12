# Recipe: screens from Google Flow

## Accounts
Image generation is free but rate-capped per account, so work is spread across five. Each has its own Flow project.

| Suffix | Account |
| --- | --- |
| hsd | headsmartdesign@gmail.com |
| m35 | mike.lewis35@gmail.com |
| wgv6 | wegotvegan6@gmail.com |
| wgv7 | wegotvegan7@gmail.com |
| wgv8 | wegotvegan8@gmail.com |

Before generating, confirm the active account by clicking the username at the top right of Flow. Never trust the user number in the URL. If you can't confirm it, stop and ask Mike.

## A still screen
1. Generate the painting at 16:9 from the style block, with no characters in it. Ask for "a raised three-quarter view".
2. Check the camera steepness against the screens already accepted. Pip's sprites are rendered from one angle, so screens must roughly agree.
3. Mike picks. Download at 1K (original size); 2K is an upscale.
4. Cut out anything that should pass in front of a character as a foreground layer.
5. Mark where characters can walk and where the exits are. How depends on the engine; that step is written after the first-screen milestone.

## An animated screen
Untested. Written during the screen pipeline milestone. Flow's video models change often, so check the model picker rather than trusting a name written here.

## Gotchas
- Flow paints every scene in its own perspective. Asking for a flat top-down view doesn't work; judge steepness across screens instead.
- Don't use Pip's sheet as a style reference: it makes every character look like Pip, and childish. Describe the rendering style in words and ask for grounded proportions.
- Agents can't upload files into Flow (the Chrome file upload fails). Mike drags references in by hand. Don't retry in a loop.
- References and prompt text clear after every submit, so re-attach each run. Check the mode chip says Image before submitting.
- The grid reshuffles. Identify images by title, never by position. Titles are editable and a good place for scores.
- Downloads are JPEG named after the image title.
- Images kept in Drive can't be seen by the planning room. Attach them in the chat.
