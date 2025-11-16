const functions = require('firebase-functions/v2/https');

exports.getPremiumReport = functions.onRequest({
  region: 'us-central1',
  cors: true,
}, (req, res) => {
  if (req.method !== 'GET' && req.method !== 'POST') {
    res.status(405).send({ error: 'Method not allowed' });
    return;
  }

  // This mock intentionally omits App Check enforcement in the baseline build.
  const response = {
    score: 73,
    risk: 'medium',
    note: 'sample report',
  };

  res.status(200).send(response);
});
