import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs
import CoreImage.CIFilterBuiltins

struct ShareableCredentialListItem: View {
    let credentialPack = CredentialPack()
    let mdoc: String
    let mdocId: String?
    @State var sheetOpen: Bool = false
    
    init(mdoc: String) {
        self.mdoc = mdoc
        do {
            let credentials = try credentialPack.addMDoc(mdocBase64: mdoc, keyPEM: keyPEM)
            self.mdocId = credentials![0].id
        } catch {
            print(error.localizedDescription)
            self.mdocId = nil
        }
    }

    
    var body: some View {
        VStack {
            VStack {
                Text(mdocId!)
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    .onTapGesture {
                        sheetOpen.toggle()
                    }
                ShareableCredentialListItemQRCode(credentials: credentialPack.get(credentialsIds: [mdocId!]))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("CredentialBorder"), lineWidth: 1)
            )
            .padding(.all, 12)
                
        }
        .sheet(isPresented: $sheetOpen) {
            
        } content: {
            VStack {
                Text("Review Info")
                    .font(.customFont(font: .inter, style: .bold, size: .h0))
                    .foregroundStyle(Color("TextHeader"))
                    .padding(.top, 25)
                Text(mdocId!)
            }
            
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.automatic)
            .presentationBackgroundInteraction(.automatic)
            
        }
    }
    
}

struct ShareableCredentialListItemQRCode: View {
    let credentials: [Credential]
    @State private var showingQRCode = false

    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color("Primary"))
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    HStack {
                        Image("QRCode")
                        Text(showingQRCode ? "Hide QR code" : "Show QR code")
                            .font(.customFont(font: .inter, style: .regular, size: .xsmall))
                            .foregroundStyle(Color("TextBody"))
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .onTapGesture {
//                    Task {
//                        do {
//                            vp = try await vcToSignedVp(vc: vc, keyStr: ed25519_2020_10_18)
//                        } catch {
//                            print(error)
//                        }
//
//                    }
                    showingQRCode.toggle()
                }
                if(showingQRCode) {
                    QRSheetView(credentials: credentials)
                    
                    Text("Shares your credential online or \n in-person, wherever accepted.")
                        .font(.customFont(font: .inter, style: .regular, size: .small))
                        .foregroundStyle(Color("TextOnPrimary"))
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}


struct ShareableCredentialListItemPreview: PreviewProvider {
    static var previews: some View {
        ShareableCredentialListItem(mdoc: mdocBase64)
    }
}
