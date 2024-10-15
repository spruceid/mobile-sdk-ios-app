import SwiftUI
import SpruceIDMobileSdk
import SpruceIDMobileSdkRs

func parseCredential(rawCredential: String) throws -> CredentialPack{
    let credPack = CredentialPack()
    if let _ = try? credPack.addJwtVc(jwtVc: JwtVc.newFromCompactJws(jws: rawCredential)) {}
    else if let _ = try? credPack.addJsonVc(jsonVc: JsonVc.newFromJson(utf8JsonString: rawCredential)) {}
    else if let _ = try? credPack.addMDoc(mdoc: Mdoc.fromStringifiedDocument(stringifiedDocument: rawCredential, keyAlias: UUID().uuidString)) {}
    else {
        throw CredentialError.parsingError("Couldn't parse credential: \(rawCredential)")
    }
    return credPack
}

func credentialHasType(credentialPack: CredentialPack, credentialType: String) -> Bool {
    let credentialTypes = credentialPack.findCredentialClaims(claimNames: ["type"])
    let credentialWithType = credentialTypes.first(where: { credential in
        credential.value["type"]?.arrayValue?.contains(where: { type in
            type.toString().lowercased() == credentialType.lowercased()
        }) ?? false
    })
    return credentialWithType != nil ? true : false
}

func genericObjectDisplayer(object: [String : GenericJSON], filter: [String] = [], level: Int = 1) -> [AnyView] {
    var res: [AnyView] = []
    object
        .filter { !filter.contains($0.key) }
        .sorted(by: { $0.0 < $1.0 })
        .forEach { (key, value) in
            if let dictValue = value.dictValue {
                let tmpViews = genericObjectDisplayer(object: dictValue, filter: filter, level: level+1)
                
                res.append(AnyView(
                    VStack(alignment: .leading) {
                        Text(key.camelCaseToWords().capitalized.replaceUnderscores())
                            .font(.customFont(font: .inter, style: .bold, size: .h4))
                            .foregroundStyle(Color("TextBody"))
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(0..<tmpViews.count, id: \.self) { index in
                                tmpViews[index]
                            }
                        }
                        .padding(.leading, CGFloat(level * 4))
                        .overlay(
                            Rectangle()
                                .frame(width: 1, height: nil, alignment: .leading)
                                .foregroundColor(Color.gray), alignment: .leading)
                    }
                ))
            } else if let arrayValue = value.arrayValue {
                var tmpSections: [AnyView] = []
                for (idx, item) in arrayValue.enumerated() {
                    let tmpViews = genericObjectDisplayer(object: ["\(idx)": item], filter: filter, level: level+1)
                    tmpSections.append(AnyView(
                        VStack(alignment: .leading) {
                            ForEach(0..<tmpViews.count, id: \.self) { index in
                                tmpViews[index]
                            }
                        }
                    ))
                }
                
                res.append(AnyView(
                    VStack(alignment: .leading) {
                        Text(key.camelCaseToWords().capitalized.replaceUnderscores())
                            .font(.customFont(font: .inter, style: .bold, size: .h4))
                            .foregroundStyle(Color("TextBody"))
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(0..<tmpSections.count, id: \.self) { index in
                                tmpSections[index]
                            }
                        }
                        .padding(.leading, CGFloat(level * 4))
                        .overlay(
                            Rectangle()
                                .frame(width: 1, height: nil, alignment: .leading)
                                .foregroundColor(Color.gray), alignment: .leading)
                    }
                ))
                
                
            } else {
                res.append(AnyView(
                    VStack(alignment: .leading) {
                        Text(key.camelCaseToWords().capitalized.replaceUnderscores())
                            .font(.customFont(font: .inter, style: .regular, size: .p))
                            .foregroundStyle(Color("TextBody"))
                        if key.lowercased().contains("image") ||
                            key.lowercased().contains("portrait") ||
                            value.toString().contains("data:image") {
                            CredentialImage(image: value.toString())
                        } else if key.lowercased().contains("date") ||
                                    key.lowercased().contains("from") ||
                                    key.lowercased().contains("until") {
                            CredentialDate(dateString: value.toString())
                        } else if key.lowercased().contains("url") {
                            Link(value.toString(),
                                 destination: URL(string: value.toString())!)
                        } else {
                            Text(value.toString())
                        }
                    }))
            }
        }
    return res
}

func genericObjectFlattener(object: [String : GenericJSON], filter: [String] = []) -> [String:String] {
    var res: [String:String] = [:]
    object
        .filter { !filter.contains($0.key) }
        .forEach { (key, value) in
            if let dictValue = value.dictValue {
                res = genericObjectFlattener(object: dictValue, filter: filter)
                    .reduce(into: [String: String](), { result, x in
                        result["\(key).\(x.key)"] = x.value
                    })
            } else if let arrayValue = value.arrayValue {
                for (idx, item) in arrayValue.enumerated() {
                    genericObjectFlattener(object: ["\(idx)": item], filter: filter)
                        .forEach {
                            res["\(key).\($0.key)"] = $0.value
                        }
                }
            } else {
                res[key] = value.toString()
            }
        }
    return res
}
