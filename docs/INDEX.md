# ReWear — Source Index (feature → spec section map)

**Purpose:** find where any feature is specified across the three reference docs
**without** re-reading them whole. Reference by **section heading** (stable), not
line number (rots when docs are edited).

**Docs (short names used below):**
- **FE** = `Wardrobe_App_Frontend_Reference_PlainEnglish.md` (UI authority)
- **RE** = `Stage3_Complete_Rule_Engine_v7.md` (logic authority)
- **DB** = `Final_MVP_Supabase_Database_Design_Clean.md` (schema authority)

> Workflow: before building a feature, open the rows below, extract a small
> `docs/features/<feature>_contract.md`, build from the contract, verify against it.
> Contradiction resolutions live in the plan (`C1–C10`, `M1–M5`) and `docs/DECISIONS.md`.

---

## Design system & shared widgets
| Topic | FE | RE | DB |
|---|---|---|---|
| Colours / typography / spacing / radius / shadows | §1–§5 | — | — |
| Component library (buttons, chips, inputs, cards, nav, etc.) | §6 | — | — |
| Navigation structure | §7 | — | — |
| Theme file (app_theme.dart) | §40 | — | — |
| Badge system (priority, colours, alignment) | §39 | "Item Badge Labels" | — |
| Shared bottom sheets (universal confirm + variants) | §38 | — | — |
| Locked design decisions | §43 | — | — |

## Auth & onboarding
| Screen | FE | RE | DB |
|---|---|---|---|
| Splash | §8 | — | "Laundry Auto-Return" (runs on open) |
| Login / Sign Up / Forgot Password | §9 / §10 / §11 | — | §2 Auth, profiles |
| Onboarding 1 Welcome | §12 | — | — |
| Onboarding 2 Style Preferences (colour picker V1) | §13, §42 | S5 PS (uses colours) | profiles.style_preferences |
| Onboarding 3 Recommendation Mode | §14 | S6 FRS Mode A/B | profiles.recommendation_mode |
| Onboarding 4 Notifications | §15 | "Notification Rules" | — |

## Wardrobe
| Screen | FE | RE | DB |
|---|---|---|---|
| Home | §16 | DailyRotationDisplay, Health/snapshot | items, item_events |
| Wardrobe list/grid + filter sheet | §17, §38 | F2/F3/F4, badges | items |
| Add Item | §18 | "Item Type Dictionary", "Add Item — Initial History", condition thresholds | items (all fields) |
| Item Detail | §19 | Rule-Based Usage Summary, badges, D-rules | items, item_events |
| Edit Item | §20 | condition_next_drop recalculates on category/type edit | items |
| Full Wear History | §21 | — | item_events |

## Outfit
| Screen | FE | RE | DB |
|---|---|---|---|
| Daily Rotation tab | §22 | "Daily Rotation — Backend Behaviour", display labels | items, item_events |
| Outfit Generator tab | §23 | "Outfit Generator — Full Behaviour" (session, pinning, skip/cascade) | items |
| Outfit Detail + explainability | §24 | "Outfit Detail Explainability Rules", P1a/P1b/P1c, OutfitScore | outfit_logs, outfit_log_items, item_events |
| Outfit History | §25 | — | outfit_logs, outfit_log_items |

## Donate
| Screen | FE | RE | DB |
|---|---|---|---|
| Donate page (candidates, filters) | §26 | "Donation Decision Support" D1–D5, DPS | items |
| Kept Items | §27 | KEPT behaviour, kept_until | items.kept_until |
| Donation History | §28 | confirmDonation | items.donated_at |

## Insights
| Screen | FE | RE | DB |
|---|---|---|---|
| Insights page (health, stats, attention tabs) | §29, §41 | "Insights — Health Score", attention defs | items, item_events |
| View All sub-pages (×5) | §30 | same filters (Never/Long/Skipped/Overused/Sleeping) | items, item_events |

## Profile & settings
| Screen | FE | RE | DB |
|---|---|---|---|
| Profile & Settings hub | §31 | — | profiles |
| My Profile | §32 | — | profiles, auth |
| Style Preferences (edit) | §33 (= §13) | S5 PS | profiles.style_preferences |
| App Theme | §34 | — | local SharedPreferences |
| Notification Settings | §35 | N1–N6 | local |
| Data & Privacy | §36 | — | auth (delete account) |
| Help / About | §37 | — | — |

## Engine (pure Dart — Phase 5)
| Rule | RE section | DB |
|---|---|---|
| F2/F3/F4 filters + empty-pool guard | "Layer 1 — Filter Rules" | — |
| TDS / SPS / WFSS / NIBS / PS / FRS | "Layer 2 — Scoring Formulas" | runtime-only (DB §8) |
| P1a/P1b/P1c, ColourScore, OutfitScore | "Layer 3 — Post-Processing" | — |
| Colour compatibility table (**M1 — author**) | P1c groups/bands | — |
| Donation D1–D5 + DPS | "Donation Decision Support" | items |
| Condition AUTO drop + thresholds | "Condition Review Thresholds" | items.condition, condition_next_drop |
| Badges (computeAllBadges) | "Item Badge Labels" + FE §39 | — |
| Health score + insights defs | "Insights — Health Score" | — |
| Daily rotation display labels | "Daily Rotation — Backend Behaviour" | — |
| Notifications N1–N6 | "Notification Rules" | local |
| Riverpod invalidation / sync | "Data Sync Strategy" | — |

## Database / infra
| Topic | DB | RE |
|---|---|---|
| 5 tables + fields | §3–§7 | "Database Tables" |
| Enums / checks | §9 | — |
| Relationships | §10 | — |
| RLS | §11 | "Row Level Security" |
| Storage bucket + path | §12 | — |
| Old→new renames (USERS→profiles etc.) | §13 | — |
