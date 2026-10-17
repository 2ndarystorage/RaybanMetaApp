# RaybanMeta-OpenAI — Ray-Ban Meta向けAIアシスタント

> **iOS版の最新構成（2026年10月18日）:** ホーム画面はLive AI、クイック画像認識、リアルタイム翻訳、LeanEatの2×2配置です。OpenClaw、RTMP配信、単独ライブ配信はiOSアプリから削除しました。英語・中国語READMEと画像は元プロジェクトの参考資料で、現在のiOS版と一致しない箇所があります。

## OpenAI APIキーの共通利用

**設定 → OpenAI API Key（画像・栄養・翻訳共通）** で登録した1つのキーを、OpenAI選択時のLive AI、クイック画像認識、撮影後の画像認識、LeanEat、リアルタイム翻訳で使います。キーはiPhoneのKeychainに保存されます。画像認識とLeanEatは `gpt-4.1-mini`、翻訳は `gpt-realtime-translate` を利用します。各モデルへのアクセス権と利用料金が必要です。Live AIのQwen/Gemini切り替えは残しており、その場合だけ各サービスのキーが別途必要です。

翻訳は原文言語を自動判定し、設定で翻訳先を指定します。旧Qwen版の音色選択、画像補助翻訳、原文言語の固定は使えません。音声オフはiPhone側の再生停止です。実際の眼鏡とAPIを使う動作は未検証です。

[日本語](README.md) · [English](README_EN.md) · [简体中文](README_ZH.md)

![TurboMetaのロゴ](rayban.png)

