import UIKit

/// 시스템 공유 시트. SwiftUI ShareLink는 iOS 17.0에서 여러 개가 동시에 항목을 등록할 때
/// CoreTransferable 내부에서 크래시가 나서, 버튼을 누를 때만 UIKit 공유 시트를 띄운다
enum ShareSheet {
    @MainActor
    static func present(_ items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var top = scene.keyWindow?.rootViewController else { return }
        while let next = top.presentedViewController { top = next }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = top.view
        vc.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY - 80, width: 1, height: 1)
        top.present(vc, animated: true)
    }
}
