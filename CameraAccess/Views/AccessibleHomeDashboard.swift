import SwiftUI

/// Task-first home: all actions have visible text, VoiceOver labels, and flexible heights.
struct AccessibleHomeDashboard: View {
    let isConnected: Bool
    let onSelect: (UrbanHomeAction) -> Void
    let onDisplaySettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AccessibleHomeHeader(onDisplaySettings: onDisplaySettings)
                Text("知りたいことを、\n自分のペースで。")
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                AccessibleHomeImage()
                Text("声でたずねる。文字や本を音声で確かめる。自分に合う方法を選べます。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Label(isConnected ? "グラスは接続されています" : "グラスは未接続です。設定で接続を確認できます", systemImage: isConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.body.weight(.semibold))
                    .accessibilityIdentifier("home.glasses.status")

                action(title: "声で質問したい", detail: "AIとの会話を開きます。声で質問し、返答を音声で聴けます。", symbol: "mic.fill", destination: .liveAI, prominent: true)

                Text("いま、確かめたいこと")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 16) {
                    action(title: "目の前に見えるものを知りたい", detail: "設定した画像認識モードで、グラスで撮影した画像の解析結果を聴けます。", symbol: "text.viewfinder", destination: .quickVision)
                    action(title: "本を要約して聴きたい", detail: "本のページを日本語で要約して聴けます。要約の長さを選べます。", symbol: "book.fill", destination: .book)
                    action(title: "会話を訳してほしい", detail: "話していることばを、設定した言語に翻訳します。", symbol: "character.bubble.fill", destination: .translation)
                    action(title: "食事の内容を知りたい", detail: "食事の写真から、栄養の目安を確認します。", symbol: "fork.knife", destination: .leanEat)
                }

                Text("画像や音声はAIサービスへ送信されます。AIの説明には誤りや見落としがあります。移動や道路の横断など、安全に関わる判断には使えません。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.primary)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .accessibilityIdentifier("home.accessible")
    }

    private func action(title: String, detail: String, symbol: String, destination: UrbanHomeAction, prominent: Bool = false) -> some View {
        Button { onSelect(destination) } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2.weight(.semibold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(22)
            .foregroundStyle(prominent ? Color(uiColor: .systemBackground) : .primary)
            .background(prominent ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.primary.opacity(0.6), lineWidth: 1.25)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
        .accessibilityIdentifier("home.action.\(destination.accessibilityID)")
    }
}

struct AccessibleWelcomeContent: View {
    let isConnecting: Bool
    let onConnect: () -> Void
    let onDisplaySettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AccessibleHomeHeader(onDisplaySettings: onDisplaySettings)
                Text("知りたいことを、\n自分のペースで。")
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                AccessibleHomeImage()
                Text("グラスを接続すると、声で質問したり、文字や本の内容を音声で確かめたりできます。まずは接続から始めます。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onConnect) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isConnecting ? "グラスに接続しています" : "グラスを接続する")
                            .font(.title2.weight(.bold))
                        Text("Meta AIアプリで接続の確認を行います。")
                            .font(.body)
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .padding(22)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .disabled(isConnecting)
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("welcome.connect")
                .accessibilityLabel(isConnecting ? "グラスに接続しています" : "グラスを接続する")
                .accessibilityHint("Meta AIアプリで接続を確認します。")

                Text("声と音声で、情報を確かめる")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 20) {
                    Label("声で質問し、AIの返答を聴く", systemImage: "mic.fill")
                    Label("画像に写った文字やものを確かめる", systemImage: "text.viewfinder")
                    Label("本のページを短い要約で聴く", systemImage: "book.fill")
                }
                .font(.body)
                Text("この表示は、全盲・ロービジョンなど見え方の違いにかかわらず選べます。文字の大きさはiPhoneの設定に合わせて変わります。VoiceOverを使う場合も、同じボタンから操作できます。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.primary)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .accessibilityIdentifier("welcome.accessible")
    }
}

private struct AccessibleHomeHeader: View {
    let onDisplaySettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RaybanMetaApp")
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Button(action: onDisplaySettings) {
                Label("表示の設定", systemImage: "textformat.size")
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 48)
                    .padding(.horizontal, 16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityHint("視覚障害者向けの表示をオン、オフにできます。")
            .accessibilityIdentifier("home.display.settings")
        }
    }
}

private struct AccessibleHomeImage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("AccessibleEveryday")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("スマートグラスをかけた人が、机に開いた本を置き、音声に耳を傾けています。椅子のそばに白杖があります。")
            Text("聴いて確かめる、自分の時間。")
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
    }
}

extension UrbanHomeAction {
    var accessibilityID: String {
        switch self {
        case .liveAI: return "liveAI"
        case .quickVision: return "quickVision"
        case .translation: return "translation"
        case .leanEat: return "leanEat"
        case .book: return "book"
        }
    }
}
