# Khai Trí AI (bản 0.5.3 · v9, có AI offline tạo câu hỏi)

App Flutter chạy trên cả Android và iPhone. Bản này gồm:

- Làm 20 câu Toán 10 (viết tay), chọn đáp án và mức tự tin (Đoán / Hơi chắc / Chắc chắn).
- Tính 5 tiêu chí: Ghi nhớ, Hiểu bản chất, Vận dụng, Phân tích, Tự tin chính xác.
- Vẽ biểu đồ radar, chia kết quả thành 4 nhóm (nắm vững, lung lay, hiểu sai ngầm, biết mình chưa biết), gợi ý ôn tập.
- Lưu lịch sử trên máy, so sánh với lần làm trước (nét đứt trên radar).
- Có sẵn bộ đọc và kiểm tra JSON từ AI (`lib/ai/question_generator.dart`) để dùng ở Bước 5.

## Mới ở bản 0.2

- Giao diện mới theo phong cách Apple: phông hệ thống, viền 1px, khoảng trắng rộng, hiệu ứng nhấn thu nhỏ 0,97.
- Sửa lỗi tab Kết quả bị tràn 42 pixel: bỏ lưới tỉ lệ cố định, dùng ô tự co giãn theo nội dung. Nhãn radar ngắn hơn và tự căn theo hướng.
- **So sánh 2 lần làm bài**: radar chồng (trước nét đứt, sau nét liền), chênh lệch từng tiêu chí, các câu đã sửa / vẫn sai / bị tụt. Mở từ trang chính, từ Lịch sử (bấm "So sánh", chọn 2 lần) hoặc nút ở cuối trang Kết quả.
- **Cài đặt** (nút ở góc trang chính): sáng / tối / theo máy, phông chữ, cỡ chữ, giảm chuyển động, nhạc nền (chỗ giữ sẵn), rung, số câu mỗi bài, xáo trộn câu hỏi, xóa lịch sử.

## Bản 0.5.5 (v11): bố cục máy tính, sửa lỗi tạo câu hỏi và nút Dừng

- Cửa sổ rộng (từ 900 px): Trang chính, Làm bài và Kết quả chia 2 cột, co giãn theo cửa sổ; các màn khác căn giữa một cột. Điện thoại giữ nguyên bố cục dọc.
- Tạo câu hỏi: mô hình viết đáp án thành khóa A, B, C, D (dễ hơn mảng); app tự gán nhãn tiêu chí (không tin nhãn mô hình ghi); đọc được nhiều kiểu ghi đáp án đúng; lý do loại câu nói rõ (ví dụ "chỉ có 2/4 đáp án").
- Nút Dừng: về màn hình trước ngay, không đợi mô hình AI chạy xong.

## Bản 0.5.4 (v10): bố cục dọc trên Windows

- Màn hình rộng (Windows, máy tính bảng ngang): app giữ khung dọc như điện thoại, căn giữa, hai bên là nền trống.
- Windows: tắt chụp ảnh và nhắc làm bài, hiển thị "Không hỗ trợ trên Windows".

## Bản 0.5.3 (v9): AI offline không còn treo im lặng

- Hiện lý do các lần thử bị loại ngay trên màn tạo câu hỏi; dừng sau 3 lần mô hình báo lỗi liên tiếp; mỗi lần thử tối đa 3 phút.
- Tài liệu dài: bỏ đoạn quá ngắn và chọn đoạn ngẫu nhiên trải đều cả tài liệu.
- Ghi nhật ký `[AI]` trong console (`flutter run`) để xem mô hình trả lời gì.

## Bản 0.5.2 (v8): `FilePicker.pickFiles` trả về danh sách tệp

## Bản 0.5.1 (v7): sửa lỗi biên dịch

- Bộ chọn tệp dùng cách gọi mới của `file_picker` (`FilePicker.pickFiles`), đọc XML bằng `namespaceUri`, bỏ cảnh báo chú thích thư viện.

## Mới ở bản 0.5 (v6): AI offline tạo câu hỏi

