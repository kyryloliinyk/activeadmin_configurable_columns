require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'propshaft'
require 'importmap-rails'
require 'activeadmin_configurable_columns'

# A minimal host application for the gem's own test suite: propshaft +
# importmap-rails + sqlite, mirroring a typical ActiveAdmin 4 installation.
module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.root = File.expand_path('..', __dir__)
    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = 'dummy-secret-key-base-for-the-test-suite-only'
    config.logger = ActiveSupport::Logger.new(File::NULL)
    config.active_record.dump_schema_after_migration = false
  end
end
