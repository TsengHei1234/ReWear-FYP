# Wardrobe App — Complete Rule Engine (Stage 3 Final, v8)

**Project title:** Developing a Rule-Based Wardrobe Recommendation and Donation Decision Support System
**System type:** Rule-based, no AI, no machine learning
**SDG alignment:** SDG 12 — Responsible Consumption and Production
**Status:** All formulas fixed, all edge cases patched, stress tested, all decisions locked. Incorporates Phases 1–11 implementation deltas.

---

## Changelog v7 → v8

- Schema: `profiles.display_name` added; `created_at`/`updated_at`/`event_at`/`logged_at` are `timestamptz`; `item_events.outfit_log_id` (nullable) added.
- Type dictionary: `CASUAL_SHORTS` and `SANDALS` formality → 2; generic `SKIRT` replaced by `CASUAL_SKIRT` + `WORK_SKIRT` (`DRESS_SKIRT` kept); `CASUAL_COAT_PARKA` split into `PARKA` (2) + `CASUAL_COAT` (3); added `OVERSHIRT_SHIRT_JACKET`, `SPORTS_BRA`, `CAMISOLE`, `CROP_TOP`, `BALLET_FLATS`, `HEELS`.
- Layer 1: added **F5 — Worn-Today Gate** and its empty-pool case.
- Layer 3: replaced the P1c low-colour reject/fallback with **P1D — Tier-Priority Reorder**; added the P1c colour-matrix note; added the cosmetic "Loose formality" badge line.
- Outfit Generator: session lifecycle replaced with the hasGenerated confirm/clear model (G1); "Regenerate" → "Start Over"; documented the Candidate Pool **Type Filter**.
- Daily Rotation / Insights / Badges: "Overused" now requires `wear_count >= 3`; "Most worn" badge renamed display label "Top Worn"; "Never worn" badge uses effective age; skip-scope split (G3).
- Condition: added the Edit-time `condition_next_drop` preserve rule; drop-to-1 nulls via clear flag.
- Donate/Delete: confirmation-sheet-only, no undo snackbar; donated/deleted Item Detail read-only.

---

## Locked Occasions

```
Casual    Work    Active    Relax
```

- Formal removed entirely — rare event, FULL_BODY not in MVP, adds complexity for no daily value
- Interview falls under Work
- "All" selection in UI skips F2 occasion filter entirely

---

## Item Data Model — All Fields

### Static fields (set on add)

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to profiles |
| image_path | Text | Supabase Storage path for item photo |
| name | String | e.g. "Blue Slim Jeans" |
| category | Enum | TOP, BOTTOM, OUTERWEAR, FOOTWEAR, OTHERS |
| type | String | Controlled stored type from Item Type Dictionary. Display labels may repeat across categories, but stored values must be unique per category/type |
| color_tags | String[] | Required, ≥1 colour. The Add/Edit UI is single-select and stores exactly one primary colour at color_tags[0] (used by P1c and PS); the array type is retained for schema compatibility and future multi-colour expansion |
| occasion_tags | Enum[] | CASUAL, WORK, ACTIVE, RELAX |
| formality_level | Int (1–5) | 1=very casual, 5=very formal |
| date_added | Date | When added to app |
| is_new_item | Boolean | True = user confirmed brand new never worn |
| is_favorite | Boolean | Handled inside PS only, no separate multiplier |
| status | Enum | IN_WARDROBE, LAUNDRY, LENT, STORED, DONATED, DELETED |
| initial_history_type | Enum | BRAND_NEW, ALREADY_OWNED_WORN, ALREADY_OWNED_UNWORN |
| initial_last_worn_option | Enum / Nullable | Approximate last worn selection |
| initial_wear_count_option | Enum / Nullable | Approximate wear count selection |
| initial_owned_duration_option | Enum / Nullable | Approximate owned duration selection |
| initial_usage_age_days | Integer | Estimated days owned before app, default 0 |
| laundry_started_at | Date / Nullable | Set when status changes to LAUNDRY |
| kept_until | Date / Nullable | Suppresses item from donation candidates until this date |
| donated_at | Date / Nullable | Set when status changes to DONATED |
| condition_review_mode | Enum | AUTO or MANUAL. Default AUTO. User chooses on AddItemScreen. |

The `initial_*_option` fields preserve the user's original add-item dropdown answers for edit/review/explanation screens. Runtime formulas use the mapped values.

### Dynamic fields (updated on interactions)

| Field | Type | Updated when |
|---|---|---|
| wear_count | Int | User logs wear |
| last_worn_date | Date / Nullable | User logs wear |
| skip_count | Int | User explicitly skips item or outfit |
| wear_count_unknown | Boolean | True when initial wear count was unknown. Set false when logWorn() is called. |
| last_worn_unknown | Boolean | True when initial last worn was unknown. Set false when logWorn() is called. |
| condition | Int (1–5) | User selects on add/edit. Default 5 Excellent. User manually updates, or AUTO mode drops it on wear log |
| condition_next_drop | Int / Nullable | Advances after every AUTO drop or manual condition change. NULL if MANUAL or condition == 1. |

### Computed at runtime (never stored)

```
days_since_worn   = today - last_worn_date (NULL if never worn)
days_since_added  = today - date_added (minimum 1)
skip_ratio        =
    IF (wear_count + skip_count) == 0:
        0.0
    ELSE:
        skip_count / (wear_count + skip_count)
                    (raw ratio — used in badges and D3 donation rule)
wear_rate         = wear_count / usage_period_days
usage_period_days =
    IF initial_wear_count_option == "I don't remember"
       AND wear_count_unknown == false:
        max(days_since_added, 1)
    ELSE:
        max(initial_usage_age_days + days_since_added, 1)
```

Note: `skip_ratio` computed getter uses raw formula with a zero-interaction guard.
SPS formula uses buffered formula (+5). Different purposes, intentional.

### Formality level scale

```
1 = Very casual    (gym shorts, loungewear, slippers)
2 = Casual         (jeans, plain t-shirt, basic sneakers)
3 = Smart casual   (chinos, button-down shirt, clean trainers)
4 = Business       (dress shirt, formal trousers, oxford shoes)
5 = Very formal    (suit jacket, evening blazer, dress shoes)
```

---

## Item Type Dictionary and Default Mapping

The Item Type Dictionary is a fixed app-rule mapping, not a database table.
It controls which item types appear for each selected category on Add/Edit
Item screens and provides safe default values for `occasion_tags`,
`formality_level`, and AUTO condition thresholds.

The database stores the final item values:

```
category
type
occasion_tags
formality_level
condition
condition_next_drop
```

The dictionary itself should live in app code as constants. It is used for:
- Showing only valid types for the selected category
- Auto-selecting default occasion tags when a type is chosen
- Restricting occasion chips to allowed occasions only
- Auto-filling the default formality level
- Validating that selected type belongs to selected category before save
- Looking up the condition threshold used by AUTO condition review

### Type dictionary rules

```
Each stored type belongs to exactly one category.
Add/Edit screens show only types belonging to the selected category.
Default occasions must always be a subset of allowed occasions.
Blocked occasions are not stored.
Blocked occasions = all locked occasions - allowed occasions.
The user can select or deselect only allowed occasions.
The engine uses saved category, occasion_tags, formality_level, condition,
status, and wear history. Type is used for defaults, validation, and
condition threshold lookup.
```

If the user changes category on Edit and the old type no longer belongs to
the new category:

```
Clear selected type
Clear type-based defaults
Require user to choose a valid type for the new category
```

Duplicate display labels are allowed only when stored types are different.
Example:

```
TOP_HOODIE       -> category TOP, threshold 28
OUTERWEAR_HOODIE -> category OUTERWEAR, threshold 34
```

### Type-based condition threshold rule

```
threshold = lookup from category/type mapping

On item add:
    IF condition_review_mode == AUTO AND condition > 1:
        condition_next_drop = wear_count + threshold
    ELSE:
        condition_next_drop = NULL

On category/type edit (threshold changed):
    Do not change condition
    Do not change wear_count
    Recalculate threshold from updated category/type
    IF condition_review_mode == AUTO AND condition > 1:
        condition_next_drop = wear_count + new_threshold
    ELSE:
        condition_next_drop = NULL
```

On an edit that does NOT change condition, type/threshold, or review mode, the
existing condition_next_drop is PRESERVED — see "condition_next_drop logic →
On editItem()" for the full rule.

### TOP type mapping

All TOP items use condition threshold 28 wears.

| Stored type | Display label | Default occasions | Allowed occasions | Default formality | Condition threshold |
|---|---|---|---|---:|---:|
| T_SHIRT | T-shirt | CASUAL, RELAX | CASUAL, RELAX, ACTIVE | 2 | 28 |
| SPORTS_T_SHIRT | Sports T-shirt / Active top | ACTIVE | ACTIVE, CASUAL, RELAX | 1 | 28 |
| TANK_TOP_SINGLET | Tank top / Singlet | RELAX, ACTIVE | RELAX, ACTIVE, CASUAL | 1 | 28 |
| LONG_SLEEVE_TOP | Long-sleeve top | CASUAL, RELAX | CASUAL, RELAX | 2 | 28 |
| POLO_SHIRT | Polo shirt | CASUAL | CASUAL, WORK | 3 | 28 |
| CASUAL_BUTTON_UP_SHIRT | Casual button-up shirt | CASUAL | CASUAL, WORK | 3 | 28 |
| DRESS_SHIRT | Dress shirt | WORK | WORK | 4 | 28 |
| BLOUSE | Blouse | CASUAL, WORK | CASUAL, WORK | 3 | 28 |
| TOP_HOODIE | Hoodie / Sweatshirt as top | CASUAL, RELAX | CASUAL, RELAX | 2 | 28 |
| SPORTS_BRA | Sports bra / Active bra | ACTIVE | ACTIVE, RELAX | 1 | 28 |
| CAMISOLE | Camisole / Cami top | CASUAL, RELAX | CASUAL, RELAX | 2 | 28 |
| CROP_TOP | Crop top | CASUAL | CASUAL, RELAX | 2 | 28 |
| OTHER_TOP | Other top | CASUAL | CASUAL, RELAX, ACTIVE, WORK | 2 | 28 |

### BOTTOM type mapping

All BOTTOM items use condition threshold 58 wears.

| Stored type | Display label | Default occasions | Allowed occasions | Default formality | Condition threshold |
|---|---|---|---|---:|---:|
| JEANS | Jeans | CASUAL | CASUAL, WORK, RELAX | 2 | 58 |
| CASUAL_SHORTS | Casual shorts | CASUAL, RELAX | CASUAL, RELAX | 2 | 58 |
| SPORT_SHORTS | Sport shorts | ACTIVE | ACTIVE, RELAX | 1 | 58 |
| JOGGERS_SWEATPANTS | Joggers / Sweatpants | RELAX | RELAX, CASUAL, ACTIVE | 1 | 58 |
| CHINOS | Chinos | CASUAL, WORK | CASUAL, WORK | 3 | 58 |
| CASUAL_LONG_PANTS | Casual long pants | CASUAL | CASUAL, WORK | 3 | 58 |
| FORMAL_TROUSERS_SLACKS | Formal trousers / Slacks | WORK | WORK | 4 | 58 |
| CASUAL_SKIRT | Casual skirt | CASUAL | CASUAL, RELAX | 2 | 58 |
| WORK_SKIRT | Work skirt | WORK | WORK, CASUAL | 3 | 58 |
| DRESS_SKIRT | Dress skirt | WORK | WORK | 4 | 58 |
| LEGGINGS | Leggings | ACTIVE, RELAX | ACTIVE, RELAX, CASUAL | 1 | 58 |
| OTHER_BOTTOM | Other bottom | CASUAL | CASUAL, RELAX, ACTIVE, WORK | 2 | 58 |