- Nút **Tạo câu hỏi bằng AI** (màn Xem lại chữ): chạy Gemma 3 1B ngay trên máy, mỗi lần một đoạn một câu, kiểm tra từng câu rồi mới nhận. Có màn tiến độ (dừng được) và màn **Duyệt câu hỏi** (xóa câu không ưng, rồi làm bài).
- Mô hình **đóng gói sẵn trong app**, người dùng không phải tải gì. Người phát triển cần đặt file `gemma3-1b-it-int4.litertlm` (khoảng 529 MB) vào `assets/models/` rồi build (xem `assets/models/README.txt`). Chưa có file thì app vẫn chạy, chỉ báo "chưa có mô hình" khi bấm tạo.
- Chế độ Online chưa có (hiện hộp thoại báo).
- Cần thêm gói: `flutter pub add flutter_edge_ai flutter_edge_ai_litertlm`, đặt `minSdk` Android = 26 và không nén file `.litertlm` (`setup.bat` làm sẵn; làm tay thì xem phần dưới).
- App sẽ lớn thêm khoảng 530 MB; lần chạy AI đầu tiên mất 1-2 phút để nạp mô hình.
- Gemma dùng theo Gemma Terms of Use của Google: đã ghi trong mục Giới thiệu của app.

### Làm tay nếu `setup.bat` không sửa được gradle
Trong `android/app/build.gradle.kts`, trong khối `android { ... }` thêm:
```kotlin
androidResources {
    noCompress += listOf("litertlm")
}
```
và đổi `minSdk = flutter.minSdkVersion` thành `minSdk = 26`.

## Mới ở bản 0.4 (v5) (Giai đoạn 1: nhập tài liệu)

- Màn hình **Tạo bộ đề từ tài liệu**: chụp ảnh, ảnh từ thư viện, tệp PDF/Word/PowerPoint/.txt, hoặc dán chữ.
- Đọc chữ: PDF/Word/PowerPoint lấy chữ trực tiếp; ảnh và PDF quét dùng OCR (Google ML Kit) ngay trên máy. PDF có trang hỏng chữ thì tự chuyển sang OCR.
- Màn hình **Xem lại chữ đã đọc**: có điểm chất lượng, cảnh báo, sửa tay, xem các đoạn đã cắt.
- Cài đặt có mục **Chế độ AI** (Offline/Online) với giới hạn của Offline ghi rõ. Chế độ Online mới là công tắc, chưa gắn AI (Giai đoạn 2).
- Bộ kiểm tra câu hỏi dùng chung (`lib/ai/question_checks.dart`): trích dẫn có thật, tiếng Việt, không trùng, đáp án khác nhau.
- Cần thêm các gói: `flutter pub add file_picker image_picker google_mlkit_text_recognition syncfusion_flutter_pdf printing archive xml path_provider` (`setup.bat` đã làm sẵn bước này).
- Nút Tạo câu hỏi chưa hoạt động: sẽ nối AI ở Giai đoạn 2 (Online) và 3 (Offline). Mô hình AI chưa kèm theo.

## Mới ở bản 0.3 (logo, intro, màu Apple)

- **Logo mới** của nhóm (file SVG đã tách thành ảnh `assets/images/logo_icon.png` và chữ `wordmark_light/dark.png`). Intro: biểu tượng bật lên kèm quầng sáng, trượt sang trái, chữ "Khai Trí AI" trượt ra bên phải, rồi vệt sáng quét qua.
- **Icon ứng dụng Android** = logo mới (`setup.bat` tự chép; muốn làm tay thì chép các thư mục trong `android_extra/res/mipmap-*` vào `android/app/src/main/res/`). Icon iPhone chưa thay.
- **Màu UI theo Apple**: xanh hệ thống #007AFF / #0A84FF, nền #F2F2F7 / đen, xanh lá, cam, đỏ chuẩn iOS (bản sáng dùng tông đậm hơn cho chữ để dễ đọc). Công tắc xanh lá và thanh trượt kiểu iOS.

## Mới ở bản 0.3

