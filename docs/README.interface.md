# Management Interface

The management web interface of the appliance: the pages, what each judgement shows and where its value comes from,
the limits it keeps, and how its files reach the WARs and take the site skin. It covers the interface prepared in
`site-template/ui`; the server behind it is not changed by it.

## Scope

| In scope | Out of scope |
| :--- | :--- |
| The pages under `/mgmt/ui/` and the data viewer under `/retrieval/ui/viewer/` | The server calls (BPL) themselves, which are documented by the source repository |
| What the pages judge and the starting values of each judgement | Tuning the policies and the stores (see [the policy guide](./README.policies.md)) |
| Browser support, the content security policy, the files stored in the browser | The Channel Archiver integration beyond its page |
| The build step and the site skin | Moving the files to the source repository |

## Pages

| Page | Address | For | Content |
| :--- | :--- | :--- | :--- |
| Work | `index.html` | Everyone | Find PVs, scan the selected ones, inspect them, act on them |
| System: Overview | `system.html` | Everyone | Three verdict lines and one row per measure with its meaning and a link to the detail |
| System: Operations | `operations.html` | The person who looks after the appliance | Samples, dropped samples, write path, stores and ETL, processes, configuration |
| System: Retrieval performance | `retrieval.html` | A person whose data requests are slow | What the server reports and a request measured in the browser |
| Integration | `integration.html` | Administrators | Channel Archiver configuration, external archiver servers, a comparison |
| Data viewer | `/retrieval/ui/viewer/archViewer.html` | Everyone | Charts per unit for the PVs of the address |

The addresses `metrics.html`, `storage.html`, `appliance.html`, `reports.html`, `pvdetails.html` and `cacompare.html` forward
to the page that replaced them; `pvdetails.html?pv=<name>` opens that PV on the Work page.

## Work page

| Part | Behavior |
| :--- | :--- |
| Find | Words in any order with case ignored, glob, or regular expression; chips group the matches by the first two `:` segments; the rows in view show the state of a PV that is not in the scan list (paused, not archived), read in one call for at most 60 rows |
| Show | A selection of the list by one of the server reports: disconnected now, paused, never connected, waiting for the first connection, recently added, recently changed, highest event rate, highest storage rate, most storage used, most connection drops, silent for the longest time, most events dropped for a wrong time stamp, by buffer overflow and by a type change |
| Scan | One row per selected PV with its state, a trend of the chosen range, the value now and the last event; at most 100 PVs. A link opens the selected PVs in the data viewer over the window of the chart |
| Inspect | Time series of at most 5 PVs of the same unit, distribution, scatter and statistics; a drag across the chart zooms to that window and marks the samples when 200 or fewer are in view; Earlier and Later move the window by half its span |
| Detail | State with its explanation, the actions that apply, a link that opens the PV in the data viewer, and the full details list |

A PV name is a base name with an optional field (`X:Y` or `X:Y.RBV`); a name with a field is a PV of its own and the Work page
and the viewer accept it. A chart line is the held value of a monitored PV: it continues through a time without
samples, so a PV that changes rarely is drawn as one line. It stops at the last sample and starts again at the next one
only where the archiver recorded a lost connection or an engine start, so a lost connection is never drawn as a held
value. A range of up to 10 minutes on the Work page (11 minutes in the viewer) shows the stored samples; a longer one
shows means over equal intervals (`meanSample_N`), and the chart says so. An interval of such a range in which the archiver
has no sample has no value, and the line is not extended through it.
The viewer's CSV download holds the values as drawn, with the column `interval_seconds` (1 for a stored sample, N for a
mean over N seconds).

The state of a PV and the actions that apply:

| State | Actions |
| :--- | :--- |
| Being archived | Pause, Change sampling, Stop archiving, Maintenance |
| Paused | Resume, Change sampling, Stop archiving, Maintenance |
| Initial sampling, Appliance assigned | Abort the request |
| Not being archived | Archive |

Stop archiving pauses the PV first, because the archiver removes only a paused PV. Change sampling applies at once to a
running PV. Maintenance holds rename, change of type and consolidation; each of them pauses the PV first, and a change of
type asks for a confirmation that a backup exists. Pause, Resume and Stop archiving also work on all selected PVs at once.

The state is kept in the address, so a link reproduces the view:

| Parameter | Meaning |
| :--- | :--- |
| `q` | The search words |
| `mode` | `contains` (default), `glob` or `regex` |
| `report` | The selection of the Show list: `disconnected`, `paused`, `never`, `metagets`, `recent`, `modified`, `eventrate`, `storagerate`, `consumed`, `lost`, `silent`, `droppedtime`, `droppedbuffer` or `droppedtype`; none selects all archived PVs |
| `range` | The range in minutes (default 60) |
| `from`, `to` | A zoomed window, in milliseconds since the epoch |
| `pv` (repeated) | The selected PVs |

## The list of PV names

Archived names do not leave the list when their IOC stops, so a change of the list is almost always an addition. The page
keeps a snapshot of the names in the browser (IndexedDB database `aa-work-names`), shows it at once with the time it is
current to, and then keeps it current:

| Event | What the page does |
| :--- | :--- |
| Every 15 s while the page is visible | Asks for the number of PVs; nothing else when it is unchanged |
| The number rose | Reads the most recently added PVs and merges them |
| The number was unchanged for four polls | Reads the 20 most recent additions too, because a removal and an addition within one poll leave the number as it was; a removed name stays in the list until the number falls or the snapshot is a day old |
| The number fell, the snapshot is a day old, or an addition may be incomplete | Reads the whole list again |
| A name the snapshot lacks is searched | Asks the server once and keeps what it knows |
| More than 500,000 names | Does not hold the list; the server answers each search |

