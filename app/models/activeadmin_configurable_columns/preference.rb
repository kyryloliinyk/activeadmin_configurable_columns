module ActiveadminConfigurableColumns
  # One row per admin per ActiveAdmin index table, holding the columns that
  # admin chose to see there. The available columns themselves are declared in
  # the ActiveAdmin registration with the `configurable_columns` DSL.
  #
  # `admin` is polymorphic and its id column is a string, so any current-user
  # model works, whatever its class and primary key type (integer, uuid, ...).
  class Preference < ::ActiveRecord::Base
    self.table_name = 'activeadmin_configurable_columns_preferences'

    belongs_to :admin, polymorphic: true

    # Stored as JSON text rather than a database-specific json type, so the
    # table works the same on every Active Record adapter. The array shape is
    # enforced by the validation below, not by the coder, so a bad assignment
    # surfaces as a validation error instead of a serialization exception.
    serialize :visible_columns, coder: JSON

    after_initialize { self.visible_columns ||= [] if has_attribute?(:visible_columns) }

    validates :resource_key, presence: true,
                             uniqueness: { scope: %i[admin_type admin_id], case_sensitive: false }
    validate :visible_columns_must_be_an_array

    # Returns the keys this admin picked for the table, or nil when they never
    # saved anything (the caller then falls back to the declared defaults).
    def self.visible_column_keys(admin, resource_key)
      return nil if admin.blank?

      find_by(admin: admin, resource_key: resource_key)&.visible_columns&.map(&:to_sym)
    end

    def self.store(admin:, resource_key:, keys:)
      preference = find_or_initialize_by(admin: admin, resource_key: resource_key)
      preference.update!(visible_columns: keys.map(&:to_s))
      preference
    end

    private

    def visible_columns_must_be_an_array
      return if visible_columns.is_a?(Array)

      errors.add(:visible_columns, :invalid)
    end
  end
end
