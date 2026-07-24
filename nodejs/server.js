const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok' }));
        return;
    }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
        message: 'Hello from the Node.js container!',
        path: req.url,
        timestamp: new Date().toISOString()
    }));
});

server.listen(PORT, () => {
    console.log(`Node.js server listening on port ${PORT}`);
});
