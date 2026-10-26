RSpec.describe ActiveadminConfigurableColumns::Selection do
  let(:registry) do
    ActiveadminConfigurableColumns::Registry.build('widgets') do
      column :name
      column :code
      column :size
      column :notes, default: false
    end
  end

  def selection(saved) = described_class.new(registry, saved)

  def order_of(saved) = selection(saved).columns.map(&:key)

  def visible_of(saved) = selection(saved).visible_columns.map(&:key)

  context 'when the admin never saved anything' do
    it 'lists every column in declaration order' do
      expect(order_of(nil)).to eq(%i[name code size notes])
    end

    it 'shows the declared defaults' do
      expect(visible_of(nil)).to eq(%i[name code size])
    end
  end

  context 'with a selection saved before reordering existed' do
    let(:saved) { Fakes.saved(%i[notes name]) }

    it 'keeps declaration order' do
      expect(order_of(saved)).to eq(%i[name code size notes])
    end

    it 'shows exactly what was ticked, in declaration order' do
      expect(visible_of(saved)).to eq(%i[name notes])
    end
  end

  context 'with a saved order' do
    let(:saved) { Fakes.saved(%i[name notes], %i[notes size name code]) }

    it 'lists every column in that order' do
      expect(order_of(saved)).to eq(%i[notes size name code])
    end

    it 'shows the ticked columns in that order' do
      expect(visible_of(saved)).to eq(%i[notes name])
    end

    it 'answers visibility per column' do
      expect(selection(saved).columns.map { |column| selection(saved).visible?(column) })
        .to eq([true, false, true, false])
    end
  end

  context 'when columns were declared after the order was saved' do
    let(:registry) do
      ActiveadminConfigurableColumns::Registry.build('widgets') do
        column :name
        column :added
        column :code
        column :added_hidden, default: false
      end
    end
    let(:saved) { Fakes.saved(%i[code], %i[code name]) }

    it 'places them after their declared neighbour' do
      expect(order_of(saved)).to eq(%i[code added_hidden name added])
    end

    it 'shows the new default columns, but not the new hidden ones' do
      expect(visible_of(saved)).to eq(%i[code added])
    end
  end

  it 'drops columns that are no longer declared' do
    saved = Fakes.saved(%i[gone code], %i[gone code name size notes])

    expect(order_of(saved)).to eq(%i[code name size notes])
    expect(visible_of(saved)).to eq(%i[code])
  end

  it 'falls back to the defaults for an empty visible list, keeping the order' do
    saved = Fakes.saved([], %i[notes size code name])

    expect(visible_of(saved)).to eq(%i[size code name])
  end
end
