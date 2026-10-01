# End-to-end coverage of the library inside a real ActiveAdmin registration,
# running against the dummy application's Widget resource.
RSpec.describe 'Configurable table columns' do
  let(:admin) { AdminUser.create!(email: 'alice@example.com') }
  let(:resource_key) { 'widgets' }
  let(:resource) do
    ActiveadminConfigurableColumns.resource_for(ActiveAdmin.application.namespaces[:admin], resource_key)
  end
  let(:registry) { resource.column_registry }
  let(:preferences) { ActiveadminConfigurableColumns::Preference }

  # ActiveAdmin stamps every table header and cell with the column it renders.
  def rendered_columns = response.body.scan(/data-column="([^"]+)"/).flatten.uniq.map(&:to_sym)

  before do
    sign_in admin
    Widget.create!(title: 'Widget one', code: 'W1')
  end

  describe 'the index table' do
    it 'renders the declared defaults for an admin who never chose' do
      get admin_widgets_path

      expect(response).to have_http_status(:ok)
      expect(rendered_columns).to include(*registry.default_keys)
      expect(rendered_columns).not_to include(:code)
    end

    it 'renders the columns the admin saved' do
      preferences.store(admin: admin, resource_key: resource_key, keys: %i[title code])

      get admin_widgets_path

      expect(rendered_columns).to include(:title, :code)
      expect(rendered_columns).not_to include(:linked)
    end

    it 'is unaffected by what another admin saved' do
      other = AdminUser.create!(email: 'bob@example.com')
      preferences.store(admin: other, resource_key: resource_key, keys: %i[code])

      get admin_widgets_path

      expect(rendered_columns).to include(*registry.default_keys)
    end

    it 'runs a column block against the view, so view helpers work' do
      get admin_widgets_path

      expect(response.body).to include('<a href="#">Widget one</a>')
    end

    it 'renders the columns picker in the sidebar' do
      get admin_widgets_path

      expect(response.body).to include(I18n.t('active_admin.sidebars.columns'))
      expect(response.body).to include('name="visible_columns[]" id="widgets_column_title"')
    end
  end

  describe 'the table columns page' do
    it 'lists every configurable table' do
      get admin_table_columns_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(resource.plural_resource_label)
      expect(response.body).to include("name=\"resource_key\" value=\"#{resource_key}\"")
    end
  end

  describe 'saving a selection' do
    it 'stores it for the current admin' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title code] }

      expect(response).to have_http_status(:see_other)
      expect(preferences.visible_column_keys(admin, resource_key)).to eq(%i[title code])
    end

    it 'ignores keys the resource never declared' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title made_up] }

      expect(preferences.visible_column_keys(admin, resource_key)).to eq(%i[title])
    end

    it 'stores the defaults when nothing is selected' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: [''] }

      expect(preferences.visible_column_keys(admin, resource_key)).to eq(registry.default_keys)
    end

    it 'refuses an unknown table' do
      patch admin_table_columns_update_path,
            params: { resource_key: 'made_up', visible_columns: %w[title] }

      expect(response).to have_http_status(:see_other)
      expect(preferences.count).to eq(0)
    end

    it 'goes through the pluggable preference store' do
      store = Class.new do
        def self.calls = @calls ||= []
        def self.visible_column_keys(_admin, _resource_key) = nil

        def self.store(**kwargs)
          calls << kwargs
        end
      end
      ActiveadminConfigurableColumns.preference_store = store

      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title] }

      expect(store.calls).to eq([{ admin: admin, resource_key: resource_key, keys: %i[title] }])
    end
  end
end
