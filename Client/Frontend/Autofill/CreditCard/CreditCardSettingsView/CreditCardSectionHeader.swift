// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if !os(iOS) || WK_IOS_SINCE_13
import Combine
import SwiftUI
import Shared

struct CreditCardSectionHeader: View {
    // Theming
    @Environment(\.themeType)
    var themeVal
    @State var textColor: Color = .clear

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.CreditCard.EditCard.SavedCardListTitle)
                .font(.caption)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity,
                       alignment: .leading)
        }
        .padding(EdgeInsets(top: 24,
                            leading: 16,
                            bottom: 8,
                            trailing: 16))
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onReceive(Just(themeVal)) { val in
            applyTheme(theme: val.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textSecondary)
    }
}

struct CreditCardSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardSectionHeader()
    }
}
#endif
