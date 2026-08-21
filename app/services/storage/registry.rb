module Storage
  class Registry
    def self.build
      # A real cloud adapter can be registered here without changing the
      # monitoring, threshold, or dashboard layers.
      NullProvider.new
    end
  end
end
