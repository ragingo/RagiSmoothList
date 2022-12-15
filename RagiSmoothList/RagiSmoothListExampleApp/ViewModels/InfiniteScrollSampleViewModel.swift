//
//  InfiniteScrollSampleViewModel.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import Foundation
import RagiSmoothList

final class InfiniteScrollSampleViewModel: ObservableObject {
    struct SectionType: Identifiable, Hashable {
        var id: String { hireYear }
        let hireYear: String
    }

    typealias ItemType = EditableEmployee
    typealias SectionModelType = RagiSmoothListSectionModel<SectionType, ItemType>

    enum State: Equatable {
        case initial
        case loading
        case loaded(employees: [SectionModelType])
        case deleted(employees: [SectionModelType])
        case unchanged
        case firstLoadFailed
        case moreLoadFailed
    }

    @Published private(set) var state: State = .initial

    private static let itemsPerPage = 50
    private static let intiniteLoadEnabled = true
    private static let totalItemsCount = 1000

    private var employees: [ItemType] = []
    private var infiniteSequence = (1...).lazy
    private var offset = 1

    private var hasMore: Bool {
        Self.intiniteLoadEnabled ? true : offset < Self.totalItemsCount
    }

    @MainActor
    func loadMore(forceFirstLoadError: Bool = false, forceMoreLoadError: Bool = false) async {
        state = .loading

        if forceFirstLoadError, offset == 1 {
            state = .firstLoadFailed
            return
        }

        if forceMoreLoadError {
            state = .moreLoadFailed
            return
        }

        if !hasMore {
            state = .unchanged
            return
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let employees = await Self.request(offset: offset)

        self.employees.append(contentsOf: employees.map {
            var employee = EditableEmployee(employee: $0)
            employee.canEdit = $0.id % 2 == 0
            return employee
        })
        offset += Self.itemsPerPage

        state = .loaded(employees: sections())
    }

    func refresh(forceFirstLoadError: Bool = false) async {
        offset = 1
        employees.removeAll(keepingCapacity: true)

        await loadMore(forceFirstLoadError: forceFirstLoadError)
    }

    func delete(section: Int, row: Int, employee: ItemType) {
        // 変換済みのデータを保持して効率よく削除できるようにしたい...
        // load more によって同一セクションが別タイミングで追加されることがあるので、変換済みのデータ同士を単純に結合することはできない
        // ※ 単純に結合してしまうと、 Differentiator の Diff.differencesForSectionedView を実行した際にセクション重複エラーが発生してしまう。
        //sectionedEmployees[section].items.remove(at: row)

        if let index = employees.firstIndex(of: employee) {
            employees.remove(at: index)
        }
        state = .deleted(employees: sections())
    }

    private static func request(offset: Int) async -> [Employee] {
        let range = (1...).lazy
            .filter { $0 >= offset } // from
            .filter { Self.intiniteLoadEnabled ? true : $0 <= Self.totalItemsCount } // to
            .prefix(Self.itemsPerPage)

        let employees = Array(range)
            .map {
                let year = 2022 - ($0 / 10)
                return Employee(
                    id: $0,
                    name: "emp \($0)",
                    hireDate: randomDate(year: year)
                )
            }

        return employees
    }

    private func sections() -> [SectionModelType] {
        Dictionary(grouping: employees) { employee in
            Self.toYear(from: employee.hireDate)
        }
        .sorted(by: { lhs, rhs in
            lhs.key > rhs.key
        })
        .map { key, value in
            (section: SectionType(hireYear: key), items: value)
        }
        .listSectionModels()
    }

    private static func toYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private static func randomDate(year: Int) -> Date {
        let month = Int.random(in: 1...12)
        let components = DateComponents(
            calendar: .current,
            timeZone: .current,
            year: year,
            month: month
        )
        let date = Calendar.current.date(from: components) ?? Date()
        let days = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 1

        return makeDate(year: year, month: month, day: Int.random(in: 1...days))
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(
            calendar: .current,
            timeZone: .current,
            year: year,
            month: month,
            day: day
        )
        return Calendar.current.date(from: components) ?? Date()
    }
}
