import 'dart:io';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/data/auth_repository.dart';

/// UC-06/brief P10 item 7: "edit profile (name, avatar, WhatsApp number)". Phone/role stay
/// read-only — `MeSerializer`'s `read_only_fields` (docs/API.md) never accepted them.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  String? _newAvatarPath;
  bool _saving = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final user = switch (ref.read(authStateProvider)) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };
    _nameController = TextEditingController(text: user?.name ?? '');
    _whatsappController = TextEditingController(text: user?.whatsappPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _newAvatarPath = picked.path);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _fieldErrors = const {};
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            name: _nameController.text.trim(),
            whatsappPhone: _whatsappController.text.trim(),
            avatarPath: _newAvatarPath,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.editProfileSaved)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = switch (ref.watch(authStateProvider)) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEditProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryTint,
                  backgroundImage: _newAvatarPath != null
                      ? FileImage(File(_newAvatarPath!)) as ImageProvider
                      : (user?.avatar != null ? NetworkImage(user!.avatar!) : null),
                  child: _newAvatarPath == null && user?.avatar == null
                      ? const Icon(Icons.person_outline, size: 36, color: AppColors.primary)
                      : null,
                ),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.surface),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _nameController,
            label: l10n.authName,
            errorText: _fieldErrors['name']?.first,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.authPhone,
            controller: TextEditingController(text: user?.phone ?? ''),
            enabled: false,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _whatsappController,
            label: l10n.editProfileWhatsappLabel,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            errorText: _fieldErrors['whatsapp_phone']?.first,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: l10n.commonSave,
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}
