// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if !os(iOS) || WK_IOS_SINCE_13
#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 14.0, *)
@main
struct FirefoxWidgets: WidgetBundle {
    @WidgetBundleBuilder var body: some Widget {
        SmallQuickLinkWidget()
        SearchQuickLinksWidget()
        OpenTabsWidget()
        TopSitesWidget()
    }
}
#endif
#endif
