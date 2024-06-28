//// Module of helper functions and types duplicated from within the main date implementation
//// because we don't want to expose them publicly but want to use them in tests.

import gleam/int
import gleam/result

import rada/date.{type Month, type Weekday}

pub type CalendarDate {
  CalendarDate(year: Int, month: Month, day: Int)
}

pub type WeekDate {
  WeekDate(week_year: Int, week_number: Int, weekday: Weekday)
}

pub type OrdinalDate {
  OrdinalDate(year: Int, ordinal_day: Int)
}

pub fn days_in_month(year: Int, month: Month) -> Int {
  case month {
    date.Jan -> 31
    date.Feb ->
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    date.Mar -> 31
    date.Apr -> 30
    date.May -> 31
    date.Jun -> 30
    date.Jul -> 31
    date.Aug -> 31
    date.Sep -> 30
    date.Oct -> 31
    date.Nov -> 30
    date.Dec -> 31
  }
}

fn is_leap_year(year: Int) -> Bool {
  modulo_unwrap(year, 4) == 0
  && modulo_unwrap(year, 100) != 0
  || modulo_unwrap(year, 400) == 0
}

fn modulo_unwrap(a: Int, b: Int) -> Int {
  int.modulo(a, b) |> result.unwrap(0)
}
