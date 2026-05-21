import CoreText
import Foundation

public enum FontRegistrar {

    private static let fontFiles: [(name: String, ext: String)] = [
        ("Pretendard-Regular",   "otf"),
        ("Pretendard-Medium",    "otf"),
        ("Pretendard-SemiBold",  "otf"),
        ("Pretendard-Bold",      "otf"),
        ("IBMPlexMono-Regular",  "ttf"),
        ("IBMPlexMono-Medium",   "ttf"),
        ("Caveat-Regular",       "ttf"),
        ("Caveat-Medium",        "ttf"),
    ]

    /// 앱 시작 시 한 번 호출하세요 (NalssiChanggoApp.init 등).
    /// DesignSystem 번들에서 폰트를 읽어 프로세스에 등록합니다.
    public static func register() {
        for font in fontFiles {
            guard let url = Bundle.module.url(forResource: font.name, withExtension: font.ext) else {
                assertionFailure("[DesignSystem] 폰트 파일을 찾을 수 없음: \(font.name).\(font.ext)")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
