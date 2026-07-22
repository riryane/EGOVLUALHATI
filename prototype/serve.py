#!/usr/bin/env python3
"""Dev server for the prototype — like `python3 -m http.server` but with
no-cache headers so edits and DB changes always show up on refresh."""
import http.server, functools, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    http.server.ThreadingHTTPServer(('', PORT), NoCacheHandler).serve_forever()
