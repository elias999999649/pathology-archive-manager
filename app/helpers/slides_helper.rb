module SlidesHelper
  def badge_classes(kind, value)
    palette = {
      "available" => "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300",
      "archived" => "bg-blue-50 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300",
      "under_review" => "bg-amber-50 text-amber-700 dark:bg-amber-950/50 dark:text-amber-300",
      "deleted" => "bg-rose-50 text-rose-700 dark:bg-rose-950/50 dark:text-rose-300",
      "keep" => "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300",
      "keep_forever" => "bg-violet-50 text-violet-700 dark:bg-violet-950/50 dark:text-violet-300",
      "delete" => "bg-rose-50 text-rose-700 dark:bg-rose-950/50 dark:text-rose-300",
      "delete_after_retention" => "bg-orange-50 text-orange-700 dark:bg-orange-950/50 dark:text-orange-300",
      "manual_review" => "bg-amber-50 text-amber-700 dark:bg-amber-950/50 dark:text-amber-300"
    }
    "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold #{palette.fetch(value.to_s, 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300')}"
  end

  def human_enum(value)
    value.to_s.humanize
  end

  def retention_label(slide)
    return "Forever" if slide.decision == "keep_forever"
    return "—" if slide.retention_expires_at.blank?

    slide.retention_expires_at.to_date.to_fs(:long)
  end

  def slides_query_params(overrides = {})
    request.query_parameters.symbolize_keys.merge(overrides).compact
  end
end
