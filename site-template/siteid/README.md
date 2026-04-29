# SVG Asset Sources

## `siteid/img`

All SVG files except `LBNLogo_293_75.svg` come from Feather open-source icons [1, 2], rendered with the lab color `#00313C` at `32x32` pixels. Refer to `LICENSE.Feather` in this directory for licensing terms. Files are renamed to match the existing Archiver Appliance asset names.

Then, all svg are converted through

```bash
for i in *.svg; do convert -background none "$i" "${i%.svg}.png"; done
```

## References

[1] <https://feathericons.com>

[2] <https://github.com/feathericons/feather>
