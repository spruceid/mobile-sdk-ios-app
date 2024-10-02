import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs

struct WalletHomeView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
            WalletHomeHeader(path: $path)
            WalletHomeBody(path: $path)
        }
        .navigationBarBackButtonHidden(true)
    }
}

extension Data {
  var base64EncodedUrlSafe: String {
    let string = self.base64EncodedString()

    // Make this URL safe and remove padding
    return string
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

struct WalletHomeHeader: View {
    @Binding var path: NavigationPath

    var body: some View {
        HStack {
            Text("Spruce Wallet")
                .font(.customFont(font: .inter, style: .bold, size: .h0))
                .padding(.leading, 36)
                .foregroundStyle(Color("TextHeader"))
            Spacer()
            Button {
//                path.append(WalletSettingsHome())
                let client = Oid4vciAsyncHttpClient()
                let oid4vciSession = Oid4vci.newWithAsyncClient(client: client)
                Task {
                    print("1")
                    do {
                        let res1 = try await oid4vciSession.initiateWithOffer(
                            credentialOffer: "openid-credential-offer://?credential_offer_uri=https%3A%2F%2Fqa.veresexchanger.dev%2Fexchangers%2Fz1A68iKqcX2HbQGQfVSfFnjkM%2Fexchanges%2Fz19yKV1qydHnEzuo4qNgDXfSS%2Fopenid%2Fcredential-offer",
                            clientId: "skit-ref-wallet",
                            redirectUrl: "https://google.com"
                        )
                        print(res1)
                        
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
                        
                    } catch {
                        print(error)
                    }
                    
                }
                
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color("Primary"))
                        .frame(width: 36, height: 36)
                    Image("User")
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 10)
    }
}

struct WalletHomeBody: View {
    @Binding var path: NavigationPath
    
    @State var credentials: [Credential] = []

    var body: some View {
        ZStack {
            if(!credentials.isEmpty) {
                ScrollView(.vertical, showsIndicators: false) {
                    Section {
                        ForEach(credentials, id: \.self.id) { credential in
                            AchievementCredentialItem(
                                rawCredential: credential.rawCredential,
                                onDelete: {
                                    _ = CredentialDataStore.shared.delete(id: credential.id)
                                    self.credentials = CredentialDataStore.shared.getAllCredentials()
                                }
                            )
                        }
                        //                    ForEach(vcs, id: \.self) { vc in
                        //                        GenericCredentialListItem(vc: vc)
                        //                    }
                        //                    ShareableCredentialListItem(mdoc: mdocBase64)
                    }
                    .padding(.bottom, 50)
                }
            } else {
                VStack {
                    Spacer()
                    Section {
                        Image("EmptyWallet")
                    }
                    Spacer()
                }
            }
//            VStack {
//                Spacer()
//                Button{
//                    path.append(Scanning(scanningType: .qrcode))
//                } label: {
//                    HStack(alignment: .center, spacing: 10) {
//                        Image("QRCodeReader")
//                            .resizable()
//                            .frame(width: CGFloat(18), height: CGFloat(18))
//                            .foregroundColor(.scanButton)
//                        Text("Scan to share")
//                            .font(.customFont(font: .inter, style: .medium, size: .h4))
//                    }
//                    .foregroundStyle(.white)
//                    .padding(.vertical, 13)
//                    .frame(width: UIScreen.screenWidth - 40)
//                    .background(.scanButton)
//                    .cornerRadius(100)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 100)
//                            .stroke(.scanButton, lineWidth: 2)
//                    )
//                    .padding(.bottom, 6)
//                }
//            }
        }
        .onAppear(perform: {
            self.credentials = CredentialDataStore.shared.getAllCredentials()
        })
    }
}

struct WalletHomeViewPreview: PreviewProvider {
    @State static var path: NavigationPath = .init()

    static var previews: some View {
        WalletHomeView(path: $path)
    }
}