### OUTERWEAR type mapping

All OUTERWEAR items use condition threshold 34 wears.

| Stored type | Display label | Default occasions | Allowed occasions | Default formality | Condition threshold |
|---|---|---|---|---:|---:|
| OUTERWEAR_HOODIE | Hoodie / Sweatshirt as outerwear | CASUAL, RELAX | CASUAL, RELAX | 2 | 34 |
| CARDIGAN | Cardigan | CASUAL, WORK | CASUAL, WORK, RELAX | 3 | 34 |
| CASUAL_JACKET | Casual jacket | CASUAL | CASUAL, WORK, RELAX | 2 | 34 |
| DENIM_JACKET | Denim jacket | CASUAL | CASUAL, RELAX | 2 | 34 |
| BOMBER_JACKET | Bomber jacket | CASUAL | CASUAL, RELAX | 2 | 34 |
| BLAZER | Blazer | WORK | WORK, CASUAL | 4 | 34 |
| PARKA | Parka | CASUAL | CASUAL, RELAX | 2 | 34 |
| CASUAL_COAT | Casual coat | CASUAL | CASUAL, WORK | 3 | 34 |
| FORMAL_COAT_OVERCOAT | Formal coat / Overcoat | WORK | WORK, CASUAL | 4 | 34 |
| RAIN_JACKET_WINDBREAKER | Rain jacket / Windbreaker | CASUAL | CASUAL, ACTIVE | 2 | 34 |
| OVERSHIRT_SHIRT_JACKET | Overshirt / Shirt jacket | CASUAL | CASUAL, RELAX | 2 | 34 |
| OTHER_OUTERWEAR | Other outerwear | CASUAL | CASUAL, WORK, RELAX, ACTIVE | 2 | 34 |

### FOOTWEAR type mapping

FOOTWEAR maps to the outfit layer `SHOES`.
Only sport shoes use the sport-shoe threshold of 50 wears.
All other footwear uses the normal-shoe threshold of 25 wears.

| Stored type | Display label | Default occasions | Allowed occasions | Default formality | Condition threshold |
|---|---|---|---|---:|---:|
| SPORT_SHOES | Sport shoes | ACTIVE | ACTIVE, CASUAL | 2 | 50 |
| CASUAL_SNEAKERS | Casual sneakers | CASUAL | CASUAL, RELAX, WORK | 2 | 25 |
| SLIP_ON_SHOES | Slip-on shoes | CASUAL, RELAX | CASUAL, RELAX | 2 | 25 |
| LOAFERS | Loafers | CASUAL, WORK | CASUAL, WORK | 3 | 25 |
| SANDALS | Sandals | CASUAL, RELAX | CASUAL, RELAX | 2 | 25 |
| SLIPPERS_FLIP_FLOPS | Slippers / Flip-flops | RELAX | RELAX, CASUAL | 1 | 25 |
| CASUAL_BOOTS | Casual boots | CASUAL | CASUAL, WORK | 3 | 25 |
| FORMAL_SHOES | Formal shoes | WORK | WORK | 4 | 25 |
| BALLET_FLATS | Flats / Ballet flats | CASUAL, WORK | CASUAL, WORK | 3 | 25 |
| HEELS | Heels | WORK | WORK, CASUAL | 4 | 25 |
| OTHER_SHOES | Other shoes | CASUAL | CASUAL, WORK, ACTIVE, RELAX | 2 | 25 |

Sport shoes use formality 2 for MVP because many users wear them as daily
casual footwear. This can be tuned after user testing if recommendations feel
too sporty.

### OTHERS type mapping

OTHERS items are excluded from Daily Rotation and Outfit Generator.
Their occasion and formality values are stored for consistency, filtering,
insights, donation review, and future expansion, but they do not affect P1b
in MVP.

All OTHERS items use condition threshold 25 wears.

| Stored type | Display label | Default occasions | Allowed occasions | Default formality | Condition threshold |
|---|---|---|---|---:|---:|
| ACCESSORY | Accessory | CASUAL | CASUAL, WORK, ACTIVE, RELAX | 2 | 25 |
| BAG | Bag | CASUAL | CASUAL, WORK, ACTIVE, RELAX | 2 | 25 |
| BELT | Belt | CASUAL, WORK | CASUAL, WORK | 3 | 25 |
| HAT_CAP | Hat / Cap | CASUAL | CASUAL, ACTIVE, RELAX | 2 | 25 |
| SCARF | Scarf | CASUAL | CASUAL, WORK, RELAX | 3 | 25 |
| TIE | Tie | WORK | WORK | 4 | 25 |
| RING_JEWELLERY | Ring / Jewellery | CASUAL | CASUAL, WORK, RELAX | 3 | 25 |
| WATCH | Watch | CASUAL, WORK | CASUAL, WORK, ACTIVE, RELAX | 3 | 25 |
| SUNGLASSES | Sunglasses | CASUAL | CASUAL, ACTIVE, RELAX | 2 | 25 |
| OTHER_ITEM | Other item | CASUAL | CASUAL, WORK, ACTIVE, RELAX | 2 | 25 |

---

## Database Tables

### profiles
```
id                  uuid        primary key, references auth.users.id
email               text
display_name        text
style_preferences   jsonb       { preferred_colours: [], disliked_colours: [] }
laundry_cycle_days  integer     default 3
recommendation_mode text        default 'BALANCED'
created_at          timestamptz
updated_at          timestamptz
```

### items
All fields listed in data model above.

### item_events
```
id            uuid        primary key
item_id       uuid        foreign key → items.id
user_id       uuid        foreign key → profiles.id
event_type    text        'WORN' or 'SKIPPED'
source        text        'DAILY_ROTATION', 'OUTFIT_GENERATOR', 'ITEM_DETAIL', 'MANUAL'
occasion      text        nullable
outfit_log_id uuid        nullable, foreign key → outfit_logs.id
event_at      timestamptz
```

### outfit_logs
```
id              uuid        primary key
user_id         uuid        foreign key → profiles.id
occasion        text
outfit_score    numeric     nullable
source          text        'OUTFIT_GENERATOR' or 'MANUAL'
logged_at       timestamptz
```

### outfit_log_items
```
id              uuid        primary key
user_id         uuid        foreign key → profiles.id
outfit_log_id   uuid        foreign key → outfit_logs.id
item_id         uuid        foreign key → items.id
layer_type      text        'TOP', 'BOTTOM', 'OUTERWEAR', 'SHOES'
```

`layer_type` stores the outfit layer, not the item category. For shoe items,
`layer_type = 'SHOES'` while `item.category = FOOTWEAR`.

**Row Level Security:** Enable on all app tables. Users read and write own rows only.

---

## Status Enum — All Values and Meanings

| Status | Meaning | In wardrobe? | In engine? | In donation scan? |
|---|---|---|---|---|
| IN_WARDROBE | Available and wearable | Yes | Yes | Yes |
| LAUNDRY | Temporarily unavailable | Yes (auto-returns) | No | Yes |
| LENT | Lent to someone | Yes | No | Yes |
| STORED | Physically stored away | Yes | No | Yes |
| DONATED | Confirmed donated | No (in history) | No | No |
| DELETED | Soft deleted by user | No | No | No |

**DELETED behaviour:**
- Status set to DELETED on user confirmation via the confirmation sheet (no undo snackbar)
- Supabase write waits for confirmation before removing from UI
- After the write succeeds: item remains in database as DELETED, invisible everywhere
- `item_events` rows preserved for data integrity
- DELETED items excluded from all list views, counts, and donation scans

**STORED behaviour:**
- First-class visible-but-unavailable status, set via Item Detail "Mark as Stored"
- Excluded from Home / Daily Rotation / Outfit Generator (F4); returns via "Return to Wardrobe"

**KEPT behaviour (not a status):**
- KEPT is not a status. Kept items remain IN_WARDROBE.
- `kept_until` field suppresses item from donation rules D1–D5 only
- Kept items pass F4 normally and can be recommended
- SPS behaves naturally for kept items — skips still count

---

## Add Item — Initial History Handling

```
Step 1:
"Is this item brand new or already owned?"
→ Brand new, never worn
→ Already owned

Condition selection:
→ User selects current condition (1–5)
→ Default = 5 Excellent if unchanged

Step 2 (only if Already owned):
"Have you worn this item before?"
→ Yes, I have worn it before
→ No / not sure

Step 3a (only if Yes, worn before — show all three dropdowns):
→ Approximate last worn
→ Approximate wear count
→ Approximate owned duration

Step 3b (if No / not sure — still no wear history, but ask ownership age):
→ Approximate owned duration
```

### Backend effect by choice

| Choice | Backend effect |
|---|---|
| Brand new, never worn | initial_history_type=BRAND_NEW, is_new_item=true, wear_count=0, last_worn_date=NULL, wear_count_unknown=false, last_worn_unknown=false, initial_usage_age_days=0, NIBS activates |
| Already owned, worn before | initial_history_type=ALREADY_OWNED_WORN, is_new_item=false, uses approximate mapped values for TDS and WFSS |
| Already owned, never worn / not sure | initial_history_type=ALREADY_OWNED_UNWORN, is_new_item=false, wear_count=0, last_worn_date=NULL, wear_count_unknown=false, last_worn_unknown=false, no NIBS; still asks + stores `initial_owned_duration_option` + `initial_usage_age_days` |

For already-owned worn items:
- Approximate last worn maps to `last_worn_date = today - mapped_days`, unless the user selects "I don't remember", then `last_worn_date=NULL` and `last_worn_unknown=true`
- Approximate wear count maps to stored `wear_count`, unless the user selects "I don't remember", then `wear_count=0` and `wear_count_unknown=true`
- Approximate owned duration maps to `initial_usage_age_days`

For already-owned never-worn / not-sure items:
- Approximate owned duration is still asked and maps to `initial_usage_age_days` (and `initial_owned_duration_option`); `wear_count` stays 0 and NIBS does not activate

### Approximate last worn mapping

| User selects | days_since_worn used |
|---|---:|
| This week | 4 days |
| This month | 15 days |
| 1–3 months ago | 60 days |
| 3–6 months ago | 135 days |
| 6+ months ago | 210 days |
| I don't remember | last_worn_unknown = true → TDS fallback 0.50 |

### Approximate wear count mapping

| User selects | wear_count stored |
|---|---:|
| 1–5 times | 3 |
| 6–20 times | 10 |
| 20+ times | 25 |
| I don't remember | wear_count=0, wear_count_unknown = true → WFSS fallback 0.50 until real wear is logged |

### Approximate owned duration mapping

| User selects | initial_usage_age_days |
|---|---:|
| Less than 1 month | 30 |
| 1–3 months | 90 |
| 3–6 months | 180 |
| 6–12 months | 365 |
| 1–2 years | 730 |
| 2+ years | 1095 |
| I don't remember | 365 (safe default) |

---

## Laundry Auto-Return

Runs on every app open. Separate from the rule engine.

```
FOR each item WHERE status == LAUNDRY:
    IF (today - laundry_started_at) >= user.laundry_cycle_days:
        SET status = IN_WARDROBE
        SET laundry_started_at = NULL
```

When user marks item as LAUNDRY: set laundry_started_at = today.
F4 only checks status field — never reads laundry_started_at directly.

---

## Layer 1 — Filter Rules

Runs first on every recommendation request.
Items that fail are removed from the recommendation pool.
Filtered items still appear on Donation page and Insights.
All filters run before any scoring.
All queries exclude status = DELETED automatically.

---

### F1 — Season Filter
**STATUS: DROPPED FROM MVP**
Weather API is extra-time feature. All items treated as available year-round.

