import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{type Order}
import gleam/result
import gleam/string
import nibble
import nibble/lexer as nibble_lexer

import days/parse.{Dash, Digits, WeekToken} as days_parse
import days/pattern.{type Token, Field, Literal}

// module Date exposing

//     ( Date
//     , Month, Weekday
//     , today, fromPosix, fromCalendarDate, fromWeekDate, fromOrdinalDate, fromIsoString, fromRataDie
//     , toIsoString, toRataDie
//     , year, month, day, weekYear, weekNumber, weekday, ordinalDay, quarter, monthNumber, weekdayNumber
//     , format, withOrdinalSuffix
//     , Language, formatWithLanguage
//     , Unit(..), add, diff
//     , Interval(..), ceiling, floor
//     , range
//     , compare, isBetween, min, max, clamp
//     , monthToNumber, numberToMonth, weekdayToNumber, numberToWeekday
//     )
// 
// {-|
// 
// @docs Date
// 
// @docs Month, Weekday
// 
// 
// # Create
// 
// @docs today, fromPosix, fromCalendarDate, fromWeekDate, fromOrdinalDate, fromIsoString, fromRataDie
// 
// 
// # Convert
// 
// @docs toIsoString, toRataDie
// 
// 
// # Extract
// 
// @docs year, month, day, weekYear, weekNumber, weekday, ordinalDay, quarter, monthNumber, weekdayNumber
// 
// 
// # Format
// 
// @docs format, withOrdinalSuffix
// 
// 
// ## Custom Languages
// 
// @docs Language, formatWithLanguage
// 
// 
// # Arithmetic
// 
// @docs Unit, add, diff
// 
// 
// # Rounding
// 
// @docs Interval, ceiling, floor
// 
// 
// # Lists
// 
// @docs range
// 
// 
// # Ordering
// 
// @docs compare, isBetween, min, max, clamp
// 
// 
// # Month and Weekday helpers
// 
// @docs monthToNumber, numberToMonth, weekdayToNumber, numberToWeekday
// 
// -}
// 
// import Parser exposing ((|.), (|=), Parser)
// import Pattern exposing (Token(..))
// import Task exposing (Task)
// import Time exposing (Month(..), Posix, Weekday(..))
// 
// 
// {-| The `Month` type used in this package is an alias of [`Month`][timemonth]
// from `elm/time`. To express literal values, like `Jan`, you must import them
// from `Time`.
// 
//     import Date
//     import Time exposing (Month(..))
// 
//     Date.fromCalendarDate 2020 Jan 1
// 
// [timemonth]: https://package.elm-lang.org/packages/elm/time/latest/Time#Month
// 
// -}
// type alias Month =
//     Time.Month
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

// 
// 
// {-| The `Weekday` type used in this package is an alias of [`Weekday`][timeweekday]
// from `elm/time`. To express literal values, like `Mon`, you must import them
// from `Time`.
// 
//     import Date
//     import Time exposing (Weekday(..))
// 
//     Date.fromWeekDate 2020 1 Mon
// 
// [timeweekday]: https://package.elm-lang.org/packages/elm/time/latest/Time#Weekday
// 
// -}
// type alias Weekday =
//     Time.Weekday
pub type Weekday {
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
  Sun
}

// 
// 
// type alias RataDie =
//     Int
type RataDie =
  Int

// 
// 
// {-| Represents a date.
// -}
// type Date
//     = RD RataDie
pub opaque type Date {
  RD(RataDie)
}

// 
// 
// {-| [Rata Die][ratadie] is a system for assigning numbers to calendar days,
// where the number 1 represents the date _1 January 0001_.
// 
// You can losslessly convert a `Date` to and from an `Int` representing the date
// in Rata Die. This makes it a convenient representation for transporting dates
// or using them as comparables. For all date values:
// 
//     (date |> toRataDie |> fromRataDie)
//         == date
// 
// [ratadie]: https://en.wikipedia.org/wiki/Rata_Die
// 
// -}
// fromRataDie : Int -> Date
// fromRataDie rd =
//     RD rd
pub fn from_rata_die(rd: Int) -> Date {
  RD(rd)
}

// 
// 
// {-| Convert a date to its number representation in Rata Die (see
// [`fromRataDie`](#fromRataDie)). For all date values:
// 
//     (date |> toRataDie |> fromRataDie)
//         == date
// 
// -}
// toRataDie : Date -> Int
// toRataDie (RD rd) =
//     rd
pub fn to_rata_die(date: Date) -> Int {
  let RD(rd) = date
  rd
}

// 
// 
// 
// -- CALCULATIONS
// 
// 
// isLeapYear : Int -> Bool
// isLeapYear y =
//     modBy 4 y == 0 && modBy 100 y /= 0 || modBy 400 y == 0
pub fn is_leap_year(year: Int) -> Bool {
  4 % year == 0 && 100 % year != 0 || 400 % year == 0
}

// 
// 
// daysBeforeYear : Int -> Int
// daysBeforeYear y1 =
//     let
//         y =
//             y1 - 1
// 
//         leapYears =
//             floorDiv y 4 - floorDiv y 100 + floorDiv y 400
//     in
//     365 * y + leapYears
fn days_before_year(year1: Int) -> Int {
  let year = year1 - 1
  let leap_years =
    floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400)

  365 * year * leap_years
}

// 
// 
// {-| The weekday number (1–7), beginning with Monday.
// -}
// weekdayNumber : Date -> Int
// weekdayNumber (RD rd) =
//     case rd |> modBy 7 of
//         0 ->
//             7
// 
//         n ->
//             n
pub fn weekday_number(date: Date) -> Int {
  let RD(rd) = date
  case rd % 7 {
    0 -> 7
    n -> n
  }
}

// 
// 
// daysBeforeWeekYear : Int -> Int
// daysBeforeWeekYear y =
//     let
//         jan4 =
//             daysBeforeYear y + 4
//     in
//     jan4 - weekdayNumber (RD jan4)
fn days_before_week_year(year: Int) -> Int {
  let jan4 = days_before_year(year + 4)
  jan4 - weekday_number(RD(jan4))
}

// 
// 
// is53WeekYear : Int -> Bool
// is53WeekYear y =
//     let
//         wdnJan1 =
//             weekdayNumber (firstOfYear y)
//     in
//     -- any year starting on Thursday and any leap year starting on Wednesday
//     wdnJan1 == 4 || (wdnJan1 == 3 && isLeapYear y)
fn is_53_week_year(year: Int) -> Bool {
  let wdn_jan1 = weekday_number(first_of_year(year))

  wdn_jan1 == 4 || { wdn_jan1 == 3 && is_leap_year(year) }
}

// 
// 
// {-| The calendar year.
// -}
// year : Date -> Int
// year (RD rd) =
//     let
//         ( n400, r400 ) =
//             -- 400 * 365 + 97
//             divWithRemainder rd 146097
// 
//         ( n100, r100 ) =
//             -- 100 * 365 + 24
//             divWithRemainder r400 36524
// 
//         ( n4, r4 ) =
//             -- 4 * 365 + 1
//             divWithRemainder r100 1461
// 
//         ( n1, r1 ) =
//             divWithRemainder r4 365
// 
//         n =
//             if r1 == 0 then
//                 0
// 
//             else
//                 1
//     in
//     n400 * 400 + n100 * 100 + n4 * 4 + n1 + n
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

