class Review < ApplicationRecord
  belongs_to :slide
  belongs_to :reviewer, class_name: "User"

  enum :decision, { keep: "keep", delete: "delete" }, validate: true

  validates :decision, :decided_at, presence: true
  validate :previous_state_is_an_object
  validate :tags_are_strings

  private

  def previous_state_is_an_object
    errors.add(:previous_state, "must be a JSON object") unless previous_state.is_a?(Hash)
  end

  def tags_are_strings
    errors.add(:tags_added, "must contain only strings") unless tags_added.is_a?(Array) && tags_added.all? { |tag| tag.is_a?(String) }
  end
end
