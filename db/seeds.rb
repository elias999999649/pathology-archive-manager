[
  ["30_days", "30 days", "days", 30], ["60_days", "60 days", "days", 60], ["90_days", "90 days", "days", 90],
  ["6_months", "6 months", "months", 6], ["1_year", "1 year", "years", 1], ["5_years", "5 years", "years", 5],
  ["10_years", "10 years", "years", 10], ["forever", "Forever", "forever", nil]
].each do |code, name, unit, value|
  RetentionPolicy.find_or_create_by!(code: code) { |policy| policy.assign_attributes(name: name, duration_unit: unit, duration_value: value) }
end
