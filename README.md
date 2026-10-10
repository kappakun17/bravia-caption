# BRAVIA Caption

Sony XRJ-75X90J の地デジ音声を日本語字幕化するための検証プロジェクト。
最終目標はテレビ本体でのローカル認識と、リモコンからのオン／オフ。
現在は Windows PC の CPU で Nemotron 3.5 ASR Streaming 0.6B を試す段階です。

## Windows での開始

64bit Windows、PowerShell、インターネット接続が必要です。Python と NVIDIA GPU は不要です。
リポジトリのフォルダーで以下を実行します。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\make-sample.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\transcribe.ps1 -AudioPath .\samples\japanese-smoke.wav
```

setup は NVIDIA 公式 CPU ランタイム v0.2.0 を SHA-256 検証後に展開し、
ランタイムに登録された量子化モデルを取得します。約742MBのモデルとランタイムの空き容量が必要です。
保存先はこのフォルダーの `.runtime` と `.models`。ユーザーの PATH は変更しません。
初回取得後の音声認識はローカルです。音声を外部 API へ送信しません。
モデル・ランタイム・音声・認識結果は Git 管理から除外しています。

`make-sample` は Windows の Microsoft Haruka Desktop で合成音声を作ります。
この音声がない環境では、自分の PCM WAV ファイルを使用してください。
合成音声は動作確認用で、地デジのBGMや複数話者に対する精度評価には使えません。

## 自分の音声を認識

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\transcribe.ps1 -AudioPath C:\audio\japanese.wav
```

結果は `results/日時/` に保存します。計測時間には起動・モデル読み込みを含みます。
これは字幕表示の遅延や、テレビ上でのリアルタイム性能を示す数値ではありません。

## マイクで試す

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\live.ps1
```

実行すると既定のマイク入力を使います。Ctrl+C で停止。
地デジ音声の内部取得や PC 再生音声のループバックはまだ実装していません。

## 検証順序

1. PCで日本語WAV認識（本段階）
2. PCで連続入力・字幕表示・遅延測定
3. BRAVIA実機で地デジ画面への重ね表示と音声取得
4. 家庭内PCとテレビ間で字幕を送受信
5. テレビ本体へASRを移植し、RAM・処理速度・長時間動作を測定
6. オン／オフ操作と字幕設定を仕上げる

純正クイック設定への独自項目追加、内蔵地デジの音声取得、RAM 3GBでの動作は未確認。
AndroidエミュレーターではこれらのSony実機固有条件を再現できません。

## 参照・ライセンス

- [NVIDIA公式ランタイム](https://github.com/NVIDIA/NeMo-Speech.cpp)（Apache-2.0、同梱第三者ライセンスあり）
- [NVIDIA公式ASRモデル](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b)（モデル固有ライセンス参照）

外部ランタイムとモデルは本リポジトリへ再配布しません。
