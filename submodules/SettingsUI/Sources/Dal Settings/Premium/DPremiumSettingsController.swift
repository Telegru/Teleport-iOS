import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

import TPStrings

private final class DPremiumSettingsArguments {
    let context: AccountContext

    let updateShowPremiumInSettings: (Bool) -> Void

    let updateShowStatusIcon: (Bool) -> Void
    let updateShowAnimatedAvatar: (Bool) -> Void
    let updateShowAnimatedReactions: (Bool) -> Void
    let updateShowPremiumStickerAnimation: (Bool) -> Void

    let updateHideStories: (Bool) -> Void
    let updateHideStoriesPublishButton: (Bool) -> Void
    let updateHideViewedStories: (Bool) -> Void

    init(
        context: AccountContext,
        updateShowPremiumInSettings: @escaping (Bool) -> Void,
        updateShowStatusIcon: @escaping (Bool) -> Void,
        updateShowAnimatedAvatar: @escaping (Bool) -> Void,
        updateShowAnimatedReactions: @escaping (Bool) -> Void,
        updateShowPremiumStickerAnimation: @escaping (Bool) -> Void,
        updateHideStories: @escaping (Bool) -> Void,
        updateHideStoriesPublishButton: @escaping (Bool) -> Void,
        updateHideViewedStories: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.updateShowPremiumInSettings = updateShowPremiumInSettings
        self.updateShowStatusIcon = updateShowStatusIcon
        self.updateShowAnimatedAvatar = updateShowAnimatedAvatar
        self.updateShowAnimatedReactions = updateShowAnimatedReactions
        self.updateShowPremiumStickerAnimation = updateShowPremiumStickerAnimation
        self.updateHideStories = updateHideStories
        self.updateHideStoriesPublishButton = updateHideStoriesPublishButton
        self.updateHideViewedStories = updateHideViewedStories
    }
}

private enum DPremiumSettingsSection: Int32, CaseIterable {
    case settings
    case general
    case stories
}

private enum DPremiumSettingsEntryTag: ItemListItemTag {

    case showPremiumItemInSettings

    case showStatusIcon
    case showAnimatedAvatar
    case showAnimatedReactions
    case showPremiumStickerAnimation