---

### F2 — Occasion Filter

```
IF user selected "All":
    → Skip this filter, keep all items

ELSE:
    user_occasion = CASUAL | WORK | ACTIVE | RELAX

    IF item.occasion_tags contains user_occasion:
        → KEEP
    ELSE:
        → REMOVE
```

---

### F3 — Condition Gate

```
IF item.condition == 1:
    → REMOVE from recommendation pool
    → FLAG for disposal review

IF item.condition >= 2:
    → KEEP, no penalty
    → Note: condition 2 items are monitored by D5 for donation flagging
```

---

### F4 — Availability Gate

```
IF item.status == IN_WARDROBE:
    → KEEP

IF item.status == LAUNDRY | LENT | STORED | DONATED | DELETED:
    → REMOVE
```

---

### F5 — Worn-Today Gate

Authored (DECISIONS G2). Applied only on recommendation paths — runs when `now`
is supplied to `applyLayer1Filters`. Pure filter callers omit it and get F2–F4.

```
IF item.last_worn_unknown == true OR item.last_worn_date IS NULL:
    → KEEP (unknown / never worn cannot have been worn today)

ELSE IF item.last_worn_date == today:
    → REMOVE from BOTH Daily Rotation and Outfit Generator pools
      (the wear count survives in the DB; the gate auto-expires at midnight,
       no stored flag)

ELSE:
    → KEEP
```

Log Wear from anywhere → wardrobe invalidates → Daily Rotation re-ranks (the
worn item drops out) and the Generator session resets; the next generation
excludes it for the rest of the day.

---

### Empty Pool Guard (runs after all filters)

```
IF filtered_item_count == 0:
    → Do NOT proceed to Layer 2
    → Determine reason and show specific message:

    All items unavailable (laundry/lent/stored):
    "All your items are currently unavailable.
     Update item status to get suggestions."

    No items match selected occasion:
    "No items match this occasion.
     Try a different occasion or add more items."

    All items condition == 1:
    "All your items are too worn out to recommend.
     Update item condition or add new items."

    All suitable items already worn today (F5):
    "You've already worn everything suitable today.
     Check back tomorrow."

    Empty-pool message priority:
    Show the message for the filter step where the pool first became empty.
    1. Empty after F2 → "No items match this occasion."
    2. Empty after F3 → "All your items are too worn out to recommend."
    3. Empty after F4 → "All your items are currently unavailable."
    4. Empty after F5 → "You've already worn everything suitable today."
```

---

## Layer 2 — Scoring Formulas

Runs on every item that passed Layer 1.
All formulas produce a value between 0.0 and 1.0.
Higher score = item should be recommended more.

---

### S1 — Temporal Decay Score (TDS)

**What it does:** Items not worn for a long time get a higher score.

```
category_active_count = number of IN_WARDROBE items in same category
                        (excludes DELETED, DONATED)
rotation_window_days  = clamp(category_active_count × 1.5, 30, 180)

IF is_new_item == true AND wear_count == 0 AND days_since_added <= 14:
    TDS = 0.50
    (NIBS window active — suppress TDS to prevent double-boost with NIBS)

ELSE IF last_worn_unknown == true:
    TDS = 0.50
    (unknown history — neutral fallback)

ELSE:
    IF last_worn_date is NULL:
        days_since_worn = days_since_added
        (never worn proxy — uses time in app as urgency signal)
    ELSE:
        days_since_worn = today - last_worn_date

    TDS = min(days_since_worn / rotation_window_days, 1.0)

Range: 0.0 (worn very recently) → 1.0 (long unused or never worn)
```

### Rotation window examples

| Active items in category | Rotation window |
|---:|---:|
| 10 or fewer | 30 days (minimum) |
| 20 | 30 days |
| 40 | 60 days |
| 60 | 90 days |
| 100 | 150 days |
| 150+ | 180 days (maximum) |

---

### S2 — Skip Penalty Score (SPS)

**What it does:** Items the user repeatedly rejects get a lower score.

```
IF wear_count == 0 AND skip_count == 0:
    SPS = 1.0
    (no data — no negative signal detected, neutral and correct)

ELSE:
    SPS = 1.0 - (skip_count / (wear_count + skip_count + 5))

Range: ~0.0 (almost always skipped) → 1.0 (never skipped)
```

The +5 smoothing buffer prevents a single early skip from unfairly penalising an item.
This buffered formula is used only in SPS. skip_ratio computed getter uses raw formula (different purpose).

### What counts as a skip

| User action | skip_count increases? |
|---|---|
| Taps Skip Item icon in Outfit Detail | Yes — +1 for that item only |
| Taps Skip Outfit button in Outfit Detail | Yes — +1 for all items in that outfit |
| Taps Skip on Daily Rotation card | Yes — +1 for that item only |
| Scrolls past a card | No |
| Leaves the app | No |
| Opens Outfit Detail but does nothing | No |
| Presses Generate Outfits button | No |

---

### S3 — Wear Frequency Saturation Score (WFSS)

**What it does:** Items worn too frequently get a lower score to give other clothes a chance.

```
IF wear_count_unknown == true:
    WFSS = 0.50
    (unknown history — neutral fallback)

ELSE:
    IF initial_wear_count_option == "I don't remember":
        usage_period_days = max(days_since_added, 1)
        (app-observed wear data only — numerator and denominator match)
    ELSE:
        usage_period_days = max(initial_usage_age_days + days_since_added, 1)

    wear_rate = wear_count / usage_period_days

    IF wear_rate >= 0.20:
        WFSS = 0.10
        (overused — worn more than once every 5 days)
    ELSE:
        WFSS = 1.0 - (wear_rate / 0.20)

    WFSS = clamp(WFSS, 0.10, 1.00)

Saturation point: 0.20 = worn more than once every 5 days
Range: 0.10 (overused) → 1.00 (rarely worn)
```

max(..., 1) prevents divide-by-zero for brand new items on day 0.
initial_usage_age_days prevents already-owned items from appearing overused on day 1 in the app.
For items with unknown initial wear count, once a real wear is logged, WFSS uses app-observed days only so the numerator and denominator describe the same period.

---

### S4 — New Item Boost Score (NIBS)

**What it does:** Brand new never-worn items get a 14-day boost to surface in recommendations.

```
IF wear_count == 0 AND is_new_item == true:

    IF days_since_added <= 7:
        NIBS = 1.0
        (full boost — first week)

    ELSE IF days_since_added <= 14:
        NIBS = (14 - days_since_added) / 7
        (smooth taper: 1.0 at day 7 → 0.0 at day 14)

    ELSE:
        NIBS = 0.0
        (grace period expired — TDS takes over as urgency signal)

ELSE:
    NIBS = 0.0

Grace period: 14 days
```

is_new_item must be true. Already-owned items added during onboarding do NOT receive NIBS.
After item is worn once: wear_count > 0, NIBS permanently deactivates.
Smooth taper prevents sudden score cliff at day 14.
After NIBS expires for an unworn item: TDS uses days_since_added as proxy and naturally increases urgency.

---

### S5 — Preference Score (PS)

**What it does:** Small advantage to items matching user preferences.
Used in Mode A (Balanced Rotation) only. Skipped in Mode B (Pure Rotation).

```
PS = 0.50
(neutral default)

IF item.is_favorite == true:
    PS += 0.20

IF item.color_tags[0] is in user.style_preferences.preferred_colours:
    PS += 0.15

IF item.color_tags[0] is in user.style_preferences.disliked_colours:
    PS -= 0.20

PS = clamp(PS, 0.00, 1.00)

Range: 0.00 → 1.00
```

is_favorite is handled inside PS only. No separate favourite multiplier.
color_tags[0] is the primary colour (first tag set when adding the item).
If a colour appears in both preferred and disliked lists, both adjustments apply.
PS is computed at runtime. Not stored in database.

---

### S6 — Final Recommendation Score (FRS)

**What it does:** Combines all scores into one final number per item.
Items ranked by FRS descending to produce the recommendation list.

#### Mode A — Balanced Rotation

```
FRS = (0.35 × TDS)
    + (0.25 × WFSS)
    + (0.20 × SPS)
    + (0.20 × PS)
    + (0.15 × NIBS)

Weight check: 0.35 + 0.25 + 0.20 + 0.20 = 1.00 ✓
NIBS additive bonus → max FRS = 1.15
```

#### Mode B — Pure Rotation

```
FRS = (0.45 × TDS)
    + (0.30 × WFSS)
    + (0.25 × SPS)
    + (0.15 × NIBS)

Weight check: 0.45 + 0.30 + 0.25 = 1.00 ✓
NIBS additive bonus → max FRS = 1.15
In Pure Rotation: PS is skipped, is_favorite has zero effect
```

#### Tiebreaker

```
IF two items have equal FRS:
    Primary:   sort by last_worn_date ascending
               (NULL = never worn = longest unused, comes first)
    Secondary: sort by days_since_added descending
               (older in wardrobe wins on second tie)
```

---

## Layer 3 — Post-Processing Rules

Runs after FRS ranking. Assembles items into complete outfits.

---

### P1a — Category Completeness (Hard Rule)

```
A valid outfit requires:
    1 × TOP  +  1 × BOTTOM  (minimum, always required)

Optional (user-controlled toggles in Outfit Generator UI):
    OUTERWEAR
    SHOES

IF Outerwear toggle is ON:
    → All generated combinations MUST include an Outerwear item

IF Shoes toggle is ON:
    → All generated combinations MUST include a Shoes item

canAssemble() checks completeness at generation time — toggles are NOT disabled
when a layer has no items. If any required layer (TOP, BOTTOM, or a toggled-ON
OUTERWEAR/SHOES) has no candidate, it returns ONE unified failure message naming
every missing layer:
    "Cannot build outfit — no available [tops/bottoms/outerwear/shoes] for this occasion."

With pinned item:
    → Pinned item satisfies its layer requirement automatically
    → P1a only checks remaining required layers (same unified message on failure)
```

P1a is NOT about keeping combinations unique. That is handled by session_excluded_combinations.

---

### P1b — Formality Matching (Hard Rule)

```
max_formality = MAX(formality_level of all items in current outfit)
min_formality = MIN(formality_level of all items in current outfit)

IF (max_formality - min_formality) <= 1:
    → ACCEPT combination

IF (max_formality - min_formality) > 1:
    → REJECT
    → Find most mismatched item:
         avg_f = AVERAGE(formality_level of all items in outfit)
         target = item with MAX(ABS(formality_level - avg_f))
         Tiebreaker: if equal distance, target item with HIGHER formality level
         Pinned items are NEVER targeted for swapping

    → Try each candidate in same category as target, sorted by FRS descending:
         IF replacing target with candidate results in diff <= 1:
             → Make swap, ACCEPT → stop

    → If no valid candidate in same category:
         → Target second most mismatched item, repeat

    → Max 20 total retry attempts across all swaps
    → If still no valid combination after 20 attempts:
         → Accept best available (loose == true)
         → Surfaced by the "Loose" / "Loose formality" badge only — display-only,
           no snackbar or message

    → After P1b finishes, recompute final outfit tuple:
         IF final tuple is in session_excluded_combinations:
             → REJECT combination
         IF final tuple duplicates another valid combination already produced:
             → Keep only the higher OutfitScore version
```

### Formality examples

