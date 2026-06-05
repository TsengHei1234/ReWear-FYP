# ReWear — Locked Decisions & Contradiction Resolutions

Pinned in-repo so any chat resolves conflicts the same way without re-deriving.
**Authority rule:** logic → Rule Engine (RE); schema → Database (DB); UI → Frontend (FE).

## Open decisions (confirm with user at the relevant phase)
- **C5 — Donate filter chips:** default to backend's **5** (All · Never Worn · Long
  Unused · Skipped Often · **Poor Condition**). Confirm before Phase 7.
- **M2 — Notification times:** default N1 ~08:00 local, N5 Sunday ~18:00. Confirm Phase 8.
- **M3 — Password-reset redirect:** MVP uses Supabase default hosted flow; deep link post-MVP.

## Resolved contradictions
| # | Issue | Resolution |
|---|---|---|
| C1 | "Never worn" definition differs (is_new_item vs wear_count==0) | Use **RE**. Insights/list "Never worn" = `wear_count==0 AND status NOT IN (DONATED,DELETED)`. Badges: blue **New** = `is_new_item && days_since_added<=14`; amber **Never worn** = `wear_count==0 && days_since_added>14`. |
| C2 | D6 referenced but undefined | Only **D1–D5** exist. |
| C3 | Add-Item history inputs (date/number vs buckets) | Use **RE buckets** (mapped values feed TDS/WFSS). See `app_constants.dart`. |
| C4 | "How long owned" options list | Use **RE fuller list** (adds 1–2y, 2+y, "I don't remember"=365). |
| C5 | Donate filter chips count | Default **5** incl Poor Condition (open — confirm). |
| C6 | profiles.display_name omitted in RE snippet | **Include** display_name (UI needs it). |
| C7 | event_at/logged_at type (timestamptz vs date) | Use **timestamptz** (DB authority). |
| C8 | item_events.outfit_log_id absent in RE snippet | **Include** nullable. |
| C9 | View-All Long Unused missing wear_count>0 | Add **wear_count>0** (matches D1/badge). |
| C10 | FE says USERS.* | Stale name → table is **profiles** (DB §13). |

## Authored (spec gaps filled)
| # | Gap | Plan |
|---|---|---|
| M1 | No explicit 12×12 colour matrix | **DONE + user-reviewed (Phase 5).** `core/constants/colour_compatibility.dart` authors `colourScore(a,b)` from groups/bands. Neutrals split achromatic{black,white,grey,beige}/coloured-neutral{navy,brown}: 2 achromatic or achromatic+coloured-neutral=1.00, navy+brown=0.80; achromatic+chromatic=0.90; coloured-neutral+chromatic=0.80 (navy+blue=0.65); cool-family/adjacent=0.80, analogous=0.65, clashes(green+red, yellow+purple)=0.30, else 0.50. **Same-colour diagonal (user-set): achromatic=0.80, navy/brown=0.70, chromatic=0.65.** Validated: White+Navy=1.00, Navy+Brown=0.80→avg 0.90. 0.70 is an authored off-band value. |
| M4 | formality_level not user-editable | Auto-derived from Item Type Dictionary default (intended). |
| M5 | "Most worn" badge top 10% | `ceil(0.10 × N)`, min 1 when wardrobe non-empty. |
| M6 | P4 "Skipped often" badge skip_ratio | **Strict RE: `skip_ratio > 0.50`** using the guarded raw ratio `skip/(wear+skip)` (0 when no interactions). An earlier `>=3 interactions` noise-floor was **removed** (undocumented, inconsistent with insights `isSkippedOften`). Do not re-add a floor without recording it here. |

## Locked product choices
- Colour picker: **V1 swatch grid** (V2 dropdown is a trivial later swap).
- State management: **Riverpod**. Routing: **go_router**.
- Run target: Android emulator (daily) + physical phone (checks).
- Cadence: one chat by default; switch chats only if tokens/quality degrade.

## Authored / overrides (post-Phase-5)

**Engine deltas vs `Stage3_…v7.md` (read this with the MD — the MD stays frozen):**
the runtime rule engine = the v7 MD **plus** these recorded deltas: C1–C10 (resolved
contradictions, table above), M1/M4/M5/M6 (authored gaps, table above), and **G1/G2/G3**
below. Code in `lib/engine/*` + tests is the source of truth once verified.

