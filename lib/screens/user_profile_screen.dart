import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import '../utils/formatters.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSavingUsername = false;
  bool _isSavingContact = false;
  bool _isEditingContact = false;
  String? _errorMessage;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _addressFocusNode;
  final GlobalKey _usernameCardKey = GlobalKey();
  final GlobalKey<FormState> _contactFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _addressFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _usernameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final role = _role;
    final joinDateText = _joinDate != null
        ? Formatters.formatDate(_joinDate!)
        : 'Unknown';
    final photoUrl = _photoUrl;
    final avatarInitial = displayName.isNotEmpty
      ? displayName[0].toUpperCase()
      : 'S';

    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.darkSecondary,
        title: const Text('User Profile', style: AppConstants.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit username',
            onPressed: (_isLoading || _errorMessage != null || _profile == null)
                ? null
                : () {
                    if (_usernameCardKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _usernameCardKey.currentContext!,
                        duration: const Duration(milliseconds: 350),
                        alignment: 0.1,
                      );
                    }
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted) {
                        FocusScope.of(context).requestFocus(_usernameFocusNode);
                      }
                    });
                  },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
            ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryOrange.withOpacity(0.3),
                              AppConstants.darkSecondary,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Picture
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppConstants.primaryOrange,
                                      width: 3,
                                    ),
                                  ),
                                  child: photoUrl != null && photoUrl.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 60,
                                          backgroundImage: NetworkImage(photoUrl),
                                        )
                                      : CircleAvatar(
                                          radius: 60,
                                          backgroundColor: AppConstants.darkSecondary,
                                          child: Text(
                                            avatarInitial,
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.primaryOrange,
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showComingSoon('Change profile picture');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryOrange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppConstants.darkBackground,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            // Name
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: AppConstants.headingMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppConstants.primaryOrange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                role,
                                style: AppConstants.bodyMedium.copyWith(
                                  color: AppConstants.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            // Join Date
                            Text(
                              'Member since $joinDateText',
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile Information
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildUsernameEditor(),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildInfoCard(
                              icon: Icons.badge_outlined,
                              label: 'Role',
                              value: _safeValue(role, fallback: 'Staff'),
                            ),
                            const SizedBox(height: AppConstants.paddingLarge),

                            Row(
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: AppConstants.headingSmall,
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _isSavingContact
                                      ? null
                                      : () {
                                          if (_isEditingContact) {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              _isEditingContact = false;
                                              _phoneController.text =
                                                  _profile?['phone']?.toString() ?? '';
                                              _addressController.text =
                                                  _profile?['address']?.toString() ?? '';
                                            });
                                          } else {
                                            setState(() {
                                              _isEditingContact = true;
                                              _phoneController.text =
                                                  _profile?['phone']?.toString() ?? '';
                                              _addressController.text =
                                                  _profile?['address']?.toString() ?? '';
                                            });
                                            Future.microtask(() {
                                              if (mounted) {
                                                _phoneFocusNode.requestFocus();
                                              }
                                            });
                                          }
                                        },
                                  icon: Icon(
                                    _isEditingContact ? Icons.close : Icons.edit,
                                    size: 18,
                                  ),
                                  label: Text(_isEditingContact ? 'Cancel' : 'Edit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildInfoCard(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _safeValue(_email, fallback: 'Not provided'),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            if (!_isEditingContact) ...[
                              _buildInfoCard(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: _safeValue(_profile?['phone']),
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              _buildInfoCard(
                                icon: Icons.location_on_outlined,
                                label: 'Address',
                                value: _safeValue(_profile?['address']),
                              ),
                            ] else ...[
                              Form(
                                key: _contactFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEditableField(
                                      icon: Icons.phone_outlined,
                                      label: 'Phone',
                                      controller: _phoneController,
                                      focusNode: _phoneFocusNode,
                                      keyboardType: TextInputType.phone,
                                      validator: _validatePhone,
                                      hintText: 'e.g. +63 912 345 6789',
                                    ),
                                    const SizedBox(height: AppConstants.paddingMedium),
                                    _buildEditableField(
                                      icon: Icons.location_on_outlined,
                                      label: 'Address',
                                      controller: _addressController,
                                      focusNode: _addressFocusNode,
                                      keyboardType: TextInputType.streetAddress,
                                      maxLines: 3,
                                      hintText: 'Street, City, Province',
                                    ),
                                    const SizedBox(height: AppConstants.paddingMedium),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isSavingContact ? null : _saveContactInfo,
                                        icon: _isSavingContact
                                            ? SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.save),
                                        label: Text(
                                          _isSavingContact ? 'Saving...' : 'Save Details',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Account Settings
                            const Text(
                              'Account Settings',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildSettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              onTap: _showChangePasswordDialog,
                            ),
                            _buildSettingsTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              onTap: () {
                                _showComingSoon('Notifications');
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.security_outlined,
                              title: 'Privacy & Security',
                              onTap: () {
                                _showComingSoon('Privacy & Security');
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.language_outlined,
                              title: 'Language',
                              subtitle: 'English',
                              onTap: () {
                                _showComingSoon('Language Settings');
                              },
                            ),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Activity Stats
                            const Text(
                              'Activity Stats',
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildActivityStats(),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showLogoutDialog,
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.errorRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _loadUserProfile({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authService = context.read<AuthService>();
    final profile = await authService.fetchUserProfile();

    if (!mounted) {
      return;
    }

    if (profile == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load profile information.';
      });
      return;
    }

    profile['joinDate'] = _resolveDate(profile['joinDate'] ?? profile['createdAt']);
    profile['displayName'] = (profile['displayName'] as String?)?.trim() ?? '';
    profile['username'] = (profile['username'] as String?)?.trim() ?? '';
    profile['email'] = (profile['email'] as String?)?.trim() ?? '';
    profile['role'] = (profile['role'] as String?)?.trim() ?? '';
    final phoneRaw = profile['phone'];
    profile['phone'] = phoneRaw is String
      ? phoneRaw.trim()
      : (phoneRaw?.toString() ?? '');
    final addressRaw = profile['address'];
    profile['address'] = addressRaw is String
      ? addressRaw.trim()
      : (addressRaw?.toString() ?? '');

    setState(() {
      _profile = profile;
      _isLoading = false;
      _errorMessage = null;
    });

    final preferredUsername = profile['username'] as String;
    final fallbackName = profile['displayName'] as String;
    final controllerText = preferredUsername.isNotEmpty
        ? preferredUsername
        : fallbackName;
    _usernameController.value = TextEditingValue(text: controllerText);
    _phoneController.value = TextEditingValue(text: profile['phone']?.toString() ?? '');
    _addressController.value = TextEditingValue(text: profile['address']?.toString() ?? '');
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty.'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    final currentUsername = (_profile?['username'] as String?)?.trim() ??
        (_profile?['displayName'] as String?)?.trim() ?? '';
    if (currentUsername.toLowerCase() == username.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected.'),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
      return;
    }

    setState(() => _isSavingUsername = true);

    final authService = context.read<AuthService>();
    final result = await authService.updateProfile(
      displayName: username,
      username: username,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSavingUsername = false);

    if (result['success'] == true) {
      FocusScope.of(context).unfocus();
      await _loadUserProfile(showLoader: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Username updated.'),
          backgroundColor: AppConstants.successGreen,
        ),
      );
    } else {
      final error = result['error']?.toString() ?? 'Failed to update username.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  Future<void> _saveContactInfo() async {
    if (_contactFormKey.currentState?.validate() != true) {
      return;
    }

    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if ((_profile?['phone'] as String? ?? '').trim() == phone &&
        (_profile?['address'] as String? ?? '').trim() == address) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected.'),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
      return;
    }

    setState(() => _isSavingContact = true);

    final authService = context.read<AuthService>();
    final result = await authService.updateProfile(
      phone: phone,
      address: address,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSavingContact = false);

    if (result['success'] == true) {
      FocusScope.of(context).unfocus();
      setState(() => _isEditingContact = false);
      await _loadUserProfile(showLoader: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Profile updated.'),
          backgroundColor: AppConstants.successGreen,
        ),
      );
    } else {
      final error = result['error']?.toString() ?? 'Failed to update profile.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final authService = context.read<AuthService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              if (isSubmitting) {
                return;
              }
              if (formKey.currentState?.validate() != true) {
                return;
              }

              setStateDialog(() => isSubmitting = true);

              final result = await authService.changePassword(
                currentPassword: currentController.text,
                newPassword: newController.text,
              );

              if (!mounted) {
                return;
              }

              setStateDialog(() => isSubmitting = false);

              if (result['success'] == true) {
                if (navigator.canPop()) {
                  navigator.pop();
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message']?.toString() ?? 'Password updated.',
                    ),
                    backgroundColor: AppConstants.successGreen,
                  ),
                );
              } else {
                final error = result['error']?.toString() ??
                    'Failed to update password.';
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppConstants.errorRed,
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: AppConstants.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              title: const Text(
                'Change Password',
                style: AppConstants.headingSmall,
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    TextFormField(
                      controller: newController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your new password';
                        }
                        if (value != newController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: AppConstants.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }

  Widget _buildUsernameEditor() {
    return Container(
      key: _usernameCardKey,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username',
            style: AppConstants.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            style: AppConstants.bodyMedium,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveUsername(),
            decoration: InputDecoration(
              hintText: 'Enter username',
              filled: true,
              fillColor: AppConstants.darkSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: BorderSide(color: AppConstants.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: BorderSide(color: AppConstants.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: const BorderSide(color: AppConstants.primaryOrange),
              ),
              suffixIcon: _isSavingUsername
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.primaryOrange,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.save, color: AppConstants.primaryOrange),
                      tooltip: 'Save username',
                      onPressed: _saveUsername,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This name appears across the app for activity and reports.',
            style: AppConstants.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: CircularProgressIndicator(
          color: AppConstants.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppConstants.errorRed, size: 48),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Failed to load profile',
              style: AppConstants.headingSmall.copyWith(
                color: AppConstants.errorRed,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: () => _loadUserProfile(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String get _displayName {
    final name = _profile?['displayName'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    final username = _profile?['username'];
    if (username is String && username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'SmartServe User';
  }

  String get _role {
    final role = _profile?['role'];
    if (role is String && role.trim().isNotEmpty) {
      return role.trim();
    }
    return 'Staff';
  }

  String get _email {
    final email = _profile?['email'];
    if (email is String) {
      return email;
    }
    return '';
  }

  String? get _photoUrl {
    final url = _profile?['photoUrl'];
    if (url is String && url.trim().isNotEmpty) {
      return url.trim();
    }
    return null;
  }

  DateTime? get _joinDate {
    final joinDate = _profile?['joinDate'];
    return _resolveDate(joinDate);
  }

  DateTime? _resolveDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _safeValue(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^+\d]'), '');
    if (digitsOnly.length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(icon, color: AppConstants.primaryOrange, size: 20),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                label,
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppConstants.bodyMedium,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: AppConstants.darkSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: BorderSide(color: AppConstants.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: BorderSide(color: AppConstants.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: const BorderSide(color: AppConstants.primaryOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    final transactionService = context.read<TransactionService>();

    return StreamBuilder<List<TransactionRecord>>(
      stream: transactionService.watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppConstants.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppConstants.errorRed),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        'Unable to load activity stats',
                        style: AppConstants.bodyMedium.copyWith(
                          color: AppConstants.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  snapshot.error.toString(),
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? const <TransactionRecord>[];
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        final ordersProcessed = transactions.length;
        final totalSales = transactions.fold<double>(
          0,
          (sum, record) => sum + record.saleAmount,
        );

        final joinDate = _joinDate;
        final double hoursLogged = joinDate != null
            ? DateTime.now().difference(joinDate).inMinutes / 60.0
            : 0;

        String formattedHours;
        if (hoursLogged <= 0) {
          formattedHours = '0 h';
        } else if (hoursLogged < 1) {
          formattedHours = '${(hoursLogged * 60).round()} min';
        } else {
          formattedHours = '${hoursLogged.toStringAsFixed(1)} h';
        }

        String formatCount(int count) {
          return count.toString();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final spacing = AppConstants.paddingMedium;
            final isWide = constraints.maxWidth >= 520;
            final double itemWidth = isWide
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            final cards = <Widget>[
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  'Orders Processed',
                  isLoading ? '—' : formatCount(ordersProcessed),
                  Icons.receipt_long,
                  AppConstants.successGreen,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  'Total Sales',
                  isLoading
                      ? '—'
                      : Formatters.formatCurrency(totalSales),
                  Icons.trending_up,
                  AppConstants.primaryOrange,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  'Hours Logged',
                  formattedHours,
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards,
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppConstants.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.darkSecondary,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
          child: Icon(icon, color: AppConstants.primaryOrange, size: 20),
        ),
        title: Text(title, style: AppConstants.bodyMedium),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppConstants.textSecondary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppConstants.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppConstants.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.darkSecondary,
        title: const Text('Logout', style: AppConstants.headingSmall),
        content: const Text(
          'Are you sure you want to logout?',
          style: AppConstants.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Sign out from Firebase
              final authService = Provider.of<AuthService>(context, listen: false);
              final result = await authService.signOut();
              
              if (result['success'] && mounted) {
                // Navigate to login screen and clear navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: AppConstants.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}