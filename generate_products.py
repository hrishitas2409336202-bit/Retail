import json
import random

categories = [
    'Vegetables & Fruits',
    'Atta, Rice & Dal',
    'Oil, Ghee & Masala',
    'Dairy, Bread & Eggs',
    'Snacks & Packaged Foods',
    'Beverages',
    'Cleaning & Household',
    'Personal Care'
]

products_data = {
    'Vegetables & Fruits': [
        ('Fresh Apples', 180, '1 kg', '🍎', 'Fresh and crisp red apples.', 'https://images.unsplash.com/photo-1560806887-1e4cd0b6caa6?auto=format&fit=crop&q=80&w=200'),
        ('Organic Bananas', 60, '1 dozen', '🍌', 'Naturally ripened sweet bananas.', 'https://images.unsplash.com/photo-1571501470233-a332a6cb82e4?auto=format&fit=crop&q=80&w=200'),
        ('Hass Avocado', 240, '2 pcs', '🥑', 'Creamy and ready-to-eat avocados.', 'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&q=80&w=200'),
        ('Hybrid Tomatoes', 40, '1 kg', '🍅', 'Firm and juicy red tomatoes.', 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=200'),
        ('Fresh Spinach Bunch', 30, '1 bunch', '🥬', 'Green and leafy farm spinach.', 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&q=80&w=200'),
        ('Red Bell Pepper', 120, '1 kg', '🫑', 'Sweet and crunchy bell peppers.', 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&q=80&w=200'),
        ('Green Grapes Seedless', 150, '500 g', '🍇', 'Sweet seedless green grapes.', 'https://images.unsplash.com/photo-1596363505729-41941ba9e1cd?auto=format&fit=crop&q=80&w=200'),
        ('Pomegranates', 200, '1 kg', '🍎', 'Juicy and rich pomegranates.', 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&q=80&w=200'),
        ('Organic Carrots', 70, '1 kg', '🥕', 'Crunchy orange carrots.', 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&q=80&w=200'),
        ('Sweet Corn', 45, '2 pcs', '🌽', 'Fresh yellow sweet corn.', 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&q=80&w=200'),
        ('Potatoes', 35, '1 kg', '🥔', 'Multi-purpose cooking potatoes.', 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=200'),
        ('Green Beans', 80, '1 kg', '🥒', 'Fresh crunchy green string beans.', 'https://images.unsplash.com/photo-1562923696-2775aab518fb?auto=format&fit=crop&q=80&w=200'),
        ('Onions', 40, '1 kg', '🧅', 'Essential red cooking onions.', 'https://images.unsplash.com/photo-1620574387735-3624d75b2dbc?auto=format&fit=crop&q=80&w=200')
    ],
    'Atta, Rice & Dal': [
        ('Aashirvaad Atta', 485, '10 kg', '🌾', 'Premium whole wheat chakki atta.', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200'),
        ('Kohinoor Basmati Rice', 520, '5 kg', '🍚', 'Long-grain royal basmati rice.', 'https://images.unsplash.com/photo-1536304929831-2fb0c69d0340?auto=format&fit=crop&q=80&w=200'),
        ('Toor Dal unpolished', 165, '1 kg', '🥣', 'Protein-rich premium toor dal.', 'https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200'),
        ('Moong Dal', 140, '1 kg', '🥣', 'Organic cleaned yellow moong dal.', 'https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200'),
        ('Sona Masuri Rice', 650, '10 kg', '🍚', 'Everyday usage premium sona masuri.', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200'),
        ('Chana Dal', 110, '1 kg', '🥣', 'High quality protein chana dal.', 'https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200'),
        ('Kabuli Chana', 180, '1 kg', '🥣', 'Large white chickpeas.', 'https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200'),
        ('Fortune Besan', 95, '1 kg', '🌾', 'Finely grounded gram flour.', 'https://images.unsplash.com/photo-1627485937980-221c88ce04ea?auto=format&fit=crop&q=80&w=200'),
        ('Madhur Sugar', 45, '1 kg', '🍬', 'Pure and hygienic fine sugar.', 'https://images.unsplash.com/photo-1622485493026-6a2c2df9e578?auto=format&fit=crop&q=80&w=200'),
        ('Tata Salt', 28, '1 kg', '🧂', 'Iodized quality table salt.', 'https://images.unsplash.com/photo-1518110925485-5ce82d8c3656?auto=format&fit=crop&q=80&w=200'),
        ('Urad Dal White', 150, '1 kg', '🥣', 'Split and skinned white urad.', 'https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200'),
        ('Rajma Chitra', 160, '1 kg', '🥣', 'Speckled kidney beans for thick gravy.', 'https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200'),
        ('Idli Rice', 85, '1 kg', '🍚', 'Round grained rice specially for Idli batter.', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200')
    ],
    'Oil, Ghee & Masala': [
        ('Fortune Sunflower Oil', 165, '1 Litre', '🌻', 'Light and healthy sunflower oil for daily cooking.', 'https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200'),
        ('Amul Pure Ghee', 310, '500 ml', '🧈', 'Rich, premium pure cow ghee.', 'https://plus.unsplash.com/premium_photo-1694707172082-9366115fb6de?auto=format&fit=crop&q=80&w=200'),
        ('Everest Turmeric Powder', 35, '100 g', '🌶️', 'High quality yellow turmeric powder.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Catch Red Chili Powder', 45, '100 g', '🌶️', 'Spicy red chilli powder.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Saffola Gold Oil', 195, '1 Litre', '🌻', 'Pro-health blended edible oil.', 'https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200'),
        ('Everest Garam Masala', 65, '50 g', '🌶️', 'Authentic blend of Indian spices.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Patanjali Mustard Oil', 180, '1 Litre', '🌻', 'Kachi Ghani pure mustard oil.', 'https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200'),
        ('Cumin Seeds (Jeera)', 85, '100 g', '🌿', 'Aromatic unroasted cumin seeds.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Black Pepper Whole', 120, '50 g', '🌿', 'Strong premium black peppercorns.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Coriander Powder', 40, '100 g', '🌿', 'Freshly ground coriander powder.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Gowardhan Ghee', 580, '1 Litre', '🧈', 'Rich aroma Desi ghee.', 'https://plus.unsplash.com/premium_photo-1694707172082-9366115fb6de?auto=format&fit=crop&q=80&w=200'),
        ('MDH Chana Masala', 75, '100 g', '🌶️', 'Special spice mix for Chana.', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200'),
        ('Virgin Olive Oil', 850, '500 ml', '🫒', 'Cold-pressed extra virgin olive oil.', 'https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200')
    ],
    'Dairy, Bread & Eggs': [
        ('Amul Taaza Milk', 58, '1 Litre', '🥛', 'Fresh toned milk tetra pack.', 'https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200'),
        ('Britannia Brown Bread', 45, '1 packet', '🍞', 'Whole wheat healthy brown bread.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200'),
        ('Farm Fresh Eggs', 84, '1 Dozen', '🥚', 'High protein fresh white eggs.', 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&q=80&w=200'),
        ('Amul Butter', 56, '100 g', '🧈', 'Delicious pasteurized butter.', 'https://images.unsplash.com/photo-1588195538326-c5b1e9f6f5b4?auto=format&fit=crop&q=80&w=200'),
        ('Mother Dairy Paneer', 90, '200 g', '🧀', 'Fresh and soft malai paneer.', 'https://images.unsplash.com/photo-1631387227447-fd9b85c1dbcf?auto=format&fit=crop&q=80&w=200'),
        ('Nestle Dahi', 40, '400 g', '🥛', 'Thick and tasty set curd.', 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=200'),
        ('Garlic Bread Loaf', 65, '250 g', '🍞', 'Freshly baked garlic bread loaf.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200'),
        ('Nutrela Soya Milk', 140, '1 Litre', '🥛', 'Plain organic vegan soya milk.', 'https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200'),
        ('Epigamia Greek Yogurt', 55, '100 g', '🥛', 'High protein natural greek yogurt.', 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=200'),
        ('Amul Cheese Slices', 160, '10 slices', '🧀', 'Processed cheese slices.', 'https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200'),
        ('White Sandwich Bread', 40, '1 packet', '🍞', 'Soft and fluffy white bread slice.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200'),
        ('Pizza Base', 35, '2 pcs', '🍕', 'Ready to bake pizza bases.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200')
    ],
    'Snacks & Packaged Foods': [
        ('Parle-G Biscuits', 65, '800 g', '🍪', 'Original glucose biscuits.', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200'),
        ('Oreo Chocolate Cookies', 35, '120 g', '🍪', 'Classic sandwich cookies.', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200'),
        ('Maggi 2-Minute Noodles', 144, '12 pack', '🍜', 'The famous instant masala noodles.', 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&q=80&w=200'),
        ('Lays Magic Masala', 20, '50 g', '🍟', 'Crispy spicy potato chips.', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=200'),
        ('Haldiram Aloo Bhujia', 105, '400 g', '🥨', 'Spicy potato and besan noodles.', 'https://images.unsplash.com/photo-1621303837174-89787a7d4729?auto=format&fit=crop&q=80&w=200'),
        ('Pringles Sour Cream', 110, '110 g', '🍟', 'Sour cream and onion stacked chips.', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=200'),
        ('Knorr Tomato Soup', 55, '4 serves', '🥣', 'Instant thick tomato soup powder.', 'https://images.unsplash.com/photo-1574484284002-952d92456975?auto=format&fit=crop&q=80&w=200'),
        ('Nutella Hazelnut Spread', 350, '350 g', '🍫', 'Delicious cocoa hazelnut spread.', 'https://images.unsplash.com/photo-1582293041079-7814c2f12063?auto=format&fit=crop&q=80&w=200'),
        ('Kissan Mixed Fruit Jam', 120, '500 g', '🍓', 'Sweet fruit jam for breakfast.', 'https://images.unsplash.com/photo-1582293041079-7814c2f12063?auto=format&fit=crop&q=80&w=200'),
        ('Kellogg\'s Corn Flakes', 190, '500 g', '🥣', 'Crunchy original corn flakes.', 'https://images.unsplash.com/photo-1521483756775-addabfc80dec?auto=format&fit=crop&q=80&w=200'),
        ('Quaker Oats', 160, '1 kg', '🥣', 'Healthy whole grain oats.', 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&q=80&w=200'),
        ('Dairy Milk Silk', 175, '150 g', '🍫', 'Premium smooth milk chocolate.', 'https://images.unsplash.com/photo-1614088685112-0a860dbbfbe9?auto=format&fit=crop&q=80&w=200'),
        ('Ferrero Rocher', 890, '16 pcs', '💎', 'Crisp hazelnut and milk chocolate.', 'https://images.unsplash.com/photo-1548844877-38e4a9042b31?auto=format&fit=crop&q=80&w=200'),
        ('Sunfeast Dark Fantasy', 90, '75 g', '🍪', 'Choco-filled delicious cookies.', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200')
    ],
    'Beverages': [
        ('Coca-Cola', 95, '2 Litres', '🥤', 'Refreshing carbonated soft drink.', 'https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200'),
        ('Pepsi', 45, '750 ml', '🥤', 'Crisp and cool cola drink.', 'https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200'),
        ('Tropicana Orange Juice', 125, '1 Litre', '🍊', '100% mixed fruit orange juice.', 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200'),
        ('Maaza Mango Drink', 75, '1.2 Litres', '🥭', 'Delicious Alphonso mango juice.', 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200'),
        ('Red Bull Energy Drink', 115, '250 ml', '⚡', 'Instant physical energy drink.', 'https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200'),
        ('Kinley Mineral Water', 20, '1 Litre', '💧', 'Pure packaged drinking water.', 'https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200'),
        ('Nescafe Classic Coffee', 320, '100 g', '☕', 'Rich instant coffee powder.', 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?auto=format&fit=crop&q=80&w=200'),
        ('Taj Mahal Tea', 345, '500 g', '🍵', 'Rich flavorful loose leaf tea.', 'https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200'),
        ('Bournvita Chocolate Health', 225, '500 g', '🥛', 'Chocolate health drink powder.', 'https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200'),
        ('Lipton Green Tea', 165, '25 bags', '🍵', 'Zero calorie healthy green tea leaves.', 'https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200'),
        ('Sprite', 95, '2 Litres', '🥤', 'Clear lime flavored soda.', 'https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200'),
        ('Paper Boat Coconut Water', 50, '200 ml', '🥥', '100% natural tender coconut water.', 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200')
    ],
    'Cleaning & Household': [
        ('Surf Excel Matic Liquid', 210, '1 Litre', '🧼', 'Top load automatic laundry liquid.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Ariel Washing Powder', 320, '2 kg', '🧴', 'Complete stain removal powder.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Vim Dishwash Gel', 115, '500 ml', '🍋', 'Lemon fragrant dishwash liquid.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Lizol Floor Cleaner', 105, '1 Litre', '🧹', 'Citrus scented disinfectant base.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Harpic Toilet Cleaner', 95, '1 Litre', '🚽', 'Powerful bathroom and toilet cleaner.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Comfort Fabric Conditioner', 240, '860 ml', '🧺', 'After wash fabric softener.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Colin Glass Cleaner', 90, '500 ml', '🪟', 'Shine booster glass spray.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Scotch-Brite Scrub Pad', 60, '3 pcs', '🧽', 'Heavy duty kitchen scrub pad.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Hit Mosquito Killer', 190, '400 ml', '🦟', 'Effective flying insect spray.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Dettol Disinfectant Liquid', 340, '1 Litre', '🏥', 'Antiseptic germ killing liquid.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200'),
        ('Tissue Paper Rolls', 180, '4 Rolls', '🧻', 'Soft 2-ply toilet paper rolls.', 'https://images.unsplash.com/photo-1584432810601-6c7f27d2362b?auto=format&fit=crop&q=80&w=200'),
        ('Garbage Bags Large', 75, '30 pcs', '🗑️', 'Sturdy stretchable garbage bags.', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200')
    ],
    'Personal Care': [
        ('Dove Cream Beauty Bathing Bar', 180, '3 x 100g', '🧼', 'Moisturizing beauty cream soap.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Pears Pure & Gentle Soap', 150, '3 x 125g', '🧼', 'Glycerin rich transparent soap.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Head & Shoulders Shampoo', 315, '650 ml', '🧴', 'Anti-dandruff cool menthol shampoo.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Sunsilk Black Shine', 280, '650 ml', '🧴', 'Nourishing herbal hair shampoo.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Colgate MaxFresh Paste', 190, '300 g', '🦷', 'Cooling crystals red gel paste.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Sensodyne Repair & Protect', 210, '100 g', '🦷', 'Tooth sensitivity relief paste.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Nivea Body Lotion', 350, '400 ml', '🧴', 'Nourishing skin body moisturizer.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Gillette Mach 3 Razor', 240, '1 pc', '🪒', 'Close and comfortable shaving razor.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Old Spice After Shave', 290, '100 ml', '💈', 'Classic musk after shave lotion.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Listerine Mouthwash', 145, '250 ml', '👄', 'Cool mint mouth freshness wash.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Himalaya Neem Face Wash', 180, '150 ml', '🌿', 'Herbal purifying daily face wash.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Whisper Ultra Clean', 360, '15 pads', '🦋', 'Wings XL sanitary protection.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200'),
        ('Parachute Coconut Oil', 120, '250 ml', '🥥', '100% pure edible coconut oil.', 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200')
    ]
}

lines = []
id_counter = 1
for cat, items in products_data.items():
    shelf = f"S{categories.index(cat)+1}"
    for item in items:
        name, price, unit, emoji, desc, image = item
        pid = f"PRD{id_counter:03d}"
        stock = random.randint(5, 100)
        lines.append(f"      {{'id': '{pid}', 'name': '{name}', 'category': '{cat}', 'price': {price}.0, 'stock': {stock}, 'threshold': 20, 'emoji': '{emoji}', 'shelf': '{shelf}', 'unit': '{unit}', 'description': '{desc}', 'imageUrl': '{image}', 'supplierId': 'SUP001'}},")
        id_counter += 1

print("\n".join(lines))
