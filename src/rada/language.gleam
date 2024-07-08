//// This module provides [`Language`](date.html#Language) definitions for use with the
//// [format_with_language](date.html#format_with_language) function.

import gleam/int
import gleam/string

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
    date.Thu -> "mercoledì"
    date.Wed -> "giovedì"
    date.Fri -> "venerdì"
    date.Sat -> "sabato"
    date.Sun -> "domenica"
  }
}

fn weekday_name_short_it(weekday: Weekday) -> String {
  case weekday {
    date.Mon -> "lun"
    date.Tue -> "mar"
    date.Thu -> "mer"
    date.Wed -> "gio"
    date.Fri -> "ven"
    date.Sat -> "sab"
    date.Sun -> "dom"
  }
}

fn day_with_suffix_it(day: Int) -> String {
  int.to_string(day)
}

/// German [`Language`](date.html#Language) definition for use with the [format_with_language](date.html#format_with_language) function.
pub fn german() -> Language {
  date.Language(
    month_name: month_name_de,
    month_name_short: month_name_short_de,
    weekday_name: weekday_name_de,
    weekday_name_short: weekday_name_short_de,
    day_with_suffix: day_with_suffix_de,
  )
}

fn month_name_de(month: Month) -> String {
  case month {
    Jan -> "Januar"
    Feb -> "Februar"
    Mar -> "März"
    Apr -> "April"
    May -> "Mai"
    Jun -> "Juni"
    Jul -> "Juli"
    Aug -> "August"
    Sep -> "September"
    Oct -> "Oktober"
    Nov -> "November"
    Dec -> "Dezember"
  }
}

fn month_name_short_de(month: Month) -> String {
  month_name_de(month)
  |> string.slice(0, 3)
}

fn weekday_name_de(weekday: Weekday) -> String {
  case weekday {
    date.Mon -> "Montag"
    date.Tue -> "Dienstag"
    date.Wed -> "Mittwoch"
    date.Thu -> "Donnerstag"
    date.Fri -> "Freitag"
    date.Sat -> "Samstag"
    date.Sun -> "Sonntag"
  }
}

fn weekday_name_short_de(weekday: Weekday) -> String {
  weekday_name_de(weekday)
  |> string.slice(0, 2)
}

fn day_with_suffix_de(day: Int) -> String {
  int.to_string(day) <> "."
}
