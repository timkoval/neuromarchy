-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Caps Lock is owned by keyd (tap Esc, hold Ctrl; physical Esc is Caps).
-- Do not also set caps:swapescape here: Hypr would swap keyd's output
-- and Caps would be Caps again. Both Shifts still cancel Caps Lock.
-- Mouse natural_scroll matches elitebook/neuronix and the Omarchy trackpad.
-- Dvorak stays first so Omarchy binds keep using the Dvorak keysyms.
-- QWERTY is layout 1 for KiCad hotkeys (M/R/W and friends).
hl.config({
  input = {
    kb_layout = "us,us",
    kb_variant = "dvorak,",
    kb_options = "shift:both_capslock_cancel",
    natural_scroll = true,
  },
})

-- KiCad's class is "kicad" for the project manager and editors. Switch only
-- typed keyboards plus the fcitx virtual one (main); skip lid/power so the
-- bar layout widget does not follow those devices.
local function set_seat_layout(idx)
  for _, name in ipairs({
    "keyd-virtual-keyboard",
    "apple-mtp-keyboard",
    "hl-virtual-keyboard-fcitx5",
  }) do
    hl.exec_cmd("hyprctl switchxkblayout " .. name .. " " .. idx)
  end
  -- fcitx is the main keyboard; KiCad is GTK and reads this IM.
  local im = (idx == 1) and "keyboard-us" or "keyboard-us-dvorak"
  hl.exec_cmd("fcitx5-remote -s " .. im)
end

local function apply_layout_for_window(window)
  if type(window) ~= "table" or not window.class then
    window = hl.get_active_window()
  end
  local class = window and window.class or ""
  set_seat_layout((class == "kicad") and 1 or 0)
end

hl.on("window.active", apply_layout_for_window)
hl.on("config.reloaded", function()
  apply_layout_for_window()
end)

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use traditional (non-inverse) scrolling.
--       natural_scroll = false,
--
--       -- Re-enable tap-to-click (one-finger tap = left, two-finger = right).
--       tap_to_click = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Three-finger swipe scrolls the column tape (niri-like).
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })

-- Enable touchpad gestures for changing workspaces.
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
