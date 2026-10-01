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
  end

  describe '.visible_column_keys' do
    it 'returns nil when the admin never saved anything' do
      expect(described_class.visible_column_keys(admin, 'products')).to be_nil
    end

    it 'returns nil without an admin' do
      expect(described_class.visible_column_keys(nil, 'products')).to be_nil
    end

    it 'returns the stored keys as symbols' do
      build_preference(visible_columns: %w[sku name]).save!

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[sku name])
    end

    it 'ignores preferences of other admins and other tables' do
      build_preference(resource_key: 'brands', visible_columns: %w[name]).save!
      other = AdminUser.create!(email: 'bob@example.com')
      build_preference(admin: other, visible_columns: %w[sku]).save!

      expect(described_class.visible_column_keys(admin, 'products')).to be_nil
    end
  end

  describe '.store' do
    it 'creates the preference' do
      expect { described_class.store(admin: admin, resource_key: 'products', keys: %i[sku name]) }
        .to change(described_class, :count).by(1)

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[sku name])
    end

    it 'updates the existing preference instead of adding another one' do
      described_class.store(admin: admin, resource_key: 'products', keys: %i[sku])

      expect { described_class.store(admin: admin, resource_key: 'products', keys: %i[name]) }
        .not_to change(described_class, :count)

      expect(described_class.visible_column_keys(admin, 'products')).to eq(%i[name])
    end
  end
end
