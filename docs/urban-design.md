# Urban eyewear home design

2026-10-18

ホームと接続前の画面を、グラスの黒いフレーム、レンズの透け感、都会の建築と自然光を軸に変更。

- 背景：温かみのあるアイボリー。文字：墨色。接続インジケータ：落ち着いたモスグリーン。
- 機能アイコン：2026年10月26日、利用場面を表す[実写調の画像](use-case-icons.md)に変更。ナビゲーションにはSF Symbolsとオリジナルのグラス形状を使用。
- 書体：丸いシステム書体から標準システム書体へ。日本語の読みやすさを優先し、英語の小見出しに等幅書体を使用。
- 機能：Live AIを写真カードに、画像認識・翻訳・LeanEat・本の要約を4枚のカードに配置。読書の写真カードからも本の要約を開ける。
- アクセシビリティ：各機能に読み上げラベル。大きなアクセシビリティ文字サイズでは機能カードを1列に変更。動きを減らす設定では拡縮アニメーションを無効化。
- 起動：Meta SDK初期化失敗時は未初期化のシングルトンへアクセスせずウェルカムを表示し、接続ボタンから設定の確認を案内。

## 保存した画像

生成方式：組み込みの `image_gen` ツール。画像はAI生成の実写調コンセプト素材で、公式の商品写真ではありません。

- `CameraAccess/Assets.xcassets/UrbanGlassesHero.imageset/urban-glasses.png`
- `CameraAccess/Assets.xcassets/UrbanReading.imageset/urban-reading.png`

## 最終生成プロンプト

### UrbanGlassesHero

Use case: photorealistic-natural. Asset type: premium iPhone smart-glasses app home hero, landscape 3:2 photograph. Create a sophisticated editorial photograph of matte black wayfarer style smart glasses resting on a dark charcoal stone ledge in a contemporary Tokyo city setting. Glasses are the clear hero in the right-center of frame, realistic camera detail subtly visible in the frame corners, carefully crafted black acetate and dark lenses. Behind them: softly out-of-focus modern glass architecture, a little warm afternoon sunlight reflecting off windows, restrained urban atmosphere. Shot on a real full-frame camera, 85mm lens, tactile material detail, natural reflections, rich film shadows, quiet cinematic luxury, warm ivory highlights, muted colors, no saturated neon. Leave the left third and bottom area naturally dark and simple for white interface typography, but generate NO text, NO lettering, NO logos, NO interface, NO watermark. Final asset is a photograph, not a UI mockup.

### UrbanReading

Use case: photorealistic-natural. Asset type: wide 3:2 editorial photograph for a refined reading feature in an iPhone app. An open Japanese book with fine unreadable print, a small black espresso cup and matte black sunglasses on a dark walnut table by the window of a quiet modern Tokyo cafe, afternoon light, softly blurred modern city architecture outside. Real photograph, full frame camera, restrained warm film tones, rich dark shadows, tactile paper and wood, understated urban sophistication. Composition: book in the right half, left half softly dark with room for light UI text. No legible words, no added typography, no graphics, no interface, no logos, no watermark.

## 確認

- Xcode 26.6、接続したiPhone 15 Pro向け署名付きDebugビルドに成功。
- SDKに依存しない表示用アプリで、ホーム・ウェルカムのiPhone 17 Proサイズを目視確認。
- スクリーンショット：`screenshots/urban/home-iphone.png`、`screenshots/urban/welcome-iphone.png`。ホームの接続済み表示はプレビュー用の値。
- 統合アプリのシミュレータで本の要約テスト7件すべて成功。
- iPhone 15 Proへ最新版をインストールし、起動に成功。
- 実際のグラスとAPIの通信・音声は未検証。
