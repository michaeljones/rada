export function get_year_month_day() {
  let date = new Date();
  return [date.getFullYear(), date.getMonth() + 1, date.getDate()]
}
