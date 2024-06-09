import gleam/int
import gleam/string

import date

// fr : Date.Language
// fr =
//     { monthName = fr_monthName
//     , monthNameShort = fr_monthNameShort
//     , weekdayName = fr_weekdayName
//     , weekdayNameShort = fr_weekdayName >> String.left 3
//     , dayWithSuffix = fr_dayWithSuffix
//     }
pub fn language_fr() {
  date.Language(
    month_name: fr_month_name,
    month_name_short: fr_month_name_short,
    weekday_name: fr_weekday_name,
    weekday_name_short: fn(weekday) {
      weekday |> fr_weekday_name |> string.slice(at_index: 0, length: 3)
    },
    day_with_suffix: fr_day_with_suffix,
  )
}

// fr_monthName : Month -> String
// fr_monthName month =
//     case month of
//         Jan ->
//             "janvier"

//         Feb ->
//             "février"

//         Mar ->
//             "mars"

//         Apr ->
//             "avril"

//         May ->
//             "mai"

//         Jun ->
//             "juin"

//         Jul ->
//             "juillet"

//         Aug ->
//             "août"

//         Sep ->
//             "septembre"

//         Oct ->
//             "octobre"

//         Nov ->
//             "novembre"

//         Dec ->
//             "décembre"
fn fr_month_name(month: date.Month) {
  case month {
    date.Jan -> "janvier"
    date.Feb -> "février"
    date.Mar -> "mars"
    date.Apr -> "avril"
    date.May -> "mai"
    date.Jun -> "juin"
    date.Jul -> "juillet"
    date.Aug -> "août"
    date.Sep -> "septembre"
    date.Oct -> "octobre"
    date.Nov -> "novembre"
    date.Dec -> "décembre"
  }
}

// fr_monthNameShort : Month -> String
// fr_monthNameShort month =
//     case month of
//         Jan ->
//             "janv."

//         Feb ->
//             "févr."

//         Mar ->
//             "mars"

//         Apr ->
//             "avr."

//         May ->
//             "mai"

//         Jun ->
//             "juin"

//         Jul ->
//             "juill."

//         Aug ->
//             "août"

//         Sep ->
//             "sept."

//         Oct ->
//             "oct."

//         Nov ->
//             "nov."

//         Dec ->
//             "déc."
fn fr_month_name_short(month: date.Month) {
  case month {
    date.Jan -> "janv."
    date.Feb -> "févr."
    date.Mar -> "mars"
    date.Apr -> "avr."
    date.May -> "mai"
    date.Jun -> "juin"
    date.Jul -> "juill."
    date.Aug -> "août"
    date.Sep -> "sept."
    date.Oct -> "oct."
    date.Nov -> "nov."
    date.Dec -> "déc."
  }
}

// fr_weekdayName : Weekday -> String
// fr_weekdayName weekday =
//     case weekday of
//         Mon ->
//             "lundi"

//         Tue ->
//             "mardi"

//         Wed ->
//             "mercredi"

//         Thu ->
//             "jeudi"

//         Fri ->
//             "vendredi"

//         Sat ->
//             "samedi"

//         Sun ->
//             "dimanche"
fn fr_weekday_name(weekday: date.Weekday) {
  case weekday {
    date.Mon -> "lundi"
    date.Tue -> "mardi"
    date.Wed -> "mercredi"
    date.Thu -> "jeudi"
    date.Fri -> "vendredi"
    date.Sat -> "samedi"
    date.Sun -> "dimanche"
  }
}

// fr_dayWithSuffix : Int -> String
// fr_dayWithSuffix day =
//     if day == 1 then
//         "1er"

//     else
//         String.fromInt day

fn fr_day_with_suffix(day: Int) {
  case day {
    1 -> "1er"
    _ -> int.to_string(day)
  }
}
