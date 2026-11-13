#!/usr/bin/env python3
"""Fetch public weather responses separately from the native macOS renderer."""
import base64
import concurrent.futures
import hashlib
import json
import pathlib
import subprocess
import sys
import time
import urllib.parse


def fetch(address, folder):
    parsed = urllib.parse.urlsplit(address)
    if parsed.scheme != 'https' or parsed.hostname != 'api.open-meteo.com':
        return 'rejected source'
    key = hashlib.sha256(address.encode()).hexdigest()
    output = folder / (key + '.data')
    try:
        result = subprocess.run([
            'curl', '--ipv4', '--fail', '--silent', '--show-error', '--location',
            '--proto', '=https', '--proto-redir', '=https', '--connect-timeout', '8',
            '--max-time', '25', '--retry', '2', '--retry-delay', '1',
            '--retry-max-time', '75', '--max-filesize', '8000000',
            '--user-agent', 'AtelierKindle/0.7.9', '--output', str(output), address,
        ], capture_output=True, timeout=100)
        if result.returncode:
            return 'weather HTTPS unavailable (curl code %s)' % result.returncode
        data = output.read_bytes()
        if len(data) >= 8_000_000:
            return 'weather response too large'
        json.loads(data)  # Do not pass an HTML error document as a successful response.
        entry = dict(url=address, fetchedAt=time.time(), data=base64.b64encode(data).decode())
        (folder / (key + '.json')).write_text(json.dumps(entry))
        return 'weather response prepared'
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        return 'weather unavailable (%s)' % type(error).__name__
    finally:
        output.unlink(missing_ok=True)


def main():
    requests, folder = map(pathlib.Path, sys.argv[1:3])
    folder.mkdir(parents=True, exist_ok=True)
    addresses = json.loads(requests.read_text()) if requests.is_file() else []
    if not isinstance(addresses, list) or len(addresses) > 200 or not all(isinstance(v, str) for v in addresses):
        raise ValueError('invalid source manifest')
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        for message in executor.map(lambda address: fetch(address, folder), dict.fromkeys(addresses)):
            print(message)
    # Always provide a small artifact, even when no weather source is configured.
    (folder / 'status.txt').write_text('Weather preparation finished; renderer validates each response.\n')


if __name__ == '__main__':
    main()
