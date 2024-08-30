import CoreBluetooth
import CoreImage.CIFilterBuiltins
import SwiftUI
import SpruceIDMobileSdk
import CryptoKit

func generateQRCode(from data: Data) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = data
    if let outputImage = filter.outputImage {
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }
    return UIImage(systemName: "xmark.circle") ?? UIImage()
}

public struct QRSheetView: View {
    var credentials: CredentialStore
    @State var proceed = true
    @StateObject var delegate: ShareViewDelegate
    @Environment(\.presentationMode) var presentationMode
    
    init(credentials: [Credential]) {
        let credentialStore = CredentialStore(credentials: credentials)
        self.credentials = credentialStore
        self._delegate = StateObject(wrappedValue: ShareViewDelegate(credentials: credentialStore))
    }
    
    @ViewBuilder
    var cancelButton: some View {
        Button("Cancel") {
            self.delegate.cancel()
        }
            .padding(10)
            .buttonStyle(.bordered)
            .tint(.red)
            .foregroundColor(.red)
    }
    
    public var body: some View {
        VStack {
            switch self.delegate.state {
            case .engagingQRCode(let data):
                Image(uiImage: generateQRCode(from: data))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
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
                case .peripheral(let error):
                    error
                case .generic(let error):
                    error
                }
                Text(message)
            case .uploadProgress(let value, let total):
                ProgressView(value: Double(value), total: Double(total),
                             label: {
                    Text("Uploading...").padding(.bottom, 4)
                }, currentValueLabel: {
                    Text("\(100 * value/total)%")
                        .padding(.top, 4)
                }
                ).progressViewStyle(.linear)
                cancelButton
            case .success:
                let _ = presentationMode.wrappedValue.dismiss()
                Text("Credential Sent")
            case .selectNamespaces(let items):
                SelectiveDisclosureView(itemsRequests: items, delegate: delegate, proceed: $proceed)
                    .onChange(of: proceed) { _ in
                        self.delegate.cancel()
                    }
            case .connected:
                Text("Connected")
                cancelButton
            case .canceled:
                Text("Operation canceled")
            }
            
        }
    }
    
    func cancel() {
        self.delegate.cancel()
        presentationMode.wrappedValue.dismiss()
    }
}

class ShareViewDelegate: ObservableObject {
    @Published var state: BLESessionState = .connected
    private var sessionManager: BLESessionManager?
    
    init(credentials: CredentialStore) {
        self.sessionManager = credentials.presentMdocBLE(deviceEngagement: .QRCode, callback: self)!
    }
    
    func cancel() {
        self.sessionManager?.cancel()
    }
    
    func submitItems(items: [String: [String: [String: Bool]]]) {
        self.sessionManager?.submitNamespaces(items: items.mapValues { namespaces in
            return namespaces.mapValues { items in
                Array(items.filter { $0.value }.keys)
            }
        })
    }
}

extension ShareViewDelegate: BLESessionStateDelegate {
    public func update(state: BLESessionState) {
        self.state = state
    }
}


//struct ShareView_Previews: PreviewProvider {
//    static var previews: some View {
//        let credentials = [generateMDoc()!]
//        ShareView(credentials: .constant(CredentialStore(credentials: credentials)))
//    }
//}
