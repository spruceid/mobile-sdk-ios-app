import SpruceIDMobileSdkRs
import SpruceIDMobileSdk
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
    @State private var permissionResponse: PermissionResponse? = nil
    @State private var selectedCredential: ParsedCredential? = nil
    @State private var credentialClaims: [String: [String: GenericJSON]] = [:]

    @State private var err: String? = nil

    func credentialSelector(
        credentials: [ParsedCredential],
        onSelectedCredential: @escaping ([ParsedCredential]) -> Void
    ) {
        // TODO: Implement UI component for selecting a valid
        // credential for satisfying the permission request
    }
    
    func presentCredential() async {
        print("????? URL: \(url)")

        do {
            let credentials = rawCredentials.map { rawCredential in
                // TODO: Update to use VDC collection in the future
                // to detect the type of credential.
                do {
                    return try ParsedCredential.newSdJwt(sdJwtVc: Vcdm2SdJwt.newFromCompactSdJwt(input: rawCredential))
                } catch {
                    return nil
                }
            }.compactMap{ $0 }
            
            let credentialPack = CredentialPack()
            
            credentials.forEach { credential in
                _ = credentialPack.addSdJwt(sdJwt: credential.asSdJwt()!)
            }
            
            credentialClaims = credentialPack.findCredentialClaims(claimNames: ["name", "type"])
                        
            print("#Credentials -- \(credentials.count)")

            holder = try await Holder.newWithCredentials(
                providedCredentials: credentials, trustedDids: trustedDids)
            
            print("Holder -- \(holder)")

            permissionRequest = try await holder!.authorizationRequest(url: Url(url))
            
            
//            print("PermissionRequest -- \(permissionRequest) --- # \(permissionRequest.credentials().count)")
//            
//            let permissionResponse = permissionRequest.createPermissionResponse(selectedCredential: credentials.first!)
//            
//            print("PermissionResponse -- \(permissionResponse)")
//            
//            _ = try await holder.submitPermissionResponse(response: permissionResponse)

        } catch {
            print("Error: \(error)")
        }
    }
    
    func back() {
        while !path.isEmpty {
            path.removeLast()
        }
    }

    var body: some View {
        if err != nil {
            ErrorView(
                errorTitle: "Error Presenting Credential",
                errorDetails: err!,
                onClose: {
                    back()
                }
            )
        } else {
            if permissionRequest == nil {
                LoadingView(loadingText: "Loading...")
                .task {
                    await presentCredential()
                }
            } else if permissionResponse == nil {
                if !(permissionRequest?.credentials().isEmpty ?? false) {
                    CredentialSelector(
                        credentials: permissionRequest!.credentials(),
                        credentialClaims: credentialClaims,
                        getRequestedFields: { credential in
                            return permissionRequest!.requestedFields(credential: credential)
                        },
                        onContinue: { selectedCredentials in
                            do {
                                selectedCredential = selectedCredentials.first
                                permissionResponse = permissionRequest!.createPermissionResponse(
                                    selectedCredential: selectedCredential!
                                )
                            } catch {
                                err = error.localizedDescription
                            }
                        },
                        onCancel: {
                            back()
                        }
                    )
                } else {
                    ErrorView(
                        errorTitle: "No matching credential(s)",
                        errorDetails: "There are no credentials in your wallet that match the verification request you have scanned",
                        closeButtonLabel: "Cancel",
                        onClose: {
                            back()
                        }
                    )
                }
            } else {
                // DataFieldSelector
            }
        }
    }
}

struct CredentialSelector: View {
    let credentials: [ParsedCredential]
    let credentialClaims: [String: [String: GenericJSON]]
    let getRequestedFields: (ParsedCredential) -> [RequestedField]
    let onContinue: ([ParsedCredential]) -> Void
    let onCancel: () -> Void
    var allowMultiple: Bool = false
    
    @State private var selectedCredentials: [ParsedCredential] = []
    
    func selectCredential(credential: ParsedCredential) {
        if allowMultiple {
            selectedCredentials.append(credential)
        } else {
            selectedCredentials.removeAll()
            selectedCredentials.append(credential)
        }
    }
    
    func getCredentialTitle(credential: ParsedCredential) -> String {
        if let name = credentialClaims[credential.id()]?["name"]?.toString() {
            return name
        } else if let types = credentialClaims[credential.id()]?["type"]?.arrayValue {
            var title = ""
            types.forEach {
                if $0.toString() != "VerifiableCredential" {
                    title = $0.toString().camelCaseToWords()
                    return
                }
            }
            return title
        } else {
            return ""
        }
    }
    
    func toggleBinding(for credential: ParsedCredential) -> Binding<Bool> {
        Binding {
            selectedCredentials.contains(where: { $0.id() == credential.id()} )
        } set: { _ in
            // TODO: update when allowing multiple
            selectCredential(credential: credential)
        }
    }
    
    var body: some View {
        VStack {
            Text("Select the credential\(allowMultiple ? "(s)" : "") to share")
            
            // TODO: Add select all when implement allowMultiple
            
            ScrollView {
                ForEach(0..<credentials.count, id: \.self) { idx in
                    
                    let credential = credentials[idx]
                    
                    CredentialSelectorItem(
                        credential: credential,
                        requestedFields: getRequestedFields(credential),
                        getCredentialTitle: { credential in
                            getCredentialTitle(credential: credential)
                        },
                        isChecked: toggleBinding(for: credential)
                    )
                }
            }
            
            // Cancel / Continue buttons
        }
    }
}

struct CredentialSelectorItem: View {
    let credential: ParsedCredential
    let requestedFields: [String]
    let getCredentialTitle: (ParsedCredential) -> String
    @Binding var isChecked: Bool
    
    @State var expanded = false
    
    init(
        credential: ParsedCredential,
        requestedFields: [RequestedField],
        getCredentialTitle: @escaping (ParsedCredential) -> String,
        isChecked: Binding<Bool>
    ) {
        self.credential = credential
        self.requestedFields = requestedFields.map { field in
            field.name().capitalized
        }
        self.getCredentialTitle = getCredentialTitle
        self._isChecked = isChecked
    }
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $isChecked) {
                    Text(getCredentialTitle(credential))
                }
                .toggleStyle(iOSCheckboxToggleStyle())
                Spacer()
                if expanded {
                    // seta pra dentro
                    Text("Close")
                        .onTapGesture {
                            expanded = false
                        }
                } else {
                    // seta pra fora
                    Text("Open")
                        .onTapGesture {
                            expanded = true
                        }
                }
            }
            VStack {
                ForEach(requestedFields, id: \.self) { field in
                    Text("• \(field)")
                }
            }
            .hide(if: expanded)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("BorderSecondary"), lineWidth: 1)
        )
    }
}

struct iOSCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        // 1
        Button(action: {

            // 2
            configuration.isOn.toggle()

        }, label: {
            HStack {
                // 3
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")

                configuration.label
            }
        })
    }
}


// Load the Credential View
//ZStack {
    //credentialSelector(
    //    credentials: permissionRequest!.credentials()
    //) { selectedCredentials in
    //    Task {
    //        do {
    //            guard let selectedCredential = selectedCredentials.first else { return }
    //            let permissionResponse = permissionRequest!.createPermissionResponse(
    //                selectedCredential: selectedCredential)

    //            print("Submitting permission response")

    //            holder!.submitPermissionResponse(response: permissionResponse)
    //        } catch {
    //            print("Error: \(error)")
    //        }
    //    }
    //}
//}
