import gleam/list
import gleam/result
import gleeunit/should
import nibble/lexer as nl

import date
import date/parse as dp

pub fn lex_ordinal_date_test() {
  nl.run("2019-269", dp.lexer())
  |> result.map(fn(list_) {
    list_
    |> list.map(fn(entry) { entry.value })
  })
  |> should.equal(
    Ok([
      dp.Digit("2"),
      dp.Digit("0"),
      dp.Digit("1"),
      dp.Digit("9"),
      dp.Dash,
      dp.Digit("2"),
      dp.Digit("6"),
      dp.Digit("9"),
    ]),
  )
}

pub fn lex_week_date_test() {
  nl.run("2018-W39-3", dp.lexer())
  |> result.map(fn(list_) {
    list_
    |> list.map(fn(entry) { entry.value })
  })
  |> should.equal(
    Ok([
      dp.Digit("2"),
      dp.Digit("0"),
      dp.Digit("1"),
      dp.Digit("8"),
      dp.Dash,
      dp.WeekToken,
      dp.Digit("3"),
      dp.Digit("9"),
      dp.Dash,
      dp.Digit("3"),
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
    Ok([
      dp.Digit("2"),
      dp.Digit("0"),
      dp.Digit("1"),
      dp.Digit("8"),
      dp.Dash,
      dp.Digit("0"),
      dp.Digit("9"),
      dp.Dash,
      dp.Digit("2"),
      dp.Digit("6"),
    ]),
  )
}

pub fn parse_calendar_date_test() {
  date.from_iso_string("2018-09-26")
  |> should.equal(Ok(date.from_calendar_date(2018, date.Sep, 26)))
}

pub fn parse_week_weekday_date_test() {
  date.from_iso_string("2009-W01-4")
  |> should.equal(Ok(date.from_calendar_date(2009, date.Jan, 1)))
}
