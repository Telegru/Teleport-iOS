import Foundation
import UIKit
import Display
import TelegramCore
import TelegramUIPreferences
import Postbox
import SwiftSignalKit
import DWallpaper

public let defaultDahlServiceBackgroundColor = UIColor(rgb: 0x000000, alpha: 0.2)
public let defaultDahlPresentationTheme = makeDefaultDahlDayPresentationTheme(serviceBackgroundColor: defaultServiceBackgroundColor, day: false, preview: false)
public let defaultDahlDayAccentColor = UIColor(rgb: 0x3D4052)

public func customizeDefaultDahlDayTheme(theme: PresentationTheme, editing: Bool, title: String?, accentColor: UIColor?, outgoingAccentColor: UIColor?, backgroundColors: [UInt32], bubbleColors: [UInt32], animateBubbleColors: Bool?, wallpaper forcedWallpaper: TelegramWallpaper? = nil, serviceBackgroundColor: UIColor?) -> PresentationTheme {
    if (theme.referenceTheme != .day && theme.referenceTheme != .dayClassic) {
        return theme
    }
    
    let day = theme.referenceTheme == .day
    var intro = theme.intro
    var rootController = theme.rootController
    var list = theme.list
    var chatList = theme.chatList
    var chat = theme.chat
    var actionSheet = theme.actionSheet
    
    var outgoingAccent: UIColor?
    var suggestedWallpaper: TelegramWallpaper?
    
    var bubbleColors = bubbleColors  
    if bubbleColors.isEmpty, editing {
        if day {
            let accentColor = accentColor ?? defaultDayAccentColor
            bubbleColors = [accentColor.withMultiplied(hue: 0.966, saturation: 0.61, brightness: 0.98).rgb, accentColor.rgb]
            outgoingAccent = outgoingAccentColor
        } else {
            if let accentColor = accentColor, !accentColor.alpha.isZero {
                let hsb = accentColor.hsb
                bubbleColors = [UIColor(hue: hsb.0, saturation: (hsb.1 > 0.0 && hsb.2 > 0.0) ? 0.14 : 0.0, brightness: 0.79 + hsb.2 * 0.21, alpha: 1.0).rgb]
                if let outgoingAccentColor = outgoingAccentColor {
                    outgoingAccent = outgoingAccentColor
                } else {
                    if accentColor.lightness > 0.705 {
                        outgoingAccent = UIColor(hue: hsb.0, saturation: min(1.0, hsb.1 * 1.1), brightness: min(hsb.2, 0.6), alpha: 1.0)
                    } else {
                        outgoingAccent = accentColor
                    }
                }

                suggestedWallpaper = .gradient(TelegramWallpaper.Gradient(id: nil, colors: defaultBuiltinWallpaperGradientColors.map(\.rgb), settings: WallpaperSettings()))
            } else {
                bubbleColors = [UIColor(rgb: 0xe1ffc7).rgb]
                suggestedWallpaper = .gradient(TelegramWallpaper.Gradient(id: nil, colors: defaultBuiltinWallpaperGradientColors.map(\.rgb), settings: WallpaperSettings()))
                outgoingAccent = outgoingAccentColor
            }
        }
    } else {
        outgoingAccent = outgoingAccentColor
    }
    
    var accentColor = accentColor
    if let initialAccentColor = accentColor, initialAccentColor.lightness > 0.705 {
        let hsb = initialAccentColor.hsb
        accentColor = UIColor(hue: hsb.0, saturation: min(1.0, hsb.1 * 1.1), brightness: min(hsb.2, 0.6), alpha: 1.0)
    }
    
    if let accentColor = accentColor {
        intro = intro.withUpdated(accentTextColor: accentColor)
        rootController = rootController.withUpdated(
            tabBar: rootController.tabBar.withUpdated(selectedIconColor: accentColor, selectedTextColor: accentColor),
            navigationBar: rootController.navigationBar.withUpdated(buttonColor: accentColor, accentTextColor: accentColor),
            navigationSearchBar: rootController.navigationSearchBar.withUpdated(accentColor: accentColor)
        )
        list = list.withUpdated(
            itemAccentColor: accentColor,
            itemDisclosureActions: list.itemDisclosureActions.withUpdated(accent: list.itemDisclosureActions.accent.withUpdated(fillColor: accentColor)),
            itemCheckColors: list.itemCheckColors.withUpdated(fillColor: accentColor),
            itemBarChart: list.itemBarChart.withUpdated(color1: accentColor)
        )
        chatList = chatList.withUpdated(
            checkmarkColor: day ? accentColor : nil,
            unreadBadgeActiveBackgroundColor: accentColor,
            verifiedIconFillColor: day ? accentColor : nil
        )
        actionSheet = actionSheet.withUpdated(
            standardActionTextColor: accentColor,
            controlAccentColor: accentColor
        )
    }
        
    var incomingBubbleStrokeColor: UIColor?
    var outgoingBubbleFillColors: [UIColor]?
    var outgoingBubbleHighlightedFill: UIColor?
    var outgoingBubbleStrokeColor: UIColor?
    var outgoingPrimaryTextColor: UIColor?
    var outgoingSecondaryTextColor: UIColor?
    var outgoingLinkTextColor: UIColor?
    var outgoingScamColor: UIColor?
    var outgoingAccentTextColor: UIColor?
    var outgoingControlColor: UIColor?
    var outgoingInactiveControlColor: UIColor?
    var outgoingPendingActivityColor: UIColor?
    var outgoingFileTitleColor: UIColor?
    var outgoingFileDescriptionColor: UIColor?
    var outgoingFileDurationColor: UIColor?
    var outgoingMediaPlaceholderColor: UIColor?
    var outgoingPollsButtonColor: UIColor?
    var outgoingPollsProgressColor: UIColor?
    var outgoingSelectionColor: UIColor?
    var outgoingSelectionBaseColor: UIColor?
    var outgoingCheckColor: UIColor?
    
    if !day {
        if let outgoingAccent = outgoingAccent {
            outgoingBubbleStrokeColor = outgoingAccent.withAlphaComponent(0.2)
        } else {
            let bubbleStrokeColor = serviceBackgroundColor?.withMultiplied(hue: 0.999, saturation: 1.667, brightness: 1.1).withAlphaComponent(0.2)
            incomingBubbleStrokeColor = bubbleStrokeColor
            outgoingBubbleStrokeColor = bubbleStrokeColor
        }
    }
    
    if !bubbleColors.isEmpty {
        outgoingBubbleFillColors = bubbleColors.map(UIColor.init(rgb:))

        if day {
            outgoingBubbleStrokeColor = .clear
        }
        
        if let outgoingBubbleFillColors {
            let middleBubbleFillColor = outgoingBubbleFillColors[Int(floor(Float(outgoingBubbleFillColors.count - 1) / 2))]
            if middleBubbleFillColor.lightness < 0.85 {
                outgoingBubbleHighlightedFill = middleBubbleFillColor.multipliedWith(middleBubbleFillColor).withMultiplied(hue: 1.0, saturation: 0.6, brightness: 1.0)
            } else if middleBubbleFillColor.lightness > 0.97 {
                outgoingBubbleHighlightedFill = middleBubbleFillColor.withMultiplied(hue: 1.00, saturation: 2.359, brightness: 0.99)
            } else {
                outgoingBubbleHighlightedFill = middleBubbleFillColor.withMultiplied(hue: 1.00, saturation: 1.589, brightness: 0.99)
            }
        }
        
        let lightnessColor = UIColor.average(of: bubbleColors.map(UIColor.init(rgb:)))
        if lightnessColor.lightness > 0.705 {
            let hueFactor: CGFloat = 0.75
            let saturationFactor: CGFloat = 1.1
            outgoingPrimaryTextColor = UIColor(rgb: 0x000000)
            
            if let outgoingAccent = outgoingAccent {
                outgoingSecondaryTextColor = outgoingAccent
                outgoingAccentTextColor = outgoingAccent
                outgoingLinkTextColor = outgoingAccent
                outgoingScamColor = UIColor(rgb: 0xff3b30)
                outgoingControlColor = outgoingAccent
                outgoingInactiveControlColor = outgoingAccent.withMultipliedAlpha(0.5)
                outgoingFileTitleColor = outgoingAccent
                outgoingPollsProgressColor = outgoingControlColor
                outgoingSelectionColor = outgoingAccent.withAlphaComponent(0.2)
                outgoingSelectionBaseColor = outgoingControlColor
                outgoingCheckColor = outgoingAccent
            } else {
                let outgoingBubbleMixedColor = lightnessColor
                outgoingSecondaryTextColor = outgoingBubbleFillColors?.first?.withMultiplied(hue: 1.344 * hueFactor, saturation: 4.554 * saturationFactor, brightness: 0.549).withAlphaComponent(0.8)
                outgoingAccentTextColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.302 * hueFactor, saturation: 4.554 * saturationFactor, brightness: 0.655)
                outgoingLinkTextColor = UIColor(rgb: 0x004bad)
                outgoingScamColor = UIColor(rgb: 0xff3b30)
                outgoingControlColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.283 * hueFactor, saturation: 3.176, brightness: 0.765)
                outgoingInactiveControlColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.207 * hueFactor, saturation: 1.721, brightness: 0.851)
                outgoingFileTitleColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.285 * hueFactor, saturation: 2.946, brightness: 0.667)
                outgoingPollsProgressColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.283 * hueFactor, saturation: 3.176, brightness: 0.765)
                outgoingSelectionColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.013 * hueFactor, saturation: 1.292, brightness: 0.871)
                outgoingSelectionBaseColor = outgoingControlColor
                outgoingCheckColor = outgoingBubbleMixedColor.withMultiplied(hue: 1.344 * hueFactor, saturation: 4.554 * saturationFactor, brightness: 0.549).withAlphaComponent(0.8)
            }
            outgoingPendingActivityColor = outgoingCheckColor
            
            outgoingFileDescriptionColor = outgoingBubbleFillColors?.first?.withMultiplied(hue: 1.257 * hueFactor, saturation: 1.842, brightness: 0.698)
            outgoingFileDurationColor = outgoingBubbleFillColors?.first?.withMultiplied(hue: 1.344 * hueFactor, saturation: 4.554, brightness: 0.549).withAlphaComponent(0.8)
            outgoingMediaPlaceholderColor = outgoingBubbleFillColors?.first?.withMultiplied(hue: 0.998, saturation: 1.129, brightness: 0.949)
            outgoingPollsButtonColor = outgoingBubbleFillColors?.first?.withMultiplied(hue: 1.207 * hueFactor, saturation: 1.721, brightness: 0.851)

            if day {
                if let distance = outgoingBubbleFillColors?.first?.distance(to: UIColor(rgb: 0xffffff)), distance < 200 {
                    outgoingBubbleStrokeColor = UIColor(rgb: 0xc8c7cc)
                }
            }
        } else {
            outgoingPrimaryTextColor = UIColor(rgb: 0xffffff)
            outgoingSecondaryTextColor = UIColor(rgb: 0xffffff, alpha: 0.65)
            outgoingAccentTextColor = outgoingPrimaryTextColor
            outgoingLinkTextColor = UIColor(rgb: 0xffffff)
            outgoingScamColor = outgoingPrimaryTextColor
            outgoingControlColor = outgoingPrimaryTextColor
            outgoingInactiveControlColor = outgoingSecondaryTextColor
            outgoingPendingActivityColor = outgoingSecondaryTextColor
            outgoingFileTitleColor = outgoingPrimaryTextColor
            outgoingFileDescriptionColor = outgoingSecondaryTextColor
            outgoingFileDurationColor = outgoingSecondaryTextColor
            outgoingMediaPlaceholderColor = outgoingBubbleFillColors?.first?.withMultipliedBrightnessBy(0.95)
            outgoingPollsButtonColor = outgoingSecondaryTextColor
            outgoingPollsProgressColor = outgoingPrimaryTextColor
            outgoingSelectionBaseColor = UIColor(rgb: 0xffffff)
            outgoingSelectionColor = outgoingSelectionBaseColor?.withAlphaComponent(0.2)
            outgoingCheckColor = UIColor(rgb: 0xffffff)
        }
    }
    
    var defaultWallpaper: TelegramWallpaper?
    if let forcedWallpaper = forcedWallpaper {
        defaultWallpaper = forcedWallpaper
    } else if !backgroundColors.isEmpty {
        if backgroundColors.count >= 2 {
            defaultWallpaper = .gradient(TelegramWallpaper.Gradient(id: nil, colors: backgroundColors, settings: WallpaperSettings()))
        } else {
            defaultWallpaper = .color(backgroundColors[0])
        }
    } else if let forcedWallpaper = suggestedWallpaper {
        defaultWallpaper = forcedWallpaper
    }
    
    chat = chat.withUpdated(
        defaultWallpaper: defaultWallpaper,
        animateMessageColors: animateBubbleColors,
        message: chat.message.withUpdated(
            incoming: chat.message.incoming.withUpdated(
                bubble: chat.message.incoming.bubble.withUpdated(
                    withWallpaper: chat.message.incoming.bubble.withWallpaper.withUpdated(
                        stroke: incomingBubbleStrokeColor,
                        reactionInactiveBackground: accentColor?.withMultipliedAlpha(0.1),
                        reactionInactiveForeground: accentColor,
                        reactionActiveBackground: accentColor,
                        reactionActiveForeground: .clear,
                        reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                        reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                    ),
                    withoutWallpaper: chat.message.incoming.bubble.withoutWallpaper.withUpdated(
                        stroke: incomingBubbleStrokeColor,
                        reactionInactiveBackground: accentColor?.withMultipliedAlpha(0.1),
                        reactionInactiveForeground: accentColor,
                        reactionActiveBackground: accentColor,
                        reactionActiveForeground: .clear,
                        reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                        reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                    )
                ),
                accentTextColor: accentColor,
                accentControlColor: accentColor,
                accentControlDisabledColor: accentColor?.withAlphaComponent(0.7),
                mediaActiveControlColor: accentColor,
                fileTitleColor: accentColor,
                polls: chat.message.incoming.polls.withUpdated(
                    radioProgress: accentColor,
                    highlight: accentColor?.withAlphaComponent(0.12),
                    bar: accentColor
                ),
                actionButtonsFillColor: serviceBackgroundColor.flatMap { chat.message.incoming.actionButtonsFillColor.withUpdated(withWallpaper: $0) },
                actionButtonsStrokeColor: day ? chat.message.incoming.actionButtonsStrokeColor.withUpdated(withoutWallpaper: accentColor) : nil,
                actionButtonsTextColor: day ? chat.message.incoming.actionButtonsTextColor.withUpdated(withoutWallpaper: accentColor) : nil,
                textSelectionColor: accentColor?.withAlphaComponent(0.2),
                textSelectionKnobColor: accentColor
            ),
            outgoing: chat.message.outgoing.withUpdated(
                bubble: chat.message.outgoing.bubble.withUpdated(
                    withWallpaper: chat.message.outgoing.bubble.withWallpaper.withUpdated(
                        fill: outgoingBubbleFillColors,
                        highlightedFill: outgoingBubbleHighlightedFill,
                        stroke: outgoingBubbleStrokeColor,
                        reactionInactiveBackground: outgoingControlColor?.withMultipliedAlpha(0.1),
                        reactionInactiveForeground: outgoingControlColor,
                        reactionActiveBackground: outgoingControlColor,
                        reactionActiveForeground: .clear,
                        reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                        reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                    ),
                    withoutWallpaper: chat.message.outgoing.bubble.withoutWallpaper.withUpdated(
                        fill: outgoingBubbleFillColors,
                        highlightedFill: outgoingBubbleHighlightedFill,
                        stroke: outgoingBubbleStrokeColor,
                        reactionInactiveBackground: outgoingControlColor?.withMultipliedAlpha(0.1),
                        reactionInactiveForeground: outgoingControlColor,
                        reactionActiveBackground: outgoingControlColor,
                        reactionActiveForeground: .clear,
                        reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                        reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                    )
                ),
                primaryTextColor: outgoingPrimaryTextColor,
                secondaryTextColor: outgoingSecondaryTextColor,
                linkTextColor: outgoingLinkTextColor,
                linkHighlightColor: day ? nil : outgoingLinkTextColor?.withAlphaComponent(0.3),
                scamColor: outgoingScamColor,
                accentTextColor: outgoingAccentTextColor,
                accentControlColor: outgoingControlColor,
                accentControlDisabledColor: outgoingControlColor?.withAlphaComponent(0.7),
                mediaActiveControlColor: outgoingControlColor,
                mediaInactiveControlColor: outgoingInactiveControlColor,
                mediaControlInnerBackgroundColor: .clear,
                pendingActivityColor: outgoingPendingActivityColor,
                fileTitleColor: outgoingFileTitleColor,
                fileDescriptionColor: outgoingFileDescriptionColor,
                fileDurationColor: outgoingFileDurationColor,
                mediaPlaceholderColor: day ? accentColor?.withMultipliedBrightnessBy(0.95) : outgoingMediaPlaceholderColor,
                polls: chat.message.outgoing.polls.withUpdated(radioButton: outgoingPollsButtonColor, radioProgress: outgoingPollsProgressColor, highlight: outgoingPollsProgressColor?.withAlphaComponent(0.12), separator: outgoingPollsButtonColor, bar: outgoingPollsProgressColor, barIconForeground: .clear, barPositive: outgoingPollsProgressColor, barNegative: outgoingPollsProgressColor),
                actionButtonsFillColor: chat.message.outgoing.actionButtonsFillColor.withUpdated(withWallpaper: serviceBackgroundColor),
                actionButtonsStrokeColor: day ? chat.message.outgoing.actionButtonsStrokeColor.withUpdated(withoutWallpaper: accentColor) : nil,
                actionButtonsTextColor: day ? chat.message.outgoing.actionButtonsTextColor.withUpdated(withoutWallpaper: accentColor) : nil,
                textSelectionColor: outgoingSelectionColor,
                textSelectionKnobColor: outgoingSelectionBaseColor),
            outgoingCheckColor: outgoingCheckColor,
            shareButtonFillColor: serviceBackgroundColor.flatMap { chat.message.shareButtonFillColor.withUpdated(withWallpaper: $0) },
            shareButtonForegroundColor: chat.message.shareButtonForegroundColor.withUpdated(withoutWallpaper: day ? accentColor : nil),
            selectionControlColors: chat.message.selectionControlColors.withUpdated(fillColor: accentColor)),
        serviceMessage: serviceBackgroundColor.flatMap {
            chat.serviceMessage.withUpdated(components: chat.serviceMessage.components.withUpdated(withCustomWallpaper: chat.serviceMessage.components.withCustomWallpaper.withUpdated(fill: $0, dateFillStatic: $0, dateFillFloating: $0.withAlphaComponent($0.alpha * 0.6667))))
        },
        inputPanel: chat.inputPanel.withUpdated(
            panelControlAccentColor: accentColor,
            actionControlFillColor: accentColor,
            mediaRecordingControl: chat.inputPanel.mediaRecordingControl.withUpdated(
                buttonColor: accentColor,
                micLevelColor: accentColor?.withAlphaComponent(0.2)
            )
        ),
        historyNavigation: chat.historyNavigation.withUpdated(
            badgeBackgroundColor: accentColor,
            badgeStrokeColor: accentColor
        )
    )
    
    return PresentationTheme(
        name: title.flatMap { .custom($0) } ?? theme.name,
        index: theme.index,
        referenceTheme: theme.referenceTheme,
        overallDarkAppearance: theme.overallDarkAppearance,
        intro: intro,
        passcode: theme.passcode,
        rootController: rootController,
        list: list,
        chatList: chatList,
        chat: chat,
        actionSheet: actionSheet,
        contextMenu: theme.contextMenu,
        inAppNotification: theme.inAppNotification,
        chart: theme.chart,
        preview: theme.preview
    )
}

