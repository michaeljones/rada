//// This module provides a simple [`Date`](#Date) type for working with dates without times or zones.
////
//// The module uses the [Rata Die][ratadie] system to represent dates in the standard Gregorian Calendar.
//// The number 1 represents the date **1 January 0001** and all other dates are represented as positive
//// or negative numbers relative to that date.
////
//// [ratadie]: https://en.wikipedia.org/wiki/Rata_Die

import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/order.{type Order}
import gleam/result
import gleam/string
import nibble
import nibble/lexer as nibble_lexer

import rada/date/parse.{Dash, Digit, TimeToken, WeekToken} as days_parse
import rada/date/pattern.{type Token, Field, Literal}

/// Represents the 12 months of the year.
pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

/// Represents the 7 days of the week.
pub type Weekday {
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
  Sun
}

type RataDie =
  Int

/// Represents a date.
///
/// The internal storage is a single `Int` using the [Rata Die][ratadie] system. The
/// number 1 represents the date **1 January 0001** and all other dates are represented
/// as positive or negative numbers relative to that date.
///
/// [ratadie]: https://en.wikipedia.org/wiki/Rata_Die
pub opaque type Date {
  RD(RataDie)
}

/// [Rata Die][ratadie] where the number 1 represents the date **1 January 0001**.
/// [Rata Die][ratadie] is a system for assigning numbers to calendar days,
/// 
/// You can losslessly convert a `Date` to and from an `Int` representing the date
/// in Rata Die. This makes it a convenient representation for transporting dates
/// or using them as comparables. For all date values:
/// 
/// ```gleam
/// { date |> to_rata_die |> from_rata_die } == date
/// ```
///
/// [ratadie]: https://en.wikipedia.org/wiki/Rata_Die
pub fn from_rata_die(rd: Int) -> Date {
  RD(rd)
}

/// Convert a date to its number representation in Rata Die (see
/// [`from_rata_die`](#from_rata_die)). For all date values:
/// 
/// ```gleam
/// { date |> to_rata_die |> from_rata_die } == date
/// ```
pub fn to_rata_die(date: Date) -> Int {
  let RD(rd) = date
  rd
}

// Calculations

fn is_leap_year(year: Int) -> Bool {
  modulo_unwrap(year, 4) == 0
  && modulo_unwrap(year, 100) != 0
  || modulo_unwrap(year, 400) == 0
}

fn days_before_year(year1: Int) -> Int {
  let year = year1 - 1
  let leap_years =
    floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400)

  365 * year + leap_years
}

/// The weekday number (1–7), beginning with Monday.
///
/// ```gleam
/// from_calendar_date(2020, 03, 04) |> weekday_number
/// // -> 3
/// ```
pub fn weekday_number(date: Date) -> Int {
  let RD(rd) = date
  case modulo_unwrap(rd, 7) {
    0 -> 7
    n -> n
  }
}

fn days_before_week_year(year: Int) -> Int {
  let jan4 = days_before_year(year) + 4
  jan4 - weekday_number(RD(jan4))
}

fn is_53_week_year(year: Int) -> Bool {
  let wdn_jan1 = weekday_number(first_of_year(year))

  wdn_jan1 == 4 || { wdn_jan1 == 3 && is_leap_year(year) }
}

/// The calendar year.
///
/// ```gleam
/// from_calendar_date(2020, 03, 04) |> year
/// // -> 2020
/// ```
pub fn year(date: Date) -> Int {
  let RD(rd) = date
  let #(n400, r400) =
    // -- 400 * 365 + 97
    div_with_remainder(rd, 146_097)

  let #(n100, r100) =
    // -- 100 * 365 + 24
    div_with_remainder(r400, 36_524)

  let #(n4, r4) =
    // -- 4 * 365 + 1
    div_with_remainder(r100, 1461)

  let #(n1, r1) = div_with_remainder(r4, 365)

  let n = case r1 == 0 {
    True -> 0
    False -> 1
  }

  n400 * 400 + n100 * 100 + n4 * 4 + n1 + n
}

fn first_of_year(year: Int) -> Date {
  RD(days_before_year(year) + 1)
}

fn first_of_month(year: Int, month: Month) -> Date {
  RD(days_before_year(year) + days_before_month(year, month) + 1)
}

// From parts (clamps out-of-range values)

/// Create a date from an [ordinal date][ordinaldate]: a year and day of the
/// year. Out-of-range day values will be clamped.
/// 
/// ```gleam
/// from_ordinal_date(2018, 269)
/// ```
/// 
/// [ordinaldate]: https://en.wikipedia.org/wiki/Ordinal_date
pub fn from_ordinal_date(year: Int, ordinal: Int) -> Date {
  let days_in_year = case is_leap_year(year) {
    True -> 366
    False -> 365
  }

  RD(days_before_year(year) + int.clamp(ordinal, 1, days_in_year))
}

