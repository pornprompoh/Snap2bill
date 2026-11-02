import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_top_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> thaiBanks = [
    'ธนาคารกสิกรไทย (KBANK)',
    'ธนาคารไทยพาณิชย์ (SCB)',
    'ธนาคารกรุงไทย (KTB)',
    'ธนาคารกรุงเทพ (BBL)',
    'ธนาคารกรุงศรีอยุธยา (BAY)',
    'ธนาคารทหารไทยธนชาต (TTB)',
    'ธนาคารออมสิน (GSB)',
    'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร (ธ.ก.ส.)',
    'ธนาคารยูโอบี (UOB)',
    'ธนาคารเกียรตินาคินภัทร (KKP)',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptPayController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  String _promptPayType = 'phone';
  String? _selectedBank;
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
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
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
    _selectedBank = profile?.bankName;
    if (_selectedBank != null && !thaiBanks.contains(_selectedBank)) {
      _selectedBank = thaiBanks.first;
    }
    _bankAccountController.text = profile?.bankAccountNumber ?? '';
    _bankAccountNameController.text =
        profile?.bankAccountName ?? (profile?.displayName ?? '');
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
    final bankAccountNumber = _bankAccountController.text.trim();
    final bankAccountName = _bankAccountNameController.text.trim();

    final succeeded = await context.read<UserProvider>().saveProfile(
      name: _nameController.text.trim(),
      promptPayNumber: promptPayNumber.isEmpty ? null : promptPayNumber,
      promptPayType: promptPayNumber.isEmpty ? null : _promptPayType,
      bankName: bankAccountNumber.isEmpty
          ? null
          : (_selectedBank ?? thaiBanks.first),
      bankAccountNumber: bankAccountNumber.isEmpty ? null : bankAccountNumber,
      bankAccountName: bankAccountNumber.isEmpty
          ? null
          : (bankAccountName.isEmpty
                ? _nameController.text.trim()
                : bankAccountName),
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.darkCardBackground : AppColors.white;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.background,
          appBar: CustomTopAppBar(
            title: 'โปรไฟล์ส่วนตัว',
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.background,
            foregroundColor: isDark ? AppColors.white : AppColors.black,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userProvider.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.lightPink,
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 36,
                                color: AppColors.pink,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ข้อมูลบัญชีของคุณ',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.white
                                          : AppColors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: AppColors.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing) ...[
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
                                  textInputAction: TextInputAction.next,
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
                                Text(
                                  'ข้อมูลบัญชีธนาคาร (ทางเลือกเพิ่มเติม)',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ระบุเพื่อให้เพื่อนสามารถโอนผ่านเลขบัญชีธนาคารได้',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppConstants.paddingS),
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      _selectedBank ?? thaiBanks.first,
                                  decoration: const InputDecoration(
                                    labelText: 'ธนาคาร',
                                    prefixIcon: Icon(
                                      Icons.account_balance_outlined,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: thaiBanks.map((bank) {
                                    return DropdownMenuItem<String>(
                                      value: bank,
                                      child: Text(
                                        bank,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedBank = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppConstants.paddingS),
                                TextFormField(
                                  controller: _bankAccountController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'เลขที่บัญชีธนาคาร',
                                    prefixIcon: Icon(Icons.numbers_outlined),
                                    helperText:
                                        'ระบุเลขที่บัญชี 10-15 หลัก (ไม่บังคับ)',
                                  ),
                                ),
                                const SizedBox(height: AppConstants.paddingS),
                                TextFormField(
                                  controller: _bankAccountNameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อบัญชีธนาคาร',
                                    prefixIcon: Icon(Icons.person_pin_outlined),
                                    helperText: 'ชื่อ-นามสกุล เจ้าของบัญชี',
                                  ),
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
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.pink.withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Display Name',
                                  style: TextStyle(
                                    color: AppColors.gray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'PromptPay',
                                  style: TextStyle(
                                    color: AppColors.gray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userProvider
                                                    .currentUser
                                                    ?.promptPayNumber
                                                    ?.isNotEmpty ==
                                                true
                                            ? userProvider
                                                  .currentUser!
                                                  .promptPayNumber!
                                            : 'ยังไม่ได้ตั้งค่า',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.white
                                              : AppColors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
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
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightPink,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.pink,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _promptPayTypeLabel(
                                            userProvider
                                                .currentUser
                                                ?.promptPayType,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                          Container(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingM,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'โอนด้วยเลขบัญชีธนาคาร',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                if (userProvider.currentUser?.hasBankTransfer ==
                                    true) ...[
                                  Text(
                                    'ธนาคาร',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userProvider.currentUser!.bankName ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'เลขที่บัญชี',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userProvider
                                                  .currentUser!
                                                  .bankAccountNumber ??
                                              '-',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy_rounded,
                                          size: 18,
                                        ),
                                        tooltip: 'คัดลอกเลขบัญชี',
                                        onPressed: () {
                                          final num = userProvider
                                              .currentUser!
                                              .bankAccountNumber;
                                          if (num != null && num.isNotEmpty) {
                                            Clipboard.setData(
                                              ClipboardData(text: num),
                                            );
                                            _showMessage(
                                              'คัดลอกเลขบัญชีแล้ว',
                                              AppColors.success,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ชื่อบัญชี',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userProvider.currentUser!.bankAccountName ??
                                        '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ] else ...[
                                  Text(
                                    'ยังไม่ได้ตั้งค่าเลขบัญชีธนาคาร',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'กด "แก้ไขโปรไฟล์" ด้านล่างเพื่อเพิ่มทางเลือกโอนด้วยเลขบัญชีธนาคาร',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    color: themeProvider.isDarkMode
                                        ? Colors.amber
                                        : AppColors.primary,
                                  ),
                                  title: Text(
                                    'โหมดมืด (Dark Mode)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    themeProvider.isDarkMode
                                        ? 'เปิดใช้งานธีมมืด สบายตา'
                                        : 'เปิดใช้งานธีมสว่าง คมชัด',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  value: themeProvider.isDarkMode,
                                  activeTrackColor: AppColors.primary
                                      .withValues(alpha: 0.5),
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (_) => themeProvider.toggleTheme(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppConstants.paddingL),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealGreen,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: userProvider.isLoading
                                ? null
                                : () => _beginEditing(userProvider.currentUser),
                            child: const Text(
                              'แก้ไขโปรไฟล์',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD3455B),
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _logout(context),
                            child: const Text(
                              'ออกจากระบบ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