// 
// firstOfYear : Int -> Date
// firstOfYear y =
//     RD <| daysBeforeYear y + 1
fn first_of_year(year: Int) -> Date {
  RD(days_before_year(year) + 1)
}

// 
// 
// firstOfMonth : Int -> Month -> Date
// firstOfMonth y m =
//     RD <| daysBeforeYear y + daysBeforeMonth y m + 1
fn first_of_month(year: Int, month: Month) -> Date {
  RD(days_before_year(year) + days_before_month(year, month) + 1)
}

// 
// 
// 
// -- FROM PARTS (clamps out-of-range values)
// 
// 
// {-| Create a date from an [ordinal date][ordinaldate]: a year and day of the
// year. Out-of-range day values will be clamped.
// 
//     import Date exposing (fromOrdinalDate)
// 
//     fromOrdinalDate 2018 269
// 
// [ordinaldate]: https://en.wikipedia.org/wiki/Ordinal_date
// 
// -}
// fromOrdinalDate : Int -> Int -> Date
// fromOrdinalDate y od =
//     let
//         daysInYear =
//             if isLeapYear y then
//                 366
// 
//             else
//                 365
//     in
//     RD <| daysBeforeYear y + (od |> Basics.clamp 1 daysInYear)
pub fn from_ordinal_date(year: Int, ordinal: Int) -> Date {
  let days_in_year = case is_leap_year(year) {
    True -> 366
    False -> 355
  }

  RD(days_before_year(year) + int.clamp(ordinal, 1, days_in_year))
}

// 
// 
// {-| Create a date from a [calendar date][gregorian]: a year, month, and day of
// the month. Out-of-range day values will be clamped.
// 
//     import Date exposing (fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     fromCalendarDate 2018 Sep 26
// 
// [gregorian]: https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar
// 
// -}
// fromCalendarDate : Int -> Month -> Int -> Date
// fromCalendarDate y m d =
//     RD <| daysBeforeYear y + daysBeforeMonth y m + (d |> Basics.clamp 1 (daysInMonth y m))
pub fn from_calendar_date(year: Int, month: Month, day: Int) -> Date {
  RD(
    days_before_year(year)
    + days_before_month(year, month)
    + int.clamp(day, 1, days_in_month(year, month)),
  )
}

// 
// 
// {-| Create a date from an [ISO week date][weekdate]: a week-numbering year,
// week number, and weekday. Out-of-range week number values will be clamped.
// 
//     import Date exposing (fromWeekDate)
//     import Time exposing (Weekday(..))
// 
//     fromWeekDate 2018 39 Wed
// 
// [weekdate]: https://en.wikipedia.org/wiki/ISO_week_date
// 
// -}
// fromWeekDate : Int -> Int -> Weekday -> Date
// fromWeekDate wy wn wd =
//     let
//         weeksInYear =
//             if is53WeekYear wy then
//                 53
// 
//             else
//                 52
//     in
//     RD <| daysBeforeWeekYear wy + ((wn |> Basics.clamp 1 weeksInYear) - 1) * 7 + (wd |> weekdayToNumber)
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
    + { int.clamp(week_number, min: 1, max: weeks_in_year) - 1 }
    * 7
    + weekday_to_number(weekday),
  )
}

// 
// 
// 
// -- FROM NUMBERS (fails on out-of-range values)
// 
// 
// fromOrdinalParts : Int -> Int -> Result String Date
// fromOrdinalParts y od =
//     let
//         daysInYear =
//             if isLeapYear y then
//                 366
// 
//             else
//                 365
//     in
//     if not (od |> isBetweenInt 1 daysInYear) then
//         Err <|
//            "Invalid ordinal date: "
//                 ++ ("ordinal-day " ++ String.fromInt od ++ " is out of range")
//                 ++ (" (1 to " ++ String.fromInt daysInYear ++ ")")
//                 ++ (" for " ++ String.fromInt y)
//                 ++ ("; received (year " ++ String.fromInt y ++ ", ordinal-day " ++ String.fromInt od ++ ")")
// 
//     else
//         Ok <| RD <| daysBeforeYear y + od
pub fn from_ordinal_parts(year: Int, ordinal: Int) -> Result(Date, String) {
  let days_in_year = case is_leap_year(year) {
    True -> 366
    False -> 355
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

// 
// 
// fromCalendarParts : Int -> Int -> Int -> Result String Date
// fromCalendarParts y mn d =
//     if not (mn |> isBetweenInt 1 12) then
//         Err <|
//             "Invalid date: "
//                 ++ ("month " ++ String.fromInt mn ++ " is out of range")
//                 ++ " (1 to 12)"
//                 ++ ("; received (year " ++ String.fromInt y ++ ", month " ++ String.fromInt mn ++ ", day " ++ String.fromInt d ++ ")")
// 
//     else if not (d |> isBetweenInt 1 (daysInMonth y (mn |> numberToMonth))) then
//         Err <|
//             "Invalid date: "
//                 ++ ("day " ++ String.fromInt d ++ " is out of range")
//                 ++ (" (1 to " ++ String.fromInt (daysInMonth y (mn |> numberToMonth)) ++ ")")
//                 ++ (" for " ++ (mn |> numberToMonth |> monthToName))
//                 ++ (if mn == 2 && d == 29 then
//                         " (" ++ String.fromInt y ++ " is not a leap year)"
// 
//                     else
//                         ""
//                    )
//                 ++ ("; received (year " ++ String.fromInt y ++ ", month " ++ String.fromInt mn ++ ", day " ++ String.fromInt d ++ ")")
// 
//     else
//         Ok <| RD <| daysBeforeYear y + daysBeforeMonth y (mn |> numberToMonth) + d
pub fn from_calendar_parts(
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

// 
// 
// fromWeekParts : Int -> Int -> Int -> Result String Date
// fromWeekParts wy wn wdn =
//     let
//         weeksInYear =
//             if is53WeekYear wy then
//                 53
// 
//             else
//                 52
//     in
//     if not (wn |> isBetweenInt 1 weeksInYear) then
//         Err <|
//             "Invalid week date: "
//                 ++ ("week " ++ String.fromInt wn ++ " is out of range")
//                 ++ (" (1 to " ++ String.fromInt weeksInYear ++ ")")
//                 ++ (" for " ++ String.fromInt wy)
//                 ++ ("; received (year " ++ String.fromInt wy ++ ", week " ++ String.fromInt wn ++ ", weekday " ++ String.fromInt wdn ++ ")")
// 
//     else if not (wdn |> isBetweenInt 1 7) then
//         Err <|
//             "Invalid week date: "
//                 ++ ("weekday " ++ String.fromInt wdn ++ " is out of range")
//                 ++ " (1 to 7)"
//                 ++ ("; received (year " ++ String.fromInt wy ++ ", week " ++ String.fromInt wn ++ ", weekday " ++ String.fromInt wdn ++ ")")
// 
//     else
//         Ok <| RD <| daysBeforeWeekYear wy + (wn - 1) * 7 + wdn
pub fn from_week_parts(
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
        + { week_number - 1 }
        * 7
        + weekday_number,
      ))
    }
  }
}

