//
//  MonthYearPickerViewModel.swift
//  grail-calendar-poc
//
//  Created by Neil Francis Hipona on 6/10/22.
//

import Foundation

extension MonthYearPickerViewModel {
  struct PickerData<T: Hashable>: Identifiable, Hashable {
    let id: UUID
    var idx: Int
    let title: String
    let value: T

    init(idx: Int, title: String, value: T) {
      self.id = UUID()
      self.idx = idx
      self.title = title
      self.value = value
    }

    static func == (lhs: MonthYearPickerViewModel.PickerData<T>, rhs: MonthYearPickerViewModel.PickerData<T>) -> Bool {
      return lhs.id == rhs.id && lhs.idx == rhs.idx && lhs.title == rhs.title && lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(idx)
      hasher.combine(title)
      hasher.combine(value)
    }
  }

  struct MonthYearData: Identifiable, Hashable {
    let id: UUID
    let month: Int
    let year: Int

    var title: String { // MMMMyyyy
      let monthName = Calendar.current.monthSymbols[month]
      return "\(monthName) \(year)"
    }

    init(month: Int, year: Int) {
      self.id = UUID()
      self.month = month
      self.year = year
    }

    static func == (lhs: MonthYearData, rhs: MonthYearData) -> Bool {
      return lhs.id == rhs.id && lhs.month == rhs.month && lhs.year == rhs.year
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(month)
      hasher.combine(year)
    }
  }
}

class MonthYearPickerViewModel: ObservableObject {
  private let minYear: Int // offset limit from the current year
  private let maxYear: Int // offset limit from the current year

  let monthsData: [PickerData<Int>]
  let yearsData: [PickerData<Int>]

  init(minYear: Int = 5, maxYear: Int = 10) {
    self.minYear = minYear
    self.maxYear = maxYear

    self.monthsData = MonthYearPickerViewModel.generateMonths()
    self.yearsData = MonthYearPickerViewModel.generateYears(minYear: minYear, maxYear: maxYear)
  }
}

extension MonthYearPickerViewModel {
  class  func generateMonths() -> [PickerData<Int>] {
    var data: [PickerData<Int>] = []
    for (idx, month) in Calendar.current.monthSymbols.enumerated() {
      data.append(PickerData(idx: idx, title: month, value: idx))
    }
    return data
  }

  class func generateYears(minYear: Int = 5, maxYear: Int = 10) -> [PickerData<Int>] {
    var data: [PickerData<Int>] = []
    let currentYear = Calendar.current.dateComponents([.year], from: Date()).year!

    let minYearLimit = currentYear - minYear
    for i in minYearLimit..<currentYear {
      data.append(PickerData(idx: i, title: i.description, value: i))
    }

    let maxYearLimit = currentYear + maxYear
    for i in currentYear...maxYearLimit {
      data.append(PickerData(idx: i, title: i.description, value: i))
    }

    return data
  }
}
