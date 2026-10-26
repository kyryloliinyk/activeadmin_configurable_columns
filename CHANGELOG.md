# Changelog

## 2.0.0 (2026-10-26)

### Added

- Drag-and-drop column reordering in the "Columns" picker and on the "Table
  columns" page, with arrow-key reordering on the focused handle and touch
  support. The index table renders the visible columns in the admin's order.
- "Reset to defaults" button: forgets the admin's choice for a table.
- Columns added to a declaration after an admin saved an order appear next to
  their declared neighbour, and are visible when declared `default: true`.

### Changed (breaking)

- New migration adding a nullable `column_order` column to the preferences
  table. Rows saved before it keep declaration order until saved again.
- Preference store contract: `visible_column_keys(admin, resource_key)` became
  `fetch(admin, resource_key)`, returning a `SavedSelection` (or nil);
  `store` takes `visible_keys:` and `order_keys:` instead of `keys:`; a new
  `clear(admin:, resource_key:)` is required.
- `ActiveadminConfigurableColumns.visible_columns` is replaced by
  `selection_for(registry, admin)`.
- The picker form no longer sends an empty `visible_columns[]` placeholder; a
  missing parameter falls back to the defaults as before.

## 1.0.0 (2026-09-30)

Initial release.

- `configurable_columns` DSL to declare the columns an admin may pick from.
- `configurable_columns` index-table renderer that shows the columns the
  current admin chose, falling back to the declared defaults.
- "Columns" picker in the sidebar of every configurable index.
- "Table columns" admin page to review and change every table at once.
- Per-admin persistence in the `activeadmin_configurable_columns_preferences`
  table, with a pluggable preference store.
