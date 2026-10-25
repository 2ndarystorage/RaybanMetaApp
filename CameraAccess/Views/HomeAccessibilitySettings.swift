import SwiftUI

/// A display preference only. It never changes VoiceOver, API keys, or AI provider settings.
enum HomeAccessibilitySettings {
    static let storageKey = "home_accessibility_mode"
}

struct HomeAccessibilityToggle: View {
    @AppStorage(HomeAccessibilitySettings.storageKey) private var isEnabled = false

    var body: some View {
        Toggle("視覚障害者向け", isOn: $isEnabled)
            .accessibilityIdentifier("home.accessibility.toggle")
            .accessibilityHint("ホームの文言、配置、画像を切り替えます。設定は次回の起動後も保持されます。")
    }
}

struct HomeDisplaySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HomeAccessibilityToggle()
                } header: {
                    Text("ホームの表示")
                } footer: {
                    Text("知りたいことから選べる文言、大きなボタン、はっきりした配色に切り替えます。音声で操作する場合は、iPhoneの設定からVoiceOverを有効にしてください。このスイッチでVoiceOverの設定は変わりません。")
                }
            }
            .navigationTitle("表示の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }
}