/// Create a date from a [calendar date][gregorian]: a year, month, and day of
/// the month. Out-of-range day values will be clamped.
/// 
/// ```gleam
/// from_calendar_date(2018, Sep, 26)
/// ```
/// 
/// [gregorian]: https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar
pub fn from_calendar_date(year: Int, month: Month, day: Int) -> Date {
  RD(
    days_before_year(year)
    + days_before_month(year, month)
    + int.clamp(day, 1, days_in_month(year, month)),
  )
}

/// Create a date from an [ISO week date][weekdate]: a week-numbering year,
/// week number, and weekday. Out-of-range week number values will be clamped.
/// 
/// ```gleam
/// from_week_date(2018, 39, Wed)
/// ```
/// 
/// [weekdate]: https://en.wikipedia.org/wiki/ISO_week_date
pub fn from_week_date(
  week_year: Int,
  week_number: Int,
  weekday: Weekday,
) -> Date {
  let weeks_in_year = case is_53_week_year(week_year) {
    True -> 53
    False -> 52
  }

  RD(
    days_before_week_year(week_year)
    + { { int.clamp(week_number, min: 1, max: weeks_in_year) - 1 } * 7 }
    + weekday_to_number(weekday),
  )
}

// From numbers (fails on out-of-range values)

fn from_ordinal_parts(year: Int, ordinal: Int) -> Result(Date, String) {
  let days_in_year = case is_leap_year(year) {
    True -> 366
    False -> 365
  }

  case !is_between_int(ordinal, 1, days_in_year) {
    True -> {
      Error(
        "Invalid ordinal date: "
        <> { "ordinal-day " <> int.to_string(ordinal) <> " is out of range" }
        <> { " (1 to " <> int.to_string(days_in_year) <> ")" }
        <> { " for " <> int.to_string(year) }
        <> {
          "; received (year "
          <> int.to_string(year)
          <> ", ordinal-day "
          <> int.to_string(ordinal)
          <> ")"
        },
      )
    }
    False -> {
      Ok(RD(days_before_year(year) + ordinal))
    }
  }
}

fn from_calendar_parts(
  year: Int,
  month_number: Int,
  day: Int,
) -> Result(Date, String) {
  case
    is_between_int(month_number, 1, 12),
    is_between_int(day, 1, days_in_month(year, number_to_month(month_number)))
  {
    False, _ -> {
      Error(
        "Invalid date: "
        <> { "month " <> int.to_string(month_number) <> " is out of range" }
        <> " (1 to 12)"
        <> {
          "; received (year "
          <> int.to_string(year)
          <> ", month "
          <> int.to_string(month_number)
          <> ", day "
          <> int.to_string(day)
          <> ")"
        },
      )
    }
    True, False -> {
      Error(
        "Invalid date: "
        <> { "day " <> int.to_string(day) <> " is out of range" }
        <> {
          " (1 to "
          <> int.to_string(days_in_month(year, number_to_month(month_number)))
          <> ")"
        }
        <> {
          " for "
          <> {
            month_number
            |> number_to_month
            |> month_to_name
          }
        }
        <> {
          case month_number == 2 && day == 29 {
            True -> " (" <> int.to_string(year) <> " is not a leap year)"
            False -> ""
          }
        }
        <> {
          "; received (year "
          <> int.to_string(year)
          <> ", month "
          <> int.to_string(month_number)
          <> ", day "
          <> int.to_string(day)
          <> ")"
        },
      )
    }
    True, True -> {
      Ok(RD(
        days_before_year(year)
        + days_before_month(year, number_to_month(month_number))
        + day,
      ))
    }
  }
}

fn from_week_parts(
  week_year: Int,
  week_number: Int,
  weekday_number: Int,
) -> Result(Date, String) {
  let weeks_in_year = case is_53_week_year(week_year) {
    True -> 53
    False -> 52
  }

  case
    is_between_int(week_number, 1, weeks_in_year),
    is_between_int(weekday_number, 1, 7)
  {
    False, _ -> {
      Error(
        "Invalid week date: "
        <> { "week " <> int.to_string(week_number) <> " is out of range" }
        <> { " (1 to " <> int.to_string(weeks_in_year) <> ")" }
        <> { " for " <> int.to_string(week_year) }
        <> {
          "; received (year "
          <> int.to_string(week_year)
          <> ", week "
          <> int.to_string(week_number)
          <> ", weekday "
          <> int.to_string(weekday_number)
          <> ")"
        },
      )
    }
    True, False -> {
      Error(
        "Invalid week date: "
        <> { "weekday " <> int.to_string(weekday_number) <> " is out of range" }
        <> " (1 to 7)"
        <> {
          "; received (year "
          <> int.to_string(week_year)
          <> ", week "
          <> int.to_string(week_number)
          <> ", weekday "
          <> int.to_string(weekday_number)
          <> ")"
        },
      )
    }
    True, True -> {
      Ok(RD(
        days_before_week_year(week_year)
        + { { week_number - 1 } * 7 }
        + weekday_number,
      ))
    }
  }
}

// To records

type OrdinalDate {
  OrdinalDate(year: Int, ordinal_day: Int)
}

fn to_ordinal_date(date: Date) -> OrdinalDate {
  let RD(rd) = date
  let year_ = year(date)

  OrdinalDate(year: year_, ordinal_day: rd - days_before_year(year_))
}

