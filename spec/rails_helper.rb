ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require_relative 'dummy/config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

# The dummy app keeps its whole schema in an in-memory sqlite database: the
# tables its models need are created here, and the preferences table comes from
# the gem's own migration, so the migration is exercised on every run.
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :admin_users, force: true do |t|
    t.string :email
    t.timestamps
  end

  create_table :widgets, force: true do |t|
    t.string :title
    t.string :code
    t.timestamps
  end

  create_table :gadgets, force: true do |t|
    t.string :name
    t.string :serial
    t.timestamps
  end
end

ActiveRecord::MigrationContext.new(
  ActiveadminConfigurableColumns::Engine.root.join('db', 'migrate').to_s
).migrate

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
