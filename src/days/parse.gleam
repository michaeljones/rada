import gleam/regex
import nibble/lexer as nl

pub type ParseDateToken {
  Digits(String)
  WeekToken
  Dash
}

pub fn lexer() {
  let options = regex.Options(case_insensitive: False, multi_line: True)
  let assert Ok(digits_regex) = regex.compile("^[0-9]+$", options)
  let is_digits = fn(str) { regex.check(digits_regex, str) }

  nl.simple([
    nl.custom(fn(mode, lexeme, next_grapheme) {
      case lexeme {
        "" -> nl.Drop(mode)
        "W" -> nl.Keep(WeekToken, mode)
        "-" -> nl.Keep(Dash, mode)
        _ -> {
          case is_digits(lexeme) {
            True ->
              case is_digits(next_grapheme) {
                True -> nl.Skip
                False -> nl.Keep(Digits(lexeme), mode)
              }
            False -> nl.NoMatch
          }
        }
      }
    }),
  ])
}
