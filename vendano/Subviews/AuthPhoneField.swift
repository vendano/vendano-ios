//
//  AuthPhoneField.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import PhoneNumberKit
import SwiftUI

struct AuthPhoneField: View {
    @EnvironmentObject var theme: VendanoTheme
    @Binding var dialCode: String
    @Binding var localNumber: String
    @State private var rawInput = ""

    private let kit = PhoneNumberUtility()
    private let fmtr = PartialFormatter() // formats live

    // Convert dialCode like "+91" into "IN"
    private func regionCode(from dialCode: String) -> String {
        if let code = kit.mainCountry(forCode: UInt64(dialCode.dropFirst()) ?? 0) {
            return code
        }
        return Locale.current.region?.identifier ?? "US"
    }

    var body: some View {
        TextField("(555) 123-4567", text: $rawInput)
            .vendanoFont(.body, size: 18)
            .keyboardType(.phonePad)
            .onChange(of: rawInput) { _, new in
                let region = regionCode(from: dialCode)

                if let num = try? kit.parse(new, withRegion: region, ignoreType: true) {
                    //Extract nationalNumber directly (no 0 prefix)
                    localNumber = String(num.nationalNumber)

                    //pretty format for user, but without leading 0
                    rawInput = fmtr.formatPartial(localNumber)
                } else {
                    localNumber = new.filter(\.isNumber)
                }
            }
    }
}
