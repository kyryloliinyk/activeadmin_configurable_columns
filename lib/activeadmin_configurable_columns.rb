require 'active_admin'

require_relative 'activeadmin_configurable_columns/version'

# Per-admin index table columns for ActiveAdmin.
#
# ActiveAdmin has no built-in way to let each admin choose which columns of an
# index table they see. This gem adds one, built on ActiveAdmin's own extension
# points:
#
#   * ResourceDSL   -- `configurable_columns` declares the available columns
#   * IndexTableFor -- `configurable_columns` renders the chosen ones
#   * SidebarSection -- the picker next to every configurable index table
#
# The choice is stored per admin by the preference store, which defaults to the
# bundled ActiveadminConfigurableColumns::Preference model.
module ActiveadminConfigurableColumns
  # ActiveAdmin renders the filters sidebar section with priority 10; the
  # default puts the "Columns" picker right below it.
  DEFAULT_SIDEBAR_PRIORITY = 20

  # Raised when an index renders `configurable_columns` without a matching
  # `configurable_columns do ... end` declaration.
  class NotDeclared < StandardError
    def initialize(resource_name)
      super("#{resource_name} renders configurable_columns but never declares them. " \
            'Add a `configurable_columns do ... end` block to its ActiveAdmin registration.')
    end
  end

  class << self
    def configure
      yield self
    end

    # Where saved selections live. Any object answering
    #
    #   visible_column_keys(admin, resource_key) -> [Symbol] | nil   (nil = never saved)
    #   store(admin:, resource_key:, keys:)                          (persists a selection)
    #
    # can be plugged in; the default is the bundled Preference model. Assigning
    # nil restores that default.
    attr_writer :preference_store

    def preference_store = @preference_store || Preference

    # Priority of the "Columns" sidebar section. Assigning nil restores the default.
    attr_writer :sidebar_priority

    def sidebar_priority = @sidebar_priority || DEFAULT_SIDEBAR_PRIORITY

    # Options passed to `menu` for the "Table columns" page (assign false to keep
    # the page out of the menu entirely). Assigning nil restores the default.
    attr_writer :menu

    def menu
      return @menu unless @menu.nil?

      { label: proc { I18n.t('active_admin.table_columns.title') } }
    end

    # The columns the given admin sees for this resource.
    def visible_columns(registry, admin)
      saved = preference_store.visible_column_keys(admin, registry.resource_key)

      registry.columns_for(saved || registry.default_keys)
    end

    # Every resource of the namespace that declares configurable columns.
    def resources(namespace)
      namespace.resources.select do |resource|
        resource.respond_to?(:configurable_columns?) && resource.configurable_columns?
      end
    end

    def resource_for(namespace, resource_key)
      resources(namespace).find { |resource| resource.column_registry.resource_key == resource_key.to_s }
    end

    # Name of a route helper for the "Table columns" page in the given namespace:
    #
    #   route_name(admin_namespace)           # => 'admin_table_columns_path'
    #   route_name(admin_namespace, :update)  # => 'admin_table_columns_update_path'
    #
    # The namespace prefix is looked up rather than hardcoded, so the page works
    # in any ActiveAdmin namespace, including the root one.
    def route_name(namespace, action = nil)
      [namespace.route_prefix, 'table_columns', action, 'path'].compact.join('_')
    end
  end
end

require_relative 'activeadmin_configurable_columns/column'
require_relative 'activeadmin_configurable_columns/registry'
require_relative 'activeadmin_configurable_columns/dsl'
require_relative 'activeadmin_configurable_columns/resource_extension'
require_relative 'activeadmin_configurable_columns/table_renderer'
require_relative 'activeadmin_configurable_columns/engine'
