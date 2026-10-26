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
      preferences.store(admin: admin, resource_key: resource_key, visible_keys: %i[title code], order_keys: nil)

      get admin_widgets_path

      expect(rendered_columns).to include(:title, :code)
      expect(rendered_columns).not_to include(:linked)
    end

    it 'renders them in the order the admin saved' do
      preferences.store(admin: admin, resource_key: resource_key,
                        visible_keys: %i[title code linked], order_keys: %i[code linked title])

      get admin_widgets_path

      expect(rendered_columns & registry.keys).to eq(%i[code linked title])
    end

    it 'is unaffected by what another admin saved' do
      other = AdminUser.create!(email: 'bob@example.com')
      preferences.store(admin: other, resource_key: resource_key, visible_keys: %i[code], order_keys: nil)

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

    it 'lists every column in the picker in the admin order, with a drag handle each' do
      preferences.store(admin: admin, resource_key: resource_key,
                        visible_keys: %i[title], order_keys: %i[code title linked])

      get admin_widgets_path

      expect(response.body.scan(/name="columns\[\]" value="([^"]+)"/).flatten).to eq(%w[code title linked])
      expect(response.body.scan('data-aacc-handle').size).to eq(3)
      expect(response.body).to include('aria-label="Move Code"')
    end

    it 'loads the picker script through the ActiveAdmin importmap' do
      get admin_widgets_path

      expect(response.body).to include('"activeadmin_configurable_columns/picker"')
      expect(response.body).to include('"activeadmin_configurable_columns/sortable"')
      expect(response.body).to include('import "activeadmin_configurable_columns/picker"')
    end
  end

  describe 'the table columns page' do
    it 'lists every configurable table' do
      get admin_table_columns_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(resource.plural_resource_label)
      expect(response.body).to include("name=\"resource_key\" value=\"#{resource_key}\"")
    end

    it 'loads the picker script once, however many pickers it shows' do
      get admin_table_columns_path

      expect(response.body.scan('data-aacc-list').size).to eq(2)
      expect(response.body.scan('import "activeadmin_configurable_columns/picker"').size).to eq(1)
    end
  end

  describe 'the picker assets' do
    it 'serves the vendored SortableJS module' do
      get ActionController::Base.helpers.asset_path('activeadmin_configurable_columns/sortable.js')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('export{')
    end

    it 'serves the picker module' do
      get ActionController::Base.helpers.asset_path('activeadmin_configurable_columns/picker.js')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('from "activeadmin_configurable_columns/sortable"')
    end
  end

  describe 'saving a selection' do
    def saved = preferences.fetch(admin, resource_key)

    it 'stores it for the current admin' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title code] }

      expect(response).to have_http_status(:see_other)
      expect(saved.visible_keys).to eq(%i[title code])
    end

    it 'stores the submitted order' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title], columns: %w[code title linked] }

      expect(saved.order_keys).to eq(%i[code title linked])
    end

    it 'keeps the saved order when none is submitted' do
      preferences.store(admin: admin, resource_key: resource_key,
                        visible_keys: %i[title], order_keys: %i[linked code title])

      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[code] }

      expect(saved.order_keys).to eq(%i[linked code title])
    end

    it 'ignores keys the resource never declared' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title made_up],
                      columns: %w[made_up code title linked] }

      expect(saved.visible_keys).to eq(%i[title])
      expect(saved.order_keys).to eq(%i[code title linked])
    end

    it 'stores the defaults when nothing is selected' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: [''] }

      expect(saved.visible_keys).to eq(registry.default_keys)
    end

    it 'resets the table to the defaults' do
      preferences.store(admin: admin, resource_key: resource_key,
                        visible_keys: %i[code], order_keys: %i[code title linked])

      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, reset: '1', visible_columns: %w[code] }

      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq(I18n.t('active_admin.table_columns.reset_done'))
      expect(saved).to be_nil
    end

    it 'refuses an unknown table' do
      patch admin_table_columns_update_path,
            params: { resource_key: 'made_up', visible_columns: %w[title] }

      expect(response).to have_http_status(:see_other)
      expect(preferences.count).to eq(0)
    end

    it 'goes through the pluggable preference store' do
      store = Fakes::Store.new
      ActiveadminConfigurableColumns.preference_store = store

      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title], columns: %w[title linked code] }

      expect(store.stored).to eq([{ admin: admin, resource_key: resource_key,
                                    visible_keys: %i[title], order_keys: %i[title linked code] }])
    end
  end
end
