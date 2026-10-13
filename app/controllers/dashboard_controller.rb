class DashboardController < ApplicationController
  def show
    @user = Current.user
  end
end
