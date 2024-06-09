import gleam/list
import gleam/order
import gleam/result
import gleeunit
import gleeunit/should

import date.{type CalendarDate, type Date, type WeekDate, CalendarDate, WeekDate}
import french_language.{language_fr}

pub fn main() {
  gleeunit.main()
}

pub fn leap_year_test() {
  date.is_leap_year(2024)
  |> should.equal(True)

  date.is_leap_year(2022)
  |> should.equal(False)
}

// module Tests exposing (suite)

// import Date exposing (Date, Interval(..), Unit(..))
// import Language
// import Shim exposing (Expectation, Test, describe, equal, test)
// import Time exposing (Month(..), Weekday(..))

// -- import Expect exposing (Expectation)
// -- import Test exposing (Test, describe, test)
// -------------------------------------------------------------------------------

// {-| temporary collection of all tests

//     run suite

// -}
// suite : Test
// suite =
//     describe "Date"
//         [ test_CalendarDate
//         , test_RataDie
//         , test_WeekDate
//         , test_format
//         , test_formatWithLanguage
//         , test_add
//         , test_diff
//         , test_floor
//         , test_ceiling
//         , test_range
//         , test_fromIsoString
//         , test_fromOrdinalDate
//         , test_fromCalendarDate
//         , test_fromWeekDate
//         , test_numberToMonth
//         , test_numberToWeekday
//         , test_compare
//         , test_isBetween
//         , test_min
//         , test_max
//         , test_clamp
//         ]

// -------------------------------------------------------------------------------

// test_CalendarDate : Test
// test_CalendarDate =
//     describe "CalendarDate"
//         [ describe "CalendarDate and Date are are isomorphic"
//             (List.concat
//                 [ List.range 1897 1905
//                 , List.range 1997 2025
//                 , List.range -5 5
//                 , List.range -105 -95
//                 , List.range -405 -395
//                 ]
//                 |> List.concatMap calendarDatesInYear
//                 |> List.map
//                     (\calendarDate ->
//                         test (Debug.toString calendarDate) <|
//                             \() -> expectIsomorphism fromCalendarDate toCalendarDate calendarDate
//                     )
//             )
//         ]
pub fn calendar_date_test() {
  list.concat([
    list.range(1897, 1905),
    list.range(1997, 2025),
    list.range(-5, 5),
    list.range(-105, -95),
    list.range(-405, -395),
  ])
  |> list.map(calendar_dates_in_year)
  |> list.concat
  |> list.each(fn(date) {
    expect_isomorphism(from_calendar_date, to_calendar_date, date)
  })
}

// test_RataDie : Test
// test_RataDie =
//     describe "RataDie"
//         [ test "a list of contiguous CalendarDates, converted to RataDie, is equivalent to a list of contiguous integers" <|
//             \() ->
//                 List.range 1997 2025
//                     |> List.concatMap (calendarDatesInYear >> List.map (fromCalendarDate >> Date.toRataDie))
//                     |> equal
//                         (List.range
//                             (Date.fromCalendarDate 1997 Jan 1 |> Date.toRataDie)
//                             (Date.fromCalendarDate 2025 Dec 31 |> Date.toRataDie)
//                         )
//         ]
pub fn rata_die_test() {
  list.range(1997, 2025)
  |> list.map(fn(year) {
    year
    |> calendar_dates_in_year
    |> list.map(fn(date) { date |> from_calendar_date |> date.to_rata_die })
  })
  |> list.concat
  |> should.equal(list.range(
    date.from_calendar_date(1997, date.Jan, 1) |> date.to_rata_die,
    date.from_calendar_date(2025, date.Dec, 31) |> date.to_rata_die,
  ))
}

// test_WeekDate : Test
// test_WeekDate =
//     describe "WeekDate"
//         [ describe "WeekDate and Date are isomorphic"
//             (List.concat
//                 [ List.range 1997 2025
//                 , List.range -5 5
//                 ]
//                 |> List.concatMap calendarDatesInYear
//                 |> List.map
//                     (\calendarDate ->
//                         test (Debug.toString calendarDate) <|
//                             \() -> expectIsomorphism toWeekDate fromWeekDate (fromCalendarDate calendarDate)
//                     )
//             )
//         , describe "toWeekDate produces results that match samples"
//             ([ ( CalendarDate 2005 Jan 1, WeekDate 2004 53 Sat )
//              , ( CalendarDate 2005 Jan 2, WeekDate 2004 53 Sun )
//              , ( CalendarDate 2005 Dec 31, WeekDate 2005 52 Sat )
//              , ( CalendarDate 2007 Jan 1, WeekDate 2007 1 Mon )
//              , ( CalendarDate 2007 Dec 30, WeekDate 2007 52 Sun )
//              , ( CalendarDate 2007 Dec 31, WeekDate 2008 1 Mon )
//              , ( CalendarDate 2008 Jan 1, WeekDate 2008 1 Tue )
//              , ( CalendarDate 2008 Dec 28, WeekDate 2008 52 Sun )
//              , ( CalendarDate 2008 Dec 29, WeekDate 2009 1 Mon )
//              , ( CalendarDate 2008 Dec 30, WeekDate 2009 1 Tue )
//              , ( CalendarDate 2008 Dec 31, WeekDate 2009 1 Wed )
//              , ( CalendarDate 2009 Jan 1, WeekDate 2009 1 Thu )
//              , ( CalendarDate 2009 Dec 31, WeekDate 2009 53 Thu )
//              , ( CalendarDate 2010 Jan 1, WeekDate 2009 53 Fri )
//              , ( CalendarDate 2010 Jan 2, WeekDate 2009 53 Sat )
//              , ( CalendarDate 2010 Jan 3, WeekDate 2009 53 Sun )
//              ]
//                 |> List.map
//                     (\( calendarDate, weekDate ) ->
//                         test (Debug.toString calendarDate) <|
//                             \() -> fromCalendarDate calendarDate |> toWeekDate |> equal weekDate
//                     )
//             )
//         ]

pub fn week_date_isomorphic_test() {
  list.concat([list.range(1997, 2025), list.range(-5, 5)])
  |> list.map(calendar_dates_in_year)
  |> list.concat
  |> list.each(fn(date) {
    expect_isomorphism(to_week_date, from_week_date, from_calendar_date(date))
  })
}

pub fn week_date_sample_test() {
  [
    #(CalendarDate(2005, date.Jan, 1), WeekDate(2004, 53, date.Sat)),
    #(CalendarDate(2005, date.Jan, 2), WeekDate(2004, 53, date.Sun)),
    #(CalendarDate(2005, date.Dec, 31), WeekDate(2005, 52, date.Sat)),
    #(CalendarDate(2007, date.Jan, 1), WeekDate(2007, 1, date.Mon)),
    #(CalendarDate(2007, date.Dec, 30), WeekDate(2007, 52, date.Sun)),
    #(CalendarDate(2007, date.Dec, 31), WeekDate(2008, 1, date.Mon)),
    #(CalendarDate(2008, date.Jan, 1), WeekDate(2008, 1, date.Tue)),
    #(CalendarDate(2008, date.Dec, 28), WeekDate(2008, 52, date.Sun)),
    #(CalendarDate(2008, date.Dec, 29), WeekDate(2009, 1, date.Mon)),
    #(CalendarDate(2008, date.Dec, 30), WeekDate(2009, 1, date.Tue)),
    #(CalendarDate(2008, date.Dec, 31), WeekDate(2009, 1, date.Wed)),
    #(CalendarDate(2009, date.Jan, 1), WeekDate(2009, 1, date.Thu)),
    #(CalendarDate(2009, date.Dec, 31), WeekDate(2009, 53, date.Thu)),
    #(CalendarDate(2010, date.Jan, 1), WeekDate(2009, 53, date.Fri)),
    #(CalendarDate(2010, date.Jan, 2), WeekDate(2009, 53, date.Sat)),
    #(CalendarDate(2010, date.Jan, 3), WeekDate(2009, 53, date.Sun)),
  ]
  |> list.map(fn(tuple) {
    let #(calendar_date, week_date) = tuple
    should.equal(from_calendar_date(calendar_date) |> to_week_date, week_date)
  })
}

// test_format : Test
// test_format =
//     let
//         toTest : Date -> ( String, String ) -> Test
//         toTest date ( pattern, expected ) =
//             test ("\"" ++ pattern ++ "\" " ++ Debug.toString date) <|
//                 \() -> date |> Date.format pattern |> equal expected
//     in
//     describe "format"
//         [ describe "replaces supported character patterns" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2001 Jan 2))
//                 [ ( "y", "2001" )
//                 , ( "yy", "01" )
//                 , ( "yyy", "2001" )
//                 , ( "yyyy", "2001" )
//                 , ( "yyyyy", "02001" )
//                 , ( "Y", "2001" )
//                 , ( "YY", "01" )
//                 , ( "YYY", "2001" )
//                 , ( "YYYY", "2001" )
//                 , ( "YYYYY", "02001" )
//                 , ( "Q", "1" )
//                 , ( "QQ", "1" )
//                 , ( "QQQ", "Q1" )
//                 , ( "QQQQ", "1st" )
//                 , ( "QQQQQ", "1" )
//                 , ( "QQQQQQ", "" )
//                 , ( "M", "1" )
//                 , ( "MM", "01" )
//                 , ( "MMM", "Jan" )
//                 , ( "MMMM", "January" )
//                 , ( "MMMMM", "J" )
//                 , ( "MMMMMM", "" )
//                 , ( "w", "1" )
//                 , ( "ww", "01" )
//                 , ( "www", "" )
//                 , ( "d", "2" )
//                 , ( "dd", "02" )
//                 , ( "ddd", "2nd" )
//                 , ( "dddd", "" )
//                 , ( "D", "2" )
//                 , ( "DD", "02" )
//                 , ( "DDD", "002" )
//                 , ( "DDDD", "" )
//                 , ( "E", "Tue" )
//                 , ( "EE", "Tue" )
//                 , ( "EEE", "Tue" )
//                 , ( "EEEE", "Tuesday" )
//                 , ( "EEEEE", "T" )
//                 , ( "EEEEEE", "Tu" )
//                 , ( "EEEEEEE", "" )
//                 , ( "e", "2" )
//                 , ( "ee", "2" )
//                 , ( "eee", "Tue" )
//                 , ( "eeee", "Tuesday" )
//                 , ( "eeeee", "T" )
//                 , ( "eeeeee", "Tu" )
//                 , ( "eeeeeee", "" )
//                 ]
pub fn format_supported_character_pattern_test() {
  list.each(
    [
      #("y", "2001"),
      #("yy", "01"),
      #("yyy", "2001"),
      #("yyyy", "2001"),
      #("yyyyy", "02001"),
      #("Y", "2001"),
      #("YY", "01"),
      #("YYY", "2001"),
      #("YYYY", "2001"),
      #("YYYYY", "02001"),
      #("Q", "1"),
      #("QQ", "1"),
      #("QQQ", "Q1"),
      #("QQQQ", "1st"),
      #("QQQQQ", "1"),
      #("QQQQQQ", ""),
      #("M", "1"),
      #("MM", "01"),
      #("MMM", "Jan"),
      #("MMMM", "January"),
      #("MMMMM", "J"),
      #("MMMMMM", ""),
      #("w", "1"),
      #("ww", "01"),
      #("www", ""),
      #("d", "2"),
      #("dd", "02"),
      #("ddd", "2nd"),
      #("dddd", ""),
      #("D", "2"),
      #("DD", "02"),
      #("DDD", "002"),
      #("DDDD", ""),
      #("E", "Tue"),
      #("EE", "Tue"),
      #("EEE", "Tue"),
      #("EEEE", "Tuesday"),
      #("EEEEE", "T"),
      #("EEEEEE", "Tu"),
      #("EEEEEEE", ""),
      #("e", "2"),
      #("ee", "2"),
      #("eee", "Tue"),
      #("eeee", "Tuesday"),
      #("eeeee", "T"),
      #("eeeeee", "Tu"),
      #("eeeeeee", ""),
    ],
    fn(tuple) {
      let #(pattern, text) = tuple
      let date = date.from_calendar_date(2001, date.Jan, 2)
      should.equal(date.format(date, pattern), text)
    },
  )
}