    case hideStories
    case hideStoriesPublishButton
    case hideViewedStories

    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DPremiumSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DPremiumSettingsEntry: ItemListNodeEntry {

    case showPremiumInSettingsHeader(PresentationTheme, title: String)
    case showPremiumInSettings(PresentationTheme, title: String, value: Bool)
    case showPremiumInSettingsFooter(PresentationTheme, title: String)

    case generalHeader(PresentationTheme, title: String)
    case showStatusIcon(Bool)
    case showAnimatedAvatar(Bool)
    case showAnimatedReactions(Bool)
    case showPremiumStickerAnimation(Bool)
    case generalFooter(PresentationTheme, title: String)

    case storiesHeader(PresentationTheme, title: String)
    case hideStories(PresentationTheme, title: String, value: Bool)
    case hideStoriesPublishButton(PresentationTheme, title: String, value: Bool)
    case hideViewedStories(PresentationTheme, title: String, value: Bool)

    var section: ItemListSectionId {
        switch self {
        case .showPremiumInSettingsHeader, .showPremiumInSettings, .showPremiumInSettingsFooter:
            return DPremiumSettingsSection.settings.rawValue

        case .generalHeader, .showStatusIcon, .showAnimatedAvatar, .showAnimatedReactions,
            .showPremiumStickerAnimation, .generalFooter:
            return DPremiumSettingsSection.general.rawValue

        case .storiesHeader, .hideStories, .hideStoriesPublishButton, .hideViewedStories:
            return DPremiumSettingsSection.stories.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .showPremiumInSettingsHeader: return 0
        case .showPremiumInSettings: return 1
        case .showPremiumInSettingsFooter: return 2

        case .generalHeader: return 3
        case .showStatusIcon: return 4
        case .showAnimatedAvatar: return 5
        case .showAnimatedReactions: return 6
        case .showPremiumStickerAnimation: return 7
        case .generalFooter: return 8

        case .storiesHeader: return 9
        case .hideStories: return 10
        case .hideStoriesPublishButton: return 11
        case .hideViewedStories: return 12
        }
    }

    var tag: ItemListItemTag? {
        switch self {
        case .showPremiumInSettings:
            return DPremiumSettingsEntryTag.showPremiumItemInSettings

        case .showStatusIcon:
            return DPremiumSettingsEntryTag.showStatusIcon
        case .showAnimatedAvatar:
            return DPremiumSettingsEntryTag.showAnimatedAvatar
        case .showAnimatedReactions:
            return DPremiumSettingsEntryTag.showAnimatedReactions
        case .showPremiumStickerAnimation:
            return DPremiumSettingsEntryTag.showPremiumStickerAnimation

        case .hideStories:
            return DPremiumSettingsEntryTag.hideStories
        case .hideStoriesPublishButton:
            return DPremiumSettingsEntryTag.hideStoriesPublishButton
        case .hideViewedStories:
            return DPremiumSettingsEntryTag.hideViewedStories
        case .showPremiumInSettingsHeader, .showPremiumInSettingsFooter, .generalHeader,
            .generalFooter, .storiesHeader:
            return nil
        }
    }

    static func == (
        lhs: DPremiumSettingsEntry,
        rhs: DPremiumSettingsEntry
    ) -> Bool {
        switch lhs {
        case let .showPremiumInSettingsHeader(lhsTheme, lhsTitle):
            guard case let .showPremiumInSettingsHeader(rhsTheme, rhsTitle) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle

        case let .showPremiumInSettings(lhsTheme, lhsTitle, lhsValue):
            guard case let .showPremiumInSettings(rhsTheme, rhsTitle, rhsValue) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle && lhsValue == rhsValue

        case let .showPremiumInSettingsFooter(lhsTheme, lhsTitle):
            guard case let .showPremiumInSettingsFooter(rhsTheme, rhsTitle) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle

        case let .generalHeader(lhsTheme, lhsTitle):
            guard case let .generalHeader(rhsTheme, rhsTitle) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle

        case let .showStatusIcon(lhsValue):
            guard case let .showStatusIcon(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue

        case let .showAnimatedAvatar(lhsValue):
            guard case let .showAnimatedAvatar(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue

        case let .showAnimatedReactions(lhsValue):
            guard case let .showAnimatedReactions(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue

        case let .showPremiumStickerAnimation(lhsValue):
            guard case let .showPremiumStickerAnimation(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue

        case let .generalFooter(lhsTheme, lhsTitle):
            guard case let .generalFooter(rhsTheme, rhsTitle) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle

        case let .storiesHeader(lhsTheme, lhsTitle):
            guard case let .storiesHeader(rhsTheme, rhsTitle) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle

        case let .hideStories(lhsTheme, lhsTitle, lhsValue):
            guard case let .hideStories(rhsTheme, rhsTitle, rhsValue) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle && lhsValue == rhsValue

        case let .hideStoriesPublishButton(lhsTheme, lhsTitle, lhsValue):
            guard case let .hideStoriesPublishButton(rhsTheme, rhsTitle, rhsValue) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle && lhsValue == rhsValue

        case let .hideViewedStories(lhsTheme, lhsTitle, lhsValue):
            guard case let .hideViewedStories(rhsTheme, rhsTitle, rhsValue) = rhs else {
                return false
            }
            return lhsTheme === rhsTheme && lhsTitle == rhsTitle && lhsValue == rhsValue
        }
    }

    static func < (
        lhs: DPremiumSettingsEntry,
        rhs: DPremiumSettingsEntry
    ) -> Bool {
        lhs.stableId < rhs.stableId
    }

    func item(
        presentationData: ItemListPresentationData,
        arguments: Any
    ) -> ListViewItem {
        let arguments = arguments as! DPremiumSettingsArguments
        let lang = presentationData.strings.baseLanguageCode

        switch self {
        case let .showPremiumInSettingsHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )

        case let .showPremiumInSettings(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowPremiumInSettings(updatedValue)
                },
                tag: self.tag
            )

        case let .showPremiumInSettingsFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )

        case let .generalHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )

        case let .showStatusIcon(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.Status".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowStatusIcon(updatedValue)
                },
                tag: tag
            )

        case let .showAnimatedAvatar(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedAvatars".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowAnimatedAvatar(updatedValue)
                },
                tag: tag
            )

        case let .showAnimatedReactions(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedReactions".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowAnimatedReactions(updatedValue)
                },
                tag: tag
            )

        case let .showPremiumStickerAnimation(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedPremiumStickers".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowPremiumStickerAnimation(updatedValue)
                },
                tag: tag
            )

        case let .generalFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )

        case let .storiesHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )

        case let .hideStories(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideStories(updatedValue)
                },
                tag: self.tag
            )

        case let .hideStoriesPublishButton(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideStoriesPublishButton(updatedValue)
                },
                tag: self.tag
            )

        case let .hideViewedStories(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideViewedStories(updatedValue)
                },
                tag: self.tag
            )
        }
    }
}

