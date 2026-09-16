#!/usr/bin/env python3
"""Print the extension id Chrome derives from the public key in a manifest.

The manifest pins a "key", so the unpacked extension keeps the same id wherever
it is loaded from -- which is what lets the native messaging host allowlist it.
"""
import base64
import hashlib
import json
import sys

manifest = json.load(open(sys.argv[1]))
der = base64.b64decode(manifest["key"])
digest = hashlib.sha256(der).hexdigest()[:32]
print("".join(chr(ord("a") + int(c, 16)) for c in digest))
