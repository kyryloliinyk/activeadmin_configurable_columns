RSpec.describe ActiveadminConfigurableColumns::ResourceExtension do
  subject(:config) { Fakes::ResourceConfig.new }

  it 'has no registry until columns are declared' do
    expect(config.column_registry).to be_nil
    expect(config.configurable_columns?).to be(false)
  end

  it 'reports itself configurable once a registry is assigned' do
    config.column_registry = ActiveadminConfigurableColumns::Registry.build('widgets') { column :name }

    expect(config.configurable_columns?).to be(true)
  end
end
