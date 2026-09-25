class RostersController < ApplicationController
  before_action :require_admin

  def show
    @trial_class = TrialClass.find(params[:trial_class_id])
  end
end
