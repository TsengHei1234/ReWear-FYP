# Feature Contract — <FEATURE NAME>

> Copy this file to `docs/features/<feature>_contract.md` and fill it in by
> **mechanically searching** the three docs (use `docs/INDEX.md` to find sections,
> then search keywords listed below). Keep it ~50–150 lines. After the feature
> is built and verified, this contract is a build aid only — code + tests become
> the source of truth.

**Search keywords:** <e.g. Generate, pinned, skip, occasion, layers, session_excluded>

## Source sections used
- FE: §__ "__"
- RE: "__"
- DB: tables/fields __

## Required UI behaviour
- [ ] <state / layout / component, with the spec measurement or rule>

## Required DB reads/writes
- [ ] reads: __
- [ ] writes: __ (which fields, when)

## Required engine behaviour
- [ ] <which engine functions, inputs/outputs, edge cases>

## Edge cases / empty & error states
- [ ] __

## Open questions (resolve before/while building)
- __

## Verification checklist (build is "done" when all pass)
- [ ] `flutter analyze` clean
- [ ] relevant `flutter test` green
- [ ] manual flow on emulator matches the UI behaviour above
- [ ] DB writes confirmed (correct fields/values)
