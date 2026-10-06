# TurboMeta v1.3.0 リリースノート

[トップページ](README.md) · [英語・中国語の元リリースノート](RELEASE_NOTES_v1.3.0_EN_ZH.md)

**元リリース日：2024年12月30日**

このページは元プロジェクトのv1.3.0時点の変更履歴を日本語でまとめたものです。現在のフォークに追加したOpenAI Realtime、ウェイクワード、Function Calling、AI Routerの説明は[トップページ](README.md#今回追加した機能)を参照してください。

## 主な変更

- **英語・中国語の画面表示：** 設定から表示言語を切り替え可能。
- **OpenRouter連携：** 複数のAIモデルを選択でき、画像対応モデルで絞り込み可能。
- **Google Gemini Live：** Qwen Omniに加えてリアルタイム音声会話の接続先を選択可能。元リリースノートでは地域による利用制限に注意が必要とされています。
- **Alibaba Cloudの地域選択：** 北京とシンガポールのエンドポイントに対応し、地域ごとにAPIキーを管理。
- **APIキー管理：** サービスごとのキーをiOS Keychainに保存。

## 当時の主要機能

| 機能 | 内容 |
| --- | --- |
| Quick Vision | Siriから起動する画像認識と音声読み上げ。 |
| Live AI | 眼鏡のカメラとマイクを使うリアルタイム会話。 |
| LeanEat | 食事の認識、栄養情報、健康スコアの表示。 |

元の動作要件はiOS 17以降、対応するRay-Ban Meta眼鏡、Meta Viewアプリの開発者向け設定です。Xcodeでソースからビルドし、アプリの設定でAPIキーを登録します。

不具合報告や元リリースの詳細は[元プロジェクトのIssues](https://github.com/Turbo1123/turbometa-rayban-ai/issues)と[英語・中国語版](RELEASE_NOTES_v1.3.0_EN_ZH.md)を参照してください。
