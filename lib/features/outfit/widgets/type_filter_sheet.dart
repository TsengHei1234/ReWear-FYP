import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/item_type_dictionary.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/models/item.dart';

/// Bottom sheet for the Candidate Pool Type Filter. One dropdown per active
/// outfit slot (Top always, Bottom always, Outerwear/Shoes when their layer
/// toggle is on). Pinned slot shows a locked indicator instead of a dropdown.
/// Returns `Map<ItemCategory, String>` (non-null values only) on Apply, or null
/// if dismissed without applying.
class TypeFilterSheet extends StatefulWidget {
  const TypeFilterSheet({
    super.key,
    required this.selectedTypes,
    required this.requireOuterwear,
    required this.requireShoes,
    required this.pinnedItem,
    required this.occasion,
    required this.wardrobe,
  });

  final Map<ItemCategory, String> selectedTypes;
  final bool requireOuterwear;
  final bool requireShoes;
  final Item? pinnedItem;
  final Occasion? occasion;
  final List<Item> wardrobe;

  @override
  State<TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<TypeFilterSheet> {
  // null value = "Any type" (no filter for this category).
  late final Map<ItemCategory, String?> _pending;

  @override
  void initState() {
    super.initState();
    _pending = {
      for (final entry in widget.selectedTypes.entries) entry.key: entry.value,
    };
  }

  bool get _hasActiveFilters => _pending.values.any((v) => v != null);

  List<String> _typesFor(ItemCategory category) {
    final occasion = widget.occasion;
    final types = widget.wardrobe
        .where((i) =>
            i.category == category &&
            i.status == ItemStatus.inWardrobe &&
            i.condition >= 2 &&
            (occasion == null || i.occasionTags.contains(occasion)))
        .map((i) => i.type)
        .toSet()
        .toList();
    types.sort((a, b) {
      final la = ItemTypeDictionary.byStoredValue(a)?.displayLabel ?? a;
      final lb = ItemTypeDictionary.byStoredValue(b)?.displayLabel ?? b;
      return la.compareTo(lb);
    });
    return types;
  }

  String _label(String storedValue) =>
      ItemTypeDictionary.byStoredValue(storedValue)?.displayLabel ?? storedValue;

  void _onApply() {
    final result = Map<ItemCategory, String>.fromEntries(
      _pending.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pinnedCat = widget.pinnedItem?.category;

    // Sections in display order; pair = (category, header label, isEditable).
    final sections = [
      (ItemCategory.top, 'TOP', pinnedCat != ItemCategory.top),
      (ItemCategory.bottom, 'BOTTOM', pinnedCat != ItemCategory.bottom),
      if (widget.requireOuterwear)
        (
          ItemCategory.outerwear,
          'OUTERWEAR',
          pinnedCat != ItemCategory.outerwear
        ),
      if (widget.requireShoes)
        (ItemCategory.footwear, 'SHOES', pinnedCat != ItemCategory.footwear),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
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
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Type Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: () => setState(
                      () => _pending.updateAll((key, _) => null)),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // One section per active slot
          for (final (category, header, isEditable) in sections) ...[
            _buildSection(category, header, isEditable),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
          // Apply
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ItemCategory category, String header, bool isEditable) {
    final c = context.colors;
    final isPinned = widget.pinnedItem?.category == category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              header,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: c.textTertiary,
              ),
            ),
            if (isPinned) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock, size: 10, color: c.textTertiary),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (isPinned)
          _LockedDropdown(label: _label(widget.pinnedItem!.type))
        else
          _TypeDropdown(
            value: _pending[category],
            types: isEditable ? _typesFor(category) : const [],
            labelFor: _label,
            onChanged: (val) => setState(() => _pending[category] = val),
          ),
      ],
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.value,
    required this.types,
    required this.labelFor,
    required this.onChanged,
  });

  final String? value;
  final List<String> types;
  final String Function(String) labelFor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: c.surface,
        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: c.textTertiary),
        style: TextStyle(fontSize: 14, color: c.textPrimary),
        onChanged: onChanged,
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Any type',
              style: TextStyle(fontSize: 14, color: c.textTertiary),
            ),
          ),
          for (final type in types)
            DropdownMenuItem<String?>(
              value: type,
              child: Text(
                labelFor(type),
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedDropdown extends StatelessWidget {
  const _LockedDropdown({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
            ),
            Icon(Icons.lock, size: 14, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
