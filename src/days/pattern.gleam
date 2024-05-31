import gleam/io
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
      lexer.token("''", EscapedQuote),
      lexer.token("'", Quote),
      lexer.keep(fn(lexeme, _grapheme) {
        case lexeme {
          "" -> {
            Error(Nil)
          }
          _ -> Ok(Text(lexeme))
        }
      }),
      // lexer.custom(fn(mode, lexeme, grapheme) {
    //   case lexeme {
    //     "" -> lexer.Skip
    //     value -> {
    //       case string.last(value) {
    //         Ok(last) if last == grapheme -> {
    //           lexer.Skip
    //         }
    //         Ok(last) -> {
    //           lexer.Keep(Field(last, string.length(lexeme)), mode)
    //         }
    //         Error(Nil) -> {
    //           lexer.Skip
    //         }
    //       }
    //     }
    //   }
    // }// case lexeme {
    //   "" -> Ok(grapheme)
    //   value -> {
    //     case string.last(value) == Ok(grapheme) {
    //       True -> Ok(value <> grapheme)
    //       False -> Ok(value)
    //     }
    //   }
    // }
    // Error(Nil)
    // ),
    ])

  let tokens_result = lexer.run(str, l)

  io.println("Lexer tokens: " <> string.inspect(tokens_result))

  case tokens_result {
    Ok(tokens) -> {
      nibble.run(tokens, parser())
      |> result.unwrap([Literal(str)])
    }
    Error(_error) -> {
      []
    }
  }
}

fn parser() {
  nibble.one_of([field()])
  //, literal, escaped_quote, quoted])
  nibble.return([])
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
  nibble.take_if("Expecting an Alpha token", fn(token) {
    case token {
      Alpha(_) -> True
      _ -> False
    }
  })
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
  nibble.succeed(Nil)
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
//         