```
T-shirt (2) + Jeans (2) + Sneakers (2): diff=0 → ACCEPT
Button-down (3) + Chinos (3) + Trainers (3): diff=0 → ACCEPT
Dress shirt (4) + Chinos (3) + Oxford (4): diff=1 → ACCEPT
Dress shirt (4) + Jeans (2) + Oxford (4): diff=2 → REJECT
    → Most mismatched: Jeans (2), furthest from avg 3.33
    → Try Bottom-B (3): diff = 4-3 = 1 → ACCEPT
Gym shorts (1) + Smart shirt (3): diff=2 → REJECT
    → Most mismatched: Gym shorts (1), avg = 2.0, distance = 1
    → Try Bottom-B (2): diff = 3-2 = 1 → ACCEPT
    → No other bottoms: target Smart shirt next
    → Try Top-B (2): diff = 2-1 = 1 → ACCEPT
    → No alternatives anywhere: accept best available (loose == true), surfaced
      by the "Loose" / "Loose formality" badge only (no snackbar/message)
```

The engine is unchanged. When a combination is accepted best-available
(loose == true), a cosmetic "Loose formality" badge is shown on the outfit card
(display only — it does not affect ranking).

---

### P1c — Colour Compatibility Score

Used inside OutfitScore. Not a hard block on its own.
Uses color_tags[0] (primary colour) of each item.

The 12×12 colour-compatibility matrix is authored in code
(`core/constants/colour_compatibility.dart`, plan M1) from the colour groups
and bands below. Same-colour (monochrome) diagonal is tiered: achromatic
(black/white/grey/beige) 0.80, coloured-neutral (navy/brown) 0.70, bright
chromatic 0.65. 0.70 is an authored intermediate value, not one of the six
bands.

### Pairs evaluated

```
Top ↔ Bottom         (always evaluated — most visible pairing)
Top ↔ Outerwear      (only if Outerwear present)
Bottom ↔ Shoes       (only if Shoes present)
Outerwear ↔ Shoes    (only if both present)
```

### Pair score table

| Colour relationship | Score |
|---|---:|
| Strong safe match | 1.00 |
| Good match | 0.90 |
| Acceptable / neutral | 0.80 |
| Too similar but wearable | 0.65 |
| Weak / awkward | 0.50 |
| Known clash | 0.30 |

### Colour groups

| Group | Colours |
|---|---|
| Neutral | black, white, grey, beige, navy, brown |
| Earth | beige, brown, olive, cream |
| Cool | blue, navy, green, grey |
| Warm | red, orange, yellow, pink, brown |
| Accent | red, orange, yellow, pink, purple |

### Scoring rules

```
neutral + most colours = 0.80 to 1.00
same colour family = 0.80
too many strong accents together = 0.50
known clash pair = 0.30

ColorCompatibilityScore = average(all evaluated pair scores)
```

### Behaviour thresholds

ColorCompatibilityScore is never a hard reject on its own. It feeds OutfitScore
(0.30 weight) and the final ordering is handled by P1D Tier-Priority Reorder,
which uses a 0.40 colour cut-line to separate acceptable from weak colour within
each formality tier. The bands are used for display warnings only:

```
ColorCompatibilityScore >= 0.60   → Normal outfit, no warning
ColorCompatibilityScore 0.40–0.60 → Allow, show colour warning
ColorCompatibilityScore < 0.40    → Weak colour; enters the weak-colour tiers
                                     in P1D (T2 if formality matched, T4 if
                                     loose). A matched weak-colour outfit (T2)
                                     still ranks ABOVE a loose compatible-colour
                                     outfit (T3) — it is not pushed to the bottom.
```

### Concrete example

```
Outfit: White Top + Navy Bottom + Brown Shoes (no Outerwear)

Pairs:
  Top ↔ Bottom:   White (neutral) + Navy (neutral) = Strong match → 1.00
  Bottom ↔ Shoes: Navy (cool) + Brown (neutral) = Acceptable → 0.80

ColorCompatibilityScore = (1.00 + 0.80) / 2 = 0.90 → No warning ✓
```

---

### OutfitScore

**What it does:** Ranks full outfit combinations after assembly.

```
AverageItemFRS = average(FRS of all items in the outfit)

OutfitScore = (0.70 × AverageItemFRS)
            + (0.30 × ColorCompatibilityScore)

Weight check: 0.70 + 0.30 = 1.00 ✓

Display: min(round(OutfitScore × 100), 100)
         (capped at 100 for display only — internal score unchanged)
         (max internal OutfitScore = ~1.105 when NIBS items present)

Ranking always uses internal OutfitScore (not capped display value)
```

0.70 on FRS: wardrobe rotation is the primary purpose.
0.30 on colour: compatibility matters but is not the main point.

---

### P1D — Tier-Priority Reorder

Runs after OutfitScore ranking and de-duplication. It reorders the full ranked
list so formality outranks colour: a clean formality match is always preferred
over a better colour palette. The colour SCORE computation (pairs + averages)
and the OutfitScore formula are UNCHANGED — only the ordering changed.

```
After OutfitScore-descending sort + de-dup, split into 4 tiers:
    T1: formality matched   AND ColorCompatibilityScore >= 0.40
    T2: formality matched   AND ColorCompatibilityScore <  0.40
    T3: formality loose     AND ColorCompatibilityScore >= 0.40
    T4: formality loose     AND ColorCompatibilityScore <  0.40

Within each tier, preserve OutfitScore-descending order.
Return the full concatenated list T1 → T2 → T3 → T4.
```

The full list (not just the top 3) is returned so T/B uniqueness, backfill, and
skip replacement can iterate the whole pool. "loose" means P1b accepted a
best-available formality after exhausting swaps.

---

## Outfit Detail Explainability Rules

Outfit Detail explainability is a display-only layer.
It explains why an already-generated outfit was shown.
It does not change Layer 1 filtering, Layer 2 item scoring, Layer 3 outfit
assembly, OutfitScore, sorting, ranking, skip replacement, or database data.

Explanation text is computed fresh at runtime from current item data and
computed scores. Explanation strings are not stored in the database.

```
OutfitExplanation {
    score_message
    why_reasons[]
    rule_breakdown[]
}
```

Inputs available to OutfitExplanation:
```
Selected occasion
Pinned item, if any
Item-level TDS, SPS, WFSS, NIBS
Final formality result from P1b
ColorCompatibilityScore
OutfitScore display score
```

If a future Outfit History detail page is added from `outfit_logs`, explanation
snapshot storage must be reconsidered. For MVP, OutfitExplanation applies to
currently generated outfits only.

### Why this outfit?

The "Why this outfit?" card gives a short friendly summary of why the outfit
was suggested. It must stay positive and user-readable.

```
Maximum reasons shown: 4
Minimum reasons shown: 2 where possible
Reason type: positive reasons only
Selection rule: evaluate all matching reasons, then show the first 4 by priority
```

Reason priority and triggers:

| Priority | Reason | Trigger |
|---:|---|---|
| 1 | "Built around [item name]" | Outfit generated with pinned item from Build Outfit |
| 2 | "Matches [occasion] occasion" | Selected occasion is not All |
| 3 | "Includes a new item before it gets forgotten" | Any outfit item has NIBS > 0 |
| 4 | "Strong rotation priority" | Temporal Decay badge is High Rotation |
| 5 | "No frequent skip pattern detected" | Skip Penalty badge is Clear |
| 6 | "No overused items in this outfit" | Wear Balance badge is Balanced |
| 7 | "Formality levels match" | Formality Match badge is Matched |
| 8 | "Colour palette is compatible" | Colour Compatibility badge is Strong or Compatible |

Special cases:
```
IF selected occasion == All:
    Do not show "Matches [occasion] occasion"

IF pinned item exists:
    "Built around [item name]" is first reason

IF fewer than 2 reasons match:
    Add fallback reason:
    "Recommended based on wardrobe rotation score"
```

Negative or warning-style messages do not appear in "Why this outfit?".
Weak colour, colour fallback, loose formality, skip penalty, or overused warnings
belong in Rule Breakdown instead.

### Rule Breakdown

Rule Breakdown gives technical-but-readable evidence for the generated outfit.
It uses the same formulas already computed by the engine.

Rows shown:
```
Temporal Decay
Skip Penalty
Wear Balance
Formality Match
Colour Compatibility
```

Each row contains:
```
Rule name
Short row description
Badge
```

Item-level rule rows use outfit averages:
```
avgTDS  = average(TDS of all outfit items)
avgSPS  = average(SPS of all outfit items)
avgWFSS = average(WFSS of all outfit items)
```

The average divisor is always the actual outfit item count. This supports
2-item, 3-item, and 4-item outfits without special cases.

#### Temporal Decay row

```
IF avgTDS >= 0.65:
    Badge: "High Rotation"
    Description: "Outfit has strong rotation priority"

ELSE IF avgTDS >= 0.35:
    Badge: "Medium Rotation"
    Description: "Outfit has moderate rotation priority"

ELSE:
    Badge: "Low Rotation"
    Description: "Most items were worn recently"
```

#### Skip Penalty row

```
IF avgSPS >= 0.85:
    Badge: "Clear"
    Description: "No frequent skip pattern detected"

ELSE IF avgSPS >= 0.60:
    Badge: "Minor Skips"
    Description: "Some items have been skipped before"

ELSE:
    Badge: "Penalty"
    Description: "One or more items are often skipped"
```

#### Wear Balance row

```
IF avgWFSS >= 0.70:
    Badge: "Balanced"
    Description: "No overused items in this outfit"

ELSE IF avgWFSS >= 0.40:
    Badge: "Moderate"
    Description: "Some items are worn more often than others"

ELSE:
    Badge: "Overused"
    Description: "One or more items are worn very frequently"
```

#### Formality Match row

```
IF final outfit formality difference <= 1:
    Badge: "Matched"
    Description: "Items are within 1 formality level"

ELSE IF P1b accepted best available after retry limit:
    Badge: "Loose"
    Description: "Best available formality match"
```

#### Colour Compatibility row

```
IF ColorCompatibilityScore >= 0.80:
    Badge: "Strong"
    Description: "Colour palette has strong matching pairs"

ELSE IF ColorCompatibilityScore >= 0.60:
    Badge: "Compatible"
    Description: "No clashing colour pairs detected"

ELSE IF ColorCompatibilityScore >= 0.40:
    Badge: "Weak"
    Description: "Some colour pairs may feel less compatible"

ELSE:
    Badge: "Fallback"
    Description: "Used only because few alternatives were available"
```

`Fallback` marks outfits with weak colour (ColorCompatibilityScore < 0.40),
which P1D places in T2 (formality matched) or T4 (loose). They are no longer
hard-rejected; a matched weak-colour outfit (T2) still ranks above a loose
compatible-colour outfit (T3).

### Score sentence

The short sentence below the outfit score is generated from the display score
band plus the strongest positive reason.

Score band:
```
90-100  -> "Strong outfit"
80-89   -> "Balanced outfit"
70-79   -> "Good outfit"
60-69   -> "Acceptable outfit"
0-59    -> "Backup outfit"
```

Reason suffix priority:
```
1. with strong rotation priority
2. with a new item included
3. with no frequent skip pattern
4. with balanced wear
5. with matched formality
6. with compatible colours
```

If no positive suffix condition matches, display the score band sentence alone.

Examples:
```
"Strong outfit with compatible colours."
"Balanced outfit with strong rotation priority."
"Good outfit with no frequent skip pattern."
"Acceptable outfit with matched formality."
```

Never display "Perfect outfit", even when the display score is 100.
Use "Strong outfit" for the highest score band.

---

## Outfit Generator — Full Behaviour

### Outfit eligibility (enforced at generation by P1a)

The Generate button is NOT pre-disabled by item counts — it is enabled except
while a generation/skip is in flight (isGenerating). Completeness is enforced at
generation time by P1a / canAssemble(); on failure the result is shown inline as
a failure card. There is no startup/status-change pre-check and no per-layer
button disabling.

