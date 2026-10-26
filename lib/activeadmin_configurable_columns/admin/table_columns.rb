# The "Table columns" page: a central place to review and change visible table
# columns and their order at once. The same form is rendered in the "Columns"
# sidebar of every configurable index, and both post back to the page's update
# action.
ActiveAdmin.register_page 'Table columns' do
  menu ActiveadminConfigurableColumns.menu

  content title: proc { I18n.t('active_admin.table_columns.title') } do
    resources = ActiveadminConfigurableColumns.resources(active_admin_namespace).select do |resource|
      authorized?(ActiveAdmin::Authorization::READ, resource.resource_class)
    end

    render 'activeadmin_configurable_columns/page', resources: resources
  end

  page_action :update, method: :patch do
    page_path = send(ActiveadminConfigurableColumns.route_name(active_admin_namespace))
    resource = ActiveadminConfigurableColumns.resource_for(active_admin_namespace, params[:resource_key])

    if resource.nil?
      redirect_back fallback_location: page_path,
                    status: :see_other,
                    alert: t('active_admin.table_columns.unknown_resource')
    elsif params[:reset].present?
      ActiveadminConfigurableColumns.reset_selection(resource.column_registry, current_active_admin_user)

      redirect_back fallback_location: page_path,
                    status: :see_other,
                    notice: t('active_admin.table_columns.reset_done')
    else
      ActiveadminConfigurableColumns.save_selection(
        resource.column_registry,
        current_active_admin_user,
        visible: params[:visible_columns],
        order: params[:columns]
      )

      redirect_back fallback_location: page_path,
                    status: :see_other,
                    notice: t('active_admin.table_columns.saved')
    end
  end
end