// 
// 
// 
// -- TO RECORDS
// 
// 
// {-| -}
// toOrdinalDate : Date -> { year : Int, ordinalDay : Int }
// toOrdinalDate (RD rd) =
//     let
//         y =
//             year (RD rd)
//     in
//     { year = y
//     , ordinalDay = rd - daysBeforeYear y
//     }
pub type OrdinalDate {
  OrdinalDate(year: Int, ordinal_day: Int)
}

pub fn to_ordinal_date(date: Date) -> OrdinalDate {
  let RD(rd) = date
  let year_ = year(date)

  OrdinalDate(year: year_, ordinal_day: rd - days_before_year(year_))
}

// 
// 
// {-| -}
// toCalendarDate : Date -> { year : Int, month : Month, day : Int }
// toCalendarDate (RD rd) =
//     let
//         date =
//             RD rd |> toOrdinalDate
//     in
//     toCalendarDateHelp date.year Jan date.ordinalDay
pub type CalendarDate {
  CalendarDate(year: Int, month: Month, day: Int)
}

pub fn to_calendar_date(date: Date) -> CalendarDate {
  let ordinal_date = to_ordinal_date(date)

  to_calendar_date_helper(ordinal_date.year, Jan, ordinal_date.ordinal_day)
}

// 
// 
// toCalendarDateHelp : Int -> Month -> Int -> { year : Int, month : Month, day : Int }
// toCalendarDateHelp y m d =
//     let
//         monthDays =
//             daysInMonth y m
// 
//         mn =
//             m |> monthToNumber
//     in
//     if mn < 12 && d > monthDays then
//         toCalendarDateHelp y (mn + 1 |> numberToMonth) (d - monthDays)
// 
//     else
//         { year = y
//         , month = m
//         , day = d
//         }
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

// 
// 
// {-| -}
// toWeekDate : Date -> { weekYear : Int, weekNumber : Int, weekday : Weekday }
// toWeekDate (RD rd) =
//     let
//         wdn =
//             weekdayNumber (RD rd)
// 
//         wy =
//             -- `year <thursday of this week>`
//             year (RD (rd + (4 - wdn)))
// 
//         week1Day1 =
//             daysBeforeWeekYear wy + 1
//     in
//     { weekYear = wy
//     , weekNumber = 1 + (rd - week1Day1) // 7
//     , weekday = wdn |> numberToWeekday
//     }

pub type WeekDate {
  WeekDate(week_year: Int, week_number: Int, weekday: Weekday)
}

pub fn to_week_date(date: Date) {
  let RD(rd) = date
  let weekday_number_ = weekday_number(date)
  let week_year = year(RD(rd + { 4 - weekday_number_ }))
  let week_1_day_1 = days_before_week_year(week_year + 1)

  WeekDate(
    week_year: week_year,
    week_number: 1 + { rd - week_1_day_1 },
    weekday: number_to_weekday(weekday_number_),
  )
}

// 
// 
// 
// -- TO PARTS
// 
// 
// {-| The day of the year (1–366).
// -}
// ordinalDay : Date -> Int
// ordinalDay =
//     toOrdinalDate >> .ordinalDay
pub fn ordinal_day(date: Date) -> Int {
  to_ordinal_date(date).ordinal_day
}

// 
// 
// {-| The month as a [`Month`](https://package.elm-lang.org/packages/elm/time/latest/Time#Month)
// value (`Jan`–`Dec`).
// -}
// month : Date -> Month
// month =
//     toCalendarDate >> .month
pub fn month(date: Date) -> Month {
  to_calendar_date(date).month
}

// 
// 
// {-| The month number (1–12).
// -}
// monthNumber : Date -> Int
// monthNumber =
//     month >> monthToNumber
pub fn month_number(date: Date) -> Int {
  date
  |> month
  |> month_to_number
}

// 
// 
// {-| The quarter of the year (1–4).
// -}
// quarter : Date -> Int
// quarter =
//     month >> monthToQuarter
pub fn quarter(date: Date) -> Int {
  date
  |> month
  |> month_to_quarter
}

// 
// 
// {-| The day of the month (1–31).
// -}
// day : Date -> Int
// day =
//     toCalendarDate >> .day
pub fn day(date: Date) -> Int {
  to_calendar_date(date).day
}

// 
// 
// {-| The ISO week-numbering year. This is not always the same as the
// calendar year.
// -}
// weekYear : Date -> Int
// weekYear =
//     toWeekDate >> .weekYear
pub fn week_year(date: Date) -> Int {
  to_week_date(date).week_year
}

// 
// 
// {-| The ISO week number of the year (1–53).
// -}
// weekNumber : Date -> Int
// weekNumber =
//     toWeekDate >> .weekNumber
pub fn week_number(date: Date) -> Int {
  to_week_date(date).week_number
}

// 
// 
// {-| The weekday as a [`Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#Weekday)
// value (`Mon`–`Sun`).
// -}
// weekday : Date -> Weekday
// weekday =
// //     weekdayNumber >> numberToWeekday
pub fn weekday(date: Date) -> Weekday {
  date
  |> weekday_number
  |> number_to_weekday
}

// 
// 
// 
// -- quarters
// 
// 
// monthToQuarter : Month -> Int
// monthToQuarter m =
//     (monthToNumber m + 2) // 3
fn month_to_quarter(month: Month) -> Int {
  { month_to_number(month) + 2 } / 3
}

// 
// 
// quarterToMonth : Int -> Month
// quarterToMonth q =
//     q * 3 - 2 |> numberToMonth
fn quarter_to_month(quarter: Int) -> Month {
  quarter * 3 - 2
  |> number_to_month
}

// 
// 
// 
// -- TO FORMATTED STRINGS
// 
// 
// {-| Functions to convert date information to strings in a custom language.
// -}
// type alias Language =
//     { monthName : Month -> String
//     , monthNameShort : Month -> String
//     , weekdayName : Weekday -> String
//     , weekdayNameShort : Weekday -> String
//     , dayWithSuffix : Int -> String
//     }

pub type Language {
  Language(
    month_name: fn(Month) -> String,
    month_name_short: fn(Month) -> String,
    weekday_name: fn(Weekday) -> String,
    weekday_name_short: fn(Weekday) -> String,
    day_with_suffix: fn(Int) -> String,
  )
}

