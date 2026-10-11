# Site folder layout

The site folder holds the inputs that the build applies to the source tree for one site. This page lists its contents as the repository ships them and what each entry becomes. The folder is `site-template/siteid`, and `ARCHAPPL_SITEID` (default `als`) names the destination `src/sitespecific/<ARCHAPPL_SITEID>` of the source tree.

## Contents of the site folder

| Path | Content | Used by |
| :--- | :--- | :--- |
| `classpathfiles/appliances.xml` | The appliance identity and the addresses of the components | Packed into every WAR by the source build |
| `classpathfiles/archappl.properties` | The properties of the engine and the retrieval | Packed into every WAR by the source build |
| `classpathfiles/policies.py` | The storage policies and the store URLs | Packed into every WAR by the source build |
| `css/main.css` | The shared stylesheet, defined by color, font and spacing tokens | Copied over `staticcontent/css/main.css` |
| `css/mgmt.css` | The stylesheet of the management pages | Copied over `mgmt/staticcontent/css/mgmt.css` |
| `img/` | Images, with the site logo | Copied over `staticcontent/img` |
| `template_changes.html` | The header, navigation and footer blocks | Merged into the management pages |
| `README.md`, `LICENSE.FeatherIcons` | Notes and a license | Not applied |

The three files of `classpathfiles/` are written by `make conf`; the other entries are tracked in the repository.

## The tokens of main.css

The management pages take their color, font and spacing from the custom properties of `css/main.css`, so a site changes the look by changing the tokens. The file defines these groups:

| Token | Use |
| :--- | :--- |
| `--c-brand`, `--c-accent`, `--c-accent-dark`, `--c-accent-soft` | The site header, the links and the selection |
| `--c-bg`, `--c-surface`, `--c-border`, `--c-border-strong` | The page and the rules |
| `--c-text`, `--ink-2`, `--ink-3` | The text, with a contrast of at least 4.5 to 1 on the page |
| `--c-danger`, `--alarm`, `--warn` | The alert and the attention color, used for judgements and disconnections |
| `--font-sans`, `--font-mono` | The fonts |

## Build for another site

A build for another site uses another folder with the same layout. Set `ARCHAPPL_SITEID` and `ARCHAPPL_SITEID_TEMPATE_PATH` (spelled as the configuration spells it) in `../CONFIG_SITE.local`, as in [Override a setting for one host](override-setting.md).
