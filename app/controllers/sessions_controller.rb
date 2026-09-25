class SessionsController < ApplicationController
  def new
  end

  # No session to clear until the auth mechanism lands.
  def destroy
    redirect_to root_path, status: :see_other
  end
end
