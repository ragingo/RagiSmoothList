//
//  SampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import RagiSmoothList
import SwiftUI

struct InfiniteScrollSampleView: View {
    struct AlertInfo {
        let message: String
    }

    @State private var employees: [InfiniteScrollSampleViewModel.SectionModelType] = []
    @State private var isLoading = false
    @State private var isFirstLoadFailed = false
    @State private var isMoreLoadFailed = false
    @StateObject private var viewModel: InfiniteScrollSampleViewModel
    @State private var showAlert = false
    @State private var alertInfo: AlertInfo?
    @State private var scrollToTop = false
    @State private var searchText = ""

    // MARK: - デバッグ用
    @State private var isDebugMenuExpanded = false
    @State private var forceFirstLoadError = false
    @State private var forceMoreLoadError = false

    init() {
        self._viewModel = .init(wrappedValue: InfiniteScrollSampleViewModel())
    }

    var body: some View {
        VStack {
            DebugView(
                forceFirstLoadError: $forceFirstLoadError,
                forceMoreLoadError: $forceMoreLoadError
            )

            Button {
                scrollToTop = true
            } label: {
                Text("\(Image(systemName: "arrow.up.circle")) scroll to top")
            }

            HStack {
                Text("filter text:")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text(searchText)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)

            RagiSmoothList(
                data: $employees,
                listConfiguration: .init(
                    separator: .init(isVisible: true, insets: .init(), color: .red),
                    edit: .init(
                        deleteButtonBackgroundColor: lightOrange,
                        deleteButtonImage: .remove
                    ),
                    animation: .init(mode: .fade)
                ),
                sectionHeaderContent: { section, _ in
                    SectionHeader(hireYear: section.hireYear)
                },
                sectionFooterContent: { _, items in
                    SectionFooter(subtotal: items.count)
                },
                cellContent: { employee in
                    EmployeeCell(employee: employee) {
                       alertInfo = .init(message: "id: \(employee.id)")
                       showAlert = true
                    }
                }
            )
            .scrollToTop($scrollToTop)
            .refreshable {
                Task {
                    await viewModel.refresh(forceFirstLoadError: forceFirstLoadError)
                }
            }
            .searchable(text: $searchText, placeholder: "search employees")
            .onLoadMore {
                Task {
                    await viewModel.loadMore(
                        forceFirstLoadError: forceFirstLoadError,
                        forceMoreLoadError: forceMoreLoadError
                    )
                }
            }
            .onRowDeleted { _, _, section, item in
                viewModel.delete(section: section, item: item)
            }
            .onChange(of: searchText) { _ in
                viewModel.filter(text: searchText)
            }
            .alert(isPresented: $showAlert) {
                if let alertInfo {
                    return Alert(title: Text(alertInfo.message))
                }
                assertionFailure()
                return Alert(title: Text(""))
            }
            .overlay(
                moreLoadingState
                    .opacity(isLoading ? 1.0 : 0.0),
                alignment: .bottom
            )
            .overlay(
                // MEMO: タップを貫通させたい
                firstLoadErrorState
                    .opacity(isFirstLoadFailed ? 1.0 : 0.0),
                alignment: .center
            )
            .overlay(
                moreLoadErrorState
                    .opacity(isMoreLoadFailed ? 1.0 : 0.0)
                    .padding(),
                alignment: .bottom
            )
            .onAppear {
                Task {
                    await viewModel.loadMore()
                }
            }
            .onChange(of: viewModel.state) { state in
                switch state {
                case .initial:
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                case .loading:
                    isLoading = true
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                case .loaded(let employees):
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                    self.employees = employees
                case .deleted(let employees):
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                    self.employees = employees
                case .filtered(let employees):
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                    self.employees = employees
                case .unchanged:
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = false
                case .firstLoadFailed:
                    isLoading = false
                    isFirstLoadFailed = true
                    isMoreLoadFailed = false
                    self.employees = []
                case .moreLoadFailed:
                    isLoading = false
                    isFirstLoadFailed = false
                    isMoreLoadFailed = true
                }
            }
        }
    }

    private let lightOrange = Color(red: 254.0 / 255.0, green: 216.0 / 255.0, blue: 177.0 / 255.0)

    private var moreLoadingState: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }

    private var firstLoadErrorState: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            Text("エラー発生")
                .font(.title)
        }
    }

    private var moreLoadErrorState: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
            Text("エラー発生")
                .font(.title)
        }
    }
}

struct SampleView_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollSampleView()
    }
}
