# A second configurable table, so the "Table columns" page shows more than one
# picker.
ActiveAdmin.register Gadget do
  configurable_columns do
    column :name
    column :serial
  end

  index do
    configurable_columns
  end
end
