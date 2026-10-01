Rails.application.routes.draw do
  # ActiveAdmin's header renders a logout link for the current user; the dummy
  # app has no real session to destroy, so the route just answers 204.
  delete 'logout', to: proc { [204, {}, []] }, as: :logout

  ActiveAdmin.routes(self)
end