//         , describe "removes unsupported pattern characters" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2008 Dec 31))
//                 [ ( "ABCFGHIJKLNOPRSTUVWXZabcfghijklmnopqrstuvxz", "" )
//                 ]
pub fn format_removes_unsupported_pattern_characters_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("ABCFGHIJKLNOPRSTUVWXZabcfghijklmnopqrstuvxz")
  |> should.equal("")
}

//         , describe "ignores non-alpha characters" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2008 Dec 31))
//                 [ ( "0123456789 .,\\//:-%", "0123456789 .,\\//:-%" )
//                 ]
pub fn format_ignores_non_alpha_characters_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("0123456789 .,\\//:-%")
  |> should.equal("0123456789 .,\\//:-%")
}

//         , describe "handles escaped characters and escaped escape characters" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2001 Jan 2))
//                 [ ( "'yYQMwdDEe'", "yYQMwdDEe" )
//                 , ( "''' '' ''' ''", "' ' ' '" )
//                 , ( "'yyyy:' yyyy", "yyyy: 2001" )
//                 ]
pub fn format_handles_escaped_characters_and_escaped_escape_characters_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  list.each(
    [
      #("'yYQMwdDEe'", "yYQMwdDEe"),
      #("''' '' ''' ''", "' ' ' '"),
      #("'yyyy:' yyyy", "yyyy: 2008"),
    ],
    fn(tuple) {
      let #(pattern, text) = tuple
      date
      |> date.format(pattern)
      |> should.equal(text)
    },
  )
}

//         , describe "is lenient on unclosed quotes" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2001 Jan 2))
//                 [ ( "yyyy 'yyyy", "2001 yyyy" )
//                 ]

pub fn format_is_lenient_on_unclosed_quotes_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("yyyy 'yyyy")
  |> should.equal("2008 yyyy")
}

//         , describe "formats day ordinals" <|
//             List.map
//                 (\( n, string ) ->
//                     toTest (Date.fromCalendarDate 2001 Jan n) ( "ddd", string )
//                 )
//                 [ ( 1, "1st" )
//                 , ( 2, "2nd" )
//                 , ( 3, "3rd" )
//                 , ( 4, "4th" )
//                 , ( 5, "5th" )
//                 , ( 6, "6th" )
//                 , ( 7, "7th" )
//                 , ( 8, "8th" )
//                 , ( 9, "9th" )
//                 , ( 10, "10th" )
//                 , ( 11, "11th" )
//                 , ( 12, "12th" )
//                 , ( 13, "13th" )
//                 , ( 14, "14th" )
//                 , ( 15, "15th" )
//                 , ( 16, "16th" )
//                 , ( 17, "17th" )
//                 , ( 18, "18th" )
//                 , ( 19, "19th" )
//                 , ( 20, "20th" )
//                 , ( 21, "21st" )
//                 , ( 22, "22nd" )
//                 , ( 23, "23rd" )
//                 , ( 24, "24th" )
//                 , ( 25, "25th" )
//                 , ( 26, "26th" )
//                 , ( 27, "27th" )
//                 , ( 28, "28th" )
//                 , ( 29, "29th" )
//                 , ( 30, "30th" )
//                 , ( 31, "31st" )
//                 ]
pub fn format_formats_day_ordinals_test() {
  list.each(
    [
      #(1, "1st"),
      #(2, "2nd"),
      #(3, "3rd"),
      #(4, "4th"),
      #(5, "5th"),
      #(6, "6th"),
      #(7, "7th"),
      #(8, "8th"),
      #(9, "9th"),
      #(10, "10th"),
      #(11, "11th"),
      #(12, "12th"),
      #(13, "13th"),
      #(14, "14th"),
      #(15, "15th"),
      #(16, "16th"),
      #(17, "17th"),
      #(18, "18th"),
      #(19, "19th"),
      #(20, "20th"),
      #(21, "21st"),
      #(22, "22nd"),
      #(23, "23rd"),
      #(24, "24th"),
      #(25, "25th"),
      #(26, "26th"),
      #(27, "27th"),
      #(28, "28th"),
      #(29, "29th"),
      #(30, "30th"),
      #(31, "31st"),
    ],
    fn(tuple) {
      let #(day, expected) = tuple
      date.from_calendar_date(2008, date.Dec, day)
      |> date.format("ddd")
      |> should.equal(expected)
    },
  )
}

//         , describe "formats with sample patterns as expected" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2008 Dec 31))
//                 [ ( "yyyy-MM-dd", "2008-12-31" )
//                 , ( "yyyy-DDD", "2008-366" )
//                 , ( "YYYY-'W'ww-e", "2009-W01-3" )
//                 , ( "M/d/y", "12/31/2008" )
//                 , ( "''yy", "'08" )
//                 ]
//         ]

pub fn format_formats_with_sample_patterns_as_expected_test() {
  list.each(
    [
      #("yyyy-MM-dd", "2008-12-31"),
      #("yyyy-DDD", "2008-366"),
      #("YYYY-'W'ww-e", "2009-W01-3"),
      #("M/d/y", "12/31/2008"),
      #("''yy", "'08"),
    ],
    fn(tuple) {
      let #(pattern, expected) = tuple
      date.from_calendar_date(2008, date.Dec, 31)
      |> date.format(pattern)
      |> should.equal(expected)
    },
  )
}

// test_formatWithLanguage : Test
// test_formatWithLanguage =
//     let
//         toTest : Date -> ( String, String ) -> Test
//         toTest date ( pattern, expected ) =
//             test ("\"" ++ pattern ++ "\" " ++ Debug.toString date) <|
//                 \() -> date |> Date.formatWithLanguage Language.fr pattern |> equal expected
//     in
//     describe "formatWithLanguage"
//         [ describe "replaces names as expected" <|
//             List.map
//                 (toTest (Date.fromCalendarDate 2001 Jan 1))
//                 [ ( "MMM", "janv." )
//                 , ( "MMMM", "janvier" )
//                 , ( "MMMMM", "j" )
//                 , ( "MMMMMM", "" )
//                 , ( "d", "1" )
//                 , ( "dd", "01" )
//                 , ( "ddd", "1er" )
//                 , ( "dddd", "" )
//                 , ( "E", "lun" )
//                 , ( "EE", "lun" )
//                 , ( "EEE", "lun" )
//                 , ( "EEEE", "lundi" )
//                 , ( "EEEEE", "l" )
//                 , ( "EEEEEE", "lu" )
//                 , ( "EEEEEEE", "" )
//                 ]
//         ]
pub fn format_with_language_test() {
  list.each(
    [
      #("MMM", "janv."),
      #("MMMM", "janvier"),
      #("MMMMM", "j"),
      #("MMMMMM", ""),
      #("d", "1"),
      #("dd", "01"),
      #("ddd", "1er"),
      #("dddd", ""),
      #("E", "lun"),
      #("EE", "lun"),
      #("EEE", "lun"),
      #("EEEE", "lundi"),
      #("EEEEE", "l"),
      #("EEEEEE", "lu"),
      #("EEEEEEE", ""),
    ],
    fn(tuple) {
      let #(pattern, expected) = tuple
      date.from_calendar_date(2001, date.Jan, 1)
      |> date.format_with_language(language_fr(), pattern)
      |> should.equal(expected)
    },
  )
}

// test_add : Test
// test_add =
//     let
//         toTest : ( Int, Month, Int ) -> Int -> Unit -> ( Int, Month, Int ) -> Test
//         toTest ( y1, m1, d1 ) n unit (( y2, m2, d2 ) as expected) =
//             test (Debug.toString ( y1, m1, d1 ) ++ " + " ++ Debug.toString n ++ " " ++ Debug.toString unit ++ " => " ++ Debug.toString expected) <|
//                 \() ->
//                     Date.fromCalendarDate y1 m1 d1 |> Date.add unit n |> equal (Date.fromCalendarDate y2 m2 d2)
//     in
//     describe "add"
//         [ describe "add 0 x == x" <|
//             List.map
//                 (\unit -> toTest ( 2000, Jan, 1 ) 0 unit ( 2000, Jan, 1 ))
//                 [ Years, Months, Weeks, Days ]
fn test_add(from_tuple, count, unit, to_tuple) {
  let #(from_year, from_month, from_day) = from_tuple
  let #(to_year, to_month, to_day) = to_tuple
  date.from_calendar_date(from_year, from_month, from_day)
  |> date.add(count, unit)
  |> should.equal(date.from_calendar_date(to_year, to_month, to_day))
}

