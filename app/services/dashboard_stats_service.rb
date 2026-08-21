class DashboardStatsService
  CACHE_KEY = "dashboard_stats/v1"
  CACHE_TTL = 1.minute

  def self.call
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { new.build }
  end

  def self.clear!
    Rails.cache.delete(CACHE_KEY)
  end

  def build
    now = Time.current
    week_start = now.beginning_of_week
    {
      slides: slide_stats(now, week_start),
      storage: storage_stats,
      api: api_stats,
      rules: rule_stats,
      activity: activity_stats,
      retention: retention_stats
    }
  end

  private

  def slide_stats(now, week_start)
    {
      total: Slide.count,
      added_today: Slide.where(received_at: now.beginning_of_day..now.end_of_day).count,
      added_this_week: Slide.where(received_at: week_start..now.end_of_week).count,
      pending_review: Slide.review_queue.count,
      kept: Slide.where(decision: %w[keep keep_forever]).count,
      delete_scheduled: Slide.where(deletion_status: "scheduled").count,
      deleted: Slide.where(status: "deleted").count
    }
  end

  def storage_stats
    snapshot = StorageSnapshot.latest_first.first
    return {} unless snapshot

    {
      provider: snapshot.provider_name,
      total_bytes: snapshot.total_bytes,
      used_bytes: snapshot.used_bytes,
      free_bytes: snapshot.free_bytes,
      usage_percentage: snapshot.usage_percentage,
      status: snapshot.status,
      checked_at: snapshot.checked_at
    }
  end

  def api_stats
    { connected: ApiConnection.where(enabled: true, status: %w[healthy testing syncing]).count, offline: ApiConnection.where(status: %w[error disabled]).count, last_synchronization: ApiConnection.maximum(:last_successful_sync_at) }
  end

  def rule_stats
    evaluations = RuleEvaluation.includes(:slide, :winning_rule).order(evaluated_at: :desc).limit(5)
    distribution = RuleEvaluation.group(:final_decision).count
    { active: ArchiveRule.where(enabled: true).count, recent_decisions: evaluations.map { |evaluation| { slide_uid: evaluation.slide.slide_uid, decision: evaluation.final_decision, rule_name: evaluation.winning_rule&.name || "No matching rule", reason: evaluation.reason, evaluated_at: evaluation.evaluated_at } }, distribution: distribution }
  end

  def activity_stats
    AuditLog.includes(:actor).order(created_at: :desc).limit(8).map { |event| { event_type: event.event_type, actor: event.actor&.email || "System", created_at: event.created_at } }
  end

  def retention_stats
    { expiring_soon: Slide.expiring_soon.count, eligible_for_deletion: Slide.eligible_for_deletion.count }
  end
end
