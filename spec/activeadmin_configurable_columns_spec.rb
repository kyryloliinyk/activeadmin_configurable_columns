RSpec.describe ActiveadminConfigurableColumns do
  let(:registry) do
    ActiveadminConfigurableColumns::Registry.build('widgets') do
      column :name
      column :code
      column :notes, default: false
    end
  end

  describe '.preference_store' do
    it 'defaults to a store that answers the read and write contract' do
      expect(described_class.preference_store).to respond_to(:visible_column_keys)
      expect(described_class.preference_store).to respond_to(:store)
    end

    it 'can be replaced' do
      store = Fakes::Store.new

      described_class.preference_store = store

      expect(described_class.preference_store).to eq(store)
    end

    it 'falls back to the default store when cleared' do
      default = described_class.preference_store
      described_class.preference_store = Fakes::Store.new

      described_class.preference_store = nil

      expect(described_class.preference_store).to eq(default)
    end
  end

  describe '.sidebar_priority' do
    it 'defaults to sitting below the filters section, which ActiveAdmin gives priority 10' do
      expect(described_class.sidebar_priority).to be > 10
    end

    it 'can be replaced, and falls back to the default when cleared' do
      described_class.sidebar_priority = 42
      expect(described_class.sidebar_priority).to eq(42)

      described_class.sidebar_priority = nil
      expect(described_class.sidebar_priority).to eq(described_class::DEFAULT_SIDEBAR_PRIORITY)
    end
  end

  describe '.menu' do
    it 'defaults to a translated label' do
      expect(described_class.menu).to include(:label)
    end

    it 'can be replaced with menu options' do
      described_class.menu = { parent: 'Settings', priority: 0 }

      expect(described_class.menu).to eq(parent: 'Settings', priority: 0)
    end

    it 'can be turned off entirely' do
      described_class.menu = false

      expect(described_class.menu).to be(false)
    end
  end

  describe '.configure' do
    it 'yields the module itself' do
      described_class.configure { |config| config.sidebar_priority = 15 }

      expect(described_class.sidebar_priority).to eq(15)
    end
  end

  describe '.visible_columns' do
    it 'returns the declared defaults when the admin never saved anything' do
      described_class.preference_store = Fakes::Store.new

      expect(described_class.visible_columns(registry, :alice).map(&:key)).to eq(%i[name code])
    end

    it 'returns what the admin saved' do
      described_class.preference_store =
        Fakes::Store.new(alice: { 'widgets' => %i[notes] })

      expect(described_class.visible_columns(registry, :alice).map(&:key)).to eq(%i[notes])
    end

    it 'asks the store for this resource and this admin' do
      store = Fakes::Store.new
      allow(store).to receive(:visible_column_keys).and_return(nil)
      described_class.preference_store = store

      described_class.visible_columns(registry, :alice)

      expect(store).to have_received(:visible_column_keys).with(:alice, 'widgets')
    end
  end

  describe '.resources' do
    let(:configured) do
      Fakes::ResourceConfig.new(route_key: 'widgets')
        .tap { |config| config.column_registry = registry }
    end
    let(:undeclared) { Fakes::ResourceConfig.new(route_key: 'gadgets') }
    # ActiveAdmin pages sit in the same collection and answer none of this.
    let(:page) { Object.new }

    it 'keeps only resources that declared columns' do
      namespace = Fakes::Namespace.new([page, undeclared, configured])

      expect(described_class.resources(namespace)).to eq([configured])
    end

    it 'is empty when nothing is configurable' do
      namespace = Fakes::Namespace.new([page, undeclared])

      expect(described_class.resources(namespace)).to be_empty
    end

    describe '.resource_for' do
      let(:namespace) { Fakes::Namespace.new([page, undeclared, configured]) }

      it 'finds a configurable resource by its key' do
        expect(described_class.resource_for(namespace, 'widgets')).to eq(configured)
      end

      it 'accepts a symbol key' do
        expect(described_class.resource_for(namespace, :widgets)).to eq(configured)
      end

      it 'returns nil for an unknown key' do
        expect(described_class.resource_for(namespace, 'made_up')).to be_nil
      end

      it 'returns nil for a resource that declared no columns' do
        expect(described_class.resource_for(namespace, 'gadgets')).to be_nil
      end
    end
  end

  describe '.route_name' do
    it 'prefixes the helper with the namespace' do
      namespace = Fakes::Namespace.new([], :admin)

      expect(described_class.route_name(namespace)).to eq('admin_table_columns_path')
      expect(described_class.route_name(namespace, :update)).to eq('admin_table_columns_update_path')
    end

    it 'drops the prefix for the root namespace, whose route_prefix is nil' do
      namespace = Fakes::Namespace.new([], nil)

      expect(described_class.route_name(namespace, :update)).to eq('table_columns_update_path')
    end
  end

  describe ActiveadminConfigurableColumns::NotDeclared do
    it 'names the resource and the missing declaration' do
      expect(described_class.new('Widget').message)
        .to eq('Widget renders configurable_columns but never declares them. ' \
               'Add a `configurable_columns do ... end` block to its ActiveAdmin registration.')
    end
  end
end
