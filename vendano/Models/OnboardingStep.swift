//
//  OnboardingStep.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

enum OnboardingStep: Hashable {
    case loading, splash, faq, auth, otp, profile, walletChoice, newSeed, importSeed, confirmSeed, home, send, receive
}
