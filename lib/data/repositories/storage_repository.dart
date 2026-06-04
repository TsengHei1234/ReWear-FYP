import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/supabase/supabase_client.dart';

/// Handles file uploads/deletes in the `wardrobe-items` Storage bucket.
///
/// Path convention: {user_id}/{item_id}/main.jpg (Database §12).
class StorageRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Uploads [file] to `{userId}/{itemId}/main.jpg`.
  /// Returns the signed public URL (valid 1 year — enough for in-app display).
  /// Uses upsert so re-uploading an edited photo replaces the old one.
  Future<String> uploadItemPhoto({
    required String userId,
    required String itemId,
    required File file,
  }) async {
    final path = AppConstants.itemImagePath(userId, itemId);
    await _client.storage.from(AppConstants.storageBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage
        .from(AppConstants.storageBucket)
        .createSignedUrl(path, 60 * 60 * 24 * 365);
  }

  /// Returns a fresh signed URL for an existing photo path.
  Future<String> getSignedUrl(String storagePath) {
    return _client.storage
        .from(AppConstants.storageBucket)
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  /// Removes the photo for the given item. No-op if the file doesn't exist.
  Future<void> deleteItemPhoto({
    required String userId,
    required String itemId,
  }) async {
    final path = AppConstants.itemImagePath(userId, itemId);
    await _client.storage.from(AppConstants.storageBucket).remove([path]);
  }
}
