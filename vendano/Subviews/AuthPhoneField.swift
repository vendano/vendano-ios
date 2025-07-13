//
//  AuthPhoneField.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import PhoneNumberKit
import SwiftUI

struct AuthPhoneField: View {
    @Binding var localNumber: String
    @State private var rawInput = ""

    private let kit = PhoneNumberUtility()
    private let fmtr = PartialFormatter() // formats live

    var body: some View {
        TextField("(555) 123-4567", text: $rawInput)
            .keyboardType(.phonePad)
            .onChange(of: rawInput) { _, new in
                rawInput = fmtr.formatPartial(new)
                if let num = try? kit.parse(new, ignoreType: true) {
                    localNumber = kit.format(num, toType: .national)
                }
            }
    }
}
