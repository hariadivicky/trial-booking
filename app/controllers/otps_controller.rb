class OtpsController < ApplicationController
  def show
    @email = session[:otp_email]
    redirect_to sign_in_path unless @email
  end

  # Nothing is sent; the email is remembered for the OTP step.
  def create
    if user = find_user_by_email(params[:email])
      session[:otp_email] = user.email
      redirect_to sign_in_otp_path
    else
      redirect_to sign_in_path, alert: "No account found for that email."
    end
  end
end
