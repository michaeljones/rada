# rada

This package provides a simple `Date` type for working with dates without times or zones.

## Origins

This is a port of the [justinmimbs/date](https://package.elm-lang.org/packages/justinmimbs/date/latest) Elm library.
Done with the kind permission of the author. The API has been adjusted to match norms of the Gleam language in places.

## Installation

```sh
gleam add rada
```

## Usage

```gleam
import gleam/io
import gleam/list

import rada/date

pub fn main() {
  let today = date.today()
  let one_week_later = date.add(today, 1, date.Weeks)

  date.range(date.Day, 1, today, one_week_later)
  |> list.each(fn(entry)
    date.format(entry, "EEEE, d MMMM y") |> io.println
  })
}
```

Documentation can be found at <https://hexdocs.pm/rada>.

