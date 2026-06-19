import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/item_type_dictionary.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/mutation_helper.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../data/models/item.dart';
import '../../engine/condition/condition_engine.dart';
import '../../providers/wardrobe_providers.dart';

// ── Public entry points ───────────────────────────────────────────────────────

/// Thin wrapper for the Add flow.
class AddItemPage extends StatelessWidget {
  const AddItemPage({super.key});

  @override
  Widget build(BuildContext context) => const ItemFormPage();
}

/// Thin wrapper for the Edit flow.
class EditItemPage extends StatelessWidget {
  const EditItemPage({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) => ItemFormPage(existingItem: item);
}

// ── Core form page ────────────────────────────────────────────────────────────

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.existingItem});

  final Item? existingItem;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  // ── Form state ────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  ItemCategory _category = ItemCategory.top;
  String? _selectedType;
  List<String> _colorTags = [];
  List<Occasion> _occasionTags = [];
  InitialHistoryType _historyType = InitialHistoryType.brandNew;
  LastWornOption? _lastWornOption;
  WearCountOption? _wearCountOption;
  OwnedDurationOption? _ownedDurationOption;
  int _condition = AppConstants.defaultCondition;
  ConditionReviewMode _reviewMode = ConditionReviewMode.auto;
  bool _isFavorite = false;
  File? _photoFile;

  bool get _isEditing => widget.existingItem != null;

  ItemTypeDef? get _selectedTypeDef =>
      _selectedType == null ? null : ItemTypeDictionary.byStoredValue(_selectedType!);

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _nameController.text = item.name;
      _category = item.category;
      _selectedType = item.type;
      _colorTags = List.from(item.colorTags);
      _occasionTags = List.from(item.occasionTags);
      _condition = item.condition;
      _reviewMode = item.conditionReviewMode;
      _isFavorite = item.isFavorite;
    }
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onCategoryChanged(ItemCategory cat) {
    if (_category == cat) return;
    setState(() {
      _category = cat;
      _selectedType = null;
      _occasionTags = [];
    });
  }

  void _onTypeChanged(String? typeValue) {
    if (typeValue == null) return;
    final def = ItemTypeDictionary.byStoredValue(typeValue)!;
    setState(() {
      _selectedType = typeValue;
      _occasionTags = List.from(def.defaultOccasions);
    });
  }

  /// Single-select: tapping a swatch sets it as the only colour.
  /// Tapping the already-selected swatch does nothing (must always have 1).
  void _toggleColour(String swatchValue) {
    if (_colorTags.contains(swatchValue)) return; // already selected — no-op
    setState(() => _colorTags = [swatchValue]);
  }

  void _toggleOccasion(Occasion occ) {
    setState(() {
      if (_occasionTags.contains(occ)) {
        if (_occasionTags.length > 1) _occasionTags.remove(occ);
      } else {
        _occasionTags.add(occ);
      }
    });
  }

  bool _canSave() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_selectedType == null) return false;
    if (_colorTags.isEmpty) return false;
    if (_occasionTags.isEmpty) return false;
    if (!_isEditing) {
      if (_historyType == InitialHistoryType.alreadyOwnedWorn) {
        if (_lastWornOption == null ||
            _wearCountOption == null ||
            _ownedDurationOption == null) {
          return false;
        }
      } else if (_historyType == InitialHistoryType.alreadyOwnedUnworn) {
        if (_ownedDurationOption == null) { return false; }
      }
    }
    return true;
  }

  ({
    int wearCount,
    bool wearCountUnknown,
    DateTime? lastWornDate,
    bool lastWornUnknown,
    int initialUsageAgeDays,
    String? initialLastWornOption,
    String? initialWearCountOption,
    String? initialOwnedDurationOption,
    bool isNewItem,
  })
      _computeHistory() {
    switch (_historyType) {
      case InitialHistoryType.brandNew:
        return (
          wearCount: 0,
          wearCountUnknown: false,
          lastWornDate: null,
          lastWornUnknown: false,
          initialUsageAgeDays: 0,
          initialLastWornOption: null,
          initialWearCountOption: null,
          initialOwnedDurationOption: null,
          isNewItem: true,
        );
      case InitialHistoryType.alreadyOwnedWorn:
        final lastWornDays = _lastWornOption!.mappedDays;
        final mappedWearCount = _wearCountOption!.mappedCount;
        final durationDays = _ownedDurationOption!.mappedDays;
        DateTime? lastWornDate;
        if (lastWornDays != null) {
          lastWornDate = DateTime.now().subtract(Duration(days: lastWornDays));
        }
        return (
          wearCount: mappedWearCount ?? 0,
          wearCountUnknown: mappedWearCount == null,
          lastWornDate: lastWornDate,
          lastWornUnknown: lastWornDays == null,
          initialUsageAgeDays: durationDays,
          initialLastWornOption: _lastWornOption!.name,
          initialWearCountOption: _wearCountOption!.name,
          initialOwnedDurationOption: _ownedDurationOption!.name,
          isNewItem: false,
        );
      case InitialHistoryType.alreadyOwnedUnworn:
        return (
          wearCount: 0,
          wearCountUnknown: false,
          lastWornDate: null,
          lastWornUnknown: false,
          initialUsageAgeDays: _ownedDurationOption!.mappedDays,
          initialLastWornOption: null,
          initialWearCountOption: null,
          initialOwnedDurationOption: _ownedDurationOption!.name,
          isNewItem: false,
        );
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave()) return;
    FocusScope.of(context).unfocus();
    bool succeeded = false;
    await runMutation(
      context,
      action: () async {
        if (_isEditing) {
          await _saveEdit();
        } else {
          await _saveNew();
        }
        succeeded = true;
      },
      successMessage: _isEditing ? 'Item updated' : 'Item added to wardrobe',
    );
    if (mounted && succeeded) context.pop();
  }

  Future<void> _saveNew() async {
    final hist = _computeHistory();
    final typeDef = _selectedTypeDef!;
    final now = DateTime.now();
    final threshold = conditionThreshold(_selectedType!);
    int? nextDrop;
    if (_reviewMode == ConditionReviewMode.auto && _condition > 1) {
      nextDrop = hist.wearCount + threshold;
    }

    final item = Item(
      id: '',
      userId: '',
      name: _nameController.text.trim(),
      category: _category,
      type: _selectedType!,
      colorTags: List.from(_colorTags),
      occasionTags: List.from(_occasionTags),
      formalityLevel: typeDef.defaultFormality,
      condition: _condition,
      conditionReviewMode: _reviewMode,
      conditionNextDrop: nextDrop,
      isFavorite: _isFavorite,
      status: ItemStatus.inWardrobe,
      dateAdded: now,
      isNewItem: hist.isNewItem,
      initialHistoryType: _historyType,
      initialLastWornOption: hist.initialLastWornOption,
      initialWearCountOption: hist.initialWearCountOption,
      initialOwnedDurationOption: hist.initialOwnedDurationOption,
      initialUsageAgeDays: hist.initialUsageAgeDays,
      wearCountUnknown: hist.wearCountUnknown,
      lastWornUnknown: hist.lastWornUnknown,
      wearCount: hist.wearCount,
      lastWornDate: hist.lastWornDate,
      skipCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await ref
        .read(wardrobeProvider.notifier)
        .addItem(item: item, photo: _photoFile);
  }

  Future<void> _saveEdit() async {
    final existing = widget.existingItem!;
    final typeDef = _selectedTypeDef!;
    final now = DateTime.now();
    final threshold = conditionThreshold(_selectedType!);
    int? nextDrop;
    if (_reviewMode == ConditionReviewMode.auto && _condition > 1) {
      nextDrop = existing.wearCount + threshold;
    }

    final updated = Item(
      id: existing.id,
      userId: existing.userId,
      name: _nameController.text.trim(),
      category: _category,
      type: _selectedType!,
      colorTags: List.from(_colorTags),
      occasionTags: List.from(_occasionTags),
      formalityLevel: typeDef.defaultFormality,
      condition: _condition,
      conditionReviewMode: _reviewMode,
      conditionNextDrop: nextDrop,
      isFavorite: _isFavorite,
      status: existing.status,
      dateAdded: existing.dateAdded,
      isNewItem: existing.isNewItem,
      initialHistoryType: existing.initialHistoryType,
      initialLastWornOption: existing.initialLastWornOption,
      initialWearCountOption: existing.initialWearCountOption,
      initialOwnedDurationOption: existing.initialOwnedDurationOption,
      initialUsageAgeDays: existing.initialUsageAgeDays,
      wearCountUnknown: existing.wearCountUnknown,
      lastWornUnknown: existing.lastWornUnknown,
      wearCount: existing.wearCount,
      lastWornDate: existing.lastWornDate,
      skipCount: existing.skipCount,
      laundryStartedAt: existing.laundryStartedAt,
      keptUntil: existing.keptUntil,
      donatedAt: existing.donatedAt,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    await ref
        .read(wardrobeProvider.notifier)
        .editItem(item: updated, photo: _photoFile);
  }

  // ── Photo picker + cropper ────────────────────────────────────────────────

  /// Picks an image from [source], then launches the 1:1 crop UI.
  /// Sets [_photoFile] only if the user confirms the crop.
  Future<void> _pickAndCrop(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      // Cap output resolution so full-camera shots (12 MP+) don't generate
      // multi-MB uploads. 1600×1600 at 85 % JPEG ≈ 200–400 KB — sharp enough
      // for the full-screen 1:1 detail view on any current phone screen.
      maxWidth: 1600,
      maxHeight: 1600,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped != null && mounted) {
      setState(() => _photoFile = File(cropped.path));
    }
  }

  Future<void> _showPhotoPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final c = sheetCtx.colors;
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: c.primary),
                title: Text('Choose from gallery',
                    style: TextStyle(color: c.textPrimary, fontSize: 14)),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  await _pickAndCrop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: c.primary),
                title: Text('Take a photo',
                    style: TextStyle(color: c.textPrimary, fontSize: 14)),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  await _pickAndCrop(ImageSource.camera);
                },
              ),
              if (_photoFile != null || widget.existingItem?.imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove photo',
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    setState(() => _photoFile = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final imageAsync = widget.existingItem?.imagePath != null
        ? ref.watch(itemImageUrlProvider(widget.existingItem!.imagePath))
        : null;
    final existingImageUrl = switch (imageAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Item' : 'Add Item',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildPhotoSection(c, existingImageUrl),
            const SizedBox(height: 24),
            _sectionTitle('Item Name', c),
            const SizedBox(height: 8),
            _buildNameField(c),
            const SizedBox(height: 20),
            _sectionTitle('Category', c),
            const SizedBox(height: 10),
            _buildCategorySelector(c),
            const SizedBox(height: 20),
            _sectionTitle('Type', c),
            const SizedBox(height: 8),
            _buildTypeDropdown(c),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _sectionTitle('Primary Colour', c)),
                Text(
                  'select 1',
                  style: TextStyle(fontSize: 11, color: c.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildColourGrid(c),
            const SizedBox(height: 20),
            _sectionTitle('Occasions', c),
            const SizedBox(height: 8),
            _buildOccasionChips(c),
            if (!_isEditing) ...[
              const SizedBox(height: 24),
              _sectionTitle('Item History', c),
              const SizedBox(height: 4),
              Text(
                "Tell us about this item's past",
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              ),
              const SizedBox(height: 12),
              _buildHistorySection(c),
            ],
            const SizedBox(height: 24),
            _sectionTitle('Condition', c),
            const SizedBox(height: 10),
            _buildConditionSection(c),
            const SizedBox(height: 16),
            _buildFavouriteRow(c),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave() ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                disabledBackgroundColor: c.border,
                foregroundColor: Colors.white,
                disabledForegroundColor: c.textTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Add to Wardrobe',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section widgets ───────────────────────────────────────────────────────

  Widget _sectionTitle(String label, AppColorsTheme c) => Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      );

  // Photo ───────────────────────────────────────────────────────────────────

  Widget _buildPhotoSection(AppColorsTheme c, String? existingImageUrl) {
    Widget photoContent;

    if (_photoFile != null) {
      photoContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_photoFile!, fit: BoxFit.cover,
            width: double.infinity, height: 200),
      );
    } else if (existingImageUrl != null) {
      photoContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: existingImageUrl,
          cacheKey: widget.existingItem?.imagePath != null
              ? '${widget.existingItem!.imagePath}_v${widget.existingItem!.updatedAt.millisecondsSinceEpoch}'
              : null,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (ctx, url) => Container(
            color: c.surface,
            height: 200,
            child: Center(
                child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)),
          ),
          errorWidget: (ctx, url, err) => _photoPlaceholder(c),
        ),
      );
    } else {
      photoContent = _photoPlaceholder(c);
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _showPhotoPicker,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: photoContent,
          ),
        ),
        if (_photoFile != null || existingImageUrl != null)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _showPhotoPicker,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _photoPlaceholder(AppColorsTheme c) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 32, color: c.textTertiary),
          const SizedBox(height: 8),
          Text('Add Photo',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
          const SizedBox(height: 2),
          Text('optional',
              style: TextStyle(fontSize: 11, color: c.textTertiary)),
        ],
      );

  // Name ────────────────────────────────────────────────────────────────────

  Widget _buildNameField(AppColorsTheme c) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _nameController,
          style: TextStyle(fontSize: 14, color: c.textPrimary),
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. Grey hoodie, Blue jeans…',
            hintStyle: TextStyle(fontSize: 14, color: c.textTertiary),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            counterText: '',
          ),
        ),
      );

  // Category ────────────────────────────────────────────────────────────────

  static const _catOptions = [
    (cat: ItemCategory.top, label: 'Tops'),
    (cat: ItemCategory.bottom, label: 'Bottoms'),
    (cat: ItemCategory.outerwear, label: 'Outerwear'),
    (cat: ItemCategory.footwear, label: 'Shoes'),
    (cat: ItemCategory.others, label: 'Others'),
  ];

  Widget _buildCategorySelector(AppColorsTheme c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _catOptions.map((opt) {
            final selected = _category == opt.cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onCategoryChanged(opt.cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? c.primary : c.surface,
                    border: Border.all(
                      color: selected ? c.primary : c.border,
                      width: selected ? 1.5 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : c.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  // Type ────────────────────────────────────────────────────────────────────

  Widget _buildTypeDropdown(AppColorsTheme c) {
    final types = ItemTypeDictionary.forCategory(_category);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedType,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: c.surface,
        hint: Text('Select type…',
            style: TextStyle(fontSize: 14, color: c.textTertiary)),
        style: TextStyle(fontSize: 14, color: c.textPrimary),
        icon: Icon(Icons.keyboard_arrow_down, color: c.textTertiary, size: 20),
        items: types
            .map((t) => DropdownMenuItem<String>(
                  value: t.storedValue,
                  child: Text(t.displayLabel),
                ))
            .toList(),
        onChanged: _onTypeChanged,
      ),
    );
  }

  // Colours ─────────────────────────────────────────────────────────────────

  Widget _buildColourGrid(AppColorsTheme c) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: SwatchColour.values.map((swatch) {
          final color = kSwatchColours[swatch]!;
          final selected = _colorTags.contains(swatch.value);
          return GestureDetector(
            onTap: () => _toggleColour(swatch.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: c.primary, width: 2.5)
                    : swatch == SwatchColour.white
                        ? Border.all(color: c.border, width: 0.5)
                        : null,
              ),
              child: selected
                  ? Icon(Icons.check,
                      size: 18, color: _iconOnColour(color))
                  : null,
            ),
          );
        }).toList(),
      );

  Color _iconOnColour(Color bg) =>
      bg.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;

  // Occasions ───────────────────────────────────────────────────────────────

  Widget _buildOccasionChips(AppColorsTheme c) {
    final def = _selectedTypeDef;
    if (def == null) {
      return Text('Select a type first to set occasions',
          style: TextStyle(fontSize: 13, color: c.textTertiary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: def.allowedOccasions.map((occ) {
        final label =
            occ.name[0].toUpperCase() + occ.name.substring(1);
        return AppFilterChip(
          label: label,
          selected: _occasionTags.contains(occ),
          onTap: () => _toggleOccasion(occ),
        );
      }).toList(),
    );
  }

  // History ─────────────────────────────────────────────────────────────────

  Widget _buildHistorySection(AppColorsTheme c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _historyCard(
            title: 'Brand New',
            subtitle: 'Just bought or received as new',
            selected: _historyType == InitialHistoryType.brandNew,
            onTap: () => setState(() {
              _historyType = InitialHistoryType.brandNew;
              _lastWornOption = null;
              _wearCountOption = null;
              _ownedDurationOption = null;
            }),
            c: c,
          ),
          const SizedBox(height: 8),
          _historyCard(
            title: 'Already Owned — Worn',
            subtitle: "I've worn it before",
            selected: _historyType == InitialHistoryType.alreadyOwnedWorn,
            onTap: () => setState(
                () => _historyType = InitialHistoryType.alreadyOwnedWorn),
            c: c,
          ),
          const SizedBox(height: 8),
          _historyCard(
            title: 'Already Owned — Unworn',
            subtitle: "Owned it but never wore it",
            selected: _historyType == InitialHistoryType.alreadyOwnedUnworn,
            onTap: () => setState(() {
              _historyType = InitialHistoryType.alreadyOwnedUnworn;
              _lastWornOption = null;
              _wearCountOption = null;
            }),
            c: c,
          ),
          if (_historyType == InitialHistoryType.alreadyOwnedWorn) ...[
            const SizedBox(height: 16),
            _dropdownRow<LastWornOption>(
              label: 'Last worn',
              value: _lastWornOption,
              options: LastWornOption.values,
              labelOf: (o) => o.label,
              onChanged: (o) => setState(() => _lastWornOption = o),
              c: c,
            ),
            const SizedBox(height: 12),
            _dropdownRow<WearCountOption>(
              label: 'Approximate wear count',
              value: _wearCountOption,
              options: WearCountOption.values,
              labelOf: (o) => o.label,
              onChanged: (o) => setState(() => _wearCountOption = o),
              c: c,
            ),
            const SizedBox(height: 12),
            _dropdownRow<OwnedDurationOption>(
              label: 'How long owned',
              value: _ownedDurationOption,
              options: OwnedDurationOption.values,
              labelOf: (o) => o.label,
              onChanged: (o) => setState(() => _ownedDurationOption = o),
              c: c,
            ),
          ] else if (_historyType == InitialHistoryType.alreadyOwnedUnworn) ...[
            const SizedBox(height: 16),
            _dropdownRow<OwnedDurationOption>(
              label: 'How long owned',
              value: _ownedDurationOption,
              options: OwnedDurationOption.values,
              labelOf: (o) => o.label,
              onChanged: (o) => setState(() => _ownedDurationOption = o),
              c: c,
            ),
          ],
        ],
      );

  Widget _historyCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required AppColorsTheme c,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? c.primaryLight : c.surface,
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _radioDot(selected, c),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: c.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _radioDot(bool selected, AppColorsTheme c) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? c.primary : c.surface,
          border: selected ? null : Border.all(color: c.border, width: 1.5),
        ),
        child: selected
            ? const Center(
                child: CircleAvatar(radius: 4, backgroundColor: Colors.white))
            : null,
      );

  Widget _dropdownRow<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
    required AppColorsTheme c,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
          const SizedBox(height: 6),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: c.surface,
              hint: Text('Select…',
                  style: TextStyle(fontSize: 14, color: c.textTertiary)),
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              icon: Icon(Icons.keyboard_arrow_down,
                  color: c.textTertiary, size: 20),
              items: options
                  .map((o) =>
                      DropdownMenuItem<T>(value: o, child: Text(labelOf(o))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      );

  // Condition ───────────────────────────────────────────────────────────────

  Widget _buildConditionSection(AppColorsTheme c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              final val = i + 1;
              final selected = _condition == val;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: val < 5 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _condition = val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.surface,
                        border: Border.all(
                          color: selected ? c.primary : c.border,
                          width: selected ? 1.5 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color:
                                selected ? Colors.white : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              conditionLabel(_condition),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto condition review',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                    if (_reviewMode == ConditionReviewMode.auto &&
                        _selectedType != null)
                      Text(
                        'Drops every ${conditionThreshold(_selectedType!)} wears',
                        style:
                            TextStyle(fontSize: 11, color: c.textTertiary),
                      ),
                  ],
                ),
              ),
              Text(
                _reviewMode == ConditionReviewMode.auto ? 'AUTO' : 'MANUAL',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _reviewMode == ConditionReviewMode.auto
                        ? c.primary
                        : c.textTertiary),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _reviewMode == ConditionReviewMode.auto,
                onChanged: (v) => setState(() => _reviewMode =
                    v ? ConditionReviewMode.auto : ConditionReviewMode.manual),
                activeTrackColor: c.primary,
              ),
            ],
          ),
        ],
      );

  // Favourite ───────────────────────────────────────────────────────────────

  Widget _buildFavouriteRow(AppColorsTheme c) => Row(
        children: [
          Icon(Icons.star_border, size: 20, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add to favourites',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
          ),
          Switch(
            value: _isFavorite,
            onChanged: (v) => setState(() => _isFavorite = v),
            activeTrackColor: c.primary,
          ),
        ],
      );
}
