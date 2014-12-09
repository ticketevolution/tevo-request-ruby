module TEVO
  class Utils
    def self.sign(secret, string_to_sign)
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha256'),
          secret,
          string_to_sign
        )
      ).chomp
    end
  end
end
