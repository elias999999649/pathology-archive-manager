module ExternalPathologyApi
  class Registry
    def self.build(connection)
      GenericAdapter.new(connection)
    end
  end
end
