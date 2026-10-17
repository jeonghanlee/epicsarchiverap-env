# Management Interface

The management web interface of the appliance (the Browse PVs page, the Archive PVs page, the System pages and the data viewer) is part of the
source repository `jeonghanlee/epicsarchiverap-maven`. Its pages, what each judgement shows and its starting values,
the limits it keeps and the browsers it supports are described there:

- [The management interface pages](https://github.com/jeonghanlee/epicsarchiverap-maven/blob/modernize/docs/book/src/interface.md)

## What this repository keeps

| Item | Where |
| :--- | :--- |
| The site logo and favicon of the header | `site-template/siteid/template_changes.html`, the `site_logo` block; the header frame, the header logo, the menu and the stylesheet come from the source |
| The site folder inputs and how a build applies them | [Site inputs](./README.install.md#site-inputs) and [Interface files](./README.install.md#interface-files) |
| Static checks of the interface files | `bash tests/ui-static.bash`; the files come from the source checkout that `SRC_TAG` selects, listed in `tests/ui-files.list` |

## Selecting the source

`SRC_TAG` in `configure/RELEASE` names the source commit or branch that every build uses. The interface is part of the
source since `d0932d1b`; a source older than that builds with the earlier pages, and the installers stop with the
message `The selected source does not carry the management interface`.
