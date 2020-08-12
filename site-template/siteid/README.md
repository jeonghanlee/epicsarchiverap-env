# License Information

## `siteid/img`

All svg files except LBNLogo_293_75.svg comes from Feather Open source
cons [1, 2] with the lab color `#00313C`  and `32x32` pixels.
Please consult the relevant license `LICENSE.Feather` in this directory. I r
enamed them to match the exist archiver appliance names.

Then, all svg are converted through

```bash
for i in *.svg; do convert -background none "$i" "${i%.svg}.png"; done
```

## References

[1] <https://feathericons.com>

[2] <https://github.com/feathericons/feather>
