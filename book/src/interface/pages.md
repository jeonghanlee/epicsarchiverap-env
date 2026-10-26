# The pages of the management interface

The `mgmt` application serves the management interface under `/mgmt/ui/`, and the `retrieval` application serves the data viewer under `/retrieval/ui/viewer/`. This page names each page, says who it is for, and lists the older addresses that forward to a page. The pages are static files; their source is the interface of the source repository that `SRC_TAG` selects, under `src/main/org/epics/archiverappliance`.

## The pages and their addresses

| Page | Address | For | What it shows |
| :--- | :--- | :--- | :--- |
| Browse PVs | `/mgmt/ui/index.html` | Everyone | Find process variables (PVs) by name, scan the selected ones, chart them, and act on them |
| Archive PVs | `/mgmt/ui/archive.html` | Everyone who adds PVs | Request archiving for a list of PV names with a sampling choice, and follow the requests of the visit |
| System: Overview | `/mgmt/ui/system.html` | Everyone | Three verdict lines and one row for each measure, with its meaning and a link to the detail |
| System: Operations | `/mgmt/ui/operations.html` | The person who looks after the appliance | Samples, dropped samples, the write path, the stores and ETL, the processes and the configuration in effect |
| System: Retrieval performance | `/mgmt/ui/retrieval.html` | A person whose data requests are slow | What the server reports about reading, and a data request measured in the browser |
| System: External servers | `/mgmt/ui/external.html` | Administrators | The other EPICS Archiver Appliance clusters whose data this appliance serves: add or remove one |
| Data viewer | `/retrieval/ui/viewer/archViewer.html` | Everyone | Charts for the PVs and the time span of the address, one chart for each unit |

`archappl.bash status` prints the address of the Browse PVs page for the host.

## The Browse PVs page

The page has two areas. The finder on the left has a search field with three modes (Contains, Glob, Regex), a list for selecting server reports, name groups and the result list. The board on the right shows the selected PVs: a Scan table, a time series chart with a distribution, a plot of two PVs against each other and a summary table. It also shows the detail of the focused PV with the actions that apply to it. The address keeps the state of the page, so a link reproduces the view.

The task page [Find and pause a PV on the Browse PVs page](browse-page.md) uses it. The link `Archive PVs…` under the result list opens the Archive PVs page.

## The Archive PVs page

The page has a field for PV names, one for each line or pasted as a list, and a Sampling choice that holds the method (Monitor or Scan), the period, the policy and a controlling PV. What the choice leaves empty is decided by the policy of the site. The `Archive` button submits the names, and the table `Requested in this visit` lists each request with its state. The table has actions to pause, resume, stop archiving or cancel the selected requests.

## The System pages

The four System pages share a tab bar. The first three, Overview, Operations and Retrieval performance, also share an appliance selector, which appears only when the cluster has more than one appliance. Each of these three pages states, in a short block at the start of each section, the question the section answers, when the numbers are a problem and what to do. The judgements are listed in [Judgements of the System pages](judgements.md).

## Older addresses that forward to a page

A page that moved leaves a short page at its old address.

| Old address | Forwards to |
| :--- | :--- |
| `/mgmt/ui/appliance.html` | `system.html` |
| `/mgmt/ui/metrics.html` | `operations.html` |
| `/mgmt/ui/storage.html` | `operations.html#stores` |
| `/mgmt/ui/integration.html` | `external.html` |
| `/mgmt/ui/cacompare.html` | `external.html` |
| `/mgmt/ui/reports.html` | `index.html`; the reports are selections of the list on the Browse PVs page |
| `/mgmt/ui/pvdetails.html?pv=<pv_name>` | `index.html#pv=<pv_name>`, which selects that PV on the Browse PVs page |

## Content security of the pages

Every full page carries a content security policy that allows scripts only from the page's own origin: `script-src 'self'`. The Browse PVs page and the Retrieval performance page also allow `http:` and `https:` for connections, because they read the address of the data retrieval application that `getApplianceInfo` reports. The pages insert data only as text.