- **Streak và số bài đã làm** ở trang chính (đếm theo ngày; còn hiệu lực nếu hôm nay hoặc hôm qua có làm bài). Lưu riêng với lịch sử nên xóa lịch sử không mất streak.
- **Nhắc 19:00** nếu hôm nay chưa làm bài, kèm tiếng thông báo. Hôm nay làm rồi thì tự dời sang ngày mai. Bật/tắt trong Cài đặt, có nút "Gửi thử thông báo".
- **Intro**: logo bật lên có quầng sáng (tiếng intro_pop), rồi vệt sáng quét qua (tiếng intro_sweep). Tắt được trong Cài đặt.
- **Âm thanh**: chạm (tap), chọn đáp án (select), công tắc (toggle), kết quả (result), mở trang (whoosh), đóng trang (whoosh_close, đã hạ cao độ). Tất cả đã chuẩn hóa cùng độ to. Tắt được hiệu ứng và nhạc nền riêng; nhạc nền có thanh trượt và ô nhập số 0–100% (mặc định 50%, và 100% vẫn chỉ ở mức nhỏ).
- **Nhạc nền**: file `assets/audio/bgm.mp3` (đã chuẩn hóa nhỏ). Muốn đổi bài thì thay file cùng tên.
- Sửa lỗi bảng Cài đặt không đổi màu nền ngay khi đổi Sáng/Tối.

### Cấu hình Android cho thông báo (làm một lần)

1. Chép `android_extra/res/raw/notification_sound.mp3` vào `android/app/src/main/res/raw/notification_sound.mp3` (tạo thư mục `raw` nếu chưa có).
2. Mở `android/app/src/main/AndroidManifest.xml`. Ngay trên thẻ `<application`, thêm:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```
   Rồi bên trong `<application ...>` (cạnh thẻ `<activity>`), thêm:
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```
3. Mở `android/app/build.gradle.kts` (hoặc `build.gradle` nếu máy bạn dùng bản cũ) và thêm:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
   (Nếu file là `build.gradle` kiểu Groovy: `coreLibraryDesugaringEnabled true` trong `compileOptions` và `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'` trong `dependencies`.)
4. Chạy `flutter pub get`, rồi `flutter run`. Vào Cài đặt, bấm "Gửi thử thông báo" để kiểm tra.

Lưu ý: một số máy (Xiaomi, Oppo, Realme, Vivo) tự tắt thông báo của app chạy ngầm; cần vào Cài đặt máy cho phép app "Tự khởi chạy" hoặc "Không hạn chế pin" thì lời nhắc 19:00 mới chắc chắn hiện. Trên iPhone, thông báo dùng âm mặc định.

### Khai báo phông chữ trong `pubspec.yaml`
Chép thư mục `assets/fonts` vào dự án, rồi thêm (đúng thụt lề, nằm trong mục `flutter:`):
```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter_400Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter_500Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter_600SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter_700Bold.ttf
          weight: 700
    - family: SpotifyMixUI
      fonts:
        - asset: assets/fonts/SpotifyMixUI-Regular.ttf
          weight: 400
        - asset: assets/fonts/SpotifyMixUI-Bold.ttf
          weight: 700
```
Rồi chạy `flutter pub get`. Lưu ý: phông Spotify Mix UI là phông có bản quyền; dùng thi ở trường thì ổn, còn phát hành app thật nên bỏ và dùng Inter.

Nhạc nền: công tắc và thanh âm lượng đã có, chỉ cần gắn trình phát (ví dụ gói `audioplayers`) vào `SettingsController` (xem dòng TODO).

## Cách chạy nhanh nhất (Windows)

1. Giải nén bộ code ra một thư mục mới tên `khai_tri_ai`.
2. Bấm đúp file **`setup.bat`** (hoặc mở PowerShell trong thư mục đó và chạy `.\setup.ps1`). Script tự làm: `flutter create` (tạo khung Android/iPhone), xóa file test mẫu, chép âm thanh thông báo, sửa AndroidManifest + gradle, `flutter pub get`.
3. Cắm điện thoại, chạy `flutter devices`, rồi `flutter run -d <mã máy>`.

Các mục bên dưới là cách làm tay, chỉ cần khi script báo lỗi.

## Cách chạy (dành cho người mới)

