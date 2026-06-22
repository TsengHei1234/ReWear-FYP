import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/wardrobe_item_card.dart';
import '../../data/models/item.dart';
import '../../core/utils/mutation_helper.dart';
import '../../core/widgets/main_page_header.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';
import '../outfit/build_outfit_action.dart';

/// Filter state for the Wardrobe Filter bottom sheet.
class WardrobeFilter {
  const WardrobeFilter({
    this.occasions = const [],
    this.statuses = const [],
    this.sortBy = WardrobeSortBy.recentlyWorn,
    this.favouritesOnly = false,
  });

  final List<Occasion> occasions;
  final List<ItemStatus> statuses;
  final WardrobeSortBy sortBy;
  final bool favouritesOnly;

  bool get isActive =>
      occasions.isNotEmpty ||
      statuses.isNotEmpty ||
      favouritesOnly ||
      sortBy != WardrobeSortBy.recentlyWorn;

  WardrobeFilter copyWith({
    List<Occasion>? occasions,
    List<ItemStatus>? statuses,
    WardrobeSortBy? sortBy,
    bool? favouritesOnly,
  }) =>
      WardrobeFilter(
        occasions: occasions ?? this.occasions,
        statuses: statuses ?? this.statuses,
        sortBy: sortBy ?? this.sortBy,
        favouritesOnly: favouritesOnly ?? this.favouritesOnly,
      );
}

enum WardrobeSortBy {
  recentlyWorn('Recently worn'),
  oldestWorn('Oldest worn'),
  nameAZ('Name A–Z'),
  mostWorn('Most worn');

  const WardrobeSortBy(this.label);
  final String label;
}

/// Wardrobe main page. Source: FE §17.
class WardrobePage extends ConsumerStatefulWidget {
  const WardrobePage({super.key});

  @override
  ConsumerState<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends ConsumerState<WardrobePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _selectedCategory = 0; // 0 = All
  WardrobeFilter _filter = const WardrobeFilter();
  String _searchQuery = '';