private func dPremiumSettingsEntries(
    presentationData: PresentationData,
    showPremiumInSettings: Bool,
    showStatusIcon: Bool,
    showAnimatedAvatar: Bool,
    showAnimatedReactions: Bool,
    showPremiumStickerAnimation: Bool,
    hideStories: Bool,
    hideStoriesPublishButton: Bool,
    hideViewedStories: Bool
) -> [DPremiumSettingsEntry] {
    let lang = presentationData.strings.baseLanguageCode
    var entries = [DPremiumSettingsEntry]()

    entries.append(
        .showPremiumInSettingsHeader(
            presentationData.theme,
            title: "DahlSettings.General.Premium.PremiumInSettings.Header".tp_loc(lang: lang)
                .uppercased()
        )
    )

    entries.append(
        .showPremiumInSettings(
            presentationData.theme,
            title: "DahlSettings.General.Premium.PremiumInSettings".tp_loc(lang: lang),
            value: showPremiumInSettings
        )
    )

    entries.append(
        .showPremiumInSettingsFooter(
            presentationData.theme,
            title: "DahlSettings.General.Premium.PremiumInSettings.Footer".tp_loc(lang: lang)
        )
    )

    entries.append(
        .generalHeader(
            presentationData.theme,
            title: "DahlSettings.General.Premium.General.Header".tp_loc(lang: lang).uppercased()
        )
    )

    entries.append(.showStatusIcon(showStatusIcon))
    entries.append(.showAnimatedAvatar(showAnimatedAvatar))
    entries.append(.showAnimatedReactions(showAnimatedReactions))
    entries.append(.showPremiumStickerAnimation(showPremiumStickerAnimation))

    entries.append(
        .generalFooter(
            presentationData.theme,
            title: "DahlSettings.General.Premium.General.Footer".tp_loc(lang: lang)
        )
    )

    entries.append(
        .storiesHeader(
            presentationData.theme,
            title: "DahlSettings.General.Premium.Stories.Header".tp_loc(lang: lang).uppercased()
        )
    )

    entries.append(
        .hideStories(
            presentationData.theme,
            title: "DahlSettings.General.Premium.Stories.HideStories".tp_loc(lang: lang),
            value: hideStories
        )
    )

    entries.append(
        .hideStoriesPublishButton(
            presentationData.theme,
            title: "DahlSettings.General.Premium.Stories.HideStoriesPublishButton".tp_loc(
                lang: lang),
            value: hideStoriesPublishButton
        )
    )

    entries.append(
        .hideViewedStories(
            presentationData.theme,
            title: "DahlSettings.General.Premium.Stories.HideViewedStories".tp_loc(lang: lang),
            value: hideViewedStories
        )
    )

    return entries
}

public func dPremiumSettingsController(
    context: AccountContext
) -> ViewController {
    let arguments = DPremiumSettingsArguments(
        context: context,
        updateShowPremiumInSettings: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.menuItemsSettings.premium = value
                    return settings
                }
            ).start()
        },
        updateShowStatusIcon: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showStatusIcon = value
                    return settings
                }
            ).start()
        },
        updateShowAnimatedAvatar: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showAnimatedAvatar = value
                    return settings
                }
            ).start()
        },
        updateShowAnimatedReactions: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showAnimatedReactions = value
                    return settings
                }
            ).start()
        },
        updateShowPremiumStickerAnimation: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showPremiumStickerAnimation = value
                    return settings
                }
            ).start()
        },
        updateHideStories: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideStories = value
                    return settings
                }
            ).start()
        },
        updateHideStoriesPublishButton: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hidePublishStoriesButton = value
                    return settings
                }
            ).start()
        },
        updateHideViewedStories: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideViewedStories = value
                    return settings
                }
            ).start()
        }
    )

    let sharedData = context.sharedContext.accountManager.sharedData(keys: [
        ApplicationSpecificSharedDataKeys.dalSettings
    ])

    let signal =
        combineLatest(
            sharedData,
            context.sharedContext.presentationData,
            context.account.postbox.preferencesView(keys: [
                ApplicationSpecificSharedDataKeys.dalSettings
            ])
        )
        |> map {
            sharedData, presentationData, preferences -> (
                ItemListControllerState, (ItemListNodeState, Any)
            ) in
            let settings =
                sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(
                    DalSettings.self) ?? .defaultSettings

            let entries = dPremiumSettingsEntries(
                presentationData: presentationData,
                showPremiumInSettings: settings.menuItemsSettings.premium,
                showStatusIcon: settings.premiumSettings.showStatusIcon,
                showAnimatedAvatar: settings.premiumSettings.showAnimatedAvatar,
                showAnimatedReactions: settings.premiumSettings.showAnimatedReactions,
                showPremiumStickerAnimation: settings.premiumSettings.showPremiumStickerAnimation,
                hideStories: settings.hideStories,
                hideStoriesPublishButton: settings.hidePublishStoriesButton,
                hideViewedStories: settings.hideViewedStories
            )

            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .navigationItemTitle(
                    "DahlSettings.PremiumSettings.Title".tp_loc(
                        lang: presentationData.strings.baseLanguageCode)),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(
                    title: presentationData.strings.Common_Back)
            )

            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: entries,
                style: .blocks
            )

            return (controllerState, (listState, arguments))
        }

    return ItemListController(context: context, state: signal)
}