```
Hard minimum (canAssemble):
    >= 1 TOP  AND  >= 1 BOTTOM
    + >= 1 item in each toggled-ON layer (Outerwear / Shoes)

With a pinned item:
    The pinned item's own layer is already satisfied; the other required layers
    use the same >= 1 rule.

Higher counts are NOT an eligibility gate — they only affect variety:
    Top/Bottom uniqueness across the initial 3 cards needs >= 3 tops AND
    >= 3 bottoms (otherwise uniqueness is off; see "Top and Bottom uniqueness").
```

On failure, P1a reports ALL missing required layers in a single message:
"Cannot build outfit — no available [tops/bottoms/outerwear/shoes] for this occasion."

### Candidate Pool Type Filter

An optional per-layer type filter, opened from the "Filter" button next to the
LAYERS header (Type Filter sheet). It narrows each active layer's candidate pool
to a single stored type before ranking.

```
selectedTypes = { category → stored type }   (absent key = no filter for that layer)

Applied inside pool building (poolFor), AFTER FRS sort and the pinned formality
pre-filter but BEFORE take(8), so the cap never hides the filtered type when an
unfiltered type is more numerous.

Which filter-change actions clear filters:
    → Occasion change → clears ALL type filters (available types per occasion
      differ, so stale filters would silently empty pools)
    → Toggling a layer OFF → clears ONLY that layer's filter
    → Setting a pin → clears ONLY the pinned category's filter (the pin IS that
      slot)
    → Any wardrobe mutation → clears all type filters (full session reset)

Type filters are otherwise PRESERVED. In particular, a confirmed no-pin filter
change clears the generated CARDS (session reset, hasGenerated = false) but
KEEPS selectedTypes — only an action in the list above clears the filters
themselves. Unpinning also preserves filters.

IF a type filter empties a required slot that otherwise had candidates:
    → Show: "No items match your type filter. Try changing or clearing your
      filters." (shown before the generic P1a / pinned-formality messages)
```

When a pin and a type filter coexist on different layers, the pinned formality
pre-filter is skipped for a layer that has its own type filter — the user
explicitly chose that type, so P1b resolves any formality gap (loose == true).

### Start Over

Replaces the old "Regenerate" / "Clear and regenerate" action.

```
"Start Over":
    → Confirm, then clear the session (excluded items/combinations, shown
      tops/bottoms, hasGenerated = false)
    → KEEP the pin and all filters
    → User taps "Generate" again to produce a fresh set

All Generator guards key on hasGenerated, not outfits.isNotEmpty (so the
"no more combinations" empty state is still treated as an active session).
Card highlight badges are sorted good > medium > bad.
```

### Pinned item behaviour

When user arrives via Build Outfit from Daily Rotation, Wardrobe, or Item Detail:

```
Build Outfit button availability (Wardrobe card / Item Detail):
    Enabled only when item.status == IN_WARDROBE.
    IF item.status != IN_WARDROBE:
        → "Build Outfit" button disabled (greyed)

    IF item.category == OTHERS:
        → Blocked centrally in openGeneratorWithPin (OTHERS has no outfit
          layer): shows "This item cannot be used to build an outfit." and
          returns. OTHERS items can still Log Wear.

    condition == 1 and worn-today (F5) are NOT blocked at the button — such an
    IN_WARDROBE item can still be tapped/pinned. They are handled by the engine
    safety net at generation time (Step 0 below), which auto-unpins them.

Pinned item = specific item locked into its layer for this session

Occasion chip behaviour:
    → Disable (grey, ~50% opacity) all occasion chips NOT in
      pinned_item.occasion_tags
    → Disabled chips are NOT tappable (no tooltip, no snackbar — tapping does
      nothing)
    → IF currently selected occasion not in pinned_item.occasion_tags:
         → Silently auto-switch to the first tag in pinned_item.occasion_tags
           (no snackbar)
    → The pinned item's own layer toggle (outerwear/shoes) is locked ON
    → IF pinned item has all 4 occasion tags: nothing disabled, all selectable
    → IF user removes pin: restore all occasion chips, keep current occasion

Generation with pinned item:
    → Pinned item is locked in its layer
    → Only candidates for OTHER layers are generated
    → All other candidates pre-filtered by formality in Step 0
    → Pinned item NEVER targeted for P1b swaps
    → Combinations = 1 × other_layer_candidates × ...
    → If only 2 valid combinations: show 2, not 3 — acceptable for small wardrobes
```

### Generation flow (full — no pinned item)

#### Outfit layer to item category mapping

```
TOP       → TOP
BOTTOM    → BOTTOM
OUTERWEAR → OUTERWEAR
SHOES     → FOOTWEAR
```

Outfit layers are user-facing outfit slots. Item categories are stored in the database.
Pool building must use `categoryForLayer(layer)`, not direct string equality.

```
Step 1: Run Layer 1 filters (F2, F3, F4, F5 worn-today) on all items
Step 2: Run Layer 2 scoring (FRS) on all passing items
Step 3: Build candidate pools per layer

    FOR each required layer (TOP, BOTTOM, and OUTERWEAR/SHOES if toggled ON):
        pool[layer] = items that passed Layer 1
                      WHERE item.category == categoryForLayer(layer)
                      AND item NOT IN session_excluded_items
                      SORTED by FRS descending
                      TAKE top min(count, 8) items

    Each pool contains up to 8 items sorted by FRS descending.
    Pool size is dynamic — if fewer than 8 available, use all available.
    Excluded items are removed at pool-building time so they never waste pool slots.

    IF initial_generation_done == false:
        IF COUNT(pool[TOP]) >= 3 AND COUNT(pool[BOTTOM]) >= 3:
            use_tb_uniqueness = true
        ELSE:
            use_tb_uniqueness = false
    (if initial_generation_done == true: skip this calculation entirely)

Step 4: Generate all valid unique combinations

    combinations = []

    FOR each top in pool[TOP]:
      FOR each bottom in pool[BOTTOM]:
        FOR each outerwear in pool[OUTERWEAR] (only if Outerwear toggled ON):
          FOR each shoes in pool[SHOES] (only if Shoes toggled ON):

            outfit = assembled combination of selected items

            IF any item in outfit is in session_excluded_items:
                → SKIP — item was explicitly skipped this session

            IF outfit tuple (item_ids) is in session_excluded_combinations:
                → SKIP — same combination already on screen this session

            IF any item_id appears more than once across outfit slots:
                → SKIP — self-pairing protection
                  (cannot trigger in MVP since each item has one category,
                   but guard is required for dual-role enhancement later)

            combinations.append(outfit)

    Result: list of all valid unique combinations for this session

Step 5: Apply P1a (category completeness check)
Step 6: Apply P1b (formality matching, max 20 retries)
Step 7: Calculate ColorCompatibilityScore per combination
Step 8: Calculate OutfitScore per combination
Step 8.5: Calculate OutfitExplanation per combination
          (display-only; does not affect sorting or ranking)

Step 9: Sort valid_combinations by OutfitScore descending

    IF initial_generation_done == false AND use_tb_uniqueness == true:
        selected = []
        FOR each combination in sorted list:
            IF top.id NOT in session_shown_tops
               AND bottom.id NOT in session_shown_bottoms:
                → Add combination to selected
                → Add top.id to session_shown_tops
                → Add bottom.id to session_shown_bottoms
            ELSE:
                → SKIP — top or bottom already used in another initial card
            IF COUNT(selected) == 3: STOP

        IF COUNT(selected) < 3:
            → BACKFILL: restart from top of sorted list ignoring uniqueness
            FOR each combination in sorted list:
                IF combination already in selected: SKIP
                IF combination in session_excluded_combinations: SKIP
                → Add to selected
                IF COUNT(selected) == 3: STOP

        final_outfits = selected

    ELSE:
        → Take top 3 (or fewer if less available) from sorted list
        final_outfits = top 3 from sorted list

Step 10: Show final_outfits on screen
         → Add each shown combination to session_excluded_combinations
         SET initial_generation_done = true
         SET use_tb_uniqueness = false

After replacement generation (skip triggered):
         → Sort all currently displayed cards by OutfitScore descending
         → Apply smooth animation for card repositioning
```

### Generation flow (with pinned item)

Pre-condition (Wardrobe card / Item Detail, before the Outfit Generator):
```
Build Outfit is enabled only when item.status == IN_WARDROBE:
    IF item.status != IN_WARDROBE:
        → "Build Outfit" button disabled (greyed)

IF item.category == OTHERS:
    → Blocked centrally in openGeneratorWithPin (message + return)

condition == 1 and worn-today (F5) are NOT gated at the button — the engine
handles them in Step 0 (auto-unpin: 0a condition, 0b status, 0b2 worn-today).
```

```
Step 0 (runs ONLY if pinned_item exists):

    a. F3 safety check (engine safety net — condition-1 is NOT blocked at the
       Build Outfit button):
       IF pinned_item.condition == 1:
           → Auto-unpin
           → Proceed to normal generation without pinned item
           → Exit Step 0

    b. F4 safety check (same combined engine guard as 0a):
       IF pinned_item.status != IN_WARDROBE:
           → Auto-unpin (silently)
           → Proceed to normal generation without pinned item
           → Exit Step 0

    b2. F5 worn-today safety check (same combined engine guard):
        IF pinned_item was worn today (!last_worn_unknown AND
           last_worn_date == today):
           → Auto-unpin (silently)
           → Proceed to normal generation without pinned item
           → Exit Step 0
        Without this, the pinned slot returns the pin directly and would bypass
        the F5 gate that already removes worn-today items from the normal pool.

    c. Occasion already constrained at UI level via grayed chips
       → No F2 engine check needed for pinned item

    d. Lock pinned item in its layer
       → Remove pinned item's category from normal candidate generation
       → Engine only generates candidates for other layers

    e. Formality pre-filter (new simple function — NOT P1b):
       This runs on individual items BEFORE any combinations are built.
       P1b runs AFTER combinations are built. They are complementary, not duplicate.

       FOR each candidate item in non-pinned layers:
           IF ABS(candidate.formality_level - pinned_item.formality_level) > 1:
               → Remove candidate from that layer's pool

       Why only for pinned generation:
           Pinned item is a fixed anchor — its formality sets the range.
           Without a pinned item there is no anchor, so no pre-filter is possible.
           P1b handles non-pinned formality checking after assembly.

       IF any required layer has zero candidates remaining after pre-filter:
           → Show: "Cannot find items matching [PinnedItemName]'s formality"
           → Offer button: "Remove pin and generate freely"
           → Stop generation until user decides

    f. Minimum threshold:
       → Pinned item's layer: threshold already satisfied
       → All other required layers: normal thresholds apply

Step 1-10: Same as normal flow with these differences:
           Step 3: Pinned item's layer pool = [pinned_item only] (single item, no candidates)
                   All other layer pools built normally from FRS-ranked candidates
           Step 4: All combinations include pinned_item in its locked slot
                   Self-pairing check still runs (pinned item cannot appear in other slots)
           Step 6: Pinned item EXEMPT from P1b swapping
           Step 8.5: OutfitExplanation includes "Built around [item name]"
                     as the first Why this outfit reason
           P1b still runs as final safety net but finds very little to fix
           because Step 0 pre-filter already removed formality mismatches
```

### After a generation (button state)

Once hasGenerated == true, the primary "Generate Outfit" button is replaced by
an outlined "Start Over" button — there is no second "Generate" action to press
while outfits are shown. To get different outfits the user skips a card (in-place
replacement) or taps Start Over. (The engine's generate() is idempotent if called
again — it returns the current outfits — but the UI does not expose that path.)

### Filter change while outfits are shown (G1)

