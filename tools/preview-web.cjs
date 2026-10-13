// Preview the exported game at the same base path as GitHub Pages.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../builds/web');
const base = '/jovian-wake-callisto/';
const port = Number(process.argv[2] || 4175);
const types = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml' };

http.createServer((request, response) => {
  const url = new URL(request.url, 'http://127.0.0.1');
  if (!url.pathname.startsWith(base)) {
    response.writeHead(302, { Location: base });
    response.end();
    return;
  }
  const relative = decodeURIComponent(url.pathname.slice(base.length)) || 'index.html';
  const filename = path.resolve(root, relative);
  if (!filename.startsWith(root + path.sep)) {
    response.writeHead(403);
    response.end();
    return;
  }
  fs.readFile(filename, (error, data) => {
    if (error) {
      response.writeHead(404);
      response.end('Export the Web preset first.');
      return;
    }
    response.writeHead(200, { 'Content-Type': types[path.extname(filename)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    response.end(data);
  });
}).listen(port, '127.0.0.1', () => console.log(`Callisto preview: http://127.0.0.1:${port}${base}`));