### 1. Cài công cụ
1. Cài Flutter: https://docs.flutter.dev/get-started/install (chọn hệ điều hành của bạn).
2. Cài **Android Studio** (để có công cụ Android). iPhone thì cần máy **Mac** có **Xcode**.
3. Mở Terminal, gõ `flutter doctor` và làm theo các mục còn dấu ✗.

### 2. Tạo dự án và chép code vào
```bash
flutter create khai_tri_ai
cd khai_tri_ai
flutter pub add shared_preferences
```
Sau đó **xóa thư mục `lib` và `test` có sẵn** trong `khai_tri_ai`, rồi chép thư mục `lib` và `test` của bộ code này vào thay thế.
Tên dự án phải đúng là `khai_tri_ai` vì file test gọi đến tên này.

### 3. Chạy thử
Cắm điện thoại Android (đã bật Chế độ nhà phát triển và Gỡ lỗi USB), rồi:
```bash
flutter devices        # xem điện thoại đã được nhận chưa
flutter run            # chạy app lên điện thoại
flutter test           # chạy các bài test chấm điểm
```
Trên iPhone: mở `ios/Runner.xcworkspace` bằng Xcode, chọn tài khoản Apple ở mục Signing, rồi chạy `flutter run`.

## Cách chấm điểm (để bạn giải thích với ban giám khảo)

Mỗi câu có đúng/sai và mức tự tin (0 = Đoán, 1 = Hơi chắc, 2 = Chắc chắn).

| | Đoán | Hơi chắc | Chắc chắn |
|---|---|---|---|
| Đúng | 0,4 điểm | 0,7 điểm | 1 điểm |
| Sai | 0,1 điểm | 0,05 điểm | 0 điểm |

- Điểm mỗi tiêu chí = trung bình điểm các câu thuộc nhãn đó, nhân 100.
- **Tự tin chính xác** = trung bình của `1 − |đúng(1/0) − tự tin/2|`. Đúng và chắc chắn được 1, sai và đoán được 1, sai nhưng chắc chắn được 0.
- 4 nhóm: Đúng + (Hơi chắc/Chắc chắn) = nắm vững; Đúng + Đoán = lung lay; Sai + (Hơi chắc/Chắc chắn) = **hiểu sai ngầm**; Sai + Đoán = biết mình chưa biết.

Các con số điểm là đề xuất, nhóm có thể chỉnh trong `lib/logic/scoring.dart` (hàm `points`).

## Mẫu JSON mà AI phải trả về (Bước 5)

```json
[{
  "cau_hoi": "...",
  "dap_an": ["A. ...", "B. ...", "C. ...", "D. ..."],
  "dap_an_dung": "B",
  "tieu_chi": "nho | hieu | van_dung | phan_tich",
  "trich_dan": "đoạn nguyên văn trong tài liệu",
  "loi_sai_pho_bien": {"A": "kiểu hiểu sai", "C": "..."},
  "giai_thich": "..."
}]
```
Hàm `parseAiQuestions` sẽ loại câu thiếu trường, đáp án trùng, nhãn sai hoặc trích dẫn không có trong tài liệu.

## Cấu trúc thư mục
```
lib/
  main.dart                  Điểm vào của app
  models/                    Câu hỏi, câu trả lời, lần làm bài
  logic/scoring.dart         Tính 5 tiêu chí và gợi ý ôn tập
  data/sample_questions.dart 20 câu Toán 10
  ai/question_generator.dart Bộ đọc JSON từ AI và chỗ gắn AI sau này
  storage/history_store.dart Lưu lịch sử trên máy
  ui/                        Các màn hình và biểu đồ radar
test/scoring_test.dart       Test chấm điểm và bộ đọc JSON
```

## Lưu ý
- Code này chưa được chạy thử trên thiết bị thật khi viết. Nếu có lỗi khi chạy `flutter run` hoặc `flutter test`, hãy dán nguyên thông báo lỗi để sửa.
- Ký hiệu toán (ℝ, ∀, ∃, ∩, ∪, Δ, √) cần font hệ thống hiển thị được. Nếu thấy ô vuông, báo lại để đổi cách hiển thị.
- Câu hỏi mẫu nên được thầy cô rà soát lại trước khi cho học sinh dùng thật.
