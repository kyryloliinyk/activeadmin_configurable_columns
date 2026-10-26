module ActiveadminConfigurableColumns
  # What a preference store returns for one admin and one table.
  #
  #   visible_keys -- the keys the admin ticked
  #   order_keys   -- every key in the admin's order, or nil when the selection
  #                   was saved before reordering existed (declaration order)
  SavedSelection = Struct.new(:visible_keys, :order_keys, keyword_init: true)
end