type CalendarDate {
  CalendarDate(year: Int, month: Month, day: Int)
}

fn to_calendar_date(date: Date) -> CalendarDate {
  let ordinal_date = to_ordinal_date(date)

  to_calendar_date_helper(ordinal_date.year, Jan, ordinal_date.ordinal_day)
}

fn to_calendar_date_helper(
  year: Int,
  month: Month,
  ordinal_day: Int,
) -> CalendarDate {
  let month_days = days_in_month(year, month)
  let month_number = month_to_number(month)

  case month_number < 12 && ordinal_day > month_days {
    True -> {
      to_calendar_date_helper(
        year,
        number_to_month(month_number + 1),
        ordinal_day - month_days,
      )
    }
    False -> {
      CalendarDate(year: year, month: month, day: ordinal_day)
    }
  }
}

type WeekDate {
  WeekDate(week_year: Int, week_number: Int, weekday: Weekday)
}

fn to_week_date(date: Date) {
  let RD(rd) = date
  let weekday_number_ = weekday_number(date)
  let week_year = year(RD(rd + { 4 - weekday_number_ }))
  let week_1_day_1 = days_before_week_year(week_year) + 1

  WeekDate(
    week_year: week_year,
    week_number: 1 + { { rd - week_1_day_1 } / 7 },
    weekday: number_to_weekday(weekday_number_),
  )
}

// To parts

/// The day of the year (1–366).
pub fn ordinal_day(date: Date) -> Int {
  to_ordinal_date(date).ordinal_day
}

/// The month as [`Month`](#Month) value (`Jan`–`Dec`).
pub fn month(date: Date) -> Month {
  to_calendar_date(date).month
}

/// The month number (1–12).
pub fn month_number(date: Date) -> Int {
  date
  |> month
  |> month_to_number
}

/// The quarter of the year (1–4).
pub fn quarter(date: Date) -> Int {
  date
  |> month
  |> month_to_quarter
}

/// The day of the month (1–31).
pub fn day(date: Date) -> Int {
  to_calendar_date(date).day
}

/// The ISO week-numbering year. This is not always the same as the calendar year.
pub fn week_year(date: Date) -> Int {
  to_week_date(date).week_year
}

/// The ISO week number of the year (1–53).
pub fn week_number(date: Date) -> Int {
  to_week_date(date).week_number
}

/// The weekday as a [`Weekday`](#Weekday) value (`Mon`–`Sun`).
pub fn weekday(date: Date) -> Weekday {
  date
  |> weekday_number
  |> number_to_weekday
}

// -- quarters

fn month_to_quarter(month: Month) -> Int {
  { month_to_number(month) + 2 } / 3
}

fn quarter_to_month(quarter: Int) -> Month {
  quarter * 3 - 2
  |> number_to_month
}

// -- TO FORMATTED STRINGS

/// Functions to convert date information to strings in a custom language.
pub type Language {
  Language(
    month_name: fn(Month) -> String,
    month_name_short: fn(Month) -> String,
    weekday_name: fn(Weekday) -> String,
    weekday_name_short: fn(Weekday) -> String,
    day_with_suffix: fn(Int) -> String,
  )
}

fn format_field(
  date: Date,
  language: Language,
  char: String,
  length: Int,
) -> String {
  case char {
    "y" ->
      case length {
        2 ->
          date
          |> year
          |> int.to_string
          |> string.pad_left(2, "0")
          |> string_take_right(2)

        _ ->
          date
          |> year
          |> pad_signed_int(length)
      }

    "Y" ->
      case length {
        2 ->
          date
          |> week_year
          |> int.to_string
          |> string.pad_left(2, "0")
          |> string_take_right(2)

        _ ->
          date
          |> week_year
          |> pad_signed_int(length)
      }

    "Q" ->
      case length {
        1 ->
          date
          |> quarter
          |> int.to_string

        2 ->
          date
          |> quarter
          |> int.to_string

        3 ->
          date
          |> quarter
          |> int.to_string
          |> fn(str) { "Q" <> str }

        4 ->
          date
          |> quarter
          |> with_ordinal_suffix

        5 ->
          date
          |> quarter
          |> int.to_string

        _ -> ""
      }

    "M" ->
      case length {
        1 ->
          date
          |> month_number
          |> int.to_string

        2 ->
          date
          |> month_number
          |> int.to_string
          |> string.pad_left(2, "0")

        3 ->
          date
          |> month
          |> language.month_name_short

        4 ->
          date
          |> month
          |> language.month_name

        5 ->
          date
          |> month
          |> language.month_name_short
          |> string_take_left(1)

        _ -> ""
      }
    "w" ->
      case length {
        1 ->
          date
          |> week_number
          |> int.to_string

        2 ->
          date
          |> week_number
          |> int.to_string
          |> string.pad_left(2, "0")

        _ -> ""
      }

    "d" ->
      case length {
        1 ->
          date
          |> day
          |> int.to_string

        2 ->
          date
          |> day
          |> int.to_string
          |> string.pad_left(2, "0")

        // non-standard
        3 ->
          date
          |> day
          |> language.day_with_suffix

        _ -> ""
      }

    "D" ->
      case length {
        1 ->
          date
          |> ordinal_day
          |> int.to_string

        2 ->
          date
          |> ordinal_day
          |> int.to_string
          |> string.pad_left(2, "0")

        3 ->
          date
          |> ordinal_day
          |> int.to_string
          |> string.pad_left(3, "0")

        _ -> ""
      }

    "E" ->
      case length {
        // abbreviated
        1 ->
          date
          |> weekday
          |> language.weekday_name_short

        2 ->
          date
          |> weekday
          |> language.weekday_name_short

        3 ->
          date
          |> weekday
          |> language.weekday_name_short

        // full
        4 ->
          date
          |> weekday
          |> language.weekday_name

        // narrow
        5 ->
          date
          |> weekday
          |> language.weekday_name_short
          |> string_take_left(1)

        // short
        6 ->
          date
          |> weekday
          |> language.weekday_name_short
          |> string_take_left(2)

        _ -> ""
      }

    "e" ->
      case length {
        1 ->
          date
          |> weekday_number
          |> int.to_string

        2 ->
          date
          |> weekday_number
          |> int.to_string

        _ ->
          date
          |> format_field(language, "E", length)
      }

    _ -> ""
  }
}

