# 視覚障害者向けのホーム表示

2026年10月25日

## 設定と動作

設定の「ホームの表示」に「視覚障害者向け」スイッチを追加しました。初期状態はオフです。オンにするとホームとウェルカムの文言、配置、配色、画像が切り替わり、再起動後も保持されます。オフにすると通常のデザインへ戻ります。グラスの接続前やMeta設定のない場合も、ウェルカムの「表示の設定」から変更できます。

表示の設定だけを切り替えます。APIキー・接続先・画像認識モード・出力言語は変更しません。VoiceOverを自動的にオンにはしません。設定値は端末内に保存し、このスイッチの状態をAIサービスへ送信する処理はありません。

## 文言と配置

「知りたいことを、自分のペースで。」を軸に、「声で質問したい」「目の前に見えるものを知りたい」「本を要約して聴きたい」「会話を訳してほしい」「食事の内容を知りたい」と、利用者が選びたいことを表現しています。援助する側からの呼びかけや、見えることだけを前提としたキャッチコピーを避けています。

各入口は従来の機能を開きます。「目の前に見えるものを知りたい」は設定済みのQuick Visionモードを利用します。常時の周囲監視、歩行案内、文字読み上げへの自動モード変更は行いません。

- 1列の大きなボタン。文字の拡大時に高さが伸び、本文とアイコンが重ならない配置。
- 写真は「知りたいことを、自分のペースで。」の直後に配置し、写真に文字を重ねない。機能を色や画像だけで区別しない。
- システムの文字サイズとライト／ダーク設定を反映。
- 見出し、接続状況、操作ボタンのラベルとヒントをアクセシビリティツリーへ提供。
- 意味のある写真には日本語の代替説明。装飾アイコンは重複して読み上げない。
- 勝手な音声再生や自動フォーカス移動を追加しない。

設計ではAppleの[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)と[VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)のガイドを参照しました。最終的な使いやすさの確認には、当事者による利用評価が必要です。

## 画像

各機能のボタンは、利用場面をイメージした[写真アイコン](use-case-icons.md)を使います。画像だけに依存せず、機能名とVoiceOver用ラベルも併記しています。

本人がスマートグラスと音声を使って本の情報に触れる、カフェでの日常の場面を生成しました。白杖を含む構図とし、本人の主体性と、何をしている場面かの分かりやすさを意識しています。写真はAI生成のコンセプト素材です。機器の効果や利用者の体験を実証する写真ではありません。

保存先：`CameraAccess/Assets.xcassets/AccessibleEveryday.imageset/accessible-everyday.png`

生成方式：組み込みの`image_gen`ツール。

最終プロンプト：

Use case: photorealistic-natural. Asset type: wide landscape 3:2 hero image for the home of an iPhone app used by blind and low-vision people and their supporters. A respectful, authentic everyday moment in a quiet contemporary Japanese cafe: an adult Japanese person with low vision wearing discreet black wayfarer smart glasses, independently holding an open book on a table and listening thoughtfully, with a folded white mobility cane resting beside their chair. No helper taking over, no medical setting, no pity or inspirational hero framing. Focus on agency and the ordinary act of accessing information with glasses and audio. Clear uncluttered composition with person, smart glasses and book readily identifiable, warm daylight, realistic skin and materials, natural colors with strong separation between subject and background, calm contemporary atmosphere. Medium-wide view with the subject and entire book inside the central two thirds, suitable for a horizontal crop. No text, no lettering, no logos, no interface or watermark. This is a realistic lifestyle image, not a screenshot. Do not imply the smart glasses replace a cane or provide navigation.

## 検証

- iOS向けビルドとiPhone 15 Pro向け署名付きビルドに成功。最新版をiPhone 15 Proへインストール。
- 実アプリのシミュレータでオンへの切り替えと再起動後の保持を確認。
- SDK非依存の画面プレビューでホームの切り替えとオフへの復帰を確認。ホームの接続状態は表示確認用の値。
- アクセシビリティツリーで見出し・ボタン・設定スイッチ・画像の説明を確認。
- プレビューで大きな文字（accessibility3）とダーク表示、見出し直後の写真と全機能カードの配置を確認。
- 既存の本の要約の自動テスト7件に成功。
- 実際のVoiceOver音声による全操作の通し評価、当事者レビュー、グラスとAPIの実通信は未実施。

スクリーンショット：

- `screenshots/accessibility/settings-iphone.png`（実アプリの表示設定）
- `screenshots/accessibility/welcome-iphone.png`（実アプリの接続前画面）
- `screenshots/accessibility/home-iphone.png`（ホームの画面プレビュー）
- `screenshots/accessibility/actions-iphone.png`（更新した機能の文言）
- `screenshots/accessibility/large-text-dark-iphone.png`（大きな文字・ダーク表示）
