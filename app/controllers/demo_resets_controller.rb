class DemoResetsController < ApplicationController
  before_action :require_admin

  # The reset recreates the admin too, so the old session no longer points at an account.
  def create
    Demo.reset!
    reset_session
    redirect_to sign_in_path
  end
end
