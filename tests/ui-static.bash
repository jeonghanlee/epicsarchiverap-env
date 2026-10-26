#!/usr/bin/env bash
# Static checks of the management interface files that epicsarchiverap-maven carries.
# A management page keeps the marker blocks the site template replaces, every full page carries a content
# security policy, no page has an inline script, an event-handler or style attribute, no file refers to jQuery
# or to an outside host (the target of a navigation link, which the user follows and the page does not request,
# may name one), and every element id that a script reads exists in its page.
# The files are read from the source checkout that SRC_TAG selects (override: AA_SOURCE_CLONE); the list of
# files is tests/ui-files.list. Without a source checkout the checks are skipped with a message.

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOP

# shellcheck source=lib/common.bash
source "${TOP}/tests/lib/common.bash"

phase_header "Interface files: markers, content security, inline code and element ids"

# The tree under test; a mutation run points this at another tree with the layout below.
if [[ -n "${UI_STATIC_TREE_UNDER_TEST:-}" ]]; then
    ROOT="${UI_STATIC_TREE_UNDER_TEST}"
else
    clone="${AA_SOURCE_CLONE:-}"
    if [[ -z "${clone}" ]]; then
        src_path=$(make -C "${TOP}" --no-print-directory -s print-SRC_PATH | tail -1)
        clone="${TOP}/${src_path}"
    fi
    if [[ ! -d "${clone}/src/main/org/epics/archiverappliance" ]]; then
        printf '  [SKIP] No source checkout at %s; run make init to check the interface files.\n' "${clone}"
        phase_skip "Interface files: markers, content security, inline code and element ids"
        exit 0
    fi
    # Gather the listed files into the layout the checks use: <root>/site-template/ui/<relative path>,
    # next to the site skin that this repository keeps in site-template/siteid.
    ROOT="${WORKSPACE}/interface-tree"
    mkdir -p "${ROOT}/site-template/siteid"
    # The site folder may carry no stylesheet; the one of the source then applies.
    if [[ -d "${TOP}/site-template/siteid/css" ]]; then
        cp -a "${TOP}/site-template/siteid/css" "${ROOT}/site-template/siteid/css"
    fi
    cp -a "${TOP}/site-template/siteid/template_changes.html" "${ROOT}/site-template/siteid/template_changes.html"
    missing=""
    while IFS= read -r relative; do
        [[ -n "${relative}" ]] || continue
        source_file="${clone}/src/main/org/epics/archiverappliance/${relative}"
        if [[ -f "${source_file}" ]]; then
            mkdir -p "$(dirname "${ROOT}/site-template/ui/${relative}")"
            cp -a "${source_file}" "${ROOT}/site-template/ui/${relative}"
        else
            missing+="${relative} "
        fi
    done < "${TOP}/tests/ui-files.list"
    assert_empty "${missing}" "The source checkout carries every interface file of tests/ui-files.list"
fi
UI="${ROOT}/site-template/ui"
assert_dir "${UI}" "The interface folder exists"

# Third-party code is checked by its integrity record, not by these rules.
function own_files {
    find "${UI}" -type f \( -name '*.html' -o -name '*.js' -o -name '*.css' \) ! -path '*/js/vendor/*' | LC_ALL=C sort
}

function is_forward {
    grep -q -E 'http-equiv="refresh"|js/forward\.js' "$1"
}

