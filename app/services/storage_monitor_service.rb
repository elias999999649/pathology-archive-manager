class StorageMonitorService
  WARNING_THRESHOLDS = { warning_80: 80.0, warning_90: 90.0, critical_95: 95.0 }.freeze

  def self.refresh!(actor: nil, checked_at: Time.current)
    new(actor: actor, checked_at: checked_at).refresh!
  end

  def initialize(actor:, checked_at:)
    @actor = actor
    @checked_at = checked_at
  end

  def refresh!
    slides = Slide.where.not(file_size: nil).select(:file_size, :slide_type, :hospital)
    provider_data = Storage::Registry.build.summary(slides: slides)
    previous = StorageSnapshot.latest_first.first
    usage = usage_percentage(provider_data[:used_bytes], provider_data[:total_bytes])
    growth = growth_per_day(previous, provider_data[:used_bytes])
    snapshot = StorageSnapshot.create!(
      provider_name: provider_data[:provider_name], total_bytes: provider_data[:total_bytes], used_bytes: provider_data[:used_bytes], free_bytes: provider_data[:free_bytes], usage_percentage: usage, status: status_for(usage), checked_at: checked_at, slide_count: Slide.where.not(deletion_status: "permanently_deleted").count, growth_bytes_per_day: growth, estimated_remaining_days: estimated_days(provider_data[:free_bytes], growth), by_slide_type: breakdown(slides, :slide_type), by_hospital: breakdown(slides, :hospital)
    )
    AuditLogger.record!(event_type: "storage.checked", auditable: snapshot, actor: actor, metadata: { provider_name: snapshot.provider_name, status: snapshot.status, usage_percentage: snapshot.usage_percentage })
    AuditLogger.record!(event_type: "storage.warning", auditable: snapshot, actor: actor, reason: "Storage usage reached the #{snapshot.status.humanize} threshold.", metadata: { usage_percentage: snapshot.usage_percentage }) if snapshot.warning?
    snapshot
  rescue StandardError => e
    snapshot = StorageSnapshot.create!(provider_name: "Unknown", status: "error", checked_at: checked_at, error: "#{e.class.name.demodulize}: #{e.message}", by_slide_type: {}, by_hospital: {})
    AuditLogger.record!(event_type: "storage.check_failed", auditable: snapshot, actor: actor, metadata: { error_class: e.class.name })
    snapshot
  end

  private

  attr_reader :actor, :checked_at

  def usage_percentage(used, total)
    return nil if total.blank? || total.zero?

    ((used.to_f / total) * 100).round(2).clamp(0, 100)
  end

  def status_for(usage)
    return "unconfigured" if usage.nil?
    return "critical_95" if usage >= WARNING_THRESHOLDS[:critical_95]
    return "warning_90" if usage >= WARNING_THRESHOLDS[:warning_90]
    return "warning_80" if usage >= WARNING_THRESHOLDS[:warning_80]

    "healthy"
  end

  def growth_per_day(previous, used)
    return nil unless previous&.used_bytes && previous.checked_at && used

    days = (checked_at - previous.checked_at).to_f / 1.day
    return nil if days <= 0

    ((used - previous.used_bytes) / days).round
  end

  def estimated_days(free, growth)
    return nil if free.nil? || growth.nil? || growth <= 0

    (free.to_f / growth).floor
  end

  def breakdown(slides, field)
    slides.each_with_object(Hash.new(0)) do |slide, values|
      values[slide.public_send(field).presence || "Unknown"] += slide.file_size.to_i
    end
  end
end
