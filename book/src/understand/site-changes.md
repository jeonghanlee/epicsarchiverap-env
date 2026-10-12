# How a site changes the appliance

A site changes the appliance in three places: Make variables, the site folder and the interface files. This page explains what each place can change and where it takes effect.

## Make variables and local files

The files `configure/CONFIG_SITE`, `CONFIG_SRC`, `CONFIG_VARS`, `CONFIG_SQL`, `CONFIG_TOMCAT`, `CONFIG_SYSTEMD` and `CONFIG_EPICSENV` define every setting with its default. A site overrides a setting in a local file that Git ignores, so the tracked files stay unchanged. `CONFIG_SITE` includes these two files at its end, in this order:

1. `../CONFIG_SITE.local`, in the directory that holds the checkout.
2. `configure/CONFIG_SITE.local`, in the checkout.

`CONFIG_VARS` includes `CONFIG_VARS.local` from the same two places, and `RELEASE` includes `RELEASE.local`. An assignment in a local file wins over the default, as long as the variable is not defined again after the include.

The operating system target `<os>.conf` (for example `debian13.conf`) deletes `configure/CONFIG_SITE.local` and writes one line into it, the include of `configure/os/<os>.mk`. The installers run this target first. A site therefore keeps its own values in `../CONFIG_SITE.local`, next to the checkout, where no target rewrites them.

The generated files take their values from these variables when `make conf` runs. A change of a variable therefore needs the stage that uses it to run again, as the page [What the repository builds and installs](build-and-install.md) shows.

## The site folder

The variable `ARCHAPPL_SITEID` names the site, and its default is `als`. The folder `site-template/siteid` holds the site's inputs, and `copy.sitespecific` copies the whole folder to `src/sitespecific/<ARCHAPPL_SITEID>` of the source tree before every build. The source build then applies it to the WAR files.

| Path in the site folder | Effect |
| :--- | :--- |
| `img/` | Copied with its subfolders over the shared images of `staticcontent/img`, replacing the defaults |
| `css/main.css` | Copied over the shared stylesheet `staticcontent/css/main.css` |
| `css/mgmt.css` | Copied over `mgmt/staticcontent/css/mgmt.css` |
| `template_changes.html` | Merged into the staged management pages by `SyncStaticContentHeadersFooters`; the repository's file supplies the header, navigation and footer blocks |
| `classpathfiles/` | Holds `appliances.xml`, `archappl.properties` and `policies.py`; the WAR build packs the folder, the overlay does not apply it |

The overlay reports a site folder that does not exist or that holds a `build.xml`, and it stops the build. Any other file under `css/`, and any folder other than `img`, `css` and `classpathfiles`, only produces a warning. A site builds with another site folder by setting `ARCHAPPL_SITEID` and `ARCHAPPL_SITEID_TEMPATE_PATH` (the spelling of the second variable is as the configuration writes it).

## The interface files

The management pages and the data viewer are part of the source that `SRC_TAG` selects; this repository copies no interface files over the source tree. A site changes how the pages look through the site folder: `css/main.css`, `css/mgmt.css` and `template_changes.html` of `site-template/siteid`. A source older than commit `d0932d1b` of the source repository builds with the earlier pages, and the installers stop with `The selected source does not carry the management interface`.
