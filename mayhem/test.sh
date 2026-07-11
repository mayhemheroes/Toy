#!/usr/bin/env bash
#
# mayhem/test.sh — functional oracle for Toy. RUNS the project's ENTIRE existing test suite (built by
# build.sh; nothing is compiled here):
#   1. unit tests   — tests/units/out/test_*.exe (upstream C unit tests). Each prints "All good" and
#                     exits 0 on success; on failure it prints an ERROR line and returns nonzero.
#   2. script tests — tests/scripts/{basics,values,keywords,algorithms}/test_*.toy, executed by the
#                     prebuilt repl (out/repl.out). The repl exit(-1)s on a failed assert.
#
# A patch that breaks Toy fails these; a neutered binary prints no "All good" and fails too (the
# anti-reward-hack behavioral check, §6.3).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "${SRC:-/mayhem}"
shopt -s nullglob

passed=0; failed=0; skipped=0
check() { if [ "$2" -eq 0 ]; then echo "  ok   - $1"; passed=$((passed+1)); else echo "  FAIL - $1"; failed=$((failed+1)); fi; }
skip()  { echo "  skip - $1"; skipped=$((skipped+1)); }

emit_ctrf() {
  local tool="$1" p="$2" f="$3" s="${4:-0}"; local tests=$(( p + f + s ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": { "tests": $tests, "passed": $p, "failed": $f, "pending": 0, "skipped": $s, "other": 0 }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":0,"skipped":%d,"other":0}}}\n' \
    "$tool" "$tests" "$p" "$f" "$s"
  [ "$f" -eq 0 ]
}

# 1) upstream unit tests — run each prebuilt binary; require exit 0 AND the "All good" success marker
#    (the marker is what makes this behavioral: a neutered binary that just exits 0 prints nothing).
units=(tests/units/out/test_*.exe)
if [ ${#units[@]} -eq 0 ]; then
  echo "test.sh: no unit-test binaries under tests/units/out — build.sh must build them" >&2
  emit_ctrf toy 0 1; exit 1
fi
for exe in "${units[@]}"; do
  name="unit $(basename "$exe" .exe)"
  o="$("$exe" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$o" | grep -q 'All good'; then
    check "$name" 0
  elif [ "$rc" -eq 0 ] && printf '%s' "$o" | grep -q 'Test not yet implemented'; then
    skip "$name (upstream stub)"     # upstream ships an unimplemented placeholder that exits 0
  else
    check "$name" 1
  fi
done

# 2) upstream script tests — execute each .toy with the prebuilt repl; assert-failure -> nonzero exit.
repl="$(find out -maxdepth 1 -name 'repl*' -type f -perm -u+x 2>/dev/null | head -1)"
if [ -z "$repl" ]; then
  echo "test.sh: no repl under out/ — build.sh must build it" >&2
  emit_ctrf toy "$passed" $((failed+1)); exit 1
fi
scripts=(tests/scripts/basics/test_*.toy tests/scripts/values/test_*.toy \
         tests/scripts/keywords/test_*.toy tests/scripts/algorithms/test_*.toy)
for s in "${scripts[@]}"; do
  [ -f "$s" ] || continue
  if "$repl" -f "$s" >/dev/null 2>&1; then
    check "script ${s#tests/scripts/}" 0
  else
    check "script ${s#tests/scripts/}" 1
  fi
done

echo "test.sh: passed=$passed failed=$failed skipped=$skipped"
emit_ctrf toy "$passed" "$failed" "$skipped"
