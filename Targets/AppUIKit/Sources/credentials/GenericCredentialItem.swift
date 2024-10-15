import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs

struct GenericCredentialItem: View {
    let credentialPack = CredentialPack()
    let rawCredential: String
    let onDelete: (() -> Void)?
    
    @State var sheetOpen: Bool = false
    @State var optionsOpen: Bool = false

    init(rawCredential: String, onDelete: (() -> Void)? = nil) {
        self.rawCredential = rawCredential
        self.onDelete = onDelete
        
        if let _ = try? credentialPack.addJwtVc(jwtVc: JwtVc.newFromCompactJws(jws: rawCredential)) {}
        else if let _ = try? credentialPack.addJsonVc(jsonVc: JsonVc.newFromJson(utf8JsonString: rawCredential)) {}
        else if let _ = try? credentialPack.addMDoc(mdoc: Mdoc.fromStringifiedDocument(stringifiedDocument: rawCredential, keyAlias: UUID().uuidString)) {}
        else {
//            print("Couldn't parse credential: \(rawCredential)")
        }
    }

    @ViewBuilder
    func descriptionFormatter(values: [String: [String: GenericJSON]]) -> some View {
        let credential = values.first(where: {
            let credential = credentialPack.get(credentialId: $0.key)
            return credential?.asJwtVc() != nil || credential?.asJsonVc() != nil
        }).map { $0.value } ?? [:]
        
        var description = ""
        if let issuerName = credential["issuer"]?.dictValue?["name"]?.toString() {
            description = issuerName
        } else if let descriptionString = credential["description"]?.toString() {
            description = descriptionString
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(description)
                .font(.customFont(font: .inter, style: .regular, size: .p))
                .foregroundStyle(Color("TextBody"))
                .padding(.top, 6)
            Spacer()
            if credential["valid"]?.toString() == "true" {
                HStack {
                    Image("Valid")
                    Text("Valid")
                        .font(.customFont(font: .inter, style: .medium, size: .xsmall))
                        .foregroundStyle(Color("GreenValid"))
                }
            }
        }
        .padding(.leading, 12)
    }
    
    @ViewBuilder
    func leadingIconFormatter(values: [String: [String: GenericJSON]]) -> some View {
        let credential = values.first(where: {
            let credential = credentialPack.get(credentialId: $0.key)
            return credential?.asJwtVc() != nil || credential?.asJsonVc() != nil
        }).map { $0.value } ?? [:]
        
        let issuerImg = credential["issuer"]?.dictValue?["image"]
        var stringValue = ""
        
        if let dictValue = issuerImg?.dictValue {
            if let imageValue = dictValue["image"]?.toString() {
                stringValue = imageValue
            } else if let idValue = dictValue["id"]?.toString() {
                stringValue = idValue
            } else {
                stringValue = ""
            }
        } else {
            stringValue = issuerImg?.toString() ?? ""
        }
        
        return CredentialImage(image: stringValue)
    }

    @ViewBuilder
    var cardList: some View {
        Card(
            credentialPack: credentialPack,
            rendering: CardRendering.list(CardRenderingListView(
                titleKeys: ["name"],
                titleFormatter: { (values) in
                    let credential = values.first(where: {
                        let credential = credentialPack.get(credentialId: $0.key)
                        return credential?.asJwtVc() != nil || credential?.asJsonVc() != nil
                    }).map { $0.value } ?? [:]
                    
                    var title = credential["name"]?.toString()
                    if title == nil {
                        credential["type"]?.arrayValue?.forEach {
                            if $0.toString() != "VerifiableCredential" {
                                title = $0.toString().camelCaseToWords()
                                return
                            }
                        }
                    }
                    
                    return VStack(alignment: .leading, spacing: 12) {
                        Text(title ?? "")
                            .font(.customFont(font: .inter, style: .semiBold, size: .h1))
                            .foregroundStyle(Color("TextHeader"))
                    }
                    .padding(.leading, 12)
                },
                descriptionKeys: ["description", "issuer"],
                descriptionFormatter: descriptionFormatter,
                leadingIconKeys: ["issuer"],
                leadingIconFormatter: leadingIconFormatter
            ))
        )
    }
    
    @ViewBuilder
    public var cardListWithOptions: some View {
        Card(
            credentialPack: credentialPack,
            rendering: CardRendering.list(CardRenderingListView(
                titleKeys: ["name", "type"],
                titleFormatter: { (values) in
                    let credential = values.first(where: {
                        let credential = credentialPack.get(credentialId: $0.key)
                        return credential?.asJwtVc() != nil || credential?.asJsonVc() != nil
                    }).map { $0.value } ?? [:]
                    
                    var title = credential["name"]?.toString()
                    if title == nil {
                        credential["type"]?.arrayValue?.forEach {
                            if $0.toString() != "VerifiableCredential" {
                                title = $0.toString().camelCaseToWords()
                                return
                            }
                        }
                    }
                    
                    return VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()
                            Image("ThreeDotsHorizontal")
                                .frame(height: 12)
                                .onTapGesture {
                                    optionsOpen = true
                                }
                        }
                        Text(title ?? "")
                            .font(.customFont(font: .inter, style: .semiBold, size: .h1))
                            .foregroundStyle(Color("TextHeader"))
                    }
                    .padding(.leading, 12)
                },
                descriptionKeys: ["description", "issuer"],
                descriptionFormatter: descriptionFormatter,
                leadingIconKeys: ["issuer"],
                leadingIconFormatter: leadingIconFormatter
            ))
        )
        .confirmationDialog(
            Text("Credential Options"),
            isPresented: $optionsOpen,
            titleVisibility: .visible,
            actions: {
                if(onDelete != nil) {
                    Button("Delete", role: .destructive) { onDelete?() }
                }
                Button("Cancel", role: .cancel) { }
            }
        )

    }

    @ViewBuilder
    var cardDetails: some View {
        Card(
            credentialPack: credentialPack,
            rendering: CardRendering.details(CardRenderingDetailsView(
                fields: [
                    CardRenderingDetailsField(
                        keys: [],
                        formatter: { (values) in
                            let credential = values.first.map { $0.value } ?? [:]
                            return CredentialObjectDisplayer(dict: credential)
                            .padding(.horizontal, 4)
                        })
                ]
            ))
        )
        .padding(.all, 12)
    }

    @ViewBuilder
    public func listComponent(withOptions: Bool = false) -> some View {
        VStack {
            VStack {
                if(withOptions){
                    cardListWithOptions
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                } else {
                    cardList
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("CredentialBorder"), lineWidth: 1)
            )
            .padding(.all, 12)

        }
    }
    
    @ViewBuilder
    public var detailsComponent: some View {
        VStack {
            Text("Review Info")
                .font(.customFont(font: .inter, style: .bold, size: .h0))
                .foregroundStyle(Color("TextHeader"))
                .padding(.top, 25)
            listComponent()
                .frame(height: 120)
            cardDetails
        }
    }

    var body: some View {
        listComponent(withOptions: true)
            .onTapGesture {
                sheetOpen.toggle()
            }
            .sheet(isPresented: $sheetOpen) {

            } content: {
                detailsComponent
                    .presentationDetents([.fraction(0.85)])
                    .presentationDragIndicator(.automatic)
                    .presentationBackgroundInteraction(.automatic)
            }
    }
}
