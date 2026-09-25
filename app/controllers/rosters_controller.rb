class RostersController < ApplicationController
  before_action :require_admin

  def show
    @trial_class = TrialClass.find(params[:trial_class_id])
    bookings = @trial_class.bookings.eager_load(student: :parent).order("students.name")
    @confirmed_bookings = bookings.confirmed
    @held_bookings = bookings.held
  end

  private
    def require_admin
      redirect_to root_path, alert: "Only admins can see class rosters." unless current_user.is_a?(Admin)
    end
end
