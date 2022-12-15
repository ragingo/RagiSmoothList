//
//  EditableEmployee.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/15.
//

import Foundation
import RagiSmoothList

struct EditableEmployee: Identifiable, Hashable, RagiSmoothListCellEditable {
    private let employee: Employee

    var id: Int { employee.id }
    var name: String { employee.name }
    var hireDate: Date { employee.hireDate }
    var canEdit: Bool = false

    init(employee: Employee) {
        self.employee = employee
    }
}
