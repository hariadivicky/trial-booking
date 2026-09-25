class CheckoutsController < ApplicationController
  def show
    @trial_class = TrialClass.find(params[:trial_class_id])
  end
end