## What the System pages judge

The judgements are starting values, shown on the Operations page next to their basis. A measure that the appliance does not
report is shown as Not reported and is never shown as Normal.

| Judgement | Attention | Problem | Basis |
| :--- | :--- | :--- | :--- |
| Days left in the stores | Fewer than 30 days | Fewer than 7 days | Free space divided by the data the archiver adds per day |
| Free share of a device | Below 5 % | Below 3 % | Prometheus node exporter alert defaults |
| Write time of the engine | Above 50 % of the write period | 100 % or more | Samples are lost when the writer needs more than its period |
| Lowest heap after a collection | 70 % of the maximum, or a rise of 5 points in a day | 90 % | The live set of the application, not the instantaneous heap |
| A PV disconnected | For more than an hour | No PV connected | A shorter loss is often a restart |
| An ETL pass | Overran its interval, late, or a failed job | Busy for 200 % of its interval | The measures the ETL reports |
| Dropped samples | None | Any PV in the four dropped-event reports | A dropped sample is lost data |
| Components | Different versions | A component is not running | The appliance status and version reports |

The remedies on the Operations page name the setting to change. The sample buffer capacity adjustment is
`org.epics.archiverappliance.config.PVTypeInfo.sampleBufferCapacityAdjustment` in `archappl.properties`. The heap size of
a process is a property of the installation: in this environment it is `AA_JAVA_HEAPSIZE`, set in `CONFIG_SITE.local`
and applied by a new installation (see "Memory budget for a test VM" in the installation guide).

Disconnected PVs are grouped by the host the Channel Access connection came from and the time they were lost, because the
appliance reports no IOC name. A PV Access PV has no host and is listed under an unknown host.

## Limits and refresh

| Item | Value |
| :--- | :--- |
| PVs in the scan list | 100 |
| PVs in a chart | 5, and at most one unit per chart |
| Concurrent data requests | 6 |
| Status of the selected PVs | Every 3 s while a request is unfinished or an action is recent, every 20 s otherwise |
| System: Overview, Operations, Retrieval performance | Every 20 s, 30 s and 30 s while the page is visible |
| A request measured on the Retrieval performance page | The whole answer is read into the page, about 100 bytes per sample (a week of a PV at 1 Hz is about 60 MB); the page says so next to the form |

Measured on one host with 100 PVs at 1 Hz, ten minutes of samples each: every scan row is filled in 0.65 s or less, and the
slowest data request takes under 50 ms.

## Browsers and security

| Item | Behavior |
| :--- | :--- |
| Supported | The current releases of Firefox, Edge and Safari; no jQuery, no framework and no build tool. Checked in Firefox, Edge and the WebKitGTK engine of Safari, not in the Safari application |
| Content security policy | `script-src 'self'` on every page: no inline script, event-handler attribute or style attribute, and no outside host |
| `connect-src` | `'self'`, and `http:` and `https:` on the Work page and the Retrieval performance page, which read the data retrieval address the appliance reports |
| Stored in the browser | The snapshot of the names; nothing else |
| Data inserted into a page | Only as text, never as markup |

## Build and site skin

The prepared files live in `site-template/ui`, mirroring the layout of the source repository. Every build target runs
`make copy.ui` after `make copy.sitespecific`: the script `scripts/prepare-ui.bash` first undoes the earlier copy through a
manifest in the source checkout's git directory, then copies the folder over the source tree. With no folder the step leaves
the source tree unchanged. A copy prints `>>> We are copying the prepared interface files to <target>` and writes the
manifest `aa-ui-prepared.list` in that git directory; the copied pages are then served under `/mgmt/ui/` and
`/retrieval/ui/viewer/` of the built WARs.

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `ARCHAPPL_UI_TEMPLATE_PATH` | `$(AA_SITE_TEMPLATE_PATH)/ui` | The folder of prepared files |
| `ARCHAPPL_UI_TARGET_PATH` | `src/main/org/epics/archiverappliance` of the source checkout | Where they are copied |

The site skin keeps its inputs in `site-template/siteid` (see the installation guide). The pages take their colors, fonts and
spacing from the tokens of `css/main.css`, so a site changes the look by changing the tokens:

| Token | Use |
| :--- | :--- |
| `--c-brand`, `--c-accent`, `--c-accent-dark`, `--c-accent-soft` | The site header, links and selection |
| `--c-bg`, `--c-surface`, `--c-border`, `--c-border-strong` | Page and rule colors |
| `--c-text`, `--ink-2`, `--ink-3` | Text, which keeps a contrast of at least 4.5 to 1 on the page |
| `--c-danger`, `--alarm`, `--warn` | The alert color and the attention color, used only for judgements and disconnections |
| `--font-sans`, `--font-mono` | Fonts |

The marker blocks `site_header`, `site_navbar` and `site_footer` of a page are replaced by the build with those of
`index.html`; a page of `site-template/ui` must keep them.

## Verification

`tests/ui-static.bash` runs inside `bash tests/run-all-tests.bash --local`. It checks the marker blocks, the content
security policy, the absence of inline code, outside hosts, jQuery and text turned into markup, that the files a page names
exist, that every element id a script reads exists in its page, that the vendored chart library is the file whose
SHA-256 `d3.SOURCE.txt` records, and the contrast of the text colors; fifteen broken copies must
each be refused for their own reason. Every server call of a management file is written with its literal `../bpl/` path,
because the source repository's `StaticContentBPLCallsTest` reads that form.
