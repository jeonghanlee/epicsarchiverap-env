# Components of the appliance

The appliance is four Java web applications that run side by side on an appliance host. This page names them, shows how each one is started and addressed, and explains how they find each other through `appliances.xml`.

## The four web applications

The repository lists them in `ARCHAPPL_SERVICES`: `mgmt`, `engine`, `etl` and `retrieval`. The source builds each one as its own web application archive (WAR) file, and the installation puts each one in its own Tomcat instance.

| Component | Default port | Address path | What it does |
| :--- | ---: | :--- | :--- |
| `mgmt` | 17665 | `/mgmt/bpl` | Accepts management requests. Its `BPLServlet` registers every management action, and the package `archivepv` runs the archive request workflow. It also serves the management pages. |
| `engine` | 17666 | `/engine/bpl` | Connects to the process variables (PVs), buffers their samples and writes them to the first store. `ArchiveEngine` creates the channels and pauses and resumes archiving. |
| `etl` | 17667 | `/etl/bpl` | Moves data from one store to the next (`ETLSource`, `ETLDest`, `ETLExecutor`). |
| `retrieval` | 17668 | `/retrieval/bpl`, data at `/retrieval` | Serves stored data. `DataRetrievalServlet` is the single entry for data requests. |

The ports are the variables `ARCHAPPL_MGMT_PORT`, `ARCHAPPL_ENGINE_PORT`, `ARCHAPPL_ETL_PORT` and `ARCHAPPL_RETRIEVAL_PORT` in `configure/CONFIG_SITE`. The Tomcat shutdown port of every instance is `-1`, which turns the shutdown port off (`ARCHAPPL_SHUTDOWN_*_PORT`).

## One Tomcat instance for each component

Each component has its own Tomcat instance in a folder of the same name under `AA_INSTALL_LOCATION`, for example `/opt/epicsarchiverap-maven/mgmt`. The rule `serverxml.install` writes the port of the component into the `conf/server.xml` of its instance. The rule `serveroption.install` installs the file `<component>.conf` of `site-template` into `conf/` of the instance.

In this repository only `mgmt.conf` carries options: Java module arguments (`--add-modules`, `--add-exports`, `--add-opens`). The other three files hold only comments.

## How the components find each other

The file `appliances.xml` lists the appliances of a cluster and the addresses of their components. Every component reads it at start. The repository generates it from `site-template/appliances.xml.in`. A single appliance with the default settings produces this file:

```xml
<appliances>
   <appliance>
     <identity>appliance0</identity>
     <cluster_inetport>localhost:16670</cluster_inetport>
     <mgmt_url>http://localhost:17665/mgmt/bpl</mgmt_url>
     <engine_url>http://localhost:17666/engine/bpl</engine_url>
     <etl_url>http://localhost:17667/etl/bpl</etl_url>
     <retrieval_url>http://localhost:17668/retrieval/bpl</retrieval_url>
     <data_retrieval_url>http://localhost:17668/retrieval</data_retrieval_url>
   </appliance>
</appliances>
```

| Element | Set by variable | Default |
| :--- | :--- | :--- |
| `identity` | `ARCHAPPL_SINGLE_IDENTITY` | `appliance0` |
| `cluster_inetport` | `ARCHAPPL_CLUSTER_INETPORT` | `$(ARCHAPPL_HOST_IPADDR):16670` |
| `mgmt_url`, `engine_url`, `etl_url` | `ARCHAPPL_MGMT_URL`, `ARCHAPPL_ENGINE_URL`, `ARCHAPPL_ETL_URL` | `http://$(ARCHAPPL_HOST_IPADDR):<port>/<component>/bpl` |
| `retrieval_url` | `ARCHAPPL_RETRIEVAL_URL` | `$(ARCHAPPL_DATA_RETRIEVAL_URL)/bpl` |
| `data_retrieval_url` | `ARCHAPPL_DATA_RETRIEVAL_URL` | `http://$(ARCHAPPL_HOST_IPADDR):17668/retrieval` |

`ARCHAPPL_HOST_IPADDR` is `localhost` by default. A client that reads data uses `data_retrieval_url`; the management pages read it through the `getApplianceInfo` call of `mgmt`.

The reader of `appliances.xml` in the source (`AppliancesList`) refuses two appliances with the same identity. It also refuses two appliances with the same `cluster_inetport` when that value does not start with `localhost`.

## Settings the components share

The file `archappl.conf` is generated from `archappl.conf.in` and installed into `AA_INSTALL_LOCATION`. It holds the environment that every instance reads: the Java and Tomcat locations, the paths of `appliances.xml`, `policies.py` and `archappl.properties`, the appliance identity, the ports, the storage folders and the `EPICS_CA_*` settings of the Channel Access client.
