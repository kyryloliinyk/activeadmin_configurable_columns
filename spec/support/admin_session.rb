module AdminSession
  def sign_in(admin)
    ApplicationController.current_admin = admin
  end
end

RSpec.configure do |config|
  config.include AdminSession, type: :request
  config.after { ApplicationController.current_admin = nil }
end