# ---- every page ------------------------------------------------------------------------------------
while IFS= read -r page; do
    name="${page#"${UI}/"}"

    inline=$(grep -n -E '<script' "${page}" | grep -v -E 'src=' || true)
    assert_eq "${inline}" "" "${name} has no inline script"

    handlers=$(grep -n -E '[[:space:]]on[a-z]+[[:space:]]*=' "${page}" || true)
    assert_eq "${handlers}" "" "${name} has no event-handler attribute"

    styles=$(grep -n -E '[[:space:]]style[[:space:]]*=' "${page}" || true)
    assert_eq "${styles}" "" "${name} has no inline style attribute"

    scripts=$(grep -n -E 'javascript:' "${page}" || true)
    assert_eq "${scripts}" "" "${name} has no javascript: address"

    if is_forward "${page}"; then
        continue
    fi

    case "$(cat "${page}")" in
        *"Content-Security-Policy"*"script-src 'self'"*) _record_pass "${name} carries a content security policy" ;;
        *) _record_fail "${name} carries a content security policy" "no script-src 'self' policy found" ;;
    esac

    case "${name}" in
        mgmt/staticcontent/*)
            for block in site_header site_navbar site_footer; do
                begins=$(grep -c -F "@begin(${block})" "${page}" || true)
                ends=$(grep -c -F "@end(${block})" "${page}" || true)
                if [[ "${begins}" == 1 && "${ends}" == 1 ]]; then
                    _record_pass "${name} keeps the marker block ${block}"
                else
                    _record_fail "${name} keeps the marker block ${block}" "marker block missing or repeated (begin ${begins}, end ${ends})"
                fi
            done
            ;;
    esac
done < <(find "${UI}" -type f -name '*.html' ! -path '*/js/vendor/*' | LC_ALL=C sort)

# ---- every own file --------------------------------------------------------------------------------
while IFS= read -r file; do
    name="${file#"${UI}/"}"
    jquery=$(grep -n -i 'jquery' "${file}" || true)
    assert_eq "${jquery}" "" "${name} does not refer to jQuery"
    markup=$(grep -n -E 'innerHTML|outerHTML|insertAdjacentHTML|document\.write|[^a-zA-Z]eval\(|new Function' "${file}" || true)
    assert_eq "${markup}" "" "${name} does not turn text into markup or run text as code"
    # The SVG namespace is an identifier, not an address that is requested. The target of a link that the user
    # follows is not requested either; every other address, of a script, a style, an image or a data call, is.
    hosts=$(python3 -I - "${file}" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read().replace("http://www.w3.org/2000/svg", "")
text = re.sub(r'<a\b[^>]*?\bhref\s*=\s*"https?://[^"]*"',
              lambda m: "<a" + "\n" * m.group(0).count("\n"), text, flags=re.S)
for number, line in enumerate(text.splitlines(), 1):
    if re.search(r'https?://', line):
        print("%d:%s" % (number, line))
PY
) || true
    assert_eq "${hosts}" "" "${name} does not refer to an outside host"
done < <(own_files)

# ---- every server call is written with its literal path ---------------------------------------------
# The source repository's StaticContentBPLCallsTest collects the pattern ../bpl/<name> from the management files and
# checks each name against the registered actions, so a call has to be written in that form to be checked there.
calls=$(grep -h -o -E '\.\./bpl/[A-Za-z]+(/[A-Za-z]+)*' -r "${UI}/mgmt/staticcontent" --include='*.js' --include='*.html' | sed 's|\.\./bpl/||' | LC_ALL=C sort -u)
case $'\n'"${calls}"$'\n' in
    *$'\ngetPVStatus\n'*) _record_pass "The management files name their server calls with the literal ../bpl/ path" ;;
    *) _record_fail "The management files name their server calls with the literal ../bpl/ path" "getPVStatus is not written as ../bpl/getPVStatus" ;;
esac
assert_eq "$([[ $(printf '%s\n' "${calls}" | wc -l) -ge 30 ]] && echo enough || echo few)" "enough" "At least 30 server calls are written with the literal path"

# ---- element ids read by a script exist in its page ------------------------------------------------
PAIRS=(
    "mgmt/staticcontent/index.html:mgmt/staticcontent/js/browse.js"
    "mgmt/staticcontent/system.html:mgmt/staticcontent/js/system.js"
    "mgmt/staticcontent/operations.html:mgmt/staticcontent/js/operations.js"
    "mgmt/staticcontent/retrieval.html:mgmt/staticcontent/js/retrieval.js"
    "mgmt/staticcontent/external.html:mgmt/staticcontent/js/external.js"
    "mgmt/staticcontent/archive.html:mgmt/staticcontent/js/archive.js"
    "retrieval/staticcontent/viewer/archViewer.html:retrieval/staticcontent/viewer/viewer.js"
)
for pair in "${PAIRS[@]}"; do
    page="${UI}/${pair%%:*}"
    script="${UI}/${pair##*:}"
    assert_file "${page}" "${pair%%:*} exists"
    assert_file "${script}" "${pair##*:} exists"
    missing=''
    while IFS= read -r id; do
        [[ -n "${id}" ]] || continue
        grep -q -F "id=\"${id}\"" "${page}" || missing+=" ${id}"
    done < <({ grep -o -E '(\$|getElementById)\("[A-Za-z0-9_-]+"\)' "${script}" | sed -E 's/.*\("([^"]+)"\)/\1/'
               grep -o -E '(fill|emptyRow)\("[A-Za-z0-9_-]+"' "${script}" | sed -E 's/.*\("([^"]+)"/\1/'; } | LC_ALL=C sort -u)
    assert_eq "${missing}" "" "${pair##*:} reads only element ids that ${pair%%:*} defines (no element for:${missing})"
done

# ---- the site template names no jQuery ------------------------------------------------------------
site_jquery=$(grep -n -i 'jquery' "${ROOT}/site-template/siteid/template_changes.html" || true)
assert_eq "${site_jquery}" "" "The site template template_changes.html does not refer to jQuery"

# ---- a PV name is a base name with an optional field --------------------------------------------
# The server archives X:Y.RBV as a PV of its own, so the name patterns of the pages must accept it.
for script in mgmt/staticcontent/js/browse.js mgmt/staticcontent/js/archive.js retrieval/staticcontent/viewer/viewer.js; do
    refused=$(python3 - "${UI}/${script}" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r"^const PV_NAME = /(.*)/;$", text, re.M)
if not match:
    print("no PV_NAME pattern")
    sys.exit(0)
pattern = re.compile(match.group(1))
bad = [n for n in ("UI:TEST:X1", "UI:TEST:X2.A", "SR:C01:BPM.RBV") if not pattern.search(n)]
bad += [n for n in ("bad name!", "X.", "X..Y") if pattern.search(n)]
print(" ".join(bad))
PY
)
    assert_eq "${refused}" "" "${script} accepts a PV name with a field and refuses a malformed name (wrong for: ${refused})"
done
system_links=$(grep -c 'pageHref(row.href)' "${UI}/mgmt/staticcontent/js/system.js" || true)
assert_eq "${system_links}" "1" "The System overview builds its detail links with the chosen appliance"

# ---- a reduced range does not fill empty intervals ---------------------------------------------------
# mean_N fills an interval without samples with the previous value; meanSample_N leaves it empty, so a lost connection
# is not drawn as a held line.
filling=$(grep -rn -E '`mean_\$' "${UI}" --include='*.js' || true)
assert_eq "${filling}" "" "No page asks the server for mean_N, which fills an interval without samples"

# ---- the vendored chart library is the file its record names -----------------------------------------
d3_recorded=$(grep -o -E '[0-9a-f]{64}' "${UI}/staticcontent/js/vendor/d3.SOURCE.txt" | head -1 || true)
d3_actual=$(sha256sum "${UI}/staticcontent/js/vendor/d3.min.js" | cut -d' ' -f1)
assert_eq "${d3_actual}" "${d3_recorded}" "d3.min.js matches the SHA-256 recorded in d3.SOURCE.txt"

# ---- scripts and styles named by a page exist ------------------------------------------------------
# comm/ is the shared folder; the stylesheet and the header image come from the source itself.
SOURCE_FILES=" comm/css/main.css comm/img/archiverheader.svg "
while IFS= read -r page; do
    name="${page#"${UI}/"}"
    dir="$(dirname "${name}")"
    while IFS= read -r reference; do
        [[ -n "${reference}" ]] || continue
        case "${reference}" in http*|//*) continue ;; esac
        resolved=$(realpath -m --relative-to="${UI}" "${UI}/${dir}/${reference}")
        shared="${resolved}"
        case "${reference}" in
            comm/*) shared="staticcontent/${reference#comm/}" ;;
            ../comm/*) shared="staticcontent/${reference#../comm/}" ;;
        esac
        reference_key="${reference#../}"
        if [[ -f "${UI}/${resolved}" || -f "${UI}/${shared}" || "${SOURCE_FILES}" == *" ${reference_key} "* ]]; then
            _record_pass "${name} finds ${reference}"
        else
            _record_fail "${name} finds ${reference}" "no such file in the interface files and not a known source file"
        fi
    done < <(grep -o -E '(src|href)="[^"]+\.(js|css|svg)"' "${page}" | sed -E 's/^(src|href)="//; s/"$//')
done < <(find "${UI}" -type f -name '*.html' | LC_ALL=C sort)

# ---- text colors keep a contrast of at least 4.5:1 -------------------------------------------------
# The tokens are read from the stylesheet that applies: the one of the site folder when it carries one, and the
# shared stylesheet of the source otherwise. A token that points to another one is followed.
if [[ -f "${ROOT}/site-template/siteid/css/main.css" ]]; then
    STYLESHEET="${ROOT}/site-template/siteid/css/main.css"
    STYLESHEET_RELATIVE="siteid/css/main.css"
else
    STYLESHEET="${UI}/staticcontent/css/main.css"
    STYLESHEET_RELATIVE="ui/staticcontent/css/main.css"
fi
assert_file "${STYLESHEET}" "The stylesheet that applies exists"
contrast=$(python3 -I - "${STYLESHEET}" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
tokens = dict(re.findall(r'^\s*(--[a-z0-9-]+):\s*([^;]+);', text, re.M))
def value(name):
    v = tokens[name].strip()
    m = re.fullmatch(r'var\((--[a-z0-9-]+)\)', v)
    return value(m.group(1)) if m else v
def luminance(h):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
def ratio(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)
failures = []
for foreground in ('--ink', '--ink-2', '--ink-3', '--accent', '--warn', '--alarm'):
    for background in ('--bg', '--focus-bg'):
        r = ratio(value(foreground), value(background))
        if r < 4.5:
            failures.append('%s on %s is %.2f:1' % (foreground, background, r))
print('; '.join(failures))
PY
)
assert_eq "${contrast}" "" "Every text color has a contrast of at least 4.5:1 on the page and on a selected row"

# ---- the checks reject a copy with one defect each -------------------------------------------------
# A check that cannot fail protects nothing: each copy below holds one defect and must be refused,
# and for the reason named, not for another one.
function expect_rejected {
    local description="$1" phrase="$2" relative="$3" snippet="$4"
    local tree="${WORKSPACE}/mutation-${description// /-}" output status=0
    mkdir -p "${tree}/site-template/siteid"
    cp -a "${UI}" "${tree}/site-template/ui"
    if [[ -d "${ROOT}/site-template/siteid/css" ]]; then
        cp -a "${ROOT}/site-template/siteid/css" "${tree}/site-template/siteid/css"
    fi
    cp -a "${ROOT}/site-template/siteid/template_changes.html" "${tree}/site-template/siteid/template_changes.html"
    F="${tree}/site-template/${relative}" bash -c "${snippet}"
    output=$(WORKSPACE="$(mktemp -d -p "${WORKSPACE}")" UI_STATIC_TREE_UNDER_TEST="${tree}" bash "${BASH_SOURCE[0]}" 2>&1) || status=$?
    if [[ "${status}" -eq 0 ]]; then
        _record_fail "A copy with ${description} is refused" "the checks passed"
    fi
    case "${output}" in
        *"${phrase}"*) _record_pass "A copy with ${description} is refused: ${phrase}" ;;
        *) _record_fail "A copy with ${description} is refused for the named reason" "expected '${phrase}' in: ${output}" ;;
    esac
}

# The counterpart of expect_rejected: a rule that is narrowed must still accept what it was narrowed for.
function expect_accepted {
    local description="$1" relative="$2" snippet="$3"
    local tree="${WORKSPACE}/mutation-${description// /-}" output status=0
    mkdir -p "${tree}/site-template/siteid"
    cp -a "${UI}" "${tree}/site-template/ui"
    if [[ -d "${ROOT}/site-template/siteid/css" ]]; then
        cp -a "${ROOT}/site-template/siteid/css" "${tree}/site-template/siteid/css"
    fi
    cp -a "${ROOT}/site-template/siteid/template_changes.html" "${tree}/site-template/siteid/template_changes.html"
    F="${tree}/site-template/${relative}" bash -c "${snippet}"
    output=$(WORKSPACE="$(mktemp -d -p "${WORKSPACE}")" UI_STATIC_TREE_UNDER_TEST="${tree}" bash "${BASH_SOURCE[0]}" 2>&1) || status=$?
    if [[ "${status}" -eq 0 ]]; then
        _record_pass "A copy with ${description} is accepted"
    else
        _record_fail "A copy with ${description} is accepted" "the checks failed: ${output}"
    fi
}

if [[ -z "${UI_STATIC_TREE_UNDER_TEST:-}" ]]; then
    expect_rejected "a page without its navigation block" "marker block site_navbar" \
        ui/mgmt/staticcontent/system.html "sed -i '/@begin(site_navbar)/d' \"\$F\""
    expect_rejected "an inline script" "has no inline script" \
        ui/mgmt/staticcontent/system.html "printf '<script>alert(1)</script>\\n' >> \"\$F\""
    expect_rejected "an event handler" "has no event-handler attribute" \
        ui/mgmt/staticcontent/external.html "sed -i '0,/<button/s//<button onclick=\"go()\"/' \"\$F\""
    expect_rejected "a jQuery reference" "does not refer to jQuery" \
        ui/mgmt/staticcontent/js/browse.js "printf '// jQuery\\n' >> \"\$F\""
    expect_rejected "an unknown element id" "no element for: noSuchElement" \
        ui/mgmt/staticcontent/js/browse.js "printf 'document.getElementById(\"noSuchElement\");\\n' >> \"\$F\""
    expect_rejected "an outside host" "does not refer to an outside host" \
        ui/retrieval/staticcontent/viewer/viewer.js "printf '// https://example.invalid/x.js\\n' >> \"\$F\""
    expect_rejected "a script from an outside host" "does not refer to an outside host" \
        ui/mgmt/staticcontent/system.html "printf '<script src=\"https://example.invalid/x.js\"></script>\\n' >> \"\$F\""
    expect_rejected "a stylesheet from an outside host" "does not refer to an outside host" \
        ui/mgmt/staticcontent/system.html "printf '<link rel=\"stylesheet\" href=\"https://example.invalid/x.css\">\\n' >> \"\$F\""
    expect_accepted "a navigation link to an outside host" \
        ui/mgmt/staticcontent/system.html "printf '<a href=\"https://example.invalid/manual\">Manual</a>\\n' >> \"\$F\""
    expect_rejected "no content security policy" "carries a content security policy" \
        ui/mgmt/staticcontent/index.html "sed -i '/Content-Security-Policy/d' \"\$F\""
    expect_rejected "a script that is not there" "finds js/missing.js" \
        ui/mgmt/staticcontent/index.html "sed -i 's|js/browse.js|js/missing.js|' \"\$F\""
    expect_rejected "data inserted as markup" "does not turn text into markup" \
        ui/mgmt/staticcontent/js/browse.js "printf 'document.body.innerHTML = \"\";\\n' >> \"\$F\""
    expect_rejected "a server call built from parts" "name their server calls with the literal" \
        ui/mgmt/staticcontent/index.html "grep -rl --include='*.js' --include='*.html' 'bpl/getPVStatus' \"\$(dirname \"\$F\")\" | xargs sed -i 's|bpl/getPVStatus|bpl/get\" + \"PVStatus|g'"
    expect_rejected "a site template that includes jQuery" "template_changes.html does not refer to jQuery" \
        siteid/template_changes.html "printf '<script src=\"comm/js/jquery.js\"></script>\\n' >> \"\$F\""
    expect_rejected "a PV name pattern without the field" "accepts a PV name with a field" \
        ui/retrieval/staticcontent/viewer/viewer.js "sed -i 's|(\\\\.\\[a-zA-Z_\\]\\[a-zA-Z0-9_\\]\\*)?||' \"\$F\""
    expect_rejected "a reduced range that fills empty intervals" "asks the server for mean_N" \
        ui/retrieval/staticcontent/viewer/viewer.js "sed -i 's|meanSample_|mean_|' \"\$F\""
    expect_rejected "a vendored chart library that differs from its record" "matches the SHA-256 recorded" \
        ui/staticcontent/js/vendor/d3.min.js "printf '\\n' >> \"\$F\""
    expect_rejected "a faint text color below the contrast limit" "contrast of at least 4.5:1" \
        "${STYLESHEET_RELATIVE}" "sed -i 's|--ink-3: var(--c-muted);|--ink-3: #9aa9ae;|' \"\$F\""
fi

phase_pass "Interface files: markers, content security, inline code and element ids"
