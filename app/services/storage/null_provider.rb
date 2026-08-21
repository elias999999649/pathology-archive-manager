module Storage
  class NullProvider < Provider
    def summary(slides:)
      total = ENV["STORAGE_TOTAL_BYTES"].presence&.to_i
      used = slides.sum { |slide| slide.file_size.to_i }
      { provider_name: "Not configured", total_bytes: total, used_bytes: used, free_bytes: total ? [total - used, 0].max : nil }
    end
  end
end
