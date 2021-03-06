//
//  CustomCalendarModel.swift
//  grail-calendar-poc
//
//  Created by Neil Francis Hipona on 6/9/22.
//

import Foundation
import SwiftUI

extension CustomCalendarModel {
  enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var description: String {
      switch self {
      case .sunday:
        return "Sunday"
      case .monday:
        return "Monday"
      case .tuesday:
        return "Tuesday"
      case .wednesday:
        return "Wednesday"
      case .thursday:
        return "Thursday"
      case .friday:
        return "Friday"
      case .saturday:
        return "Saturday"
      }
    }
  }
}

extension CustomCalendarModel {
  enum RowState {
    case `default`
    case rejected
    case warning

    var stateColor: Color {
      switch self {
      case .warning:
        return .orange
      case .rejected:
        return .red
      default:
        return .clear
      }
    }
  }

  struct DayModel {
    let id: UUID
    let date: Date?
    let number: Int
    let isSelected: Bool

    var isCurrentDate: Bool {
      if let date = date {
        let isCurrent = CustomCalendarModel.calendar.isDateInToday(date)
        return isCurrent
      }

      return false
    }

    init(id: UUID = UUID(), date: Date? = nil, number: Int, isSelected: Bool = false) {
      self.id = id
      self.date = date
      self.number = number
      self.isSelected = isSelected
    }

    func setSelected(isSelected: Bool) -> Self {
      .init(id: id, date: date, number: number, isSelected: isSelected)
    }
  }

  struct DayRowModel {
    let rows: [DayModel]
    let state: RowState

    var isRowActive: Bool {
      return !rows.filter { $0.isSelected }.isEmpty
    }
  }
}

extension CustomCalendarModel {
  static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = .current
    calendar.timeZone = .current
    return calendar
  }()
}

class CustomCalendarModel: ObservableObject {
  private let formatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.setLocalizedDateFormatFromTemplate("EEEEMMMMdyyyy")
    return dateFormatter
  }()

  @Published var date: Date
  @Published var activeMonth: Date

  @Published var dates: [DayRowModel] = []
  @Published var datesTempLeft: [DayRowModel] = []
  @Published var datesTempRight: [DayRowModel] = []
  @Published var monthYear: MonthYearPickerViewModel.MonthYearData

  init(initialDate: Date = .now) {
    self.date = initialDate
    self.activeMonth = initialDate

    let month = CustomCalendarModel.calendar.component(.month, from: initialDate)
    let year = CustomCalendarModel.calendar.component(.year, from: initialDate)
    let monthIndex = month - 1
    self.monthYear = .init(month: monthIndex, year: year)

    generateTempCollectionPage()
  }
}

extension CustomCalendarModel {
  var currentMonthYear: String {
    // MMMMyyyy
    return monthYear.title
  }

  func startOfDayInCurrentWeek(_ calendar: Calendar = .current, day: Int = 1, inMonth month: Int, inYear: Int) -> Weekday {
    var weekdaySubject = DateComponents(calendar: calendar, timeZone: .current)
    weekdaySubject.day = day
    weekdaySubject.month = month
    weekdaySubject.year = inYear

    let weekdayDate = calendar.date(from: weekdaySubject)!
    let weekday = calendar.component(.weekday, from: weekdayDate)
    return Weekday(rawValue: weekday)!
  }
}

extension CustomCalendarModel {
  func selectDate(with sd: DayModel) {
    if let d = sd.date {
      print("selectDated: ", sd.number)
      date = d
    }

    var datesTmp: [DayRowModel] = []
    for d in dates {
      let rows = d.rows.map { d -> DayModel in
        let isSelected = d.id == sd.id
        return d.setSelected(isSelected: isSelected)
      }

      datesTmp.append(.init(rows: rows, state: .default))
    }
    dates = datesTmp
  }

  func generateTempCollectionPage() {
    let monthNumberConstant = monthYear.month + 1

    let newIndexLeft = monthNumberConstant - 1
    let isPreviousYear = newIndexLeft < 0
    let previousMonth = isPreviousYear ? 11 : newIndexLeft
    let yearTemplateLeft = isPreviousYear ? monthYear.year - 1 : monthYear.year
    datesTempLeft = CustomCalendarModel.collectDaysPerRow(CustomCalendarModel.calendar, selectedDate: date, forMonth: previousMonth, inYear: yearTemplateLeft)

    // current timeline
    dates = CustomCalendarModel.collectDaysPerRow(CustomCalendarModel.calendar, selectedDate: date, forMonth: monthNumberConstant, inYear: monthYear.year)

    // future timeline
    let newIndexRight = monthNumberConstant + 1
    let isNewYear = newIndexRight > 12
    let nextMonth = isNewYear ? 1 : newIndexRight
    let yearTemplateRight = isNewYear ? monthYear.year + 1 : monthYear.year
    datesTempRight = CustomCalendarModel.collectDaysPerRow(CustomCalendarModel.calendar, selectedDate: date, forMonth: nextMonth, inYear: yearTemplateRight)
  }
}

extension CustomCalendarModel {
  class func dateRange(_ calendar: Calendar = .current, forMonth month: Int, inYear year: Int) -> ClosedRange<Int> {
    var start = DateComponents(calendar: calendar, timeZone: .current)
    start.day = 1
    start.month = month
    start.year = year

    var end = DateComponents(calendar: calendar, timeZone: .current)
    end.day = 1
    end.month = month + 1
    end.year = year

    return 1...calendar.dateComponents([.day], from: start, to: end).day!
  }

  class func generateDays(_ calendar: Calendar = .current, selectedDate: Date? = .now, forMonth month: Int, inYear: Int) -> [DayModel] {
    var dComponents = DateComponents(calendar: calendar, timeZone: .current)
    dComponents.day = 1
    dComponents.month = month
    dComponents.year = inYear

    let startDate = calendar.date(from: dComponents)!
    let range = dateRange(calendar, forMonth: month, inYear: inYear)
    let dayStartInWeek = Calendar.current.component(.weekday, from: startDate)

    var days: [DayModel] = []

    for _ in 1..<dayStartInWeek { // add offset
      days.append(DayModel(number: -1))
    }

    var dayComponents = DateComponents(calendar: calendar, timeZone: .current)
    dayComponents.calendar = calendar
    dayComponents.month = month
    dayComponents.year = inYear

    for i in range {
      dayComponents.day = i

      if let date = calendar.date(from: dayComponents) {
        var isSelected = false
        if let selectedDate = selectedDate {
          isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        }
        let model = DayModel(date: date, number: i, isSelected: isSelected)
        days.append(model)
      }
    }

    return days
  }

  class func collectDaysPerRow(_ calendar: Calendar = .current, selectedDate: Date? = nil, forMonth month: Int, inYear: Int) -> [DayRowModel] {
    let days = generateDays(calendar, selectedDate: selectedDate, forMonth: month, inYear: inYear)

    var daysCollection: [DayRowModel] = []
    var collectionIndex: Int = 0

    for _ in 1...6 {
      var daysRow: [DayModel] = []
      for _ in 1...7 {
        if collectionIndex < days.count {
          daysRow.append(days[collectionIndex])
          collectionIndex += 1
        }
      }

      if !daysRow.isEmpty {
        if daysRow.count < 7 {
          let fillCount = 7 - daysRow.count
          for _ in 1...fillCount { // add offset
            daysRow.append(DayModel(number: -1))
          }
        }

        daysCollection.append(DayRowModel(rows: daysRow, state: .default))
      }
    }

    return daysCollection
  }
}
