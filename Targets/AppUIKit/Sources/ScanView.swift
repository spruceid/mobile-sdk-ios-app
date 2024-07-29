import CoreBluetooth
import SwiftUI
import SpruceIDWalletSdk

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

public struct ScanView: View {
    @State private var scanned: String?

    public var body: some View {
        QRCodeScanner(onRead: onRead, onCancel: onCancel)
            .sheet(item: $scanned, onDismiss: onCancel) {
                scanned in
                MDocReaderView(uri: scanned, requestedItems: ["org.iso.18013.5.1": ["given_name": true]])
            }
    }

    func onCancel() {
        self.scanned = nil
    }
    
    func onRead(code: String) {
        self.scanned = code
        
    }
}

public struct MDocReaderView: View {
    @StateObject var delegate: MDocScanViewDelegate
    @Environment(\.presentationMode) var presentationMode
    
    init(uri: String, requestedItems: [String: [String: Bool]]) {
        self._delegate = StateObject(wrappedValue: MDocScanViewDelegate(uri: uri, requestedItems: requestedItems))
    }
    
    public var body: some View {
        VStack {
            switch self.delegate.state {
            case .advertizing:
                Text("Waiting for holder...")
            case .connected:
                Text("Connected to holder!")
            case .error(let error):
                let message = switch error {
                case .bluetooth(let central):
                    switch central.state {
                            case .poweredOff:
                                "Is Powered Off."
                            case .unsupported:
                                "Is Unsupported."
                            case .unauthorized:
                                switch CBManager.authorization {
                                case .denied:
                                    "Authorization denied"
                                case .restricted:
                                    "Authorization restricted"
                                case .allowedAlways:
                                    "Authorized"
                                case .notDetermined:
                                    "Authorization not determined"
                                @unknown default:
                                    "Unknown authorization error"
                                }
                            case .unknown:
                                "Unknown"
                            case .resetting:
                                "Resetting"
                    case .poweredOn:
                       "Impossible"
                    @unknown default:
                                "Error"
                            }
                case .server(let error):
                    error
                case .generic(let error):
                    error
                }
                Text(message)
            case .downloadProgress(let index):
                ProgressView(label: {
                    Text("Downloading... \(index) chunks received so far.").font(.caption).foregroundStyle(.secondary)
                }).progressViewStyle(.circular)
            case .success(let items):
                Text("Success! Received: \(items)")
            }
            Button("Cancel") {
                self.cancel()
            }.padding(10).buttonStyle(.bordered).tint(.red).foregroundColor(.red)
        }
    }
    
    func cancel() {
        self.delegate.cancel()
        presentationMode.wrappedValue.dismiss()
    }
}

class MDocScanViewDelegate: ObservableObject {
    @Published var state: BLEReaderSessionState = .advertizing
    private var mdocReader: MDocReader?
    
    init(uri: String, requestedItems: [String: [String: Bool]]) {
        self.mdocReader = MDocReader(callback: self, uri: uri, requestedItems: requestedItems)
    }
    
    func cancel() {
        self.mdocReader?.cancel()
    }
}

extension MDocScanViewDelegate: BLEReaderSessionStateDelegate {
    public func update(state: BLEReaderSessionState) {
        self.state = state
    }
}
