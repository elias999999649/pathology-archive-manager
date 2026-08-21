class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = user.present?
  def show? = user.present?
  def create? = administrator?
  def new? = create?
  def update? = administrator?
  def edit? = update?
  def destroy? = system_administrator?

  private

  def administrator?
    user&.system_administrator? || user&.archive_administrator?
  end

  def system_administrator?
    user&.system_administrator?
  end
end
