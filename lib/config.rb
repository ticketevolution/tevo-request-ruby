module TEVO
  class Config
    def self.for_mode(mode = :development)
      mode       ||= :development
      http       = "http"
      https      = "https"
      https_port = 443
      puts "...fetching configuration for #{mode.to_s}"
      configs = {
        :development => {
          :mode      => :development,
          :protocol  => http,   # http://api.lvh.me:3000
          :subdomain => 'api',    # PROTOCOL SUBDOMAIN URL_BASE PORT
          :url_base  => 'lvh.me',
          :port      => 3000
        },
        :staging => {
          :mode      => :staging,
          :protocol  => https,
          :subdomain => 'api',
          :url_base  => 'staging.ticketevolution.com',
        },

        :sandbox => {
          :mode      => :sandbox,
          :protocol  => https,
          :subdomain => 'api',
          :url_base  => 'sandbox.ticketevolution.com',
          :port      => https_port
        },

        :production => {
          :mode      => :production,
          :protocol  => https,
          :subdomain => 'api',
          :url_base  => 'ticketevolution.com',
          :port      => https_port
        }
      }
      configs[mode]
    end
  end
end
