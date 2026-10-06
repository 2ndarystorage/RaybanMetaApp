# TurboMeta Android版

[トップページに戻る](../README.md) · [英語・中国語の元README](README_EN_ZH.md)

Ray-Ban Meta向けAIアシスタントのAndroid版です。元のAndroid READMEはv1.4.0時点の説明で、リポジトリ全体のREADMEではAndroid v1.5.0と案内されています。最新の機能はソースコードも確認してください。

## 主な機能

| 機能 | 内容 |
| --- | --- |
| Live AI | 眼鏡を使ったリアルタイム音声会話。Alibaba Qwen OmniとGoogle Gemini Liveを選択できます。 |
| Quick Vision | 眼鏡のカメラ画像をAIで解析します。「Jarvis」のウェイクワードにも対応しています。 |
| 画像解析モデル | Alibaba DashscopeとOpenRouterから選択できます。 |
| RTMP配信 | 眼鏡の一人称映像をRTMP対応の配信先へ送れます。H.264、ビットレート調整、スマートフォン上のプレビューに対応します。 |

**iOS版で今回追加したOpenAI Realtime、Function Calling、AI Routerは、Android版にはまだ移植していません。** Androidの「Jarvis」は、iOS版の「Hey Turbo」とは別の実装です。

## 動作環境と設定

- Android 8.0（API 26）以上と、Meta Viewアプリでペアリング済みのRay-Ban Meta眼鏡が必要です。
- Qwenによる会話・画像解析には[AlibabaのAPIキー](https://help.aliyun.com/zh/model-studio/get-api-key)が必要です。
- OpenRouterの画像解析には[OpenRouterのAPIキー](https://openrouter.ai/keys)が必要です。
- Gemini Liveには[Google AI StudioのAPIキー](https://aistudio.google.com/apikey)が必要です。
- 「Jarvis」の検出には[Picovoice Console](https://console.picovoice.ai/)で取得したAccess Keyが必要です。アプリの設定からQuick Vision用のPicovoiceキーを登録してください。

ウェイクワードを有効にすると、マイクを継続的に使用する前景サービスと通知が動作します。電池消費に注意してください。元のREADMEではGemini Liveは十分に実機検証されていないとされています。

## ビルド

`android` ディレクトリでGradle Wrapperを実行します。

```bash
./gradlew assembleDebug
```

リリースビルドには `./gradlew assembleRelease`、接続端末へのデバッグ版インストールには `./gradlew installDebug` を利用します。配布や署名に必要な設定は利用環境で行ってください。

## ライセンス

[ルートのライセンス](../LICENSE)を参照してください。詳細な変更履歴と元の説明は[英語・中国語のREADME](README_EN_ZH.md)に残しています。
