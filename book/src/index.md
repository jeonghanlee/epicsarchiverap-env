# Introduction

This book describes `epicsarchiverap-env`, the Make-driven environment that builds the EPICS Archiver Appliance from its `epicsarchiverap-maven` source and installs it on a host.

## What the repository does

The repository performs four jobs, each driven by a Make target:

- It clones the source repository named by `SRC_GITURL` into `SRC_PATH` and checks out the commit `SRC_TAG`.
- It copies the site inputs of `site-template/siteid` and the interface files of `site-template/ui` over the source tree.
- It builds the four web applications of the appliance (`mgmt`, `engine`, `etl` and `retrieval`) as WAR files with the Maven Wrapper of the source.
- It installs a local appliance with SQLite or with MariaDB over a Unix socket or over TCP, using the installers `install-local-sqlite.bash`, `install-local-mariadb-uds.bash` and `install-local-mariadb-tcp.bash` in `scripts/`.

## Values the repository pins

The configuration files under `configure/` set the values that decide which source is built and where it is installed. To print a value, run `make -s print-<variable_name>`, for example `make -s print-SRC_TAG`.

| Variable | Meaning | Set in |
| :--- | :--- | :--- |
| `SRC_GITURL` | The source repository that is cloned | `configure/CONFIG_VARS` |
| `SRC_PATH` | The folder, under the repository root, that holds the clone | `configure/CONFIG_VARS` |
| `SRC_TAG` | The commit of the source that is built | `configure/RELEASE` |
| `ARCHAPPL_SITEID` | The name of the site folder that is applied to the source; its default is `als` | `configure/CONFIG_SITE` |
| `AA_INSTALL_LOCATION` | The directory the appliance is installed into | `configure/CONFIG_SITE` |

## How the book is organized

| Part | What it answers |
| :--- | :--- |
| Understand the appliance | What the components are, how data moves between the stores, what the repository builds, and how a site changes it |
| Install and verify an appliance | How to prepare a host, install with SQLite or MariaDB, check a test PV, and reinstall |
| Build from source | How to fetch and build the web applications and how to select the source commit |
| Configure the appliance | Which variables exist, where to override them, what the site folder holds and which files an installation creates |
| Operate the appliance | How to start and stop it, check its health, read its logs, change a log level and watch the storage |
| Use the management interface | What the pages show, what the System pages judge and how to find and pause a PV |
| Test the environment | How to run the local suite and what the virtual machine tests do |
| Appendices | The make targets, the options of the scripts and the glossary |

## How to read this book

Each page has one type: a concept page explains, a procedure page gives numbered steps and a verification, a reference page lists exact values, and a tutorial page teaches one task from start to finish. A value in angle brackets, such as `<variable_name>`, is a placeholder that you replace.

Every page says which of its commands were run as shown. A command that changes the host, such as an installation, was not run for the book, and its page says so. The reference pages that restate the configuration, the make targets, the script options, the storage parameters and the judgement thresholds are generated from the repository by the scripts in `book/scripts`, so they cannot differ from it.

## Why the book has no tutorial

A tutorial would repeat the procedure "Install an appliance with SQLite" and then "Archive a test PV and check the stored samples" step for step. The installation changes the host and needs root privilege and systemd, so the author cannot show each result of a tutorial on one host. The two procedures are the path from an empty host to a verified appliance.