// 
// 
// formatField : Language -> Char -> Int -> Date -> String
// formatField language char length date =
//     case char of
//         'y' ->
//             case length of
//                 2 ->
//                     date |> year |> String.fromInt |> String.padLeft 2 '0' |> String.right 2
// 
//                 _ ->
//                     date |> year |> padSignedInt length
// 
//         'Y' ->
//             case length of
//                 2 ->
//                     date |> weekYear |> String.fromInt |> String.padLeft 2 '0' |> String.right 2
// 
//                 _ ->
//                     date |> weekYear |> padSignedInt length
// 
//         'Q' ->
//             case length of
//                 1 ->
//                     date |> quarter |> String.fromInt
// 
//                 2 ->
//                     date |> quarter |> String.fromInt
// 
//                 3 ->
//                     date |> quarter |> String.fromInt |> (++) "Q"
// 
//                 4 ->
//                     date |> quarter |> withOrdinalSuffix
// 
//                 5 ->
//                     date |> quarter |> String.fromInt
// 
//                 _ ->
//                     ""
// 
//         'M' ->
//             case length of
//                 1 ->
//                     date |> monthNumber |> String.fromInt
// 
//                 2 ->
//                     date |> monthNumber |> String.fromInt |> String.padLeft 2 '0'
// 
//                 3 ->
//                     date |> month |> language.monthNameShort
// 
//                 4 ->
//                     date |> month |> language.monthName
// 
//                 5 ->
//                     date |> month |> language.monthNameShort |> String.left 1
// 
//                 _ ->
//                     ""
// 
//         'w' ->
//             case length of
//                 1 ->
//                     date |> weekNumber |> String.fromInt
// 
//                 2 ->
//                     date |> weekNumber |> String.fromInt |> String.padLeft 2 '0'
// 
//                 _ ->
//                     ""
// 
//         'd' ->
//             case length of
//                 1 ->
//                     date |> day |> String.fromInt
// 
//                 2 ->
//                     date |> day |> String.fromInt |> String.padLeft 2 '0'
// 
//                 -- non-standard
//                 3 ->
//                     date |> day |> language.dayWithSuffix
// 
//                 _ ->
//                     ""
// 
//         'D' ->
//             case length of
//                 1 ->
//                     date |> ordinalDay |> String.fromInt
// 
//                 2 ->
//                     date |> ordinalDay |> String.fromInt |> String.padLeft 2 '0'
// 
//                 3 ->
//                     date |> ordinalDay |> String.fromInt |> String.padLeft 3 '0'
// 
//                 _ ->
//                     ""
// 
//         'E' ->
//             case length of
//                 -- abbreviated
//                 1 ->
//                     date |> weekday |> language.weekdayNameShort
// 
//                 2 ->
//                     date |> weekday |> language.weekdayNameShort
// 
//                 3 ->
//                     date |> weekday |> language.weekdayNameShort
// 
//                 -- full
//                 4 ->
//                     date |> weekday |> language.weekdayName
// 
//                 -- narrow
//                 5 ->
//                     date |> weekday |> language.weekdayNameShort |> String.left 1
// 
//                 -- short
//                 6 ->
//                     date |> weekday |> language.weekdayNameShort |> String.left 2
// 
//                 _ ->
//                     ""
// 
//         'e' ->
//             case length of
//                 1 ->
//                     date |> weekdayNumber |> String.fromInt
// 
//                 2 ->
//                     date |> weekdayNumber |> String.fromInt
// 
//                 _ ->
//                     date |> formatField language 'E' length
// 
//         _ ->
//             ""
// formatField : Language -> Char -> Int -> Date -> String
// formatField language char length date =
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
          |> fn(str) { str <> "Q" }

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

// 
// 
// {-| Expects `tokens` list reversed for foldl.
// -}
// formatWithTokens : Language -> List Token -> Date -> String
// formatWithTokens language tokens date =
//     List.foldl
//         (\token formatted ->
//             case token of
//                 Field char length ->
//                     formatField language char length date ++ formatted
// 
//                 Literal str ->
//                     str ++ formatted
//         )
//         ""
//         tokens
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

// 
// 
// {-| Format a date in a custom language using a string as a template.
// 
//     import Date exposing (fromOrdinalDate, formatWithLanguage)
// 
//     formatWithLanguage fr "EEEE, ddd MMMM y" (fromOrdinalDate 1970 1)
//         == "jeudi, 1er janvier 1970"
// 
//     -- assuming `fr` is a custom `Date.Language`
// 
// -}
// formatWithLanguage : Language -> String -> Date -> String
// formatWithLanguage language pattern =
//     let
//         tokens =
//             pattern |> Pattern.fromString |> List.reverse
//     in
//     formatWithTokens language tokens

fn format_with_language(
  language: Language,
  pattern: String,
  date: Date,
) -> String {
  let tokens =
    pattern
    |> pattern.from_string
    |> list.reverse
  format_with_tokens(language, tokens, date)
}

// 
// 
// 
// -- default language
// 
// 
// monthToName : Month -> String
// monthToName m =
//     case m of
//         Jan ->
//             "January"
// 
//         Feb ->
//             "February"
// 
//         Mar ->
//             "March"
// 
//         Apr ->
//             "April"
// 
//         May ->
//             "May"
// 
//         Jun ->
//             "June"
// 
//         Jul ->
//             "July"
// 
//         Aug ->
//             "August"
// 
//         Sep ->
//             "September"
// 
//         Oct ->
//             "October"
// 
//         Nov ->
//             "November"
// 
//         Dec ->
//             "December"
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

// 
// 
// weekdayToName : Weekday -> String
// weekdayToName wd =
//     case wd of
//         Mon ->
//             "Monday"
// 
//         Tue ->
//             "Tuesday"
// 
//         Wed ->
//             "Wednesday"
// 
//         Thu ->
//             "Thursday"
// 
//         Fri ->
//             "Friday"
// 
//         Sat ->
//             "Saturday"
// 
//         Sun ->
//             "Sunday"
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

// 
// 
// ordinalSuffix : Int -> String
// ordinalSuffix n =
//     let
//         -- use 2-digit number
//         nn =
//             n |> modBy 100
//     in
//     case
//         Basics.min
//             (if nn < 20 then
//                 nn
// 
//              else
//                 nn |> modBy 10
//             )
//             4
//     of
//         1 ->
//             "st"
// 
//         2 ->
//             "nd"
// 
//         3 ->
//             "rd"
// 
//         _ ->
//             "th"
fn ordinal_suffix(value: Int) -> String {
  // use 2-digit number
  let value_mod_100 = value % 100
  let value = case value_mod_100 < 20 {
    True -> value_mod_100
    False -> value_mod_100 % 10
  }
  case int.min(value, 4) {
    1 -> "st"
    2 -> "nd"
    3 -> "rd"
    _ -> "th"
  }
}

// 
// 
// {-| Convert an integer into an English ordinal number string (like `"4th"`).
// 
//     import Date exposing (withOrdinalSuffix)
// 
//     withOrdinalSuffix 21 == "21st"
//     withOrdinalSuffix 42 == "42nd"
//     withOrdinalSuffix 0 == "0th"
//     withOrdinalSuffix 23 == "23rd"
//     withOrdinalSuffix -1 == "-1st"
// 
// -}
// withOrdinalSuffix : Int -> String
// withOrdinalSuffix n =
//     String.fromInt n ++ ordinalSuffix n
pub fn with_ordinal_suffix(value: Int) -> String {
  int.to_string(value) <> ordinal_suffix(value)
}

// 
// 
// language_en : Language
// language_en =
//     { monthName = monthToName
//     , monthNameShort = monthToName >> String.left 3
//     , weekdayName = weekdayToName
//     , weekdayNameShort = weekdayToName >> String.left 3
//     , dayWithSuffix = withOrdinalSuffix
//     }
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

