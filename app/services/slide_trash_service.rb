class SlideTrashService
  def self.call(slide, actor: nil, trashed_at: Time.current)
    raise ArgumentError, "Slide is not eligible for trash" unless slide.deletion_status_eligible_for_trash?

    slide.update!(deletion_status: "trashed", trashed_at: trashed_at)
    AuditLogger.record!(event_type: "slide.trashed", auditable: slide, actor: actor, metadata: { retention_expires_at: slide.retention_expires_at&.iso8601, deletion_status: slide.deletion_status })
    slide
  end
end
