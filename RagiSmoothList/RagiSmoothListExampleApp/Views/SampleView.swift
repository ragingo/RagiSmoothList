//
//  SampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import RagiSmoothList

struct SampleView: View {
    struct AlertInfo {
        let message: String
    }

    struct CellButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color.yellow : Color.white)
        }
    }

    @State private var employees: [SampleViewModel.SectionModelType] = []
    @State private var isLoading = false
    @State private var isFirstLoadFailed = false
    @State private var isMoreLoadFailed = false
    @StateObject private var viewModel: SampleViewModel
    @State private var showAlert = false
    @State private var alertInfo: AlertInfo?

    // MARK: - デバッグ用
    @State private var forceFirstLoadError = false
    @State private var forceMoreLoadError = false

    init() {
        self._viewModel = .init(wrappedValue: SampleViewModel())
    }

    var body: some View {
        VStack {
            debugView

            ZStack {
                RagiSmoothList(
                    data: $employees,
                    cellContent: { employee in
                        makeEmployeeCell(employee: employee)
                    },
                    onLoadMore: {
                        Task {
                            await viewModel.loadMore(
                                forceFirstLoadError: forceFirstLoadError,
                                forceMoreLoadError: forceMoreLoadError
                            )
                        }
                    },
                    onRefresh: {
                        Task {
                            await viewModel.refresh(forceFirstLoadError: forceFirstLoadError)
                        }
                    }
                )
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
    }

    private let checkMarkIcon = Image(systemName: "checkmark.circle.fill")

    private func makeEmployeeCell(employee: Employee) -> some View {
        RagiSmoothListButtonCell(
            label: {
                HStack(spacing: 32) {
                    Image(systemName: "\(employee.id % 50).square.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(employee.id % 2 == 0 ? Color.blue : Color.orange)

                    VStack(alignment: .leading) {
                        Text("id: \(employee.id)")
                            .font(.title3)
                        Text("name: \(employee.name)")
                            .font(.title)
                    }

                    Spacer()

                    checkMarkIcon
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.green)
                        .opacity(employee.id % 5 == 0 ? 1.0 : 0.0)
                }
                .padding()
            }
        ) {
            alertInfo = .init(message: "id: \(employee.id)")
            showAlert = true
        }
        .buttonStyle(CellButtonStyle())
    }

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

    private var debugView: some View {
        HStack(spacing: 32) {
            Toggle("初回データ取得時にエラー", isOn: $forceFirstLoadError)
                .fixedSize()
            Toggle("追加データ取得時にエラー", isOn: $forceMoreLoadError)
                .fixedSize()
        }
    }
}


struct SampleView_Previews: PreviewProvider {
    static var previews: some View {
        SampleView()
    }
}