fn string_take_right(str: String, count: Int) -> String {
  string.slice(from: str, at_index: -1 * count, length: count)
}

fn string_take_left(str: String, count: Int) -> String {
  string.slice(from: str, at_index: 0, length: count)
}

/// Expects `tokens` list reversed for foldl.
fn format_with_tokens(
  language: Language,
  tokens: List(Token),
  date: Date,
) -> String {
  list.fold(tokens, "", fn(formatted, token) {
    case token {
      Field(char, length) -> {
        format_field(date, language, char, length) <> formatted
      }
      Literal(str) -> {
        str <> formatted
      }
    }
  })
}

/// Format a date in a custom language using a string as a template.
/// 
/// ```gleam
/// // Assuming that `french_lang` is a custom `Language` value
/// from_ordinate_date(1970, 1)
/// |> format_with_language(french_lang, "EEEE, ddd MMMM y")
/// // -> "jeudi, 1er janvier 1970"
/// ```
pub fn format_with_language(
  date: Date,
  language: Language,
  pattern_text: String,
) -> String {
  let tokens =
    pattern_text
    |> pattern.from_string
    |> list.reverse

  format_with_tokens(language, tokens, date)
}

// Default language

fn month_to_name(month: Month) -> String {
  case month {
    Jan -> "January"
    Feb -> "February"
    Mar -> "March"
    Apr -> "April"
    May -> "May"
    Jun -> "June"
    Jul -> "July"
    Aug -> "August"
    Sep -> "September"
    Oct -> "October"
    Nov -> "November"
    Dec -> "December"
  }
}

fn weekday_to_name(weekday: Weekday) -> String {
  case weekday {
    Mon -> "Monday"
    Tue -> "Tuesday"
    Wed -> "Wednesday"
    Thu -> "Thursday"
    Fri -> "Friday"
    Sat -> "Saturday"
    Sun -> "Sunday"
  }
}

fn ordinal_suffix(value: Int) -> String {
  // use 2-digit number
  let value_mod_100 = modulo_unwrap(value, 100)
  let value = case value_mod_100 < 20 {
    True -> value_mod_100
    False -> modulo_unwrap(value_mod_100, 10)
  }
  case int.min(value, 4) {
    1 -> "st"
    2 -> "nd"
    3 -> "rd"
    _ -> "th"
  }
}

/// Convert an integer into an English ordinal number string (like `"4th"`).
/// 
/// ```gleam
/// with_ordinal_suffix(21) == "21st"
/// with_ordinal_suffix(42) == "42nd"
/// with_ordinal_suffix(0) == "0th"
/// with_ordinal_suffix(23) == "23rd"
/// with_ordinal_suffix(-1) == "-1st"
/// ```
/// 
pub fn with_ordinal_suffix(value: Int) -> String {
  int.to_string(value) <> ordinal_suffix(value)
}

fn language_en() -> Language {
  Language(
    month_name: month_to_name,
    month_name_short: fn(val) {
      val
      |> month_to_name
      |> string_take_left(3)
    },
    weekday_name: weekday_to_name,
    weekday_name_short: fn(val) {
      val
      |> weekday_to_name
      |> string_take_left(3)
    },
    day_with_suffix: with_ordinal_suffix,
  )
}

