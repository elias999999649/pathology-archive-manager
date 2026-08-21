class StorageSnapshotPolicy < ApplicationPolicy
  def index? = administrator?
  def refresh? = administrator?
end
