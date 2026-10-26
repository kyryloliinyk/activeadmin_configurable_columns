# Stand-ins for the ActiveAdmin objects the library talks to, so its unit specs
# never depend on a real model, table or admin registration.
module Fakes
  # Stands in for ActiveAdmin::Views::IndexAsTable::IndexTableFor: records what was
  # emitted instead of building HTML.
  class Table
    Emitted = Struct.new(:args, :block, keyword_init: true)

    attr_reader :emitted, :active_admin_config, :helpers

    def initialize(config: nil, helpers: nil)
      @emitted = []
      @active_admin_config = config
      @helpers = helpers
    end

    def column(*args, &block)
      @emitted << Emitted.new(args: args, block: block)
    end

    def titles = emitted.map { |column| column.args.first }

    def options = emitted.map { |column| column.args.last }

    # A view helper reachable from the table, as Arbre reaches the real helpers.
    def shout(value) = "shout:#{value}"
  end

  # Stands in for ActiveAdmin::Resource, including the real extension under test.
  class ResourceConfig
    include ActiveadminConfigurableColumns::ResourceExtension

    ResourceName = Struct.new(:route_key)

    attr_reader :sidebar_sections, :resource_name, :resource_class

    def initialize(route_key: 'widgets', resource_class: nil)
      @resource_name = ResourceName.new(route_key)
      @sidebar_sections = []
      @resource_class = resource_class
    end
  end

  # Stands in for ActiveAdmin::ResourceDSL, which is where the declaration DSL lands.
  class ResourceDsl
    include ActiveadminConfigurableColumns::Dsl

    attr_reader :config

    def initialize(config) = @config = config
  end

  # Stands in for the preference store: nil means "this admin never saved
  # anything". Records writes instead of persisting them.
  class Store
    attr_reader :stored, :cleared

    def initialize(saved = {})
      @saved = saved
      @stored = []
      @cleared = []
    end

    def fetch(admin, resource_key) = @saved.dig(admin, resource_key)

    def store(**selection) = @stored << selection

    def clear(**selection) = @cleared << selection
  end

  def self.saved(visible, order = nil)
    ActiveadminConfigurableColumns::SavedSelection.new(visible_keys: visible, order_keys: order)
  end

  # Stands in for a model class that provides translated attribute names.
  class TranslatedModel
    def self.human_attribute_name(attribute, default: nil) = "translated:#{attribute}"
  end

  # Stands in for the view context a sidebar section block is evaluated against.
  class SidebarView
    attr_reader :rendered, :active_admin_config

    def initialize(config) = @active_admin_config = config

    def render(*args) = @rendered = args
  end

  # Stands in for the view context a table reaches through `helpers`.
  Helpers = Struct.new(:current_active_admin_user)

  # Minimal ActiveAdmin namespace: `resources` only has to be enumerable, and
  # `route_prefix` mirrors ActiveAdmin::Namespace (nil for the root namespace).
  Namespace = Struct.new(:resources, :route_prefix)
end

RSpec.configure do |config|
  config.after do
    ActiveadminConfigurableColumns.preference_store = nil
    ActiveadminConfigurableColumns.sidebar_priority = nil
    ActiveadminConfigurableColumns.menu = nil
  end
end
