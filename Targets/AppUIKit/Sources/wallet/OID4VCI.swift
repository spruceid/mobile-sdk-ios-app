import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs

struct OID4VCI: Hashable {}

struct OID4VCIView: View {

    @State var credential: String?

    @Binding var path: NavigationPath
    
    func getCredential(credentialOffer: String) {
        // TODO: display loading screen (waiting for designs)

        let client = Oid4vciAsyncHttpClient()
        let oid4vciSession = Oid4vci.newWithAsyncClient(client: client)
        Task {
            print("1")
            do {
                try await oid4vciSession.initiateWithOffer(
                    credentialOffer: credentialOffer,
                    clientId: "skit-ref-wallet",
                    redirectUrl: "https://spruceid.com"
                )
                
                let nonce = try await oid4vciSession.exchangeToken()
                print(nonce)
                
                let metadata = try oid4vciSession.getMetadata()
                
                _ = KeyManager.generateSigningKey(id: "reference-app/default-signing")
                let jwk = KeyManager.getJwk(id: "reference-app/default-signing")
                
                let signingInput = try await SpruceIDMobileSdkRs.generatePopPrepare(
                    audience: metadata.issuer(),
                    nonce: nonce,
                    didMethod: .jwk,
                    publicJwk: """
                    {"kty":"EC","crv":"P-256","x":"d781ozWe-MQ85L9FNb6m8l5EabvYo9nXSrJwVOWbbhA","y":"zGuEjtxFW49qQVfMfU30o6QdZcP0EfMb4Zl6P5GUQgk"}
                    """,
                    durationInSecs: nil
                )
                print(signingInput)
                 
                let signature = KeyManager.signPayload(id: "reference-app/default-signing", payload: [UInt8](signingInput))
                
                print(signature)

                
                let pop = try SpruceIDMobileSdkRs.generatePopComplete(
                    signingInput: signingInput,
                    signature: Data(Data(signature!).base64EncodedUrlSafe.utf8)
                )
                print(pop)
                
                let credential = try await oid4vciSession.exchangeCredential(proofsOfPossession: [pop])
                print(credential)
                credential.forEach {
                    print($0.format, $0.payload, String(decoding: Data($0.payload), as: UTF8.self))
                    self.credential = String(decoding: Data($0.payload), as: UTF8.self)
                }
//                self.credential = credential.description
                
            } catch {
                // TODO: display error screen (waiting for designs)
                print(error)
            }
            
        }
    }

    var body: some View {
        if credential == nil {
            ScanningComponent(
                path: $path,
                scanningParams: Scanning(
                    title: "Scan to Add Credential",
                    scanningType: .qrcode,
                    onCancel: {
                        path.removeLast()
                    },
                    onRead: { code in
//                        Task {
//                            do {
//                                try await verifyJwtVp(jwtVp: code)
//                                success = true
//                            } catch {
//                                success = false
//                                print(error)
//                            }
//                        }
                        getCredential(credentialOffer: code)
                    }
                )
            )
        } else {
            Text(credential!)
            .navigationBarBackButtonHidden(true)
        }

    }
}
