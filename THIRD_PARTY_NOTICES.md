# Third-party notices

hypr-hands is MIT © 2026 PWN. It is an independent project, not affiliated with or endorsed by Basecamp/Omarchy, Cua AI, the Hyprland project, or any tool listed below.

## Omarchy (https://github.com/basecamp/omarchy) — MIT

`skills/omarchy/` is copied and adapted from the agent skill bundled with Omarchy
(`default/agents/skills/omarchy`). `capture.md`, `contributing.md`, `hooks.md` and
`theming.md` are verbatim; `SKILL.md`, `hyprland.md` and `plugins.md` are modified
(remote-use notes, Lua dispatch notes, shortened trigger text). These files keep
Omarchy's license, also in `skills/omarchy/LICENSE`:

```
Copyright (c) David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## Referenced, not bundled

| Project | License | How it is used |
|---|---|---|
| [Cua Driver](https://github.com/trycua/cua) (Cua AI, Inc.) | MIT | Optional; `install.sh` runs Cua's official installer (`https://cua.ai/driver/install.sh`). No Cua code or docs are included; `skills/cua-driver-local-computer-use` is our own text that points to Cua's upstream skill pack. |
| [Hyprland](https://github.com/hyprwm/Hyprland) | BSD-3-Clause | Compositor; called via `hyprctl`. |
| [wlrctl](https://git.sr.ht/~brocellous/wlrctl) | MIT | System package. |
| [wtype](https://github.com/atx/wtype) | MIT | System package. |
| [grim](https://git.sr.ht/~emersion/grim) | MIT | System package. |
| [tesseract](https://github.com/tesseract-ocr/tesseract) | Apache-2.0 | System package. |
| [ydotool](https://github.com/ReimuNotMoe/ydotool) | AGPL-3.0 | Optional system package (opt-in), invoked as a separate program. |
