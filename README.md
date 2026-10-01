# activeadmin_configurable_columns

Per-admin configurable index table columns for [ActiveAdmin](https://activeadmin.info) 4.

ActiveAdmin has no built-in way to let each admin choose which columns of an
index table they see. This gem adds one, built on ActiveAdmin's own extension
points:

- a `configurable_columns do ... end` DSL declares the columns an admin may pick from;
- `configurable_columns` inside an `index` block renders the ones the current admin chose;
- a "Columns" picker appears in the sidebar of every configurable index;
- a "Table columns" admin page lets an admin review and change every table at once;
- each admin's choice is stored in the database, per admin and per table.

## Requirements

- Ruby >= 3.1
- Rails >= 7.1
- ActiveAdmin 4.0 (beta15 or later)

## Installation

Add the gem to your Gemfile:

```ruby
gem 'activeadmin_configurable_columns'
```

Install the migration and migrate:

```sh
bin/rails activeadmin_configurable_columns:install:migrations
bin/rails db:migrate
```

This creates the `activeadmin_configurable_columns_preferences` table. The
`admin` reference is polymorphic with a string id, so it works with any
current-user model and any primary key type (integer, uuid, ...).

## Usage

Declare the available columns in an ActiveAdmin registration, and render them
in the index:

```ruby
ActiveAdmin.register Product do
  configurable_columns do
    column :brand
    column :sku, label: 'SKU'
    column(:qty, sortable: 'stock_items_quantity') { |product| product.total_quantity }
    column :notes, default: false        # available, but hidden until picked
  end

  index do
    selectable_column
    configurable_columns
    actions
  end
end
```

`column` mirrors the arguments of ActiveAdmin's own `column`, so a declaration
reads the same as the index DSL it replaces:

| Argument | Meaning |
| --- | --- |
| `key` | Identifies the column in the picker and in stored preferences. Also the rendered attribute unless `attribute:` or a block says otherwise. |
| `label:` | Column header and checkbox label. Defaults to the model's `human_attribute_name`. |
| `default:` | Whether the column is visible for admins who never picked anything. Defaults to `true`. |
| `attribute:` | The attribute to render when it differs from the key. |
| a block | Renders the cell. The block is evaluated against the index table, so view helpers work, exactly as in a regular `index` column. |
| anything else | Passed through to ActiveAdmin's `column` (e.g. `sortable:`, `class:`). |

Every resource that declares `configurable_columns` gets a "Columns" sidebar
section on its index, and a card on the "Table columns" page. Selections are
saved per admin; unknown or stale keys are dropped on read and write, and an
empty selection falls back to the declared defaults, so an admin can never end
up with an empty table.

## Configuration

All settings are optional. In `config/initializers/activeadmin_configurable_columns.rb`:

```ruby
ActiveadminConfigurableColumns.configure do |config|
  # Options for the "Table columns" page's `menu` call, or false to keep the
  # page out of the navigation. Default: a translated label, top level.
  config.menu = { parent: 'Settings', priority: 0 }

  # Priority of the "Columns" sidebar section. ActiveAdmin's filters sidebar
  # uses 10; the default (20) renders right below it.
  config.sidebar_priority = 20

  # Where selections are read from and written to. Any object answering
  #   visible_column_keys(admin, resource_key) -> [Symbol] | nil  (nil = never saved)
  #   store(admin:, resource_key:, keys:)
  # can be plugged in. Default: the bundled Preference model.
  config.preference_store = MyOwnStore
end
```

The current admin is whatever ActiveAdmin's `current_active_admin_user`
returns, so the gem follows your `config.current_user_method` setting.

## Translations

The gem ships English strings under standard ActiveAdmin keys; override them
per locale in your application:

```yaml
en:
  active_admin:
    sidebars:
      columns: "Columns"
    table_columns:
      title: "Table columns"
      save: "Save columns"
      saved: "Columns saved"
      empty: "No table has configurable columns yet."
      unknown_resource: "Unknown table"
```

Column checkbox labels come from `human_attribute_name`, so your existing
Active Record attribute translations apply.

## Tailwind CSS

ActiveAdmin 4 builds its stylesheet with Tailwind, which only emits classes it
finds in scanned sources. Add the gem's views to your Tailwind entrypoint (or
config) so the picker and the "Table columns" page keep their layout:

```css
@source "<path to the installed gem>/app/views/**/*.{arb,erb,html,rb}";
```

If a rake task generates your ActiveAdmin Tailwind entrypoint, resolve the path
with `Gem.loaded_specs['activeadmin_configurable_columns'].full_gem_path`.

## How it works

- `ActiveadminConfigurableColumns::Dsl` is mixed into `ActiveAdmin::ResourceDSL`;
  `configurable_columns do ... end` builds a `Registry` of `Column`s, stores it on
  the resource, and adds the sidebar section.
- `ActiveadminConfigurableColumns::TableRenderer` is mixed into
  `ActiveAdmin::Views::IndexAsTable::IndexTableFor`; `configurable_columns` inside
  `index` looks up the current admin's saved keys and emits the matching columns.
- The "Table columns" page is a regular `ActiveAdmin.register_page`, loaded
  through ActiveAdmin's own load paths; its update action also serves the
  sidebar forms.
- Rendering an index whose resource never declared its columns raises
  `ActiveadminConfigurableColumns::NotDeclared` with a hint, rather than an
  empty table.

## Development

```sh
bundle install
bundle exec rspec
```

The test suite is standalone: it boots a dummy Rails application
(`spec/dummy`) with an in-memory sqlite database and a real ActiveAdmin
registration, and exercises the gem's migration on every run.

## License

The gem is available as open source under the terms of the
[MIT License](LICENSE.txt).
