import SpruceIDMobileSdk
import SpruceIDMobileSdkRs
import SwiftUI

struct HandleOID4VP: Hashable {
    var url: String
}

struct HandleOID4VPView: View {
    @Binding var path: NavigationPath
    var url: String
    @State var rawCredentials: [String] = CredentialDataStore.shared.getAllRawCredentials()
    @State private var holder: Holder? = nil
    @State private var permissionRequest: PermissionRequest? = nil
    @State var presentError: Bool
    @State var errorDetails: String

    func launchEffect(url: URL, rawCredentials: [String], trustedDIDs: [String]) {
        print("URL: \(url)")

        do {
            let credentials = try rawCredentials.map { rawCredential -> ParsedCredential in
                // TODO: Update to use VDC collection in the future
                // to detect the type of credential.
                let sdJwt = try SdJwt.newFromCompactSdJwt(rawCredential)
                return ParsedCredential.newSdJwt(sdJwt).intoGenericForm()
            }

            DispatchQueue.global(qos: .userInitiated).async {
                holder = Holder.newWithCredentials(
                    credentials: credentials, trustedDIDs: trustedDIDs)
                permissionRequest = holder?.authorizationRequest(url: url)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func credentialSelector(
        credentials: [ParsedCredential],
        onSelectedCredential: @escaping ([ParsedCredential]) -> Void
    ) {
        // TODO: Implement UI component for selecting a valid
        // credential for satisfying the permission request
    }

    var body: some View {
        if permissionRequest == nil {
            // Show a loading screen
            ZStack {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Loading... \(url)")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.regular)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            }
        } else {
            // Load the Credential View
            credentialSelector(
                credentials: permissionRequest!.credentials()
            ) { selectedCredentials in
                Task {
                    do {
                        guard let selectedCredential = selectedCredentials.first else { return }
                        let permissionResponse = permissionRequest!.createPermissionResponse(
                            selectedCredential)

                        print("Submitting permission response")

                        holder!.submitPermissionResponse(permissionResponse)
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
    }
}
