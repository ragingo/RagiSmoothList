//
//  SampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import RagiSmoothList

struct InfiniteScrollSampleView: View {
    struct AlertInfo {
        let message: String
    }

    struct CellButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color.yellow : nil)
        }
    }

    @State private var employees: [InfiniteScrollSampleViewModel.SectionModelType] = []
    @State private var isLoading = false
    @State private var isFirstLoadFailed = false
    @State private var isMoreLoadFailed = false
    @StateObject private var viewModel: InfiniteScrollSampleViewModel
    @State private var showAlert = false
    @State private var alertInfo: AlertInfo?
    @State private var scrollToTop = false

    // MARK: - デバッグ用
    @State private var isDebugMenuExpanded = false
    @State private var forceFirstLoadError = false
    @State private var forceMoreLoadError = false

    init() {
        self._viewModel = .init(wrappedValue: InfiniteScrollSampleViewModel())
    }

    var body: some View {
        VStack {
            debugView

            Button {
                scrollToTop = true
            } label: {
                Text("\(Image(systemName: "arrow.up.circle")) scroll to top")
            }


            RagiSmoothList(
                data: $employees,
                listConfiguration: .init(
                    hasSeparator: true,
                    separatorInsets: EdgeInsets(),
                    separatorColor: .red,
                    canRowDelete: true
                ),
                sectionContent: { section in
                    makeSection(section: section)
                },
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
                },
                onDeleting: { employee in
                },
                onDeleted: { employee in
                    viewModel.delete(target: employee)
                    alertInfo = .init(message: "[removed] id: \(employee.id)")
                    showAlert = true
                }
            )
            .scrollToTop($scrollToTop)
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

    private let calendarIcon = Image(systemName: "calendar")
    private let checkMarkIcon = Image(systemName: "checkmark.circle.fill")

    private func makeSection(section: InfiniteScrollSampleViewModel.SectionType) -> some View {
        Button {
        } label: {
            HStack {
                calendarIcon
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.purple)
                Text("hire year: \(section.hireYear)")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            .background(Color(red: 176/255, green: 237/255, blue: 148/255))
        }
    }

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private func makeEmployeeCell(employee: Employee) -> some View {
        RagiSmoothListButtonCell(
            label: {
                HStack(spacing: 16) {
                    Text("id: \(String(employee.id))")
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.orange)
                        )

                    VStack(alignment: .leading) {
                        Text("\(employee.name)")
                            .font(.title2)
                        Text("hire date: \(employee.hireDate, formatter: Self.dateFormatter)")
                            .font(.subheadline)
                    }

                    Spacer()

                    checkMarkIcon
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.green)
                        .opacity(employee.id % 5 == 0 ? 1.0 : 0.0)
                }
                .padding()
                .contentShape(Rectangle())
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
        Expander(
            isExpanded: $isDebugMenuExpanded,
            header: { isExpanded in
                ExpanderHeader(
                    isExpanded: isExpanded,
                    label: {
                        Text("\(Image(systemName: "gearshape.fill")) Debug Menu")
                    },
                    toggleIcon: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                    }
                )
                .padding()
            },
            content: { _ in
                VStack {
                    Toggle("初回データ取得時にエラー", isOn: $forceFirstLoadError)
                        .fixedSize()
                    Toggle("追加データ取得時にエラー", isOn: $forceMoreLoadError)
                        .fixedSize()
                }
                .padding()
            }
        )
        .background(Color.blue.opacity(0.3))
    }
}

struct SampleView_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollSampleView()
    }
}
