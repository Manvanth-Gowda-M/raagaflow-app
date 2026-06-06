// Server-side CORS Proxy running natively on Vercel's backend runtime (CommonJS format)
module.exports = async function handler(req, res) {
  // Allow all Cross-Origin requests
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const url = req.query.url;
  if (!url) {
    return res.status(400).send('Missing url parameter');
  }

  // Validate the URL to prevent open-proxy abuse
  let parsedUrl;
  try {
    parsedUrl = new URL(url);
    if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
      return res.status(400).send('Only http/https URLs are allowed');
    }
  } catch {
    return res.status(400).send('Invalid URL');
  }

  // 15-second timeout so Vercel doesn't hang on slow Piped/JioSaavn instances
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);

  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept': 'application/json',
      }
    });

    clearTimeout(timeout);

    const data = await response.arrayBuffer();

    // Forward the Content-Type header if present
    const contentType = response.headers.get('content-type');
    if (contentType) {
      res.setHeader('Content-Type', contentType);
    }
    // Never cache proxy responses — always fetch fresh
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');

    res.status(response.status).send(Buffer.from(data));
  } catch (error) {
    clearTimeout(timeout);
    if (error.name === 'AbortError') {
      res.status(504).send('Upstream request timed out');
    } else {
      res.status(500).send(error.message);
    }
  }
};
