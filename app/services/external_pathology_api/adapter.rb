module ExternalPathologyApi
  class Adapter
    def initialize(connection)
      @connection = connection
    end

    def test_connection
      raise NotImplementedError
    end

    def fetch_slide_metadata
      raise NotImplementedError
    end

    private

    attr_reader :connection
  end
end