  static const _categories = ['All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Others'];
  static const _categoryEnums = [
    null,
    ItemCategory.top,
    ItemCategory.bottom,
    ItemCategory.outerwear,
    ItemCategory.footwear,
    ItemCategory.others,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Item> _applyFilters(List<Item> items) {
    var result = items;

    // Category
    final cat = _categoryEnums[_selectedCategory];
    if (cat != null) result = result.where((i) => i.category == cat).toList();

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    // Occasions (multi-select OR — item must have at least one matching)
    if (_filter.occasions.isNotEmpty) {
      result = result
          .where((i) =>
              i.occasionTags.any((o) => _filter.occasions.contains(o)))
          .toList();
    }

    // Statuses
    if (_filter.statuses.isNotEmpty) {
      result =
          result.where((i) => _filter.statuses.contains(i.status)).toList();
    }

    // Favourites only
    if (_filter.favouritesOnly) {
      result = result.where((i) => i.isFavorite).toList();
    }

    // Sort
    result = List.from(result);
    switch (_filter.sortBy) {
      case WardrobeSortBy.recentlyWorn:
        result.sort((a, b) {
          if (a.lastWornDate == null && b.lastWornDate == null) return 0;
          if (a.lastWornDate == null) return 1;
          if (b.lastWornDate == null) return -1;
          return b.lastWornDate!.compareTo(a.lastWornDate!);
        });
      case WardrobeSortBy.oldestWorn:
        result.sort((a, b) {
          if (a.lastWornDate == null && b.lastWornDate == null) return 0;
          if (a.lastWornDate == null) return 1;
          if (b.lastWornDate == null) return -1;
          return a.lastWornDate!.compareTo(b.lastWornDate!);
        });
      case WardrobeSortBy.nameAZ:
        result.sort((a, b) => a.name.compareTo(b.name));
      case WardrobeSortBy.mostWorn:
        result.sort((a, b) => b.wearCount.compareTo(a.wearCount));
    }

    return result;
  }

  String _countLabel(List<Item> filtered) {
    final label = _selectedCategory == 0
        ? 'All Items'
        : _categories[_selectedCategory];
    return '$label · ${filtered.length}';
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: wardrobeAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MainPageHeader(
                title: 'Wardrobe',
                avatarSource: profile?.displayName ?? profile?.email,
              ),
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
              ),
            ],
          ),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MainPageHeader(
                title: 'Wardrobe',
                avatarSource: profile?.displayName ?? profile?.email,
              ),
              Expanded(
                child: Center(
                  child: Text('Could not load wardrobe',
                      style: TextStyle(color: c.textSecondary)),
                ),
              ),
            ],
          ),
          data: (allItems) {
            final filtered = _applyFilters(allItems);
            return Stack(
              children: [
                Column(
                  children: [
                    // ── Fixed top section (does NOT scroll) ──────
                    MainPageHeader(
                      title: 'Wardrobe',
                      subtitle: '${allItems.length} items',
                      avatarSource: profile?.displayName ?? profile?.email,
                    ),

                    // ── Search bar ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _SearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (q) => setState(() => _searchQuery = q),
                      ),
                    ),

                    // ── Category chips ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilterChipRow(
                        labels: _categories,
                        selectedIndex: _selectedCategory,
                        onSelected: (i) =>
                            setState(() => _selectedCategory = i),
                      ),
                    ),

                    // ── Count label + filter icon ─────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _countLabel(filtered),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openFilterSheet(context, allItems),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _filter.isActive
                                        ? c.primary
                                        : c.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.tune,
                                  size: 14,
                                  color: _filter.isActive
                                      ? c.primary
                                      : c.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Grid or empty state (ONLY this scrolls) ──
                    Expanded(
                      child: RefreshIndicator(
                        displacement: 16,
                        edgeOffset: 0,
                        onRefresh: () => Future.wait([
                          ref.refresh(wardrobeProvider.future),
                          ref.refresh(profileProvider.future),
                        ]),
                        child: filtered.isEmpty
                            ? LayoutBuilder(
                                builder: (_, constraints) =>
                                    SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: _EmptyState(
                                        hasItems: allItems.isNotEmpty),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 88),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.64,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return _ItemCardWithImage(
                                    item: item,
                                    allItems: allItems,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),

                // ── FAB ──────────────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      context.push(Routes.addItem);
                    },
                    backgroundColor: c.primary,
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, List<Item> allItems) {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    showModalBottomSheet<WardrobeFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(initial: _filter),
    ).then((result) {
      if (result != null && mounted) setState(() => _filter = result);
      // Double post-frame: first fires after the sheet's pop animation frame,
      // second fires after Flutter's internal focus-restoration pass.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusManager.instance.primaryFocus?.unfocus();
        });
      });
    });
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 16, color: c.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(fontSize: 14, color: c.textTertiary),
                // Kill all border + fill states so only the outer rounded
                // Container is visible (the global inputDecorationTheme would
                // otherwise draw a rectangular outline behind this field).
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close, size: 16, color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads the image URL for [item] from Riverpod and renders [WardrobeItemCard].
class _ItemCardWithImage extends ConsumerWidget {
  const _ItemCardWithImage({required this.item, required this.allItems});

