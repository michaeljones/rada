import gleam/list
import gleam/result
import gleeunit/should
import nibble/lexer as nl

import days
import days/parse as dp

pub fn lex_ordinal_date_test() {
  nl.run("2019-269", dp.lexer())
  |> result.map(fn(list_) {
    list_
    |> list.map(fn(entry) { entry.value })
  })
  |> should.equal(Ok([dp.Digits("2019"), dp.Dash, dp.Digits("269")]))
}

pub fn lex_week_date_test() {
  nl.run("2018-W39-3", dp.lexer())
  |> result.map(fn(list_) {
    list_
    |> list.map(fn(entry) { entry.value })
  })
  |> should.equal(
    Ok([
      dp.Digits("2018"),
      dp.Dash,
      dp.WeekToken,
      dp.Digits("39"),
      dp.Dash,
      dp.Digits("3"),
    ]),
  )
}

pub fn lex_calendar_date_test() {
  nl.run("2018-09-26", dp.lexer())
  |> result.map(fn(list_) {
    list_
    |> list.map(fn(entry) { entry.value })
  })
  |> should.equal(
    Ok([dp.Digits("2018"), dp.Dash, dp.Digits("09"), dp.Dash, dp.Digits("26")]),
  )
}

pub fn parse_calendar_date_test() {
  days.from_iso_string("2018-09-26")
  |> should.equal(Ok(days.from_calendar_date(2018, days.Sep, 26)))
}

pub fn parse_week_weekday_date_test() {
  days.from_iso_string("2009-W01-4")
  |> should.equal(Ok(days.from_calendar_date(2009, days.Jan, 1)))
}
