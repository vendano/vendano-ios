import SwiftUI

enum L10n {
    enum Common {
        static var adaUnit: String { String(localized: "Common.adaUnit") }
        static let back: LocalizedStringKey = "Common.back"
        static let cancel: LocalizedStringKey = "Common.cancel"
        static var cancelString: String { String(localized: "Common.cancel") }
        static let close: LocalizedStringKey = "Common.close"
        static let confirm: LocalizedStringKey = "Common.confirm"
        static let `continue`: LocalizedStringKey = "Common.continue"
        static let delete: LocalizedStringKey = "Common.delete"
        static let done: LocalizedStringKey = "Common.done"
        static let edit: LocalizedStringKey = "Common.edit"
        static let enable: LocalizedStringKey = "Common.enable"
        static var hoskyToken: String { String(localized: "Common.token.hosky") }
        static let next: LocalizedStringKey = "Common.next"
        static var notNow: String { String(localized: "Common.notNow") }
        static let ok: LocalizedStringKey = "Common.ok"
        static let remove: LocalizedStringKey = "Common.remove"
        static let retry: LocalizedStringKey = "Common.retry"
        static let save: LocalizedStringKey = "Common.save"
        static let skip: LocalizedStringKey = "Common.skip"
        static var unnamed: String { String(localized: "Common.unnamed") }
        static var unknownError: String { String(localized: "Common.unknownError") }

        static var on: String { String(localized: "Common.on") }
        static var off: String { String(localized: "Common.off") }
        static var setUp: String { String(localized: "Common.setUp") }
        static var ellipsis: String { String(localized: "Common.ellipsis") }
    }

    enum ActivityView {
        static let noTransactionHistoryFound: LocalizedStringKey = "ActivityView.noTransactionHistoryFound"
        static let recentActivity: LocalizedStringKey = "ActivityView.recentActivity"
    }

    enum AuthPhoneField {
        static let text5551234567: LocalizedStringKey = "AuthPhoneField.text5551234567"
    }

    enum AuthView {
        static let email: LocalizedStringKey = "AuthView.email"
        static let enterYourEmailOrPhoneNumberAndWe: LocalizedStringKey = "AuthView.enterYourEmailOrPhoneNumberAndWe"
        static let ifYouReNewWeLlCreateAn: LocalizedStringKey = "AuthView.ifYouReNewWeLlCreateAn"
        static let loginRegister: LocalizedStringKey = "AuthView.loginRegister"
        static let phone: LocalizedStringKey = "AuthView.phone"
        static let sendCode: LocalizedStringKey = "AuthView.sendCode"
        static let text1: LocalizedStringKey = "AuthView.text1"
        static let youExampleCom: LocalizedStringKey = "AuthView.youExampleCom"

        static func errorSendingEmailLink(_ details: String) -> String {
            String(format: String(localized: "AuthView.errorSendingEmailLink", table: "AuthView"), details)
        }
    }

    enum CardanoRustError {
        static func dataError(_ msg: String) -> String {
            String(format: String(localized: "CardanoRustError.dataError"), msg)
        }

        static func textEncodingError(_ msg: String) -> String {
            String(format: String(localized: "CardanoRustError.textEncodingError"), msg)
        }

        static func internalError(_ reason: String) -> String {
            String(format: String(localized: "CardanoRustError.internalError"), reason)
        }

        static var unexpectedDataLength: String {
            String(localized: "CardanoRustError.unexpectedDataLength")
        }

        static var internalNullPointerError: String {
            String(localized: "CardanoRustError.internalNullPointerError")
        }

        static var unknownError: String {
            String(localized: "CardanoRustError.unknownError")
        }
    }

    enum ConfirmSeedView {
        static let clear: LocalizedStringKey = "ConfirmSeedView.clear"
        static let confirmKeys: LocalizedStringKey = "ConfirmSeedView.confirmKeys"
        static let error: LocalizedStringKey = "ConfirmSeedView.error"
        static let incorrectOrderTryAgain: LocalizedStringKey = "ConfirmSeedView.incorrectOrderTryAgain"
        static let theseWordsAreNeverSentToOurServers: LocalizedStringKey = "ConfirmSeedView.theseWordsAreNeverSentToOurServers"