pub fn add_zero_test() {
  list.each([date.Years, date.Months, date.Weeks, date.Days], fn(unit) {
    test_add(#(2000, date.Jan, 1), 0, unit, #(2000, date.Jan, 1))
  })
}

//         , describe "adding positive numbers works as expected"
//             [ toTest ( 2000, Jan, 1 ) 2 Years ( 2002, Jan, 1 )
//             , toTest ( 2000, Jan, 1 ) 2 Months ( 2000, Mar, 1 )
//             , toTest ( 2000, Jan, 1 ) 2 Weeks ( 2000, Jan, 15 )
//             , toTest ( 2000, Jan, 1 ) 2 Days ( 2000, Jan, 3 )
//             , toTest ( 2000, Jan, 1 ) 18 Years ( 2018, Jan, 1 )
//             , toTest ( 2000, Jan, 1 ) 18 Months ( 2001, Jul, 1 )
//             , toTest ( 2000, Jan, 1 ) 18 Weeks ( 2000, May, 6 )
//             , toTest ( 2000, Jan, 1 ) 36 Days ( 2000, Feb, 6 )
//             ]
pub fn add_positive_numbers_test() {
  test_add(#(2000, date.Jan, 1), 2, date.Years, #(2002, date.Jan, 1))
  test_add(#(2000, date.Jan, 1), 2, date.Months, #(2000, date.Mar, 1))
  test_add(#(2000, date.Jan, 1), 2, date.Weeks, #(2000, date.Jan, 15))
  test_add(#(2000, date.Jan, 1), 2, date.Days, #(2000, date.Jan, 3))
  test_add(#(2000, date.Jan, 1), 18, date.Years, #(2018, date.Jan, 1))
  test_add(#(2000, date.Jan, 1), 18, date.Months, #(2001, date.Jul, 1))
  test_add(#(2000, date.Jan, 1), 18, date.Weeks, #(2000, date.May, 6))
  test_add(#(2000, date.Jan, 1), 36, date.Days, #(2000, date.Feb, 6))
}

//         , describe "adding negative numbers works as expected"
//             [ toTest ( 2000, Jan, 1 ) -2 Years ( 1998, Jan, 1 )
//             , toTest ( 2000, Jan, 1 ) -2 Months ( 1999, Nov, 1 )
//             , toTest ( 2000, Jan, 1 ) -2 Weeks ( 1999, Dec, 18 )
//             , toTest ( 2000, Jan, 1 ) -2 Days ( 1999, Dec, 30 )
//             , toTest ( 2000, Jan, 1 ) -18 Years ( 1982, Jan, 1 )
//             , toTest ( 2000, Jan, 1 ) -18 Months ( 1998, Jul, 1 )
//             , toTest ( 2000, Jan, 1 ) -18 Weeks ( 1999, Aug, 28 )
//             , toTest ( 2000, Jan, 1 ) -18 Days ( 1999, Dec, 14 )
//             ]
pub fn add_negative_numbers_test() {
  test_add(#(2000, date.Jan, 1), -2, date.Years, #(1998, date.Jan, 1))
  test_add(#(2000, date.Jan, 1), -2, date.Months, #(1999, date.Nov, 1))
  test_add(#(2000, date.Jan, 1), -2, date.Weeks, #(1999, date.Dec, 18))
  test_add(#(2000, date.Jan, 1), -2, date.Days, #(1999, date.Dec, 30))
  test_add(#(2000, date.Jan, 1), -18, date.Years, #(1982, date.Jan, 1))
  test_add(#(2000, date.Jan, 1), -18, date.Months, #(1998, date.Jul, 1))
  test_add(#(2000, date.Jan, 1), -18, date.Weeks, #(1999, date.Aug, 28))
  test_add(#(2000, date.Jan, 1), -18, date.Days, #(1999, date.Dec, 14))
}

//         , describe "adding Years from a leap day clamps overflow to the end of February"
//             [ toTest ( 2000, Feb, 29 ) 1 Years ( 2001, Feb, 28 )
//             , toTest ( 2000, Feb, 29 ) 4 Years ( 2004, Feb, 29 )
//             ]
pub fn add_years_from_a_leap_day_clamps_to_end_of_feb_test() {
  test_add(#(2000, date.Feb, 29), 1, date.Years, #(2001, date.Feb, 28))
  test_add(#(2000, date.Feb, 29), 4, date.Years, #(2004, date.Feb, 29))
}

//         , describe "adding Months clamps overflow to the end of a short month"
//             [ toTest ( 2000, Jan, 31 ) 1 Months ( 2000, Feb, 29 )
//             , toTest ( 2000, Jan, 31 ) 2 Months ( 2000, Mar, 31 )
//             , toTest ( 2000, Jan, 31 ) 3 Months ( 2000, Apr, 30 )
//             , toTest ( 2000, Jan, 31 ) 13 Months ( 2001, Feb, 28 )
//             ]
//         ]
pub fn add_months_clamps_to_end_of_short_month_test() {
  test_add(#(2000, date.Jan, 31), 1, date.Months, #(2000, date.Feb, 29))
  test_add(#(2000, date.Jan, 31), 2, date.Months, #(2000, date.Mar, 31))
  test_add(#(2000, date.Jan, 31), 3, date.Months, #(2000, date.Apr, 30))
  test_add(#(2000, date.Jan, 31), 13, date.Months, #(2001, date.Feb, 28))
}

// test_diff : Test
// test_diff =
//     let
//         toTest : ( Int, Month, Int ) -> ( Int, Month, Int ) -> Int -> Unit -> Test
//         toTest ( y1, m1, d1 ) ( y2, m2, d2 ) expected unit =
//             test (Debug.toString ( y2, m2, d2 ) ++ " - " ++ Debug.toString ( y1, m1, d1 ) ++ " => " ++ Debug.toString expected ++ " " ++ Debug.toString unit) <|
//                 \() ->
//                     Date.diff unit (Date.fromCalendarDate y1 m1 d1) (Date.fromCalendarDate y2 m2 d2) |> equal expected
//     in
//     describe "diff"
//         [ describe "diff x x == 0" <|
//             List.map
//                 (\unit -> toTest ( 2000, Jan, 1 ) ( 2000, Jan, 1 ) 0 unit)
//                 [ Years, Months, Weeks, Days ]
fn test_diff(from_tuple, to_tuple, count, unit) {
  let #(from_year, from_month, from_day) = from_tuple
  let #(to_year, to_month, to_day) = to_tuple
  let from_date = date.from_calendar_date(from_year, from_month, from_day)
  let to_date = date.from_calendar_date(to_year, to_month, to_day)

  date.diff(unit, from_date, to_date)
  |> should.equal(count)
}

pub fn diff_same_date_diff_units_test() {
  list.each([date.Years, date.Months, date.Weeks, date.Days], fn(unit) {
    test_diff(#(2000, date.Jan, 1), #(2000, date.Jan, 1), 0, unit)
  })
}

//         , describe "diff x y == -(diff y x)" <|
//             let
//                 ( x, y ) =
//                     ( Date.fromCalendarDate 2000 Jan 1, Date.fromCalendarDate 2017 Sep 28 )
//             in
//             List.map
//                 (\unit -> test (Debug.toString unit) <| \() -> Date.diff unit x y |> equal (negate (Date.diff unit y x)))
//                 [ Years, Months, Weeks, Days ]
pub fn diff_inverts_correctly_test() {
  list.each([date.Years, date.Months, date.Weeks, date.Days], fn(unit) {
    let from_date = date.from_calendar_date(2000, date.Jan, 1)
    let to_date = date.from_calendar_date(2017, date.Sep, 28)
    should.equal(
      date.diff(unit, from_date, to_date),
      -1 * date.diff(unit, to_date, from_date),
    )
  })
}

//         , describe "`diff earlier later` results in positive numbers"
//             [ toTest ( 2000, Jan, 1 ) ( 2002, Jan, 1 ) 2 Years
//             , toTest ( 2000, Jan, 1 ) ( 2000, Mar, 1 ) 2 Months
//             , toTest ( 2000, Jan, 1 ) ( 2000, Jan, 15 ) 2 Weeks
//             , toTest ( 2000, Jan, 1 ) ( 2000, Jan, 3 ) 2 Days
//             , toTest ( 2000, Jan, 1 ) ( 2018, Jan, 1 ) 18 Years
//             , toTest ( 2000, Jan, 1 ) ( 2001, Jul, 1 ) 18 Months
//             , toTest ( 2000, Jan, 1 ) ( 2000, May, 6 ) 18 Weeks
//             , toTest ( 2000, Jan, 1 ) ( 2000, Feb, 6 ) 36 Days
//             ]
pub fn diff_earlier_later_is_positive_test() {
  test_diff(#(2000, date.Jan, 1), #(2002, date.Jan, 1), 2, date.Years)
  test_diff(#(2000, date.Jan, 1), #(2000, date.Mar, 1), 2, date.Months)
  test_diff(#(2000, date.Jan, 1), #(2000, date.Jan, 15), 2, date.Weeks)
  test_diff(#(2000, date.Jan, 1), #(2000, date.Jan, 3), 2, date.Days)
  test_diff(#(2000, date.Jan, 1), #(2018, date.Jan, 1), 18, date.Years)
  test_diff(#(2000, date.Jan, 1), #(2001, date.Jul, 1), 18, date.Months)
  test_diff(#(2000, date.Jan, 1), #(2000, date.May, 6), 18, date.Weeks)
  test_diff(#(2000, date.Jan, 1), #(2000, date.Feb, 6), 36, date.Days)
}

//         , describe "`diff later earlier` results in negative numbers"
//             [ toTest ( 2000, Jan, 1 ) ( 1998, Jan, 1 ) -2 Years
//             , toTest ( 2000, Jan, 1 ) ( 1999, Nov, 1 ) -2 Months
//             , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 18 ) -2 Weeks
//             , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 30 ) -2 Days
//             , toTest ( 2000, Jan, 1 ) ( 1982, Jan, 1 ) -18 Years
//             , toTest ( 2000, Jan, 1 ) ( 1998, Jul, 1 ) -18 Months
//             , toTest ( 2000, Jan, 1 ) ( 1999, Aug, 28 ) -18 Weeks
//             , toTest ( 2000, Jan, 1 ) ( 1999, Dec, 14 ) -18 Days
//             ]
pub fn diff_later_earlier_is_negative_test() {
  test_diff(#(2000, date.Jan, 1), #(1998, date.Jan, 1), -2, date.Years)
  test_diff(#(2000, date.Jan, 1), #(1999, date.Nov, 1), -2, date.Months)
  test_diff(#(2000, date.Jan, 1), #(1999, date.Dec, 18), -2, date.Weeks)
  test_diff(#(2000, date.Jan, 1), #(1999, date.Dec, 30), -2, date.Days)
  test_diff(#(2000, date.Jan, 1), #(1982, date.Jan, 1), -18, date.Years)
  test_diff(#(2000, date.Jan, 1), #(1998, date.Jul, 1), -18, date.Months)
  test_diff(#(2000, date.Jan, 1), #(1999, date.Aug, 28), -18, date.Weeks)
  test_diff(#(2000, date.Jan, 1), #(1999, date.Dec, 14), -18, date.Days)
}

//         , describe "diffing Years returns a number of whole years as determined by calendar date (anniversary)"
//             [ toTest ( 2000, Feb, 29 ) ( 2001, Feb, 28 ) 0 Years
//             , toTest ( 2000, Feb, 29 ) ( 2004, Feb, 29 ) 4 Years
//             ]
pub fn diff_diffing_years_handles_leap_years_test() {
  test_diff(#(2000, date.Feb, 29), #(2001, date.Feb, 28), 0, date.Years)
  test_diff(#(2000, date.Feb, 29), #(2004, date.Feb, 29), 4, date.Years)
}

//         , describe "diffing Months returns a number of whole months as determined by calendar date"
//             [ toTest ( 2000, Jan, 31 ) ( 2000, Feb, 29 ) 0 Months
//             , toTest ( 2000, Jan, 31 ) ( 2000, Mar, 31 ) 2 Months
//             , toTest ( 2000, Jan, 31 ) ( 2000, Apr, 30 ) 2 Months
//             , toTest ( 2000, Jan, 31 ) ( 2001, Feb, 28 ) 12 Months
//             ]

pub fn diff_diffing_months_handles_leap_year_febs_test() {
  test_diff(#(2000, date.Jan, 31), #(2000, date.Feb, 29), 0, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2000, date.Mar, 31), 2, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2000, date.Apr, 30), 2, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2001, date.Feb, 28), 12, date.Months)
}

//         ]

// test_floor : Test
// test_floor =
//     let
//         toTest : Interval -> ( Int, Month, Int ) -> ( Int, Month, Int ) -> Test
//         toTest interval ( y1, m1, d1 ) (( y2, m2, d2 ) as expected) =
//             describe (Debug.toString interval ++ " " ++ Debug.toString ( y1, m1, d1 ))
//                 [ test ("=> " ++ Debug.toString expected) <|
//                     \() -> Date.fromCalendarDate y1 m1 d1 |> Date.floor interval |> equal (Date.fromCalendarDate y2 m2 d2)
//                 , test "is idempotent" <|
//                     \() -> Date.fromCalendarDate y1 m1 d1 |> expectIdempotence (Date.floor interval)
//                 ]
//     in
//     describe "floor"
//         [ describe "doesn't affect a date that is already at a rounded interval"
//             [ toTest Year ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Quarter ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Month ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Week ( 2000, Jan, 3 ) ( 2000, Jan, 3 )
//             , toTest Monday ( 2000, Jan, 3 ) ( 2000, Jan, 3 )
//             , toTest Tuesday ( 2000, Jan, 4 ) ( 2000, Jan, 4 )
//             , toTest Wednesday ( 2000, Jan, 5 ) ( 2000, Jan, 5 )
//             , toTest Thursday ( 2000, Jan, 6 ) ( 2000, Jan, 6 )
//             , toTest Friday ( 2000, Jan, 7 ) ( 2000, Jan, 7 )
//             , toTest Saturday ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Sunday ( 2000, Jan, 2 ) ( 2000, Jan, 2 )
//             , toTest Day ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             ]
fn test_floor(interval, input_tuple, expected_tuple) {
  let input_date = tuple_to_calendar_date(input_tuple)
  let expected_date = tuple_to_calendar_date(expected_tuple)

  date.floor(input_date, interval)
  |> should.equal(expected_date)

  // Check that calling it twice is the same as calling it once
  expect_idempotence(fn(date) { date.floor(date, interval) }, input_date)
}

pub fn floor_does_not_affect_already_rounded_date_test() {
  test_floor(date.Year, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_floor(date.Quarter, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_floor(date.Month, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_floor(date.Week, #(2000, date.Jan, 3), #(2000, date.Jan, 3))
  test_floor(date.Monday, #(2000, date.Jan, 3), #(2000, date.Jan, 3))
  test_floor(date.Tuesday, #(2000, date.Jan, 4), #(2000, date.Jan, 4))
  test_floor(date.Wednesday, #(2000, date.Jan, 5), #(2000, date.Jan, 5))
  test_floor(date.Thursday, #(2000, date.Jan, 6), #(2000, date.Jan, 6))
  test_floor(date.Friday, #(2000, date.Jan, 7), #(2000, date.Jan, 7))
  test_floor(date.Saturday, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_floor(date.Sunday, #(2000, date.Jan, 2), #(2000, date.Jan, 2))
  test_floor(date.Day, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
}

//         , describe "returns the previous rounded interval"
//             [ toTest Year ( 2000, May, 21 ) ( 2000, Jan, 1 )
//             , toTest Quarter ( 2000, May, 21 ) ( 2000, Apr, 1 )
//             , toTest Month ( 2000, May, 21 ) ( 2000, May, 1 )
//             , toTest Week ( 2000, May, 21 ) ( 2000, May, 15 )
//             , toTest Monday ( 2000, May, 21 ) ( 2000, May, 15 )
//             , toTest Tuesday ( 2000, May, 21 ) ( 2000, May, 16 )
//             , toTest Wednesday ( 2000, May, 21 ) ( 2000, May, 17 )
//             , toTest Thursday ( 2000, May, 21 ) ( 2000, May, 18 )
//             , toTest Friday ( 2000, May, 21 ) ( 2000, May, 19 )
//             , toTest Saturday ( 2000, May, 21 ) ( 2000, May, 20 )
//             , toTest Sunday ( 2000, May, 22 ) ( 2000, May, 21 )
//             , toTest Day ( 2000, May, 21 ) ( 2000, May, 21 )
//             ]
pub fn floor_rounds_as_expected_test() {
  test_floor(date.Year, #(2000, date.May, 21), #(2000, date.Jan, 1))
  test_floor(date.Quarter, #(2000, date.May, 21), #(2000, date.Apr, 1))
  test_floor(date.Month, #(2000, date.May, 21), #(2000, date.May, 1))
  test_floor(date.Week, #(2000, date.May, 21), #(2000, date.May, 15))
  test_floor(date.Monday, #(2000, date.May, 21), #(2000, date.May, 15))
  test_floor(date.Tuesday, #(2000, date.May, 21), #(2000, date.May, 16))
  test_floor(date.Wednesday, #(2000, date.May, 21), #(2000, date.May, 17))
  test_floor(date.Thursday, #(2000, date.May, 21), #(2000, date.May, 18))
  test_floor(date.Friday, #(2000, date.May, 21), #(2000, date.May, 19))
  test_floor(date.Saturday, #(2000, date.May, 21), #(2000, date.May, 20))
  test_floor(date.Sunday, #(2000, date.May, 22), #(2000, date.May, 21))
  test_floor(date.Day, #(2000, date.May, 21), #(2000, date.May, 21))
}

//         , describe "rounds to Quarter as expected" <|
//             List.concatMap
//                 (\( ms, expected ) -> ms |> List.map (\m -> toTest Quarter ( 2000, m, 15 ) expected))
//                 [ ( [ Jan, Feb, Mar ], ( 2000, Jan, 1 ) )
//                 , ( [ Apr, May, Jun ], ( 2000, Apr, 1 ) )
//                 , ( [ Jul, Aug, Sep ], ( 2000, Jul, 1 ) )
//                 , ( [ Oct, Nov, Dec ], ( 2000, Oct, 1 ) )
//                 ]
//         ]
pub fn floor_rounds_to_quarter_test() {
  list.each(
    [
      #([date.Jan, date.Feb, date.Mar], #(2000, date.Jan, 1)),
      #([date.Apr, date.May, date.Jun], #(2000, date.Apr, 1)),
      #([date.Jul, date.Aug, date.Sep], #(2000, date.Jul, 1)),
      #([date.Oct, date.Nov, date.Dec], #(2000, date.Oct, 1)),
    ],
    fn(tuple) {
      let #(months, expected) = tuple
      list.each(months, fn(month) {
        test_floor(date.Quarter, #(2000, month, 15), expected)
      })
    },
  )
}

// test_ceiling : Test
// test_ceiling =
//     let
//         toTest : Interval -> ( Int, Month, Int ) -> ( Int, Month, Int ) -> Test
//         toTest interval ( y1, m1, d1 ) (( y2, m2, d2 ) as expected) =
//             describe (Debug.toString interval ++ " " ++ Debug.toString ( y1, m1, d1 ))
//                 [ test ("=> " ++ Debug.toString expected) <|
//                     \() -> Date.fromCalendarDate y1 m1 d1 |> Date.ceiling interval |> equal (Date.fromCalendarDate y2 m2 d2)
//                 , test "is idempotent" <|
//                     \() -> Date.fromCalendarDate y1 m1 d1 |> expectIdempotence (Date.ceiling interval)
//                 ]
//     in
//     describe "ceiling"
//         [ describe "doesn't affect a date that is already at a rounded interval"
//             [ toTest Year ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Quarter ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Month ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Week ( 2000, Jan, 3 ) ( 2000, Jan, 3 )
//             , toTest Monday ( 2000, Jan, 3 ) ( 2000, Jan, 3 )
//             , toTest Tuesday ( 2000, Jan, 4 ) ( 2000, Jan, 4 )
//             , toTest Wednesday ( 2000, Jan, 5 ) ( 2000, Jan, 5 )
//             , toTest Thursday ( 2000, Jan, 6 ) ( 2000, Jan, 6 )
//             , toTest Friday ( 2000, Jan, 7 ) ( 2000, Jan, 7 )
//             , toTest Saturday ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             , toTest Sunday ( 2000, Jan, 2 ) ( 2000, Jan, 2 )
//             , toTest Day ( 2000, Jan, 1 ) ( 2000, Jan, 1 )
//             ]
fn test_ceiling(interval, input_tuple, expected_tuple) {
  let input_date = tuple_to_calendar_date(input_tuple)
  let expected_date = tuple_to_calendar_date(expected_tuple)

  date.ceiling(input_date, interval)
  |> should.equal(expected_date)

  // Check that calling it twice is the same as calling it once
  expect_idempotence(fn(date) { date.floor(date, interval) }, input_date)
}

pub fn ceiling_does_not_affect_already_rounded_date_test() {
  test_ceiling(date.Year, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_ceiling(date.Quarter, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_ceiling(date.Month, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_ceiling(date.Week, #(2000, date.Jan, 3), #(2000, date.Jan, 3))
  test_ceiling(date.Monday, #(2000, date.Jan, 3), #(2000, date.Jan, 3))
  test_ceiling(date.Tuesday, #(2000, date.Jan, 4), #(2000, date.Jan, 4))
  test_ceiling(date.Wednesday, #(2000, date.Jan, 5), #(2000, date.Jan, 5))
  test_ceiling(date.Thursday, #(2000, date.Jan, 6), #(2000, date.Jan, 6))
  test_ceiling(date.Friday, #(2000, date.Jan, 7), #(2000, date.Jan, 7))
  test_ceiling(date.Saturday, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
  test_ceiling(date.Sunday, #(2000, date.Jan, 2), #(2000, date.Jan, 2))
  test_ceiling(date.Day, #(2000, date.Jan, 1), #(2000, date.Jan, 1))
}

//         , describe "returns the next rounded interval"
//             [ toTest Year ( 2000, May, 21 ) ( 2001, Jan, 1 )
//             , toTest Quarter ( 2000, May, 21 ) ( 2000, Jul, 1 )
//             , toTest Month ( 2000, May, 21 ) ( 2000, Jun, 1 )
//             , toTest Week ( 2000, May, 21 ) ( 2000, May, 22 )
//             , toTest Monday ( 2000, May, 21 ) ( 2000, May, 22 )
//             , toTest Tuesday ( 2000, May, 21 ) ( 2000, May, 23 )
//             , toTest Wednesday ( 2000, May, 21 ) ( 2000, May, 24 )
//             , toTest Thursday ( 2000, May, 21 ) ( 2000, May, 25 )
//             , toTest Friday ( 2000, May, 21 ) ( 2000, May, 26 )
//             , toTest Saturday ( 2000, May, 21 ) ( 2000, May, 27 )
//             , toTest Sunday ( 2000, May, 22 ) ( 2000, May, 28 )
//             , toTest Day ( 2000, May, 21 ) ( 2000, May, 21 )
pub fn ceiling_returns_next_rounded_interval_test() {
  test_ceiling(date.Year, #(2000, date.May, 21), #(2001, date.Jan, 1))
  test_ceiling(date.Quarter, #(2000, date.May, 21), #(2000, date.Jul, 1))
  test_ceiling(date.Month, #(2000, date.May, 21), #(2000, date.Jun, 1))
  test_ceiling(date.Week, #(2000, date.May, 21), #(2000, date.May, 22))
  test_ceiling(date.Monday, #(2000, date.May, 21), #(2000, date.May, 22))
  test_ceiling(date.Tuesday, #(2000, date.May, 21), #(2000, date.May, 23))
  test_ceiling(date.Wednesday, #(2000, date.May, 21), #(2000, date.May, 24))
  test_ceiling(date.Thursday, #(2000, date.May, 21), #(2000, date.May, 25))
  test_ceiling(date.Friday, #(2000, date.May, 21), #(2000, date.May, 26))
  test_ceiling(date.Saturday, #(2000, date.May, 21), #(2000, date.May, 27))
  test_ceiling(date.Sunday, #(2000, date.May, 22), #(2000, date.May, 28))
  test_ceiling(date.Day, #(2000, date.May, 21), #(2000, date.May, 21))
}

//             ]
//         , describe "rounds to Quarter as expected" <|
//             List.concatMap
//                 (\( ms, expected ) -> ms |> List.map (\m -> toTest Quarter ( 2000, m, 15 ) expected))
//                 [ ( [ Jan, Feb, Mar ], ( 2000, Apr, 1 ) )
//                 , ( [ Apr, May, Jun ], ( 2000, Jul, 1 ) )
//                 , ( [ Jul, Aug, Sep ], ( 2000, Oct, 1 ) )
//                 , ( [ Oct, Nov, Dec ], ( 2001, Jan, 1 ) )
//                 ]
pub fn ceiling_rounds_to_quarter_test() {
  list.each(
    [
      #([date.Jan, date.Feb, date.Mar], #(2000, date.Apr, 1)),
      #([date.Apr, date.May, date.Jun], #(2000, date.Jul, 1)),
      #([date.Jul, date.Aug, date.Sep], #(2000, date.Oct, 1)),
      #([date.Oct, date.Nov, date.Dec], #(2001, date.Jan, 1)),
    ],
    fn(tuple) {
      let #(months, expected) = tuple
      list.each(months, fn(month) {
        test_ceiling(date.Quarter, #(2000, month, 15), expected)
      })
    },
  )
}

//         ]

// test_range : Test
// test_range =
//     let
//         toTest : Interval -> Int -> CalendarDate -> CalendarDate -> List CalendarDate -> Test
//         toTest interval step start end expected =
//             test ([ Debug.toString interval, Debug.toString step, Debug.toString start, Debug.toString end ] |> String.join " ") <|
//                 \() ->
//                     Date.range interval step (fromCalendarDate start) (fromCalendarDate end)
//                         |> equal (expected |> List.map fromCalendarDate)
//     in
//     describe "range"
//         [ describe "returns a list of dates at rounded intervals which may include start and must exclude end"
//             [ toTest Year 10 (CalendarDate 2000 Jan 1) (CalendarDate 2030 Jan 1) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2010 Jan 1
//                 , CalendarDate 2020 Jan 1
//                 ]
//             , toTest Quarter 1 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Sep 1) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Apr 1
//                 , CalendarDate 2000 Jul 1
//                 ]
//             , toTest Month 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Jul 1) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Mar 1
//                 , CalendarDate 2000 May 1
//                 ]
//             , toTest Week 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 14) <|
//                 [ CalendarDate 2000 Jan 3
//                 , CalendarDate 2000 Jan 17
//                 , CalendarDate 2000 Jan 31
//                 ]
//             , toTest Monday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 14) <|
//                 [ CalendarDate 2000 Jan 3
//                 , CalendarDate 2000 Jan 17
//                 , CalendarDate 2000 Jan 31
//                 ]
//             , toTest Tuesday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 15) <|
//                 [ CalendarDate 2000 Jan 4
//                 , CalendarDate 2000 Jan 18
//                 , CalendarDate 2000 Feb 1
//                 ]
//             , toTest Wednesday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 16) <|
//                 [ CalendarDate 2000 Jan 5
//                 , CalendarDate 2000 Jan 19
//                 , CalendarDate 2000 Feb 2
//                 ]
//             , toTest Thursday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 17) <|
//                 [ CalendarDate 2000 Jan 6
//                 , CalendarDate 2000 Jan 20
//                 , CalendarDate 2000 Feb 3
//                 ]
//             , toTest Friday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 18) <|
//                 [ CalendarDate 2000 Jan 7
//                 , CalendarDate 2000 Jan 21
//                 , CalendarDate 2000 Feb 4
//                 ]
//             , toTest Saturday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 12) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Jan 15
//                 , CalendarDate 2000 Jan 29
//                 ]
//             , toTest Sunday 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 13) <|
//                 [ CalendarDate 2000 Jan 2
//                 , CalendarDate 2000 Jan 16
//                 , CalendarDate 2000 Jan 30
//                 ]
//             , toTest Day 2 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Jan 7) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Jan 3
//                 , CalendarDate 2000 Jan 5
//                 ]
//             ]
fn test_range(unit, step, start_tuple, end_tuple, expected_tuples) {
  let start_date = tuple_to_calendar_date(start_tuple)
  let end_date = tuple_to_calendar_date(end_tuple)
  date.range(unit, step, start_date, end_date)
  |> should.equal(expected_tuples |> list.map(tuple_to_calendar_date))
}

pub fn range_returns_list_of_dates_test() {
  test_range(date.Year, 10, #(2000, date.Jan, 1), #(2030, date.Jan, 1), [
    #(2000, date.Jan, 1),
    #(2010, date.Jan, 1),
    #(2020, date.Jan, 1),
  ])

  test_range(date.Quarter, 1, #(2000, date.Jan, 1), #(2000, date.Sep, 1), [
    #(2000, date.Jan, 1),
    #(2000, date.Apr, 1),
    #(2000, date.Jul, 1),
  ])

  test_range(date.Month, 2, #(2000, date.Jan, 1), #(2000, date.Jul, 1), [
    #(2000, date.Jan, 1),
    #(2000, date.Mar, 1),
    #(2000, date.May, 1),
  ])

  test_range(date.Week, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 14), [
    #(2000, date.Jan, 3),
    #(2000, date.Jan, 17),
    #(2000, date.Jan, 31),
  ])

  test_range(date.Monday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 14), [
    #(2000, date.Jan, 3),
    #(2000, date.Jan, 17),
    #(2000, date.Jan, 31),
  ])

  test_range(date.Tuesday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 15), [
    #(2000, date.Jan, 4),
    #(2000, date.Jan, 18),
    #(2000, date.Feb, 1),
  ])

  test_range(date.Wednesday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 16), [
    #(2000, date.Jan, 5),
    #(2000, date.Jan, 19),
    #(2000, date.Feb, 2),
  ])

  test_range(date.Thursday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 17), [
    #(2000, date.Jan, 6),
    #(2000, date.Jan, 20),
    #(2000, date.Feb, 3),
  ])

  test_range(date.Friday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 18), [
    #(2000, date.Jan, 7),
    #(2000, date.Jan, 21),
    #(2000, date.Feb, 4),
  ])

  test_range(date.Saturday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 12), [
    #(2000, date.Jan, 1),
    #(2000, date.Jan, 15),
    #(2000, date.Jan, 29),
  ])

  test_range(date.Sunday, 2, #(2000, date.Jan, 1), #(2000, date.Feb, 13), [
    #(2000, date.Jan, 2),
    #(2000, date.Jan, 16),
    #(2000, date.Jan, 30),
  ])

  test_range(date.Day, 2, #(2000, date.Jan, 1), #(2000, date.Jan, 7), [
    #(2000, date.Jan, 1),
    #(2000, date.Jan, 3),
    #(2000, date.Jan, 5),
  ])
}

//         , describe "begins at interval nearest to start date"
//             [ toTest Day 10 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Jan 30) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Jan 11
//                 , CalendarDate 2000 Jan 21
//                 ]
//             , toTest Day 10 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Jan 31) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Jan 11
//                 , CalendarDate 2000 Jan 21
//                 ]
//             , toTest Day 10 (CalendarDate 2000 Jan 1) (CalendarDate 2000 Feb 1) <|
//                 [ CalendarDate 2000 Jan 1
//                 , CalendarDate 2000 Jan 11
//                 , CalendarDate 2000 Jan 21
//                 , CalendarDate 2000 Jan 31
//                 ]
//             ]
pub fn range_beings_at_interval_nearest_start_date_test() {
  test_range(date.Day, 10, #(2000, date.Jan, 1), #(2000, date.Jan, 30), [
    #(2000, date.Jan, 1),
    #(2000, date.Jan, 11),
    #(2000, date.Jan, 21),
  ])

  test_range(date.Day, 10, #(2000, date.Jan, 1), #(2000, date.Jan, 31), [
    #(2000, date.Jan, 1),
    #(2000, date.Jan, 11),
    #(2000, date.Jan, 21),
  ])

  test_range(date.Day, 10, #(2000, date.Jan, 1), #(2000, date.Feb, 1), [
    #(2000, date.Jan, 1),
    #(2000, date.Jan, 11),
    #(2000, date.Jan, 21),
    #(2000, date.Jan, 31),
  ])
}

//         , test "returns a list of days as expected" <|
//             \() ->
//                 Date.range Day 1 (Date.fromCalendarDate 2000 Jan 1) (Date.fromCalendarDate 2001 Jan 1)
//                     |> equal (calendarDatesInYear 2000 |> List.map fromCalendarDate)
pub fn range_returns_a_list_of_days_test() {
  date.range(
    date.Day,
    1,
    date.from_calendar_date(2000, date.Jan, 1),
    date.from_calendar_date(2001, date.Jan, 1),
  )
  |> should.equal(calendar_dates_in_year(2000) |> list.map(from_calendar_date))
}

//         , test "can return the empty list" <|
//             \() ->
//                 Date.range Day 1 (Date.fromCalendarDate 2000 Jan 1) (Date.fromCalendarDate 2000 Jan 1)
//                     |> equal []
pub fn range_can_return_empty_list_test() {
  date.range(
    date.Day,
    1,
    date.from_calendar_date(2000, date.Jan, 1),
    date.from_calendar_date(2000, date.Jan, 1),
  )
  |> should.equal([])
}

//         , describe "can return a large list (tail recursion)"
//             [ let
//                 start =
//                     Date.fromCalendarDate 1950 Jan 1

//                 end =
//                     Date.fromCalendarDate 2050 Jan 1

//                 expectedLength =
//                     Date.diff Days start end
//               in
//               test ("length: " ++ Debug.toString expectedLength) <|
//                 \() -> Date.range Day 1 start end |> List.length |> equal expectedLength
//             ]
//         ]
pub fn range_can_return_large_list_test() {
  let start = date.from_calendar_date(1950, date.Jan, 1)
  let end = date.from_calendar_date(2050, date.Jan, 1)

  let expected_length = date.diff(date.Days, start, end)

  date.range(date.Day, 1, start, end)
  |> list.length
  |> should.equal(expected_length)
}

// test_fromIsoString : Test
// test_fromIsoString =
//     let
//         toTest : ( String, ( Int, Month, Int ) ) -> Test
//         toTest ( string, ( y, m, d ) as expected ) =
//             test (string ++ " => " ++ Debug.toString expected) <|
//                 \() -> Date.fromIsoString string |> equal (Ok (Date.fromCalendarDate y m d))
//     in
//     describe "fromIsoString"
//         [ describe "converts ISO 8601 date strings in basic format" <|
//             List.map toTest
//                 [ ( "2008", ( 2008, Jan, 1 ) )
//                 , ( "200812", ( 2008, Dec, 1 ) )
//                 , ( "20081231", ( 2008, Dec, 31 ) )
//                 , ( "2009W01", ( 2008, Dec, 29 ) )
//                 , ( "2009W014", ( 2009, Jan, 1 ) )
//                 , ( "2008061", ( 2008, Mar, 1 ) )
//                 ]
fn test_from_iso_string(string: String, tuple) {
  date.from_iso_string(string)
  |> should.equal(Ok(tuple_to_calendar_date(tuple)))
}

pub fn from_iso_string_handles_basic_format_test() {
  list.each(
    [
      #("2008", #(2008, date.Jan, 1)),
      #("200812", #(2008, date.Dec, 1)),
      #("20081231", #(2008, date.Dec, 31)),
      #("2009W01", #(2008, date.Dec, 29)),
      #("2009W014", #(2009, date.Jan, 1)),
      #("2008061", #(2008, date.Mar, 1)),
    ],
    fn(entry) { test_from_iso_string(entry.0, entry.1) },
  )
}

//         , describe "converts ISO 8601 date strings in extended format" <|
//             List.map toTest
//                 [ ( "2008-12", ( 2008, Dec, 1 ) )
//                 , ( "2008-12-31", ( 2008, Dec, 31 ) )
//                 , ( "2009-W01", ( 2008, Dec, 29 ) )
//                 , ( "2009-W01-4", ( 2009, Jan, 1 ) )
//                 , ( "2008-061", ( 2008, Mar, 1 ) )
//                 ]
pub fn from_iso_string_handles_extended_format_test() {
  list.each(
    [
      #("2008-12", #(2008, date.Dec, 1)),
      #("2008-12-31", #(2008, date.Dec, 31)),
      #("2009-W01", #(2008, date.Dec, 29)),
      #("2009-W01-4", #(2009, date.Jan, 1)),
      #("2008-061", #(2008, date.Mar, 1)),
    ],
    fn(entry) { test_from_iso_string(entry.0, entry.1) },
  )
}

//         , describe "returns Err for malformed date strings" <|
//             List.map
//                 (\s -> test s <| \() -> Date.fromIsoString s |> extractErr "" |> String.startsWith "Expected a date" |> equal True)
//                 [ "200812-31"
//                 , "2008-1231"
//                 , "2009W01-4"
//                 , "2009-W014"
//                 , "2008-012-31"
//                 , "2008-12-031"
//                 , "2008-0061"
//                 , "2018-05-1"
//                 , "2018-5"
//                 , "20180"
//                 ]
pub fn from_iso_string_returns_error_for_malformed_date_strings_test() {
  list.each(
    [
      "200812-31", "2008-1231", "2009W01-4", "2009-W014", "2008-012-31",
      "2008-12-031", "2008-0061", "2018-05-1", "2018-5", "20180",
    ],
    fn(string) {
      date.from_iso_string(string) |> result.is_error() |> should.equal(True)
    },
  )
}

//         , describe "returns Err for invalid dates" <|
//             List.map
//                 (\( s, message ) -> test s <| \() -> Date.fromIsoString s |> equal (Err message))
//                 -- ordinal-day
//                 [ ( "2007-000", "Invalid ordinal date: ordinal-day 0 is out of range (1 to 365) for 2007; received (year 2007, ordinal-day 0)" )
//                 , ( "2007-366", "Invalid ordinal date: ordinal-day 366 is out of range (1 to 365) for 2007; received (year 2007, ordinal-day 366)" )
//                 , ( "2008-367", "Invalid ordinal date: ordinal-day 367 is out of range (1 to 366) for 2008; received (year 2008, ordinal-day 367)" )

//                 -- month
//                 , ( "2008-00", "Invalid date: month 0 is out of range (1 to 12); received (year 2008, month 0, day 1)" )
//                 , ( "2008-13", "Invalid date: month 13 is out of range (1 to 12); received (year 2008, month 13, day 1)" )
//                 , ( "2008-00-01", "Invalid date: month 0 is out of range (1 to 12); received (year 2008, month 0, day 1)" )
//                 , ( "2008-13-01", "Invalid date: month 13 is out of range (1 to 12); received (year 2008, month 13, day 1)" )

//                 -- day
//                 , ( "2008-01-00", "Invalid date: day 0 is out of range (1 to 31) for January; received (year 2008, month 1, day 0)" )
//                 , ( "2008-01-32", "Invalid date: day 32 is out of range (1 to 31) for January; received (year 2008, month 1, day 32)" )
//                 , ( "2006-02-29", "Invalid date: day 29 is out of range (1 to 28) for February (2006 is not a leap year); received (year 2006, month 2, day 29)" )
//                 , ( "2008-02-30", "Invalid date: day 30 is out of range (1 to 29) for February; received (year 2008, month 2, day 30)" )

//                 -- week
//                 , ( "2008-W00-1", "Invalid week date: week 0 is out of range (1 to 52) for 2008; received (year 2008, week 0, weekday 1)" )
//                 , ( "2008-W53-1", "Invalid week date: week 53 is out of range (1 to 52) for 2008; received (year 2008, week 53, weekday 1)" )
//                 , ( "2009-W54-1", "Invalid week date: week 54 is out of range (1 to 53) for 2009; received (year 2009, week 54, weekday 1)" )

//                 -- weekday
//                 , ( "2008-W01-0", "Invalid week date: weekday 0 is out of range (1 to 7); received (year 2008, week 1, weekday 0)" )
//                 , ( "2008-W01-8", "Invalid week date: weekday 8 is out of range (1 to 7); received (year 2008, week 1, weekday 8)" )
//                 ]
pub fn from_iso_string_returns_errors_for_invalid_dates_test() {
  list.each(
    // ordinal-day
    [
      #(
        "2007-000",
        "Invalid ordinal date: ordinal-day 0 is out of range (1 to 365) for 2007; received (year 2007, ordinal-day 0)",
      ),
      #(
        "2007-366",
        "Invalid ordinal date: ordinal-day 366 is out of range (1 to 365) for 2007; received (year 2007, ordinal-day 366)",
      ),
      #(
        "2008-367",
        "Invalid ordinal date: ordinal-day 367 is out of range (1 to 366) for 2008; received (year 2008, ordinal-day 367)",
      ),
      // month
      #(
        "2008-00",
        "Invalid date: month 0 is out of range (1 to 12); received (year 2008, month 0, day 1)",
      ),
      #(
        "2008-13",
        "Invalid date: month 13 is out of range (1 to 12); received (year 2008, month 13, day 1)",
      ),
      #(
        "2008-00-01",
        "Invalid date: month 0 is out of range (1 to 12); received (year 2008, month 0, day 1)",
      ),
      #(
        "2008-13-01",
        "Invalid date: month 13 is out of range (1 to 12); received (year 2008, month 13, day 1)",
      ),
      // day
      #(
        "2008-01-00",
        "Invalid date: day 0 is out of range (1 to 31) for January; received (year 2008, month 1, day 0)",
      ),
      #(
        "2008-01-32",
        "Invalid date: day 32 is out of range (1 to 31) for January; received (year 2008, month 1, day 32)",
      ),
      #(
        "2006-02-29",
        "Invalid date: day 29 is out of range (1 to 28) for February (2006 is not a leap year); received (year 2006, month 2, day 29)",
      ),
      #(
        "2008-02-30",
        "Invalid date: day 30 is out of range (1 to 29) for February; received (year 2008, month 2, day 30)",
      ),
      // week
      #(
        "2008-W00-1",
        "Invalid week date: week 0 is out of range (1 to 52) for 2008; received (year 2008, week 0, weekday 1)",
      ),
      #(
        "2008-W53-1",
        "Invalid week date: week 53 is out of range (1 to 52) for 2008; received (year 2008, week 53, weekday 1)",
      ),
      #(
        "2009-W54-1",
        "Invalid week date: week 54 is out of range (1 to 53) for 2009; received (year 2009, week 54, weekday 1)",
      ),
      // weekday
      #(
        "2008-W01-0",
        "Invalid week date: weekday 0 is out of range (1 to 7); received (year 2008, week 1, weekday 0)",
      ),
      #(
        "2008-W01-8",
        "Invalid week date: weekday 8 is out of range (1 to 7); received (year 2008, week 1, weekday 8)",
      ),
    ],
    fn(tuple) { date.from_iso_string(tuple.0) |> should.equal(Error(tuple.1)) },
  )
}

//         , describe "returns Err for a valid date followed by a 'T'" <|
//             List.map
//                 (\s -> test s <| \() -> Date.fromIsoString s |> equal (Err "Expected a date only, not a date and time"))
//                 [ "2018-09-26T00:00:00.000Z"
//                 , "2018-W39-3T00:00:00.000Z"
//                 , "2018-269T00:00:00.000Z"
//                 ]
pub fn from_iso_string_errors_for_valid_date_followed_by_t_test() {
  list.each(
    [
      "2018-09-26T00:00:00.000Z", "2018-W39-3T00:00:00.000Z",
      "2018-269T00:00:00.000Z",
    ],
    fn(string) {
      date.from_iso_string(string)
      |> should.equal(Error("Expected a date only, not a date and time"))
    },
  )
}

//         , describe "returns Err for a valid date followed by anything else" <|
//             List.map
//                 (\s -> test s <| \() -> Date.fromIsoString s |> equal (Err "Expected a date only"))
//                 [ "2018-09-26 "
//                 , "2018-W39-3 "
//                 , "2018-269 "
//                 ]
pub fn from_iso_string_errors_for_valid_date_followed_by_anything_else_test() {
  list.each(["2018-09-26 ", "2018-W39-3 ", "2018-269 "], fn(string) {
    date.from_iso_string(string)
    |> should.equal(Error("Expected a date only"))
  })
}

//         , describe "returns error messages describing only one parser dead end" <|
//             List.map
//                 (\s -> test s <| \() -> Date.fromIsoString s |> equal (Err "Expected a date in ISO 8601 format"))
//                 [ "2018-"
//                 ]
pub fn from_iso_string_errors_describing_only_one_parser_dead_end_test() {
  list.each(["2018-"], fn(string) {
    date.from_iso_string(string)
    |> should.equal(Error("Expected a date in ISO 8601 format"))
  })
}

//         , describe "can form an isomorphism with toIsoString"
//             (List.concat
//                 [ List.range 1897 1905
//                 , List.range 1997 2025
//                 , List.range -5 5
//                 ]
//                 |> List.concatMap calendarDatesInYear
//                 |> List.map
//                     (\calendarDate ->
//                         test (Debug.toString calendarDate) <|
//                             \() ->
//                                 expectIsomorphism
//                                     (Result.map Date.toIsoString)
//                                     (Result.andThen Date.fromIsoString)
//                                     (Ok <| fromCalendarDate calendarDate)
//                     )
//             )
pub fn from_iso_string_can_form_an_isomorphism_with_to_iso_string_test() {
  list.concat([
    list.range(1897, 1905),
    list.range(1997, 2025),
    list.range(-5, 5),
  ])
  |> list.map(calendar_dates_in_year)
  |> list.concat
  |> list.each(fn(date) {
    expect_isomorphism(
      fn(val) { val |> result.map(date.to_iso_string) },
      fn(val) { val |> result.then(date.from_iso_string) },
      Ok(from_calendar_date(date)),
    )
  })
}

//         , describe "can form an isomorphism with `format \"yyyy-DDD\"`"
//             (List.concat
//                 [ List.range 1997 2005
//                 , List.range -5 5
//                 ]
//                 |> List.concatMap calendarDatesInYear
//                 |> List.map
//                     (\calendarDate ->
//                         test (Debug.toString calendarDate) <|
//                             \() ->
//                                 expectIsomorphism
//                                     (Result.map (Date.format "yyyy-DDD"))
//                                     (Result.andThen Date.fromIsoString)
//                                     (Ok <| fromCalendarDate calendarDate)
//                     )
//             )
pub fn from_iso_string_can_form_an_isomorphism_with_format_yyyy_ddd_test() {
  list.concat([list.range(1997, 2005), list.range(-5, 5)])
  |> list.map(calendar_dates_in_year)
  |> list.concat
  |> list.each(fn(date) {
    expect_isomorphism(
      fn(val) { val |> result.map(fn(date) { date.format(date, "yyyy-DDD") }) },
      fn(val) { val |> result.then(date.from_iso_string) },
      Ok(from_calendar_date(date)),
    )
  })
}

//         , describe "can form an isomorphism with `format \"YYYY-'W'ww-e\"`"
//             (List.concat
//                 [ List.range 1997 2005
//                 , List.range -5 5
//                 ]
//                 |> List.concatMap calendarDatesInYear
//                 |> List.map
//                     (\calendarDate ->
//                         test (Debug.toString calendarDate) <|
//                             \() ->
//                                 expectIsomorphism
//                                     (Result.map (Date.format "YYYY-'W'ww-e"))
//                                     (Result.andThen Date.fromIsoString)
//                                     (Ok <| fromCalendarDate calendarDate)
//                     )
//             )
//         ]
pub fn from_iso_string_can_form_an_isomorphism_with_format_yyyy_w_www_e_test() {
  list.concat([list.range(1997, 2005), list.range(-5, 5)])
  |> list.map(calendar_dates_in_year)
  |> list.concat
  |> list.each(fn(date) {
    expect_isomorphism(
      fn(val) {
        val |> result.map(fn(date) { date.format(date, "YYYY-'W'ww-e") })
      },
      fn(val) { val |> result.then(date.from_iso_string) },
      Ok(from_calendar_date(date)),
    )
  })
}

// test_fromOrdinalDate : Test
// test_fromOrdinalDate =
//     describe "fromOrdinalDate"
//         [ describe "clamps days that are out of range for the given year"
//             (List.map
//                 (\( ( y, od ), expected ) ->
//                     test (Debug.toString ( y, od ) ++ " " ++ Debug.toString expected) <|
//                         \() ->
//                             Date.fromOrdinalDate y od |> toOrdinalDate |> equal expected
//                 )
//                 [ ( ( 2000, -1 ), OrdinalDate 2000 1 )
//                 , ( ( 2000, 0 ), OrdinalDate 2000 1 )
//                 , ( ( 2001, 366 ), OrdinalDate 2001 365 )
//                 , ( ( 2000, 367 ), OrdinalDate 2000 366 )
//                 ]
//             )
//         ]
pub fn from_ordinal_date_test() {
  list.each(
    [
      #(#(2000, -1), date.OrdinalDate(2000, 1)),
      #(#(2000, 0), date.OrdinalDate(2000, 1)),
      #(#(2001, 366), date.OrdinalDate(2001, 365)),
      #(#(2000, 367), date.OrdinalDate(2000, 366)),
    ],
    fn(tuple) {
      date.from_ordinal_date({ tuple.0 }.0, { tuple.0 }.1)
      |> to_ordinal_date
      |> should.equal(tuple.1)
    },
  )
}

// test_fromCalendarDate : Test
// test_fromCalendarDate =
//     describe "fromCalendarDate"
//         [ describe "clamps days that are out of range for the given year and month"
//             (List.map
//                 (\( ( y, m, d ), expected ) ->
//                     test (Debug.toString ( y, m, d ) ++ " " ++ Debug.toString expected) <|
//                         \() ->
//                             Date.fromCalendarDate y m d |> toCalendarDate |> equal expected
//                 )
//                 [ ( ( 2000, Jan, -1 ), CalendarDate 2000 Jan 1 )
//                 , ( ( 2000, Jan, 0 ), CalendarDate 2000 Jan 1 )
//                 , ( ( 2000, Jan, 32 ), CalendarDate 2000 Jan 31 )
//                 , ( ( 2000, Feb, 0 ), CalendarDate 2000 Feb 1 )
//                 , ( ( 2001, Feb, 29 ), CalendarDate 2001 Feb 28 )
//                 , ( ( 2000, Feb, 30 ), CalendarDate 2000 Feb 29 )
//                 , ( ( 2000, Mar, 32 ), CalendarDate 2000 Mar 31 )
//                 , ( ( 2000, Apr, 31 ), CalendarDate 2000 Apr 30 )
//                 , ( ( 2000, May, 32 ), CalendarDate 2000 May 31 )
//                 , ( ( 2000, Jun, 31 ), CalendarDate 2000 Jun 30 )
//                 , ( ( 2000, Jul, 32 ), CalendarDate 2000 Jul 31 )
//                 , ( ( 2000, Aug, 32 ), CalendarDate 2000 Aug 31 )
//                 , ( ( 2000, Sep, 31 ), CalendarDate 2000 Sep 30 )
//                 , ( ( 2000, Oct, 32 ), CalendarDate 2000 Oct 31 )
//                 , ( ( 2000, Nov, 31 ), CalendarDate 2000 Nov 30 )
//                 , ( ( 2000, Dec, 32 ), CalendarDate 2000 Dec 31 )
//                 ]
//             )
//         ]
pub fn from_calendar_date_test() {
  list.each(
    [
      #(#(2000, date.Jan, -1), date.CalendarDate(2000, date.Jan, 1)),
      #(#(2000, date.Jan, 0), date.CalendarDate(2000, date.Jan, 1)),
      #(#(2000, date.Jan, 32), date.CalendarDate(2000, date.Jan, 31)),
      #(#(2000, date.Feb, 0), date.CalendarDate(2000, date.Feb, 1)),
      #(#(2001, date.Feb, 29), date.CalendarDate(2001, date.Feb, 28)),
      #(#(2000, date.Feb, 30), date.CalendarDate(2000, date.Feb, 29)),
      #(#(2000, date.Mar, 32), date.CalendarDate(2000, date.Mar, 31)),
      #(#(2000, date.Apr, 31), date.CalendarDate(2000, date.Apr, 30)),
      #(#(2000, date.May, 32), date.CalendarDate(2000, date.May, 31)),
      #(#(2000, date.Jun, 31), date.CalendarDate(2000, date.Jun, 30)),
      #(#(2000, date.Jul, 32), date.CalendarDate(2000, date.Jul, 31)),
      #(#(2000, date.Aug, 32), date.CalendarDate(2000, date.Aug, 31)),
      #(#(2000, date.Sep, 31), date.CalendarDate(2000, date.Sep, 30)),
      #(#(2000, date.Oct, 32), date.CalendarDate(2000, date.Oct, 31)),
      #(#(2000, date.Nov, 31), date.CalendarDate(2000, date.Nov, 30)),
      #(#(2000, date.Dec, 32), date.CalendarDate(2000, date.Dec, 31)),
    ],
    fn(tuple) {
      date.from_calendar_date({ tuple.0 }.0, { tuple.0 }.1, { tuple.0 }.2)
      |> to_calendar_date
      |> should.equal(tuple.1)
    },
  )
}

// test_fromWeekDate : Test
// test_fromWeekDate =
//     describe "fromWeekDate"
//         [ describe "clamps weeks that are out of range for the given week-year"
//             (List.map
//                 (\( ( wy, wn, wd ), expected ) ->
//                     test (Debug.toString ( wy, wn, wd ) ++ " " ++ Debug.toString expected) <|
//                         \() ->
//                             Date.fromWeekDate wy wn wd |> toWeekDate |> equal expected
//                 )
//                 [ ( ( 2000, -1, Mon ), WeekDate 2000 1 Mon )
//                 , ( ( 2000, 0, Mon ), WeekDate 2000 1 Mon )
//                 , ( ( 2000, 53, Mon ), WeekDate 2000 52 Mon )
//                 , ( ( 2004, 54, Mon ), WeekDate 2004 53 Mon )
//                 ]
//             )
//         ]
pub fn from_week_date_test() {
  list.each(
    [
      #(#(2000, -1, date.Mon), date.WeekDate(2000, 1, date.Mon)),
      #(#(2000, 0, date.Mon), date.WeekDate(2000, 1, date.Mon)),
      #(#(2000, 53, date.Mon), date.WeekDate(2000, 52, date.Mon)),
      #(#(2004, 54, date.Mon), date.WeekDate(2004, 53, date.Mon)),
    ],
    fn(tuple) {
      date.from_week_date({ tuple.0 }.0, { tuple.0 }.1, { tuple.0 }.2)
      |> to_week_date
      |> should.equal(tuple.1)
    },
  )
}

// test_numberToMonth : Test
// test_numberToMonth =
//     describe "numberToMonth"
//         [ describe "clamps numbers that are out of range"
//             (List.map
//                 (\( n, month ) ->
//                     test (Debug.toString ( n, month )) <| \() -> n |> Date.numberToMonth |> equal month
//                 )
//                 [ ( -1, Jan )
//                 , ( 0, Jan )
//                 , ( 13, Dec )
//                 ]
//             )
//         ]
pub fn number_to_month_test() {
  list.each([#(-1, date.Jan), #(0, date.Jan), #(13, date.Dec)], fn(tuple) {
    tuple.0 |> date.number_to_month |> should.equal(tuple.1)
  })
}

// test_numberToWeekday : Test
// test_numberToWeekday =
//     describe "numberToWeekday"
//         [ describe "clamps numbers that are out of range"
//             (List.map
//                 (\( n, weekday ) ->
//                     test (Debug.toString ( n, weekday )) <| \() -> n |> Date.numberToWeekday |> equal weekday
//                 )
//                 [ ( -1, Mon )
//                 , ( 0, Mon )
//                 , ( 8, Sun )
//                 ]
//             )
//         ]
pub fn number_to_weekday_test() {
  list.each([#(-1, date.Mon), #(0, date.Mon), #(8, date.Sun)], fn(tuple) {
    tuple.0 |> date.number_to_weekday |> should.equal(tuple.1)
  })
}

// {-
//    test_is53WeekYear : Test
//    test_is53WeekYear =
//        test "is53WeekYear" <|
//            \() ->
//                List.range 1970 2040
//                    |> List.filter Date.is53WeekYear
//                    |> equal [ 1970, 1976, 1981, 1987, 1992, 1998, 2004, 2009, 2015, 2020, 2026, 2032, 2037 ]
// -}

// test_compare : Test
// test_compare =
//     describe "compare"
//         [ describe "returns an Order" <|
//             List.map
//                 (\( a, b, expected ) ->
//                     test (Debug.toString a ++ " " ++ Debug.toString b) <|
//                         \() -> Date.compare a b |> equal expected
//                 )
//                 [ ( Date.fromOrdinalDate 1970 1, Date.fromOrdinalDate 2038 1, LT )
//                 , ( Date.fromOrdinalDate 1970 1, Date.fromOrdinalDate 1970 1, EQ )
//                 , ( Date.fromOrdinalDate 2038 1, Date.fromOrdinalDate 1970 1, GT )
//                 ]
pub fn compare_returns_order_test() {
  list.each(
    [
      #(
        date.from_ordinal_date(1970, 1),
        date.from_ordinal_date(2038, 1),
        order.Lt,
      ),
      #(
        date.from_ordinal_date(1970, 1),
        date.from_ordinal_date(1970, 1),
        order.Eq,
      ),
      #(
        date.from_ordinal_date(2038, 1),
        date.from_ordinal_date(1970, 1),
        order.Gt,
      ),
    ],
    fn(tuple) { date.compare(tuple.0, tuple.1) |> should.equal(tuple.2) },
  )
}

//         , test "can be used with List.sortWith" <|
//             \() ->
//                 [ Date.fromOrdinalDate 2038 1
//                 , Date.fromOrdinalDate 2038 19
//                 , Date.fromOrdinalDate 1970 1
//                 , Date.fromOrdinalDate 1969 201
//                 , Date.fromOrdinalDate 2001 1
//                 ]
//                     |> List.sortWith Date.compare
//                     |> equal
//                         [ Date.fromOrdinalDate 1969 201
//                         , Date.fromOrdinalDate 1970 1
//                         , Date.fromOrdinalDate 2001 1
//                         , Date.fromOrdinalDate 2038 1
//                         , Date.fromOrdinalDate 2038 19
//                         ]
//         ]
pub fn compare_can_be_used_with_list_sort_test() {
  list.sort(
    [
      date.from_ordinal_date(2038, 1),
      date.from_ordinal_date(2038, 19),
      date.from_ordinal_date(1970, 1),
      date.from_ordinal_date(1969, 201),
      date.from_ordinal_date(2001, 1),
    ],
    date.compare,
  )
  |> should.equal([
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2001, 1),
    date.from_ordinal_date(2038, 1),
    date.from_ordinal_date(2038, 19),
  ])
}

// test_isBetween : Test
// test_isBetween =
//     let
//         ( a, b, c ) =
//             ( Date.fromOrdinalDate 1969 201
//             , Date.fromOrdinalDate 1970 1
//             , Date.fromOrdinalDate 2038 19
//             )

//         toTest : ( String, ( Date, Date, Date ), Bool ) -> Test
//         toTest ( desc, ( minimum, maximum, x ), expected ) =
//             test desc <|
//                 \() ->
//                     Date.isBetween minimum maximum x |> equal expected
//     in
//     describe "isBetween"
//         [ describe "when min < max, works as expected" <|
//             List.map toTest
//                 [ ( "before", ( b, c, a ), False )
//                 , ( "min", ( b, c, b ), True )
//                 , ( "middle", ( a, c, b ), True )
//                 , ( "max", ( a, b, b ), True )
//                 , ( "after", ( a, b, c ), False )
//                 ]

pub fn is_between_with_min_less_than_max_test() {
  let #(a, b, c) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2038, 19),
  )

  list.each(
    [
      #("before", #(b, c, a), False),
      #("min", #(b, c, b), True),
      #("middle", #(a, c, b), True),
      #("max", #(a, b, b), True),
      #("after", #(a, b, c), False),
    ],
    fn(tuple) {
      date.is_between({ tuple.1 }.2, { tuple.1 }.0, { tuple.1 }.1)
      |> should.equal(tuple.2)
    },
  )
}

//         , describe "when min == max, works as expected" <|
//             List.map toTest
//                 [ ( "before", ( b, b, a ), False )
//                 , ( "equal", ( b, b, b ), True )
//                 , ( "after", ( b, b, c ), False )
//                 ]
pub fn is_between_with_min_equal_than_max_test() {
  let #(a, b, c) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2038, 19),
  )

  list.each(
    [
      #("before", #(b, b, a), False),
      #("equal", #(b, b, b), True),
      #("after", #(b, b, c), False),
    ],
    fn(tuple) {
      date.is_between({ tuple.1 }.2, { tuple.1 }.0, { tuple.1 }.1)
      |> should.equal(tuple.2)
    },
  )
}

//         , describe "when min > max, always returns False" <|
//             List.map toTest
//                 [ ( "before", ( c, b, a ), False )
//                 , ( "min", ( c, b, b ), False )
//                 , ( "middle", ( c, a, b ), False )
//                 , ( "max", ( b, a, b ), False )
//                 , ( "after", ( b, a, c ), False )
//                 ]
//         ]
pub fn is_between_with_min_greater_than_than_max_test() {
  let #(a, b, c) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2038, 19),
  )

  list.each(
    [
      #("before", #(c, b, a), False),
      #("min", #(c, b, b), False),
      #("middle", #(c, a, b), False),
      #("max", #(b, a, b), False),
      #("after", #(b, a, c), False),
    ],
    fn(tuple) {
      date.is_between({ tuple.1 }.2, { tuple.1 }.0, { tuple.1 }.1)
      |> should.equal(tuple.2)
    },
  )
}

// test_min : Test
// test_min =
//     let
//         ( a, b ) =
//             ( Date.fromOrdinalDate 1969 201
//             , Date.fromOrdinalDate 1970 1
//             )
//     in
//     describe "min"
//         [ test "a b" <| \() -> Date.min a b |> equal a
//         , test "b a" <| \() -> Date.min b a |> equal a
//         ]
pub fn min_test() {
  let #(a, b) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
  )

  date.min(a, b) |> should.equal(a)
  date.min(b, a) |> should.equal(a)
}

// test_max : Test
// test_max =
//     let
//         ( a, b ) =
//             ( Date.fromOrdinalDate 1969 201
//             , Date.fromOrdinalDate 1970 1
//             )
//     in
//     describe "max"
//         [ test "a b" <| \() -> Date.max a b |> equal b
//         , test "b a" <| \() -> Date.max b a |> equal b
//         ]
pub fn max_test() {
  let #(a, b) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
  )

  date.max(a, b) |> should.equal(b)
  date.max(b, a) |> should.equal(b)
}

// test_clamp : Test
// test_clamp =
//     let
//         ( a, b, c ) =
//             ( Date.fromOrdinalDate 1969 201
//             , Date.fromOrdinalDate 1970 1
//             , Date.fromOrdinalDate 2038 19
//             )

//         toTest : ( String, ( Date, Date, Date ), Date ) -> Test
//         toTest ( desc, ( minimum, maximum, x ), expected ) =
//             test desc <|
//                 \() ->
//                     Date.clamp minimum maximum x |> equal expected
//     in
//     describe "clamp"
//         [ describe "when min < max, works as expected" <|
//             List.map toTest
//                 [ ( "before", ( b, c, a ), b )
//                 , ( "min", ( b, c, b ), b )
//                 , ( "middle", ( a, c, b ), b )
//                 , ( "max", ( a, b, b ), b )
//                 , ( "after", ( a, b, c ), b )
//                 ]
pub fn clamp_with_min_less_than_max_test() {
  let #(a, b, c) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2038, 19),
  )

  list.each(
    [
      #("before", #(b, c, a), b),
      #("min", #(b, c, b), b),
      #("middle", #(a, c, b), b),
      #("max", #(a, b, b), b),
      #("after", #(a, b, c), b),
    ],
    fn(tuple) {
      date.clamp({ tuple.1 }.2, { tuple.1 }.0, { tuple.1 }.1)
      |> should.equal(tuple.2)
    },
  )
}

//         , describe "when min == max, works as expected" <|
//             List.map toTest
//                 [ ( "before", ( b, b, a ), b )
//                 , ( "equal", ( b, b, b ), b )
//                 , ( "after", ( b, b, c ), b )
//                 ]
//         ]
pub fn clamp_with_min_equals_max_test() {
  let #(a, b, c) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
    date.from_ordinal_date(2038, 19),
  )

  list.each(
    [
      #("before", #(b, b, a), b),
      #("equal", #(b, b, b), b),
      #("after", #(b, b, c), b),
    ],
    fn(tuple) {
      date.clamp({ tuple.1 }.2, { tuple.1 }.0, { tuple.1 }.1)
      |> should.equal(tuple.2)
    },
  )
}

// Additional tests - not part of the original port

pub fn year_test() {
  date.from_calendar_date(1, date.Jan, 1)
  |> date.year
  |> should.equal(1)

  date.from_calendar_date(2, date.Jan, 1)
  |> date.year
  |> should.equal(2)

  date.from_calendar_date(2020, date.May, 23)
  |> date.year
  |> should.equal(2020)

  date.from_calendar_date(-5, date.May, 30)
  |> date.year
  |> should.equal(-5)
}

// -- records

// type alias OrdinalDate =
//     { year : Int, ordinalDay : Int }

// toOrdinalDate : Date -> OrdinalDate
// toOrdinalDate date =
//     OrdinalDate
//         (date |> Date.year)
//         (date |> Date.ordinalDay)
fn to_ordinal_date(date: Date) {
  date.OrdinalDate(year: date.year(date), ordinal_day: date.ordinal_day(date))
}

// type alias CalendarDate =
//     { year : Int, month : Month, day : Int }

// fromCalendarDate : CalendarDate -> Date
// fromCalendarDate { year, month, day } =
//     Date.fromCalendarDate year month day
fn from_calendar_date(date: CalendarDate) -> date.Date {
  date.from_calendar_date(date.year, date.month, date.day)
}

// toCalendarDate : Date -> CalendarDate
// toCalendarDate date =
//     CalendarDate
//         (date |> Date.year)
//         (date |> Date.month)
//         (date |> Date.day)
fn to_calendar_date(date: date.Date) -> CalendarDate {
  CalendarDate(date.year(date), date.month(date), date.day(date))
}

// type alias WeekDate =
//     { weekYear : Int, weekNumber : Int, weekday : Weekday }

// fromWeekDate : WeekDate -> Date
// fromWeekDate { weekYear, weekNumber, weekday } =
//     Date.fromWeekDate weekYear weekNumber weekday
fn from_week_date(week_date: WeekDate) -> Date {
  let WeekDate(week_year, week_number, weekday) = week_date
  date.from_week_date(week_year, week_number, weekday)
}

// toWeekDate : Date -> WeekDate
// toWeekDate date =
//     WeekDate
//         (date |> Date.weekYear)
//         (date |> Date.weekNumber)
//         (date |> Date.weekday)
fn to_week_date(date: Date) -> WeekDate {
  date.WeekDate(
    week_year: date.week_year(date),
    week_number: date.week_number(date),
    weekday: date.weekday(date),
  )
}

// -- dates

// calendarDatesInYear : Int -> List CalendarDate
// calendarDatesInYear y =
//     [ Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec ]
//         |> List.concatMap
//             (\m -> List.range 1 (daysInMonth y m) |> List.map (CalendarDate y m))

fn calendar_dates_in_year(year: Int) -> List(CalendarDate) {
  [
    date.Jan,
    date.Feb,
    date.Mar,
    date.Apr,
    date.May,
    date.Jun,
    date.Jul,
    date.Aug,
    date.Sep,
    date.Oct,
    date.Nov,
    date.Dec,
  ]
  |> list.map(fn(month) {
    list.range(1, date.days_in_month(year, month))
    |> list.map(fn(day) { CalendarDate(year, month, day) })
  })
  |> list.concat
}

// isLeapYear : Int -> Bool
// isLeapYear y =
//     modBy 4 y == 0 && modBy 100 y /= 0 || modBy 400 y == 0

// daysInMonth : Int -> Month -> Int
// daysInMonth y m =
//     case m of
//         Jan ->
//             31

//         Feb ->
//             if isLeapYear y then
//                 29

//             else
//                 28

//         Mar ->
//             31

//         Apr ->
//             30

//         May ->
//             31

//         Jun ->
//             30

//         Jul ->
//             31

//         Aug ->
//             31

//         Sep ->
//             30

//         Oct ->
//             31

//         Nov ->
//             30

//         Dec ->
//             31

// -- result

// extractErr : x -> Result x a -> x
// extractErr default result =
//     case result of
//         Err x ->
//             x

//         Ok _ ->
//             default

// -- expectation

// expectIsomorphism : (x -> y) -> (y -> x) -> x -> Expectation
// expectIsomorphism xToY yToX x =
//     x |> xToY |> yToX |> equal x
fn expect_isomorphism(x_to_y, y_to_x, x) {
  // io.println(
  // string.inspect(x) <> " : " <> string.inspect(x |> x_to_y |> y_to_x),
  // )
  x |> x_to_y |> y_to_x |> should.equal(x)
}

// expectIdempotence : (x -> x) -> x -> Expectation
// expectIdempotence f x =
//     f (f x) |> equal (f x)
fn expect_idempotence(x_to_x, x) {
  x_to_x(x_to_x(x)) |> should.equal(x_to_x(x))
}

fn tuple_to_calendar_date(tuple: #(Int, date.Month, Int)) {
  date.from_calendar_date(tuple.0, tuple.1, tuple.2)
}
