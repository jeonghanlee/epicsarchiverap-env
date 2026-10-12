# Find and pause a PV on the Work page

This page finds an archived process variable (PV) by part of its name, shows its state, and pauses it. A paused PV stays registered and keeps its data; the archiver stops sampling it until you resume it.

## Prerequisites

- A running appliance and a browser that can reach the `mgmt` port (17665 by default).
- The name, or part of the name, of an archived PV.

## Steps

1. Open the Work page.

   ```text
   http://<appliance_host>:17665/mgmt/ui/index.html
   ```

   `<appliance_host>` is the host that runs the `mgmt` application. The page loads the list of PV names; the line under the result list reads `Loading PV names…` until the list is ready, and then shows when it is current.

2. Type words of the PV name into the search field. The words match in any order and the case is ignored.

   The count line above the list reads `N of M PVs match`.

3. Select the PV in the result list: click its row, or move with the arrow keys and press the space key. The PV appears in the Scan table with its state, a trend of the last hour, its value and the time of its last event.

4. Look at the Detail area. It shows the state of the PV with an explanation and the actions that apply to that state.

   | State | Actions in the Detail area |
   | :--- | :--- |
   | Being archived | Pause, Change sampling…, Stop archiving…, and a Maintenance section |
   | Paused | Resume, Change sampling…, Stop archiving…, and a Maintenance section |
   | Initial sampling, Appliance assigned | Abort the request |
   | Not being archived | Archive… |

   `Stop archiving…` pauses the PV first, because the archiver removes only a paused process variable. `Pause all selected…`, `Resume all selected…` and `Stop archiving all selected…` above the Scan table act on every selected PV.

5. Click `Pause`. The state word of the PV changes to `Paused`, and the button becomes `Resume`.

6. Optional: click `Resume` to sample the PV again.

## Verification

The Scan row and the Detail area show the state `Paused`. The `getPVStatus` call of `mgmt` reports it too:

```bash
curl -s "http://<appliance_host>:17665/mgmt/bpl/getPVStatus?pv=<pv_name>"
```

The answer is a JSON array whose first element has `"pvName"` and `"status"`. For a PV that the appliance does not archive it reads:

```text
[{"pvName":"<pv_name>","status":"Not being archived"}]
```

After step 5 the status of the PV is `Paused`.
