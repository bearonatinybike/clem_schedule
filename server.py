#!/usr/bin/env python3
import http.server, json, os, pathlib

PORT = 8093
BASE = pathlib.Path(__file__).parent
OVERRIDES_FILE = BASE / 'overrides.json'


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BASE), **kwargs)

    def do_GET(self):
        if self.path == '/overrides':
            data = OVERRIDES_FILE.read_text() if OVERRIDES_FILE.exists() else '[]'
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(data.encode())
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/overrides':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            try:
                json.loads(body)
            except json.JSONDecodeError:
                self.send_response(400)
                self.end_headers()
                return
            OVERRIDES_FILE.write_bytes(body)
            self.send_response(204)
            self.end_headers()
        else:
            self.send_response(405)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass


if __name__ == '__main__':
    with http.server.HTTPServer(('', PORT), Handler) as httpd:
        httpd.serve_forever()
