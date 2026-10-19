# Summary

[Introduction](index.md)

# Understand the appliance

- [Components of the appliance](understand/components.md)
- [Storage tiers and the movement of data](understand/storage-tiers.md)
- [The data journey of a file from STS to LTS](understand/data-journey.md)
- [Build and install stages of the repository](understand/build-and-install.md)
- [Ways a site changes the appliance](understand/site-changes.md)

# Install and verify an appliance

- [Prepare the host for the appliance](install/prepare-host.md)
- [Install an appliance with SQLite](install/sqlite.md)
- [Install an appliance with MariaDB over a Unix socket](install/mariadb-uds.md)
- [Install an appliance with MariaDB over TCP](install/mariadb-tcp.md)
- [Archive a test PV and check the stored samples](install/verify-pv.md)
- [Reinstall or upgrade an appliance](install/reinstall.md)

# Build from source

- [Fetch and build the web applications](build/build-wars.md)
- [Select the source commit to build](build/select-commit.md)

# Configure the appliance

- [Configuration variables and their defaults](configure/variables.md)
- [Override a setting for one host](configure/override-setting.md)
- [Site folder layout](configure/site-folder.md)
- [Storage policy parameters](configure/policy-parameters.md)
- [Files of an installation](configure/installed-files.md)

# Operate the appliance

- [Start and stop actions of the appliance](operate/start-stop.md)
- [Check the health of the appliance](operate/health.md)
- [Health check results](operate/health-results.md)
- [Journal identifiers of the components](operate/logs.md)
- [Change a log level at run time](operate/loglevel.md)
- [Storage use reporting](operate/storage.md)

# Use the management interface

- [The pages of the management interface](interface/pages.md)
- [Judgements of the System pages](interface/judgements.md)
- [Find and pause a PV on the Browse PVs page](interface/browse-page.md)

# Test the environment

- [Run the local test suite](test/run-local.md)
- [Test groups of the local suite](test/phases.md)
- [VM verification operations](test/vm.md)

# Appendices

- [Make targets of the repository](appendix/make-targets.md)
- [Options of the repository scripts](appendix/script-options.md)
- [Glossary of terms used in the book](appendix/glossary.md)
