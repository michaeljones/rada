import gleam/list
import gleam/result
import gleam/set
import gleam/string
import nibble
import nibble/lexer

// module Pattern exposing (Pattern, Token(..), fromString)
// 
// import Char
// import Parser exposing ((|.), (|=), Parser)
// 
// 
// 
// -- date formatting pattern
// 
// 
// type alias Pattern =
//     List Token
pub type Pattern =
  List(Token)

// 
// 
// type Token
//     = Field Char Int
//     | Literal String
pub type Token {
  Field(String, Int)
  Literal(String)
}

pub type LexerToken {
  Alpha(String)
  Quote
  EscapedQuote
  Text(String)
}

fn is_alpha(token: LexerToken) {
  case token {
    Alpha(_) -> True
    _ -> False
  }
}

fn is_specific_alpha(char: String) {
  fn(token: LexerToken) {
    case token {
      Alpha(c) -> c == char
      _ -> False
    }
  }
}

fn is_text(token: LexerToken) {
  case token {
    Text(_) -> True
    _ -> False
  }
}

fn is_quote(token: LexerToken) {
  case token {
    Quote -> True
    _ -> False
  }
}

fn extract_content(tokens: List(LexerToken)) {
  case tokens {
    [] -> ""
    [token, ..rest] -> {
      case token {
        Alpha(str) -> str <> extract_content(rest)
        Quote -> "'" <> extract_content(rest)
        EscapedQuote -> "'" <> extract_content(rest)
        Text(str) -> str <> extract_content(rest)
      }
    }
  }
}

// 
// 
// fromString : String -> Pattern
// fromString str =
//     Parser.run (patternHelp []) str
//         |> Result.withDefault [ Literal str ]
pub fn from_string(str: String) -> Pattern {
  let alpha =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    |> string.to_graphemes
    |> set.from_list

  let is_alpha = fn(char) { set.contains(alpha, char) }

  let l =
    lexer.simple([
      lexer.keep(fn(lexeme, _grapheme) {
        case is_alpha(lexeme) {
          True -> {
            Ok(Alpha(lexeme))
          }
          False -> {
            Error(Nil)
          }
        }
      }),
      lexer.custom(fn(mode, lexeme, next_grapheme) {
        case lexeme {
          "'" ->
            case next_grapheme {
              "'" -> lexer.Skip
              _ -> lexer.Keep(Quote, mode)
            }
          "''" -> lexer.Keep(EscapedQuote, mode)
          _ -> lexer.NoMatch
        }
      }),
      lexer.keep(fn(lexeme, _grapheme) {
        case lexeme {
          "" -> {
            Error(Nil)
          }
          _ -> Ok(Text(lexeme))
        }
      }),
    ])

  let tokens_result = lexer.run(str, l)

  // io.println("Lexer tokens: " <> string.inspect(tokens_result))

  case tokens_result {
    Ok(tokens) -> {
      nibble.run(tokens, parser([]))
      |> result.unwrap([Literal(str)])
    }
    Error(_) -> {
      // io.println("Error: " <> string.inspect(error))
      []
    }
  }
}

fn parser(tokens: List(Token)) {
  nibble.one_of([
    nibble.one_of([field(), literal(), escaped_quote(), quoted()])
      |> nibble.then(fn(token) { parser([token, ..tokens]) }),
    nibble.succeed(finalize(tokens)),
  ])
}

// 
// 
// 
// -- parser
// 
// 
// field : Parser Token
// field =
//     Parser.chompIf Char.isAlpha
//         |> Parser.getChompedString
//         |> Parser.andThen fieldRepeats

fn field() {
  use alpha <- nibble.do(nibble.take_if("Expecting an Alpha token", is_alpha))

  let assert Alpha(char) = alpha

  use rest <- nibble.do(nibble.take_while(is_specific_alpha(char)))

  nibble.return(Field(char, list.length(rest) + 1))
}

