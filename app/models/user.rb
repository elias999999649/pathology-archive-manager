class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum :role, {
    system_administrator: 0,
    archive_administrator: 1,
    reviewer: 2,
    viewer: 3
  }, default: :viewer

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
