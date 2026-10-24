# Hardware on prol (wait for kernel)

Host: MacBook Pro 14" M3 Pro, Mac15,6, `apple,t6030` / `apple,j514s`.
Kernel when documented: aurora `7.1.12-2-20261017.20-sep-ARCH`.

## Touch ID

`aurora-touchid` is installed; `apple_sep` has no `t6030` profile. `/dev/sep-bio` is missing. Do not run `omarchy setup security fingerprint` (USB readers). When the node exists: `aurora-touchid-setup`.

omacom 7.2.10 and aurora-silicon 7.3 still have no `apple,t6030` SEP matcher. Silicon 7.3 is M4/Neo bring-up; it does not help this chip.

## Panel brightness

`/sys/class/backlight` empty. DCP: no Backlight service. Keyboard backlight works (`white:kbd_backlight`). Silicon 7.3 backlight path is `iomfb_is_m4()` / J713, not t6030.

Stay on the packaged omacom kernel until they ship t6030 SEP and a real IOMFB backlight service.
