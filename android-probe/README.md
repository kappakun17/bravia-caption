# 地デジ実機検証アプリ

XRJ-75X90J / Android 12向けの検証。AI認識・音声保存・音声送信は行いません。
通常の追加アプリで、表示オーバーレイとAudioPlaybackCaptureが使えるか測定します。
ビルド・署名検証は完了。TVへのインストールと動作は未検証です。

## 手順

1. TVとPCを同じLANに接続する。
2. TVのAndroid TV OSビルドを7回押し、開発者向けオプションのUSB/ADBデバッグをオンにする。
3. TVのIPを確認。PCから `adb connect IP:5555` 。TVの接続許可で自分のPCを承認する。
4. `adb -s IP:5555 install android-probe/build/bravia-caption-probe.apk`
5. `adb -s IP:5555 shell am start -n jp.braviacaption.probe/.MainActivity`
6. アプリの①で「他のアプリの上に表示」を許可し、戻って②を押す。
7. リモコンで地デジへ戻り、画面下に仮字幕が見えるか確認する。
8. アプリへ戻り③を選び、録音権限と画面/音声共有のOS確認を許可する。
9. 地デジへ戻り、音のある番組でRMS/peak/非ゼロサンプル数を観察する。
10. 標準YouTubeでも同じ測定を行い比較する。
11. 終了時に検証アプリの「停止」を押す。デバッグも検証終了後にオフにする。

非ゼロサンプルは「何らかの内部音声が取得できた」ことだけを示します。
地デジの番組音声であることは番組の発話/無音や入力切り替えとの対応で確認してください。
地デジだけゼロでYouTubeは非ゼロなら、放送音声の経路が通常APIで取得できない可能性があります。
両方ゼロなら権限・音声形式・端末実装なども疑う必要があります。
画面キャプチャの許可を使いますが、映像のキャプチャ処理は実装していません。

## ビルド

JDK 17とAndroid SDK（build-tools 36.0.0、platform android-37.0）を使用:

```powershell
.\scripts\build-probe.ps1
```

最低API29、対象API32。Android 12の個人検証用デバッグAPKです。
公開ストア用ではありません。署名鍵とAPKはGit管理から除外。
削除はTVのアプリ設定から、または `adb -s IP:5555 uninstall jp.braviacaption.probe`。
