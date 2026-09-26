# رہنما برائے سرور و مواد (Content & Server Management Guide)
### مکتبہ شیخ عبدالسلام الرستمی رحمہ اللہ (Maktabat Sheikh Abdul Salam Al-Rustami)

یہ تفصیلی دستاویز بیان کرتی ہے کہ سرور پر کتابیں (PDFs) اور آڈیوز (Audios) کس طرح رکھی جائیں گی، نئی کتب و تقاریر کا اضافہ کیسے کیا جائے گا، اور موبائل ایپ انہیں کس طرح آن لائن اور مکمل آف لائن استعمال کرے گی۔

---

## ۱. بنیادی ساخت اور رابطے کی ترتیب (Architecture Overview)

ایپلی کیشن کا حجم ہلکا اور تیز رفتار رکھنے کے لیے:
1. **کتابوں کے سرورق (Covers)** ایپ کے اندر ہی محفوظ ہیں (`assets/images/books/`) تاکہ بغیر انٹرنیٹ کے فوراً ظاہر ہوں۔
2. **بھاری فائلیں (PDFs اور 1,500+ آڈیوز)** آپ کے سرور / VPS پر ہوسٹ کی جاتی ہیں۔
3. کتاب پر کلک کرنے سے PDF ڈاؤن لوڈ ہوتی ہے۔ آڈیو پر کلک کرنے سے آن لائن سلسلہ چلتا ہے؛ آف لائن استعمال کے لیے آڈیو کا ڈاؤن لوڈ بٹن دبانا ضروری ہے۔