// 
// 
// fieldRepeats : String -> Parser Token
// fieldRepeats str =
//     case String.toList str of
//         [ char ] ->
//             Parser.succeed (\x y -> Field char (1 + (y - x)))
//                 |= Parser.getOffset
//                 |. Parser.chompWhile ((==) char)
//                 |= Parser.getOffset
// 
//         _ ->
//             Parser.problem "expected exactly one char"
// 
// 
// escapedQuote : Parser Token
// escapedQuote =
//     Parser.succeed (Literal "'")
//         |. Parser.token "''"
fn escaped_quote() {
  nibble.token(EscapedQuote)
  |> nibble.then(fn(_) { nibble.succeed(Literal("'")) })
}

// 
// 
// literal : Parser Token
// literal =
//     Parser.succeed ()
//         |. Parser.chompIf isLiteralChar
//         |. Parser.chompWhile isLiteralChar
//         |> Parser.getChompedString
//         |> Parser.map Literal
fn literal() {
  use text <- nibble.do(nibble.take_if("Expecting an Text token", is_text))
  use rest <- nibble.do(nibble.take_while(is_text))

  let joined =
    list.map([text, ..rest], fn(entry) {
      let assert Text(text) = entry
      text
    })
    |> string.concat()

  nibble.return(Literal(joined))
}

// 
// 
// isLiteralChar : Char -> Bool
// isLiteralChar char =
//     char /= '\'' && not (Char.isAlpha char)
// 
// 
// quoted : Parser Token
// quoted =
//     Parser.succeed Literal
//         |. Parser.chompIf ((==) '\'')
//         |= quotedHelp ""
//         |. Parser.oneOf
//             [ Parser.chompIf ((==) '\'')
//             , Parser.end -- lenient parse for unclosed quotes
//             ]
fn quoted() {
  use _ <- nibble.do(nibble.take_if("Expecting an Quote", is_quote))

  use text <- nibble.do(quoted_help(""))

  use _ <- nibble.do(
    nibble.one_of([
      nibble.take_if("Expecting an Quote", is_quote)
        |> nibble.map(fn(_) { Nil }),
      nibble.eof(),
    ]),
  )

  nibble.return(Literal(text))
}

// 
// 
// quotedHelp : String -> Parser String
// quotedHelp result =
//     Parser.oneOf
//         [ Parser.succeed ()
//             |. Parser.chompIf ((/=) '\'')
//             |. Parser.chompWhile ((/=) '\'')
//             |> Parser.getChompedString
//             |> Parser.andThen (\str -> quotedHelp (result ++ str))
//         , Parser.token "''"
//             |> Parser.andThen (\_ -> quotedHelp (result ++ "'"))
//         , Parser.succeed result
//         ]

fn quoted_help(result: String) -> nibble.Parser(String, LexerToken, c) {
  nibble.one_of([
    {
      use tokens <- nibble.do(
        nibble.take_while1("Expecting a non-Quote", fn(token) {
          !is_quote(token)
        }),
      )

      let str = extract_content(tokens)

      quoted_help(result <> str)
    },
    nibble.token(EscapedQuote)
      |> nibble.then(fn(_) { quoted_help(result <> "'") }),
    nibble.succeed(result),
  ])
}

// 
// 
// patternHelp : List Token -> Parser (List Token)
// patternHelp tokens =
//     Parser.oneOf
//         [ Parser.oneOf
//             [ field
//             , literal
//             , escapedQuote
//             , quoted
//             ]
//             |> Parser.andThen (\token -> patternHelp (token :: tokens))
//         , Parser.lazy
//             (\_ -> Parser.succeed (finalize tokens))
//         ]
// 
// 
// {-| Reverse list and combine consecutive Literals.
// -}
// finalize : List Token -> List Token
// finalize =
//     List.foldl
//         (\token tokens ->
//             case ( token, tokens ) of
//                 ( Literal x, (Literal y) :: rest ) ->
//                     Literal (x ++ y) :: rest
// 
//                 _ ->
//                     token :: tokens
//         )
//         []

fn finalize(tokens: List(Token)) -> List(Token) {
  list.fold(tokens, [], fn(tokens, token) {
    case token, tokens {
      Literal(x), [Literal(y), ..rest] -> {
        [Literal(x <> y), ..rest]
      }
      _, _ -> {
        [token, ..tokens]
      }
    }
  })
}
//         
