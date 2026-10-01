RSpec.describe ActiveadminConfigurableColumns::TableRenderer do
  let(:admin) { :admin_alice }
  let(:helpers) { Fakes::Helpers.new(admin) }
  let(:config) { Fakes::ResourceConfig.new(route_key: 'widgets') }
  let(:table) do
    Class.new(Fakes::Table) { include ActiveadminConfigurableColumns::TableRenderer }
      .new(config: config, helpers: helpers)
  end

  before do
    config.column_registry = ActiveadminConfigurableColumns::Registry.build('widgets') do
      column :name
      column :code
      column :notes, default: false
    end
  end

  it 'renders the declared defaults when the admin never saved anything' do
    ActiveadminConfigurableColumns.preference_store = Fakes::Store.new

    table.configurable_columns

    expect(table.titles).to eq(%i[name code])
  end

  it 'renders the columns the current admin saved' do
    ActiveadminConfigurableColumns.preference_store =
      Fakes::Store.new(admin => { 'widgets' => %i[notes name] })

    table.configurable_columns

    expect(table.titles).to eq(%i[name notes])
  end

  it 'ignores what other admins saved' do
    ActiveadminConfigurableColumns.preference_store =
      Fakes::Store.new(admin_bob: { 'widgets' => %i[notes] })

    table.configurable_columns

    expect(table.titles).to eq(%i[name code])
  end

  it 'explains itself when the resource never declared its columns' do
    config.column_registry = nil

    expect { table.configurable_columns }
      .to raise_error(ActiveadminConfigurableColumns::NotDeclared, /widgets.*configurable_columns do/m)
  end
end
