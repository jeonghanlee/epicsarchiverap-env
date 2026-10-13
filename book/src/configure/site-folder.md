# Site folder layout

The site folder holds the inputs that the build applies to the source tree for one site. This page lists its contents as the repository ships them and what each entry becomes. The folder is `site-template/siteid`, and the value of `ARCHAPPL_SITEID` (default `als`) is the `<site_id>` of the destination `src/sitespecific/<site_id>` in the source tree.

## Contents of the site folder

| Path | Content | Used by |
| :--- | :--- | :--- |
| `classpathfiles/appliances.xml` | The appliance identity and the addresses of the components | Packed into every web application archive (WAR) by the source build |
| `classpathfiles/archappl.properties` | The properties of the engine and the retrieval | Packed into every WAR by the source build |
| `classpathfiles/policies.py` | The storage policies and the store uniform resource locators (URLs) | Packed into every WAR by the source build |
| `css/main.css` | Optional: the stylesheet of a site that sets its own color, font and spacing tokens; the shipped folder has none | Copied over `staticcontent/css/main.css` |
| `img/` | The site logo `LBNLLogo.png` and the browser icon `als.ico` | Copied over `staticcontent/img` |
| `template_changes.html` | The `site_logo` block: the site logo and the favicon link | Merged into the management pages |

The three files of `classpathfiles/` are written by `make conf`; the other entries are tracked in the repository. The management pages link only `css/main.css`. A `css/mgmt.css` in the site folder is not applied, and the build reports it as `Not applied`.

The header logo, its narrow-screen wordmark and the menu come from the source and are not part of the site folder. The source supplies the header frame; a `site_header` block would put a second header inside it and a `site_navbar` block would replace the menu, so the site folder carries neither.

Keep the site logo inside `<span id="siteimages">` in the `site_logo` block. The shared stylesheet sizes `#siteimages img` to 44 px, to 30 px at 720 px and below and to 24 px at 380 px and below, and a logo outside that element gets none of these sizes. The file `template_changes.html` of the repository shows the form.

## The tokens of main.css

The management pages take their color, font and spacing from the custom properties of `css/main.css`. A site that supplies its own file changes the look by changing the tokens; without one the stylesheet of the source applies. The file replaces the whole stylesheet, so it also replaces the rules of the menu and of the logo sizes. Start from the file of the source, change only the values of the site, and compare it with the file of the source again whenever the source changes. The file defines these groups:

| Token | Use |
| :--- | :--- |
| `--c-brand`, `--c-accent`, `--c-accent-dark`, `--c-accent-soft` | The site header, the links and the selection |
| `--c-bg`, `--c-surface`, `--c-border`, `--c-border-strong` | The page and the rules |
| `--c-text`, `--ink-2`, `--ink-3` | The text, with a contrast of at least 4.5 to 1 on the page |
| `--c-danger`, `--alarm`, `--warn` | The alert and the attention color, used for judgements and disconnections |
| `--font-sans`, `--font-mono` | The fonts |

## Build for another site

A build for another site uses another folder with the same layout. Set `ARCHAPPL_SITEID` and `ARCHAPPL_SITEID_TEMPATE_PATH` (spelled as the configuration spells it) in `../CONFIG_SITE.local`, as in [Override a setting for one host](override-setting.md).
