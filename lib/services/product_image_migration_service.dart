import 'package:cloud_firestore/cloud_firestore.dart';

class ProductImageMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, String> productImagePaths = {
    '4807773300018': 'assets/images/products/eu_cola_1_5l.png',
    '4807773300025': 'assets/images/products/citrus_soda_1_5l.png',
    '4807773300032': 'assets/images/products/orange_fizz_1_5l.png',
    '4807773300049': 'assets/images/products/lemon_lime_soda_1_5l.png',
    '4807773300056': 'assets/images/products/iced_tea_500ml.png',
    '4807773300063': 'assets/images/products/mango_juice_1l.png',
    '4807773300070': 'assets/images/products/apple_juice_1l.png',
    '4807773300087': 'assets/images/products/bottled_water_1l.png',
    '4807773300094': 'assets/images/products/blue_chips_cheese_60g.png',
    '4807773300100': 'assets/images/products/crunch_rings_bbq_60g.png',

    '4807773300117': 'assets/images/products/corn_puffs_cheese_55g.png',
    '4807773300124': 'assets/images/products/potato_crisps_sour_cream_60g.png',
    '4807773300131': 'assets/images/products/nacho_chips_75g.png',
    '4807773300148': 'assets/images/products/peanut_mix_100g.png',
    '4807773300155': 'assets/images/products/quick_noodles_chicken_60g.png',
    '4807773300162': 'assets/images/products/quick_noodles_beef_60g.png',
    '4807773300179': 'assets/images/products/quick_noodles_spicy_60g.png',
    '4807773300186': 'assets/images/products/cup_noodles_seafood_70g.png',
    '4807773300193': 'assets/images/products/cup_noodles_beef_70g.png',
    '4807773300209': 'assets/images/products/pancit_style_noodles_60g.png',

    '4807773300216': 'assets/images/products/cream_crackers_250g.png',
    '4807773300223':
        'assets/images/products/chocolate_sandwich_biscuits_100g.png',
    '4807773300230': 'assets/images/products/vanilla_wafers_120g.png',
    '4807773300247': 'assets/images/products/butter_cookies_150g.png',
    '4807773300254': 'assets/images/products/graham_crackers_200g.png',
    '4807773300261': 'assets/images/products/cheese_crackers_100g.png',
    '4807773300278': 'assets/images/products/fresh_milk_1l.png',
    '4807773300285': 'assets/images/products/chocolate_milk_1l.png',
    '4807773300292': 'assets/images/products/evaporated_milk_370ml.png',
    '4807773300308': 'assets/images/products/condensed_milk_300ml.png',

    '4807773300315': 'assets/images/products/yogurt_drink_200ml.png',
    '4807773300322': 'assets/images/products/corned_beef_150g.png',
    '4807773300339': 'assets/images/products/tuna_flakes_180g.png',
    '4807773300346': 'assets/images/products/sardines_tomato_sauce_155g.png',
    '4807773300353': 'assets/images/products/meat_loaf_150g.png',
    '4807773300360': 'assets/images/products/baked_beans_220g.png',
    '4807773300377': 'assets/images/products/classic_coffee_sachet_20g.png',
    '4807773300384': 'assets/images/products/3in1_coffee_original_25g.png',
    '4807773300391': 'assets/images/products/3in1_coffee_strong_25g.png',
    '4807773300407': 'assets/images/products/chocolate_malt_drink_24g.png',

    '4807773300414': 'assets/images/products/soy_sauce_350ml.png',
    '4807773300421': 'assets/images/products/vinegar_350ml.png',
    '4807773300438': 'assets/images/products/tomato_ketchup_320g.png',
    '4807773300445': 'assets/images/products/banana_ketchup_320g.png',
    '4807773300452': 'assets/images/products/cooking_oil_1l.png',
    '4807773300469': 'assets/images/products/clean_soap_135g.png',
    '4807773300476': 'assets/images/products/fresh_shampoo_180ml.png',
    '4807773300483': 'assets/images/products/smooth_conditioner_180ml.png',
    '4807773300490': 'assets/images/products/toothpaste_fresh_mint_150g.png',
    '4807773300506': 'assets/images/products/body_wash_250ml.png',
  };

  Future<int> updateAllProductImagePaths() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('products')
        .get();

    final WriteBatch batch = _firestore.batch();

    int updatedCount = 0;

    for (final document in snapshot.docs) {
      final data = document.data();

      final String barcode = data['barcode']?.toString().trim() ?? '';

      final String? imagePath = productImagePaths[barcode];

      if (imagePath == null) {
        continue;
      }

      batch.update(document.reference, {
        'imagePath': imagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      updatedCount++;
    }

    if (updatedCount > 0) {
      await batch.commit();
    }

    return updatedCount;
  }
}
