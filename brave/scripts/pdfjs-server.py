#!/usr/bin/env python3
import http.server
import urllib.request
from urllib.parse import urlparse, parse_qs

PORT = 8080

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)

        # If the browser asks for the /proxy endpoint, Python fetches the PDF
        if parsed.path == '/proxy':
            url = parse_qs(parsed.query).get('url', [None])[0]
            if url:
                try:
                    # Fetch PDF from Arxiv using Python (bypasses browser CORS completely)
                    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req) as resp:
                        self.send_response(200)
                        self.send_header('Content-Type', 'application/pdf')
                        self.end_headers()
                        self.wfile.write(resp.read()) # Stream directly to viewer
p                    return
                except Exception as e:
                    self.send_error(500, f"Proxy Error: {e}")
                    return

        # Otherwise, serve the normal PDF.js files (viewer.html, etc)
        super().do_GET()

if __name__ == "__main__":
    # ThreadingHTTPServer prevents the viewer from hanging while loading assets
    server = http.server.ThreadingHTTPServer(("", PORT), ProxyHandler)
    print(f"PDF.js Server + Proxy running on http://localhost:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server.")
        server.server_close()
