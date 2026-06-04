# Contract — Donation Rules (D1–D5 + DPS)

**Source:** RE "Donation Decision Support". Pure Dart. Runs on full wardrobe,
EXCLUDES status DELETED/DONATED. Decision support only.
**Location:** `lib/engine/donation/donation_rules.dart` + test. Then un-stub
`_isDonationCandidate` in `badge_engine.dart`.

## Pre-check (per item)
- status DELETED/DONATED → not a candidate (no rules).
- kept_until != null AND kept_until > today → suppress (no rules).

## Rules (days_since_worn from last_worn_date; days_since_added from date_added)
- **D1** Long-term unused: wear_count>0 AND days_since_worn ≥ 90 → "Not worn in 3+ months".
- **D2** Never worn old: wear_count==0 AND days_since_added > 90 → "Added 3+ months ago, never worn".
- **D3** Frequently skipped: skip_count ≥ 10 AND raw_skip_ratio > 0.75 → "You keep skipping this item".
  (raw_skip_ratio = skip/(wear+skip); 0 when wear+skip==0)
- **D4** Poor condition: condition == 1 → "Worn out — consider disposal, not donation".
- **D5** Worn condition unused: wear_count>0 AND condition==2 AND days_since_worn ≥ 60 →
  "This item is showing wear and hasn't been used in 2+ months".

## Tier: 1 rule → "Worth Reviewing"; 2+ rules → "Strong Candidate".

## DPS — Donation Priority Score (ranking)
```
days_norm = min((never worn ? days_since_added : days_since_worn) / 365, 1.0)
skip_ratio = skip_count / (wear_count + skip_count + 1)   (+1 buffer)
condition_score = (5 - condition) / 4
DPS = 0.50·days_norm + 0.30·skip_ratio + 0.20·condition_score
```

## Filter chips (Phase 7 display): Never Worn=D2 · Long Unused=D1 ·
Frequently Skipped=D3 · Poor Condition=D4 or D5. Sort: DPS desc.
