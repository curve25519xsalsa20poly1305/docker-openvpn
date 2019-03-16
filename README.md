# OpenVPN Docker Tunnel

Wraps your program with OpenVPN network tunnel fully contained in Docker. This allows you to have multiple OpenVPN connections in different containers serving different programs running inside them.

Supports latest Docker for both Windows, Linux, and MacOS.

### Related Projects

* [openvpn-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-tunnel)) - This project.
* [openvpn-socks5](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-socks5/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5)) - Expose a SOCKS5 proxy server on your host port to serve programs on your host machine that can connect to a SOCKS5 proxy.
* [shadowsocksr-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocksr-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocksr-tunnel)) - Wraps your program with ShadowsocksR network tunnel fully contained in Docker. Also exposes SOCKS5 server to host machine.

## What it does?

1. It reads in an OpenVPN configuration file (`.ovpn`) from a mounted file, specified through `OPENVPN_CONFIG` environment variable.
2. It starts the OpenVPN client program to establish the VPN connection.
3. It optionally runs the executable defined by `OPENVPN_UP` when the VPN connection is stable.
4. It optionally runs the user specified CMD line from `docker run` positional arguments ([see Docker doc](https://docs.docker.com/engine/reference/run/#cmd-default-command-or-options)). The program will use the VPN connection inside the container.
5. If user has provided CMD line, and `DAEMON_MODE` environment variable is not set to `true`, then after running the CMD line, it will shutdown the OpenVPN client and terminate the container.

## How to use?

Prepare your OpenVPN configuration file with `.ovpn` extension, which you can usually get from your VPN provider's website.

If you want to specify OpenVPN username and password, you can change the line in your `.ovpn` configuration with `auth-user-pass` to `auth-user-pass secret`, then create a file named `secret` at the same directory as your `.ovpn` configuration file. `secret` file should contain two lines, where first line is your username, and second line is your password.

### Simple Example

The following example will run `curl ifconfig.co/json` through VPN configured in `./vpn.ovpn` on host machine.

```bash
# Unix
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "${PWD}":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    curve25519xsalsa20poly1305/openvpn-tunnel \
    curl ifconfig.co/json

# Windows
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN ^
    -v "%CD%":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn ^
    curve25519xsalsa20poly1305/openvpn-tunnel ^
    curl ifconfig.co/json
```

### Daemon Mode

You can leave the VPN connection running in background, and later use `docker exec` to run your program inside the running container without ever closing and repoening your VPN connection multiple times. Just leave out the CMD line when you start the container with `docker run`, it will automatically enter daemon mode.

```bash
# Unix
NAME="myvpn"
docker run --name "${NAME}" -dit --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "${PWD}":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    curve25519xsalsa20poly1305/openvpn-tunnel

# Windows
SET NAME="myvpn"
docker run --name "%NAME%" -dit --rm --device=/dev/net/tun --cap-add=NET_ADMIN ^
    -v "%PWD%":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn ^
    curve25519xsalsa20poly1305/openvpn-tunnel
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

To stop the daemon, run this:

```bash
# Unix
NAME="myvpn"
docker stop "${NAME}"

# Windows
SET NAME="myvpn"
docker stop "%NAME%"
```

### Extends Image

This image only includes `curl` and `wget` for most basic HTTP request usage. If the program you want to run is not available in this image, you can easily extend this image to include anything you need.

Here is a very simple example `Dockerfile` that will install [aria2](http://aria2.github.io/) in its derived image.

```Dockerfile
FROM curve25519xsalsa20poly1305/openvpn-tunnel
RUN apk add --no-cache aria2
```

Build this image with:

```bash
# Unix & Windows
docker build -t openvpn-aria2 .
```

Finally run it with

```bash
# Unix
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "${PWD}":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    -v "${PWD}":/downloads:rw \
    -w /downloads \
    openvpn-aria2 \
    arai2c http://example.com/index.html

# Windows
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -v "%CD%":/vpn:ro -e OPENVPN_CONFIG=/vpn/vpn.ovpn \
    -v "%CD%":/downloads:rw \
    -w /downloads \
    openvpn-aria2 \
    arai2c http://example.com/index.html
```

It will download the file using `aria2c` to your host's current directory.

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
