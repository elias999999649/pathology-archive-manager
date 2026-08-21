module Storage
  class Provider
    def summary(slides:)
      raise NotImplementedError
    end
  end
end
