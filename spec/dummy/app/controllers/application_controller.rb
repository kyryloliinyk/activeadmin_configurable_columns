class ApplicationController < ActionController::Base
  # The dummy app has no sign-in flow: request specs assign the acting admin here.
  cattr_accessor :current_admin

  def current_admin_user
    self.class.current_admin
  end
end