A filter change (occasion, layer toggle, or type filter) applies the field
update, then resets the session via the confirm flow below. The SAME rule
applies to pinned and non-pinned sessions — it keys on hasGenerated, with no
silent pinned-session staging (Phase 10 `_changeFilter`).

```
Nothing generated yet (hasGenerated == false):
    → Apply the filter directly, no warning

Outfits already on screen (hasGenerated == true, pinned OR not):
    → Show confirm: "This will clear your current generated outfits and skipped
      items for this session." (confirm label "Change Filters")
    → Confirm = apply the new filter + clearGenerated() (cards cleared, button
      returns to "Generate Outfit"; user re-taps Generate — no auto-generation)
    → Cancel  = keep the current cards and the previous filter

    Type filters are preserved across this card-clear ONLY when the applied
    filter change does not itself clear them: an occasion change clears ALL type
    filters, and toggling a filtered layer OFF clears that layer's filter (see
    "Candidate Pool Type Filter"). Any other change keeps them.
```

Independently of the reset rule, while a pin is set: the pin's own optional
layer is locked ON (cannot be toggled off) and occasion chips are limited to the
pinned item's occasion_tags.

### Top and Bottom uniqueness across initial outfit cards

For the initial 3 cards, when `COUNT(pool[TOP]) >= 3 AND COUNT(pool[BOTTOM]) >= 3`,
the engine enforces that each top AND each bottom appears in at most one initial card.
This means no top repeats and no bottom repeats across the 3 initial cards.
Outerwear and shoes can still repeat freely across cards in all cases.
After any skip, uniqueness is off — items can repeat in replacement cards.

```
Examples with uniqueness ON (enough tops and bottoms):
Card 1: T1 + B1 + O1 + S1
Card 2: T2 + B2 + O1 + S2   ← O1 repeats, allowed
Card 3: T3 + B3 + O2 + S1   ← S1 repeats, allowed
(T1, T2, T3 each appear once — B1, B2, B3 each appear once)

Examples with uniqueness OFF (small wardrobe):
Card 1: T1 + B1 + O1 + S1
Card 2: T1 + B2 + O1 + S1   ← T1 repeats, allowed when uniqueness off
Card 3: T2 + B1 + O1 + S1   ← B1 repeats, allowed when uniqueness off
```

Why outerwear and shoes are allowed to repeat:
    Outerwear and shoes are styling layers. Seeing the same jacket in two
    different outfits is useful — it shows multiple ways to use it.
    The core outfit identity comes from the top and bottom pairing.

Why it is safe:
    Cascade removal ensures skipping one item removes it from ALL outfit cards
    simultaneously. No outfit ever shows a skipped item.
    session_excluded_combinations prevents any exact combo from appearing twice.

### Skip behaviour — outfit card replacement

```
Session state:
    session_excluded_items:        items explicitly skipped (append-only, never removed mid-session)
    session_excluded_combinations: combinations currently displayed on screen
                                   (added when card shown, removed when card leaves screen)
    session_shown_tops:            top item ids shown in initial 3 cards
    session_shown_bottoms:         bottom item ids shown in initial 3 cards
    initial_generation_done:       false = initial generation, true = replacement generation
    use_tb_uniqueness:             true if tops >= 3 AND bottoms >= 3 on initial gen, false otherwise

When user skips (Skip Item or Skip Outfit):
    Step 1: Show blocking loading state
            → Background cannot be interacted with until replacement finishes
    Step 2: Sync skip_count update to Supabase
    Step 3 (on Supabase success):
        → Exit Outfit Detail, return to Generated Outfits page

        CASCADE REMOVAL — runs before any replacement generation:
        → Add skipped item(s) to session_excluded_items
        → Scan ALL currently displayed outfit cards on screen
        → Any card containing ANY session_excluded_item → mark for removal
        → Remove ALL marked cards simultaneously (not just the skipped one)
        → Remove each removed card's combination from session_excluded_combinations
        → Show "[Item name] removed from affected outfits" if more than 1 removed

        REPLACEMENT GENERATION:
        → Count empty slots (1 or more, depending on cascade)
        → Re-run engine once for all empty slots together:
             session_excluded_items removed from candidate pool
             session_excluded_combinations (currently displayed) excluded from results
             initial_generation_done == true → no T+B uniqueness check
             OutfitExplanation calculated for each replacement combination
        → Generate replacements only until 3 outfit cards are present again
        → Do not show more than 3 outfit cards
        → Add each new replacement card's combination to session_excluded_combinations
        → If fewer replacements available than empty slots:
             Fill available slots, show "No more combinations" in remaining slots

    Step 4 (on Supabase failure):
        → Stay on Outfit Detail screen
        → Clear loading indicator
        → Show snackbar: "Couldn't save. Check your connection."
        → User can try again

When no more valid combinations exist:
    → Show: "You've gone through all combinations. Tap 'Start Over' to reset."
    → Offer: "Start Over"
    → Pressing it: clears the session (keeps pin + filters, sets
      hasGenerated = false); user taps Generate again
```

### Skip item vs skip outfit

```
Skip Item (icon on individual item in Outfit Detail):
    → +1 skip_count on that item only
    → Item added to session_excluded_items
    → Cascade removal scans all outfit cards for that item
    → All affected cards removed simultaneously
    → Removed cards' combinations removed from session_excluded_combinations
    → Replacement(s) generated for all empty slots
    → New replacement combinations added to session_excluded_combinations

Skip Outfit (button at bottom of Outfit Detail):
    → +1 skip_count on ALL items in that outfit
    → All items added to session_excluded_items
    → Cascade removal scans all outfit cards for each of those items
    → All affected cards removed simultaneously
    → Removed cards' combinations removed from session_excluded_combinations
    → Replacement(s) generated for all empty slots
    → New replacement combinations added to session_excluded_combinations
```

### Session state lifecycle (G1)

