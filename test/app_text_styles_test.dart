import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/theme/app_text_styles.dart';
import 'package:snap2bill/utils/constants.dart';
import 'package:snap2bill/utils/validation.dart';
import 'package:snap2bill/models/bill_model.dart';

void main() {
  group('AppTextStyles and Typography Tests', () {
    test('fontFamily is Itim for all major styles', () {
      expect(AppTextStyles.fontFamily, 'Itim');
      expect(AppTextStyles.headline.fontFamily, 'Itim');
      expect(AppTextStyles.title.fontFamily, 'Itim');
      expect(AppTextStyles.body.fontFamily, 'Itim');
      expect(AppTextStyles.caption.fontFamily, 'Itim');
    });

    test('font sizes are comfortably readable', () {
      expect(AppTextStyles.headline.fontSize, 28);
      expect(AppTextStyles.title.fontSize, 20);
      expect(AppTextStyles.body.fontSize, 16.5);
      expect(AppTextStyles.caption.fontSize, 13.5);
    });

    test('textTheme builds with consistent typography hierarchy', () {
      final theme = AppTextStyles.textTheme;
      expect(theme.headlineLarge?.fontFamily, 'Itim');
      expect(theme.bodyLarge?.fontSize, 16.5);
      expect(theme.titleLarge?.fontSize, 20);
      expect(theme.bodySmall?.fontSize, 13.5);
    });
  });

  group('AppColors Theme Palette Tokens', () {
    test('tokens match brand requirements', () {
      expect(AppColors.pink, const Color(0xFFF76DB7));
      expect(AppColors.primaryOrange, const Color(0xFFE37A51));
      expect(AppColors.tealGreen, const Color(0xFF047E69));
      expect(AppColors.lightPink, const Color(0xFFFFD5EC));
      expect(AppColors.paleYellow, const Color(0xFFFFF9D4));
      expect(AppColors.lightGreen, const Color(0xFFB6F7C1));
      expect(AppColors.yellow, const Color(0xFFFFC800));
      expect(AppColors.white, const Color(0xFFFFFFFF));
      expect(AppColors.black, const Color(0xFF000000));
      expect(AppColors.gray, const Color(0xFF757575));
      expect(AppColors.textPrimary, const Color(0xFF000000));
    });
  });

  group('AppConstants Standards', () {
    test('padding and layout constants are properly defined', () {
      expect(AppConstants.paddingS, 8.0);
      expect(AppConstants.paddingM, 16.0);
      expect(AppConstants.paddingL, 24.0);
      expect(AppConstants.paddingXL, 32.0);
      expect(AppConstants.borderRadius, 12.0);
      expect(AppConstants.currencySymbol, '฿');
    });
  });

  group('BillValidation Logic Tests', () {
    test('validateAmount succeeds for positive amounts and throws for negative', () {
      expect(() => BillValidation.validateAmount(100.0), returnsNormally);
      expect(() => BillValidation.validateAmount(0.0), returnsNormally);
      expect(() => BillValidation.validateAmount(-1.0), throwsA(isA<ArgumentError>()));
      expect(() => BillValidation.validateAmount(double.infinity), throwsA(isA<ArgumentError>()));
    });

    test('validateQuantity succeeds for positive numbers and throws for <= 0', () {
      expect(() => BillValidation.validateQuantity(1), returnsNormally);
      expect(() => BillValidation.validateQuantity(5), returnsNormally);
      expect(() => BillValidation.validateQuantity(0), throwsA(isA<ArgumentError>()));
      expect(() => BillValidation.validateQuantity(-2), throwsA(isA<ArgumentError>()));
    });

    test('isClaimQuantityValid checks claimed quantity limits', () {
      final validItem = BillItemModel(
        id: '1',
        billId: 'b1',
        itemName: 'ข้าวผัด',
        price: 50,
        quantity: 3,
        userQuantities: {'u1': 1, 'u2': 2},
      );
      expect(BillValidation.isClaimQuantityValid(validItem), isTrue);

      final overClaimedItem = BillItemModel(
        id: '2',
        billId: 'b1',
        itemName: 'ข้าวผัด',
        price: 50,
        quantity: 2,
        userQuantities: {'u1': 2, 'u2': 2},
      );
      expect(BillValidation.isClaimQuantityValid(overClaimedItem), isFalse);

      final negativeItem = BillItemModel(
        id: '3',
        billId: 'b1',
        itemName: 'ข้าวผัด',
        price: 50,
        quantity: 2,
        userQuantities: {'u1': -1},
      );
      expect(BillValidation.isClaimQuantityValid(negativeItem), isFalse);
    });

    test('canEditBill and canChangeHost require active user to match owner', () {
      expect(BillValidation.canEditBill(currentUserId: 'owner1', ownerId: 'owner1'), isTrue);
      expect(BillValidation.canEditBill(currentUserId: 'other', ownerId: 'owner1'), isFalse);
      expect(BillValidation.canEditBill(currentUserId: '', ownerId: 'owner1'), isFalse);

      expect(BillValidation.canChangeHost(currentUserId: 'owner1', ownerId: 'owner1'), isTrue);
      expect(BillValidation.canChangeHost(currentUserId: 'guest', ownerId: 'owner1'), isFalse);
    });
  });

  group('BillParticipantModel Tests', () {
    test('parses json correctly and handles defaults', () {
      final json = {
        'id': 'part-1',
        'bill_id': 'bill-1',
        'profile_id': 'user-1',
        'amount_owed': 150.75,
        'status': 'paid',
      };
      final participant = BillParticipantModel.fromJson(json);
      expect(participant.id, 'part-1');
      expect(participant.billId, 'bill-1');
      expect(participant.profileId, 'user-1');
      expect(participant.amountOwed, 150.75);
      expect(participant.status, 'paid');
    });

    test('defaults amountOwed and status when missing', () {
      final participant = BillParticipantModel.fromJson({
        'id': 'part-2',
        'bill_id': 'bill-2',
      });
      expect(participant.amountOwed, 0.0);
      expect(participant.status, 'pending');
    });
  });
}
