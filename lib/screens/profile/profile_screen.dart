import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptPayController = TextEditingController();
  String _promptPayType = 'phone';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptPayController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      await context.read<UserProvider>().loadProfile();
    } catch (_) {
      if (mounted) {
        _showMessage('ไม่สามารถโหลดข้อมูลโปรไฟล์ได้', AppColors.error);
      }
    }
  }

  void _setFormValues(UserModel? profile) {
    _nameController.text = profile?.displayName ?? '';
    _promptPayController.text = profile?.promptPayNumber ?? '';
    _promptPayType = profile?.promptPayType == 'id_card' ? 'id_card' : 'phone';
  }

  void _beginEditing(UserModel? profile) {
    _setFormValues(profile);
    setState(() => _isEditing = true);
  }

  void _cancelEditing(UserModel? profile) {
    _formKey.currentState?.reset();
    _setFormValues(profile);
    setState(() => _isEditing = false);
  }

  void _changePromptPayType(String? type) {
    if (type == null || type == _promptPayType) return;
    setState(() {
      _promptPayType = type;
      _promptPayController.clear();
    });
  }

  String _promptPayTypeLabel(String? type) {
    return type == 'id_card' ? 'เลขบัตรประชาชน' : 'เบอร์มือถือ';
  }

  void _syncProfile(UserProvider provider) {
    final profile = provider.currentUser;
    if (!_isEditing && profile != null) _setFormValues(profile);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final promptPayNumber = _promptPayController.text.trim();
    final succeeded = await context.read<UserProvider>().saveProfile(
      name: _nameController.text.trim(),
      promptPayNumber: promptPayNumber.isEmpty ? null : promptPayNumber,
      promptPayType: promptPayNumber.isEmpty ? null : _promptPayType,
    );

    if (!mounted) return;
    if (succeeded) {
      setState(() => _isEditing = false);
      _showMessage('บันทึกโปรไฟล์เรียบร้อยแล้ว', AppColors.success);
    } else {
      _showMessage('บันทึกไม่สำเร็จ กรุณาลองอีกครั้ง', AppColors.error);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        // ล้างประวัติหน้าจอทั้งหมดแล้วเด้งกลับไปหน้า Login
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถออกจากระบบได้ กรุณาลองใหม่')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        _syncProfile(userProvider);
        final email =
            Supabase.instance.client.auth.currentUser?.email ??
            'ไม่พบข้อมูลอีเมล';

        return Scaffold(
          appBar: AppBar(title: const Text('โปรไฟล์ส่วนตัว')),
          body: Column(
            children: [
              if (userProvider.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppConstants.paddingS),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ข้อมูลบัญชีของคุณ',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingL),
                      if (_isEditing)
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ข้อมูลส่วนตัว',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppConstants.paddingS),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'กรุณากรอกชื่อที่ต้องการแสดง'
                                    : null,
                              ),
                              const SizedBox(height: AppConstants.paddingL),
                              Text(
                                'ข้อมูล PromptPay',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppConstants.paddingS),
                              RadioGroup<String>(
                                groupValue: _promptPayType,
                                onChanged: _changePromptPayType,
                                child: const Column(
                                  children: [
                                    RadioListTile<String>(
                                      value: 'phone',
                                      title: Text('เบอร์มือถือ'),
                                      secondary: Icon(Icons.phone_android),
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppColors.primary,
                                      dense: true,
                                    ),
                                    RadioListTile<String>(
                                      value: 'id_card',
                                      title: Text('เลขบัตรประชาชน'),
                                      secondary: Icon(
                                        Icons.credit_card_outlined,
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppColors.primary,
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),
                              TextFormField(
                                controller: _promptPayController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                    _promptPayType == 'phone' ? 10 : 13,
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: _promptPayType == 'phone'
                                      ? 'เบอร์มือถือ PromptPay'
                                      : 'เลขบัตรประชาชน PromptPay',
                                  prefixIcon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  helperText: _promptPayType == 'phone'
                                      ? 'ระบุ 10 หลัก หรือเว้นว่างหากไม่ต้องการใช้ PromptPay'
                                      : 'ระบุ 13 หลัก หรือเว้นว่างหากไม่ต้องการใช้ PromptPay',
                                ),
                                validator: (value) {
                                  final number = value?.trim() ?? '';
                                  if (number.isEmpty) return null;
                                  final expectedLength =
                                      _promptPayType == 'phone' ? 10 : 13;
                                  if (number.length != expectedLength) {
                                    return 'กรุณากรอกให้ครบ $expectedLength หลัก';
                                  }
                                  if (_promptPayType == 'phone' &&
                                      !number.startsWith('0')) {
                                    return 'เบอร์มือถือ PromptPay ต้องขึ้นต้นด้วย 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingL),
                              CustomButton(
                                text: 'บันทึกข้อมูล',
                                onPressed: _saveProfile,
                                isLoading: userProvider.isLoading,
                              ),
                              const SizedBox(height: AppConstants.paddingS),
                              OutlinedButton.icon(
                                onPressed: userProvider.isLoading
                                    ? null
                                    : () => _cancelEditing(
                                        userProvider.currentUser,
                                      ),
                                icon: const Icon(Icons.close),
                                label: const Text('ยกเลิก'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(AppConstants.paddingM),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Display Name',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userProvider
                                            .currentUser
                                            ?.displayName
                                            ?.isNotEmpty ==
                                        true
                                    ? userProvider.currentUser!.displayName!
                                    : 'ยังไม่ได้ตั้งชื่อ',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppConstants.paddingL),
                              Text(
                                'PromptPay',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      userProvider
                                              .currentUser
                                              ?.promptPayNumber ??
                                          'ยังไม่ได้ตั้งค่า',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  if (userProvider
                                              .currentUser
                                              ?.promptPayNumber !=
                                          null &&
                                      userProvider
                                          .currentUser!
                                          .promptPayNumber!
                                          .isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _promptPayTypeLabel(
                                          userProvider
                                              .currentUser
                                              ?.promptPayType,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppConstants.paddingL),
                      if (!_isEditing)
                        CustomButton(
                          text: 'แก้ไขโปรไฟล์',
                          onPressed: userProvider.isLoading
                              ? null
                              : () => _beginEditing(userProvider.currentUser),
                        ),
                      const SizedBox(height: AppConstants.paddingS),
                      CustomButton(
                        text: 'ออกจากระบบ',
                        backgroundColor: AppColors.error,
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