このリポジトリは [Turbo1123/turbometa-rayban-ai](https://github.com/Turbo1123/turbometa-rayban-ai) を基に、Ray-Ban Meta向けアプリのiOS版へ **OpenAI Realtime API、ウェイクワード、Function Calling、AI Router** を追加したものです。Live AIではQwen OmniとGemini Liveも選択できます。

元の `RaybanMetaAIAdd` とは別のプロジェクトです。[Meta Glasses iOS OpenAI](https://github.com/kirill-markin/meta-glasses-ios-openai) を設計の参考にし、**OpenAI Realtimeを初期選択**にしています。Qwen OmniとGemini Liveも設定画面から切り替えられます。参考アプリのWeb検索・長期記憶機能は未実装です。

> iOSアプリはソースコードからXcodeでビルドしてください。Android版も収録していますが、今回のOpenAI Realtime・Function Calling・AI Routerの追加はiOS版のみです。Androidの既存ウェイクワード機能は維持しています。

## まず使うには

1. **Metaの開発者設定を用意：** [Meta Wearables Developer Center](https://wearables.developer.meta.com/)でアプリを登録し、Meta App IDとClient Tokenを取得します。元アプリとは別のBundle IdentifierとURLスキームを使うため、このコピー用の登録が必要です。
2. **Xcodeで設定：** `CameraAccess.xcodeproj`を開き、SigningのTeamを選びます。`Config/LocalSecrets.example.xcconfig`を`Config/LocalSecrets.xcconfig`にコピーし、`META_APP_ID`と`CLIENT_TOKEN`を入力します。このローカルファイルはGitの追跡対象外です。
3. **iPhoneで起動：** 眼鏡をMetaアプリとペアリングし、DAT SDKプレビューモードを有効にしてから、Xcodeで実機へインストールします。
4. **AIのキーを登録：** アプリの設定画面でOpenAI APIキーを登録し、ホームのLive AIから会話を始めます。Qwen・Geminiを使う場合は各サービスのキーも登録し、Live AI Providerで切り替えます。

詳しい設定とトラブル対処は[下の手順](#ios版のセットアップ)を参照してください。APIキーなしでも画面の確認はできますが、AI会話には対応サービスのキーと通信環境が必要です。

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
- **写真・栄養解析：** 撮影、LeanEatによる食事の栄養情報とスコア表示。
- **リアルタイム翻訳：** OpenAIの翻訳専用モデルで音声と字幕を出力します。
- **画像解析モデル：** iOSのクイック画像認識、撮影後の画像認識、LeanEatはOpenAIを利用します。

英語版と中国語版のREADMEは元プロジェクト由来の参考資料です。

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
2. Xcodeで `CameraAccess.xcodeproj` を開き、署名用のTeamとBundle Identifierを確認します。このコピーには元アプリと同時インストールするため、末尾が `.openai` の別Bundle Identifierと `turbometa-openai://` のURLスキームを設定しています。Meta側にもこの識別子・スキームに対応するアプリ登録が必要です。`Config/LocalSecrets.example.xcconfig`を`Config/LocalSecrets.xcconfig`へコピーして実際の`META_APP_ID`と`CLIENT_TOKEN`を入力します。`CameraAccess/Info.plist`はその値を参照します。秘密情報をGitへコミットしないでください。
3. Meta View／Meta AIアプリで眼鏡をペアリングし、元プロジェクトの手順に従って **DAT SDKプレビューモード** を有効にします。元READMEでは、アプリ情報画面のバージョン番号を5回タップする手順が案内されています。
4. iPhoneを接続してXcodeからビルド・起動します。別Bundle Identifierのため、元アプリのKeychainに保存したAPIキーは引き継がれません。アプリの設定画面で利用するAIサービスのAPIキーを再登録します。

日本語のiPhoneではアプリの画面表示が日本語になります。必要に応じて **設定 → アプリの言語 → 日本語** を選んで再起動してください。AIの音声・テキストの言語は **設定 → 出力言語** で別に選択できます。以前保存した会話履歴やカスタム指示は自動翻訳されません。Android版の表示言語は今回の変更対象外です。

### 追加機能の設定

1. **設定 → Live AI Provider** で「OpenAI Realtime」「Alibaba Cloud Qwen Omni」「Google Gemini Live」「AI Router (Auto)」を選べます。新規インストール時の初期選択はOpenAIです。保存済みの選択がある場合はその設定を維持します。
2. **設定 → OpenAI API Key（画像・栄養・翻訳共通）** からキーを登録します。AutoでQwenを使う場合はAlibabaキー、Geminiを使う場合はGoogleキーも登録してください。
3. ウェイクワードを使う場合は **「Wake phrase: Hey Turbo」** を有効にし、マイクと音声認識の権限を許可します。眼鏡を接続してLive AI画面を開き、「Hey Turbo」と話すか、画面の「Start now」を押してください。

| 利用する機能 | 必要なキー・設定 |
| --- | --- |
| OpenAI Realtime、Function Calling、クイック画像認識、LeanEat、リアルタイム翻訳 | [OpenAIのAPIキー](https://platform.openai.com/api-keys)と利用するモデルへのアクセス権 |
| Qwen Omni | [Alibaba Cloud Model Studio](https://bailian.console.aliyun.com/) のキー。利用する地域に合わせて設定 |
| Gemini Live | [Google AI Studio](https://aistudio.google.com/apikey) のキー |
| Androidの「Jarvis」ウェイクワード | [Picovoice Console](https://console.picovoice.ai/) のAccess Key |

## 既存機能の使い方

### Quick VisionとSiri

アプリでAPIキーと眼鏡の接続を設定した後、iPhoneの「ショートカット」アプリでTurboMetaの「クイック画像認識」アクションを追加します。ショートカットに好きな名前を付け、Siriでその名前を呼ぶと、撮影・画像解析・音声読み上げを開始できます。必要に応じてiPhoneのアクションボタンやロック画面ウィジェットにも割り当てられます。初回はTurboMetaを一度開き、機能を初期化してください。

### その他の機能

Live AIはホーム画面から開き、接続後に話しかけます。クイック画像認識は撮影した場面を短く説明し、LeanEatは撮影した食事の栄養情報を推定します。栄養情報などのAI推定結果は参考情報として扱ってください。

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

2026年10月17日、変更前の版はXcode 26.6でiPhone 15 Pro向けの署名付きDebugビルド、実機へのインストール、模擬デバイスを使うカメラ統合テスト2件に成功しました。2026年10月18日、今回の変更後のiOS向けDebugビルドも成功しました。変更後の実機インストールとAI通信テストは未実施です。

このビルドでは `META_APP_ID` と `CLIENT_TOKEN` が未設定です。そのため、Ray-Ban Metaとの接続、カメラ・マイク、OpenAI/Qwen/Geminiとの会話は未検証です。これらはMeta側のアプリ登録・眼鏡のペアリング・各APIキーを設定したうえで、実機で別途確認してください。**iPhoneへのインストール成功は眼鏡上での動作確認を意味しません。**

## ライセンスと謝辞

ライセンスは[LICENSE](LICENSE)を参照してください。元プロジェクトの作者 [Turbo1123](https://github.com/Turbo1123) とMeta Wearables DAT SDKの開発元に感謝します。
