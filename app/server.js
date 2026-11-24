const express = require("express");
const path = require("node:path");
const { Pool } = require("pg");
const { createElement } = require("react");
const { renderToStaticMarkup } = require("react-dom/server");
const Dashboard = require("./dashboard");

const reports = {
  occupancy: `
    SELECT wing_id, wing_name, room_no, capacity, availability, occupied_beds, vacant_beds
    FROM hmc.room_occupancy
    ORDER BY wing_name, room_no`,
  complaints: `
    SELECT comp_id, type, status, reporting_date::text, resolved_on::text
    FROM hmc.complaint
    ORDER BY reporting_date DESC, comp_id`,
  payments: `
    SELECT to_char(p.date, 'YYYY-MM') AS month, p.payer_type,
           count(*)::integer AS payments, sum(t.amount)::text AS amount
    FROM hmc.payment p
    JOIN (
      SELECT transaction_id, amount FROM hmc.student_payment
      UNION ALL
      SELECT transaction_id, amount FROM hmc.visitor_payment
    ) t USING (transaction_id)
    GROUP BY 1, 2
    ORDER BY 1, 2`,
};

function createApp(db) {
  const app = express();
  app.disable("x-powered-by");
  app.use("/assets", express.static(path.join(__dirname, "public")));

  for (const [name, query] of Object.entries(reports)) {
    app.get("/api/" + name, async (_req, res) => {
      const { rows } = await db.query(query);
      res.json(rows);
    });
  }

  app.get("/", async (_req, res) => {
    const [occupancy, complaints, payments] = await Promise.all(
      [reports.occupancy, reports.complaints, reports.payments].map(query => db.query(query))
    );
    const html = renderToStaticMarkup(createElement(Dashboard, {
      rooms: occupancy.rows, complaints: complaints.rows, payments: payments.rows,
    }));
    res.type("html").send("<!doctype html>" + html);
  });

  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    // Leave connection strings and database details out of HTTP responses.
    const message = "Hostel data is temporarily unavailable.";
    if (req.path.startsWith("/api/")) return res.status(503).json({ error: message });
    res.status(503).type("text").send(message);
  });
  return app;
}

if (require.main === module) {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000 });
  pool.on("error", error => console.error("PostgreSQL connection error:", error.code));
  const host = process.env.HOST || "127.0.0.1";
  const port = Number(process.env.PORT || 3000);
  const server = createApp(pool).listen(port, host, () => console.log("HMC listening on", host, port));
  const stop = () => server.close(() => pool.end().catch(error => console.error(error.code)));
  process.once("SIGTERM", stop);
  process.once("SIGINT", stop);
}

module.exports = { createApp };
