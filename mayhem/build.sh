#!/usr/bin/env bash
#
# mayhem/build.sh — build the Toy parser fuzz target (toy-parser-fuzz) + the full upstream test suite.
#
# Toy is a bytecode scripting language; source/ compiles to a single library (no main()). We compile
# those sources directly into the sanitized Mayhem target, and separately build the project's ENTIRE
# existing test suite (upstream's own makefiles, NORMAL flags) so mayhem/test.sh only RUNS it:
#   build/toy-parser-fuzz          sanitized + libFuzzer -> the Mayhem target (lex+parse arbitrary input)
#   tests/units/out/test_*.exe     normal flags          -> upstream C unit tests (run by test.sh)
#   tests/scripts/out/repl.out     normal flags          -> upstream repl that runs the .toy script tests
# No network, no upstream edits. On Linux TOY_API expands to `extern`, so static linking Just Works.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}"
: "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "${SRC:-/mayhem}"

LIBSRCS=(source/*.c)
HARNESS=mayhem/toy-parser-fuzz/toy-parser-fuzz.c

# Toy's bucket arena deliberately packs Toy_Ast unions at non-8-byte offsets, so UBSan's ALIGNMENT
# check fires on literally every input (even empty) at toy_ast.c — a pervasive design choice, not a
# fuzzable memory-safety bug. Drop ONLY that sub-check so the fuzzer can explore past input #0; ASan
# and the rest of UBSan (OOB, overflow, type-mismatch, …) stay ON and halting.
TARGET_SAN="$SANITIZER_FLAGS -fno-sanitize=alignment"

# 1) Sanitized fuzz target — the WHOLE library is instrumented (ASan/UBSan see bugs inside the lexer,
#    parser and AST/bucket allocator), linked with the libFuzzer engine. $DEBUG_FLAGS after the
#    sanitizer flags so -gdwarf-3 wins (DWARF < 4 for Mayhem triage). -w silences upstream's warnings.
mkdir -p build
# shellcheck disable=SC2086
$CC $TARGET_SAN $DEBUG_FLAGS $LIB_FUZZING_ENGINE -w -Isource "${LIBSRCS[@]}" "$HARNESS" -lm -o build/toy-parser-fuzz

# 2) Build the project's EXISTING test suite with upstream's NORMAL flags (a separate, clean build),
#    so mayhem/test.sh only RUNS it (never compiles). We invoke upstream's own sub-makefiles directly,
#    exporting the directory vars the top makefile normally sets. Build-only targets (no run here):
#      - unit tests  -> compile source + each tests/units/test_*.c, link tests/units/out/test_*.exe
#      - script tests-> build out/libToy.so + out/repl.out (repl runs the .toy scripts in test.sh; it
#        finds libToy.so via rpath $ORIGIN in the same out/ dir). No `copy` step (it isn't idempotent).
export TOY_SOURCEDIR=source TOY_REPLDIR=repl TOY_OUTDIR=out TOY_OBJDIR=obj
make -C tests/units build-source build-units build-link
make source repl

echo "build.sh: built build/toy-parser-fuzz (sanitized+libFuzzer) + upstream unit/script test suite"
