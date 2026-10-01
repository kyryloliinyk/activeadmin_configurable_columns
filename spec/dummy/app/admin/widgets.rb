ActiveAdmin.register Widget do
  permit_params :title, :code

  configurable_columns do
    column :title
    # Calls a view helper with an implicit receiver, which only resolves when the
    # block is executed against the rendering table.
    column(:linked) { |widget| link_to widget.title, '#' }
    column :code, default: false
  end

  index do
    selectable_column
    configurable_columns
    actions
  end
end
