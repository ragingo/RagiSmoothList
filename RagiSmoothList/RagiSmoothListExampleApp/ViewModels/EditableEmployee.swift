//
//  EditableEmployee.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/15.
//

import Foundation
import RagiSmoothList

struct EditableEmployee: Identifiable, Hashable, RagiSmoothListCellEditable {
    var id: Int
    var name: String
    var hireDate: Date
    var canEdit: Bool

    init(employee: Employee, canEdit: Bool = false) {
        self.id = employee.id
        self.name = employee.name
        self.hireDate = employee.hireDate
        self.canEdit = canEdit
    }
}
