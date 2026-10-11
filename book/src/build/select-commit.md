# Select the source commit to build

The value `SRC_TAG` in `configure/RELEASE` names the commit, tag or branch of the source repository that every build and installation uses. This page changes it for one checkout without editing the tracked file.

## Prerequisites

- A checkout whose source clone exists (`make init` ran).
- The commit, tag or branch that you want to build, available from the source repository.

## Steps

1. Print the commit that is in effect.

   ```bash
   make -s print-SRC_TAG
   ```

   The command prints the pinned commit:

   ```text
   1f099b2f5fe7ecb714e4a055e8b895f267fb78e0
   ```

2. Write the value into `configure/RELEASE.local`, which Git ignores. `configure/RELEASE` includes this file, and `../RELEASE.local` next to the checkout, at its end.

   ```bash
   printf 'SRC_TAG:=<commit_or_branch>\n' > configure/RELEASE.local
   ```

   `<commit_or_branch>` is the commit hash, tag or branch name to build.

3. Check that the value is in effect.

   ```bash
   make -s print-SRC_TAG
   ```

   The command prints `<commit_or_branch>`.

4. Update the source clone to that commit and its submodules.

   ```bash
   make srcupdate
   ```

   The target runs `git checkout <commit_or_branch>` and `git submodule update --init` in the clone.

5. Build the web applications again, as in [Fetch and build the web applications](build-wars.md).

## Verification

The command `git -C epicsarchiverap-maven-src rev-parse HEAD` prints the commit of that value. A one-time override without a file is the Make command-line form, for example `make -s SRC_TAG=<commit_or_branch> print-SRC_TAG`.

To return to the pin, delete `configure/RELEASE.local`; `make -s print-SRC_TAG` prints the pinned commit again.
