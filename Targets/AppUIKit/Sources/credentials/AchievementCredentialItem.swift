import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs

struct AchievementCredentialItem: View, AbstractCredentialItem {
    let credentialPack: CredentialPack
    let onDelete: (() -> Void)?
    
    @State var sheetOpen: Bool = false
    @State var optionsOpen: Bool = false

    init(rawCredential: String, onDelete: (() -> Void)? = nil) {
        self.onDelete = onDelete
        self.credentialPack = CredentialPack()
        if let _ = try? self.credentialPack.addJwtVc(jwtVc: JwtVc.newFromCompactJws(jws: rawCredential)) {}
        else if let _ = try? self.credentialPack.addJsonVc(jsonVc: JsonVc.newFromJson(utf8JsonString: rawCredential)) {}
        else if let _ = try? self.credentialPack.addMDoc(mdoc: Mdoc.fromStringifiedDocument(stringifiedDocument: rawCredential, keyAlias: UUID().uuidString)) {}
        else {
//            print("Couldn't parse credential: \(rawCredential)")
        }
    }
    
    init(credentialPack: CredentialPack, onDelete: (() -> Void)? = nil) {
        self.onDelete = onDelete
        self.credentialPack = credentialPack
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
        }
        .padding(.leading, 12)
    }

    @ViewBuilder
    func cardList() -> some View {
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
                descriptionFormatter: descriptionFormatter
            ))
        )
    }
    
    @ViewBuilder
    public var cardListWithOptions: some View {
        Card(
            credentialPack: credentialPack,
            rendering: CardRendering.list(CardRenderingListView(
                titleKeys: ["issuer"],
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
                descriptionFormatter: descriptionFormatter
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
    public func credentialDetails() -> any View {
        Card(
            credentialPack: credentialPack,
            rendering: CardRendering.details(CardRenderingDetailsView(
                fields: [
                    CardRenderingDetailsField(
                        keys: ["awardedDate", "credentialSubject"],
                        formatter: { (values) in
                            let credential = values.first(where: {
                                let credential = credentialPack.get(credentialId: $0.key)
                                return credential?.asJwtVc() != nil || credential?.asJsonVc() != nil
                            }).map { $0.value } ?? [:]
                            
                            let awardedDate = credential["awardedDate"]?.toString() ?? ""
                            
                            let identity = credential["credentialSubject"]?.dictValue?["identity"]?.arrayValue
                            
                            let details = identity?.map {
                                return (
                                    $0.dictValue?["identityType"]?.toString() ?? "",
                                    $0.dictValue?["identityHash"]?.toString() ?? ""
                                )
                            }
                            
                            return VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 20) {
                                        VStack(alignment: .leading) {
                                            Text("Awarded Date")
                                                .font(.customFont(font: .inter, style: .regular, size: .p))
                                                .foregroundStyle(Color("TextBody"))
                                            CredentialDate(dateString: awardedDate)
                                        }
                                        ForEach(details ?? [], id: \.self.0) { info in
                                            VStack(alignment: .leading) {
                                                Text(info.0.camelCaseToWords().capitalized)
                                                    .font(.customFont(font: .inter, style: .regular, size: .p))
                                                    .foregroundStyle(Color("TextBody"))
                                                Text(info.1)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.vertical, 20)
                        })
                ]
            ))
        )
        .padding(.all, 12)
    }

    @ViewBuilder
    public func listComponent(withOptions: Bool = false) -> any View {
        VStack {
            VStack {
                if(withOptions){
                    cardListWithOptions
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                } else {
                    cardList()
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
    public func detailsComponent() -> any View {
        VStack {
            Text("Review Info")
                .font(.customFont(font: .inter, style: .bold, size: .h0))
                .foregroundStyle(Color("TextHeader"))
                .padding(.top, 25)
            AnyView(listComponent())
                .frame(height: 120)
            AnyView(credentialDetails())
        }
    }

    var body: some View {
        AnyView(listComponent(withOptions: true))
            .onTapGesture {
                sheetOpen.toggle()
            }
            .sheet(isPresented: $sheetOpen) {

            } content: {
                AnyView(detailsComponent())
                    .presentationDetents([.fraction(0.85)])
                    .presentationDragIndicator(.automatic)
                    .presentationBackgroundInteraction(.automatic)
            }
    }
}
