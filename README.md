# RagiSmoothList

## Introduction

標準のリストコンポーネントで機能不足やパフォーマンス問題に遭遇した。  
それらの問題を標準コンポーネントの使い方だけで解決するのは非常に困難だったので、  
`UITableView` の力を借りて代替となるコンポーネントを作成した。

できること

- Smooth Scroll
- Pull to Refresh
- Pagenation

<details>
<summary>MEMO</summary>

- `List` の内部で使われているものについては `Instruments` で確認した
  - iOS SDK 16 and iOS 16 -> `UICollectionView`
  - iOS SDK 16 and iOS 15 -> `UITableView`
  - iOS SDK 15 and iOS 16 -> `UITableView`
  - iOS SDK 15 and iOS 15 -> `UITableView`
- パフォーマンスの重大な問題
  - `List` or `List + ForEach` or `ScrollView + LazyVStack + ForEach`
    - `Button` を大量に並べただけで、まともにスクロールできない
      - `Text` に変更するだけで滑らかにスクロールできる...
      - 特に顕著なのは `iPad mini 4th gen`
      - `iPhone 12 Pro` でも、10,000件中 1,000 件を超えた辺りからスクロールが低速になる
  - `List` をうまく使うことでなんとか解決できないかと頑張ったが、どうにもならなかった
- 機能不足の問題
  - Pull to Refresh
    - `List` and iOS 15 未満だと `refreshable` が使えない
  - Load More
    - スクロール領域の終端に到達した際の追加ロードの仕組みがない
    - ※ UIKit にも無い
  - セパレータのデザイン変更
    - `List` and iOS 15 未満だと `listRowSeparator` が使えない
    - `List` and iOS 15 未満だと `listRowSeparatorTint` が使えない

</details>

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ragingo/RagiSmoothList.git")
]
```

## Usage

```swift
RagiSmoothList(
    data: $shops,
    listConfiguration: .init(
        hasSeparator: false,
        canRowDelete: true,
        separatorColor: .red,
        separatorInsets: .init()
    ),
    sectionContent: { section in Text(section.genre) },
    cellContent: { shop in Text(shop.name) },
    onLoadMore: {
        loadMore()
    },
    onRefresh: {
        refresh()
    }
)
```

## Examples

このリポジトリにある `RagiSmoothListExampleApp` を参照してください

## Requirements

- iOS 14+
- Xcode 14.x
