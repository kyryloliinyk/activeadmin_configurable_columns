ActiveAdmin.setup do |config|
  config.site_title = 'Dummy Admin'

  # The dummy app has no sign-in flow: specs assign the acting admin straight
  # to the controller (see spec/support/admin_session.rb).
  config.authentication_method = false
  config.current_user_method = :current_admin_user
  config.logout_link_path = :logout_path

  config.comments = false
end
