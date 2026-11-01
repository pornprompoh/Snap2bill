import 'package:flutter/material.dart';

/// Helper to analyze food/drink item names from OCR/AI receipts and map
/// them automatically to consistent Material Symbols / Material Icons (Material Design 3).
class MenuIconHelper {
  /// Analyzes [itemName] and returns the most accurate Material rounded icon.
  /// If the category cannot be determined, falls back to [Icons.restaurant_rounded].
  static IconData getDishIcon(String itemName) {
    final lower = itemName.trim().toLowerCase();
    if (lower.isEmpty) return Icons.restaurant_rounded;

    // 1. Sushi / Sashimi / Japanese Raw Fish / Rolls
    if (_containsAny(lower, [
      'sushi', 'ซูชิ', 'sashimi', 'ซาชิมิ', 'nigiri', 'นิกิริ',
      'maki', 'มากิ', 'roll', 'โรล', 'ข้าวปั้น', 'ปลาดิบ',
      'wasabi', 'วาซาบิ', 'california', 'ebi', 'maguro', 'salmon sushi',
      'แซลมอนซูชิ', 'ซูชิแซลมอน', 'ทูน่าซูชิ', 'bento', 'เบนโตะ'
    ])) {
      return Icons.set_meal_rounded;
    }

    // 2. Ramen / Noodles / Pasta / Spaghetti
    if (_containsAny(lower, [
      'ramen', 'ราเมน', 'ราเม็ง', 'noodle', 'noodles', 'บะหมี่',
      'ก๋วยเตี๋ยว', 'เส้น', 'อูด้ง', 'udon', 'soba', 'โซบะ',
      'pasta', 'พาสต้า', 'spaghetti', 'สปาเก็ตตี้', 'สปาเกตตี',
      'ผัดไทย', 'pad thai', 'เย็นตาโฟ', 'เฝอ', 'pho', 'ราดหน้า',
      'ผัดซีอิ๊ว', 'หมี่', 'วุ้นเส้น', 'ขนมจีน'
    ])) {
      return Icons.ramen_dining_rounded;
    }

    // 3. Pizza
    if (_containsAny(lower, ['pizza', 'พิซซ่า', 'พิซซา'])) {
      return Icons.local_pizza_rounded;
    }

    // 4. Burgers & Sandwiches
    if (_containsAny(lower, [
      'burger', 'เบอร์เกอร์', 'เบอเกอร์', 'hamburger', 'แฮมเบอร์เกอร์',
      'sandwich', 'แซนด์วิช', 'แซนวิช', 'hotdog', 'ฮอทดอก', 'whopper',
      'sub', 'bagel', 'เบเกิล'
    ])) {
      return Icons.lunch_dining_rounded;
    }

    // 5. Smoothies, Shakes, Blended Drinks & Juices (น้ำปั่น, เครื่องดื่มปั่น)
    if (_containsAny(lower, [
      'smoothie', 'สมูทตี้', 'shake', 'เชค', 'frappe', 'เฟรปเป้', 'แฟรปเป้',
      'ปั่น', 'น้ำปั่น', 'slushy', 'สลัชชี่', 'juice', 'น้ำผลไม้', 'น้ำส้ม',
      'น้ำมะนาว', 'น้ำมะพร้าว', 'lemonade', 'soda', 'โซดา', 'coke', 'โค้ก',
      'pepsi', 'เป๊ปซี่', 'น้ำอัดลม', 'water', 'น้ำดื่ม', 'น้ำเปล่า',
      'ชานมไข่มุก', 'boba'
    ])) {
      return Icons.local_drink_rounded;
    }

    // 6. Coffee, Tea & Cafe Beverages (กาแฟ, ชา, คาเฟ่)
    if (_containsAny(lower, [
      'coffee', 'กาแฟ', 'espresso', 'เอสเพรสโซ', 'americano', 'อเมริกาโน',
      'latte', 'ลาเต้', 'cappuccino', 'คาปูชิโน', 'mocha', 'มอคค่า',
      'cold brew', 'โคลด์บรูว์', 'macchiato', 'มัคคิอาโต', 'โอเลี้ยง',
      'กาแฟโบราณ', 'ชา', 'ชาเขียว', 'ชาไทย', 'tea', 'matcha', 'มัทฉะ',
      'greentea', 'green tea', 'earl grey', 'ชาจีน', 'เก๊กฮวย', 'ชาอู่หลง', 'oolong'
    ])) {
      return Icons.local_cafe_rounded;
    }

    // 7. Beer
    if (_containsAny(lower, [
      'beer', 'เบียร์', 'craft beer', 'คราฟต์เบียร์', 'lager', 'ale',
      'ipa', 'draft', 'draught', 'stout', 'singha', 'chang', 'heineken', 'asahi'
    ])) {
      return Icons.sports_bar_rounded;
    }

    // 8. Wine, Cocktails & Liquor
    if (_containsAny(lower, [
      'wine', 'ไวน์', 'cocktail', 'ค็อกเทล', 'whiskey', 'whisky', 'วิสกี้',
      'vodka', 'วอดก้า', 'gin', 'จิน', 'rum', 'เหล้า', 'champagne',
      'แชมเปญ', 'soju', 'โซจู', 'sake', 'สาเก', 'tequila', 'แอลกอฮอล์'
    ])) {
      return Icons.wine_bar_rounded;
    }

    // 9. Cake & Pastries
    if (_containsAny(lower, [
      'cake', 'เค้ก', 'cheesecake', 'ชีสเค้ก', 'cupcake', 'คัพเค้ก',
      'brownie', 'บราวนี่', 'crepe', 'เครป', 'pancake', 'แพนเค้ก',
      'waffle', 'วาฟเฟิล', 'tart', 'ทาร์ต', 'tiramisu', 'ทิรามิสุ',
      'mousse', 'มูส', 'chiffon', 'ชิฟฟอน'
    ])) {
      return Icons.cake_rounded;
    }

    // 10. Ice Cream & Frozen Sweets
    if (_containsAny(lower, [
      'ice cream', 'icecream', 'ไอศกรีม', 'ไอติม', 'gelato', 'เจลาโต้',
      'bingsu', 'บิงซู', 'sundae', 'ซันเด', 'sorbet', 'ซอร์เบต์',
      'parfait', 'พาร์เฟต์', 'น้ำแข็งไส'
    ])) {
      return Icons.icecream_rounded;
    }

    // 11. Bakery, Bread & Toast
    if (_containsAny(lower, [
      'croissant', 'ครัวซองต์', 'bread', 'ขนมปัง', 'toast', 'โทสต์',
      'bakery', 'เบเกอรี่', 'baguette', 'บาแกตต์', 'bun', 'บัน',
      'donut', 'doughnut', 'โดนัท', 'roti', 'โรตี', 'pie', 'พาย',
      'ครอฟเฟิล', 'croffle'
    ])) {
      return Icons.bakery_dining_rounded;
    }

    // 12. Cookies & Snacks
    if (_containsAny(lower, [
      'cookie', 'คุกกี้', 'biscuit', 'บิสกิต', 'cracker', 'แครกเกอร์',
      'snack', 'ขนม', 'chips', 'มันฝรั่งทอด', 'popcorn', 'ป๊อปคอร์น'
    ])) {
      return Icons.cookie_rounded;
    }

    // 13. Rice Dishes (ข้าว)
    if (_containsAny(lower, [
      'rice', 'ข้าว', 'fried rice', 'ข้าวผัด', 'ข้าวมันไก่', 'ข้าวหมูกรอบ',
      'ข้าวหมูแดง', 'ข้าวหน้า', 'donburi', 'ดงบุริ', 'ข้าวต้ม',
      'porridge', 'โจ๊ก', 'congee', 'ข้าวราด'
    ])) {
      return Icons.rice_bowl_rounded;
    }

    // 14. Soup, Hot Pot, Shabu & Suki
    if (_containsAny(lower, [
      'soup', 'ซุป', 'shabu', 'ชาบู', 'suki', 'สุกี้', 'hotpot', 'หม้อไฟ',
      'ต้มยำ', 'tomyum', 'tom yum', 'แกง', 'curry', 'ต้มข่า', 'ต้มแซ่บ',
      'จิ้มจุ่ม', 'หมูกระทะ', 'น้ำซุป', 'เกาเหลา'
    ])) {
      return Icons.soup_kitchen_rounded;
    }

    // 15. Steak, BBQ, Grilled & Skewers
    if (_containsAny(lower, [
      'steak', 'สเต็ก', 'สเต๊ก', 'bbq', 'บาร์บีคิว', 'grill', 'ย่าง',
      'ปิ้งย่าง', 'skewer', 'เสียบไม้', 'หมูปิ้ง', 'ไก่ย่าง', 'เนื้อย่าง',
      'satay', 'สะเต๊ะ', 'yakiniku', 'ยากินิกุ', 'kebab', 'เคบับ', 'สเต็กเนื้อ'
    ])) {
      return Icons.kebab_dining_rounded;
    }

    // 16. Fried Foods / Fast Food
    if (_containsAny(lower, [
      'french fries', 'เฟรนช์ฟรายส์', 'เฟรนช์ฟราย', 'nugget', 'นักเก็ต',
      'ไก่ทอด', 'fried chicken', 'karaage', 'คาราอาเกะ', 'tempura',
      'เทมปุระ', 'tonkatsu', 'ทงคัตสึ', 'ของทอด', 'ทอด'
    ])) {
      return Icons.fastfood_rounded;
    }

    // 17. Seafood & Fish
    if (_containsAny(lower, [
      'salmon', 'แซลมอน', 'tuna', 'ทูน่า', 'fish', 'ปลา', 'shrimp', 'prawn',
      'กุ้ง', 'crab', 'ปู', 'squid', 'octopus', 'หมึก', 'seafood', 'ซีฟู้ด',
      'scallop', 'หอย', 'หอยนางรม', 'oyster'
    ])) {
      return Icons.set_meal_rounded;
    }

    // 18. Salad & Greens
    if (_containsAny(lower, [
      'salad', 'สลัด', 'veggie', 'vegetable', 'ผัก', 'ยำ', 'somtam',
      'ส้มตำ', 'ตำไทย', 'ตำปู', 'ลาบ', 'น้ำตก', 'vegan', 'วีแกน', 'มังสวิรัติ'
    ])) {
      return Icons.eco_rounded;
    }

    // 19. Eggs & Breakfast
    if (_containsAny(lower, [
      'egg', 'eggs', 'ไข่', 'omelet', 'omelette', 'ไข่เจียว', 'ไข่ดาว',
      'ไข่กระทะ', 'ไข่ต้ม', 'ไข่ตุ๋น', 'benedict'
    ])) {
      return Icons.egg_alt_rounded;
    }

    // Fallback: General Food icon (ช้อนส้อม / อาหารทั่วไป)
    return Icons.restaurant_rounded;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}
