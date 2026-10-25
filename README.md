# RaybanMetaApp

**Ray-Ban Metaで、知りたいことを音声で確かめる。**

グラスのカメラとマイクを使い、AIとの会話、景色や文字の読み取り、翻訳、食事の栄養解析、本の要約ができるiPhoneアプリです。

## 2つのホーム画面

<table>
  <tr><th>通常表示</th><th>視覚障害者向け表示</th></tr>
  <tr>
    <td align="center"><img src="screenshots/urban/home-iphone.png" alt="通常表示：グラスの写真とLive AIの入口を配置したホーム" width="260"></td>
    <td align="center"><img src="screenshots/accessibility/home-iphone.png" alt="視覚障害者向け表示：知りたいことを自分のペースで、という見出しの直後に人物画像を配置したホーム" width="260"></td>
  </tr>
  <tr>
    <td>写真を中心に、機能をカードで選ぶデザイン。<br><a href="screenshots/urban/tools-iphone.png">機能ボタンを見る</a></td>
    <td>大きなボタンを1列に配置。文字サイズ・ダーク表示に対応し、VoiceOver用の説明を付けています。<br><a href="screenshots/accessibility/actions-iphone.png">機能ボタンを見る</a></td>
  </tr>
</table>

**設定 → ホームの表示 → 視覚障害者向け** で切り替えます。接続前は「表示の設定」から変更でき、設定は再起動後も保持されます。

※ 画像はシミュレータの画面プレビューです。「接続済み」は表示例です。画面内の写真素材はAI生成です。

## できること

| 機能 | こんなときに使えます |
| --- | --- |
| **AIと会話する** | グラスのカメラ・マイクを使い、気になることを声で質問して、音声で返答を聴きます。 |
| **景色や文字を読み取る** | グラスで撮影した画像の内容をAIで解析し、説明を聴きます。画像認識モードを選んで使えます。 |
| **外国語をリアルタイムで翻訳する** | 相手の話すことばを、設定した言語の音声と字幕で確認します。 |
| **食事の栄養を知る** | 食事の写真から、カロリーや栄養成分、健康スコアの目安を確認します。 |
| **本を要約して聴く** | 撮影したページを日本語で要約して読み上げます。長さは50〜1000文字で指定でき、再生・停止・キャンセルもできます。 |

2つの表示で利用できる機能は同じです。視覚障害者向け表示では「目の前に見えるものを知りたい」など、利用者がしたいことから選べます。会話履歴・ギャラリー・設定は下部のタブから開きます。

## 使い始めるには

1. **準備：** Ray-Ban Meta、iOS 17以降のiPhone、MacとXcode、Metaの開発用アプリ設定を用意します。
2. **インストール：** XcodeでビルドしてiPhoneへ入れ、グラスを接続します。
3. **APIキー：** アプリの設定でご自身のOpenAI APIキーを保存します。AI会話・画像認識・翻訳・栄養解析・本の要約で共用します。API利用料金がかかる場合があります。

[詳しいセットアップと使い方](docs/guide.md) · [表示切り替えの詳細](docs/accessibility-home.md)

**確認状況：** iPhone 15 Proへのインストール・起動と、本の要約の自動テスト7件に成功しています。実際のグラス接続・AI通信は未検証です。AIの説明は歩行案内や安全確認には使えません。

APIキーは端末のKeychainで保管します。キーやローカルの秘密設定をGitHubへアップロードしないでください。

---

ベース：[RaybanMeta-OpenAI](https://github.com/2ndarystorage/RaybanMeta-OpenAI) · 本の要約：[RaybanmetaSummarizeBook](https://github.com/2ndarystorage/RaybanmetaSummarizeBook) · [ライセンス](LICENSE) · [開発・検証の詳細](docs/guide.md#検証状況)
