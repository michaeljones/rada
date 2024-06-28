import gleam/list
import gleam/order
import gleam/result
import gleeunit
import gleeunit/should

import french_language.{language_fr}
import rada/date.{type Date}
import rada/testing as t

pub fn main() {
  gleeunit.main()
}

// // Commented out as today changes :)
// pub fn today_test() {
//   date.today()
//   |> should.equal(date.from_calendar_date(2024, date.Jun, 10))
// }

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

pub fn weekday_number_test() {
  date.from_calendar_date(2020, date.Mar, 04)
  |> date.weekday_number
  |> should.equal(3)
}

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
    #(t.CalendarDate(2005, date.Jan, 1), t.WeekDate(2004, 53, date.Sat)),
    #(t.CalendarDate(2005, date.Jan, 2), t.WeekDate(2004, 53, date.Sun)),
    #(t.CalendarDate(2005, date.Dec, 31), t.WeekDate(2005, 52, date.Sat)),
    #(t.CalendarDate(2007, date.Jan, 1), t.WeekDate(2007, 1, date.Mon)),
    #(t.CalendarDate(2007, date.Dec, 30), t.WeekDate(2007, 52, date.Sun)),
    #(t.CalendarDate(2007, date.Dec, 31), t.WeekDate(2008, 1, date.Mon)),
    #(t.CalendarDate(2008, date.Jan, 1), t.WeekDate(2008, 1, date.Tue)),
    #(t.CalendarDate(2008, date.Dec, 28), t.WeekDate(2008, 52, date.Sun)),
    #(t.CalendarDate(2008, date.Dec, 29), t.WeekDate(2009, 1, date.Mon)),
    #(t.CalendarDate(2008, date.Dec, 30), t.WeekDate(2009, 1, date.Tue)),
    #(t.CalendarDate(2008, date.Dec, 31), t.WeekDate(2009, 1, date.Wed)),
    #(t.CalendarDate(2009, date.Jan, 1), t.WeekDate(2009, 1, date.Thu)),
    #(t.CalendarDate(2009, date.Dec, 31), t.WeekDate(2009, 53, date.Thu)),
    #(t.CalendarDate(2010, date.Jan, 1), t.WeekDate(2009, 53, date.Fri)),
    #(t.CalendarDate(2010, date.Jan, 2), t.WeekDate(2009, 53, date.Sat)),
    #(t.CalendarDate(2010, date.Jan, 3), t.WeekDate(2009, 53, date.Sun)),
  ]
  |> list.map(fn(tuple) {
    let #(calendar_date, week_date) = tuple
    should.equal(from_calendar_date(calendar_date) |> to_week_date, week_date)
  })
}

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

pub fn format_removes_unsupported_pattern_characters_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("ABCFGHIJKLNOPRSTUVWXZabcfghijklmnopqrstuvxz")
  |> should.equal("")
}

pub fn format_ignores_non_alpha_characters_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("0123456789 .,\\//:-%")
  |> should.equal("0123456789 .,\\//:-%")
}

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

pub fn format_is_lenient_on_unclosed_quotes_test() {
  let date = date.from_calendar_date(2008, date.Dec, 31)
  date
  |> date.format("yyyy 'yyyy")
  |> should.equal("2008 yyyy")
}

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