### سرور کا لنک مقرر کرنا (Server Configuration):
فائل: [`lib/constants/app_config.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/constants/app_config.dart)
```dart
class AppConfig {
  // پی ڈی ایف کتب کا سرور ایڈریس
  static const String pdfBaseUrl = "https://your-server-domain.com/books/";

  // آڈیو لیکچرز کا سرور ایڈریس
  static const String audioBaseUrl = "https://your-server-domain.com/Audio/";
}
```

---

## ۲. کتب و مؤلفات (Books Management)

### فولڈر کی ساخت:
- **سرور پر پی ڈی ایف کتب:** `https://your-server.com/books/<fileName>`
- **ایپ میں سرورق (Images):** `assets/images/books/<imageName>`

### موجودہ کتب کی فہرست (21 PDF کتب؛ اس کے علاوہ ایک بیرونی اینڈرائیڈ ایپ):
| کتاب کا نام | تصویر کا نام (Assets) | سرور پر PDF فائل کا نام |
|---|---|---|
| الموسوعة القرآنية (جلد ۱) | `الموسوعة 1.png` | `الموسوعة 1.pdf` |
| الموسوعة القرآنية (جلد ۲) | `الموسوعة 2.png` | `الموسوعة 2.pdf` |
| الموسوعة القرآنية (جلد ۳) | `الموسوعة 3.png` | `الموسوعة 3.pdf` |
| انکارِ حدیث سے انکارِ قرآن تک | `انکارحدیث سے انکار قرآن تک.jpg` | `انکارحدیث سے انکار قرآن تک.pdf` |
| ترتيب الجهاد بمقابلة أهل الإلحاد | `ترتيب الجهاد.jpg` | `ترتيب الجهاد.pdf` |
| توجيه الناظرين إلى مقاصد الكتاب المبين | `توجيه الناظرين.jpg` | `توجيه الناظرين 2024.pdf` |
| جهود الشيخ في الدعوة الى الله | `جهود الشيخ في الدعوة الى الله.png` | `جهود الشيخ في الدعوة الى الله.pdf` |
| سهام الصياد | `سهام الصياد.png` | `سهام الصياد.pdf` |
| غيث السحابة على أمة الإجابة | `غيث السحابة على أمة الإجابة.jpg` | `غيث السحابة على أمة الإجابة.pdf` |
| مونږ په رڼا د احادیثو کښې | `مونز پہ رنڑا د احادیثو کی.jpg` | `مونږ به رنڑا د احاديثو كى.pdf` |
| أحسن الندي لرد المودودي | `أحسن الندي لرد المودودي.png` | `أحسن الندي لرد المودودي.pdf` |
| الدر المفتون في أحوال المسجون | `الدور المفتون في أحوال المسجون.png` | `الدور المفتون في أحوال المسجون.pdf` |
| المنهاج المستقيم | `المنہاج المستقیم.jpg` | `المنہاج المستقیم.pdf` |
| بدرة الصلات في رد الشبهات | `بدرۃ الصلات.jpeg` | `بدرۃ الصلات.pdf` |
| سيرة الأزم (پشتو) | `سيرة الآزم بشتو.png` | `سيرة الآزم بشتو.pdf` |
| سيرة الأزم (اردو) | `سيرة الأزم اردو.jpeg` | `سيرة الأزم اردو.pdf` |
| سیرت امام بخاری رحمہ اللہ | `سیرت امام بخاری.jpg` | `سیرت امام بخاری.pdf` |
| لطائف القرآن الكريم | `لطائف القرآن.jpg` | `لطائف القرآن.pdf` |
| لمونځ: ترجمہ او تشریح | `مونز ترجمة او تشريح.png` | `مونز ترجمة او تشريح.pdf` |
| منهج الشيخ الرستمي في التفسير | `منهج الشيخ الرستمي في التفسير.jpg` | `منهج الشيخ الرستمي في التفسير (محمد طارق).pdf` |
| پشتو ختم النبوت | `پشتو ختم النبوت.jpeg` | `پشتو ختم النبوت.pdf` |

### نئی کتاب شامل کرنے کا طریقہ (Adding a New Book):
1. نئی کتاب کا سرورق `assets/images/books/` میں رکھیں۔
2. کتاب کی پی ڈی ایف سرور کے `/books/` فولڈر میں اپلوڈ کریں۔
3. [`lib/screens/books_screen.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/screens/books_screen.dart) میں `_sampleBooks` لسٹ کے اندر ایک نیا اندراج شامل کریں:
```dart
{
  'title': 'نئی کتاب کا نام',
  'category': 'تفسیر قرآن', // یا توحید وعقیدہ، فقہ واحکام، خطبات ومقالات، سیرت وتاریخ
  'pages': '250',
  'fileName': 'new_book.pdf',
  'coverImage': 'assets/images/books/new_book.jpg',
  'description': 'کتاب کا مختصر تعارف',
  'language': 'پشتو',
},
```

---

## ۳. آڈیو لائبریری (Audio Library Management)

### موجودہ آڈیو مجموعات (1,589 آڈیو ریکارڈنگز):
1. **1987 تفسیر القرآن:** (136 آڈیوز - مکمل قرآن کریم کا پہلا تفسیری دورہ)
2. **شيخ عبد السلام تفسير 2003:** (330 آڈیوز سورت وار فولڈرز میں)
3. **مختصر دورہ تفسیرالقرآن سعیدآباد پشاور:** (359 آڈیوز 115 سورتوں کے فولڈرز میں)
4. **لفظي ترجمة شيخ القرآن:** (232 آڈیوز)
5. **مشكلات القرآن:** (148 آڈیوز)
6. **شیخ عبد السلام صاحب آڈیو بیانات:** (375 عمومی خطبات و تقاریر)
7. **urdu:** (9 اردو دروس)

---

### نئی آڈیوز شامل کرنے کا طریقہ (Adding New Audios Step-by-Step):

> **اہم ترین سہولت:** آپ کو نئی آڈیوز شامل کرنے کے لیے ایپلیکیشن دوبارہ بنانے (Rebuild) یا نیا ورژن جاری کرنے کی قطعاً ضرورت نہیں ہے!

#### مرحلہ ۱: اپنے کمپیوٹر یا سرور کے فولڈر میں نئی فائلیں رکھیں
نئے آڈیو فائلز کو ان کے متعلقہ مجموعے یا نئے فولڈر میں شامل کریں (مثلاً `D:\pc-data\Madrassa\Audio` میں)۔

#### مرحلہ ۲: خودکار کیٹلاگ جنریٹر چلائیں (One-Click Command)
پروجیکٹ کی ڈائریکٹری میں ٹرمینل کھول کر صرف یہ کمانڈ چلائیں:
```bash
python tools/generate_audio_catalog.py
```
*(اگر آڈیو کسی دوسری جگہ رکھی ہو تو پاتھ بھی دے سکتے ہیں: `python tools/generate_audio_catalog.py "D:\other_path\Audio"`)*

یہ اسکرپٹ سیکنڈوں میں:
- تمام نئے فولڈرز اور فائلز کو اسکین کرتا ہے۔
- ان کا دورانیہ (Duration) اور سائز (MB) معلوم کرتا ہے۔
- فائلز کو قدرتی ترتیب (Natural numerical sort: 1, 2, ... 114) دیتا ہے۔
- اپ ڈیٹ شدہ [`assets/data/audio_catalog.json`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/assets/data/audio_catalog.json) تیار کر دیتا ہے۔

#### مرحلہ ۳: سرور پر اپلوڈ کریں
1. نئی `.mp3` فائلیں اپنے سرور کے `/Audio/` فولڈر میں اس کے صحیح ذیلی فولڈر میں اپلوڈ کریں۔
2. نئی بننے والی فائل `audio_catalog.json` کو سرور کے `/Audio/` روٹ میں رکھ دیں:
   ```
   https://your-server.com/Audio/audio_catalog.json
   ```

---

### ایپ خودکار طریقے سے کیٹلاگ کیسے حاصل کرتی ہے؟ (Dynamic In-App Sync)

1. صارف جب بھی ایپ کا آڈیو صفحہ کھولے گا، ایپ سرور پر موجود `audio_catalog.json` چیک کرے گی۔
2. اگر سرور پر نئی فائلز کا اضافہ ہوا ہو تو ایپ فوراً نیا کیٹلاگ ڈاؤن لوڈ کر کے موبائل میں سیو کر لے گی۔
3. تمام نئے فولڈرز، سورتیں اور بیانات تمام صارفین کی اسکرین پر فوراً ظاہر ہو جائیں گے!
4. صفحہ کے اوپر AppBar میں دستی ریفریش بٹن (**فہرست تازہ کریں**) بھی موجود ہے۔

---

## ۴. اسٹریمنگ اور آف لائن کیشنگ (Streaming & Offline Caching)

```
                            [صارف آڈیو پلے کرتا ہے]
                                       │
                                       ▼
                   ┌──────────────────────────────────────┐
                   │ کیا یہ آڈیو پہلے سے ڈاؤن لوڈ ہے؟    │
                   └──────────────────┬───────────────────┘
                                      │
                   ہاں                │               نہیں
                    ▼                 │                ▼
       ┌────────────────────────┐     │   ┌───────────────────────────┐
       │ مکمل آف لائن چلے گی     │     │   │ سرور سے براہ راست سنیں    │
       │ (DeviceFileSource)     │     │   │ (UrlSource اسٹریمنگ)      │
       │ انٹرنیٹ کی ضرورت نہیں  │     │   └─────────────┬─────────────┘
       └────────────────────────┘     │                 │
                                      │         صارف ڈاؤن لوڈ پر کلک کرے
                                      │                 ▼
                                      │   ┌───────────────────────────┐
                                      │   │ پس منظر میں ڈاؤن لوڈنگ   │
                                      │   │ فیصد کی رفتار کے ساتھ     │
                                      │   └─────────────┬─────────────┘
                                      │                 │
                                      ▼                 ▼
             ┌────────────────────────────────────────────────────────┐
             │ AudioCacheManager موبائل کے اندر ہو بہو وہی فولڈرز      │
             │ بنا کر فائل محفوظ کر دیتا ہے:                          │
             │ <app_storage>/app_audio/<category>/<subfolder>/file.mp3│
             └────────────────────────────────────────────────────────┘
```

---

## ۵. سرور اور ویب ہوسٹنگ کے ضروری نکات (Server Checklist)

اپنے VPS یا ویب سرور (Nginx / Apache / Caddy / CloudFlare R2 / AWS S3) کی سیٹنگز میں یہ 3 چیزیں یقینی بنائیں:

1. **UTF-8 سپورٹ (Unicode Filenames):**
   چونکہ فائلز کے نام عربی اور پشتو میں ہیں (مثلاً `01 سورة الفا تحه.mp3`)، سرور پر UTF-8 فائل نیم اینکوڈنگ فعال ہونی چاہیے۔

2. **بائٹ رینج سپورٹ (Byte-Range Requests):**
   آڈیو کو آگے پیچھے (Seek/Fast-Forward) کرنے کے لیے ویب سرور کا ہیڈر فعال ہونا چاہیے:
   ```nginx
   # Nginx example:
   add_header Accept-Ranges bytes;
   ```

3. **CORS پالیسی (Cross-Origin Resource Sharing):**
   ایپ سے بلا روک ٹوک رسائی کے لیے:
   ```nginx
   add_header Access-Control-Allow-Origin *;
   ```

---

## ۶. متعلقہ کوڈ فائلز کی فہرست (Quick Links)

- کیٹلاگ اسکیننگ کا ٹول: [`tools/generate_audio_catalog.py`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/tools/generate_audio_catalog.py)
- سرور یو آر ایل کی ترتیبات: [`lib/constants/app_config.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/constants/app_config.dart)
- کتابوں کا ڈیٹا اور اسکرین: [`lib/screens/books_screen.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/screens/books_screen.dart)
- آڈیو اسکرین اور نیویگیشن: [`lib/screens/audio_screen.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/screens/audio_screen.dart)
- آڈیو پلیئر سروس: [`lib/services/audio_player_service.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/services/audio_player_service.dart)
- ڈاؤن لوڈنگ سروس: [`lib/services/download_service.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/services/download_service.dart)
- آڈیو آف لائن کیش مینیجر: [`lib/utils/audio_cache_manager.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/utils/audio_cache_manager.dart)
- پی ڈی ایف آف لائن کیش مینیجر: [`lib/utils/pdf_cache_manager.dart`](file:///c:/Users/ZESTRO/Documents/GitHub/maktabat_sheikh_abdul_salam_al_rustami/lib/utils/pdf_cache_manager.dart)
