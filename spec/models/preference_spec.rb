RSpec.describe ActiveadminConfigurableColumns::Preference do
  let(:admin) { AdminUser.create!(email: 'alice@example.com') }

  def build_preference(**overrides)
    described_class.new(admin: admin, resource_key: 'products', visible_columns: %w[brand sku], **overrides)
  end

  it 'is valid with an admin, a resource key and a column list' do
    expect(build_preference).to be_valid
  end

  it 'starts with an empty column list' do
    expect(described_class.new.visible_columns).to eq([])
  end

  describe 'validations' do
    it 'requires an admin' do
      expect(build_preference(admin: nil)).not_to be_valid
    end

    it 'requires a resource key' do
      expect(build_preference(resource_key: nil)).not_to be_valid
    end

    it 'allows one preference per admin per table, comparing keys case-insensitively' do
      build_preference.save!

      expect(build_preference(resource_key: 'Products')).not_to be_valid
    end

    it 'allows the same table for another admin' do
      build_preference.save!
      other = AdminUser.create!(email: 'bob@example.com')

      expect(build_preference(admin: other)).to be_valid
    end

    it 'rejects a non-array column list' do
      preference = build_preference
      preference.visible_columns = { brand: true }

      expect(preference).not_to be_valid
    end

    it 'accepts a missing column order' do
      expect(build_preference(column_order: nil)).to be_valid
    end

    it 'rejects a non-array column order' do
      expect(build_preference(column_order: { brand: 1 })).not_to be_valid
    end
  end

  describe '.fetch' do
    it 'returns nil when the admin never saved anything' do
      expect(described_class.fetch(admin, 'products')).to be_nil
    end

    it 'returns nil without an admin' do
      expect(described_class.fetch(nil, 'products')).to be_nil
    end

    it 'returns the stored keys and order as symbols' do
      build_preference(visible_columns: %w[sku name], column_order: %w[name sku brand]).save!

      expect(described_class.fetch(admin, 'products'))
        .to eq(ActiveadminConfigurableColumns::SavedSelection.new(visible_keys: %i[sku name],
                                                                  order_keys: %i[name sku brand]))
    end

    it 'returns no order for a selection saved before reordering existed' do
      build_preference(visible_columns: %w[sku]).save!

      expect(described_class.fetch(admin, 'products').order_keys).to be_nil
    end

    it 'ignores preferences of other admins and other tables' do
      build_preference(resource_key: 'brands', visible_columns: %w[name]).save!
      other = AdminUser.create!(email: 'bob@example.com')
      build_preference(admin: other, visible_columns: %w[sku]).save!

      expect(described_class.fetch(admin, 'products')).to be_nil
    end
  end

  describe '.store' do
    def store(**selection)
      described_class.store(admin: admin, resource_key: 'products', **selection)
    end

    it 'creates the preference' do
      expect { store(visible_keys: %i[sku name], order_keys: %i[name sku]) }
        .to change(described_class, :count).by(1)

      expect(described_class.fetch(admin, 'products').to_h)
        .to eq(visible_keys: %i[sku name], order_keys: %i[name sku])
    end

    it 'updates the existing preference instead of adding another one' do
      store(visible_keys: %i[sku], order_keys: nil)

      expect { store(visible_keys: %i[name], order_keys: %i[name sku]) }
        .not_to change(described_class, :count)

      expect(described_class.fetch(admin, 'products').to_h)
        .to eq(visible_keys: %i[name], order_keys: %i[name sku])
    end

    it 'stores a missing order as NULL' do
      store(visible_keys: %i[sku], order_keys: nil)

      expect(described_class.find_by(resource_key: 'products').read_attribute_before_type_cast(:column_order))
        .to be_nil
    end
  end

  describe '.clear' do
    it 'removes only this admin preference for this table' do
      build_preference.save!
      build_preference(resource_key: 'brands').save!

      described_class.clear(admin: admin, resource_key: 'products')

      expect(described_class.fetch(admin, 'products')).to be_nil
      expect(described_class.fetch(admin, 'brands')).not_to be_nil
    end

    it 'does nothing without an admin' do
      build_preference.save!

      expect { described_class.clear(admin: nil, resource_key: 'products') }
        .not_to change(described_class, :count)
    end
  end
end
