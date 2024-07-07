//// This module provides [`Language`](date.html#Language) definitions for use with the
//// [format_with_language](date.html#format_with_language) function.

import gleam/int

import rada/date.{
  type Language, type Month, type Weekday, Apr, Aug, Dec, Feb, Jan, Jul, Jun,
  Mar, May, Nov, Oct, Sep,
}

/// Italian [`Language`](date.html#Language) definition for use with the [format_with_language](date.html#format_with_language) function.
pub fn italian() -> Language {
  date.Language(
    month_name: month_name_it,
    month_name_short: month_name_short_it,
    weekday_name: weekday_name_it,
    weekday_name_short: weekday_name_short_it,
    day_with_suffix: day_with_suffix_it,
  )
}

fn month_name_it(month: Month) -> String {
  case month {
    Jan -> "gennaio"
    Feb -> "febbraio"
    Mar -> "marzo"
    Apr -> "aprile"
    May -> "maggio"
    Jun -> "giugno"
    Jul -> "luglio"
    Aug -> "agosto"
    Sep -> "settembre"
    Oct -> "ottobre"
    Nov -> "novembre"
    Dec -> "dicembre"
  }
}

fn month_name_short_it(month: Month) -> String {
  case month {
    Jan -> "gen"
    Feb -> "feb"
    Mar -> "mar"
    Apr -> "apr"
    May -> "mag"
    Jun -> "giu"
    Jul -> "lug"
    Aug -> "ago"
    Sep -> "set"
    Oct -> "ott"
    Nov -> "nov"
    Dec -> "dic"
  }
}

fn weekday_name_it(weekday: Weekday) -> String {
  case weekday {
    date.Mon -> "lunedì"
    date.Tue -> "martedì"
    date.Wed -> "mercoledì"
    date.Thu -> "giovedì"
    date.Fri -> "venerdì"
    date.Sat -> "sabato"
    date.Sun -> "domenica"
  }
}

fn weekday_name_short_it(weekday: Weekday) -> String {
  case weekday {
    date.Mon -> "lun"
    date.Tue -> "mar"
    date.Wed -> "mer"
    date.Thu -> "gio"
    date.Fri -> "ven"
    date.Sat -> "sab"
    date.Sun -> "dom"
  }
}

fn day_with_suffix_it(day: Int) -> String {
  int.to_string(day)
}