/// Format a date using a string as a template.
/// 
/// ```gleam
/// from_ordinal_date(1970, 1)
/// |> format("EEEE, d MMMM y")
/// // -> "Thursday, 1 January 1970"
/// ```
/// 
/// Alphabetic characters in the template represent date information; the number of
/// times a character is repeated specifies the form of a name (e.g. `"Tue"`,
/// `"Tuesday"`) or the padding of a number (e.g. `"1"`, `"01"`).
/// 
/// Alphabetic characters can be escaped within single-quotes; a single-quote can
/// be escaped as a sequence of two single-quotes, whether appearing inside or
/// outside an escaped sequence.
/// 
/// Templates are based on Date Format Patterns in [Unicode Technical
/// Standard #35][uts35]. Only the following subset of formatting characters
/// are available:
/// 
///     "y" -- year
/// 
///     "Y" -- week-numbering year
/// 
///     "Q" -- quarter
/// 
///     "M" -- month (number or name)
/// 
///     "w" -- week number
/// 
///     "d" -- day
/// 
///     "D" -- ordinal day
/// 
///     "E" -- weekday name
/// 
///     "e" -- weekday number
/// 
/// [uts35]: http://www.unicode.org/reports/tr35/tr35-43/tr35-dates.html#Date_Format_Patterns
/// 
/// The non-standard pattern field "ddd" is available to indicate the day of the
/// month with an ordinal suffix (e.g. `"1st"`, `"15th"`), as the current standard
/// does not include such a field.
pub fn format(date: Date, pattern: String) -> String {
  format_with_language(date, language_en(), pattern)
}

/// Convert a date to a string in ISO 8601 extended format.
/// 
/// ```gleam
/// from_calendar_date(2001, Jan, 1)
/// |> to_iso_string
/// // -> "2001-01-01"
/// ```
pub fn to_iso_string(date: Date) -> String {
  format(date, "yyyy-MM-dd")
}

// From iso 8601 strings

/// Attempt to create a date from a string in [ISO 8601][iso8601] format.
/// Calendar dates, week dates, and ordinal dates are all supported in extended
/// and basic format.
/// 
/// ```gleam
/// // calendar date
/// from_iso_string("2018-09-26") == Ok(from_calendar_date(2018, Sep, 26))
/// 
/// // week date
/// from_iso_string("2018-W39-3") == Ok(from_week_date(2018, 39, Wed))
/// 
/// // ordinal date
/// from_iso_string("2018-269") == Ok(from_ordinal_date(2018, 269))
/// ```
/// 
/// The string must represent a valid date; unlike `from_calendar_date` and
/// friends, any out-of-range values will fail to produce a date.
/// 
/// ```gleam
/// from_iso_string("2018-02-29") == Error("Invalid calendar date (2018, 2, 29)")
/// ```
/// 
/// [iso8601]: https://en.wikipedia.org/wiki/ISO_8601
pub fn from_iso_string(str: String) -> Result(Date, String) {
  let assert Ok(tokens) = nibble_lexer.run(str, days_parse.lexer())

  let result =
    nibble.run(
      tokens,
      parser()
        |> nibble.then(fn(val) {
          nibble.one_of([
            nibble.eof() |> nibble.then(fn(_) { nibble.succeed(val) }),
            nibble.token(TimeToken)
              |> nibble.then(fn(_) {
                nibble.succeed(Error(
                  "Expected a date only, not a date and time",
                ))
              }),
            nibble.succeed(Error("Expected a date only")),
          ])
        }),
    )

  case result {
    Ok(Ok(value)) -> Ok(value)
    Ok(Error(err)) -> Error(err)
    Error(_) -> Error("Expected a date in ISO 8601 format")
  }
}

// Day of year

type DayOfYear {
  MonthAndDay(Int, Int)
  WeekAndWeekday(Int, Int)
  OrdinalDay(Int)
}

fn from_year_and_day_of_year(
  year: Int,
  day_of_year: DayOfYear,
) -> Result(Date, String) {
  case day_of_year {
    MonthAndDay(month_number, day) -> {
      from_calendar_parts(year, month_number, day)
    }
    WeekAndWeekday(week_number, weekday_number) -> {
      from_week_parts(year, week_number, weekday_number)
    }
    OrdinalDay(ordinal_day) -> {
      from_ordinal_parts(year, ordinal_day)
    }
  }
}

// Parser

fn parser() {
  use year <- nibble.do(int_4())
  use day_of_year <- nibble.do(parse_day_of_year())

  nibble.return(from_year_and_day_of_year(year, day_of_year))
}

fn parse_day_of_year() {
  nibble.one_of([
    nibble.token(Dash)
      |> nibble.then(fn(_) {
        nibble.one_of([
          nibble.backtrackable(parse_ordinal_day()),
          parse_month_and_day(True),
          parse_week_and_weekday(True),
        ])
      }),
    nibble.backtrackable(parse_month_and_day(False)),
    parse_ordinal_day(),
    parse_week_and_weekday(False),
    nibble.succeed(OrdinalDay(1)),
  ])
}

fn parse_month_and_day(extended: Bool) {
  use month <- nibble.do(int_2())

  let dash_count = bool.to_int(extended)

  use day <- nibble.do(
    nibble.one_of([
      // Either parse a two digit day
      nibble.take_exactly(nibble.token(Dash), dash_count)
        |> nibble.then(fn(_) { int_2() }),
      // Or if it is the end of string then it is a just a year
      // and a month and so we infer '1' as the day
      nibble.eof() |> nibble.then(fn(_) { nibble.succeed(1) }),
    ]),
  )

  nibble.return(MonthAndDay(month, day))
}

