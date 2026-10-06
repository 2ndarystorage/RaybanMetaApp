# TurboMeta AI Add — Ray-Ban Meta向けAIアシスタント

[日本語](README.md) · [English](README_EN.md) · [简体中文](README_ZH.md)

![TurboMetaのロゴ](rayban.png)

このリポジトリは [Turbo1123/turbometa-rayban-ai](https://github.com/Turbo1123/turbometa-rayban-ai) を基に、Ray-Ban Meta向けアプリのiOS版へ **OpenAI Realtime API、ウェイクワード、Function Calling、AI Router** を追加したものです。元のQwen Omni、Gemini Live、OpenRouter、Quick Vision、OpenClaw、RTMP配信などの機能も残しています。

> iOSアプリはソースコードからXcodeでビルドしてください。Android版も収録していますが、今回のOpenAI Realtime・Function Calling・AI Routerの追加はiOS版のみです。Androidの既存ウェイクワード機能は維持しています。

## 今回追加した機能

| 機能 | iOSでの動作 |
| --- | --- |
| OpenAI Realtime API | `gpt-realtime` に音声を送信し、返答音声と文字起こしを表示します。発話時に眼鏡のカメラ画像も送信できます。 |
| ウェイクワード | Live AI画面を開いている間、対応端末では端末内音声認識で英語の「Hey Turbo」を待ち受けます。手動の「Start now」ボタンも利用できます。 |
| Function Calling | OpenAI Realtimeから `get_current_time`（端末の現在時刻）と `get_camera_frame_status`（カメラ画像の取得状況）を呼び出せます。どちらも読み取り専用です。 |
| AI Router | 「Auto」を選ぶと、設定済みAPIキーを **OpenAI → Qwen → Gemini** の順に確認し、会話開始時に接続先を決めます。 |

**対応範囲：** 上記のOpenAI連携・関数呼び出し・自動選択はiOS版に実装しています。Androidには既存のQwen/Gemini切り替えと「Jarvis」でQuick Visionを起動するPorcupineウェイクワードがあります。Android版の詳細は[こちら](android/README.md)をご覧ください。

## 主な既存機能

- **Live AI：** 眼鏡のマイク・カメラを使ったリアルタイム会話。Qwen OmniとGemini Liveを選択できます。
- **Quick Vision：** 撮影画像をAIで解析。iOSではSiriショートカット、Androidでは既存の「Jarvis」ウェイクワードに対応します。
- **OpenClaw：** iOSで写真・音声認識・テキストをOpenClaw Gatewayへ送信できます。
- **写真・栄養解析：** 撮影、LeanEatによる食事の栄養情報とスコア表示。
- **配信・翻訳：** RTMP配信、リアルタイム翻訳、会話履歴の保存。
- **画像解析モデル：** Alibaba DashscopeとOpenRouterに対応します。

機能の詳細や画面例は[英語版の元README](README_EN.md)と[中国語版の元README](README_ZH.md)にも掲載しています。

### 画面例

| ホーム | 会話履歴 | カメラ | 設定 |
| --- | --- | --- | --- |
| ![ホーム画面](screenshots/首页.jpg) | ![会話履歴](screenshots/对话记录.jpg) | ![カメラ画面](screenshots/camera.jpg) | ![設定画面](screenshots/设置页面.jpg) |

元プロジェクトの[デモ動画](https://www.bilibili.com/video/BV1aTqSBHEqN)も参照できます。スクリーンショットと動画は元機能の紹介であり、今回追加した4機能の動作確認映像ではありません。

## 動作に必要なもの

- Ray-Ban Metaなど、Meta Wearables DAT SDKに対応する眼鏡と、ペアリング済みのスマートフォン。
- iOS 17以降のiPhoneとXcode。Android側の要件は[Android README](android/README.md)を参照してください。
- Meta Wearables Developer Centerで作成したアプリ設定と、利用するAIサービスのAPIキー。
- リアルタイムAI機能を使うためのネットワーク接続。

## iOS版のセットアップ

1. [Meta Wearables Developer Center](https://wearables.developer.meta.com/)でプロジェクトを作成し、iOS用の **Meta App ID** と **Client Token** を取得します。
2. Xcodeで `CameraAccess.xcodeproj` を開き、署名用のTeamとBundle Identifierを設定します。`CameraAccess/Info.plist` は `$(META_APP_ID)` と `$(CLIENT_TOKEN)` を参照しているため、同名のXcodeビルド設定に取得した値を登録します。値をGitへコミットしないでください。
3. Meta View／Meta AIアプリで眼鏡をペアリングし、元プロジェクトの手順に従って **DAT SDKプレビューモード** を有効にします。元READMEでは、アプリ情報画面のバージョン番号を5回タップする手順が案内されています。
4. iPhoneを接続してXcodeからビルド・起動します。アプリの設定画面で利用するAIサービスのAPIキーを保存します。

### 追加機能の設定

1. **設定 → Live AI Provider** で「OpenAI Realtime」または「AI Router (Auto)」を選びます。既存設定の既定値はQwenのままです。
2. OpenAIを使う場合は **設定 → OpenAI API Key** からキーを登録します。キーはiOSのKeychainに保存されます。AutoでQwenを使う場合は選択中の地域に対応するAlibabaキー、Geminiを使う場合はGoogleキーを設定してください。
3. ウェイクワードを使う場合は **「Wake phrase: Hey Turbo」** を有効にし、マイクと音声認識の権限を許可します。眼鏡を接続してLive AI画面を開き、「Hey Turbo」と話すか、画面の「Start now」を押してください。

| 利用する機能 | 必要なキー・設定 |
| --- | --- |
| OpenAI Realtime、Function Calling | [OpenAIのAPIキー](https://platform.openai.com/api-keys)と `gpt-realtime` へのアクセス権 |
| Qwen Omni、Alibaba画像解析 | [Alibaba Cloud Model Studio](https://bailian.console.aliyun.com/) のキー。利用する地域に合わせて設定 |
| Gemini Live | [Google AI Studio](https://aistudio.google.com/apikey) のキー |
| OpenRouter画像解析 | [OpenRouterのAPIキー](https://openrouter.ai/keys) |
| Androidの「Jarvis」ウェイクワード | [Picovoice Console](https://console.picovoice.ai/) のAccess Key |
| OpenClaw | 利用者自身のGatewayアドレスとToken |

## 既存機能の使い方

### Quick VisionとSiri

アプリでAPIキーと眼鏡の接続を設定した後、iPhoneの「ショートカット」アプリでTurboMetaの「快速识图」アクションを追加します。ショートカットに好きな名前を付け、Siriでその名前を呼ぶと、撮影・画像解析・音声読み上げを開始できます。必要に応じてiPhoneのアクションボタンやロック画面ウィジェットにも割り当てられます。初回はTurboMetaを一度開き、機能を初期化してください。

### OpenClaw

iOSアプリの **設定 → OpenClaw** に、利用者が管理するGatewayのアドレス・ポート・Tokenを入力します。Gateway側ではローカルネットワークからの接続と必要なカメラコマンドの許可が必要です。眼鏡の写真撮影はアプリを前面に表示している間に行います。Gatewayの導入・許可コマンドの詳しい例は[元READMEのOpenClaw手順](README_EN.md#-openclaw-integration)を参照してください。外部ネットワークからの接続には、元READMEではTailscaleの利用が案内されています。

### 配信とその他の機能

Live AIはホーム画面から開き、接続後に話しかけます。Quick Visionは撮影した場面を短く説明し、LeanEatは撮影した食事の栄養情報を推定します。RTMP配信は配信先URLと必要な認証情報を用意して使用します。栄養情報などのAI推定結果は参考情報として扱ってください。

## 困ったときは

- **眼鏡が接続されない：** Meta View／Meta AIアプリでのペアリング、Bluetooth、DAT SDKプレビューモードを確認し、アプリと眼鏡を再起動します。
- **AIが返答しない：** 選択したサービスのAPIキー、地域、ネットワーク接続、利用枠を確認します。Autoは接続失敗時に別サービスへ自動で切り替わりません。
- **SiriにTurboMetaの操作が出ない：** インストール後にアプリを一度開き、必要ならiPhoneを再起動します。
- **音声が聞こえない：** iPhoneと眼鏡のBluetooth音声出力、音量、ネットワークを確認します。
- **Xcodeで起動できない：** Signing & CapabilitiesのTeam、Bundle Identifier、実機の開発者設定を確認します。

## 利用上の制約

- iOSの「Hey Turbo」は、Live AI画面を前面に表示している間だけ待ち受けます。`en-US` の端末内音声認識が利用できない場合は「Start now」を使ってください。バックグラウンドやシステム全体のウェイクワードではありません。
- AI Routerは会話開始時に設定済みキーの優先順位で選びます。会話中のモデル切り替えや、接続エラー後の自動フェイルオーバーは行いません。
- Function Callingで公開しているのは現在時刻とカメラ画像の取得状況だけです。外部サービスの操作や任意の端末操作はできません。
- OpenAIへ送った音声・画像にはAPI利用料金が発生する場合があります。実際の眼鏡とAPIを使った動作確認は利用者の環境で必要です。
- Meta DAT SDKの制約により、眼鏡カメラをバックグラウンドから利用できない機能があります。
- 配布用アプリでは共有APIキーを埋め込まず、信頼できるバックエンドで短命のクライアント用認証情報を発行してください。

## ビルド・検証状況

追加部分のSwift構文、`Info.plist`、Git差分の静的検証は通過しています。iOSのフルビルドは、実行環境でSwiftPMの依存パッケージ処理が制限されたため未確認です。眼鏡を使った実機検証も未実施です。

## ライセンスと謝辞

ライセンスは[LICENSE](LICENSE)を参照してください。元プロジェクトの作者 [Turbo1123](https://github.com/Turbo1123) とMeta Wearables DAT SDKの開発元に感謝します。
