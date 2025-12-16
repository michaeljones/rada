# Changelog

## 0.6.0 - 2025-12-16

### Added

- `weekday_to_number` function for converting from a Weekday value to an integer between 1 and 7 with 1 corresponding
  to Monday.

## 0.5.0 - 2025-01-12

### Changed

- Updated for gleam stdlib changes.

## 0.4.0 - 2024-07-09

### Added

- German and Spanish `Language` helpers to use with `format_with_language`. We have yet to establish full conventions
  for these so formatting might change slightly in future versions.

### Changed

- Changed internal logic to use few Result producing operations and unwraps.

### Fixed

- Corrected some typos in the logic of the Italian Language helper.

## 0.3.0 - 2024-07-07

### Added

- Italian `Language` helper to use with `format_with_language`. We have yet to establish full conventions
  for these so formatting might change slightly in future versions.

## 0.2.0 - 2024-06-30

### Fixed

- Argument ordering in documentation code examples.

## 0.1.0 - 2024-06-30

Initial release.
