require "benchmark"
require 'oj'
require "../../api_direct.rb"

# example:

# initialize a new config
@config = TicketEvolution::SandboxConfig.new('919a46d43bd2a9ced2e1530df04b0c5e', '6arxCYGM/zTts3GGgpwRJLbPasBmuzAtGgffsas+')

# create a client
client = @config.client

10.times do
  Benchmark.bm do |x|
    x.report('raw') { client.get('events') }
    x.report('oj') { Oj.load(client.get('events').body) }
  end
end
