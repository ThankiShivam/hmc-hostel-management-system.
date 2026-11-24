const { before, after, test } = require("node:test");
const assert = require("node:assert/strict");
const { once } = require("node:events");
const { Pool } = require("pg");
const { createApp } = require("../server");

let db, server, root;
before(async () => {
  db = new Pool({ connectionString: process.env.DATABASE_URL });
  server = createApp(db).listen(0, "127.0.0.1");
  await once(server, "listening");
  root = "http://127.0.0.1:" + server.address().port;
});
after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db) await db.end();
});
async function getJson(path) {
  const res = await fetch(root + path);
  assert.equal(res.status, 200);
  return res.json();
}

test("occupancy distinguishes the same room number in two wings", async () => {
  const rooms = await getJson("/api/occupancy");
  assert.deepEqual(rooms.filter(r => r.room_no === 101).map(r => [r.wing_name, r.occupied_beds]),
                   [["North", 2], ["South", 1]]);
});

test("complaints and payments expose the reporting fields", async () => {
  const tickets = await getJson("/api/complaints");
  assert.equal(tickets.filter(t => t.resolved_on === null).length, 2);
  assert.equal(tickets.find(t => t.comp_id === 2).resolved_on, "2025-02-26");
  const totals = await getJson("/api/payments");
  assert.deepEqual(totals.map(r => [r.month, r.payer_type, r.amount]),
    [["2025-04", "student", "4300.00"], ["2025-04", "visitor", "450.00"], ["2025-05", "student", "2500.00"]]);
});

test("the dashboard and its stylesheet load over HTTP", async () => {
  const res = await fetch(root);
  assert.equal(res.status, 200);
  const html = await res.text();
  for (const term of ["Room occupancy", "Unresolved complaints", "Fee collections", "North", "South"]) {
    assert.ok(html.includes(term), term);
  }
  assert.equal((await fetch(root + "/assets/dashboard.css")).status, 200);
});
