
-module(date_ffi).

-export([
    get_year_month_day/0
]).

get_year_month_day() ->
    date().
