class HomeController < ApplicationController
  def index
    @trial_classes_by_subject = TrialClass.eager_load(:class_subject)
      .order("class_subjects.name", :title)
      .group_by(&:class_subject)
  end
end
