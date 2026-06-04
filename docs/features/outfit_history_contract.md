# Contract — Outfit History (UI, Phase 6 Step 5)

**Sources:** FE §25. DB §5 `outfit_logs` + §7 `outfit_log_items`.
**Location:** `lib/features/outfit/outfit_history_page.dart` (route `/outfit-history`),
`lib/providers/outfit_history_providers.dart`. Reached from the Outfit top-bar
history clock icon.

## Data — `outfitHistoryProvider` (FutureProvider.autoDispose)
Newest-first list of `OutfitHistoryEntry{ log, imagePaths }`. Resolved in 3 batched
queries: `getOutfitHistory(userId)` → `getOutfitItemsForLogs(logIds)` →
`getItemsByIds(itemIds)`. Items grouped per log, sorted by `LayerType.index`
(top → bottom → outerwear → shoes); `imagePaths` are nullable (no photo / missing
item). `getItemsByIds` is status-agnostic so donated/deleted items still resolve.
Watches `wardrobeProvider` so a freshly-logged outfit appears. TDD: grouping +
layer order + empty.

## UI (FE §25)
- Top bar: back + "Outfit History" centred.
- One white card; each event row (divider between, 0.5px):
  date (left, "D Mon YYYY", 13 semibold) · occasion pill (outlined, centred) ·
  up to 4 × 40px thumbnails (right). **Rows are NOT tappable** (display-only).
- Empty state when no logs.

## New repo methods
- `ItemRepository.getItemsByIds(List<String>)` — items by id, any status.
- `OutfitLogRepository.getOutfitItemsForLogs(List<String> logIds)` — batched.
