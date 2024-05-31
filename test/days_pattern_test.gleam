import gleeunit/should

import days/pattern.{Field}

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

pub fn from_string_1_test() {
  pattern.from_string("aaa")
  |> should.equal([Field("a", 3)])
}

pub fn from_string_2_test() {
  pattern.from_string("abbccc")
  |> should.equal([Field("a", 1), Field("b", 2), Field("c", 3)])
}
