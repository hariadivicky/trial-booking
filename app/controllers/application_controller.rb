class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user

  private
    # Stub until the auth mechanism lands; nil means signed out.
    def current_user
      nil
    end
end
