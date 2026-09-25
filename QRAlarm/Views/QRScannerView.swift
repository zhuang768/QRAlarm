import SwiftUI
import VisionKit

/// A SwiftUI wrapper for VisionKit's DataScannerViewController
struct QRScannerView: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    var onDetect: (String) -> Void

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: QRScannerView

        init(_ parent: QRScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }

            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    // 為了避免連續觸發多次，可以在發現後立刻暫停掃描
                    dataScanner.stopScanning()
                    parent.onDetect(payload)
                }
            default:
                break
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        } else {
            if uiViewController.isScanning {
                uiViewController.stopScanning()
            }
        }
    }

    /// 確認設備是否支援掃描器
    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}
