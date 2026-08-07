#!/usr/bin/env python3
import http.server
import urllib.request
from urllib.parse import urlparse, parse_qs

PORT = 8080
# security: only accepts connections from your own machine
HOST = "127.0.0.1"
# security: hardcoded path, safe to run from anywhere
BASE_DIR = "/usr/share/pdf.js"

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    # overwrite initialization to always serve out of the PDF.js directory
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path == '/proxy':
            url = parse_qs(parsed.query).get('url', [None])[0]
            if url:
                # security: strictly whitelist allowed domains (Prevents SSRF and file:// access)
                target_parsed = urlparse(url)
                allowed_domains = ("arxiv.org", "www.arxiv.org", "export.arxiv.org")

                if target_parsed.netloc not in allowed_domains:
                    self.send_error(403, "Forbidden: Only arXiv URLs are allowed.")
                    return

                try:
                    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req) as resp:
                        self.send_response(200)
                        self.send_header('Content-Type', 'application/pdf')
                        self.end_headers()
                        self.wfile.write(resp.read())
                    return
                except Exception as e:
                    self.send_error(500, f"Proxy Error: {e}")
                    return
            else:
                self.send_error(400, "Bad Request: Missing URL")
                return

        super().do_GET()

if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer((HOST, PORT), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
