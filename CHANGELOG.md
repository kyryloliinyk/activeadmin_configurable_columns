# Changelog

## 1.0.0 (2026-09-30)

Initial release.

- `configurable_columns` DSL to declare the columns an admin may pick from.
- `configurable_columns` index-table renderer that shows the columns the
  current admin chose, falling back to the declared defaults.
- "Columns" picker in the sidebar of every configurable index.
- "Table columns" admin page to review and change every table at once.
- Per-admin persistence in the `activeadmin_configurable_columns_preferences`
  table, with a pluggable preference store.
