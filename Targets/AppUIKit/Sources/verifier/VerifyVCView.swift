import SwiftUI
import SpruceIDMobileSdkRs

struct VerifyVC: Hashable {}

struct VerifyVCView: View {
    
    @State var success: Bool?
    
    @Binding var path: NavigationPath
    
    var body: some View {
        if(success == nil) {
            ScanningComponent(
                path: $path,
                scanningParams: Scanning(
                    scanningType: .qrcode,
                    onCancel: {
                        print("Cancel")
                        path.removeLast()
                    },
                    onRead: { code in
                        Task {
                            do {
                                try await verifyJwtVp(jwtVp: code)
                                success = true
                            } catch {
                                success = false
                                print(error)
                            }
                        }
                    }
                )
            )
        } else {
            VerifierSuccessView(path: $path, success: success!, description: success! ? "Valid Verifiable Credential" : "Invalid Verifiable Credential")
        }
        
    }
}
