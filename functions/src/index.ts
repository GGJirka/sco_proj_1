import { onRequest } from "firebase-functions/v2/https";

export const getPremiumReport = onRequest(
  {
    region: "us-central1",
    cors: true,
  },
  (req, res) => {
    if (req.method !== "GET" && req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // Baseline: no App Check enforcement.
    // Hardened version can add: if (!req.appCheck?.token) return res.status(401)...
    const response = {
      score: 73,
      risk: "medium",
      note: "sample report",
    };

    res.status(200).json(response);
  }
);
