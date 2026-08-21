module StorageHelper
  def storage_status_label(snapshot)
    return "Not configured" if snapshot.nil? || snapshot.status == "unconfigured"
    return "Check failed" if snapshot.status == "error"

    snapshot.status.humanize
  end

  def storage_status_classes(snapshot)
    status = snapshot&.status
    palette = case status
    when "critical_95" then "bg-rose-50 text-rose-700 dark:bg-rose-950/50 dark:text-rose-300"
    when "warning_90" then "bg-orange-50 text-orange-700 dark:bg-orange-950/50 dark:text-orange-300"
    when "warning_80" then "bg-amber-50 text-amber-700 dark:bg-amber-950/50 dark:text-amber-300"
    when "healthy" then "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300"
    else "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"
    end
    "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold #{palette}"
  end

  def storage_progress_classes(snapshot)
    return "bg-slate-300 dark:bg-slate-700" unless snapshot&.usage_percentage
    return "bg-rose-500" if snapshot.critical?
    return "bg-orange-500" if snapshot.status == "warning_90"
    return "bg-amber-500" if snapshot.status == "warning_80"

    "bg-emerald-500"
  end

  def storage_value(bytes)
    bytes.nil? ? "—" : number_to_human_size(bytes)
  end
end
