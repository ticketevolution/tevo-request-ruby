require 'rubygems'
require "base64"
require "openssl"
require "rack"
require 'faraday'
require "curb"

require File.expand_path("../config", __FILE__)

module TEVO
  HTTPS_PORT = 443
  CONNECTION_TIMEOUT_SECONDS = 10
  class Connection
    def initialize(params = {})
      @secret = params[:secret]
      @token  = params[:token]
      @config = TEVO::Config.for_mode(params[:config])
      unless @secret.is_a?(String) && @token.is_a?(String)
        raise ArgumentError.new('secret and token are required STRINGS')
      end
    end

    def http_request(path, params = {})
      method               = (params[:method] || "GET").to_sym
      palyoad              = params[:payload]
      param_free_uri       = uri(path)
      req_uri_alphabetized = process_params(method, param_free_uri, params)
      string_to_sign = "#{ method } #{ req_uri_alphabetized.gsub(@config[:protocol] + '://', '').gsub(/\:\d{2,5}\//, '/') }"

      if [:POST, :PUT, :PATCH].include?(method)
        string_to_sign = "#{ string_to_sign }#{ payload }"
      end

      signature = sign(string_to_sign)

      puts "...sending"
      puts " #{method}: #{req_uri_alphabetized}"
      curl_req = Curl::Easy.new(req_uri_alphabetized) do |curl|
        curl.connect_timeout = CONNECTION_TIMEOUT_SECONDS
        curl.headers['X-Token'] = @token
        curl.headers['X-Signature'] = signature
        curl.headers['Accept'] = "application/vnd.ticketevolution.api+json; version=8"
        if (@config[:mode] == :staging)
          # Staging doesn't actually have an SSL cert.
          curl.ssl_verify_peer = false
        end
        if [:POST, :PUT, :PATCH].include?(method)
          curl.post_body = post_body
          curl.headers['Content-Type'] = 'application/json; charset=utf-8'
        end
      end

      begin
        curl_req.http(method)
        body = curl_req.body_str
        status = curl_req.status
        return {
          body: body,
          status: status
        }
      rescue => ex
        return {
          body: ex.message,
          status: 500
        }
      end

    end

    private

    def process_params(method, uri, params)
      alphabetized_url = "#{ uri }?"
      if (method == :GET)
        alphabetized_url += Faraday::Utils.build_nested_query(params)
      end
      return alphabetized_url
    end

    def uri(path)
      parts = [].tap do |parts|
        parts << url
        parts << '/'
        parts << path
      end.join
    end

    def url
      [].tap do |parts|
        parts << @config[:protocol]
        parts << "://#{ @config[:subdomain] }."
        parts << @config[:url_base]
        parts << ":#{ @config[:port] }" if @config[:port] && @config[:port] != HTTPS_PORT
      end.join
    end

    def sign(string_to_sign)
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha256'),
          @secret,
          string_to_sign
        )
      ).chomp
    end
  end
end