public func makeDefaultDahlDayPresentationTheme(extendingThemeReference: PresentationThemeReference? = nil, serviceBackgroundColor: UIColor?, day: Bool, preview: Bool) -> PresentationTheme {
    var serviceBackgroundColor = serviceBackgroundColor ?? defaultServiceBackgroundColor

    if !day {
        serviceBackgroundColor = UIColor(white: 0.0, alpha: 0.2)
    }
    
    let intro = PresentationThemeIntro(
        statusBarStyle: .black,
        primaryTextColor: UIColor(rgb: 0x000000),
        accentTextColor: defaultDayAccentColor,
        disabledTextColor: UIColor(rgb: 0xd0d0d0),
        startButtonColor: UIColor(rgb: 0x2ca5e0),
        dotColor: UIColor(rgb: 0xd9d9d9)
    )
    
    let passcode = PresentationThemePasscode(
        backgroundColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0x46739e), bottomColor: UIColor(rgb: 0x2a5982)),
        buttonColor: .clear
    )
    
    let rootNavigationBar = PresentationThemeRootNavigationBar(
        buttonColor: defaultDayAccentColor,
        disabledButtonColor: UIColor(rgb: 0xd0d0d0),
        primaryTextColor: UIColor(rgb: 0x000000),
        secondaryTextColor: UIColor(rgb: 0x787878),
        controlColor: UIColor(rgb: 0x7e8791),
        accentTextColor: defaultDayAccentColor,
        blurredBackgroundColor: UIColor(rgb: 0xf2f2f2, alpha: 0.9),
        opaqueBackgroundColor: UIColor(rgb: 0xf7f7f7).mixedWith(.white, alpha: 0.14),
        separatorColor: UIColor(rgb: 0xc8c7cc),
        badgeBackgroundColor: UIColor(rgb: 0xff3b30),
        badgeStrokeColor: UIColor(rgb: 0xff3b30),
        badgeTextColor: UIColor(rgb: 0xffffff),
        segmentedBackgroundColor: UIColor(rgb: 0x000000, alpha: 0.06),
        segmentedForegroundColor: UIColor(rgb: 0xf7f7f7),
        segmentedTextColor: UIColor(rgb: 0x000000),
        segmentedDividerColor: UIColor(rgb: 0xd6d6dc),
        clearButtonBackgroundColor: UIColor(rgb: 0xE3E3E3, alpha: 0.78),
        clearButtonForegroundColor: UIColor(rgb: 0x7f7f7f)
    )

    let rootTabBar = PresentationThemeRootTabBar(
        backgroundColor: rootNavigationBar.blurredBackgroundColor,
        separatorColor: UIColor(rgb: 0xb2b2b2),
        iconColor: UIColor(rgb: 0x959595),
        selectedIconColor: defaultDayAccentColor,
        textColor: UIColor(rgb: 0x959595),
        selectedTextColor: defaultDayAccentColor,
        badgeBackgroundColor: UIColor(rgb: 0xff3b30),
        badgeStrokeColor: UIColor(rgb: 0xff3b30),
        badgeTextColor: UIColor(rgb: 0xffffff),
        useSquareStyle: true
    )
    
    let navigationSearchBar = PresentationThemeNavigationSearchBar(
        backgroundColor: UIColor(rgb: 0xffffff),
        accentColor: defaultDayAccentColor,
        inputFillColor: UIColor(rgb: 0x000000, alpha: 0.06),
        inputTextColor: UIColor(rgb: 0x000000),
        inputPlaceholderTextColor: UIColor(rgb: 0x8e8e93),
        inputIconColor: UIColor(rgb: 0x8e8e93),
        inputClearButtonColor: UIColor(rgb: 0x7b7b81),
        separatorColor: UIColor(rgb: 0xc8c7cc)
    )
        
    let rootController = PresentationThemeRootController(
        statusBarStyle: .black,
        tabBar: rootTabBar,
        navigationBar: rootNavigationBar,
        navigationSearchBar: navigationSearchBar,
        keyboardColor: .light
    )
    
    let switchColors = PresentationThemeSwitch(
        frameColor: UIColor(rgb: 0xe9e9ea),
        handleColor: UIColor(rgb: 0xffffff),
        contentColor: UIColor(rgb: 0x35c759),
        positiveColor: UIColor(rgb: 0x00c900),
        negativeColor: UIColor(rgb: 0xff3b30)
    )
    
    let list = PresentationThemeList(
        blocksBackgroundColor: UIColor(rgb: 0xefeff4),
        modalBlocksBackgroundColor: UIColor(rgb: 0xefeff4),
        plainBackgroundColor: UIColor(rgb: 0xffffff),
        modalPlainBackgroundColor: UIColor(rgb: 0xffffff),
        itemPrimaryTextColor: UIColor(rgb: 0x000000),
        itemSecondaryTextColor: UIColor(rgb: 0x8e8e93),
        itemDisabledTextColor: UIColor(rgb: 0x8e8e93),
        itemAccentColor: defaultDayAccentColor,
        itemHighlightedColor: UIColor(rgb: 0x00b12c),
        itemDestructiveColor: UIColor(rgb: 0xff3b30),
        itemPlaceholderTextColor: UIColor(rgb: 0xc8c8ce),
        itemBlocksBackgroundColor: UIColor(rgb: 0xffffff),
        itemModalBlocksBackgroundColor: UIColor(rgb: 0xffffff),
        itemHighlightedBackgroundColor: UIColor(rgb: 0xe5e5ea),
        itemBlocksSeparatorColor: UIColor(rgb: 0xc8c7cc),
        itemPlainSeparatorColor: UIColor(rgb: 0xc8c7cc),
        disclosureArrowColor: UIColor(rgb: 0xbab9be),
        sectionHeaderTextColor: UIColor(rgb: 0x6d6d72),
        freeTextColor: UIColor(rgb: 0x6d6d72),
        freeTextErrorColor: UIColor(rgb: 0xcf3030),
        freeTextSuccessColor: UIColor(rgb: 0x26972c),
        freeMonoIconColor: UIColor(rgb: 0x7e7e87),
        itemSwitchColors: switchColors,
        itemDisclosureActions: PresentationThemeItemDisclosureActions(
            neutral1: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0x4892f2), foregroundColor: UIColor(rgb: 0xffffff)),
            neutral2: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xf09a37), foregroundColor: UIColor(rgb: 0xffffff)),
            destructive: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xff3824), foregroundColor: UIColor(rgb: 0xffffff)),
            constructive: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0x00c900), foregroundColor: UIColor(rgb: 0xffffff)),
            accent: PresentationThemeFillForeground(fillColor: defaultDayAccentColor, foregroundColor: UIColor(rgb: 0xffffff)),
            warning: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xff9500), foregroundColor: UIColor(rgb: 0xffffff)),
            inactive: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xbcbcc3), foregroundColor: UIColor(rgb: 0xffffff))
        ),
        itemCheckColors: PresentationThemeFillStrokeForeground(
            fillColor: defaultDayAccentColor,
            strokeColor: UIColor(rgb: 0xc7c7cc),
            foregroundColor: UIColor(rgb: 0xffffff)
        ),
        controlSecondaryColor: UIColor(rgb: 0xdedede),
        freeInputField: PresentationInputFieldTheme(
            backgroundColor: UIColor(rgb: 0xd6d6dc),
            strokeColor: UIColor(rgb: 0xd6d6dc),
            placeholderColor: UIColor(rgb: 0x96979d),
            primaryColor: UIColor(rgb: 0x000000),
            controlColor: UIColor(rgb: 0x96979d)
        ),
        freePlainInputField: PresentationInputFieldTheme(
            backgroundColor: UIColor(rgb: 0xe9e9e9),
            strokeColor: UIColor(rgb: 0xe9e9e9),
            placeholderColor: UIColor(rgb: 0x8e8d92),
            primaryColor: UIColor(rgb: 0x000000),
            controlColor: UIColor(rgb: 0xbcbcc0)
        ),
        mediaPlaceholderColor: UIColor(rgb: 0xEFEFF4),
        scrollIndicatorColor: UIColor(white: 0.0, alpha: 0.3),
        pageIndicatorInactiveColor: UIColor(rgb: 0xe3e3e7),
        inputClearButtonColor: UIColor(rgb: 0xcccccc),
        itemBarChart: PresentationThemeItemBarChart(color1: defaultDayAccentColor, color2: UIColor(rgb: 0xc8c7cc), color3: UIColor(rgb: 0xf2f1f7)),
        itemInputField: PresentationInputFieldTheme(backgroundColor: UIColor(rgb: 0xf2f2f7), strokeColor: UIColor(rgb: 0xf2f2f7), placeholderColor: UIColor(rgb: 0xb6b6bb), primaryColor: UIColor(rgb: 0x000000), controlColor: UIColor(rgb: 0xb6b6bb)),
        paymentOption: PresentationThemeList.PaymentOption(
            inactiveFillColor: UIColor(rgb: 0x00A650).withMultipliedAlpha(0.1),
            inactiveForegroundColor: UIColor(rgb: 0x00A650),
            activeFillColor: UIColor(rgb: 0x00A650),
            activeForegroundColor: UIColor(rgb: 0xffffff)
        )
    )
    
    let chatList = PresentationThemeChatList(
        backgroundColor: UIColor(rgb: 0xffffff),
        itemSeparatorColor: UIColor(rgb: 0xc8c7cc),
        itemBackgroundColor: UIColor(rgb: 0xffffff),
        pinnedItemBackgroundColor: UIColor(rgb: 0x3C3C43, alpha: 0.12),
        itemHighlightedBackgroundColor: UIColor(rgb: 0xe5e5ea),
        pinnedItemHighlightedBackgroundColor: UIColor(rgb: 0xe5e5ea),
        itemSelectedBackgroundColor: UIColor(rgb: 0xe9f0fa),
        titleColor: UIColor(rgb: 0x000000),
        secretTitleColor: UIColor(rgb: 0x00b12c),
        dateTextColor: UIColor(rgb: 0x8e8e93),
        authorNameColor: UIColor(rgb: 0x000000),
        messageTextColor: UIColor(rgb: 0x8e8e93),
        messageHighlightedTextColor: UIColor(rgb: 0x000000),
        messageDraftTextColor: UIColor(rgb: 0xdd4b39),
        checkmarkColor: day ? defaultDayAccentColor : UIColor(rgb: 0x21c004),
        pendingIndicatorColor: UIColor(rgb: 0x8e8e93),
        failedFillColor: UIColor(rgb: 0xff3b30),
        failedForegroundColor: UIColor(rgb: 0xffffff),
        muteIconColor: UIColor(rgb: 0xa7a7ad),
        unreadBadgeActiveBackgroundColor: defaultDayAccentColor,
        unreadBadgeActiveTextColor: UIColor(rgb: 0xffffff),
        unreadBadgeInactiveBackgroundColor: UIColor(rgb: 0x787880, alpha: 0.20), // UIColor(rgb: 0xb6b6bb)
        unreadBadgeInactiveTextColor: defaultDayAccentColor, // UIColor(rgb: 0xffffff),
        reactionBadgeActiveBackgroundColor: UIColor(rgb: 0xFF2D55),
        pinnedBadgeColor: defaultDayAccentColor, // UIColor(rgb: 0xb6b6bb),
        pinnedSearchBarColor: UIColor(rgb: 0xe5e5e5),
        regularSearchBarColor: UIColor(rgb: 0xe9e9e9),
        sectionHeaderFillColor: UIColor(rgb: 0xf7f7f7),
        sectionHeaderTextColor: UIColor(rgb: 0x8e8e93),
        verifiedIconFillColor: defaultDayAccentColor,
        verifiedIconForegroundColor: UIColor(rgb: 0xffffff),
        secretIconColor: UIColor(rgb: 0x00b12c),
        pinnedArchiveAvatarColor: PresentationThemeArchiveAvatarColors(backgroundColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0x3D4052), bottomColor: UIColor(rgb: 0x09090C)), foregroundColor: UIColor(rgb: 0xffffff)),
        unpinnedArchiveAvatarColor: PresentationThemeArchiveAvatarColors(backgroundColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0xdedee5), bottomColor: UIColor(rgb: 0xc5c6cc)), foregroundColor: UIColor(rgb: 0xffffff)),
        onlineDotColor: UIColor(rgb: 0x4cc91f),
        storyUnseenColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0x4B75F2), bottomColor: UIColor(rgb: 0x282A36)), // PresentationThemeGradientColors(topColor: UIColor(rgb: 0x34C76F), bottomColor: UIColor(rgb: 0x3DA1FD)),
        storyUnseenPrivateColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0x7CD636), bottomColor: UIColor(rgb: 0x26B470)),
        storySeenColors: PresentationThemeGradientColors(topColor: UIColor(rgb: 0xD8D8E1), bottomColor: UIColor(rgb: 0xD8D8E1))
    )
    
    let bubbleStrokeColor: UIColor
    if day {
        bubbleStrokeColor = serviceBackgroundColor.withMultiplied(hue: 0.999, saturation: 1.667, brightness: 1.1).withAlphaComponent(0.2)
    } else {
        bubbleStrokeColor = UIColor(white: 0.0, alpha: 0.2)
    }

    let message = PresentationThemeChatMessage(
        incoming: PresentationThemePartedColors(
            bubble: PresentationThemeBubbleColor(
                withWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xffffff)],
                    highlightedFill: UIColor(rgb: 0xd9f4ff),
                    stroke: bubbleStrokeColor,
                    shadow: nil,
                    reactionInactiveBackground: defaultDayAccentColor.withMultipliedAlpha(0.1),
                    reactionInactiveForeground: defaultDayAccentColor,
                    reactionActiveBackground: defaultDayAccentColor,
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                ),
                withoutWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xffffff)],
                    highlightedFill: UIColor(rgb: 0xd9f4ff),
                    stroke: bubbleStrokeColor,
                    shadow: nil,
                    reactionInactiveBackground: defaultDayAccentColor.withMultipliedAlpha(0.1),
                    reactionInactiveForeground: defaultDayAccentColor,
                    reactionActiveBackground: defaultDayAccentColor,
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                )
            ),
            primaryTextColor: UIColor(rgb: 0x000000),
            secondaryTextColor: UIColor(rgb: 0x525252, alpha: 0.6),
            linkTextColor: UIColor(rgb: 0x004bad),
            linkHighlightColor: defaultDayAccentColor.withAlphaComponent(0.3),
            scamColor: UIColor(rgb: 0xff3b30),
            textHighlightColor: UIColor(rgb: 0xffe438),
            accentTextColor: defaultDayAccentColor,
            accentControlColor: defaultDayAccentColor,
            accentControlDisabledColor: UIColor(rgb: 0x525252, alpha: 0.6),
            mediaActiveControlColor: defaultDayAccentColor,
            mediaInactiveControlColor: UIColor(rgb: 0xcacaca),
            mediaControlInnerBackgroundColor: UIColor(rgb: 0xffffff),
            pendingActivityColor: UIColor(rgb: 0x525252, alpha: 0.6),
            fileTitleColor: UIColor(rgb: 0x0b8bed),
            fileDescriptionColor: UIColor(rgb: 0x999999),
            fileDurationColor: UIColor(rgb: 0x525252, alpha: 0.6),
            mediaPlaceholderColor: UIColor(rgb: 0xe8ecf0),
            polls: PresentationThemeChatBubblePolls(radioButton: UIColor(rgb: 0xc8c7cc), radioProgress: defaultDayAccentColor, highlight: defaultDayAccentColor.withAlphaComponent(0.08), separator: UIColor(rgb: 0xc8c7cc), bar: defaultDayAccentColor, barIconForeground: .white, barPositive: UIColor(rgb: 0x2dba45), barNegative: UIColor(rgb: 0xFE3824)),
            actionButtonsFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0x596e89, alpha: 0.35)), actionButtonsStrokeColor: PresentationThemeVariableColor(color: .clear),
            actionButtonsTextColor: PresentationThemeVariableColor(color: UIColor(rgb: 0xffffff)), textSelectionColor: defaultDayAccentColor.withAlphaComponent(0.2), textSelectionKnobColor: defaultDayAccentColor),
        outgoing: PresentationThemePartedColors(
            bubble: PresentationThemeBubbleColor(
                withWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xe1ffc7)],
                    highlightedFill: UIColor(rgb: 0xbaff93),
                    stroke: bubbleStrokeColor,
                    shadow: nil,
                    reactionInactiveBackground: UIColor(rgb: 0x3fc33b).withMultipliedAlpha(0.12),
                    reactionInactiveForeground: UIColor(rgb: 0x3fc33b),
                    reactionActiveBackground: UIColor(rgb: 0x3fc33b),
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                ),
                withoutWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xe1ffc7)],
                    highlightedFill: UIColor(rgb: 0xbaff93),
                    stroke: bubbleStrokeColor,
                    shadow: nil,
                    reactionInactiveBackground: UIColor(rgb: 0x3fc33b).withMultipliedAlpha(0.12),
                    reactionInactiveForeground: UIColor(rgb: 0x3fc33b),
                    reactionActiveBackground: UIColor(rgb: 0x3fc33b),
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                )
            ),
            primaryTextColor: UIColor(rgb: 0x000000),
            secondaryTextColor: UIColor(rgb: 0x008c09, alpha: 0.8),
            linkTextColor: UIColor(rgb: 0x004bad),
            linkHighlightColor: defaultDayAccentColor.withAlphaComponent(0.3),
            scamColor: UIColor(rgb: 0xff3b30),
            textHighlightColor: UIColor(rgb: 0xffe438),
            accentTextColor: UIColor(rgb: 0x00a700),
            accentControlColor: UIColor(rgb: 0x3fc33b),
            accentControlDisabledColor: UIColor(rgb: 0x3fc33b).withAlphaComponent(0.7),
            mediaActiveControlColor: UIColor(rgb: 0x3fc33b),
            mediaInactiveControlColor: UIColor(rgb: 0x93d987),
            mediaControlInnerBackgroundColor: UIColor(rgb: 0xe1ffc7),
            pendingActivityColor: UIColor(rgb: 0x42b649),
            fileTitleColor: UIColor(rgb: 0x3faa3c),
            fileDescriptionColor: UIColor(rgb: 0x6fb26a),
            fileDurationColor: UIColor(rgb: 0x008c09, alpha: 0.8),
            mediaPlaceholderColor: UIColor(rgb: 0xd2f2b6),
            polls: PresentationThemeChatBubblePolls(radioButton: UIColor(rgb: 0x93d987), radioProgress: UIColor(rgb: 0x3fc33b), highlight: UIColor(rgb: 0x3fc33b).withAlphaComponent(0.08), separator: UIColor(rgb: 0x93d987), bar: UIColor(rgb: 0x00A700), barIconForeground: .white, barPositive: UIColor(rgb: 0x00A700), barNegative: UIColor(rgb: 0x00A700)),
            actionButtonsFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0x596e89, alpha: 0.35)),
            actionButtonsStrokeColor: PresentationThemeVariableColor(color: .clear),
            actionButtonsTextColor: PresentationThemeVariableColor(color: UIColor(rgb: 0xffffff)),
            textSelectionColor: UIColor(rgb: 0xbbde9f),
            textSelectionKnobColor: UIColor(rgb: 0x3fc33b)),
        freeform: PresentationThemeBubbleColor(
            withWallpaper: PresentationThemeBubbleColorComponents(
                fill: [UIColor(rgb: 0xffffff)],
                highlightedFill: UIColor(rgb: 0xd9f4ff),
                stroke: UIColor(rgb: 0x86a9c9, alpha: 0.5),
                shadow: nil,
                reactionInactiveBackground: UIColor(rgb: 0xffffff),
                reactionInactiveForeground: UIColor(rgb: 0xffffff),
                reactionActiveBackground: UIColor(rgb: 0xffffff, alpha: 0.8),
                reactionActiveForeground: UIColor(white: 0.0, alpha: 0.1),
                reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                reactionStarsActiveForeground: .white,
                reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
            ),
            withoutWallpaper: PresentationThemeBubbleColorComponents(
                fill: [UIColor(rgb: 0xffffff)],
                highlightedFill: UIColor(rgb: 0xd9f4ff),
                stroke: UIColor(rgb: 0x86a9c9, alpha: 0.5),
                shadow: nil,
                reactionInactiveBackground: UIColor(rgb: 0xffffff),
                reactionInactiveForeground: UIColor(rgb: 0xffffff),
                reactionActiveBackground: UIColor(rgb: 0xffffff, alpha: 0.8),
                reactionActiveForeground: UIColor(white: 0.0, alpha: 0.1),
                reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                reactionStarsActiveForeground: .white,
                reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
            )
        ),
        infoPrimaryTextColor: UIColor(rgb: 0x000000),
        infoLinkTextColor: UIColor(rgb: 0x004bad),
        outgoingCheckColor: UIColor(rgb: 0x19c700),
        mediaDateAndStatusFillColor: UIColor(white: 0.0, alpha: 0.3),
        mediaDateAndStatusTextColor: UIColor(rgb: 0xffffff),
        shareButtonFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0x748391, alpha: 0.45)),
        shareButtonStrokeColor: PresentationThemeVariableColor(withWallpaper: .clear, withoutWallpaper: .clear),
        shareButtonForegroundColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff), withoutWallpaper: UIColor(rgb: 0xffffff)),
        mediaOverlayControlColors: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0x000000, alpha: 0.45), foregroundColor: UIColor(rgb: 0xffffff)),
        selectionControlColors: PresentationThemeFillStrokeForeground(fillColor: defaultDayAccentColor, strokeColor: UIColor(rgb: 0xc7c7cc), foregroundColor: UIColor(rgb: 0xffffff)),
        deliveryFailedColors: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xff3b30), foregroundColor: UIColor(rgb: 0xffffff)),
        mediaHighlightOverlayColor: UIColor(white: 1.0, alpha: 0.6),
        stickerPlaceholderColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0x748391, alpha: 0.25)),
        stickerPlaceholderShimmerColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff, alpha: 0.2), withoutWallpaper: UIColor(rgb: 0x000000, alpha: 0.1))
    )
    
    let messageDay = PresentationThemeChatMessage(
        incoming: PresentationThemePartedColors(
            bubble: PresentationThemeBubbleColor(
                withWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xffffff)],
                    highlightedFill: UIColor(rgb: 0xdadade),
                    stroke: UIColor(rgb: 0xffffff),
                    shadow: nil,
                    reactionInactiveBackground: defaultDayAccentColor.withMultipliedAlpha(0.1),
                    reactionInactiveForeground: defaultDayAccentColor,
                    reactionActiveBackground: defaultDayAccentColor,
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                ),
                withoutWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0xf1f1f4)],
                    highlightedFill: UIColor(rgb: 0xdadade),
                    stroke: UIColor(rgb: 0xf1f1f4),
                    shadow: nil,
                    reactionInactiveBackground: .clear,
                    reactionInactiveForeground: defaultDayAccentColor,
                    reactionActiveBackground: defaultDayAccentColor,
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                )
            ),
            primaryTextColor: UIColor(rgb: 0x000000),
            secondaryTextColor: UIColor(rgb: 0x525252, alpha: 0.6),
            linkTextColor: UIColor(rgb: 0x004bad),
            linkHighlightColor: defaultDayAccentColor.withAlphaComponent(0.3),
            scamColor: UIColor(rgb: 0xff3b30),
            textHighlightColor: UIColor(rgb: 0xffc738),
            accentTextColor: defaultDayAccentColor,
            accentControlColor: defaultDayAccentColor,
            accentControlDisabledColor: UIColor(rgb: 0x525252, alpha: 0.6),
            mediaActiveControlColor: defaultDayAccentColor,
            mediaInactiveControlColor: UIColor(rgb: 0xcacaca),
            mediaControlInnerBackgroundColor: UIColor(rgb: 0xffffff),
            pendingActivityColor: UIColor(rgb: 0x525252, alpha: 0.6),
            fileTitleColor: defaultDayAccentColor,
            fileDescriptionColor: UIColor(rgb: 0x999999),
            fileDurationColor: UIColor(rgb: 0x525252, alpha: 0.6),
            mediaPlaceholderColor: UIColor(rgb: 0xffffff).withMultipliedBrightnessBy(0.95),
            polls: PresentationThemeChatBubblePolls(radioButton: UIColor(rgb: 0xc8c7cc), radioProgress: defaultDayAccentColor, highlight: defaultDayAccentColor.withAlphaComponent(0.12), separator: UIColor(rgb: 0xc8c7cc), bar: defaultDayAccentColor, barIconForeground: .white, barPositive: UIColor(rgb: 0x00A700), barNegative: UIColor(rgb: 0xFE3824)),
            actionButtonsFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0xffffff, alpha: 0.8)),
            actionButtonsStrokeColor: PresentationThemeVariableColor(withWallpaper: .clear, withoutWallpaper: defaultDayAccentColor),
            actionButtonsTextColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff), withoutWallpaper: defaultDayAccentColor),
            textSelectionColor: defaultDayAccentColor.withAlphaComponent(0.3),
            textSelectionKnobColor: defaultDayAccentColor),
        outgoing: PresentationThemePartedColors(
            bubble: PresentationThemeBubbleColor(
                withWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0x57b2e0), defaultDayAccentColor],
                    highlightedFill: UIColor(rgb: 0x57b2e0).withMultipliedBrightnessBy(0.7),
                    stroke: .clear,
                    shadow: nil,
                    reactionInactiveBackground: UIColor(rgb: 0xffffff, alpha: 0.12),
                    reactionInactiveForeground: UIColor(rgb: 0xffffff),
                    reactionActiveBackground: UIColor(rgb: 0xffffff),
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                ),
                withoutWallpaper: PresentationThemeBubbleColorComponents(
                    fill: [UIColor(rgb: 0x57b2e0), defaultDayAccentColor],
                    highlightedFill: UIColor(rgb: 0x57b2e0).withMultipliedBrightnessBy(0.7),
                    stroke: .clear,
                    shadow: nil,
                    reactionInactiveBackground: UIColor(rgb: 0xffffff, alpha: 0.12),
                    reactionInactiveForeground: UIColor(rgb: 0xffffff),
                    reactionActiveBackground: UIColor(rgb: 0xffffff),
                    reactionActiveForeground: .clear,
                    reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                    reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                    reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                    reactionStarsActiveForeground: .white,
                    reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                    reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
                )
            ),
            primaryTextColor: UIColor(rgb: 0xffffff),
            secondaryTextColor: UIColor(rgb: 0xffffff, alpha: 0.65),
            linkTextColor: UIColor(rgb: 0xffffff),
            linkHighlightColor: UIColor(rgb: 0xffffff, alpha: 0.3),
            scamColor: UIColor(rgb: 0xffffff),
            textHighlightColor: UIColor(rgb: 0xffc738),
            accentTextColor: UIColor(rgb: 0xffffff),
            accentControlColor: UIColor(rgb: 0xffffff),
            accentControlDisabledColor: UIColor(rgb: 0xffffff).withAlphaComponent(0.5),
            mediaActiveControlColor: UIColor(rgb: 0xffffff),
            mediaInactiveControlColor: UIColor(rgb: 0xffffff, alpha: 0.65),
            mediaControlInnerBackgroundColor: .clear,
            pendingActivityColor: UIColor(rgb: 0xffffff, alpha: 0.65),
            fileTitleColor: UIColor(rgb: 0xffffff),
            fileDescriptionColor: UIColor(rgb: 0xffffff, alpha: 0.65),
            fileDurationColor: UIColor(rgb: 0xffffff, alpha: 0.65),
            mediaPlaceholderColor: UIColor(rgb: 0x0077d9),
            polls: PresentationThemeChatBubblePolls(radioButton: UIColor(rgb: 0xffffff, alpha: 0.65), radioProgress: UIColor(rgb: 0xffffff), highlight: UIColor(rgb: 0xffffff, alpha: 0.12), separator: UIColor(rgb: 0xffffff, alpha: 0.65), bar: UIColor(rgb: 0xffffff), barIconForeground: .clear, barPositive: UIColor(rgb: 0xffffff), barNegative: UIColor(rgb: 0xffffff)),
            actionButtonsFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0xffffff, alpha: 0.8)),
            actionButtonsStrokeColor: PresentationThemeVariableColor(withWallpaper: .clear, withoutWallpaper: defaultDayAccentColor),
            actionButtonsTextColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff), withoutWallpaper: defaultDayAccentColor),
            textSelectionColor: UIColor(rgb: 0xffffff, alpha: 0.2),
            textSelectionKnobColor: UIColor(rgb: 0xffffff)),
        freeform: PresentationThemeBubbleColor(
            withWallpaper: PresentationThemeBubbleColorComponents(
                fill: [UIColor(rgb: 0xe5e5ea)],
                highlightedFill: UIColor(rgb: 0xdadade),
                stroke: UIColor(rgb: 0xe5e5ea),
                shadow: nil,
                reactionInactiveBackground: defaultDayAccentColor.withMultipliedAlpha(0.1),
                reactionInactiveForeground: defaultDayAccentColor,
                reactionActiveBackground: defaultDayAccentColor,
                reactionActiveForeground: .clear,
                reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                reactionStarsActiveForeground: .white,
                reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
            ),
            withoutWallpaper: PresentationThemeBubbleColorComponents(
                fill: [UIColor(rgb: 0xe5e5ea)],
                highlightedFill: UIColor(rgb: 0xdadade),
                stroke: UIColor(rgb: 0xe5e5ea),
                shadow: nil,
                reactionInactiveBackground: UIColor(rgb: 0xF1F0F5),
                reactionInactiveForeground: defaultDayAccentColor,
                reactionActiveBackground: defaultDayAccentColor,
                reactionActiveForeground: .clear,
                reactionStarsInactiveBackground: UIColor(rgb: 0xFEF1D4, alpha: 1.0),
                reactionStarsInactiveForeground: UIColor(rgb: 0xD3720A),
                reactionStarsActiveBackground: UIColor(rgb: 0xFFBC2E, alpha: 1.0),
                reactionStarsActiveForeground: .white,
                reactionInactiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2),
                reactionActiveMediaPlaceholder: UIColor(rgb: 0xffffff, alpha: 0.2)
            )
        ),
        infoPrimaryTextColor: UIColor(rgb: 0x000000),
        infoLinkTextColor: UIColor(rgb: 0x004bad),
        outgoingCheckColor: UIColor(rgb: 0xffffff),
        mediaDateAndStatusFillColor: UIColor(rgb: 0x000000, alpha: 0.3),
        mediaDateAndStatusTextColor: UIColor(rgb: 0xffffff),
        shareButtonFillColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor, withoutWallpaper: UIColor(rgb: 0xffffff, alpha: 0.8)),
        shareButtonStrokeColor: PresentationThemeVariableColor(withWallpaper: .clear, withoutWallpaper: UIColor(rgb: 0xe5e5ea)),
        shareButtonForegroundColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff), withoutWallpaper: defaultDayAccentColor),
        mediaOverlayControlColors: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0x000000, alpha: 0.45), foregroundColor: UIColor(rgb: 0xffffff)),
        selectionControlColors: PresentationThemeFillStrokeForeground(fillColor: defaultDayAccentColor, strokeColor: UIColor(rgb: 0xc7c7cc), foregroundColor: UIColor(rgb: 0xffffff)),
        deliveryFailedColors: PresentationThemeFillForeground(fillColor: UIColor(rgb: 0xff3b30), foregroundColor: UIColor(rgb: 0xffffff)),
        mediaHighlightOverlayColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        stickerPlaceholderColor: PresentationThemeVariableColor(withWallpaper: serviceBackgroundColor.withAlphaComponent(0.3), withoutWallpaper: UIColor(rgb: 0xf7f7f7)),
        stickerPlaceholderShimmerColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff, alpha: 0.2), withoutWallpaper: UIColor(rgb: 0x000000, alpha: 0.1))
    )
    
    let serviceMessage = PresentationThemeServiceMessage(
        components: PresentationThemeServiceMessageColor(withDefaultWallpaper: PresentationThemeServiceMessageColorComponents(fill: UIColor(rgb: 0x939fab, alpha: 0.5), primaryText: UIColor(rgb: 0xffffff), linkHighlight: UIColor(rgb: 0x748391, alpha: 0.25), scam: UIColor(rgb: 0xffffff), dateFillStatic: UIColor(rgb: 0x000000, alpha: 0.2), dateFillFloating: UIColor(rgb: 0x939fab, alpha: 0.5)), withCustomWallpaper: PresentationThemeServiceMessageColorComponents(fill: serviceBackgroundColor, primaryText: UIColor(rgb: 0xffffff), linkHighlight: UIColor(rgb: 0x748391, alpha: 0.25), scam: UIColor(rgb: 0xffffff), dateFillStatic: UIColor(rgb: 0x000000, alpha: 0.2), dateFillFloating: serviceBackgroundColor.withAlphaComponent(serviceBackgroundColor.alpha * 0.6667))),
        unreadBarFillColor: UIColor(white: 1.0, alpha: 0.9),
        unreadBarStrokeColor: UIColor(white: 0.0, alpha: 0.2),
        unreadBarTextColor: UIColor(rgb: 0x86868d),
        dateTextColor: PresentationThemeVariableColor(color: UIColor(rgb: 0xffffff))
    )
    
    let serviceMessageDay = PresentationThemeServiceMessage(
        components: PresentationThemeServiceMessageColor(withDefaultWallpaper: PresentationThemeServiceMessageColorComponents(fill: UIColor(rgb: 0xffffff, alpha: 0.8), primaryText: UIColor(rgb: 0x8d8e93), linkHighlight: UIColor(rgb: 0x748391, alpha: 0.25), scam: UIColor(rgb: 0xff3b30), dateFillStatic: UIColor(rgb: 0xffffff, alpha: 0.8), dateFillFloating: UIColor(rgb: 0xffffff, alpha: 0.8)), withCustomWallpaper: PresentationThemeServiceMessageColorComponents(fill: serviceBackgroundColor, primaryText: UIColor(rgb: 0xffffff), linkHighlight: UIColor(rgb: 0x748391, alpha: 0.25), scam: UIColor(rgb: 0xff3b30), dateFillStatic: UIColor(rgb: 0x000000, alpha: 0.2), dateFillFloating: serviceBackgroundColor.withAlphaComponent(serviceBackgroundColor.alpha * 0.6667))),
        unreadBarFillColor: UIColor(rgb: 0xffffff),
        unreadBarStrokeColor: UIColor(rgb: 0xffffff),
        unreadBarTextColor: UIColor(rgb: 0x8d8e93),
        dateTextColor: PresentationThemeVariableColor(withWallpaper: UIColor(rgb: 0xffffff), withoutWallpaper: UIColor(rgb: 0x8d8e93))
    )
    
    let inputPanelMediaRecordingControl = PresentationThemeChatInputPanelMediaRecordingControl(
        buttonColor: defaultDayAccentColor,
        micLevelColor: defaultDayAccentColor.withAlphaComponent(0.2),
        activeIconColor: UIColor(rgb: 0xffffff)
    )
    
    let inputPanel = PresentationThemeChatInputPanel(
        panelBackgroundColor: rootNavigationBar.blurredBackgroundColor,
        panelBackgroundColorNoWallpaper: UIColor(rgb: 0xffffff),
        panelSeparatorColor: UIColor(rgb: 0xb2b2b2),
        panelControlAccentColor: defaultDayAccentColor,
        panelControlColor: UIColor(rgb: 0x858e99),
        panelControlDisabledColor: UIColor(rgb: 0x727b87, alpha: 0.5),
        panelControlDestructiveColor: UIColor(rgb: 0xff3b30),
        inputBackgroundColor: UIColor(rgb: 0xffffff),
        inputStrokeColor: UIColor(rgb: 0x000000, alpha: 0.1),
        inputPlaceholderColor: UIColor(rgb: 0xbebec0),
        inputTextColor: UIColor(rgb: 0x000000),
        inputControlColor: UIColor(rgb: 0x868D98),
        actionControlFillColor: defaultDayAccentColor,
        actionControlForegroundColor: UIColor(rgb: 0xffffff),
        primaryTextColor: UIColor(rgb: 0x000000),
        secondaryTextColor: UIColor(rgb: 0x8e8e93),
        mediaRecordingDotColor: UIColor(rgb: 0xed2521),
        mediaRecordingControl: inputPanelMediaRecordingControl
    )
    
    let inputMediaPanel = PresentationThemeInputMediaPanel(
        panelSeparatorColor: UIColor(rgb: 0xbec2c6),
        panelIconColor: UIColor(rgb: 0x858e99),
        panelHighlightedIconBackgroundColor: UIColor(rgb: 0x858e99, alpha: 0.2),
        panelHighlightedIconColor: UIColor(rgb: 0x4D5561),
        panelContentVibrantOverlayColor: UIColor(white: 0.7, alpha: 0.65),
        panelContentControlVibrantOverlayColor: UIColor(white: 0.85, alpha: 0.65),
        panelContentControlVibrantSelectionColor: UIColor(white: 0.85, alpha: 0.1),
        panelContentControlOpaqueOverlayColor: UIColor(white: 0.0, alpha: 0.2),
        panelContentControlOpaqueSelectionColor: UIColor(rgb: 0x000000, alpha: 0.06),
        panelContentVibrantSearchOverlayColor: UIColor(white: 0.6, alpha: 0.55),
        panelContentVibrantSearchOverlaySelectedColor: UIColor(white: 0.4, alpha: 0.6),
        panelContentVibrantSearchOverlayHighlightColor: UIColor(white: 0.2, alpha: 0.02),
        panelContentOpaqueSearchOverlayColor: UIColor(rgb: 0x8e8e93),
        panelContentOpaqueSearchOverlaySelectedColor: UIColor(white: 0.0, alpha: 0.4),
        panelContentOpaqueSearchOverlayHighlightColor: UIColor(white: 0.0, alpha: 0.1),
        stickersBackgroundColor: UIColor(rgb: 0xe8ebf0),
        stickersSectionTextColor: UIColor(rgb: 0x9099a2),
        stickersSearchBackgroundColor: UIColor(rgb: 0xd9dbe1),
        stickersSearchPlaceholderColor: UIColor(rgb: 0x8e8e93),
        stickersSearchPrimaryColor: UIColor(rgb: 0x000000),
        stickersSearchControlColor: UIColor(rgb: 0x8e8e93),
        gifsBackgroundColor: UIColor(rgb: 0xffffff),
        backgroundColor: UIColor(rgb: 0xffffff, alpha: 0.7)
    )
    
    let inputButtonPanel = PresentationThemeInputButtonPanel(
        panelSeparatorColor: UIColor(rgb: 0xb2b2b2),
        panelBackgroundColor: UIColor(rgb: 0xdddfd7, alpha: 0.8),
        buttonFillColor: UIColor(rgb: 0xffffff),
        buttonHighlightColor: UIColor(rgb: 0xffffff, alpha: 0.2),
        buttonStrokeColor: UIColor(rgb: 0x353535, alpha: 0.2),
        buttonHighlightedFillColor: UIColor(rgb: 0xa8b3c0),
        buttonHighlightedStrokeColor: UIColor(rgb: 0xc3c7c9),
        buttonTextColor: UIColor(rgb: 0x000000)
    )
    
    let historyNavigation = PresentationThemeChatHistoryNavigation(
        fillColor: UIColor(rgb: 0xf7f7f7),
        strokeColor: UIColor(rgb: 0xc8c7cc),
        foregroundColor: UIColor(rgb: 0x88888d),
        badgeBackgroundColor: defaultDayAccentColor,
        badgeStrokeColor: defaultDayAccentColor,
        badgeTextColor: UIColor(rgb: 0xffffff)
    )

    let chat = PresentationThemeChat(
        defaultWallpaper: DWallpaper.russia.makeWallpaper(darkMode: false) ?? .builtin(WallpaperSettings()),
        animateMessageColors: false,
        message: day ? messageDay : message,
        serviceMessage: day ? serviceMessageDay : serviceMessage,
        inputPanel: inputPanel,
        inputMediaPanel: inputMediaPanel,
        inputButtonPanel: inputButtonPanel,
        historyNavigation: historyNavigation,
        isRectangleCountMessageBadge: true
    )
    
    let actionSheet = PresentationThemeActionSheet(
        dimColor: UIColor(white: 0.0, alpha: 0.4),
        backgroundType: .light,
        opaqueItemBackgroundColor: UIColor(rgb: 0xffffff),
        itemBackgroundColor: UIColor(white: 1.0, alpha: 0.8),
        opaqueItemHighlightedBackgroundColor: UIColor(white: 0.9, alpha: 1.0),
        itemHighlightedBackgroundColor: UIColor(white: 0.9, alpha: 0.7),
        opaqueItemSeparatorColor: UIColor(white: 0.9, alpha: 1.0),
        standardActionTextColor: defaultDayAccentColor,
        destructiveActionTextColor: UIColor(rgb: 0xff3b30),
        disabledActionTextColor: UIColor(rgb: 0xb3b3b3),
        primaryTextColor: UIColor(rgb: 0x000000),
        secondaryTextColor: UIColor(rgb: 0x8e8e93),
        controlAccentColor: defaultDayAccentColor,
        inputBackgroundColor: UIColor(rgb: 0xe9e9e9),
        inputHollowBackgroundColor: UIColor(rgb: 0xffffff),
        inputBorderColor: UIColor(rgb: 0xe4e4e6),
        inputPlaceholderColor: UIColor(rgb: 0x8e8d92),
        inputTextColor: UIColor(rgb: 0x000000),
        inputClearButtonColor: UIColor(rgb: 0x9e9ea1),
        checkContentColor: UIColor(rgb: 0xffffff)
    )
    
    let contextMenu = PresentationThemeContextMenu(
        dimColor: UIColor(rgb: 0x000a26, alpha: 0.2),
        backgroundColor: UIColor(rgb: 0xf9f9f9, alpha: 0.78),
        itemSeparatorColor: UIColor(rgb: 0x3c3c43, alpha: 0.2),
        sectionSeparatorColor: UIColor(rgb: 0x8a8a8a, alpha: 0.2),
        itemBackgroundColor: UIColor(rgb: 0x000000, alpha: 0.0),
        itemHighlightedBackgroundColor: UIColor(rgb: 0x3c3c43, alpha: 0.2),
        primaryColor: UIColor(rgb: 0x000000),
        secondaryColor: UIColor(rgb: 0x000000, alpha: 0.5),
        destructiveColor: UIColor(rgb: 0xff3b30),
        badgeFillColor: defaultDayAccentColor,
        badgeForegroundColor: UIColor(rgb: 0xffffff),
        badgeInactiveFillColor: UIColor(rgb: 0xb6b6bb),
        badgeInactiveForegroundColor: UIColor(rgb: 0xffffff),
        extractedContentTintColor: .white
    )
    
    let inAppNotification = PresentationThemeInAppNotification(
        fillColor: UIColor(rgb: 0xffffff),
        primaryTextColor: UIColor(rgb: 0x000000),
        expandedNotification: PresentationThemeExpandedNotification(
            backgroundType: .light,
            navigationBar: PresentationThemeExpandedNotificationNavigationBar(
                backgroundColor: UIColor(rgb: 0xffffff),
                primaryTextColor: UIColor(rgb: 0x000000),
                controlColor: UIColor(rgb: 0x7e8791),
                separatorColor: UIColor(rgb: 0xc8c7cc)
            )
        )
    )
    
    let chart = PresentationThemeChart(
        labelsColor: UIColor(rgb: 0x252529, alpha: 0.5),
        helperLinesColor: UIColor(rgb: 0x182d3b, alpha: 0.3),
        strongLinesColor: UIColor(rgb: 0x182d3b, alpha: 0.3),
        barStrongLinesColor: UIColor(rgb: 0x252529, alpha: 0.2),
        detailsTextColor: UIColor(rgb: 0x6d6d72),
        detailsArrowColor: UIColor(rgb: 0xc5c7cd),
        detailsViewColor: UIColor(rgb: 0xf5f5fb),
        rangeViewFrameColor: UIColor(rgb: 0xcad4de),
        rangeViewMarkerColor: UIColor(rgb: 0xffffff)
    )
    
    return PresentationTheme(
        name: extendingThemeReference?.name ?? .builtin(day ? .day : .dayClassic),
        index: extendingThemeReference?.index ?? PresentationThemeReference.builtin(day ? .day : .dayClassic).index,
        referenceTheme: day ? .day : .dayClassic,
        overallDarkAppearance: false,
        intro: intro,
        passcode: passcode,
        rootController: rootController,
        list: list,
        chatList: chatList,
        chat: chat,
        actionSheet: actionSheet,
        contextMenu: contextMenu,
        inAppNotification: inAppNotification,
        chart: chart,
        preview: preview
    )
}

public let defaultDahlBuiltinWallpaperGradientColors: [UIColor] = [
    UIColor(rgb: 0xdbddbb),
    UIColor(rgb: 0x6ba587),
    UIColor(rgb: 0xd5d88d),
    UIColor(rgb: 0x88b884)
]
