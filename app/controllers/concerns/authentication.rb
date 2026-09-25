# Fake OTP auth: the signed-in account's GlobalID lives in the encrypted session cookie.
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private
    def current_user
      @current_user ||= GlobalID::Locator.locate(session[:user_gid], only: [ Parent, Admin ])
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def require_admin
      redirect_to root_path, alert: "Only admins can do that." unless current_user.is_a?(Admin)
    end

    def find_user_by_email(email)
      Parent.find_by(email:) || Admin.find_by(email:)
    end

    def sign_in(user)
      reset_session
      session[:user_gid] = user.to_gid.to_s
    end
end
