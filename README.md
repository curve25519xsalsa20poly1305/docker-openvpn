# OpenVPN to SOCKS5/HTTP Proxy Docker Image

Convers OpenVPN connection to SOCKS5/HTTP proxy in Docker. This allows you to have multiple proxies on different ports connecting to different OpenVPN upstreams.

Supports latest Docker for both Windows, Linux, and MacOS.

## Related Projects

-   [OpenVPN](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn))
-   [WireGuard](https://hub.docker.com/r/curve25519xsalsa20poly1305/wireguard/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-wireguard))
-   [Shadowsocks/ShadowsocksR](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks))

## What it does?

1. It reads in an OpenVPN configuration file (`.ovpn`) from a mounted file, specified through `OPENVPN_CONFIG` environment variable.
2. It starts the OpenVPN client program to establish the VPN connection.
3. It optionally runs the executable defined by `OPENVPN_UP` when the VPN connection is stable.
4. It starts [3proxy](https://3proxy.ru/) server and listen on container-scoped port 1080 for SOCKS5 and 3128 for HTTP proxy on default. Proxy authentication can be enabled with `PROXY_USER` and `PROXY_PASS` environment variables. `SOCKS5_PROXY_PORT` and `HTTP_PROXY_PORT` can be used to change the default ports. For multi-user support, use sequence of `PROXY_USER_1`, `PROXY_PASS_1`, `PROXY_USER_2`, `PROXY_PASS_2`, etc.
5. It optionally runs the executable defined by `PROXY_UP` when the proxy server is ready.
6. If `ARIA2_PORT` is defined, it starts an aria2 RPC server on the port, and optionally runs the executable defined by `ARIA2_UP`.
7. It optionally runs the user specified CMD line from `docker run` positional arguments ([see Docker doc](https://docs.docker.com/engine/reference/run/#cmd-default-command-or-options)). The program will use the VPN connection inside the container.
8. If user has provided CMD line, and `DAEMON_MODE` environment variable is not set to `true`, then after running the CMD line, it will shutdown the OpenVPN client and terminate the container.

## How to use?

Prepare your OpenVPN configuration file with `.ovpn` extension, which you can usually get from your VPN provider's website.

If you want to specify OpenVPN username and password, you can change the line in your `.ovpn` configuration with `auth-user-pass` to `auth-user-pass secret`, then create a file named `secret` at the same directory as your `.ovpn` configuration file. `secret` file should contain two lines, where first line is your username, and second line is your password.

Proxy server options are specified through these container environment variables:

-   `SOCKS5_PROXY_PORT` (Default: `"1080"`) - SOCKS5 server listening port
-   `HTTP_PROXY_PORT` (Default: `"3128"`) - HTTP proxy server listening port
-   `PROXY_USER` (Default: `""`) - Proxy server authentication username
-   `PROXY_PASS` (Default: `""`) - Proxy server authentication password
-   `PROXY_USER_<N>` (Default: `""`) - The `N`-th username for multi-user proxy authentication. `N` starts from 1.
-   `PROXY_PASS_<N>` (Default: `""`) - The `N`-th password for multi-user proxy authentication. `N` starts from 1.
-   `PROXY_UP` (Default: `""`) - optional command to be executed when proxy server becomes stable

Arai2 options are specified through these container environment variables:

-   `ARIA2_PORT` (Default: `""`) - JSON-RPC server listening port
-   `ARIA2_PASS` (Default: `""`) - `--rpc-secret` password
-   `ARIA2_PATH` (Default: `"."`) - The directory to store the downloaded file
-   `ARIA2_ARGS` (Default: `""`) - BASH-style escaped command line to append to the `aria2c` command
-   `ARIA2_UP` (Default: `""`) - optional command to be executed when aria2 JSON-RPC server becomes stable

Other container environment variables:

-   `DAEMON_MODE` (Default: `"false"`) - force enter daemon mode when CMD line is specified

### Simple Example

The following example will run `curl ifconfig.co/json` through VPN configured in `./vpn.ovpn` on host machine.

```bash
# Unix
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "${PWD}":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    curve25519xsalsa20poly1305/openvpn \
    curl ifconfig.co/json

# Windows
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN ^
    -v "%CD%":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn ^
    curve25519xsalsa20poly1305/openvpn ^
    curl ifconfig.co/json
```

### Daemon Mode

You can leave the VPN connection running in background, and later use `docker exec` to run your program inside the running container without ever closing and repoening your VPN connection multiple times. Just leave out the CMD line when you start the container with `docker run`, it will automatically enter daemon mode.

```bash
# Unix
NAME="myvpn"
PORT="7777"
docker run --name "${NAME}" -dit --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "${PWD}":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    -p "${PORT}":1080 \
    curve25519xsalsa20poly1305/openvpn

# Windows
SET NAME="myvpn"
SET PORT="7777"
docker run --name "%NAME%" -dit --rm --device=/dev/net/tun --cap-add=NET_ADMIN ^
    -v "%PWD%":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn ^
    -p "%PORT%":1080 ^
    curve25519xsalsa20poly1305/openvpn
```

Then you run commads using `docker exec`:

```bash
# Unix
NAME="myvpn"
docker exec -it "${NAME}" curl ifconfig.co/json

# Windows
SET NAME="myvpn"
docker exec -it "%NAME%" curl ifconfig.co/json
```

Or use the SOCKS5 server available on host machine:

```bash
curl ifconfig.co/json -x socks5h://127.0.0.1:7777
```

To stop the daemon, run this:

```bash
# Unix
NAME="myvpn"
docker stop "${NAME}"

# Windows
SET NAME="myvpn"
docker stop "%NAME%"
```

## Contributing

Please feel free to contribute to this project. But before you do so, just make
sure you understand the following:

1\. Make sure you have access to the official repository of this project where
the maintainer is actively pushing changes. So that all effective changes can go
into the official release pipeline.

2\. Make sure your editor has [EditorConfig](https://editorconfig.org/) plugin
installed and enabled. It's used to unify code formatting style.

3\. Use [Conventional Commits 1.0.0-beta.2](https://conventionalcommits.org/) to
format Git commit messages.

4\. Use [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
as Git workflow guideline.

5\. Use [Semantic Versioning 2.0.0](https://semver.org/) to tag release
versions.

## License

Copyright © 2019 curve25519xsalsa20poly1305 &lt;<curve25519xsalsa20poly1305@gmail.com>&gt;

This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.
