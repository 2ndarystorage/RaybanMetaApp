import AVFoundation
import SwiftUI

struct VoiceMemoView: View {
    @StateObject private var model = VoiceMemoModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingDelete: VoiceMemo?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("話したことを、そのままメモに。")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("日本語の音声を端末内で文字にします。1回最大55秒。停止すると自動保存され、続けて開始すると同じメモに追記します。")
                    Toggle("Bluetoothマイクを使う", isOn: $model.useBluetooth)
                        .disabled(model.busy)
                    Text(model.useBluetooth ? "グラスなどのBluetooth通話用マイクを使用します。" : "iPhoneのマイクを使用します。グラス未接続でも使えます。")
                        .font(.footnote)
                    if !model.inputName.isEmpty && model.busy {
                        Label("使用中のマイク \(model.inputName)", systemImage: "mic")
                    }
                    Button {
                        if model.busy { model.stop() }
                        else { Task { await model.start() } }
                    } label: {
                        Label(buttonTitle, systemImage: model.busy ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.phase == .finishing)
                    .accessibilityIdentifier("voicememo.record")
                    .accessibilityHint(model.busy ? "文字起こしを止め、認識した文章を保存します。" : "選んだマイクで日本語の文字起こしを始めます。")
                }

                Section("文字起こし") {
                    TextEditor(text: $model.text)
                        .frame(minHeight: 180)
                        .disabled(model.busy)
                        .accessibilityLabel("文字起こしの内容。停止中に修正できます")
                        .accessibilityIdentifier("voicememo.text")
                    if let message = model.message {
                        Text(message).foregroundStyle(.secondary)
                    }
                    if let error = model.errorMessage {
                        Text(error).foregroundStyle(.red)
                            .accessibilityIdentifier("voicememo.error")
                    }
                    Button("修正した内容を保存") { model.save() }
                        .disabled(model.busy || model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    ShareLink(item: model.text) { Label("テキストを共有", systemImage: "square.and.arrow.up") }
                        .disabled(model.busy || model.text.isEmpty)
                    Button("新しいメモを作る") { model.newMemo() }
                        .disabled(model.busy)
                }

                Section("保存したメモ（\(model.memos.count)件）") {
                    if model.memos.isEmpty {
                        Text("保存したメモはここに表示されます。")
                    }
                    ForEach(model.memos) { memo in
                        NavigationLink {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundStyle(.secondary)
                                    Text(memo.text).textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ShareLink(item: memo.text) { Label("テキストを共有", systemImage: "square.and.arrow.up") }
                                }.padding()
                            }
                            .navigationTitle("保存した音声メモ")
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(memo.title).lineLimit(2)
                                Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) { pendingDelete = memo }
                                .disabled(model.busy)
                        }
                    }
                }
                Section {
                    Text("音声ファイルは保存しません。文章はこのiPhone内に保存されます。マイクに入る周囲の声も文字になる場合があり、自分の声だけを識別する機能ではありません。画面を閉じる、アプリを離れる、着信や音声入力の切断があった場合は停止し、その時点の文章を保存します。")
                        .font(.footnote)
                }
            }
            .navigationTitle("音声メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        model.suspend()
                        if model.save() { dismiss() }
                    }
                }
            }
            .confirmationDialog("このメモを削除しますか？", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    if let memo = pendingDelete { model.delete(memo) }
                    pendingDelete = nil
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { model.suspend() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification).receive(on: DispatchQueue.main)) { _ in
            model.suspend()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification).receive(on: DispatchQueue.main)) { notification in
            if let value = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
               value == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                model.suspend()
            }
        }
        .onDisappear { model.suspend() }
        .interactiveDismissDisabled(model.busy || !model.text.isEmpty)
    }

    private var buttonTitle: String {
        switch model.phase {
        case .idle: return "文字起こしを開始"
        case .preparing: return "準備をキャンセル"
        case .recording: return "停止して保存"
        case .finishing: return "最後のことばを確認しています"
        }
    }
}
