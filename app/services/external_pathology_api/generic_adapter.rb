require "net/http"
require "uri"

module ExternalPathologyApi
  class GenericAdapter < Adapter
    TIMEOUT_SECONDS = 10

    def test_connection
      response = request(:get)
      return true if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)

      raise ConnectionError, "External API returned HTTP #{response.code}"
    end

    def fetch_slide_metadata
      # Deliberately empty: vendor-specific payload mapping belongs in a
      # replaceable adapter and is not inferred from a generic endpoint.
      []
    end

    private

    def request(method)
      uri = URI.parse(connection.base_url)
      request = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri)
      request["Accept"] = "application/json"
      apply_authentication(request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS
      http.start { |client| client.request(request) }
    rescue Timeout::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
      raise ConnectionError, "External API connection failed (#{e.class.name.demodulize})"
    end

    def apply_authentication(request)
      secret = connection.credentials.to_h
      case connection.authentication_method
      when "api_key"
        request["X-API-Key"] = secret["token"].to_s if secret["token"].present?
      when "bearer_token"
        request["Authorization"] = "Bearer #{secret['token']}" if secret["token"].present?
      when "basic_auth"
        request.basic_auth(secret["username"].to_s, secret["password"].to_s)
      end
    end
  end

  class ConnectionError < StandardError; end
end
