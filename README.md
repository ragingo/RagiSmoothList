# RagiSmoothList

## Introduction

- SwiftUI List だと使い物にならない状況が発生したので、代替となるコンポーネントを作成
- MEMO
  - パフォーマンスの重大な問題
    - SwiftUI List のパフォーマンスが非常に悪い
      - ただの Button を大量に並べただけで、まともにスクロールできない
      - 特に顕著なのは、たまたま手元にある iPad mini 4th gen
    - List をうまく使うことでなんとか解決できないかと頑張ったが、どうにもならなかった
  - iOS 15 未満だと Pull to Refresh ができない問題

## Examples

このリポジトリにある `RagiSmoothListExampleApp` を参照してください

## Requirements

- iOS 14+
- Xcode 14.x
