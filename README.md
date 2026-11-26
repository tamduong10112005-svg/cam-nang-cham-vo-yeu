# Cẩm nang chăm vợ yêu

Ứng dụng Flutter tiếng Việt — “Hiểu nàng hơn – Yêu nàng đúng cách – Đồng hành trọn đời.” Không tích hợp AI/chatbot, không gửi dữ liệu lên máy chủ.

## Chạy thử

1. Cài Flutter stable và Android Studio/SDK.
2. Giải nén source ZIP và mở thư mục dự án.
3. Chạy `flutter pub get` rồi `flutter run` trên Android.

Hoặc cài APK release để dùng thử: chép `cam-nang-cham-vo-yeu-release.apk` sang điện thoại Android, mở tệp, cho phép cài ứng dụng từ nguồn này nếu Android hỏi, rồi chọn **Cài đặt**. Bản phát hành thử dùng upload key được lưu riêng, không nằm trong source ZIP.

## Chức năng đã làm

- Trang chủ: lời chào cá nhân, ngày, chu kỳ dự đoán, việc hôm nay và kỷ niệm sắp tới.
- Sổ tay: tạo/sửa/xóa, tìm kiếm, lọc danh mục, yêu thích; danh mục món ăn, địa điểm, sở thích và nhật ký; ảnh cục bộ. Địa điểm lưu tên, địa chỉ và link riêng; nút mở dùng link trước, nếu không có link thì chỉ tìm theo địa chỉ (không ghép tên quán).
- Chu kỳ: ngày bắt đầu, độ dài trung bình, lịch sử, ngày kết thúc, triệu chứng, tâm trạng và mức đau. Dự đoán chỉ để tham khảo, không chẩn đoán và không dùng tránh thai.
- Nhắc nhở: kỷ niệm (nhắc trước 30/7/3/1 ngày và đúng ngày), việc chăm sóc có ưu tiên/trạng thái, kế hoạch sức khỏe, lịch lặp hằng tháng/hằng năm, tùy chỉnh các tháng mùa mưa và giờ nhắc.
- Có công tắc riêng cho nhóm mùa, chu kỳ, kỷ niệm, sức khỏe và việc chăm sóc. Thông báo lịch hiện tiêu đề và ghi chú đã nhập, có thể hiển thị trên màn hình khóa theo cài đặt của Android; Android khôi phục lịch sau khi khởi động lại.
- Hồ sơ: biệt danh, khóa PIN (PBKDF2), sinh trắc học nếu thiết bị hỗ trợ, xuất/khôi phục JSON có kèm ảnh.
- Ghi chú, lịch, chu kỳ và cài đặt riêng tư được mã hóa AES-GCM; khóa dữ liệu lưu trong keystore/keychain của nền tảng. Nội dung lịch nhắc sẽ hiện trên màn hình khóa khi hệ điều hành cho phép.

## Kiểm tra đã chạy

- `flutter analyze`: thành công, không có vấn đề.
- `flutter build apk --debug`: thành công.
- `flutter build apk --release`: thành công, ký bằng upload key riêng cho Play.
- Android emulator Medium Phone API 37.0: cài APK release và mở ứng dụng thành công; emulator có lúc hiện cảnh báo ANR của dịch vụ hệ thống Android (`com.android.phone`/System UI), không thấy lỗi fatal của ứng dụng. Chưa thử trên điện thoại thật.
- `flutter build appbundle --release`: thành công; AAB đã qua kiểm tra chữ ký `jarsigner`.
- Android: `compileSdk 37`, `targetSdk 36`; quyền thông báo, khởi động lại lịch và sinh trắc học đã khai báo.
- iOS: scaffold và mô tả quyền Face ID/ảnh đã cấu hình. Chưa thể build/chạy iOS trên Windows vì cần macOS/Xcode.

## Giới hạn hiện tại

