import gleam/list
import gleeunit/should

import rada/date/pattern.{Field, Literal}

// test_fromString : Test
// test_fromString =
//     let
//         toTest : ( String, Pattern ) -> Test
//         toTest ( input, expected ) =
//             test input <| \() -> Pattern.fromString input |> equal expected
//     in
//     describe "fromString" <|
//         List.map
//             toTest
//             [ ( "aaa", [ f 'a' 3 ] )
//             , ( "abbccc", [ f 'a' 1, f 'b' 2, f 'c' 3 ] )
//             , ( "''dddd''eeeee", [ l "'", f 'd' 4, l "'", f 'e' 5 ] )
//             , ( "aa-bb-cc//#!0.dd", [ f 'a' 2, l "-", f 'b' 2, l "-", f 'c' 2, l "//#!0.", f 'd' 2 ] )
//             , ( "a'''bbb'", [ f 'a' 1, l "'bbb" ] )
//             , ( "a'''bbb", [ f 'a' 1, l "'bbb" ] )
//             , ( "'o''clock'", [ l "o'clock" ] )
//             , ( "'''aaa ' '' - ''' '' '' '..' a '", [ l "'aaa  ' - ' ' ' .. a " ] )
//             ]
pub fn from_string_test() {
  list.each(
    [
      #("aaa", [Field("a", 3)]),
      #("abbccc", [Field("a", 1), Field("b", 2), Field("c", 3)]),
      #("''dddd''eeeee", [
        Literal("'"),
        Field("d", 4),
        Literal("'"),
        Field("e", 5),
      ]),
      #("aa-bb-cc//#!0.dd", [
        Field("a", 2),
        Literal("-"),
        Field("b", 2),
        Literal("-"),
        Field("c", 2),
        Literal("//#!0."),
        Field("d", 2),
      ]),
      #("a'''bbb'", [Field("a", 1), Literal("'bbb")]),
      #("a'''bbb", [Field("a", 1), Literal("'bbb")]),
      #("'o''clock'", [Literal("o'clock")]),
      #("'''aaa ' '' - ''' '' '' '..' a '", [Literal("'aaa  ' - ' ' ' .. a ")]),
    ],
    fn(tuple) { pattern.from_string(tuple.0) |> should.equal(tuple.1) },
  )
}

pub fn from_string_1_test() {
  pattern.from_string("aaa")
  |> should.equal([Field("a", 3)])
}

pub fn from_string_2_test() {
  pattern.from_string("abbccc")
  |> should.equal([Field("a", 1), Field("b", 2), Field("c", 3)])
}