        static var walletAddressNotFound: String { String(localized: "ConfirmSeedView.walletAddressNotFound") }
        static func walletImportFailedMissingKey(_ key: String) -> String {
            String(format: String(localized: "ConfirmSeedView.walletImportFailedMissingKey"), key)
        }

        static func walletImportFailedMissingValue(_ type: String) -> String { String(format: String(localized: "ConfirmSeedView.walletImportFailedMissingValue"), type) }
        static var walletImportFailedCorruptedData: String { String(localized: "ConfirmSeedView.walletImportFailedCorruptedData") }
        static var walletImportFailedWrongFormat: String { String(localized: "ConfirmSeedView.walletImportFailedWrongFormat") }
        static var walletImportFailedUnknownDecodingError: String { String(localized: "ConfirmSeedView.walletImportFailedUnknownDecodingError") }

        static func tapRecoveryWordsInstruction(_ count: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "ConfirmSeedView.tapRecoveryWordsInstruction",
                    comment: "Instruction to tap N recovery words in order"
                ),
                count
            )
        }
    }

    enum CreateProfileView {
        static let addANameAndPictureSoSendersCan: LocalizedStringKey = "CreateProfileView.addANameAndPictureSoSendersCan"
        static let tellUsAboutYou: LocalizedStringKey = "CreateProfileView.tellUsAboutYou"
        static let yourName: LocalizedStringKey = "CreateProfileView.yourName"
    }

    enum FAQLoader {
        static func missingJSONInBundle(name: String) -> String {
            String(format: String(localized: "FAQLoader.missingJSONInBundle"), name)
        }
    }

    enum FAQSheet {
        static var segmentQuick: String { String(localized: "FAQSheet.segment.quick") }
        static var segmentExplain: String { String(localized: "FAQSheet.segment.explain") }
        static var segmentDeepDive: String { String(localized: "FAQSheet.segment.deepDive") }
    }

    enum FAQView {
        static let titleOnboarding: LocalizedStringKey = "FAQView.titleOnboarding"
        static let titleCommonQuestions: LocalizedStringKey = "FAQView.titleCommonQuestions"
    }

    enum FeedbackSheet {
        static let contactUs: LocalizedStringKey = "FeedbackSheet.contactUs"
        static var emptyPrompt1: String { String(localized: "FeedbackSheet.emptyPrompt.1") }
        static var emptyPrompt2: String { String(localized: "FeedbackSheet.emptyPrompt.2") }
        static var emptyPrompt3: String { String(localized: "FeedbackSheet.emptyPrompt.3") }
        static var emptyPrompt4: String { String(localized: "FeedbackSheet.emptyPrompt.4") }
        static var emptyPrompt5: String { String(localized: "FeedbackSheet.emptyPrompt.5") }
    }

    enum FiatCurrency {
        static var usd: String { String(localized: "FiatCurrency.usd") }
        static var eur: String { String(localized: "FiatCurrency.eur") }
        static var gbp: String { String(localized: "FiatCurrency.gbp") }
        static var jpy: String { String(localized: "FiatCurrency.jpy") }
        static var mxn: String { String(localized: "FiatCurrency.mxn") }
        static var krw: String { String(localized: "FiatCurrency.krw") }
        static var php: String { String(localized: "FiatCurrency.php") }
        static var inr: String { String(localized: "FiatCurrency.inr") }
    }

    enum FirebaseService {
        static var errorNotSignedIn: String {
            String(localized: "FirebaseService.error.notSignedIn")
        }

        static var errorOnlyProvider: String {
            String(localized: "FirebaseService.error.onlyProvider")
        }

        static var errorHandleNotFound: String {
            String(localized: "FirebaseService.error.handleNotFound")
        }
    }

    enum HomeView {
        static let receive: LocalizedStringKey = "HomeView.receive"
        static let removeThisWalletFromThisDevice: LocalizedStringKey = "HomeView.removeThisWalletFromThisDevice"
        static let send: LocalizedStringKey = "HomeView.send"
        static let thisAppWillForgetYourWalletOnThis: LocalizedStringKey = "HomeView.thisAppWillForgetYourWalletOnThis"
        static let totalOnChainInclStakingTokens: LocalizedStringKey = "HomeView.totalOnChainInclStakingTokens"
    }

    enum ImportSeedView {
        static let `import`: LocalizedStringKey = "ImportSeedView.import"
        static let invalidRecoveryPhrase: LocalizedStringKey = "ImportSeedView.invalidRecoveryPhrase"
        static let pasteYour1215Or24WordRecovery: LocalizedStringKey = "ImportSeedView.pasteYour1215Or24WordRecovery"
        static let walletImport: LocalizedStringKey = "ImportSeedView.walletImport"

        static var invalidWordCount: String { String(localized: "ImportSeedView.invalidWordCount") }
        static var recoveryPhraseNotValidAnyLanguage: String { String(localized: "ImportSeedView.recoveryPhraseNotValidAnyLanguage") }
    }

    enum NFTDetailSheet {
        static let makeThisMyAvatar: LocalizedStringKey = "NFTDetailSheet.makeThisMyAvatar"
    }

    enum NewContactAuthView {
        static let pasteSignInLink: LocalizedStringKey = "NewContactAuthView.pasteSignInLink"
        static let sendCode: LocalizedStringKey = "NewContactAuthView.sendCode"
        static let simulatorCanTOpenUniversalLinksPasteIt: LocalizedStringKey = "NewContactAuthView.simulatorCanTOpenUniversalLinksPasteIt"
        static let text1: LocalizedStringKey = "NewContactAuthView.text1"
        static let text5551234567: LocalizedStringKey = "NewContactAuthView.text5551234567"
        static let verify: LocalizedStringKey = "NewContactAuthView.verify"
        static let waitingForConfirmation: LocalizedStringKey = "NewContactAuthView.waitingForConfirmation"
        static let youExampleCom: LocalizedStringKey = "NewContactAuthView.youExampleCom"
        static let verifyYourEmail: LocalizedStringKey = "NewContactAuthView.verifyYourEmail"
        static let enterYourCode: LocalizedStringKey = "NewContactAuthView.enterYourCode"
        static let addEmail: LocalizedStringKey = "NewContactAuthView.addEmail"
        static let addPhone: LocalizedStringKey = "NewContactAuthView.addPhone"

        static let enterEmailToAdd: LocalizedStringKey = "NewContactAuthView.enterEmailToAdd"
        static let enterPhoneToAdd: LocalizedStringKey = "NewContactAuthView.enterPhoneToAdd"

        static let tapLinkWeSentTo: LocalizedStringKey = "NewContactAuthView.tapLinkWeSentTo"
        static let sentSixDigitCodeTo: LocalizedStringKey = "NewContactAuthView.sentSixDigitCodeTo"
    }

    enum NewSeedView {
        static let avoidScreenshots: LocalizedStringKey = "NewSeedView.avoidScreenshots"
        static let iWroteThemDownInASafePlace: LocalizedStringKey = "NewSeedView.iWroteThemDownInASafePlace"
        static let screenshotsMaySyncToIcloudAndExposeYour: LocalizedStringKey = "NewSeedView.screenshotsMaySyncToIcloudAndExposeYour"
        static let words: LocalizedStringKey = "NewSeedView.words"
        static let yourRecoveryPhrase: LocalizedStringKey = "NewSeedView.yourRecoveryPhrase"
        static var wordDescription12: String { String(localized: "NewSeedView.wordDescription12") }
        static var wordDescription15: String { String(localized: "NewSeedView.wordDescription15") }
        static var wordDescription24: String { String(localized: "NewSeedView.wordDescription24") }

        static func wordCountOption(_ count: Int) -> String {
            String(format: String(localized: "NewSeedView.wordCountOption"), count)
        }

        static func writeTheseWordsInstruction(_ count: Int) -> String {
            String(format: String(localized: "NewSeedView.writeTheseWordsInstruction"), count)
        }
    }

    enum OTPView {
        static let pasteSignInLink: LocalizedStringKey = "OTPView.pasteSignInLink"
        static let simulatorCanTOpenUniversalLinksPasteIt: LocalizedStringKey = "OTPView.simulatorCanTOpenUniversalLinksPasteIt"
        static let tapTheSignInLinkWeSentTo: LocalizedStringKey = "OTPView.tapTheSignInLinkWeSentTo"
        static let verify: LocalizedStringKey = "OTPView.verify"
        static let waitingForConfirmation: LocalizedStringKey = "OTPView.waitingForConfirmation"
        static let weSentA6DigitCodeTo: LocalizedStringKey = "OTPView.weSentA6DigitCodeTo"
        static let verifyYourEmail: LocalizedStringKey = "OTPView.verifyYourEmail"
        static let enterYourCode: LocalizedStringKey = "OTPView.enterYourCode"
    }

    enum OfflineBanner {
        static let noInternetConnectionPleaseCheckYourNetworkAnd: LocalizedStringKey = "OfflineBanner.noInternetConnectionPleaseCheckYourNetworkAnd"
    }

    enum OnboardingFAQCardView {
        static let noFaqsAvailable: LocalizedStringKey = "OnboardingFAQCardView.noFaqsAvailable"
        static let orSwipeForMore: LocalizedStringKey = "OnboardingFAQCardView.orSwipeForMore"
        static var tapForClarity: String { String(localized: "OnboardingFAQCardView.tapForClarity") }
        static var tapForDetails: String { String(localized: "OnboardingFAQCardView.tapForDetails") }
        static var tapForSummary: String { String(localized: "OnboardingFAQCardView.tapForSummary") }
    }

    enum ProfileSheet {
        static let addEmail: LocalizedStringKey = "ProfileSheet.addEmail"
        static let addPhone: LocalizedStringKey = "ProfileSheet.addPhone"
        static let advanced: LocalizedStringKey = "ProfileSheet.advanced"
        static let appearance: LocalizedStringKey = "ProfileSheet.appearance"
        static var confirmIdentityBeforeDeleteReason: String { String(localized: "ProfileSheet.confirmIdentityBeforeDeleteReason") }
        static let currency: LocalizedStringKey = "ProfileSheet.currency"
        static let dangerZone: LocalizedStringKey = "ProfileSheet.dangerZone"
        static let deleteAccount: LocalizedStringKey = "ProfileSheet.deleteAccount"
        static let deleteAccountConfirm: LocalizedStringKey = "ProfileSheet.deleteAccountConfirm"
        static let displayName: LocalizedStringKey = "ProfileSheet.displayName"
        static let hoskyfyMyApp: LocalizedStringKey = "ProfileSheet.hoskyfyMyApp"
        static let logins: LocalizedStringKey = "ProfileSheet.logins"
        static let namePhoto: LocalizedStringKey = "ProfileSheet.namePhoto"
        static let showStakingRewardsDetails: LocalizedStringKey = "ProfileSheet.showStakingRewardsDetails"
        static let thisRemovesYourNamePictureAndProfileInfo: LocalizedStringKey = "ProfileSheet.thisRemovesYourNamePictureAndProfileInfo"
        static var enableNotifications: String { String(localized: "ProfileSheet.enableNotifications") }
        static var notificationsOff: String { String(localized: "ProfileSheet.notificationsOff") }
        static let openSettings: LocalizedStringKey = "ProfileSheet.openSettings"
        static var notificationsTitle: String { String(localized: "ProfileSheet.notificationsTitle") }
    }

    enum ReceiveView {
        static let cardanoMainnet: LocalizedStringKey = "ReceiveView.cardanoMainnet"
        static let copy: LocalizedStringKey = "ReceiveView.copy"
        static let keepYourRecoveryPhrase1224WordsWritten: LocalizedStringKey = "ReceiveView.keepYourRecoveryPhrase1224WordsWritten"
        static let newHereAddAdaInThreeEasySteps: LocalizedStringKey = "ReceiveView.newHereAddAdaInThreeEasySteps"
        static let optionalStartWithASmallTestAmountIf: LocalizedStringKey = "ReceiveView.optionalStartWithASmallTestAmountIf"
        static let qrAccessibilityLabel: LocalizedStringKey = "ReceiveView.qrAccessibilityLabel"
        static let receiveAda: LocalizedStringKey = "ReceiveView.receiveAda"
        static let safetyTip: LocalizedStringKey = "ReceiveView.safetyTip"
        static let scanWithAnyCardanoWalletOrExchangeApp: LocalizedStringKey = "ReceiveView.scanWithAnyCardanoWalletOrExchangeApp"
        static let share: LocalizedStringKey = "ReceiveView.share"
        static let stepByStepGuide: LocalizedStringKey = "ReceiveView.stepByStepGuide"
        static let text1CreateAnAccountAtATrustedExchange: LocalizedStringKey = "ReceiveView.text1CreateAnAccountAtATrustedExchange"
        static let text2BuyAdaWithYourBankOrCard: LocalizedStringKey = "ReceiveView.text2BuyAdaWithYourBankOrCard"
        static let text3InTheExchangeChooseSendOrWithdraw: LocalizedStringKey = "ReceiveView.text3InTheExchangeChooseSendOrWithdraw"
        static var walletAddressCopiedToast: String { String(localized: "ReceiveView.walletAddressCopiedToast") }
        static let yourCardanoAddressForAda: LocalizedStringKey = "ReceiveView.yourCardanoAddressForAda"
    }

    enum SendView {
        static let adaSent: LocalizedStringKey = "SendView.adaSent"
        static let addATipForTheDeveloper: LocalizedStringKey = "SendView.addATipForTheDeveloper"
        static let all: LocalizedStringKey = "SendView.all"
        static let allow: LocalizedStringKey = "SendView.allow"
        static let amount: LocalizedStringKey = "SendView.amount"
        static let enableNotifications: LocalizedStringKey = "SendView.enableNotifications"
        static let error: LocalizedStringKey = "SendView.error"
        static let inviteFriend: LocalizedStringKey = "SendView.inviteFriend"
        static let mailServicesAreNotAvailableOnThisDevice: LocalizedStringKey = "SendView.mailServicesAreNotAvailableOnThisDevice"
        static let networkFee: LocalizedStringKey = "SendView.networkFee"
        static let networkFeesCoverBasicBlockchainCostsAnyExtra: LocalizedStringKey = "SendView.networkFeesCoverBasicBlockchainCostsAnyExtra"
        static let pasteACardanoAddressOrHandle: LocalizedStringKey = "SendView.pasteACardanoAddressOrHandle"
        static let sendAda: LocalizedStringKey = "SendView.sendAda"
        static let sendAnyway: LocalizedStringKey = "SendView.sendAnyway"
        static let sendMethodAddress: LocalizedStringKey = "SendView.sendMethodAddress"
        static let sendMethodEmail: LocalizedStringKey = "SendView.sendMethodEmail"
        static let sendMethodPhone: LocalizedStringKey = "SendView.sendMethodPhone"
        static let sendingAda: LocalizedStringKey = "SendView.sendingAda"
        static let smsServicesAreNotAvailableOnThisDevice: LocalizedStringKey = "SendView.smsServicesAreNotAvailableOnThisDevice"
        static let summary: LocalizedStringKey = "SendView.summary"
        static let text: LocalizedStringKey = "SendView.text"
        static let text00: LocalizedStringKey = "SendView.text00"
        static let text000: LocalizedStringKey = "SendView.text000"
        static let text1: LocalizedStringKey = "SendView.text1"
        static let text5551234567: LocalizedStringKey = "SendView.text5551234567"
        static let tip: LocalizedStringKey = "SendView.tip"
        static let tipAmount: LocalizedStringKey = "SendView.tipAmount"
        static let to: LocalizedStringKey = "SendView.to"
        static let total: LocalizedStringKey = "SendView.total"
        static let unknownAddress: LocalizedStringKey = "SendView.unknownAddress"
        static let vendanoFeeWaivedTheCardanoNetworkDoesnT: LocalizedStringKey = "SendView.vendanoFeeWaivedTheCardanoNetworkDoesnT"
        static let vendanoUsesNotificationsToLetYouKnowWhen: LocalizedStringKey = "SendView.vendanoUsesNotificationsToLetYouKnowWhen"
        static let weDonTRecognizeThisAddressInVendano: LocalizedStringKey = "SendView.weDonTRecognizeThisAddressInVendano"
        static let youExampleCom: LocalizedStringKey = "SendView.youExampleCom"
        static let yourAdaHasBeenSuccessfullySentYouLl: LocalizedStringKey = "SendView.yourAdaHasBeenSuccessfullySentYouLl"

        static var userSendingUnknownADAAmount: String {
            String(localized: "SendView.userSendingUnknownADAAmount")
        }

        static func inviteMessage(senderName: String, adaAmount: String) -> String {
            String(
                format: String(localized: "SendView.inviteMessage"),
                senderName, adaAmount
            )
        }

        static var sendFailedTryAgain: String {
            String(localized: "SendView.sendFailedTryAgain")
        }

        static var inviteEmailSubject: String {
            String(localized: "SendView.inviteEmailSubject")
        }

        static var notEnoughAdaForTransaction: String {
            String(localized: "SendView.notEnoughAdaForTransaction")
        }

        static func couldNotEstimateFeeWithMessage(_ message: String) -> String {
            String(format: String(localized: "SendView.couldNotEstimateFeeWithMessage"), message)
        }

        static var couldNotEstimateFeeTryAgain: String { String(localized: "SendView.couldNotEstimateFeeTryAgain")
        }

        static var couldNotCalculateMaxSendable: String { String(localized: "SendView.couldNotCalculateMaxSendable")
        }

        static var enterValidAmount: String { String(localized: "SendView.enterValidAmount")
        }

        static var confirmBeforeSendingReason: String { String(localized: "SendView.confirmBeforeSendingReason")
        }

        static func maxSendableDueToTokens(_ formattedAda: String) -> String { String(format: String(localized: "SendView.maxSendableDueToTokens"), formattedAda)
        }

        static var cardanoRejectedMinAdaWithTokens: String { String(localized: "SendView.cardanoRejectedMinAdaWithTokens")
        }

        static var recipientCardanoAddress: String { String(localized: "SendView.recipientCardanoAddress")
        }

        static func vendanoFeeFormat(_ message: String) -> String {
            String(format: String(localized: "SendView.vendanoFeeFormat"), message)
        }

        static var authPrimerTitle: String { String(localized: "SendView.authPrimerTitle") }
        static func authPrimerMessage(_ message: String) -> String {
            String(format: String(localized: "SendView.authPrimerMessage"), message)
        }

        static var authPasscode: String { String(localized: "SendView.authPasscode") }
        static var authFaceId: String { String(localized: "SendView.authFaceId") }
        static var authTouchId: String { String(localized: "SendView.authTouchId") }
        static var authBiometrics: String { String(localized: "SendView.authBiometrics") }
        static var authFailed: String { String(localized: "SendView.authFailed") }

        static func authLockedFormat(_ message: String) -> String {
            String(format: String(localized: "SendView.authLockedFormat"), message)
        }
    }

    enum SplashView {
        static let easyAdaTransfersByPhoneOrEmail: LocalizedStringKey = "SplashView.easyAdaTransfersByPhoneOrEmail"
        static let getStarted: LocalizedStringKey = "SplashView.getStarted"
    }

    enum WalletChoiceView {
        static let createANewWalletAndWeLlGive: LocalizedStringKey = "WalletChoiceView.createANewWalletAndWeLlGive"
        static let createNewWallet: LocalizedStringKey = "WalletChoiceView.createNewWallet"
        static let importAnExistingWalletByEnteringYour12: LocalizedStringKey = "WalletChoiceView.importAnExistingWalletByEnteringYour12"
        static let importSeedPhrase: LocalizedStringKey = "WalletChoiceView.importSeedPhrase"
        static let letSBegin: LocalizedStringKey = "WalletChoiceView.letSBegin"
        static let toSendOrReceiveAdaYouFirstNeed: LocalizedStringKey = "WalletChoiceView.toSendOrReceiveAdaYouFirstNeed"
    }

    enum WalletService {
        static var walletNotInitialized: String {
            String(localized: "WalletService.walletNotInitialized")
        }

        static var noAccountLoaded: String {
            String(localized: "WalletService.noAccountLoaded")
        }

        static var noPaymentAddressAvailable: String {
            String(localized: "WalletService.noPaymentAddressAvailable")
        }

        static var amountMustBeGreaterThanZero: String {
            String(localized: "WalletService.amountMustBeGreaterThanZero")
        }

        static var tipCannotBeNegative: String {
            String(localized: "WalletService.tipCannotBeNegative")
        }

        static func insufficientFunds(_ haveAda: Double, _ needAda: Double) -> String {
            String(format: String(localized: "WalletService.insufficientFunds"), haveAda, needAda)
        }

        static var walletKeychainNotInitialized: String {
            String(localized: "WalletService.walletKeychainNotInitialized")
        }

        static var noWalletFound: String {
            String(localized: "WalletService.noWalletFound")
        }
    }

    enum HomeEmptyFunding {
        static let title = NSLocalizedString("HomeEmptyFunding.title", comment: "")
        static let subtitle = NSLocalizedString("HomeEmptyFunding.subtitle", comment: "")
        static let tip = NSLocalizedString("HomeEmptyFunding.tip", comment: "")

        static let badgeEasiest = NSLocalizedString("HomeEmptyFunding.badgeEasiest", comment: "")
        static let badgeRecommended = NSLocalizedString("HomeEmptyFunding.badgeRecommended", comment: "")

        static let cardAskFriendTitle = NSLocalizedString("HomeEmptyFunding.cardAskFriendTitle", comment: "")
        static let cardAskFriendSubtitle = NSLocalizedString("HomeEmptyFunding.cardAskFriendSubtitle", comment: "")
        static let cardAskFriendCta = NSLocalizedString("HomeEmptyFunding.cardAskFriendCta", comment: "")

        static let cardTransferTitle = NSLocalizedString("HomeEmptyFunding.cardTransferTitle", comment: "")
        static let cardTransferSubtitle = NSLocalizedString("HomeEmptyFunding.cardTransferSubtitle", comment: "")
        static let cardTransferCta = NSLocalizedString("HomeEmptyFunding.cardTransferCta", comment: "")

        static let cardBuyTitle = NSLocalizedString("HomeEmptyFunding.cardBuyTitle", comment: "")
        static let cardBuySubtitle = NSLocalizedString("HomeEmptyFunding.cardBuySubtitle", comment: "")
        static let cardBuyCta = NSLocalizedString("HomeEmptyFunding.cardBuyCta", comment: "")

        static let addressCopiedCta = NSLocalizedString("HomeEmptyFunding.addressCopiedCta", comment: "")
    }

    enum NotificationPrimerCard {
        static let title = NSLocalizedString("NotificationPrimerCard.title", comment: "")
        static let details = NSLocalizedString("NotificationPrimerCard.details", comment: "")
    }

    enum StoreView {
        static let personalTab = NSLocalizedString("StoreView.personalTab", comment: "")
        static let storeTab = NSLocalizedString("StoreView.storeTab", comment: "")

        static let storeSettings = NSLocalizedString("StoreView.storeSettings", comment: "")
        static let storeName = NSLocalizedString("StoreView.storeName", comment: "")
        static let storeNamePlaceholder = NSLocalizedString("StoreView.storeNamePlaceholder", comment: "")
        static let storeNameNotSet = NSLocalizedString("StoreView.storeNameNotSet", comment: "")
        static let storeNameSetupHint = NSLocalizedString("StoreView.storeNameSetupHint", comment: "")
        static let defaultStoreNameFallback = NSLocalizedString("StoreView.defaultStoreNameFallback", comment: "")

        static let defaultPricingCurrency = NSLocalizedString("StoreView.defaultPricingCurrency", comment: "")
        static let defaultPricingLocalCurrency = NSLocalizedString("StoreView.defaultPricingLocalCurrency", comment: "")
        static let defaultPricingAda = NSLocalizedString("StoreView.defaultPricingAda", comment: "")

        static let exchangeRateBuffer = NSLocalizedString("StoreView.exchangeRateBuffer", comment: "")
        static let exchangeRateBufferHelp = NSLocalizedString("StoreView.exchangeRateBufferHelp", comment: "")
        static let enableTips = NSLocalizedString("StoreView.enableTips", comment: "")

        static func percentValue(_ value: Int) -> String {
            String(format: NSLocalizedString("StoreView.percentValue", comment: ""), value)
        }

        static let acceptPaymentsSubtitle = NSLocalizedString("StoreView.acceptPaymentsSubtitle", comment: "")
        static let amountPlaceholder = NSLocalizedString("StoreView.amountPlaceholder", comment: "")
        static let convertsToAda = NSLocalizedString("StoreView.convertsToAda", comment: "")

        static func rateAndBuffer(_ currencyCode: String, _ rate: Double, _ bufferPercent: Int, _ bufferedFiat: Double) -> String {
            String(format: NSLocalizedString("StoreView.rateAndBuffer", comment: ""), currencyCode, rate, bufferPercent, bufferedFiat)
        }

        static func fetchingRate(_ currencyCode: String) -> String {
            String(format: NSLocalizedString("StoreView.fetchingRate", comment: ""), currencyCode)
        }

        static let refreshRate = NSLocalizedString("StoreView.refreshRate", comment: "")

        static func approxFiat(_ currencyCode: String, _ fiat: Double) -> String {
            String(format: NSLocalizedString("StoreView.approxFiat", comment: ""), currencyCode, fiat)
        }

        static let fiatApproxUnavailable = NSLocalizedString("StoreView.fiatApproxUnavailable", comment: "")

        static let tapToCollect = NSLocalizedString("StoreView.tapToCollect", comment: "")
        static let readyToCollectTitle = NSLocalizedString("StoreView.readyToCollectTitle", comment: "")
        static let readyToCollectSubtitle = NSLocalizedString("StoreView.readyToCollectSubtitle", comment: "")
        static let waitingForCustomer = NSLocalizedString("StoreView.waitingForCustomer", comment: "")

        static func connectedTo(_ names: String) -> String {
            String(format: NSLocalizedString("StoreView.connectedTo", comment: ""), names)
        }

        static func paymentComplete(_ txHash: String) -> String {
            String(format: NSLocalizedString("StoreView.paymentComplete", comment: ""), txHash)
        }

        static let paymentAccepted = NSLocalizedString("StoreView.paymentAccepted", comment: "")
        static let paymentDeclined = NSLocalizedString("StoreView.paymentDeclined", comment: "")

        static func paymentFailed(_ message: String) -> String {
            String(format: NSLocalizedString("StoreView.paymentFailed", comment: ""), message)
        }

        static let paymentExpired = NSLocalizedString("StoreView.paymentExpired", comment: "")
        static let paymentCancelled = NSLocalizedString("StoreView.paymentCancelled", comment: "")

        static let tapToPay = NSLocalizedString("StoreView.tapToPay", comment: "")
        static let tapToPayTitle = NSLocalizedString("StoreView.tapToPayTitle", comment: "")
        static let tapToPaySubtitle = NSLocalizedString("StoreView.tapToPaySubtitle", comment: "")
        static let searchingForMerchant = NSLocalizedString("StoreView.searchingForMerchant", comment: "")

        static func payStoreTitle(_ storeName: String) -> String {
            String(format: NSLocalizedString("StoreView.payStoreTitle", comment: ""), storeName)
        }

        static let addTip = NSLocalizedString("StoreView.addTip", comment: "")
        static let networkFee = NSLocalizedString("StoreView.networkFee", comment: "")
        static let calculating = NSLocalizedString("StoreView.calculating", comment: "")

        static func vendanoFeePaidByStore(_ percentText: String) -> String {
            String(format: NSLocalizedString("StoreView.vendanoFeePaidByStore", comment: ""), percentText)
        }

        static let storeReceives = NSLocalizedString("StoreView.storeReceives", comment: "")
        static let youPayTotal = NSLocalizedString("StoreView.youPayTotal", comment: "")

        static let payNow = NSLocalizedString("StoreView.payNow", comment: "")
        static let paying = NSLocalizedString("StoreView.paying", comment: "")
        static let cancel = NSLocalizedString("StoreView.cancel", comment: "")
    }
}
