require 'rubygems'
require "base64"
require "openssl"
require "rack"
require 'faraday'
require "curb"

module TEVO
  HTTPS_PORT                 = 443
  HTTPS                      = "https"
  HTTP                       = "http"
  CONNECTION_TIMEOUT_SECONDS = 10
  CONFIGS = {
    :development => {
      :mode      => :development,
      :protocol  => HTTP,   # http://api.lvh.me:3000
      :subdomain => 'api',    # PROTOCOL SUBDOMAIN URL_BASE PORT
      :url_base  => 'lvh.me',
      :port      => 3000
    },
    :staging => {
      :mode      => :staging,
      :protocol  => HTTPS,
      :subdomain => 'api',
      :url_base  => 'staging.ticketevolution.com',
    },

    :sandbox => {
      :mode      => :sandbox,
      :protocol  => HTTPS,
      :subdomain => 'api',
      :url_base  => 'sandbox.ticketevolution.com',
      :port      => HTTPS_PORT
    },

    :production => {
      :mode      => :production,
      :protocol  => HTTPS,
      :subdomain => 'api',
      :url_base  => 'ticketevolution.com',
      :port      => HTTPS_PORT
    }
  }

  class Connection
    def _and(*predicates)
      !predicates.map {|p| !!p}.find_index(false)
    end

    def initialize(params = {})
      @secret = params[:secret]
      @token  = params[:token]
      @env    = params[:env] || :development
      @config = CONFIGS[@env]
      unless _and(@secret.is_a?(String), @token.is_a?(String))
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
