class DashboardController < ApplicationController
  def show
    authorize :dashboard, :show?
    @dashboard = DashboardStatsService.call
  end
end
