class ArchiveRuleConditionEvaluator
  def self.call(slide, condition)
    new(slide, condition).call
  end

  def initialize(slide, condition)
    @slide = slide
    @condition = condition.stringify_keys
  end

  def call
    field = condition["field"]
    operator = condition["operator"]
    actual = value_for(field)
    expected = condition["value"]
    result = evaluate(operator, actual, expected, condition["value_to"])
    { matched: result, field: field, operator: operator, expected: expected, actual: display_value(actual), reason: "#{field} #{operator} #{result ? 'matched' : 'did not match'}" }
  rescue ArgumentError, TypeError
    { matched: false, field: condition["field"], operator: condition["operator"], expected: condition["value"], actual: display_value(actual), reason: "#{condition['field']} could not be compared" }
  end

  private

  attr_reader :slide, :condition

  def value_for(field)
    return metadata_value(condition["path"]) if field == "metadata"

    slide.public_send(field)
  end

  def metadata_value(path)
    path.to_s.split(".").reduce(slide.metadata) { |value, key| value.is_a?(Hash) ? value[key] || value[key.to_sym] : nil }
  end

  def evaluate(operator, actual, expected, expected_to)
    return !actual.blank? if operator == "is_present"
    return actual.blank? if operator == "is_not_present"
    return false if actual.blank? && !%w[not_equals not_contains].include?(operator)

    case operator
    when "equals" then actual.is_a?(Array) ? actual.any? { |item| comparable(item, expected) == 0 } : comparable(actual, expected) == 0
    when "not_equals" then actual.is_a?(Array) ? actual.all? { |item| comparable(item, expected) != 0 } : comparable(actual, expected) != 0
    when "contains" then includes?(actual, expected)
    when "not_contains" then !includes?(actual, expected)
    when "starts_with" then actual.to_s.downcase.start_with?(expected.to_s.downcase)
    when "ends_with" then actual.to_s.downcase.end_with?(expected.to_s.downcase)
    when "greater_than" then comparable(actual, expected) > 0
    when "less_than" then comparable(actual, expected) < 0
    when "between" then comparable(actual, expected) >= 0 && comparable(actual, expected_to) <= 0
    else false
    end
  end

  def includes?(actual, expected)
    actual.is_a?(Array) ? actual.any? { |item| item.to_s.casecmp?(expected.to_s) } : actual.to_s.downcase.include?(expected.to_s.downcase)
  end

  def comparable(actual, expected)
    if actual.is_a?(Numeric)
      actual <=> Float(expected)
    elsif actual.respond_to?(:to_date) && expected.to_s.match?(/\A\d{4}-\d{2}-\d{2}/)
      actual.to_date <=> Date.parse(expected.to_s)
    else
      actual.to_s.casecmp(expected.to_s)
    end
  end

  def display_value(value)
    value.is_a?(Array) || value.is_a?(Hash) ? value : value.to_s
  end
end
