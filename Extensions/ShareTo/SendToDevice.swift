// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
#if !os(iOS) || WK_IOS_SINCE_13
import SwiftUI
#endif
import UIKit

class SendToDevice: DevicePickerViewControllerDelegate, InstructionsViewDelegate {
    var sharedItem: ShareItem?
    weak var delegate: ShareControllerDelegate?
    private let themeManager = DefaultThemeManager()
    private var profile: Profile {
        let profile = BrowserProfile(localName: "profile")

        // Re-open the profile if it was shutdown. This happens when we run from an app extension, where we must
        // make sure that the profile is only open for brief moments of time.
        if profile.isShutdown {
            profile.reopen()
        }

        return profile
    }

    func initialViewController() -> UIViewController {
        guard let shareItem = sharedItem else {
            finish()
            return UIViewController()
        }

        let colors = SendToDeviceHelper.Colors(defaultBackground: themeManager.currentTheme.colors.layer2,
                                               textColor: themeManager.currentTheme.colors.textPrimary,
                                               iconColor: themeManager.currentTheme.colors.iconPrimary)
        let helper = SendToDeviceHelper(shareItem: shareItem,
                                        profile: profile,
                                        colors: colors,
                                        delegate: self)
        return helper.initialViewController()
    }

    func finish() {
        profile.shutdown()
        delegate?.finish(afterDelay: 0)
    }

    // MARK: - DevicePickerViewControllerDelegate

    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        guard let item = sharedItem else {
            return finish()
        }

        profile.sendItem(item, toDevices: devices).uponQueue(.main) { _ in
            self.finish()

            addAppExtensionTelemetryEvent(forMethod: "send-to-device")
        }
    }

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        finish()
    }

    // MARK: - InstructionsViewDelegate

    func dismissInstructionsView() {
        finish()
    }
}