// 
// 
// {-| Format a date using a string as a template.
// 
//     import Date exposing (fromOrdinalDate, format)
// 
//     format "EEEE, d MMMM y" (fromOrdinalDate 1970 1)
//         == "Thursday, 1 January 1970"
// 
// Alphabetic characters in the template represent date information; the number of
// times a character is repeated specifies the form of a name (e.g. `"Tue"`,
// `"Tuesday"`) or the padding of a number (e.g. `"1"`, `"01"`).
// 
// Alphabetic characters can be escaped within single-quotes; a single-quote can
// be escaped as a sequence of two single-quotes, whether appearing inside or
// outside an escaped sequence.
// 
// Templates are based on Date Format Patterns in [Unicode Technical
// Standard #35][uts35]. Only the following subset of formatting characters
// are available:
// 
//     "y" -- year
// 
//     "Y" -- week-numbering year
// 
//     "Q" -- quarter
// 
//     "M" -- month (number or name)
// 
//     "w" -- week number
// 
//     "d" -- day
// 
//     "D" -- ordinal day
// 
//     "E" -- weekday name
// 
//     "e" -- weekday number
// 
// [uts35]: http://www.unicode.org/reports/tr35/tr35-43/tr35-dates.html#Date_Format_Patterns
// 
// The non-standard pattern field "ddd" is available to indicate the day of the
// month with an ordinal suffix (e.g. `"1st"`, `"15th"`), as the current standard
// does not include such a field.
// 
//     format "MMMM ddd, y" (fromOrdinalDate 1970 1)
//         == "January 1st, 1970"
// 
// -}
// format : String -> Date -> String
// format pattern =
//     formatWithLanguage language_en pattern
pub fn format(pattern: String, date: Date) -> String {
  format_with_language(language_en(), pattern, date)
}

// 
// 
// {-| Convert a date to a string in ISO 8601 extended format.
// 
//     import Date exposing (fromOrdinalDate, toIsoString)
// 
//     toIsoString (fromOrdinalDate 2001 1)
//         == "2001-01-01"
// 
// -}
// toIsoString : Date -> String
// toIsoString =
//     format "yyyy-MM-dd"
pub fn to_iso_format(date: Date) -> String {
  format("yyyy-MM-dd", date)
}

// 
// 
// 
// -- FROM ISO 8601 STRINGS
// 
// 
// {-| Attempt to create a date from a string in [ISO 8601][iso8601] format.
// Calendar dates, week dates, and ordinal dates are all supported in extended
// and basic format.
// 
//     import Date exposing (fromIsoString, fromCalendarDate, fromWeekDate, fromOrdinalDate)
//     import Time exposing (Month(..), Weekday(..))
// 
//     -- calendar date
//     fromIsoString "2018-09-26"
//         == Ok (fromCalendarDate 2018 Sep 26)
// 
// 
//     -- week date
// fromIsoString "2018-W39-3"
//         == Ok (fromWeekDate 2018 39 Wed)
// 
// 
//     -- ordinal date
//     fromIsoString "2018-269"
//         == Ok (fromOrdinalDate 2018 269)
// 
// The string must represent a valid date; unlike `fromCalendarDate` and
// friends, any out-of-range values will fail to produce a date.
// 
//     fromIsoString "2018-02-29"
//         == Err "Invalid calendar date (2018, 2, 29)"
// 
// [iso8601]: https://en.wikipedia.org/wiki/ISO_8601
// 
// -}
// fromIsoString : String -> Result String Date
// fromIsoString =
//     Parser.run
//         (Parser.succeed identity
//             |= parser
//             |. (Parser.oneOf
//                     [ Parser.map Ok
//                         Parser.end
//                     , Parser.map (always (Err "Expected a date only, not a date and time"))
//                         (Parser.chompIf ((==) 'T'))
//                     , Parser.succeed (Err "Expected a date only")
//                     ]
//                     |> Parser.andThen resultToParser
//                )
//         )
//         >> Result.mapError (List.head >> Maybe.map deadEndToString >> Maybe.withDefault "")
pub fn from_iso_string(str: String) -> Result(Date, String) {
  let assert Ok(tokens) = nibble_lexer.run(str, days_parse.lexer())
  nibble.run(tokens, parser())
  |> result.map_error(fn(err) { string.inspect(err) })
}

// 
// 
// deadEndToString : Parser.DeadEnd -> String
// deadEndToString { problem } =
//     case problem of
//         Parser.Problem message ->
//             message
// 
//         _ ->
//             "Expected a date in ISO 8601 format"
// 
// 
// resultToParser : Result String a -> Parser a
// resultToParser result =
//     case result of
//         Ok x ->
//             Parser.succeed x
// 
//         Err message ->
//             Parser.problem message
// 
// 
// 
// -- day of year
// 
// 
// type DayOfYear
//     = MonthAndDay Int Int
//     | WeekAndWeekday Int Int
//     | OrdinalDay Int
type DayOfYear {
  MonthAndDay(Int, Int)
  WeekAndWeekday(Int, Int)
  OrdinalDay(Int)
}

// 
// 
// fromYearAndDayOfYear : ( Int, DayOfYear ) -> Result String Date
// fromYearAndDayOfYear ( y, doy ) =
//     case doy of
//         MonthAndDay mn d ->
//             fromCalendarParts y mn d
// 
//         WeekAndWeekday wn wdn ->
//             fromWeekParts y wn wdn
// 
//         OrdinalDay od ->
//             fromOrdinalParts y od
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

// 
// 
// 
// -- parser
// 
// 
// parser : Parser Date
// parser =
//     Parser.succeed Tuple.pair
//         |= int4
//         |= dayOfYear
//         |> Parser.andThen
//             (fromYearAndDayOfYear >> resultToParser)
fn parser() {
  use year <- nibble.do(int_4())
  use _ <- nibble.do(nibble.token(Dash))
  use day_of_year <- nibble.do(parse_day_of_year())

  case day_of_year {
    MonthAndDay(month, day) -> {
      nibble.return(from_calendar_date(year, number_to_month(month), day))
    }
    WeekAndWeekday(week, weekday) -> {
      io.println(string.inspect(year))
      io.println(string.inspect(week))
      io.println(string.inspect(weekday))
      nibble.return(from_week_date(year, week, number_to_weekday(weekday)))
    }
    OrdinalDay(ordinal_day) -> {
      todo
    }
  }
}

// 
// 
// dayOfYear : Parser DayOfYear
// dayOfYear =
//     Parser.oneOf
//         [ Parser.succeed identity
//             -- extended format
//             |. Parser.token "-"
//             |= Parser.oneOf
//                 [ Parser.backtrackable
//                     (Parser.map OrdinalDay
//                         int3
//                         |> Parser.andThen Parser.commit
//                     )
//                 , Parser.succeed MonthAndDay
//                     |= int2
//                     |= Parser.oneOf
//                         [ Parser.succeed identity
//                             |. Parser.token "-"
//                             |= int2
//                         , Parser.succeed 1
//                         ]
//                 , Parser.succeed WeekAndWeekday
//                     |. Parser.token "W"
//                     |= int2
//                     |= Parser.oneOf
//                         [ Parser.succeed identity
//                             |. Parser.token "-"
//                             |= int1
//                         , Parser.succeed 1
//                         ]
//                 ]
// 
//         -- basic format
//         , Parser.backtrackable
//             (Parser.succeed MonthAndDay
//                 |= int2
//                 |= Parser.oneOf
//                     [ int2
//                     , Parser.succeed 1
//                     ]
//                 |> Parser.andThen Parser.commit
//             )
//         , Parser.map OrdinalDay
//             int3
//         , Parser.succeed WeekAndWeekday
//             |. Parser.token "W"
//             |= int2
//             |= Parser.oneOf
//                 [ int1
//                 , Parser.succeed 1
//                 ]
//         , Parser.succeed
//             (OrdinalDay 1)
//         ]
fn parse_day_of_year() {
  nibble.one_of([parse_month_and_day(), parse_week_and_weekday()])
}

