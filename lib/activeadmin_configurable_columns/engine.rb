module ActiveadminConfigurableColumns
  # Wires the library into the host application: autoloads the Preference model,
  # adds the gem's views and locales, and teaches ActiveAdmin the DSL before the
  # application's app/admin files load (ActiveAdmin loads them lazily, long after
  # the initializers ran).
  class Engine < ::Rails::Engine
    engine_name 'activeadmin_configurable_columns'

    initializer 'activeadmin_configurable_columns.active_admin' do
      ActiveAdmin::Resource.include ResourceExtension
      ActiveAdmin::ResourceDSL.include Dsl
      ActiveAdmin::Views::IndexAsTable::IndexTableFor.include TableRenderer

      # The "Table columns" page is a regular ActiveAdmin page registration, not
      # a constant, so it lives outside the autoload paths and loads through
      # ActiveAdmin's own load paths, together with the application's app/admin.
      ActiveAdmin.application.load_paths <<
        Engine.root.join('lib', 'activeadmin_configurable_columns', 'admin').to_s
    end
  end
end
