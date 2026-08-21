class SlideSearch
  SORT_COLUMNS = {
    "slide_uid" => "slide_uid",
    "case_id" => "case_id",
    "slide_type" => "slide_type",
    "stain" => "stain",
    "scanner" => "scanner",
    "status" => "status",
    "decision" => "decision",
    "received_at" => "received_at",
    "retention_expires_at" => "retention_expires_at"
  }.freeze

  FILTER_FIELDS = %w[slide_uid case_id patient_id barcode scanner hospital department slide_type stain].freeze

  def initialize(params, scope: Slide.all)
    @params = params
    @scope = scope
  end

  def call
    scope = @scope
    scope = apply_global_search(scope)
    scope = apply_field_filters(scope)
    scope = scope.where(acquisition_date: parsed_date(:acquisition_from)..parsed_date(:acquisition_to)) if parsed_date(:acquisition_from) && parsed_date(:acquisition_to)
    scope = scope.where("acquisition_date >= ?", parsed_date(:acquisition_from)) if parsed_date(:acquisition_from) && !parsed_date(:acquisition_to)
    scope = scope.where("acquisition_date <= ?", parsed_date(:acquisition_to)) if parsed_date(:acquisition_to) && !parsed_date(:acquisition_from)
    scope = scope.where(received_at: parsed_time(:received_from)..parsed_time(:received_to).end_of_day) if parsed_time(:received_from) && parsed_time(:received_to)
    scope = scope.where("received_at >= ?", parsed_time(:received_from)) if parsed_time(:received_from) && !parsed_time(:received_to)
    scope = scope.where("received_at <= ?", parsed_time(:received_to).end_of_day) if parsed_time(:received_to) && !parsed_time(:received_from)
    scope = scope.where(status: params[:status]) if valid_enum?(Slide.statuses, params[:status])
    scope = scope.where(decision: params[:decision]) if valid_enum?(Slide.decisions, params[:decision])
    scope = scope.order(order_clause)
    scope
  end

  private

  attr_reader :params, :scope

  def apply_global_search(scope)
    terms = params[:q].to_s.strip.split(/\s+/).reject(&:blank?)
    terms.reduce(scope) do |relation, term|
      if params[:match].to_s == "exact"
        relation.where(exact_global_search_sql, value: term)
      else
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
        relation.where(global_search_sql, pattern: pattern)
      end
    end
  end

  def apply_field_filters(scope)
    FILTER_FIELDS.reduce(scope) do |relation, field|
      value = params[field]
      next relation if value.blank?

      relation.where("slides.#{field} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s.strip)}%")
    end
  end

  def global_search_sql
    columns = Slide::SEARCHABLE_FIELDS.map { |field| "slides.#{field} ILIKE :pattern" }
    columns << "slides.tags::text ILIKE :pattern"
    columns.join(" OR ")
  end

  def exact_global_search_sql
    columns = Slide::SEARCHABLE_FIELDS.map { |field| "slides.#{field} = :value" }
    columns << "slides.tags @> ARRAY[:value]::varchar[]"
    columns.join(" OR ")
  end

  def valid_enum?(mapping, value)
    value.present? && mapping.key?(value.to_s)
  end

  def order_clause
    return relevance_order if params[:q].present? && params[:sort].blank?

    column = SORT_COLUMNS.fetch(params[:sort].to_s, "received_at")
    direction = params[:direction].to_s.downcase == "asc" ? "ASC" : "DESC"
    "slides.#{column} #{direction}, slides.id DESC"
  end

  def relevance_order
    terms = params[:q].to_s.strip.split(/\s+/).reject(&:blank?)
    terms.map { |term| relevance_for(term) }.join(" + ") + " DESC, slides.received_at DESC, slides.id DESC"
  end

  def relevance_for(term)
    value = ActiveRecord::Base.connection.quote(term)
    prefix = ActiveRecord::Base.connection.quote("#{term}%")
    contains = ActiveRecord::Base.connection.quote("%#{term}%")
    columns = Slide::SEARCHABLE_FIELDS.map do |field|
      "CASE WHEN slides.#{field} = #{value} THEN 100 WHEN slides.#{field} ILIKE #{prefix} THEN 50 WHEN slides.#{field} ILIKE #{contains} THEN 10 ELSE 0 END"
    end
    columns << "CASE WHEN slides.tags @> ARRAY[#{value}]::varchar[] THEN 100 WHEN slides.tags::text ILIKE #{contains} THEN 10 ELSE 0 END"
    "(#{columns.join(" + ")})"
  end

  def parsed_date(key)
    Date.parse(params[key].to_s) if params[key].present?
  rescue ArgumentError
    nil
  end

  def parsed_time(key)
    Time.zone.parse(params[key].to_s) if params[key].present?
  rescue ArgumentError
    nil
  end
end
