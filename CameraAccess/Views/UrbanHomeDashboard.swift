import SwiftUI

/// Presentation stays independent of the glasses SDK so the layout can be previewed offline.
enum UrbanHomeAction {
    case liveAI, quickVision, translation, leanEat, book
}

private enum UrbanPalette {
    static let paper = Color(red: 0.957, green: 0.953, blue: 0.933)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.11)
    static let muted = Color(red: 0.40, green: 0.43, blue: 0.40)
    static let line = Color(red: 0.83, green: 0.84, blue: 0.81)
    static let moss = Color(red: 0.36, green: 0.43, blue: 0.32)
}

struct UrbanHomeDashboard: View {
    let isConnected: Bool
    let onSelect: (UrbanHomeAction) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(HomeAccessibilitySettings.storageKey) private var accessibilityMode = false
    @State private var showDisplaySettings = false

    var body: some View {
        Group {
            if accessibilityMode {
                AccessibleHomeDashboard(isConnected: isConnected, onSelect: onSelect) {
                    showDisplaySettings = true
                }
            } else {
                standardBody
            }
        }
        .sheet(isPresented: $showDisplaySettings) { HomeDisplaySettingsSheet() }
    }

    private var standardBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                UrbanBrandHeader(isConnected: isConnected)
                VStack(alignment: .leading, spacing: 10) {
                    Text("EVERYDAY, A NEW PERSPECTIVE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(1.8)
                        .foregroundStyle(UrbanPalette.muted)
                    Text("いつもの街に、\n新しい視点を。")
                        .font(.system(.largeTitle, design: .default, weight: .medium))
                        .tracking(-1.6)
                        .lineSpacing(2)
                }
                liveCard
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("日常を、もっと自由に。")
                            .font(.system(.subheadline, weight: .medium))
                        Spacer()
                        Text("EXPLORE / 04")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(UrbanPalette.muted)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                        tool("目の前の景色を読み取る", detail: "見ているものを、知る。", category: "VISION", number: "02", symbol: "viewfinder", action: .quickVision)
                        tool("外国語をリアルタイムで翻訳する", detail: "会話を、その場で翻訳。", category: "TRANSLATE", number: "03", symbol: "character.bubble", action: .translation)
                        tool("食事を記録する", detail: "ひと皿から、健やかに。", category: "LEAN EAT", number: "04", symbol: "leaf", action: .leanEat)
                        tool("本の要約を聴く", detail: "一ページを、短い音声に。", category: "BOOK READER", number: "05", symbol: "book", action: .book)
                    }
                }
                readingCard
                HStack(spacing: 12) {
                    GlassesSignature().stroke(UrbanPalette.muted, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 36, height: 15)
                        .accessibilityHidden(true)
                    Text("視線の先に、あなたのアシスタント。")
                        .font(.system(.caption2, weight: .regular))
                        .foregroundStyle(UrbanPalette.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(UrbanPalette.ink)
        .background(UrbanPalette.paper.ignoresSafeArea())
    }

    private var liveCard: some View {
        Button { onSelect(.liveAI) } label: {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geometry in
                    Image("UrbanGlassesHero")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                LinearGradient(stops: [.init(color: .clear, location: 0.32), .init(color: .black.opacity(0.72), location: 1)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("LIVE AI", systemImage: "waveform")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.2)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(15)
                    .background(.black.opacity(0.14))
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("見た世界を、\nそのまま話そう。")
                                .font(.system(.title2, weight: .medium))
                                .tracking(-0.7)
                                .multilineTextAlignment(.leading)
                            Text("グラスの視点で、AIと会話する")
                                .font(.system(.caption, weight: .regular))
                                .foregroundStyle(.white.opacity(0.84))
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(UrbanPalette.ink)
                            .frame(width: 42, height: 42)
                            .background(UrbanPalette.paper, in: Circle())
                    }
                    .padding(20)
                }
            }
            .foregroundStyle(.white)
            .frame(height: typeSize.isAccessibilitySize ? 390 : 310)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(UrbanPressStyle())
        .accessibilityLabel("Live AI。グラスのカメラとマイクでAIと会話する")
    }

    private func tool(_ title: String, detail: String, category: String, number: String, symbol: String, action: UrbanHomeAction) -> some View {
        Button { onSelect(action) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.system(size: 25, weight: .ultraLight))
                        .frame(height: 29)
                    Spacer()
                    Text(number)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(UrbanPalette.muted)
                }
                .padding(.bottom, 21)
                Text(category)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(UrbanPalette.muted)
                    .padding(.bottom, 6)
                Text(title)
                    .font(.system(.subheadline, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .tracking(-0.5)
                    .padding(.bottom, 5)
                Text(detail)
                    .font(.system(.caption2))
                    .foregroundStyle(UrbanPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
            .padding(16)
            .background(.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(UrbanPalette.line.opacity(0.65), lineWidth: 0.6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(UrbanPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)。\(detail)")
    }

    private var readingCard: some View {
        Button { onSelect(.book) } label: {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geometry in
                    Image("UrbanReading")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    Text("A MOMENT TO READ")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(1.6)
                    HStack(alignment: .bottom) {
                        Text("読む時間を、\n聴く時間に。")
                            .font(.system(.title3, weight: .medium))
                            .tracking(-0.6)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .frame(height: typeSize.isAccessibilitySize ? 320 : 210)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(UrbanPressStyle())
        .accessibilityLabel("本の要約を開く。読む時間を、聴く時間に")
    }
}

private struct UrbanBrandHeader: View {
    var isConnected: Bool?

    var body: some View {
        HStack(spacing: 9) {
            GlassesSignature().stroke(UrbanPalette.ink, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 43, height: 19)
                .accessibilityHidden(true)
            Text("Ray-Ban")
                .font(.system(size: 21, weight: .semibold, design: .serif)).italic()
                .tracking(-1.0)
            Text("/")
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(UrbanPalette.muted)
            Text("Meta")
                .font(.system(size: 20, weight: .medium))
                .tracking(-0.7)
            Spacer(minLength: 4)
            if let isConnected {
                HStack(spacing: 5) {
                    Circle().fill(isConnected ? UrbanPalette.moss : UrbanPalette.muted)
                        .frame(width: 5, height: 5)
                    Text(isConnected ? "接続済み" : "未接続")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .overlay(Capsule().stroke(UrbanPalette.line, lineWidth: 0.7))
            }
        }
        .foregroundStyle(UrbanPalette.ink)
        .padding(.bottom, 4)
    }
}

/// A small, original frame silhouette, rather than a raster logo or filled app icon.
private struct GlassesSignature: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        p.move(to: point(0.04, 0.20))
        p.addQuadCurve(to: point(0.43, 0.22), control: point(0.22, 0.05))
        p.addQuadCurve(to: point(0.36, 0.84), control: point(0.45, 0.82))
        p.addQuadCurve(to: point(0.11, 0.79), control: point(0.17, 0.98))
        p.addQuadCurve(to: point(0.04, 0.20), control: point(0.07, 0.65))
        p.move(to: point(0.57, 0.22))
        p.addQuadCurve(to: point(0.96, 0.20), control: point(0.78, 0.05))
        p.addQuadCurve(to: point(0.89, 0.79), control: point(0.93, 0.65))
        p.addQuadCurve(to: point(0.64, 0.84), control: point(0.83, 0.98))
        p.addQuadCurve(to: point(0.57, 0.22), control: point(0.55, 0.82))
        p.move(to: point(0.44, 0.36))
        p.addQuadCurve(to: point(0.56, 0.36), control: point(0.50, 0.20))
        p.move(to: point(0, 0.22))
        p.addLine(to: point(0.04, 0.24))
        p.move(to: point(0.96, 0.24))
        p.addLine(to: point(1, 0.22))
        return p
    }
}

private struct UrbanPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.87 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct UrbanWelcomeContent: View {
    let isConnecting: Bool
    let onConnect: () -> Void
    @AppStorage(HomeAccessibilitySettings.storageKey) private var accessibilityMode = false
    @State private var showDisplaySettings = false

    var body: some View {
        Group {
            if accessibilityMode {
                AccessibleWelcomeContent(isConnecting: isConnecting, onConnect: onConnect) {
                    showDisplaySettings = true
                }
            } else {
                standardBody
            }
        }
        .preferredColorScheme(accessibilityMode ? nil : .light)
        .sheet(isPresented: $showDisplaySettings) { HomeDisplaySettingsSheet() }
    }

    private var standardBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                UrbanBrandHeader(isConnected: nil)
                Button {
                    showDisplaySettings = true
                } label: {
                    Label("表示の設定", systemImage: "textformat.size")
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 48)
                }
                .accessibilityIdentifier("welcome.display.settings")
                ZStack(alignment: .bottomLeading) {
                    GeometryReader { geometry in
                        Image("UrbanGlassesHero")
                            .resizable().scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR WORLD. A NEW PERSPECTIVE.")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                        Text("かけるだけで、\n日常が広がる。")
                            .font(.system(.largeTitle, weight: .medium))
                            .tracking(-1.3)
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                VStack(alignment: .leading, spacing: 12) {
                    Text("グラスの先に、AIを。")
                        .font(.system(.title2, weight: .medium))
                        .tracking(-0.8)
                    Text("見て、話して、理解する。\nRay-Ban Metaと、あなたの毎日をもっと自由に。")
                        .font(.system(.subheadline))
                        .lineSpacing(5)
                        .foregroundStyle(UrbanPalette.muted)
                }
                HStack(spacing: 20) {
                    Label("AI会話", systemImage: "waveform")
                    Label("翻訳", systemImage: "character.bubble")
                    Label("本の要約", systemImage: "book")
                }
                .font(.system(.caption))
                .foregroundStyle(UrbanPalette.muted)
                Button(action: onConnect) {
                    HStack {
                        if isConnecting { ProgressView().tint(.white) }
                        Text(isConnecting ? "接続中…" : "Ray-Ban Metaに接続")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(.subheadline, weight: .medium))
                    .padding(20)
                    .foregroundStyle(.white)
                    .background(UrbanPalette.ink, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(UrbanPressStyle())
                .disabled(isConnecting)
                Text("Meta AIアプリを開き、グラスとの接続を確認します。")
                    .font(.system(.caption2))
                    .foregroundStyle(UrbanPalette.muted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, -14)
            }
            .padding(22)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(UrbanPalette.ink)
        .background(UrbanPalette.paper.ignoresSafeArea())
    }
}
