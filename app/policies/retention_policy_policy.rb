class RetentionPolicyPolicy < ApplicationPolicy
  def index? = administrator?
  def show? = administrator?
end
