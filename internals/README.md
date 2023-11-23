# Behind the Scenes

## The website

The https://www.bhgc.org website is hosted by GitHub Pages;

```sh
$ host www.bhgc.org
www.bhgc.org is an alias for bhgc.github.io.
bhgc.github.io has address 185.199.108.153
bhgc.github.io has address 185.199.111.153
bhgc.github.io has address 185.199.109.153
bhgc.github.io has address 185.199.110.153
bhgc.github.io has IPv6 address 2606:50c0:8000::153
bhgc.github.io has IPv6 address 2606:50c0:8001::153
bhgc.github.io has IPv6 address 2606:50c0:8002::153
bhgc.github.io has IPv6 address 2606:50c0:8003::153
```


The https://bhgc.org website is hosted by A2Hosting;

```sh
$ host bhgc.org
bhgc.org has address 68.66.200.196
bhgc.org mail is handled by 10 mi3-ss1.a2hosting.com.
```

All requests to https://bhgc.org/, except those under
https://bhgc.org/mailman/, are redirected to https://www.bhgc.org by:

```
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/mailman/
RewriteRule ^(.*)$ http://www.bhgc.org/$1 [R=302,L]
```

See `internals/a2hosting.com/bhgc.org/.htaccess` for all details.


## Email

All email sent to an `<...>@bhgc.org` address, is handled by A2Hosting, per:

```sh
$ host bhgc.org
bhgc.org has address 68.66.200.196
bhgc.org mail is handled by 10 mi3-ss1.a2hosting.com.
```


## The Mailman Mailing lists

The BHGC mailing lists are hosted by A2Hosting on the bhgc.org server.
The Mailman web interfaces are served under https://bhgc.org/mailman/.
Hence the above redirect exclusion rule.
