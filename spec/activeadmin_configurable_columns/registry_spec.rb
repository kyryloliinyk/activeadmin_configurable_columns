RSpec.describe ActiveadminConfigurableColumns::Registry do
  subject(:registry) do
    described_class.build('widgets') do
      column :name
      column :code, label: 'Code'
      column(:size, sortable: 'sizes_value') { |widget| widget.size }
      column :notes, default: false
    end
  end

  describe '.build' do
    it 'stores the resource key as a string' do
      expect(described_class.build(:widgets) { column :name }.resource_key).to eq('widgets')
    end

    it 'keeps the declaration order' do
      expect(registry.keys).to eq(%i[name code size notes])
    end

    it 'builds a column per declaration' do
      expect(registry.columns).to all(be_a(ActiveadminConfigurableColumns::Column))
    end

    it 'passes the block on to the column' do
      expect(registry.columns.third.block).to be_a(Proc)
    end

    it 'passes options on to the column' do
      expect(registry.columns.third.options).to eq(sortable: 'sizes_value')
    end

    it 'accepts an empty declaration' do
      expect(described_class.build('widgets') {}.keys).to eq([])
    end

    it 'freezes the column list' do
      expect(registry.columns).to be_frozen
    end
  end

  describe '#default_keys' do
    it 'excludes columns declared hidden' do
      expect(registry.default_keys).to eq(%i[name code size])
    end
  end

  describe '#columns_for' do
    it 'returns the wanted columns' do
      expect(registry.columns_for(%i[name notes])).to all(be_a(ActiveadminConfigurableColumns::Column))
      expect(registry.selected_keys(%i[name notes])).to eq(%i[name notes])
    end

    it 'returns them in declaration order, not selection order' do
      expect(registry.selected_keys(%i[notes name])).to eq(%i[name notes])
    end

    it 'accepts strings' do
      expect(registry.selected_keys(%w[notes])).to eq(%i[notes])
    end

    it 'accepts nil as no selection' do
      expect(registry.selected_keys(nil)).to eq(registry.default_keys)
    end

    it 'drops keys that are no longer declared' do
      expect(registry.selected_keys(%i[name dropped_last_year])).to eq(%i[name])
    end

    it 'falls back to the defaults for an empty selection' do
      expect(registry.selected_keys([])).to eq(registry.default_keys)
    end

    it 'falls back to the defaults when nothing selected is still declared' do
      expect(registry.selected_keys(%i[dropped_last_year])).to eq(registry.default_keys)
    end
  end

  describe '#arrange' do
    it 'returns the keys in the given order' do
      expect(registry.arrange(%i[notes size code name])).to eq(%i[notes size code name])
    end

    it 'accepts strings' do
      expect(registry.arrange(%w[notes size code name])).to eq(%i[notes size code name])
    end

    it 'drops unknown, stale, blank and duplicate keys' do
      expect(registry.arrange(['', 'notes', :gone, :notes, :size, :code, :name]))
        .to eq(%i[notes size code name])
    end

    it 'places a missing key right after its declared predecessor' do
      expect(registry.arrange(%i[notes name size])).to eq(%i[notes name code size])
    end

    it 'places a missing first key first' do
      expect(registry.arrange(%i[notes code size])).to eq(%i[name notes code size])
    end

    it 'keeps consecutive missing keys together' do
      expect(registry.arrange(%i[notes name])).to eq(%i[notes name code size])
    end

    it 'falls back to declaration order for nothing usable' do
      expect(registry.arrange(nil)).to eq(registry.keys)
      expect(registry.arrange(%i[gone])).to eq(registry.keys)
    end
  end

  describe '#columns_in' do
    it 'returns the declared columns in the given order' do
      expect(registry.columns_in(%i[notes name]).map(&:key)).to eq(%i[notes name])
    end

    it 'skips unknown keys' do
      expect(registry.columns_in(%i[gone name]).map(&:key)).to eq(%i[name])
    end
  end

  describe ActiveadminConfigurableColumns::Registry::Builder do
    it 'collects columns in call order' do
      builder = described_class.new
      builder.column :a
      builder.column :b

      expect(builder.columns.map(&:key)).to eq(%i[a b])
    end
  end
end