This overrides the earlier "clear on every occasion/layer change" model.
Filter changes are guarded by hasGenerated (see "Filter change while outfits are
shown"): if an active session exists — pinned or not — a confirmation appears,
and confirm calls clearGenerated(). The session is reset only by the events
below.

```
Session reset — all state back to initial values:
    session_excluded_items        = empty set
    session_excluded_combinations = empty set
    session_shown_tops            = empty set
    session_shown_bottoms         = empty set
    initial_generation_done       = false
    use_tb_uniqueness             = UNSET

Session reset when:
    → Opening the Outfit Generator tab for the first time
    → Setting OR clearing a pin (fresh context; also clears that slot's filter)
    → A filter change (pinned or not) is confirmed while hasGenerated (clears
      the generated cards only)
    → Any wardrobe mutation elsewhere (add/edit/delete/donate/status/logWorn/
      Daily-Rotation skip) — this ALSO clears the pin
    → Generator Log Wear / Log Outfit — ends the session and clears the pin
    → "Start Over" is tapped (keeps pin + filters)
    → App is closed and reopened

Session preserved:
    → Navigating to another tab and returning
    → Opening Outfit Detail and returning
    → A Generator Skip Item / Skip Outfit (cascade-replace; pin kept)
    → No mutation has occurred

OutfitGeneratorProvider listens to WardrobeProvider. A settled wardrobe refresh
resets the session + clears the pin, EXCEPT the generator's own skip, which sets
a one-shot preserve guard so the current session survives.
```

---

## Daily Rotation — Backend Behaviour

Daily Rotation recommends individual items, not full outfits.

```
Step 1: Run Layer 1 filters (F2 if occasion selected, F3, F4, F5 worn-today)
        Exclude category == OTHERS
Step 2: Run Layer 2 scoring (FRS) for all passing items
Step 3: Sort by FRS descending
Step 4: Show top items per category or overall (based on UI filter chips)
```

### Actions

| Action | Backend effect |
|---|---|
| Wear | wear_count += 1, last_worn_date = today, last_worn_unknown=false, wear_count_unknown=false, insert `item_events` row (WORN) |
| Skip | skip_count += 1, insert `item_events` row (SKIPPED, DAILY_ROTATION) |
| Build Outfit | Opens Outfit Generator with item pinned in its layer |

### Skip scope (G3)

The two skips are deliberately separate and never bleed into each other:

```
Daily Rotation Skip:
    → skip_count += 1
    → DAY-SCOPED hide from Daily Rotation only (DB-backed via today's
      SKIPPED / DAILY_ROTATION events; survives restart, resets at midnight)
    → Does NOT hard-block the Outfit Generator

Outfit Generator Skip (Skip Item / Skip Outfit):
    → skip_count += 1
    → Removed from the CURRENT generator session + cascade-replace
    → Session-scoped only — may reappear in Daily Rotation (soft, lower score)
      and in a fresh generation

Wear / Log Wear (anywhere):
    → Hard-excludes from BOTH for the rest of the day (F5)
```

### Daily Rotation Display Logic

Daily Rotation card labels are display-only.
They explain the item card shown to the user.
They do not change filtering, FRS, sorting, ranking, or database data.

Daily Rotation priority label is not the same as Item Badge Labels.
The priority label explains why the item appears in Daily Rotation.
Item badges still come from `computeAllBadges(item)`.

```
Score = FRS display score
Priority label = main recommendation reason
Last worn label = factual recency
Wear status label = factual usage pattern
Wear count label = factual wear count
```

### Daily Rotation score

```
display_score = min(round(FRS * 100), 100)
```

### Daily Rotation priority label

```
IF NIBS > 0:
    "New Item"

ELSE IF TDS >= 0.70:
    "High Rotation Priority"

ELSE IF TDS >= 0.35:
    "Medium Rotation Priority"

ELSE:
    "Low Rotation Priority"
```

Priority label meaning:
```
New Item                -> item is inside active NIBS window
High Rotation Priority  -> item has strong recency/rotation need
Medium Rotation Priority -> item has moderate recency/rotation need
Low Rotation Priority   -> item was worn recently or has low rotation need
```

### Last worn label

```
IF last_worn_unknown == true:
    "Last worn unknown"

ELSE IF last_worn_date IS NULL:
    "Never worn"

ELSE:
    "Last worn: [X]d ago"
```

### Wear status label

Uses the canonical wear_rate (itemWearRate — includes initial_usage_age_days
unless initial_wear_count_option == "I don't remember"). "Overused" requires the
shared evidence floor isOverusedRate (wear_rate >= 0.20 AND wear_count >= 3), so
a high rate from 1–2 wears reads "Balanced wear", not "Overused".

```
IF wear_count_unknown == true:
    "Usage unknown"

ELSE IF wear_count == 0:
    "Never worn"

ELSE IF isOverusedRate (wear_rate >= 0.20 AND wear_count >= 3):
    "Overused"

ELSE IF wear_rate < 0.05:
    "Rarely worn"

ELSE:
    "Balanced wear"
```

### Wear count label

```
IF wear_count_unknown == true:
    "Wears unknown"

ELSE IF wear_count == 1:
    "1 wear"

ELSE:
    "[wear_count] wears"
```

Example displays:
```
Score 94
High Rotation Priority
Last worn: 14d ago
Rarely worn - 3 wears

Score 85
New Item
Never worn
Never worn - 0 wears

Score 88
Medium Rotation Priority
Last worn: 9d ago
Balanced wear - 8 wears

Score 76
Low Rotation Priority
Last worn unknown
Usage unknown - Wears unknown
```

Minimum threshold does NOT apply to Daily Rotation — single items, no combinations.

---

## Visual Treatment for Unavailable Items

Shown on item cards in all list views (Wardrobe, Donation, Insights).

| Status | Visual Treatment | Label |
|---|---|---|
| LAUNDRY | 50% gray overlay on photo, overlaps badges | "In Laundry" |
| LENT | 50% gray overlay on photo, overlaps badges | "Lent Out" |
| STORED | 50% gray overlay on photo, overlaps badges | "Stored Away" |
| IN_WARDROBE + kept_until active | No overlay — item is fully wearable | Normal item |
| DONATED | Not shown in wardrobe — only in Donation History | — |
| DELETED | Not shown anywhere | — |

Exact overlay styling (opacity, text position, font) is a Stage 5 UI decision.

---

## Donation Decision Support

Runs separately on full wardrobe.
Excludes: status = DELETED, DONATED.
Decision support only — user makes all final decisions.

---

### D1–D5 Donation Eligibility Rules

```
Pre-check before any rule evaluation per item:
    IF item.kept_until IS NOT NULL AND item.kept_until > today:
        → Skip all rules for this item — suppress from donation page

D1 — Long-term unused
     wear_count > 0 AND days_since_worn >= 90
     Message: "Not worn in 3+ months"

D2 — Never worn old item
     wear_count == 0 AND days_since_added > 90
     Message: "Added 3+ months ago, never worn"
     Note: triggers for both is_new_item=true and is_new_item=false items

D3 — Frequently skipped
     skip_count >= 10 AND skip_ratio > 0.75
     (skip_ratio here = guarded raw computed getter; returns 0.0 when wear_count + skip_count == 0)
     Message: "You keep skipping this item"

D4 — Poor condition
     condition == 1
     Message: "Worn out — consider disposal, not donation"

D5 — Worn condition unused
     wear_count > 0 AND condition == 2 AND days_since_worn >= 60
     Message: "This item is showing wear and hasn't been used in 2+ months"
```

### Tier logic

```
Flagged by 1 rule   → "Worth Reviewing"
Flagged by 2+ rules → "Strong Candidate"
```

---

### DPS — Donation Priority Score

**What it does:** Ranks donation candidates so most urgent appear first.

```
days_norm = min(days_since_worn / 365, 1.0)
IF never worn: use days_since_added / 365 instead

skip_ratio = skip_count / (wear_count + skip_count + 1)
(+1 buffer for mild smoothing in ranking context)

condition_score = (5 - condition) / 4

DPS = (0.50 × days_norm)
    + (0.30 × skip_ratio)
    + (0.20 × condition_score)

Range: 0.0 (keep) → 1.0 (strong donate candidate)
```

### Donation page display

```
Filter chips: All | Never Worn | Long Unused | Skipped Often | Poor Condition
    Never Worn = D2
    Long Unused = D1
    Skipped Often = D3
    Poor Condition = D4 or D5
Default sort within each filter: DPS descending (most urgent first)
No additional sort options in MVP
```

---

## Donation and Deletion Behaviour

Delete and Donate are confirmation-sheet-only — there is NO undo snackbar
(a trial Delete-Undo was implemented then removed; do not re-add).

### Item deletion (DELETED status)

```
User confirms delete (confirmation sheet):
    → Supabase write: set status = DELETED
    → Wait for Supabase confirmation
    → On success: item permanently hidden (data preserved in database)
    → `item_events` rows for item remain intact

On failure:
    → Show snackbar: "Couldn't delete. Check your connection."
    → Item stays visible, no change
```

### Donation confirmation

```
confirmDonation() (canonical — Item Detail Donate runs it, then pops):
    → Set status = DONATED
    → Set donated_at = today
    → Item hidden from wardrobe and recommendation engine
    → Item visible in Donation History page
    → Cannot be restored to active wardrobe from history

Keep action (from donation candidate):
    → Status remains IN_WARDROBE (no change)
    → Set kept_until = today + chosen_duration
      (options: 1 month, 3 months, 6 months, no reminder)
    → Item suppressed from D1–D5 rules until kept_until expires
    → Item remains fully wearable and appears in recommendations normally
```

### Donated / deleted Item Detail (read-only)

```
readOnly = NOT status.isVisibleInWardrobe   (DONATED or DELETED)
    → Favourite / Edit / Delete hidden (Back only)
    → Donate hidden; Log Wear / Build Outfit disabled
    → Status tile non-tappable
Prevents editing history and a DONATED → DELETED soft-delete that would drop the
row from Donation History.
```

---

## Insights — Health Score

**What it does:** One number out of 100 showing overall wardrobe health.

```
active_items = COUNT(items WHERE status NOT IN (DONATED, DELETED))

IF active_items == 0:
    → Show: "Add items to see your wardrobe health"
    → Skip calculation

IF total_worn_events < 5:
    → Show partial score with indicator:
       "Keep logging outfits to build your Health Score"

items_worn_in_last_30_days =
    COUNT unique item_id
    WHERE event_type == WORN
    AND event_at within last 30 days
    AND item.status NOT IN (DONATED, DELETED)

utilisation_rate  = clamp(items_worn_in_last_30_days / active_items, 0.0, 1.0)
utilisation_%     = utilisation_rate × 100
utilisation_score = utilisation_% × 0.50

overused_items  = COUNT(items WHERE wear_rate >= 0.20 AND wear_count >= 3 AND status = IN_WARDROBE)
                  (shared isOverusedRate — the 0.20 threshold is locked; the
                   wear_count >= 3 evidence floor was added in Phase 11)
rotation_%      = (1 - (overused_items / active_items)) × 100
rotation_score  = rotation_% × 0.50

Health Score = utilisation_score + rotation_score
Display: rounded to nearest integer, out of 100
```

### Verdict sentences

| Score | Verdict |
|---|---|
| 80–100 | Great job! Your wardrobe rotation is healthy. |
| 60–79 | Good progress — a few items need more attention. |
| 40–59 | Your wardrobe has room for better utilisation. |
| 0–39 | Many items in your wardrobe are being neglected. |

### Insights quick stats and tabs

```
Quick Stats:
    Total items = COUNT(items WHERE status NOT IN (DONATED, DELETED))
    Worn this month = items_worn_in_last_30_days
    Never worn = COUNT(items WHERE wear_count == 0 AND status NOT IN (DONATED, DELETED))
    Donation candidates = COUNT(items flagged by any D1–D5)

Items that need attention:
    Never Worn:
        wear_count == 0 AND status NOT IN (DONATED, DELETED)

    Long Unused:
        wear_count > 0 AND days_since_worn > 60 AND status NOT IN (DONATED, DELETED)

    Skipped Often:
        skip_ratio > 0.50 AND status NOT IN (DONATED, DELETED)

    Overused:
        wear_rate >= 0.20 AND wear_count >= 3 AND status == IN_WARDROBE
        (shared isOverusedRate)

Sleeping items count:
    wear_count > 0 AND days_since_worn >= 90 AND status NOT IN (DONATED, DELETED)

Attention lists are NOT filtered by kept_until (Phase 7). Sleeping (>= 90d) and
Long Unused (> 60d) remain separate definitions.

Tap item from Insights:
    → Open Item Detail
    → Back returns to Insights, not Wardrobe
```

---

## Item Badge Labels

All matching badges are computed per item using `computeAllBadges(item)`.
Badges are evaluated in priority order — all matching badges are returned as a list.
Badge evaluation excludes items with status = DELETED or DONATED.
Donation review badge respects kept_until suppression.

**On item card (wardrobe grid):**
- Show `badges[0]` as the main badge label
- If more than 1 badge matches, show `+N` next to it (e.g. "Worn out +3")
- No storage needed — computed fresh on every render from item data in memory

**On Item Detail page:**
- Show all matching badges as individual chips in full

| Priority | Badge | Trigger | Colour |
|---|---|---|---|
| 1 | Worn out | condition == 1 | Dark red |
| 2 | Donation review | Flagged by any D1–D5 AND kept_until not active | Deep orange |
| 3 | Overused | wear_rate >= 0.20 AND wear_count >= 3 | Red |
| 4 | Skipped often | skip_ratio > 0.50 | Red |
| 5 | Never worn | wear_count == 0 AND effective_age > 14 | Amber |
| 6 | Long unused | wear_count > 0 AND days_since_worn > 60 | Amber |
| 7 | New | is_new_item == true AND days_since_added <= 14 | Blue |
| 8 | Top Worn | Top 10% by wear_count among non-DELETED, non-DONATED wardrobe items | Purple |

Note: Priority 5 catches both brand-new items after NIBS expires AND already-owned-never-worn items.
P3 Overused uses the shared isOverusedRate evidence floor (0.20 threshold locked; wear_count >= 3 added Phase 11).
P5 uses effective_age = initial_usage_age_days + days_since_added so pre-owned-unworn items badge immediately (the Insights "never worn" list still uses wear_count == 0).
P4 stays strict skip_ratio > 0.50 (guarded raw ratio, no interaction floor — M6).
Priority 7 (New/blue) only shows during the active NIBS window for explicitly new items.
P8 display label is "Top Worn" (M5) — top 10% by wear_count, ceil(0.10 × N) min 1, with TIES at the cutoff included (so the badged count can exceed ceil). Logic unchanged from the old "Most worn"; the Wardrobe SORT option "Most worn" is a separate feature and keeps its name.
For P8, if the wardrobe is non-empty, at least 1 item can receive the Top Worn badge.

Status overlays (shown via gray photo overlay, not badge chip):
```
In Laundry       → status == LAUNDRY
Lent Out         → status == LENT
Stored Away      → status == STORED
```

---

## Notification Rules

Local notifications only. No server push required.
The N1–N4 app-open check fires once per WardrobeNotifier lifetime (once per app
session, via the `_sessionChecked` flag), so mutations during the session do NOT
re-trigger it. No background server job in MVP.

```
days_since_last_log =
    today - MAX(item.last_worn_date across wardrobe items
                WHERE last_worn_date IS NOT NULL AND NOT last_worn_unknown)
    (computed from item summary fields — no item_events query)

IF no item has a known last_worn_date:
    days_since_last_log = 0  → suppress N1 and N2

Store notification timestamps locally (throttle):
    last_n3_notified_at
    last_n4_notified_at
    (N5 is scheduled, not throttled — no stored timestamp)
```

| ID | Trigger | Title / Message |
|---|---|---|
| N1 | days_since_last_log == 1 (missed yesterday only) | "Daily wardrobe check-in" / "Did you wear something yesterday? Log it to keep your wardrobe history updated." |
| N2 | days_since_last_log >= 3 (suppresses N1 on same day) | "Outfit logging streak broken" / "You haven't logged an outfit in a few days. Keep your history updated." |
| N3 | Long-unworn count > 0 (isLongUnused, > 60 days), not notified in > 7 days | "Long-unworn items" / "X items not worn in a while. Review your wardrobe rotation." |
| N4 | Donation candidate count > 0, not notified in > 7 days | "Donation candidates" / "X items listed for donation review." |
| N5 | Weekly (one-shot, Sunday 20:00) | "Weekly Wardrobe Summary" / "X worn in the last 30 days · X dormant · X for donation review" |
| N6 | condition_review_mode == AUTO AND condition > 1 AND condition_next_drop IS NOT NULL AND wear_count >= condition_next_drop | "Condition update" / "[item name] is now in [condition label] condition. Tap to review." |

N1 and N2 are mutually exclusive. N2 fires on day 3+, N1 only fires on day 1.
N3 long-unworn count uses isLongUnused (wear_count > 0 AND days_since_worn > 60),
NOT D1's 90-day long-term unused rule.
N6 fires per item in AUTO mode only, inline at the moment of an AUTO condition
drop (not from the app-open check). Tap-through is implemented: the payload
`item:<id>` opens that item's Detail.
N6 is suppressed entirely when item.condition_review_mode == MANUAL.

Delivery: notifications fire on app-open / resume only (no background job —
documented limitation). N3/N4 are throttled: they fire only when MORE than 7
days have passed since that notification last fired (exactly 7 days is still
suppressed). N5 is a one-shot
notification scheduled for the next Sunday 20:00 local; it is cancelled and
rescheduled with fresh stats on every app-open / wardrobe build (no
matchDateTimeComponents, so the body never goes stale; suppressed when the
wardrobe is empty). Tap destinations: N1/N2 → Wardrobe, N3/N5 → Insights,
N4 → Donate, N6 → that item's Detail.

---

## Condition Review Thresholds

Each item independently controls condition behaviour via `condition_review_mode`.
User selects AUTO or MANUAL when adding an item. Default is AUTO.

### AUTO mode
System automatically drops condition by 1 when wear_count reaches `condition_next_drop`.
N6 notification fires at that moment to inform the user.
After each drop, `condition_next_drop` advances by one threshold.
User can still manually change condition anytime — `condition_next_drop` recalculates from there.
When condition reaches 1, `condition_next_drop` is set to NULL — no more drops.

### MANUAL mode
Nothing happens automatically.
No condition drops. No N6 notifications.
User manages condition entirely themselves.
`condition_next_drop` is NULL for all MANUAL items.

---

### Thresholds by category

Research-supported lifetime wear values divided by 4,
matching the four possible condition drops (5→4→3→2→1).

| Category | Lifetime reference | Threshold (lifetime / 4) |
|---|---|---|
| Tops | 111 wears | 28 wears |
| Bottoms | 233 wears | 58 wears |
| Outerwear | 136 wears | 34 wears |
| Normal shoes | 100 wears | 25 wears |
| Sport shoes | 200 wears | 50 wears |
| Others | 100 wears | 25 wears |

### Wear drop points per category

**Tops (drop every 28 wears):**
```
28 wears  → condition 5 → 4
56 wears  → condition 4 → 3
84 wears  → condition 3 → 2
112 wears → condition 2 → 1
```

**Bottoms (drop every 58 wears):**
```
58 wears  → condition 5 → 4
116 wears → condition 4 → 3
174 wears → condition 3 → 2
232 wears → condition 2 → 1
```

**Outerwear (drop every 34 wears):**
```
34 wears  → condition 5 → 4
68 wears  → condition 4 → 3
102 wears → condition 3 → 2
136 wears → condition 2 → 1
```

**Normal Shoes (drop every 25 wears):**
```
25 wears  → condition 5 → 4
50 wears  → condition 4 → 3
75 wears  → condition 3 → 2
100 wears → condition 2 → 1
```

**Sport Shoes (drop every 50 wears):**
```
50 wears  → condition 5 → 4
100 wears → condition 4 → 3
150 wears → condition 3 → 2
200 wears → condition 2 → 1
```

**Others (drop every 25 wears):**
```
25 wears  → condition 5 → 4
50 wears  → condition 4 → 3
75 wears  → condition 3 → 2
100 wears → condition 2 → 1
```

---

### How shoe type maps to threshold

```
IF item.category == FOOTWEAR:
    IF item.type == SPORT_SHOES:
        threshold = 50
    ELSE:
        threshold = 25
```

FOOTWEAR uses specific stored types from the Item Type Dictionary.
Only SPORT_SHOES uses the sport-shoe threshold. All other footwear types use
the normal-shoe threshold.

---

### condition_next_drop logic

Invariant:
`condition_next_drop` must be non-null when `condition_review_mode == AUTO`
and `condition > 1`. It is NULL only when `condition_review_mode == MANUAL`
or `condition == 1`. Triggers still check `condition_next_drop IS NOT NULL`
as a null-safety guard.

**On item add (AUTO mode):**
```
IF condition == 1:
    condition_next_drop = NULL
ELSE:
    condition_next_drop = wear_count + threshold
```

**AUTO mode drop trigger (checked after every wear log):**
```
IF condition_review_mode == AUTO
   AND condition > 1
   AND condition_next_drop IS NOT NULL
   AND wear_count >= condition_next_drop:
       → condition = condition - 1
       → condition_next_drop = wear_count + threshold
       → fire N6 notification
       → IF condition == 1: condition_next_drop = NULL
         (enforced via Item.copyWith(clearConditionNextDrop: true))
```

**On user manually updates condition (AUTO mode):**
```
IF condition == 1:
    condition_next_drop = NULL
ELSE:
    condition_next_drop = wear_count + threshold
```

**On user switches mode from AUTO to MANUAL:**
```
condition_next_drop = NULL
```

**On user switches mode from MANUAL to AUTO:**
```
IF condition == 1:
    condition_next_drop = NULL
ELSE:
    condition_next_drop = wear_count + threshold
```

**On editItem() — preserve unless a drop-affecting field changed (Phase 11):**

The existing absolute drop schedule is PRESERVED so an unrelated edit
(name / photo / colour / occasion / favourite) does NOT delay the next AUTO
condition drop. Recompute only when something that affects the schedule changed.
(Helper: `resolveConditionNextDropOnEdit`.)

```
IF new condition_review_mode == MANUAL:
    condition_next_drop = NULL
ELSE IF new condition == 1:
    condition_next_drop = NULL
ELSE IF condition changed
        OR type/threshold changed
        OR mode went MANUAL → AUTO:
    condition_next_drop = wear_count + new_threshold   (recompute)
ELSE:
    condition_next_drop = existing condition_next_drop  (preserve)
```

---

### Condition label mapping (used in N6 message)

```
5 → Excellent
4 → Good
3 → Fair
2 → Worn
1 → Damaged
```

---

### Sources
- Tops, Bottoms: Cooper et al., cited by Laitala & Klepp (2020), Sustainability
- Outerwear: Vermeyen et al. (2026), ScienceDirect
- Normal shoes, Others: C2C Certified Manual / Higg Product Module / PEFCR
- Sport shoes: 200 wears adopted as practical proxy for 800km estimated lifespan
  (Escamilla-Martínez et al. 2020 — original source uses distance, not wear count)

---

## Data Sync Strategy

| Action | Strategy | Reason |
|---|---|---|
| Skip item / Skip outfit | Wait for Supabase → exit screen → remove card → generate replacement | Engine must use confirmed data |
| Log Wear | Wait for Supabase → confirm → update UI | Critical data, affects TDS, WFSS, FRS |
| Add Item | Wait for Supabase → confirm → show in wardrobe | Creates new record |
| Edit Item | Wait for Supabase → confirm → update state optimistically (no full re-fetch) | Can affect filters, scoring, condition thresholds, badges |
| Delete Item | Wait for Supabase → confirm (confirmation sheet, no undo) → remove from UI | Destructive action |
| Health Score / Insights | Compute on demand from Riverpod cached data | Pure calculation, no network needed |
| DPS / Donation candidates | Compute on demand from Riverpod cached data | Pure calculation, no network needed |

`logWorn()` always performs the same core updates regardless of source:
```
wear_count += 1
last_worn_date = today
last_worn_unknown = false
wear_count_unknown = false
insert `item_events` row (WORN)
then check AUTO condition drop trigger
```

### Riverpod caching strategy

```
All providers cache on first load and stay in memory.

Invalidated (re-fetched from Supabase) only on mutations:
    logWorn()           → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider
    logSkipped()
        from Outfit Generator
                        → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider
                          OutfitGeneratorProvider preserves current session
        from Daily Rotation
                        → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider
    addItem()           → invalidates WardrobeProvider, InsightsProvider,
                          OutfitGeneratorProvider
    editItem()          → does NOT invalidate/re-fetch WardrobeProvider —
                          updates its state optimistically in place
                          (state = AsyncData([...])). InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider react to
                          that state change because they watch/listen
                          WardrobeProvider (Insights/Donation refresh;
                          OutfitGenerator resets its session).
    deleteItem()        → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider
    updateItemStatus()  → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider
    confirmDonation()   → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider
    setKeptUntil()      → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider
    laundryAutoReturn()
        if any item status changes
                        → invalidates WardrobeProvider, InsightsProvider,
                          DonationProvider, OutfitGeneratorProvider

Navigation between pages: NO re-fetch unless mutation occurred.
editItem updates state optimistically (no full re-fetch); all other mutations
call invalidateSelf. Donation / Insights / Daily-Rotation-skip refresh because
they watch WardrobeProvider; OutfitGeneratorProvider auto-clears session when
invalidated, except during Outfit Generator skip replacement where the current
session is preserved.
```

---

## Complete Rule Reference

| ID | Name | Layer | What breaks without it |
|---|---|---|---|
| F1 | Season Filter | DROPPED | Not needed for Malaysia MVP |
| F2 | Occasion Filter | Layer 1 | Wrong-occasion items in suggestions |
| F3 | Condition Gate | Layer 1 | Worn-out clothes get recommended |
| F4 | Availability Gate | Layer 1 | Unavailable items get suggested |
| F5 | Worn-Today Gate | Layer 1 | Items worn today re-recommended same day |
| S1 | TDS | Layer 2 | Long-unused clothes never surface |
| S2 | SPS | Layer 2 | Disliked items keep reappearing |
| S3 | WFSS | Layer 2 | Favourite items dominate every outfit |
| S4 | NIBS | Layer 2 | New purchases sit unworn indefinitely |
| S5 | PS | Layer 2 | User preferences have zero influence (Mode A) |
| S6 | FRS | Layer 2 | No ranking possible |
| P1a | Category Completeness | Layer 3 | Incomplete outfits returned |
| P1b | Formality Matching | Layer 3 | Formal and casual items paired together |
| P1c | Colour Compatibility | Layer 3 | Bad colour combinations ranked highly |
| P1D | Tier-Priority Reorder | Layer 3 | Colour outranks formality in final ordering |
| OutfitScore | Outfit ranking | Layer 3 | Outfit cards in no meaningful order |
| OutfitExplanation | Outfit Detail display | Display-only | Outfit details feel like a black box |
| DailyRotationDisplay | Daily Rotation display | Display-only | Daily item cards show unclear score/usage labels |
| D1 | Long-term unused | Separate | No flag for ignored items |
| D2 | Never worn old item | Separate | No flag for forgotten new items |
| D3 | Frequently skipped | Separate | No flag for disliked items |
| D4 | Poor condition | Separate | No flag for worn-out items |
| D5 | Worn condition unused | Separate | No flag for deteriorating unused items |
| DPS | Donation Priority | Separate | Donation candidates in random order |

---

## Viva One-Paragraph Summary

The backend is a three-layer deterministic rule engine. Layer 1 filters out items the user cannot or should not wear based on occasion, condition, availability, and same-day wear. Layer 2 scores each remaining item using four wear-history formulas — Temporal Decay Score surfaces long-unused clothes using a category-aware adaptive window, Skip Penalty Score with a smoothing buffer reduces repeatedly rejected items fairly, Wear Frequency Saturation Score prevents overuse of favourites using real ownership history, and New Item Boost Score gives brand new clothes a 14-day tapered window to be tried. These four scores combine with an optional Preference Score using fixed weights to produce the Final Recommendation Score in two modes: Balanced Rotation includes preference signals, Pure Rotation is wear-history only. Layer 3 assembles individual ranked items into complete outfits, enforcing category completeness, formality compatibility with a same-category swap algorithm, and colour compatibility before ranking full outfit combinations using OutfitScore and a final tier-priority reorder that ranks formality above colour. The generator supports pinned items, session-level exclusion tracking, deterministic regeneration, and a display-only OutfitExplanation layer that shows why each outfit was suggested without changing the formulas. Donation review runs separately on the full wardrobe using five eligibility rules, a kept_until suppression mechanism, and a Donation Priority Score. The entire system is transparent, deterministic, explainable, and non-AI.

---

*Stage 3 complete — stress tested, all bugs fixed, all decisions locked.*
