class SessionsController < ApplicationController
  FAKE_OTP = "1234"

  def new
  end

  def create
    user = find_user_by_email(session[:otp_email])

    if user && params[:otp] == FAKE_OTP
      sign_in user
      redirect_to root_path
    else
      redirect_to sign_in_otp_path, alert: "Wrong code, try again."
    end
  end

  def destroy
    reset_session
    redirect_to root_path, status: :see_other
  end
end