fn parse_month_and_day() {
  use month <- nibble.do(int_2())
  use _ <- nibble.do(nibble.token(Dash))
  use day <- nibble.do(int_2())

  nibble.return(MonthAndDay(month, day))
}

fn parse_week_and_weekday() {
  use _ <- nibble.do(nibble.token(WeekToken))
  use week <- nibble.do(int_2())
  use _ <- nibble.do(nibble.token(Dash))
  use day <- nibble.do(int_1())

  nibble.return(WeekAndWeekday(week, day))
}

// 
// 
// int4 : Parser Int
// int4 =
//     Parser.succeed ()
//         |. Parser.oneOf
//             [ Parser.chompIf (\c -> c == '-')
//             , Parser.succeed ()
//             ]
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |> Parser.mapChompedString
//             (\str _ -> String.toInt str |> Maybe.withDefault 0)
fn int_4() {
  use token <- nibble.do(
    nibble.take_if("Expecting 4 digits", fn(token) {
      case token {
        Digits(str) -> {
          string.length(str) == 4
        }
        _ -> False
      }
    }),
  )

  let assert Digits(str) = token

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

// 
// 
// int3 : Parser Int
// int3 =
//     Parser.succeed ()
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |> Parser.mapChompedString
//             (\str _ -> String.toInt str |> Maybe.withDefault 0)
// 
// 
// int2 : Parser Int
// int2 =
//     Parser.succeed ()
//         |. Parser.chompIf Char.isDigit
//         |. Parser.chompIf Char.isDigit
//         |> Parser.mapChompedString
//             (\str _ -> String.toInt str |> Maybe.withDefault 0)
fn int_2() {
  use token <- nibble.do(
    nibble.take_if("Expecting 2 digits", fn(token) {
      case token {
        Digits(str) -> {
          string.length(str) == 2
        }
        _ -> False
      }
    }),
  )

  let assert Digits(str) = token

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

// 
// 
// int1 : Parser Int
// int1 =
//     Parser.chompIf Char.isDigit
//         |> Parser.mapChompedString
//             (\str _ -> String.toInt str |> Maybe.withDefault 0)
fn int_1() {
  use token <- nibble.do(
    nibble.take_if("Expecting 1 digits", fn(token) {
      case token {
        Digits(str) -> {
          string.length(str) == 1
        }
        _ -> False
      }
    }),
  )

  let assert Digits(str) = token

  let assert Ok(int) = int.parse(str)

  nibble.return(int)
}

// 
// 
// 
// -- ARITHMETIC
// 
// 
// {-| -}
// type Unit
//     = Years
//     | Months
//     | Weeks
//     | Days
pub type Unit {
  Years
  Months
  Weeks
  Days
}

// 
// 
// {-| Get a past or future date by adding a number of units to a date.
// 
//     import Date exposing (Unit(..), add, fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     add Weeks -2 (fromCalendarDate 2018 Sep 26)
//         == fromCalendarDate 2018 Sep 12
// 
// When adding `Years` or `Months`, day values are clamped to the end of the
// month if necessary.
// 
//     add Months 1 (fromCalendarDate 2000 Jan 31)
//         == fromCalendarDate 2000 Feb 29
// 
// -}
// add : Unit -> Int -> Date -> Date
// add unit n (RD rd) =
//     case unit of
//         Years ->
//             RD rd |> add Months (12 * n)
// 
//         Months ->
//             let
//                 date =
//                     RD rd |> toCalendarDate
// 
//                 wholeMonths =
//                     12 * (date.year - 1) + (monthToNumber date.month - 1) + n
// 
//                 y =
//                     floorDiv wholeMonths 12 + 1
// 
//                 m =
//                     (wholeMonths |> modBy 12) + 1 |> numberToMonth
//             in
//             RD <| daysBeforeYear y + daysBeforeMonth y m + Basics.min date.day (daysInMonth y m)
// 
//         Weeks ->
//             RD <| rd + 7 * n
// 
//         Days ->
//             RD <| rd + n
pub fn add(unit: Unit, count: Int, date: Date) -> Date {
  let RD(rd) = date
  case unit {
    Years -> {
      add(Months, { 12 * count }, date)
    }
    Months -> {
      let calendar_date = to_calendar_date(date)
      let whole_months =
        12
        * { calendar_date.year - 1 }
        + { month_to_number(calendar_date.month) - 1 }
        + count

      let year = floor_div(whole_months, 12) + 1
      let month = number_to_month({ whole_months % 12 } + 1)

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

// 
// 
// {-| The number of whole months between date and 0001-01-01 plus fraction
// representing the current month. Only used for diffing months.
// -}
// toMonths : RataDie -> Float
// toMonths rd =
//     let
//         date =
//             RD rd |> toCalendarDate
// 
//         wholeMonths =
//             12 * (date.year - 1) + (monthToNumber date.month - 1)
//     in
//     toFloat wholeMonths + toFloat date.day / 100
fn to_months(rd: RataDie) -> Float {
  let calendar_date = to_calendar_date(RD(rd))
  let whole_months =
    12
    * { calendar_date.year - 1 }
    + { month_to_number(calendar_date.month) - 1 }

  // Not designed to be 0-1 of a month - just used for diffing
  let fraction = int.to_float(calendar_date.day) /. 100.0

  int.to_float(whole_months) +. fraction
}

// 
// 
// {-| Get the difference, as a number of whole units, between two dates.
// 
//     import Date exposing (Unit(..), diff, fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     diff Months
//         (fromCalendarDate 2020 Jan 2)
//         (fromCalendarDate 2020 Apr 1)
//         == 2
// 
// -}
// diff : Unit -> Date -> Date -> Int
// diff unit (RD rd1) (RD rd2) =
//     case unit of
//         Years ->
//             (toMonths rd2 - toMonths rd1 |> truncate) // 12
// 
//         Months ->
//             toMonths rd2 - toMonths rd1 |> truncate
// 
//         Weeks ->
//             (rd2 - rd1) // 7
// 
//         Days ->
//             rd2 - rd1
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

// 
// 
// 
// -- ROUNDING
// 
// 
// {-| -}
// type Interval
//     = Year
//     | Quarter
//     | Month
//     | Week
//     | Monday
//     | Tuesday
//     | Wednesday
//     | Thursday
//     | Friday
//     | Saturday
//     | Sunday
//     | Day
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

// 
// 
// daysSincePreviousWeekday : Weekday -> Date -> Int
// daysSincePreviousWeekday wd date =
//     (weekdayNumber date + 7 - weekdayToNumber wd) |> modBy 7
fn days_since_previous_weekday(weekday: Weekday, date: Date) -> Int {
  { weekday_number(date) + 7 - weekday_to_number(weekday) } % 7
}

// 
// 
// {-| Round down a date to the beginning of the closest interval. The resulting
// date will be less than or equal to the one provided.
// 
//     import Date exposing (Interval(..), floor, fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     floor Tuesday (fromCalendarDate 2018 May 11)
//         == fromCalendarDate 2018 May 8
// 
// -}
// floor : Interval -> Date -> Date
// floor interval ((RD rd) as date) =
//     case interval of
//         Year ->
//             firstOfYear (year date)
// 
//         Quarter ->
//             firstOfMonth (year date) (quarter date |> quarterToMonth)
// 
//         Month ->
//             firstOfMonth (year date) (month date)
// 
//         Week ->
//             RD <| rd - daysSincePreviousWeekday Mon date
// 
//         Monday ->
//             RD <| rd - daysSincePreviousWeekday Mon date
// 
//         Tuesday ->
//             RD <| rd - daysSincePreviousWeekday Tue date
// 
//         Wednesday ->
//             RD <| rd - daysSincePreviousWeekday Wed date
// 
//         Thursday ->
//             RD <| rd - daysSincePreviousWeekday Thu date
// 
//         Friday ->
//             RD <| rd - daysSincePreviousWeekday Fri date
// 
//         Saturday ->
//             RD <| rd - daysSincePreviousWeekday Sat date
// 
//         Sunday ->
//             RD <| rd - daysSincePreviousWeekday Sun date
// 
//         Day ->
//             date
pub fn floor(interval: Interval, date: Date) -> Date {
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

// 
// 
// intervalToUnits : Interval -> ( Int, Unit )
// intervalToUnits interval =
//     case interval of
//         Year ->
//             ( 1, Years )
// 
//         Quarter ->
//             ( 3, Months )
// 
//         Month ->
//             ( 1, Months )
// 
//         Day ->
//             ( 1, Days )
// 
//         _ ->
//             ( 1, Weeks )
fn interval_to_units(interval: Interval) -> #(Int, Unit) {
  case interval {
    Year -> #(1, Years)
    Quarter -> #(3, Months)
    Month -> #(1, Months)
    Day -> #(1, Days)
    _ -> #(1, Weeks)
  }
}

// 
// 
// {-| Round up a date to the beginning of the closest interval. The resulting
// date will be greater than or equal to the one provided.
// 
//     import Date exposing (Interval(..), ceiling, fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     ceiling Tuesday (fromCalendarDate 2018 May 11)
//         == fromCalendarDate 2018 May 15
// 
// -}
// ceiling : Interval -> Date -> Date
// ceiling interval date =
//     let
//         floored =
//             date |> floor interval
//     in
//     if date == floored then
//         date
// 
//     else
//         let
//             ( n, unit ) =
//                 interval |> intervalToUnits
//         in
//         floored |> add unit n
// 
// 
// 
// -- LISTS
pub fn ceiling(interval: Interval, date: Date) -> Date {
  let floored_date = floor(interval, date)
  case date == floored_date {
    True -> date
    False -> {
      let #(n, unit) = interval_to_units(interval)
      add(unit, n, floored_date)
    }
  }
}

// 
// 
// {-| Create a list of dates, at rounded intervals, increasing by a step value,
// between two dates. The list will start on or after the first date, and end
// before the second date.
// 
//     import Date exposing (Interval(..), range, fromCalendarDate)
//     import Time exposing (Month(..))
// 
//     start = fromCalendarDate 2018 May 8
//     until = fromCalendarDate 2018 May 14
// 
//     range Day 2 start until
//         == [ fromCalendarDate 2018 May 8
//            , fromCalendarDate 2018 May 10
//            , fromCalendarDate 2018 May 12
//            ]
// 
// -}
// range : Interval -> Int -> Date -> Date -> List Date
// range interval step (RD start) (RD until) =
//     let
//         ( n, unit ) =
//             interval |> intervalToUnits
// 
//         (RD first) =
//             RD start |> ceiling interval
//     in
//     if first < until then
//         rangeHelp unit (Basics.max 1 step * n) until [] first
// 
//     else
//         []
pub fn range(
  interval: Interval,
  step: Int,
  start_date: Date,
  until_date: Date,
) -> List(Date) {
  let #(n, unit) = interval_to_units(interval)
  let RD(first_rd) = ceiling(interval, start_date)
  let RD(until_rd) = until_date

  case first_rd < until_rd {
    True -> {
      range_help(unit, int.max(1, step * n), until_rd, [], first_rd)
    }
    False -> []
  }
}

// 
// 
// rangeHelp : Unit -> Int -> RataDie -> List Date -> RataDie -> List Date
// rangeHelp unit step until revList current =
//     if current < until then
//         let
//             (RD next) =
//                 RD current |> add unit step
//         in
//         rangeHelp unit step until (RD current :: revList) next
// 
//     else
//         List.reverse revList
fn range_help(
  unit: Unit,
  step: Int,
  until_rd: RataDie,
  reversed_list: List(Date),
  current_rd: RataDie,
) -> List(Date) {
  case current_rd < until_rd {
    True -> {
      let RD(next_rd) = add(unit, step, RD(current_rd))
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

// 
// 
// 
// -- POSIX
// 
// 
// {-| Create a date from a time [`Zone`][zone] and a [`Posix`][posix] time. This
// conversion loses the time information associated with the `Posix` value.
// 
//     import Date exposing (fromCalendarDate, fromPosix)
//     import Time exposing (millisToPosix, utc, Month(..))
// 
//     fromPosix utc (millisToPosix 0)
//         == fromCalendarDate 1970 Jan 1
// 
// [zone]: https://package.elm-lang.org/packages/elm/time/latest/Time#Zone
// [posix]: https://package.elm-lang.org/packages/elm/time/latest/Time#Posix
// 
// -}
// fromPosix : Time.Zone -> Posix -> Date
// fromPosix zone posix =
//     fromCalendarDate
//         (posix |> Time.toYear zone)
//         (posix |> Time.toMonth zone)
//         (posix |> Time.toDay zone)
// 
// 
// {-| Get the current local date. See [this page][calendarexample] for a full example.
// 
// [calendarexample]: https://github.com/justinmimbs/date/blob/master/examples/Calendar.elm
// 
// -}
// today : Task x Date
// today =
//     Task.map2 fromPosix Time.here Time.now
// 
// 
// 
// -- ORDERING
// 
// 
// {-| Compare two dates. This can be used as the compare function for
// `List.sortWith`.
// 
//     import Date exposing (fromOrdinalDate, compare)
// 
//     compare (fromOrdinalDate 1970 1) (fromOrdinalDate 2038 1)
//         == LT
// 
// -}
// compare : Date -> Date -> Order
// compare (RD a) (RD b) =
//     Basics.compare a b
pub fn compare(date1: Date, date2: Date) -> Order {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  int.compare(rd_1, rd_2)
}

// 
// 
// {-| Test if a date is within a range, inclusive of the range values.
// 
//     import Date exposing (fromOrdinalDate, isBetween)
// 
//     minimum = fromOrdinalDate 1970 1
//     maximum = fromOrdinalDate 2038 1
// 
//     isBetween minimum maximum (fromOrdinalDate 1969 201)
//         == False
// 
// -}
// isBetween : Date -> Date -> Date -> Bool
// isBetween (RD a) (RD b) (RD x) =
//     isBetweenInt a b x
pub fn is_between(value: Date, lower: Date, upper: Date) -> Bool {
  let RD(value_rd) = value
  let RD(lower_rd) = lower
  let RD(upper_rd) = upper

  is_between_int(value_rd, lower_rd, upper_rd)
}

// 
// 
// {-| Find the lesser of two dates.
// 
//     import Date exposing (fromOrdinalDate, min)
// 
//     min (fromOrdinalDate 1970 1) (fromOrdinalDate 2038 1)
//         == (fromOrdinalDate 1970 1)
// 
// -}
// min : Date -> Date -> Date
// min ((RD a) as dateA) ((RD b) as dateB) =
//     if a < b then
//         dateA
// 
//     else
//         dateB
pub fn min(date1: Date, date2: Date) -> Date {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  case rd_1 < rd_2 {
    True -> date1
    False -> date2
  }
}

// 
// 
// {-| Find the greater of two dates.
// 
//     import Date exposing (fromOrdinalDate, max)
// 
//     max (fromOrdinalDate 1970 1) (fromOrdinalDate 2038 1)
//         == (fromOrdinalDate 2038 1)
// 
// -}
// max : Date -> Date -> Date
// max ((RD a) as dateA) ((RD b) as dateB) =
//     if a < b then
//         dateB
// 
//     else
//         dateA
pub fn max(date1: Date, date2: Date) -> Date {
  let RD(rd_1) = date1
  let RD(rd_2) = date2

  case rd_1 < rd_2 {
    True -> date2
    False -> date1
  }
}

// 
// 
// {-| Clamp a date within a range.
// 
//     import Date exposing (fromOrdinalDate, clamp)
// 
//     minimum = fromOrdinalDate 1970 1
//     maximum = fromOrdinalDate 2038 1
// 
//     clamp minimum maximum (fromOrdinalDate 1969 201)
//         == fromOrdinalDate 1970 1
// 
// -}
// clamp : Date -> Date -> Date -> Date
// clamp ((RD a) as dateA) ((RD b) as dateB) ((RD x) as dateX) =
//     if x < a then
//         dateA
// 
//     else if b < x then
//         dateB
// 
//     else
//         dateX
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

// 
// 
// 
// -- NUMBERS OF DAYS
// 
// 
// daysInMonth : Int -> Month -> Int
// daysInMonth y m =
//     case m of
//         Jan ->
//             31
// 
//         Feb ->
//             if isLeapYear y then
//                 29
// 
//             else
//                 28
// 
//         Mar ->
//             31
// 
//         Apr ->
//             30
// 
//         May ->
//             31
// 
//         Jun ->
//             30
// 
//         Jul ->
//             31
// 
//         Aug ->
//             31
// 
//         Sep ->
//             30
// 
//         Oct ->
//             31
// 
//         Nov ->
//             30
// 
//         Dec ->
//             31
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

// 
// 
// daysBeforeMonth : Int -> Month -> Int
// daysBeforeMonth y m =
//     let
//         leapDays =
//             if isLeapYear y then
//                 1
// 
//             else
//                 0
//     in
//     case m of
//         Jan ->
//             0
// 
//         Feb ->
//             31
// 
//         Mar ->
//             59 + leapDays
// 
//         Apr ->
//             90 + leapDays
// 
//         May ->
//             120 + leapDays
// 
//         Jun ->
//             151 + leapDays
// 
//         Jul ->
//             181 + leapDays
// 
//         Aug ->
//             212 + leapDays
// 
//         Sep ->
//             243 + leapDays
// 
//         Oct ->
//             273 + leapDays
// 
//         Nov ->
//             304 + leapDays
// 
//         Dec ->
//             334 + leapDays
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

// 
// 
// 
// -- MONTH AND WEEKDAY NUMBERS
// 
// 
// {-| Maps `Jan`–`Dec` to 1–12.
// -}
// monthToNumber : Month -> Int
// monthToNumber m =
//     case m of
//         Jan ->
//             1
// 
//         Feb ->
//             2
// 
//         Mar ->
//             3
// 
//         Apr ->
//             4
// 
//         May ->
//             5
// 
//         Jun ->
//             6
// 
//         Jul ->
//             7
// 
//         Aug ->
//             8
// 
//         Sep ->
//             9
// 
//         Oct ->
//             10
// 
//         Nov ->
//             11
// 
//         Dec ->
//             12

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

// 
// 
// {-| Maps 1–12 to `Jan`–`Dec`.
// -}
// numberToMonth : Int -> Month
// numberToMonth mn =
//     case Basics.max 1 mn of
//         1 ->
//             Jan
// 
//         2 ->
//             Feb
// 
//         3 ->
//             Mar
// 
//         4 ->
//             Apr
// 
//         5 ->
//             May
// 
//         6 ->
//             Jun
// 
//         7 ->
//             Jul
// 
//         8 ->
//             Aug
// 
//         9 ->
//             Sep
// 
//         10 ->
//             Oct
// 
//         11 ->
//             Nov
// 
//         _ ->
//             Dec
fn number_to_month(month_number: Int) -> Month {
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

// {-| Maps `Mon`–`Sun` to 1-7.
// -}
// weekdayToNumber : Weekday -> Int
// weekdayToNumber wd =
//     case wd of
//         Mon ->
//             1
// 
//         Tue ->
//             2
// 
//         Wed ->
//             3
// 
//         Thu ->
//             4
// 
//         Fri ->
//             5
// 
//         Sat ->
//             6
// 
//         Sun ->
//             7
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

// 
// 
// {-| Maps 1-7 to `Mon`–`Sun`.
// -}
// numberToWeekday : Int -> Weekday
// numberToWeekday wdn =
//     case Basics.max 1 wdn of
//         1 ->
//             Mon
// 
//         2 ->
//             Tue
// 
//         3 ->
//             Wed
// 
//         4 ->
//             Thu
// 
//         5 ->
//             Fri
// 
//         6 ->
//             Sat
// 
//         _ ->
//             Sun
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

// 
// 
// 
// -- HELPERS
// 
// 
// padSignedInt : Int -> Int -> String
// padSignedInt length int =
//     (if int < 0 then
//         "-"
// 
//      else
//         ""
//     )
//         ++ (abs int |> String.fromInt |> String.padLeft length '0')
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

// 
// 
// floorDiv : Int -> Int -> Int
// floorDiv a b =
//     Basics.floor (toFloat a / toFloat b)
fn floor_div(a: Int, b: Int) -> Int {
  int.floor_divide(a, b)
  // We know we're not calling this with b == 0 so the unwrap value will not be used
  |> result.unwrap(0)
}

// 
// 
// {-| integer division, returning (Quotient, Remainder)
// -}
// divWithRemainder : Int -> Int -> ( Int, Int )
// divWithRemainder a b =
//     ( floorDiv a b, a |> modBy b )
fn div_with_remainder(a: Int, b: Int) -> #(Int, Int) {
  #(floor_div(a, b), a % b)
}

// 
// 
// isBetweenInt : Int -> Int -> Int -> Bool
// isBetweenInt a b x =
//     a <= x && x <= b
fn is_between_int(value: Int, lower: Int, upper: Int) -> Bool {
  lower <= value && value <= upper
}
