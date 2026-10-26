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

    # The picker script is pinned into ActiveAdmin's own importmap, the one its
    # layout renders, mirroring how ActiveAdmin ships its JavaScript.
    initializer 'activeadmin_configurable_columns.importmap', after: 'active_admin.importmap' do |app|
      next unless app.config.respond_to?(:importmap)

      ActiveAdmin.importmap.draw(Engine.root.join('config', 'importmap.rb'))

      script_paths = [Engine.root.join('app', 'javascript'), Engine.root.join('vendor', 'javascript')]
      app.config.assets.paths.concat(script_paths) if app.config.respond_to?(:assets)

      # ActiveAdmin's sweeper watches only its own scripts; replace it with one
      # that watches ours too, so edits are picked up without a restart.
      if app.config.importmap.sweep_cache
        ActiveAdmin.importmap.cache_sweeper(
          watches: [ActiveAdmin::Engine.root.join('app', 'javascript'), Engine.root.join('app', 'javascript')]
        )
      end
    end
  end
end
