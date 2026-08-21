class ApiConnectionPolicy < ApplicationPolicy
  def index? = administrator?
  def show? = administrator?
  def create? = administrator?
  def new? = create?
  def update? = administrator?
  def edit? = update?
  def destroy? = administrator?
end
