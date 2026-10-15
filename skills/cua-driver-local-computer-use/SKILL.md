---
name: cua-driver-local-computer-use
description: >-
  Use when driving a real GUI on the user's own computer (especially
  Omarchy/Hyprland Linux) via the cua-driver CLI over Shell with their
  machineId - computer-use tasks, native apps, window automation - instead of
  the box desktop.
---
# Cua Driver local computer use

Drive real GUI apps on the **user's registered computer** with the `cua-driver` CLI. Prefer this over the box `computerUse` subagent whenever the task is on their desktop (Omarchy, Hyprland, local apps, signed-in sessions).

Upstream pack (read on demand from the machine being driven):
`~/.cua-driver/skills/cua-driver/` — start with `SKILL.md`, then `WORKFLOW.md`, `RUNTIME.md`, and the host guide (`LINUX.md` on Linux).

## When to use

- Operate, click, type, or verify UI in a native app on the user's machine
- Continue / resume a Cua-driven GUI task
- Local computer-use where the box browser/desktop is the wrong surface

Do **not** use for pure filesystem/CLI outcomes the agent can do with Shell/Read without a GUI. Do not install, upgrade, change permission modes, or reconfigure the daemon unless the user asked.

## Machine and transport

1. Resolve the target with `ListMachines`. Prefer the machine the message came from, or the one the user named (e.g. their Omarchy computer).
2. Run every `cua-driver` command with Shell **`machineId` set to that computer**. Never run host GUI control on the box unless the user explicitly wants the box desktop driven.
3. Ensure `PATH` includes `~/.local/bin`. On Wayland/Hyprland/Omarchy, the daemon should already run with `CUA_DRIVER_RS_ENABLE_WAYLAND=1` (systemd user unit `cua-driver.service` if configured).
4. Preflight once per session of work:

```bash
cua-driver --version
cua-driver status
cua-driver doctor
```

If the daemon is down: `systemctl --user start cua-driver.service` (or `cua-driver serve --socket ~/.cache/cua-driver/cua-driver.sock` with Wayland enabled). Do not `cua-driver stop` a shared service when finishing a task — use `end_session` for the run label only.

Grok Bot does not use stdio MCP for Cua. Use the CLI: `cua-driver call <tool> '<json>'` (or the short form `cua-driver <tool> '<json>'` when advertised).

## Observe → act → verify

Pass the same nonempty session label (not `default`) on every call that accepts `session` in a multi-step run.

1. **Find the window** — `list_apps` / `list_windows`. Pick the intended window by title/app; never blindly take the first. Launch with `launch_app` only when needed; retry window discovery, not repeated launches.
2. **Observe** — `get_window_state` with exact `pid` + `window_id`. Prefer `element_token` from this response. Check whether a screenshot actually returned; tree-only is fine for semantic actions, not for pixel clicks.
3. **Act once** — Prefer accessibility: `click` / `type_text` / `set_value` with a **fresh** `element_token` and exact `target: {kind:"window", pid, window_id}`. Default `delivery_mode` is background. Do not invent tokens or reuse stale ones after any new snapshot.
4. **Verify** — Fresh `get_window_state` or `verify_state` against the user's postcondition. A successful tool exit or `effect:"unverifiable"` is not task success. Stop when the postcondition is proven.

Example shape (replace IDs/tokens from live output):

```bash
cua-driver call list_windows '{}'
cua-driver call get_window_state '{"pid":123,"window_id":456,"session":"run-1"}'
cua-driver call click '{"target":{"kind":"window","pid":123,"window_id":456},"element_token":"…","session":"run-1"}'
cua-driver call get_window_state '{"pid":123,"window_id":456,"session":"run-1"}'
cua-driver call end_session '{"session":"run-1"}'
```

## Linux / Hyprland / Omarchy limits

- Native Wayland needs `CUA_DRIVER_RS_ENABLE_WAYLAND=1` for reliable window discovery.
- Hyprland/Omarchy: discovery works; **background raw input is experimental**. Prefer AT-SPI / `element_token` actions. On `background_unavailable`, reobserve and **ask** before `delivery_mode:"foreground"` or desktop-scope input — never escalate silently.
- `surface_identity_unproven` on screenshots: do not invent pixels from a desktop crop. Use semantic tree actions, or ask before authorized `get_desktop_state` + desktop `target`.
- Portal/OS permission dialogs belong to the user. Never automate approval or weaken security settings.

## Hard rules

1. Exact target every action; sessions are lifecycle labels, not permission grants.
2. Fresh state before and after input; never replay partial/canceled/unknown actions blindly.
3. Use returned tokens only; a new snapshot invalidates prior handles.
4. Keep one controller on the shared desktop; do not fight the user's focus.
5. Ask before: sending/publishing, purchases, deletes, permission changes, production systems, foreground takeover, or full-desktop input.
6. Report driver refusals honestly; do not bypass via xdotool, fake clicks, or unrelated tools.
7. For deeper schemas and recovery, Read the matching file under `~/.cua-driver/skills/cua-driver/` on the target machine (use Read/`machineId`, or CopyToBox then Read).

## Pointer/keyboard fallback: hypr-hands (Hyprland/Omarchy)

When AT-SPI tokens are unavailable or `background_unavailable` persists, and the user has approved foreground input, fall back to hypr-hands (`hypr-hands <cmd>` or `~/.local/share/hypr-hands/scripts/<cmd>.sh`, same machineId): `geom`/`ocr-find` to locate, `move` (verified), `click`, `scroll`, `type`, `key`, `drag` (ydotool opt-in). Set `HYPR_HANDS_REQUIRE_CLASS=<target class prefix>` so input is refused unless the target window is focused and under the cursor. Always `end_session` your cua run label first.

### Omarchy/Hyprland Lua dispatch (Hyprland with Lua config)

Classic `hyprctl dispatch <name> args` is rewritten to `hl.dispatch(...)` and fails for most dispatchers, e.g. `hyprctl dispatch movecursor X Y` → Lua syntax error. Use `hyprctl repl` with `hl.dsp.*`:

```bash
hyprctl repl "hl.dispatch(hl.dsp.cursor.move({ x = 600, y = 400 })); return 'ok'"   # logical px; positional args go to 0,0
hyprctl repl "hl.dispatch(hl.dsp.focus({ window = 'address:0xADDR' })); return 'ok'"
hyprctl repl "hl.dispatch(hl.dsp.window.move({ workspace = '3', follow = false })); return 'ok'"  # acts on focused window
hyprctl repl "hl.dispatch(hl.dsp.window.fullscreen()); return 'ok'"
hyprctl repl "hl.dispatch(hl.dsp.window.close()); return 'ok'"
```
Read-only `hyprctl cursorpos`, `activewindow -j`, `clients -j`, `monitors -j`, `layers -j` work normally. Introspect: `hyprctl repl "local t={} for k in pairs(hl.dsp) do t[#t+1]=k end return table.concat(t,' ')"`. Avoid `hl.dsp.send_shortcut` unless the target window is verified focused — it injects real keys.
