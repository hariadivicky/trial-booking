class CheckoutsController < ApplicationController
  before_action :redirect_admin
  before_action :set_trial_class

  def show
    @checkout = Checkout.new(trial_class: @trial_class, parent: current_user)
  end

  def create
    @checkout = Checkout.new(checkout_params.merge(trial_class: @trial_class, parent: current_user))

    if @checkout.save
      sign_in @checkout.parent unless current_user
      redirect_to payment_path(@checkout.booking)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    # Admins have no children to book for.
    def redirect_admin
      redirect_to root_path, alert: "Admins can't book trial classes." if current_user.is_a?(Admin)
    end

    def set_trial_class
      @trial_class = TrialClass.find(params[:trial_class_id])
    end

    def checkout_params
      params.expect(checkout: %i[parent_name parent_email student_id student_name])
    end
end
