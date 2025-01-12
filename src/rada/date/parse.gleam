import gleam/regexp
import nibble/lexer as nl

pub type ParseDateToken {
  Digit(String)
  WeekToken
  Dash
  TimeToken
  Other(String)
}

pub fn lexer() {
  let options = regexp.Options(case_insensitive: False, multi_line: True)
  let assert Ok(digits_regex) = regexp.compile("^[0-9]+$", options)
  let is_digits = fn(str) { regexp.check(digits_regex, str) }

  nl.simple([
    nl.custom(fn(mode, lexeme, _next_grapheme) {
      case lexeme {
        "" -> nl.Drop(mode)
        "W" -> nl.Keep(WeekToken, mode)
        "T" -> nl.Keep(TimeToken, mode)
        "-" -> nl.Keep(Dash, mode)
        _ -> {
          case is_digits(lexeme) {
            True -> nl.Keep(Digit(lexeme), mode)
            False -> nl.Keep(Other(lexeme), mode)
          }
        }
      }
    }),
  ])
}
