// Safaricom Daraja STK Push callback relay for TapVerify.
//
// Daraja POSTs the payment result here (this is the CallBackURL sent with
// every STK Push). We forward the payload to the TapVerify backend when
// MPESA_FORWARD_URL is set in the Vercel dashboard, and always acknowledge
// so Safaricom stops retrying. Without a forward URL the payload is written
// to the function logs so you can still see confirmations arriving.
//
// No secrets live here: the backend holds the M-Pesa credentials.
module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const body = req.body || {};
  const forward = process.env.MPESA_FORWARD_URL;

  if (forward) {
    try {
      const resp = await fetch(forward, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!resp.ok) {
        console.error('forward failed', resp.status, await resp.text());
      }
    } catch (err) {
      console.error('forward error', err && err.message ? err.message : err);
    }
  } else {
    console.log('mpesa callback (set MPESA_FORWARD_URL):',
      JSON.stringify(body).slice(0, 4000));
  }

  // The exact acknowledgement Daraja expects.
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
};
