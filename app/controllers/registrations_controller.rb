class RegistrationsController < ApplicationController
  def new
    @parent = Parent.new
  end

  def create
    @parent = Parent.new(params.expect(parent: %i[name email]))

    if @parent.save
      sign_in @parent
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end
end
