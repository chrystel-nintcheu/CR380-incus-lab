# Architecture / Framework Internals

## Overview

The test suite is a pure Bash framework with no external dependencies beyond standard Linux tools. It's designed for simplicity and readability so that curious students can understand and extend it.

La suite de tests est un framework Bash pur sans dépendances externes au-delà des outils Linux standards.

## Key Components

### 1. `_common.sh` — The Engine

All shared logic lives in `tests/_common.sh`. Every test script sources it:

```bash
# Inside each test script:
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"  # (done by run-labs.sh)
```

Key functions:
- **`pass(msg)`** — Record a passed assertion (green ✓)
- **`fail(msg, expected, actual, hint)`** — Record a failed assertion (red ✗) with diagnostic info
- **`skip(msg, reason)`** — Record a skipped check (yellow ⊘)
- **`run_cmd(description, timeout, cmd...)`** — Execute with timeout, capture output
- **`assert_*`** — Various assertion helpers
- **`learn_pause(fr, en)`** — In learn mode, display explanation and wait for Enter
- **`check_dependency(num)`** — Skip if a required earlier test failed
- **`wait_for_ready(container)`** — Poll until container is RUNNING
- **`cleanup_container(name)`** — Stop + delete a container safely
- **`incus_run(cmd...)`** — Wrapper for incus commands (see below)

#### `incus_run` Wrapper

At source time, `_common.sh` creates an executable wrapper at `/tmp/.incus_run_cr380`:
- **Root (EUID=0)**: the wrapper calls `exec "$@"` directly — root accesses the Incus socket without group membership.
- **Regular user**: the wrapper calls `exec sg incus-admin -c "$*"` — acquires the `incus-admin` group for socket access.

This avoids `newgrp` (which spawns a new shell and breaks scripts) and is compatible with `timeout` (which requires an executable, not a function). All test files use `incus_run incus ...` instead of bare `incus ...`.

#### Container Race Condition Handling

On fast-booting images (e.g., OpenWRT), `incus launch` may auto-start the container before the test's explicit start, resulting in "Error: already running". Tests in Labs 07, 08, 09, and 11 handle this by treating *"already"* in the output as a success condition.

### 2. `run-labs.sh` — The Orchestrator

The master runner:
1. Parses CLI flags
2. Sources `_common.sh` (which sources `config.env`)
3. Sources each test file in order
4. Calls `run_test()` from each sourced file
5. Handles dependency-based skipping
6. Generates reports

### 3. `config.env` — Single Source of Truth

All configurable values (image names, container names, timeouts, ports) live here. Update this file once per semester when image versions change.

## Execution Flow

```
run-labs.sh
  └─ source _common.sh
       └─ source config.env
  └─ for each test (00, 01, ..., 12, 99):
       └─ source tests/NN-*.sh
       └─ call run_test()
            ├─ section_header()
            ├─ check_dependency() → skip if dependency failed
            ├─ learn_pause() → pause in learn mode
            ├─ run_cmd() + assert_*() → execute and verify
            └─ section_summary() → record result
  └─ finalize_report()
  └─ print_final_summary()
```

## Dependency Graph

```
00-preflight
  └─→ 01-uninstall
       └─→ 02-install
            └─→ 03-post-install
                 └─→ 04-init
                      └─→ 05-registries
                           └─→ 06-images
                                └─→ 07-containers
                                     └─→ 08-port-exposure
                                          └─→ 09-app-container
                                               └─→ 10-file-transfer
                                                    └─→ 11-storage
                                                         └─→ 12-volumes

99-teardown (no dependencies — always runs, cleans up all resources)
```

If any test fails, all downstream tests are **SKIPPED** (not failed). This prevents cascading failures and makes it clear where the real problem is.

Lab 99 is independent: it always executes regardless of other test results, and removes all containers, images, storage pools, and network bridges.

## Adding a New Test

1. Create `tests/NN-name.sh` with a `run_test()` function
2. Inside `run_test()`:
   - Call `section_header "NN" "Title" "url"`
   - Call `check_dependency "NN-1"` (previous test number)
   - Add your assertions using `assert_*` functions
   - Call `section_summary` at the end
3. Add the test number to the `TESTS` array in `run-labs.sh`

Example:

```bash
run_test() {
    section_header "13" "My New Test" ""
    check_dependency "12" || { section_summary; return 0; }

    assert_success "My check" "hint" some_command --flag
    learn_pause "Explication FR" "Explanation EN"

    section_summary
}
```

## Report Format

JSON reports in `results/`:

```json
{
  "timestamp": "20250101-143000",
  "tests": [
    {"test": "00-Preflight", "status": "pass", "duration_s": 5, "error": ""},
    {"test": "06-Images", "status": "fail", "duration_s": 120, "error": "2 assertion(s) failed"}
  ],
  "summary": {"pass": 35, "fail": 2, "skip": 12}
}
```

## Design Decisions

| Decision | Why |
|----------|-----|
| Pure Bash (no BATS/pytest) | Zero dependencies, students can read it |
| `incus_run` wrapper | Avoids `newgrp` (spawns new shell); works with `timeout`; handles root vs regular user |
| Preseed YAML for init | Reproducible, avoids interactive prompts |
| `config.env` for all values | Single place to update when images change |
| Dual mode (validate/learn) | One tool for both teacher validation and student learning |
| JSON reports | Parseable, diff-able, archivable |
| Sequential dependencies | Real labs build on each other — tests should too |
| Proxy device cleanup before add | Incus proxy device state persists; remove old device first to avoid conflicts |
