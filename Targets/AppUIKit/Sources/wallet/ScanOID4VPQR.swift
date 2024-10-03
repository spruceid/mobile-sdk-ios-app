import SpruceIDMobileSdkRs
import SwiftUI

struct ScanOID4VP: Hashable {}

struct ScanOID4VPQR: View {

    @State var success: Bool?

    @Binding var path: NavigationPath

    var body: some View {
        ScanningComponent(
            path: $path,
            scanningParams: Scanning(
                scanningType: .qrcode,
                onCancel: {
                    path.removeLast()
                },
                onRead: { code in
                    Task {
                        do {
                            // TODO: Add other checks as necessary for
                            // validating OID4VP url and handle OID4VP flow
                            success = true
                        } catch {
                            success = false
                            print(error)
                        }
                    }
                }
            )
        )
    }
}