pub fn add_years_from_a_leap_day_clamps_to_end_of_feb_test() {
  test_add(#(2000, date.Feb, 29), 1, date.Years, #(2001, date.Feb, 28))
  test_add(#(2000, date.Feb, 29), 4, date.Years, #(2004, date.Feb, 29))
}

pub fn add_months_clamps_to_end_of_short_month_test() {
  test_add(#(2000, date.Jan, 31), 1, date.Months, #(2000, date.Feb, 29))
  test_add(#(2000, date.Jan, 31), 2, date.Months, #(2000, date.Mar, 31))
  test_add(#(2000, date.Jan, 31), 3, date.Months, #(2000, date.Apr, 30))
  test_add(#(2000, date.Jan, 31), 13, date.Months, #(2001, date.Feb, 28))
}

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

pub fn diff_diffing_years_handles_leap_years_test() {
  test_diff(#(2000, date.Feb, 29), #(2001, date.Feb, 28), 0, date.Years)
  test_diff(#(2000, date.Feb, 29), #(2004, date.Feb, 29), 4, date.Years)
}

pub fn diff_diffing_months_handles_leap_year_febs_test() {
  test_diff(#(2000, date.Jan, 31), #(2000, date.Feb, 29), 0, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2000, date.Mar, 31), 2, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2000, date.Apr, 30), 2, date.Months)
  test_diff(#(2000, date.Jan, 31), #(2001, date.Feb, 28), 12, date.Months)
}

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

pub fn range_returns_a_list_of_days_test() {
  date.range(
    date.Day,
    1,
    date.from_calendar_date(2000, date.Jan, 1),
    date.from_calendar_date(2001, date.Jan, 1),
  )
  |> should.equal(calendar_dates_in_year(2000) |> list.map(from_calendar_date))
}

pub fn range_can_return_empty_list_test() {
  date.range(
    date.Day,
    1,
    date.from_calendar_date(2000, date.Jan, 1),
    date.from_calendar_date(2000, date.Jan, 1),
  )
  |> should.equal([])
}

pub fn range_can_return_large_list_test() {
  let start = date.from_calendar_date(1950, date.Jan, 1)
  let end = date.from_calendar_date(2050, date.Jan, 1)

  let expected_length = date.diff(date.Days, start, end)

  date.range(date.Day, 1, start, end)
  |> list.length
  |> should.equal(expected_length)
}

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

pub fn from_iso_string_errors_for_valid_date_followed_by_anything_else_test() {
  list.each(["2018-09-26 ", "2018-W39-3 ", "2018-269 "], fn(string) {
    date.from_iso_string(string)
    |> should.equal(Error("Expected a date only"))
  })
}

pub fn from_iso_string_errors_describing_only_one_parser_dead_end_test() {
  list.each(["2018-"], fn(string) {
    date.from_iso_string(string)
    |> should.equal(Error("Expected a date in ISO 8601 format"))
  })
}

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

pub fn from_ordinal_date_test() {
  list.each(
    [
      #(#(2000, -1), t.OrdinalDate(2000, 1)),
      #(#(2000, 0), t.OrdinalDate(2000, 1)),
      #(#(2001, 366), t.OrdinalDate(2001, 365)),
      #(#(2000, 367), t.OrdinalDate(2000, 366)),
    ],
    fn(tuple) {
      date.from_ordinal_date({ tuple.0 }.0, { tuple.0 }.1)
      |> to_ordinal_date
      |> should.equal(tuple.1)
    },
  )
}

pub fn from_calendar_date_test() {
  list.each(
    [
      #(#(2000, date.Jan, -1), t.CalendarDate(2000, date.Jan, 1)),
      #(#(2000, date.Jan, 0), t.CalendarDate(2000, date.Jan, 1)),
      #(#(2000, date.Jan, 32), t.CalendarDate(2000, date.Jan, 31)),
      #(#(2000, date.Feb, 0), t.CalendarDate(2000, date.Feb, 1)),
      #(#(2001, date.Feb, 29), t.CalendarDate(2001, date.Feb, 28)),
      #(#(2000, date.Feb, 30), t.CalendarDate(2000, date.Feb, 29)),
      #(#(2000, date.Mar, 32), t.CalendarDate(2000, date.Mar, 31)),
      #(#(2000, date.Apr, 31), t.CalendarDate(2000, date.Apr, 30)),
      #(#(2000, date.May, 32), t.CalendarDate(2000, date.May, 31)),
      #(#(2000, date.Jun, 31), t.CalendarDate(2000, date.Jun, 30)),
      #(#(2000, date.Jul, 32), t.CalendarDate(2000, date.Jul, 31)),
      #(#(2000, date.Aug, 32), t.CalendarDate(2000, date.Aug, 31)),
      #(#(2000, date.Sep, 31), t.CalendarDate(2000, date.Sep, 30)),
      #(#(2000, date.Oct, 32), t.CalendarDate(2000, date.Oct, 31)),
      #(#(2000, date.Nov, 31), t.CalendarDate(2000, date.Nov, 30)),
      #(#(2000, date.Dec, 32), t.CalendarDate(2000, date.Dec, 31)),
    ],
    fn(tuple) {
      date.from_calendar_date({ tuple.0 }.0, { tuple.0 }.1, { tuple.0 }.2)
      |> to_calendar_date
      |> should.equal(tuple.1)
    },
  )
}

pub fn from_week_date_test() {
  list.each(
    [
      #(#(2000, -1, date.Mon), t.WeekDate(2000, 1, date.Mon)),
      #(#(2000, 0, date.Mon), t.WeekDate(2000, 1, date.Mon)),
      #(#(2000, 53, date.Mon), t.WeekDate(2000, 52, date.Mon)),
      #(#(2004, 54, date.Mon), t.WeekDate(2004, 53, date.Mon)),
    ],
    fn(tuple) {
      date.from_week_date({ tuple.0 }.0, { tuple.0 }.1, { tuple.0 }.2)
      |> to_week_date
      |> should.equal(tuple.1)
    },
  )
}

pub fn number_to_month_test() {
  list.each([#(-1, date.Jan), #(0, date.Jan), #(13, date.Dec)], fn(tuple) {
    tuple.0 |> date.number_to_month |> should.equal(tuple.1)
  })
}

pub fn number_to_weekday_test() {
  list.each([#(-1, date.Mon), #(0, date.Mon), #(8, date.Sun)], fn(tuple) {
    tuple.0 |> date.number_to_weekday |> should.equal(tuple.1)
  })
}

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

pub fn min_test() {
  let #(a, b) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
  )

  date.min(a, b) |> should.equal(a)
  date.min(b, a) |> should.equal(a)
}

pub fn max_test() {
  let #(a, b) = #(
    date.from_ordinal_date(1969, 201),
    date.from_ordinal_date(1970, 1),
  )

  date.max(a, b) |> should.equal(b)
  date.max(b, a) |> should.equal(b)
}

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

// Converters

fn to_ordinal_date(date: Date) {
  t.OrdinalDate(year: date.year(date), ordinal_day: date.ordinal_day(date))
}

fn from_calendar_date(date: t.CalendarDate) -> date.Date {
  date.from_calendar_date(date.year, date.month, date.day)
}

fn to_calendar_date(date: date.Date) -> t.CalendarDate {
  t.CalendarDate(date.year(date), date.month(date), date.day(date))
}

fn from_week_date(week_date: t.WeekDate) -> Date {
  let t.WeekDate(week_year, week_number, weekday) = week_date
  date.from_week_date(week_year, week_number, weekday)
}

fn to_week_date(date: Date) -> t.WeekDate {
  t.WeekDate(
    week_year: date.week_year(date),
    week_number: date.week_number(date),
    weekday: date.weekday(date),
  )
}

fn tuple_to_calendar_date(tuple: #(Int, date.Month, Int)) {
  date.from_calendar_date(tuple.0, tuple.1, tuple.2)
}

// Generators

fn calendar_dates_in_year(year: Int) -> List(t.CalendarDate) {
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
    list.range(1, t.days_in_month(year, month))
    |> list.map(fn(day) { t.CalendarDate(year, month, day) })
  })
  |> list.concat
}

// Expectations

fn expect_isomorphism(x_to_y, y_to_x, x) {
  x |> x_to_y |> y_to_x |> should.equal(x)
}

fn expect_idempotence(x_to_x, x) {
  x_to_x(x_to_x(x)) |> should.equal(x_to_x(x))
}
