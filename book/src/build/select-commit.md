# Select the source commit to build

The value `SRC_TAG` in `configure/RELEASE` names the commit, tag or branch of the source repository that every build and installation uses. This page changes it for one checkout without editing the tracked file.

## Prerequisites

- A checkout whose source clone exists (`make init` ran).
- The commit, tag or branch that you want to build, available from the source repository.

## Steps

1. Print the reference that is in effect.

   ```bash
   make -s print-SRC_TAG
   ```

   The command prints the source reference:

   ```text
   origin/modernize
   ```

2. Write the value into `configure/RELEASE.local`, which Git ignores. `configure/RELEASE` includes this file, and `../RELEASE.local` next to the checkout, at its end. The command appends, so a file that already holds other settings keeps them.

   ```bash
   printf 'SRC_TAG:=<commit_or_branch>\n' >> configure/RELEASE.local
   ```

   `<commit_or_branch>` is the commit hash, tag or branch name to build. Write a branch as `origin/<branch>`: a bare branch name keeps the older local branch of the clone, while `origin/<branch>` follows the fetched tip.

3. Check that the value is in effect.

   ```bash
   make -s print-SRC_TAG
   ```

   The command prints `<commit_or_branch>`.

4. Fetch the source repository, then update the source clone to that reference and its submodules.

   ```bash
   git -C epicsarchiverap-maven-src fetch origin
   make srcupdate
   ```

   The target runs `git checkout <commit_or_branch>` and `git submodule update --init` in the clone; without the fetch it can only reach what the clone already has.

5. Build the web applications again, as in [Fetch and build the web applications](build-wars.md).

## Verification

The command `git -C epicsarchiverap-maven-src rev-parse HEAD` prints the commit of that value. A one-time override without a file is the Make command-line form, for example `make -s SRC_TAG=<commit_or_branch> print-SRC_TAG`.

To return to the default, delete `configure/RELEASE.local`; `make -s print-SRC_TAG` prints `origin/modernize` again.
