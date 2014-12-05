Use this folder to add your own scripts.
It is ```.gitignored```, so secrets will stay ehm..secret.

There is an example file that you can cp:

```bash
$  cp tmp/example.rb tmp/golden-request.rb
```

Then change the token/secret.

There is no cli yet, but feel free to use add scripts like this:
```bash
$ ruby -r './golden-request.rb' -e 'puts @tevo.http_request("settings/shipping")'
```

or hack in the console:
```bash
$ irb -r './golden-request.rb'
> @tevo.http_request('settings/shipping')
```
