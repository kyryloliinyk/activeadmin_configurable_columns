class AdminUser < ActiveRecord::Base
  def display_name = email
end
