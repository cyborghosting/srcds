[![Docker Build Status](https://img.shields.io/docker/cloud/build/cyborghosting/srcds.svg)](https://hub.docker.com/r/cyborghosting/srcds/) [![Docker Stars](https://img.shields.io/docker/stars/cyborghosting/srcds.svg)](https://hub.docker.com/r/cyborghosting/srcds/) [![Docker Pulls](https://img.shields.io/docker/pulls/cyborghosting/srcds.svg)](https://hub.docker.com/r/cyborghosting/srcds/) [![](https://img.shields.io/docker/image-size/cyborghosting/srcds)](https://img.shields.io/docker/image-size/cyborghosting/srcds)

# Source Dedicated Server Docker Image

This Docker image provides a ready-to-use environment for running **Source Dedicated Server (srcds)**, Valve's dedicated server software for Source engine games such as Counter-Strike: Global Offensive, Team Fortress 2, Left 4 Dead 2, and more. It leverages SteamCMD to download, install, and update game servers anonymously, automating the process for easy deployment in containers.

## Features

- **Library compatibility**: Includes 32-bit and 64-bit libraries for older Source games.
- **Non-root execution**: Runs as a configurable user via `gosu` with PUID/PGID support.
- **Health monitoring**: Built-in health check using a custom Go binary that queries the server via the A2S protocol.
- **Environment variable support**: Load configurations from a `.env` file in the install directory.
- **Automatic updates**: Validates and updates games on startup.

## Quick Start

Run a basic Counter-Strike: Global Offensive server:

```bash
docker run -d --name srcds \
  -e SRCDS_APP_ID=740 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

Mount a volume to persist game data:

```bash
docker run -d --name srcds \
  -v /host/path:/srcds \
  -e SRCDS_APP_ID=740 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

For interactive testing:

```bash
docker run -it cyborghosting/srcds bash
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PUID` | User ID for file permissions | 1000 | No |
| `PGID` | Group ID for file permissions | 1000 | No |
| `SRCDS_INSTALL_DIR` | Game install directory | `/srcds` | No |
| `SRCDS_APP_ID` | Steam App ID (e.g., 740 for CS:GO, 232250 for TF2) | - | Yes |
| `SRCDS_APP_BETA` | Beta branch for updates | - | No |
| `SRCDS_VALIDATE` | Validate files on update (set to any value) | - | No |
| `USE_DOTENV` | Load `SRCDS_*` vars from `/srcds/.env` (set to 1) | - | No |
| `SRCDS_SECURED` | Enable secure mode (1) or disable (0) | 1 | No |
| `SRCDS_GAME` | Game type (e.g., "csgo") | - | No |
| `SRCDS_STARTMAP` | Starting map (e.g., "de_dust2") | - | No |
| `SRCDS_MAXPLAYERS` | Maximum players | - | No |
| `SRCDS_FPSMAX` | Maximum FPS | - | No |
| `SRCDS_TICKRATE` | Server tickrate | - | No |
| `SRCDS_TIMEOUT` | Connection timeout | - | No |
| `SRCDS_IP` | Server IP address | - | No |
| `SRCDS_PORT` | Server port | 27015 | No |
| `SRCDS_CLIENTPORT` | Client port | 27005 | No |
| `SRCDS_HOSTPORT` | Host port | 27015 | No |
| `SRCDS_TV_PORT` | SourceTV port | 27020 | No |
| `SRCDS_PW` | Server password | - | No |
| `SRCDS_RCONPW` | RCON password | - | No |
| `SRCDS_TOKEN` | Steam account token for VAC | - | No |
| `SRCDS_NORESTART` | Disable auto-restart | - | No |
| `SRCDS_ADDITIONAL_ARGS` | Extra arguments for `srcds_run` | - | No |

## Ports

Expose the following UDP ports as needed:

- `SRCDS_PORT` (default 27015): Main server port for queries.
- `SRCDS_CLIENTPORT` (default 27005): Client connections.
- `SRCDS_HOSTPORT` (default 27015): Host port.
- `SRCDS_TV_PORT` (default 27020): SourceTV port.

Example: `-p 27015:27015/udp -p 27005:27005/udp -p 27020:27020/udp`

## Usage Examples

### Counter-Strike: Global Offensive Server
```bash
docker run -d --name csgo-server \
  -v /opt/csgo:/srcds \
  -e SRCDS_APP_ID=740 \
  -e SRCDS_GAME=csgo \
  -e SRCDS_MAXPLAYERS=12 \
  -e SRCDS_STARTMAP=de_dust2 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

### Team Fortress 2 Server
```bash
docker run -d --name tf2-server \
  -v /opt/tf2:/srcds \
  -e SRCDS_APP_ID=232250 \
  -e SRCDS_GAME=tf \
  -e SRCDS_MAXPLAYERS=24 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

### Using .env File
Create a `.env` file with variables, mount it, and enable loading:

```bash
echo "SRCDS_APP_ID=740" > /host/.env
docker run -d --name srcds \
  -v /host/.env:/srcds/.env \
  -e USE_DOTENV=1 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

### Custom User Permissions
```bash
docker run -d --name srcds \
  -e PUID=1001 \
  -e PGID=1001 \
  -e SRCDS_APP_ID=740 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

## Health Check

The container includes a built-in health check implemented as a custom Go binary (built from `healthcheck/healthcheck.go`). It runs automatically with the following parameters:

- **Interval**: 10 seconds
- **Retries**: 6 (fails after 6 consecutive failures)
- **Timeout**: Default Docker timeout (30 seconds per check)

The health check performs the following steps:

1. Verifies the `SRCDS_PORT` environment variable is set.
2. Checks the `SRCDS_PID_FILE` environment variable (default: `/tmp/srcds.pid`) to ensure the server process is running.
3. Queries the server using the A2S (App to Server) protocol via UDP to retrieve game information.
4. Validates the response includes game name, hostname, current map, and player count/max players.

On success, it logs details like: `GAME: csgo, HOSTNAME: myserver, MAP: de_dust2, PLAYERS: 5/12` and exits with code 0.

The check fails (exits with code 1) if:
- Required environment variables are missing.
- The PID file doesn't exist or the process is not alive.
- The A2S query fails (e.g., server not responding, network issues).

The binary uses the `github.com/rumblefrog/go-a2s` library for A2S queries and standard Go libraries for process checking.

### Customizing Health Check

You can override the default health check parameters using Docker's health-related flags when running the container. The health check command (`/healthcheck`) remains the same, but you can adjust timing and retry behavior.

Available options:
- `--health-interval`: Time between checks (default: 10s)
- `--health-timeout`: Timeout for each check (default: 30s)
- `--health-retries`: Number of consecutive failures before marking unhealthy (default: 6)
- `--health-start-period`: Initial delay before starting checks (default: 0s)
- `--no-healthcheck`: Disable health checks entirely

Examples:

```bash
# Increase interval to 30 seconds with 3 retries
docker run -d --name srcds \
  --health-interval=30s \
  --health-retries=3 \
  -e SRCDS_APP_ID=740 \
  -p 27015:27015/udp \
  cyborghosting/srcds

# Disable health checks
docker run -d --name srcds \
  --no-healthcheck \
  -e SRCDS_APP_ID=740 \
  -p 27015:27015/udp \
  cyborghosting/srcds
```

Note: The health check relies on `SRCDS_PORT` (default: 27015) and `SRCDS_PID_FILE` (default: `/tmp/srcds.pid`). If you change these environment variables, ensure the health check can access the correct port and PID file.

## Troubleshooting

- **Permission errors**: Ensure PUID/PGID match the host user owning the mounted volume.
- **Port conflicts**: Verify no other services use the exposed ports.
- **SteamCMD failures**: Check container logs for update errors; ensure internet access.
- **Health check failures**: Confirm server is running and ports are correctly exposed; check for firewall issues.
- **Game not starting**: Verify `SRCDS_APP_ID` and other required variables; try interactive mode for debugging.

## Contributing

Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/cyborg-hosting/srcds).

## License

MIT License - Copyright 2025 Cyborg Hosting
