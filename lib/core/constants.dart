class AppConstants {
  static const String appName = 'TextileDrop';
  static const String appTagline = 'Surat Textile Daily Drop & Catalog SaaS';

  static const List<String> textileCategories = [
    'Saree',
    'Kurti & Suit',
    'Dress Material',
    'Lehenga Choli',
    'Running Fabric',
    'Dupatta & Stole',
    'Gown & Western',
    'Mens Ethnic',
    'Blouse Piece & Lace',
  ];

  static const List<String> fabrics = [
    'Dola Silk',
    'Georgette',
    'Organza',
    'Banarasi Jacquard',
    'Pure Silk',
    'Chanderi',
    'Rayon 14kg',
    'Cotton',
    'Velvet',
    'Chiffon',
    'Crepe',
    'Satin Silk',
    'Linen',
    'Net & Sequence',
  ];

  static const List<String> colors = [
    'Red',
    'Pink / Rani',
    'Maroon',
    'Wine / Purple',
    'Royal Blue',
    'Teal / Rama Green',
    'Emerald Green',
    'Pista Green',
    'Mustard Yellow',
    'Haldi Yellow',
    'Peach',
    'Black',
    'White / Off-White',
    'Multi Color',
  ];

  static const List<String> occasions = [
    'Festive',
    'Party Wear',
    'Wedding / Bridal',
    'Daily Wear',
    'Casual',
    'Office / Formal',
    'Mehendi & Sangeet',
    'Reception Special',
  ];

  static const List<String> festivals = [
    'Diwali Special',
    'Navratri & Garba',
    'Wedding Season',
    'Eid Collection',
    'Raksha Bandhan',
    'Karwa Chauth',
    'Teej Special',
    'Durga Puja',
    'Regular / All Season',
  ];

  static const List<String> sizes = [
    'Free Size',
    'Unstitched',
    'Semi-Stitched',
    'S (36)',
    'M (38)',
    'L (40)',
    'XL (42)',
    'XXL (44)',
    '3XL (46)',
    'Set of All Sizes (S to XXL)',
  ];

  static const List<String> setOptions = [
    'Single Piece',
    'Set of 4 (4 Colors)',
    'Set of 6 (6 Colors)',
    'Set of 8 (8 Colors)',
    'Set of 10',
    'Set of 12 (Full Catalog Set)',
    'Custom MOQ (Loose)',
  ];

  static const List<String> suratMarkets = [
    'Radha Krishna Textile Market (RKTM)',
    'Millennium Textile Market (MTM)',
    'Surat Textile Market (STM)',
    'Avadh Textile Market',
    'Kohinoor Textile Market',
    'Universal Textile Market',
    'Shree Kuberji Textile Market',
    'JJ Textile Market',
    'Ring Road Textile Hub',
    'Pandesara GIDC',
    'Sachin GIDC',
  ];

  static const List<String> stockStatuses = [
    'available',
    'limited',
    'sold_out',
    'discontinued',
  ];

  static const List<String> inquiryStatuses = [
    'new',
    'contacted',
    'catalog_sent',
    'quoted',
    'follow_up',
    'ordered',
    'lost',
    'closed',
  ];

  static const List<String> contactTypes = [
    'buyer',
    'dealer',
    'reseller',
    'retailer',
    'boutique',
    'other',
  ];

  static const List<String> languages = [
    'hi', // Hindi
    'gu', // Gujarati
    'en', // English
  ];

  static const String defaultWhatsappTemplate =
      'Hello, I am interested in Design {product_code} from {collection_name}. Please share price, video and available stock.';
}