fn parse_ordinal_day() {
  use day <- nibble.do(int_3())

  nibble.return(OrdinalDay(day))
}

fn parse_week_and_weekday(extended: Bool) {
  use _ <- nibble.do(nibble.token(WeekToken))

  use week <- nibble.do(int_2())

  let dash_count = bool.to_int(extended)

  use day <- nibble.do(
    nibble.one_of([
      nibble.take_exactly(nibble.token(Dash), dash_count)
        |> nibble.then(fn(_) { int_1() }),
      nibble.succeed(1),
    ]),
  )

  nibble.return(WeekAndWeekday(week, day))
}

fn parse_digit() {
  nibble.take_if("Expecting digit", fn(token) {
    case token {
      Digit(_) -> True
      _ -> False
    }
  })
}

fn int_4() {
  use negative <- nibble.do(nibble.optional(nibble.token(Dash)))
  let negative = negative |> option.map(fn(_) { "-" }) |> option.unwrap("")

  use tokens <- nibble.do(
    parse_digit()
    |> nibble.take_exactly(4),
  )

  let str =
    list.map(tokens, fn(token) {
      let assert Digit(str) = token
      str
    })
    |> string.concat

  let assert Ok(int) = int.parse(negative <> str)

  nibble.return(int)
}

fn int_3() {
  use tokens <- nibble.do(
    parse_digit()
    |> nibble.take_exactly(3),
  )

  let str =
    list.map(tokens, fn(token) {
      let assert Digit(str) = token
      str
    })
    |> string.concat

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

fn int_2() {
  use tokens <- nibble.do(
    parse_digit()
    |> nibble.take_exactly(2),
  )

  let str =
    list.map(tokens, fn(token) {
      let assert Digit(str) = token
      str
    })
    |> string.concat

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

fn int_1() {
  use tokens <- nibble.do(
    parse_digit()
    |> nibble.take_exactly(1),
  )

  let assert [Digit(str)] = tokens

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

// Arithmetic

/// Used in `add` and `diff` operations to specify natural increments as needed.
pub type Unit {
  Years
  Months
  Weeks
  Days
}

/// Get a past or future date by adding a number of units to a date.
/// 
/// ```gleam
/// add(Weeks, -2, from_calendar_date(2018, Sep, 26))
///     == from_calendar_date(2018, Sep, 12)
/// ```
/// 
/// When adding `Years` or `Months`, day values are clamped to the end of the
/// month if necessary.
/// 
/// ```gleam
/// add(Months, 1, from_calendar_date(2000, Jan, 31))
///     == from_calendar_date(2000, Feb, 29)
/// ```
pub fn add(date: Date, count: Int, unit: Unit) -> Date {
  let RD(rd) = date
  case unit {
    Years -> {
      add(date, { 12 * count }, Months)
    }
    Months -> {
      let calendar_date = to_calendar_date(date)
      let whole_months =
        { 12 * { calendar_date.year - 1 } }
        + { month_to_number(calendar_date.month) - 1 }
        + count

      let year = floor_div(whole_months, 12) + 1
      let month = number_to_month(modulo_unwrap(whole_months, 12) + 1)

      RD(
        days_before_year(year)
        + days_before_month(year, month)
        + int.min(calendar_date.day, days_in_month(year, month)),
      )
    }
    Weeks -> {
      RD(rd + 7 * count)
    }
    Days -> {
      RD(rd + count)
    }
  }
}

/// The number of whole months between date and 0001-01-01 plus fraction
/// representing the current month. Only used for diffing months.
fn to_months(rd: RataDie) -> Float {
  let calendar_date = to_calendar_date(RD(rd))
  let whole_months =
    { 12 * { calendar_date.year - 1 } }
    + { month_to_number(calendar_date.month) - 1 }

  // Not designed to be 0-1 of a month - just used for diffing
  let fraction = int.to_float(calendar_date.day) /. 100.0

  int.to_float(whole_months) +. fraction
}

/// Get the difference, as a number of whole units, between two dates.
/// 
/// ```gleam
/// diff(Months, from_calendar_date(2020, Jan, 2), from_calendar_date(2020, Apr, 1))
/// // -> 2
/// ```
pub fn diff(unit: Unit, date1: Date, date2: Date) -> Int {
  let RD(rd1) = date1
  let RD(rd2) = date2
  case unit {
    Years -> {
      { to_months(rd2) -. to_months(rd1) }
      |> float.truncate
      |> int.divide(12)
      // Only errors on 0 divisor
      |> result.unwrap(0)
    }
    Months -> {
      { to_months(rd2) -. to_months(rd1) }
      |> float.truncate
    }
    Weeks -> {
      int.divide({ rd2 - rd1 }, 7)
      // Only errors on 0 divisor
      |> result.unwrap(0)
    }
    Days -> rd2 - rd1
  }
}

// Rounding

/// Interval indicator used in `floor`, `ceiling` and `range` functions. Allowing you to, for example, round a date
/// down to the nearest quarter, or week, or Tuesday, or whatever is required.
pub type Interval {
  Year
  Quarter
  Month
  Week
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
  Day
}

fn days_since_previous_weekday(weekday: Weekday, date: Date) -> Int {
  modulo_unwrap(weekday_number(date) + 7 - weekday_to_number(weekday), 7)
}

/// Round down a date to the beginning of the closest interval. The resulting
/// date will be less than or equal to the one provided.
/// 
/// ```gleam
/// floor(Tuesday, from_calendar_date(2018, May, 11))
///         == from_calendar_date(2018, May, 8)
/// ```
pub fn floor(date: Date, interval: Interval) -> Date {
  let RD(rd) = date
  case interval {
    Year -> {
      first_of_year(year(date))
    }
    Quarter -> {
      first_of_month(year(date), {
        quarter(date)
        |> quarter_to_month
      })
    }
    Month -> {
      first_of_month(year(date), month(date))
    }
    Week -> {
      RD(rd - days_since_previous_weekday(Mon, date))
    }
    Monday -> {
      RD(rd - days_since_previous_weekday(Mon, date))
    }
    Tuesday -> {
      RD(rd - days_since_previous_weekday(Tue, date))
    }
    Wednesday -> {
      RD(rd - days_since_previous_weekday(Wed, date))
    }
    Thursday -> {
      RD(rd - days_since_previous_weekday(Thu, date))
    }
    Friday -> {
      RD(rd - days_since_previous_weekday(Fri, date))
    }
    Saturday -> {
      RD(rd - days_since_previous_weekday(Sat, date))
    }
    Sunday -> {
      RD(rd - days_since_previous_weekday(Sun, date))
    }
    Day -> {
      date
    }
  }
}

fn interval_to_units(interval: Interval) -> #(Int, Unit) {
  case interval {
    Year -> #(1, Years)
    Quarter -> #(3, Months)
    Month -> #(1, Months)
    Day -> #(1, Days)
    _ -> #(1, Weeks)
  }
}

/// Round up a date to the beginning of the closest interval. The resulting
/// date will be greater than or equal to the one provided.
/// 
/// ```gleam
/// ceiling(Tuesday, from_calendar_date(2018, May, 11))
///     == from_calendar_date(2018, May, 15)
/// ```
pub fn ceiling(date: Date, interval: Interval) -> Date {
  let floored_date = floor(date, interval)
  case date == floored_date {
    True -> date
    False -> {
      let #(n, unit) = interval_to_units(interval)
      add(floored_date, n, unit)
    }
  }
}

/// Create a list of dates, at rounded intervals, increasing by a step value,
/// between two dates. The list will start on or after the first date, and end
/// before the second date.
/// 
/// ```gleam
/// let start = from_calendar_date(2018, May, 8)
/// let until = from_calendar_date(2018, May, 14)
///
/// range(Day, 2, start, until)
///     == [ from_calendar_date(2018, May, 8)
///        , from_calendar_date(2018, May, 10)
///        , from_calendar_date(2018, May, 12)
///        ]
/// ```
pub fn range(
  interval: Interval,
  step: Int,
  start_date: Date,
  until_date: Date,
) -> List(Date) {
  let #(n, unit) = interval_to_units(interval)
  let RD(first_rd) = ceiling(start_date, interval)
  let RD(until_rd) = until_date

  case first_rd < until_rd {
    True -> {
      range_help(unit, int.max(1, step * n), until_rd, [], first_rd)
    }
    False -> []
  }
}

fn range_help(
  unit: Unit,
  step: Int,
  until_rd: RataDie,
  reversed_list: List(Date),
  current_rd: RataDie,
) -> List(Date) {
  case current_rd < until_rd {
    True -> {
      let RD(next_rd) = add(RD(current_rd), step, unit)
      range_help(
        unit,
        step,
        until_rd,
        [RD(current_rd), ..reversed_list],
        next_rd,
      )
    }
    False -> {
      list.reverse(reversed_list)
    }
  }
}

/// Get the current local date
pub fn today() -> Date {
  let #(year, month_number, day) = get_year_month_day()

  from_calendar_date(year, number_to_month(month_number), day)
}

@external(erlang, "rada_ffi", "get_year_month_day")
@external(javascript, "../rada_ffi.mjs", "get_year_month_day")
fn get_year_month_day() -> #(Int, Int, Int)

// Ordering

/// Compare two dates. This can be used as the compare function for
/// `list.sort`.
/// 
/// ```gleam
/// import gleam/ordering
///
/// compare(from_ordinal_date(1970, 1), from_ordinal_date(2038, 1))
///     == ordering.Lt
/// ```
pub fn compare(date1: Date, date2: Date) -> Order {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  int.compare(rd_1, rd_2)
}

/// Test if a date is within a range, inclusive of the range values.
/// 
/// ```gleam
/// let minimum = from_ordinal_date(1970, 1)
/// let maximum = from_ordinal_date(2038, 1)
/// 
/// is_between(minimum, maximum, from_ordinal_date(1969, 201))
///     == False
/// ```
pub fn is_between(value: Date, lower: Date, upper: Date) -> Bool {
  let RD(value_rd) = value
  let RD(lower_rd) = lower
  let RD(upper_rd) = upper

  is_between_int(value_rd, lower_rd, upper_rd)
}

/// Find the lesser of two dates.
/// 
/// ```gleam
/// min(from_ordinal_date(1970, 1), from_ordinal_date(2038, 1))
///     == from_ordinal_date(1970, 1)
/// ```
pub fn min(date1: Date, date2: Date) -> Date {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  case rd_1 < rd_2 {
    True -> date1
    False -> date2
  }
}

/// Find the greater of two dates.
/// 
/// ```gleam
/// max(from_ordinal_date(1970, 1), from_ordinal_date(2038, 1))
///     == from_ordinal_date(2038, 1)
/// ```
pub fn max(date1: Date, date2: Date) -> Date {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  case rd_1 < rd_2 {
    True -> date2
    False -> date1
  }
}

/// Clamp a date within a range.
/// 
/// ```gleam
/// let minimum = from_ordinal_date(1970, 1)
/// let maximum = from_ordinal_date(2038, 1)
/// 
/// clamp(from_ordinal_date(1969, 201), minimum, maximum)
///     == from_ordinal_date(1970, 1)
/// ```
/// 
pub fn clamp(value: Date, lower: Date, upper: Date) -> Date {
  let RD(value_rd) = value
  let RD(lower_rd) = lower
  let RD(upper_rd) = upper

  case value_rd < lower_rd {
    True -> lower
    False -> {
      case value_rd > upper_rd {
        True -> upper
        False -> value
      }
    }
  }
}

// Numbers of days

fn days_in_month(year: Int, month: Month) -> Int {
  case month {
    Jan -> 31
    Feb ->
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    Mar -> 31
    Apr -> 30
    May -> 31
    Jun -> 30
    Jul -> 31
    Aug -> 31
    Sep -> 30
    Oct -> 31
    Nov -> 30
    Dec -> 31
  }
}

fn days_before_month(year: Int, month: Month) -> Int {
  let leap_days = bool.to_int(is_leap_year(year))
  case month {
    Jan -> 0
    Feb -> 31
    Mar -> 59 + leap_days
    Apr -> 90 + leap_days
    May -> 120 + leap_days
    Jun -> 151 + leap_days
    Jul -> 181 + leap_days
    Aug -> 212 + leap_days
    Sep -> 243 + leap_days
    Oct -> 273 + leap_days
    Nov -> 304 + leap_days
    Dec -> 334 + leap_days
  }
}

// Month and weekday numbers

/// Converts the month values `Jan`–`Dec` to 1–12.
pub fn month_to_number(month: Month) -> Int {
  case month {
    Jan -> 1
    Feb -> 2
    Mar -> 3
    Apr -> 4
    May -> 5
    Jun -> 6
    Jul -> 7
    Aug -> 8
    Sep -> 9
    Oct -> 10
    Nov -> 11
    Dec -> 12
  }
}

/// Converts the numbers 1–12 to `Jan`–`Dec`. The input is clamped to the range 1-12 before conversion.
pub fn number_to_month(month_number: Int) -> Month {
  case int.max(1, month_number) {
    1 -> Jan
    2 -> Feb
    3 -> Mar
    4 -> Apr
    5 -> May
    6 -> Jun
    7 -> Jul
    8 -> Aug
    9 -> Sep
    10 -> Oct
    11 -> Nov
    _ -> Dec
  }
}

/// Converts the weekday values `Mon`–`Sun` to 1–7.
fn weekday_to_number(weekday: Weekday) -> Int {
  case weekday {
    Mon -> 1
    Tue -> 2
    Wed -> 3
    Thu -> 4
    Fri -> 5
    Sat -> 6
    Sun -> 7
  }
}

/// Converts the numbers 1–7 to `Mon`–`Sun`. The input is clamped to the range 1-7 before conversion.
pub fn number_to_weekday(weekday_number: Int) -> Weekday {
  case int.max(1, weekday_number) {
    1 -> Mon
    2 -> Tue
    3 -> Wed
    4 -> Thu
    5 -> Fri
    6 -> Sat
    _ -> Sun
  }
}

// Helpers

fn pad_signed_int(value: Int, length: Int) -> String {
  let prefix = case value < 0 {
    True -> "-"
    False -> ""
  }

  let suffix =
    value
    |> int.absolute_value
    |> int.to_string
    |> string.pad_left(length, "0")

  prefix <> suffix
}

fn floor_div(a: Int, b: Int) -> Int {
  int.floor_divide(a, b)
  // We know we're not calling this with b == 0 so the unwrap value will not be used
  |> result.unwrap(0)
}

fn div_with_remainder(a: Int, b: Int) -> #(Int, Int) {
  #(floor_div(a, b), modulo_unwrap(a, b))
}

fn modulo_unwrap(a: Int, b: Int) -> Int {
  int.modulo(a, b) |> result.unwrap(0)
}

fn is_between_int(value: Int, lower: Int, upper: Int) -> Bool {
  lower <= value && value <= upper
}
