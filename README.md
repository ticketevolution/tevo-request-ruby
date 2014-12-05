# Current Usage

```
$ irb
> load "./api_direct.rb"
> @tevo = TEVO::Connection.new({ :token  => "123", :secret => "324" })
> @tevo.http_request("settings/shipping")
> @tevo.http_request("settings/shipping", params)
```

# Current Options / Defaults

1. method  = %w(GET POST DELETE UPDATE PUT) # defaults to "GET"
1. payload = {endpoint_arguments} (post or get)

# Todo

## HTTP Method Wrapper Fns

```
$ irb
> load "./api_direct.rb"
> tevo = TEVO::Connection.new({:token => TOKEN, :secret => SECRET})
> tevo.get("settings/shipping")
> tevo.post("phone_numbers/update", {:number => 123, :id => 2})
> tevo.get("orders?lightweight=true&abc=123")
> tevo.get("orders", {:lightweight => true, :abc => 123})
