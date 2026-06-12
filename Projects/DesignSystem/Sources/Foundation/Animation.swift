import SwiftUI

// MARK: - Animation Tokens

extension Animation {
    /// 탭 시 눌리는 애니메이션
    public static let ncTapPress = Animation.spring(response: 0.2, dampingFraction: 0.9)
    /// 손가락을 떼고 튀어오르는 bounce 애니메이션
    public static let ncTapBounce = Animation.spring(response: 0.4, dampingFraction: 0.5)
}

// MARK: - NCBounceButtonStyle

/// Button label 전체에 탭 bounce 피드백을 적용하는 ButtonStyle
public struct NCBounceButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(
                configuration.isPressed ? .ncTapPress : .ncTapBounce,
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == NCBounceButtonStyle {
    public static var ncBounce: NCBounceButtonStyle { NCBounceButtonStyle() }
}

// MARK: - bounceTap modifier

/// .onTapGesture 대신 사용. 탭 시 scale bounce 피드백 후 action을 실행한다.
private struct BounceTapModifier: ViewModifier {
    let action: () -> Void
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(
                isPressed ? .ncTapPress : .ncTapBounce,
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

extension View {
    /// 탭 bounce 피드백과 함께 action을 실행한다. .onTapGesture 대신 사용.
    public func bounceTap(action: @escaping () -> Void) -> some View {
        modifier(BounceTapModifier(action: action))
    }
}

// MARK: - Staggered Entrance

/// 뷰가 처음 등장할 때 아래에서 위로 슬라이드하며 페이드인한다.
/// index가 클수록 더 늦게 등장해 순차적인 카드 입장 효과를 만든다.
private struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 22)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.45, dampingFraction: 0.78)
                    .delay(Double(index) * 0.055)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// 카드 목록에서 순차 등장 애니메이션을 적용한다. index는 0부터 시작.
    public func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