  final Item item;
  final List<Item> allItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(itemImageUrlProvider(item.imagePath));
    final imageUrl = switch (urlAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return WardrobeItemCard(
      item: item,
      allItems: allItems,
      imageUrl: imageUrl,
      onTap: () => context.push(Routes.itemDetail, extra: item),
      onLogWear: () async {
        final ok = await showLogWearSheet(context, item.name);
        if (!ok || !context.mounted) return;
        await runMutation(
          context,
          action: () => ref.read(wardrobeProvider.notifier).logWorn(item),
          successMessage: 'Logged a wear for ${item.name}',
        );
      },
      onBuildOutfit: () => openGeneratorWithPin(context, ref, item),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasItems});

  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom_outlined, size: 56, color: c.textTertiary),
          const SizedBox(height: 16),
          Text(
            hasItems ? 'No items match your filters' : 'Your wardrobe is empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasItems
                ? 'Try adjusting the search or filters'
                : 'Tap + to add your first item',
            style: TextStyle(fontSize: 13, color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final WardrobeFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<Occasion> _occasions;
  late List<ItemStatus> _statuses;
  late WardrobeSortBy _sortBy;
  late bool _favouritesOnly;

  static const _occasionLabels = ['Casual', 'Work', 'Active', 'Relax'];
  static const _occasionEnums = [
    Occasion.casual, Occasion.work, Occasion.active, Occasion.relax
  ];
  static const _statusLabels = ['In Wardrobe', 'Laundry', 'Lent', 'Stored'];
  static const _statusEnums = [
    ItemStatus.inWardrobe, ItemStatus.laundry, ItemStatus.lent, ItemStatus.stored
  ];

  @override
  void initState() {
    super.initState();
    _occasions = List.from(widget.initial.occasions);
    _statuses = List.from(widget.initial.statuses);
    _sortBy = widget.initial.sortBy;
    _favouritesOnly = widget.initial.favouritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Filter',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ),
          const SizedBox(height: 16),

          // Occasion
          _sectionLabel('Occasion'),
          const SizedBox(height: 8),
          _multiChipRow(
            labels: _occasionLabels,
            selected: (i) => _occasions.contains(_occasionEnums[i]),
            onToggle: (i) => setState(() {
              final o = _occasionEnums[i];
              _occasions.contains(o) ? _occasions.remove(o) : _occasions.add(o);
            }),
          ),
          const SizedBox(height: 16),

          // Status
          _sectionLabel('Status'),
          const SizedBox(height: 8),
          _multiChipRow(
            labels: _statusLabels,
            selected: (i) => _statuses.contains(_statusEnums[i]),
            onToggle: (i) => setState(() {
              final s = _statusEnums[i];
              _statuses.contains(s) ? _statuses.remove(s) : _statuses.add(s);
            }),
          ),
          const SizedBox(height: 16),

          // Sort by
          _sectionLabel('Sort by'),
          const SizedBox(height: 8),
          ...WardrobeSortBy.values.map((s) => _sortTile(s)),
          const SizedBox(height: 16),

          // Favourites toggle
          Row(
            children: [
              Expanded(
                child: Text('Favourites only',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
              ),
              Switch(
                value: _favouritesOnly,
                onChanged: (v) => setState(() => _favouritesOnly = v),
                activeTrackColor: c.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                WardrobeFilter(
                  occasions: _occasions,
                  statuses: _statuses,
                  sortBy: _sortBy,
                  favouritesOnly: _favouritesOnly,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Builder(
        builder: (context) => Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
      );

  Widget _multiChipRow({
    required List<String> labels,
    required bool Function(int) selected,
    required void Function(int) onToggle,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < labels.length; i++)
            AppFilterChip(
              label: labels[i],
              selected: selected(i),
              onTap: () => onToggle(i),
            ),
        ],
      );

  Widget _sortTile(WardrobeSortBy sort) => Builder(
        builder: (context) => InkWell(
          onTap: () => setState(() => _sortBy = sort),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _RadioDot(selected: _sortBy == sort),
                const SizedBox(width: 10),
                Text(sort.label,
                    style: TextStyle(
                        fontSize: 13, color: context.colors.textPrimary)),
              ],
            ),
          ),
        ),
      );
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.primary : c.surface,
        border: selected ? null : Border.all(color: c.border, width: 1.5),
      ),
      child: selected
          ? const Center(
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Colors.white,
              ),
            )
          : null,
    );
  }
}
