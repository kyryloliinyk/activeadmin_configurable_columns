module ActiveadminConfigurableColumns
  # The columns of one table as one admin sees them: every declared column in
  # the admin's order, and which of them are visible. Both the index table and
  # the picker read it, so they can never disagree.
  class Selection
    attr_reader :columns, :visible_keys

    # `saved` is the store's SavedSelection, or nil when the admin never saved.
    def initialize(registry, saved)
      order = saved&.order_keys
      @columns = registry.columns_in(order ? registry.arrange(order) : registry.keys)
      @visible_keys = resolve_visible_keys(registry, saved).freeze
    end

    def visible_columns = columns.select { |column| visible?(column) }

    def visible?(column) = visible_keys.include?(column.key)

    private

    # A blank selection falls back to the defaults, so a table is never empty.
    def resolve_visible_keys(registry, saved)
      return registry.default_keys if saved.nil?

      keys = registry.keys & Array(saved.visible_keys).map(&:to_sym)
      keys |= added_since_saved(registry, saved.order_keys) if saved.order_keys
      keys.empty? ? registry.default_keys : keys
    end

    # A saved order lists every key declared at the time it was saved, so a key
    # missing from it was declared later; it shows up when it is a default one.
    # Selections saved without an order cannot tell new keys apart and keep
    # showing exactly what was ticked.
    def added_since_saved(registry, order_keys)
      known = order_keys.map(&:to_sym)

      registry.columns.select { |column| column.default? && !known.include?(column.key) }.map(&:key)
    end
  end
end