- Android dùng thông báo gần đúng để tránh yêu cầu quyền báo thức chính xác; hệ điều hành có thể giao trễ khi tiết kiệm pin. Các nhóm có công tắc riêng nhưng đang dùng chung giờ nhắc.
- Ảnh ở thư mục riêng của ứng dụng, chưa mã hóa riêng từng tệp. Tệp JSON backup không mã hóa để người dùng có thể phục hồi; hãy lưu ở nơi riêng tư.
- Chưa ký iOS, kiểm tra accessibility/đa kích cỡ trên thiết bị, hay đưa ứng dụng lên store.

## Phát hành Google Play

- `android/upload-keystore.jks` và `android/key.properties` là bí mật, không đưa vào Git/source ZIP. Hãy giữ nhiều bản sao an toàn; các lần upload sau cần cùng upload key. Google Play App Signing sẽ ký bản cài đặt cho người dùng.
- Nếu giải nén source ZIP để build, chép `android/key.properties.example` thành `android/key.properties`, nhập mật khẩu upload key và để `upload-keystore.jks` trong `android/`.
- Store listing, hình ảnh, chính sách quyền riêng tư và checklist nằm trong `play_store/`. Chính sách HTML cần email hỗ trợ và URL công khai hoạt động trước khi gửi duyệt.
- Khi chuyển từ APK cài thủ công đã ký bằng debug key sang bản Play, chữ ký ứng dụng sẽ đổi. Có thể cần gỡ bản cũ một lần; trước đó xuất bản sao lưu trong Hồ sơ. Sau cài đặt qua Play Store, các bản cập nhật đến từ Play Store.

## Build

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

APK được tạo ở `build/app/outputs/flutter-apk/`.

## Cập nhật Android qua GitHub Releases

Ứng dụng có mục **Hồ sơ → Cập nhật ứng dụng**. Bản phát hành kiểm tra GitHub Releases công khai, tải `cam-nang-cham-vo-yeu.apk`, rồi mở trình cài đặt Android. Người dùng phải cho phép cài ứng dụng từ nguồn này và xác nhận cài đặt; Android không cho ứng dụng tự cài âm thầm. Dữ liệu ứng dụng được giữ lại khi APK mới dùng cùng package ID và cùng khóa ký.

### Thiết lập một lần

1. Tạo một repository **public** trên GitHub và tải source dự án này lên. Không tải `android/upload-keystore.jks`, `android/key.properties`, APK/AAB hoặc tệp thông tin mật khẩu lên repository. Các mục này đã được đưa vào `.gitignore`.
2. Trong **Settings → Secrets and variables → Actions**, thêm bốn repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`.
3. Tạo giá trị `ANDROID_KEYSTORE_BASE64` cục bộ bằng PowerShell (thay đường dẫn nếu keystore của bạn nằm nơi khác):

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/upload-keystore.jks")) | Set-Clipboard
   ```

   Dán clipboard vào secret `ANDROID_KEYSTORE_BASE64`. Nhập alias và mật khẩu qua giao diện GitHub Secrets; không ghi chúng vào source.
4. Mỗi lần phát hành, tăng `version:` trong `pubspec.yaml` (ví dụ `1.0.2+3`) và push source. Tạo Release/tag mới trên GitHub, ví dụ `v1.0.2`, rồi mở **Actions → Build and publish Android release → Run workflow** và nhập tag đó. GitHub Actions sẽ build APK ký bằng khóa riêng và đính kèm APK vào Release. Ứng dụng đã cài sẽ nhìn thấy bản mới ở lần người dùng chọn **Cập nhật ứng dụng**.

Không tạo khóa ký mới sau khi đã phát hành. Bản APK phát hành lần đầu cần được cài bằng cùng khóa mà GitHub Actions dùng cho mọi lần cập nhật. Nếu điện thoại đang có bản debug ký bằng khóa khác, cần sao lưu dữ liệu rồi chuyển sang bản release một lần; các lần sau sẽ cài đè bình thường.

### Chạy/build ngoài GitHub Actions

Khi build thủ công, truyền repository public của bạn, ví dụ:

```powershell
flutter build apk --release --dart-define=UPDATE_REPOSITORY=TEN_TAI_KHOAN/TEN_REPOSITORY
```

Nếu bỏ tham số này, mục cập nhật sẽ báo rằng ứng dụng chưa được nối với GitHub.

