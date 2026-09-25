class HomeController < ApplicationController
  def index
    @trial_classes_by_subject = TrialClass.eager_load(:class_subject)
      .preload(:seat_holding_bookings)
      .order("class_subjects.name", :title)
      .group_by(&:class_subject)
  end
end
