# Icecast 2.5.0 — macOS Apple Silicon Build Guide
Patches and build instructions to compile Icecast 2.5.0 on macOS Sequoia / Tahoe (Apple Silicon / ARM64).
The official Icecast 2.5.0 release has several issues that cause crashes and build failures on macOS with Apple Silicon. This repo contains three patch scripts and a fixed `report-db.xml` that resolve all known issues.

## Issues Fixed
1. **pthread API incompatibility** — `pthread_setname_np()` takes 1 argument on macOS (not 2), and `pthread_condattr_setclock()` does not exist on macOS
2. **Null pointer crash in admin dashboard** — `client_get_reportxml()` returns NULL for missing UUIDs, causing a segfault
3. **Null pointer crash in util_crypt** — `new_algo` can be NULL on macOS when no supported hash algorithms are found
4. **Empty report-db.xml** — The shipped file is blank, causing endless WARN messages in the error log

## Dependencies
```bash
brew install pkg-config libigloo rhash speex theora curl libvorbis libogg openssl@3
```

## Build Instructions
```bash
# Download source
curl -L -o ~/Downloads/icecast-2.5.0.tar.gz https://downloads.xiph.org/releases/icecast/icecast-2.5.0.tar.gz
tar -xzf ~/Downloads/icecast-2.5.0.tar.gz -C ~/Downloads/

# Apply patches
perl patch_thread.pl ~/Downloads/icecast-2.5.0/src/common/thread/thread.c
perl patch_dashboard.pl ~/Downloads/icecast-2.5.0/src/admin.c
perl patch_util_crypt.pl ~/Downloads/icecast-2.5.0/src/util_crypt.c

# Configure and build
cd ~/Downloads/icecast-2.5.0
PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig" ./configure
make -j$(sysctl -n hw.logicalcpu)

# Sign binary (required on macOS)
strip src/icecast
codesign --sign - --force src/icecast
```

## Install
```bash
# Create directory structure
sudo mkdir -p /usr/local/icecast-2.5/{bin,etc,share,log}
sudo chown -R $(whoami):staff /usr/local/icecast-2.5

# Copy binary (never use sudo cp - breaks code signature)
cp ~/Downloads/icecast-2.5.0/src/icecast /usr/local/icecast-2.5/bin/icecast

# Copy web and admin files
cp -R ~/Downloads/icecast-2.5.0/web /usr/local/icecast-2.5/share/
cp -R ~/Downloads/icecast-2.5.0/admin /usr/local/icecast-2.5/share/

# Install fixed report-db.xml
cp report-db.xml /usr/local/icecast-2.5/share/
```

## TLS Configuration — Important Fix

### Intermittent 14-Second Stall with `auto_no_plain` in Icecast 2.5.0

Icecast 2.5.0 has a bug when using `<tls>auto_no_plain</tls>` where the server intermittently drops incoming TLS connections silently after ~14 seconds with no error log entry.

**Symptoms:**
- Client sends TLS Client Hello — server sends nothing back
- Connection times out after ~14 seconds
- OpenSSL clients report: `unexpected eof while reading`
- LibreSSL clients report: `SSL_ERROR_SYSCALL`
- No error appears in Icecast error.log
- HTTP port is always fast — TLS port only affected
- Icecast 2.4.4 on identical hardware/network/cert is not affected

**Fix: Use `RFC2818` instead of `auto_no_plain`**

`RFC2818` is direct TLS socket mode — it skips protocol negotiation entirely, eliminating the stale session ticket issue that causes the hang.

Change your listen-socket from:
```xml
<listen-socket>
    <port>8001</port>
    <tls>auto_no_plain</tls>
</listen-socket>
```

To:
```xml
<listen-socket>
    <port>8001</port>
    <tls>RFC2818</tls>
</listen-socket>
```

After this change all TLS connections are consistently fast. Tested on macOS 15 Sequoia, Apple Silicon, Icecast 2.5.0, OpenSSL 3.6.1.

### TLS Mode Options in Icecast 2.5

| Mode | Description |
|------|-------------|
| `auto` | TLS used if supported, plain HTTP fallback allowed |
| `auto_no_plain` | TLS forced, no plain HTTP — **has intermittent 14s stall bug in 2.5.0** |
| `RFC2818` | Direct TLS socket mode — **recommended** |
| `RFC2817` | HTTP Upgrade mechanism to initiate TLS |

## Tested On
- macOS 15 Sequoia (ARM64 / Apple Silicon)
- Mac Mini and Mac Studio
- Icecast 2.5.0 (official release)

## Notes
- Never use `sudo cp` to copy the binary — it breaks the ad-hoc code signature
- Fix ownership after install: `sudo chown -R $(whoami):staff /usr/local/icecast-2.5`
- The shipped `report-db.xml` is empty — always replace it with the one in this repo
- Use `PKG_CONFIG_PATH` when running configure or libigloo won't be found
- Use `RFC2818` for TLS — `auto_no_plain` has an intermittent 14-second stall bug

## License
Patches and build instructions are MIT licensed. Icecast itself is GPL v2.