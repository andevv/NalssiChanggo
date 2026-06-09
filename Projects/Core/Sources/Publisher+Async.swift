import Combine

private final class CancellableBox {
    var value: AnyCancellable?
}

public extension Publisher where Failure == Error {

    /// 단일 값을 emit하는 Publisher를 async/await으로 변환한다.
    /// Widget의 `getTimeline` 내 `Task { }` 블록에서 Combine 기반 Repository를 호출할 때 사용.
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            let box = CancellableBox()
            var resumed = false
            box.value = self.sink(
                receiveCompletion: { completion in
                    defer { box.value = nil }
                    guard !resumed else { return }
                    resumed = true
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { value in
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: value)
                    box.value = nil
                }
            )
        }
    }
}
