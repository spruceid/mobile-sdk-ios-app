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
            do {
                try await oid4vciSession.initiateWithOffer(
                    credentialOffer: credentialOffer,
                    clientId: "skit-ref-wallet",
                    redirectUrl: "https://spruceid.com"
                )
                
                let nonce = try await oid4vciSession.exchangeToken()
                
                let metadata = try oid4vciSession.getMetadata()
                
                _ = KeyManager.generateSigningKey(id: "reference-app/default-signing")
                let jwk = KeyManager.getJwk(id: "reference-app/default-signing")
                
                let signingInput = try await SpruceIDMobileSdkRs.generatePopPrepare(
                    audience: metadata.issuer(),
                    nonce: nonce,
                    didMethod: .jwk,
                    publicJwk: jwk!,
                    durationInSecs: nil
                )
                 
                let signature = KeyManager.signPayload(id: "reference-app/default-signing", payload: [UInt8](signingInput))
                
                let pop = try SpruceIDMobileSdkRs.generatePopComplete(
                    signingInput: signingInput,
                    signature: Data(Data(signature!).base64EncodedUrlSafe.utf8)
                )
                
                let credential = try await oid4vciSession.exchangeCredential(proofsOfPossession: [pop])
                credential.forEach {
                    self.credential = String(decoding: Data($0.payload), as: UTF8.self)
                }
                
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
                        getCredential(credentialOffer: code)
                    }
                )
            )
        } else {
            // TODO: display add to wallet for any credential
            Text(credential!)
        }

    }
}
