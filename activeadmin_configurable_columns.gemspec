require_relative 'lib/activeadmin_configurable_columns/version'

Gem::Specification.new do |spec|
  spec.name = 'activeadmin_configurable_columns'
  spec.version = ActiveadminConfigurableColumns::VERSION
  spec.authors = ['Kyryl Oliinyk']
  spec.email = ['kyryloliinyk@gmail.com']
  spec.homepage = 'https://github.com/kyryloliinyk/activeadmin_configurable_columns'
  spec.metadata = {
  'source_code_uri' => 'https://github.com/kyryloliinyk/activeadmin_configurable_columns',
  'changelog_uri' => 'https://github.com/kyryloliinyk/activeadmin_configurable_columns/blob/main/CHANGELOG.md',
  'bug_tracker_uri' => 'https://github.com/kyryloliinyk/activeadmin_configurable_columns/issues',
  'rubygems_mfa_required' => 'true'

}

  spec.summary = 'Per-admin configurable index table columns for ActiveAdmin 4.'
  spec.description = 'Lets every admin choose which columns of an ActiveAdmin index table they see. ' \
                     'Adds a `configurable_columns` DSL to declare the available columns, renders a ' \
                     '"Columns" picker in the index sidebar and on a central "Table columns" page, ' \
                     'and stores each admin\'s choice in the database.'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1'

  spec.files = Dir['{app,config,db,lib}/**/*', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activeadmin', '>= 4.0.0.beta15', '< 4.1'
  spec.add_dependency 'activerecord', '>= 7.1'
  spec.add_dependency 'railties', '>= 7.1'
end