| # | Topic | Decision (user-confirmed, Phase 6) |
|---|---|---|
| G3 | **Skip scope model** — separates the two skips (authored). | **Daily Rotation Skip:** `skip_count +1` + **day-scoped** hide from Daily Rotation only (DB-backed via today's `SKIPPED`/`DAILY_ROTATION` events → `dailyRotationSkippedTodayProvider`; survives restart, resets midnight). Does **not** hard-block the Generator. **Generator Skip Item/Outfit:** `skip_count +1` + remove from the **current generator session** + cascade-replace; **session-scoped only** — may reappear in Daily Rotation (soft, lower score) and in a fresh generation. **Wear/Log Wear/Log Outfit:** hard-exclude from BOTH for the day (G2). The three never bleed into each other. |
| G2 | **Worn-today exclusion (F5)** — authored, not in RE. | An item logged worn **today** (`!last_worn_unknown && last_worn_date == today`) is excluded from BOTH Daily Rotation and Outfit Generator pools for the rest of the day (auto-expires at midnight; no stored flag). Implemented as Layer-1 **F5**, applied only when `now` is passed to `applyLayer1Filters` (recommendation paths). Status gate (F4) already restricts pools to `IN_WARDROBE` only. Log Wear from anywhere → wardrobe invalidates → Daily Rotation re-ranks (worn item drops) + Generator session resets; next generation excludes it. |
| G1 | **Outfit Generator session lifecycle** — *overrides* RE "Session lifecycle" (which clears on every occasion/layer change). | **Pinned:** changing occasion/layer does **not** reset — the 3 shown outfits stay; the new filter applies only on the next **Regenerate**. The pin's own layer is locked-on (cannot be toggled off) and occasion chips are limited to the pinned item's `occasion_tags`. **No-pin:** changing occasion/layer **after** outfits exist shows a "This will clear your generated outfits. Continue?" confirm — **Confirm = apply the new filter + clear the generated cards** (button returns to "Generate Outfit"; user re-taps Generate, no auto-generation); **Cancel = keep** cards + previous filter; no warning if nothing generated yet. **Set/clear pin → reset.** **Generator Skip → preserve** session+pin (cascade-replace). **Generator Log Wear/Log Outfit → end session + clear pin** (no auto-LAUNDRY; status is user-managed). **Any wardrobe mutation elsewhere → reset + clear pin.** Tab-switch preserves; app close resets. **Regenerate** = fresh generation that keeps pin+filters but clears the skip/shown history. |
| I1 | **`CachedNetworkImage` versioned cacheKey rule** — post-Phase-6 egress + photo-refresh fix. | Supabase `createSignedUrl` produces a new token on every call. `itemImageUrlProvider` is `autoDispose`, so it regenerates after the widget leaves scope. Without a stable `cacheKey`, every new URL = cache miss = re-download → Storage Egress. **Rule (enforced from hotfix Fix C, all later phases):** every `CachedNetworkImage` loading a live/current item image via `itemImageUrlProvider` MUST use the versioned cacheKey: `imagePath != null ? '${imagePath}_v${updatedAt.millisecondsSinceEpoch}' : null`. Stable across URL regen (same `updatedAt` → same key → disk-cache hit, zero egress). Auto-busts after a photo edit (`trg_items_updated_at` bumps `updated_at` on every UPDATE → new `_v{ms}` → cache miss → downloads new image once). **Exception:** display-only historical thumbnails (e.g. `_HistoryThumb` in `outfit_history_page.dart`) may use `cacheKey: imagePath` — the item photo never changes after logging. Rule is also recorded as `⚠️ EGRESS RULE` on `itemImageUrlProvider`. **Applies to Phase 7 (Donate, Insights) and beyond.** Upload size capped at 1600×1600 px / `compressQuality: 85` — see hotfix in PROGRESS.md. |
| I2 | **Signed URL TTL + edited-photo fix — RESOLVED** | `itemImageUrlProvider` keeps successful signed URLs alive for 1 hour via `ref.keepAlive()` (timer starts `onCancel`, cancelled `onResume`, cleaned up `onDispose`). Reduces `createSignedUrl` API calls on scroll/navigation; not full offline support. **Edited-photo display bug: FIXED** by the versioned cacheKey (Fix C in PROGRESS.md). The earlier `evictFromCache` + `ref.invalidate(itemImageUrlProvider)` approach was unreliable and has been removed from `WardrobeNotifier.editItem`. The new key changes automatically when `updatedAt` changes → correct image shown immediately after save, no scroll or restart needed. TTL logic unchanged. Remaining open: general image flicker during fast scroll/tab-switch (UI polish, not egress/photo-refresh — defer to Phase 9). |
