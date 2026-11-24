const { createElement: h } = require("react");

const rupees = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR" });

function Report({ title, id, headers, rows }) {
  const body = rows.length
    ? rows.map(({ key, cells }) => h("tr", { key }, cells.map((cell, i) => h("td", { key: headers[i] }, cell))))
    : h("tr", null, h("td", { colSpan: headers.length }, "No records."));
  return h("section", { id },
    h("h2", { id: id + "-title" }, title),
    h("div", { className: "table-wrap" }, h("table", { "aria-labelledby": id + "-title" },
      h("thead", null, h("tr", null, headers.map(header => h("th", { key: header, scope: "col" }, header)))),
      h("tbody", null, body))));
}

function Dashboard({ rooms, complaints, payments }) {
  const occupied = rooms.reduce((n, room) => n + room.occupied_beds, 0);
  const available = rooms.reduce((n, room) => n + (room.availability ? Math.max(0, room.vacant_beds) : 0), 0);
  const unresolved = complaints.filter(row => !row.resolved_on).length;
  const stats = [["Resident beds occupied", occupied], ["Beds open for allocation", available],
                 ["Unresolved complaints", unresolved]];
  const roomRows = rooms.map(r => ({
    key: r.wing_id + "/" + r.room_no,
    cells: [r.wing_name, r.room_no, r.occupied_beds, r.capacity,
            r.availability ? r.vacant_beds : "Closed"],
  }));
  const tickets = complaints.map(c => ({
    key: c.comp_id,
    cells: [c.comp_id, c.type || "Unspecified", c.status, c.reporting_date, c.resolved_on || "—"],
  }));
  const ledger = payments.map(p => ({
    key: p.month + "/" + p.payer_type,
    cells: [p.month, p.payer_type, p.payments, rupees.format(Number(p.amount))],
  }));
  return h("html", { lang: "en" },
    h("head", null, h("meta", { charSet: "utf-8" }),
      h("meta", { name: "viewport", content: "width=device-width, initial-scale=1" }),
      h("title", null, "Hostel management"), h("link", { rel: "stylesheet", href: "/assets/dashboard.css" })),
    h("body", null, h("main", null,
      h("header", null, h("h1", null, "Hostel management"),
        h("nav", { "aria-label": "Reports" },
          h("a", { href: "#rooms" }, "Rooms"), h("a", { href: "#complaints" }, "Complaints"),
          h("a", { href: "#payments" }, "Payments"))),
      h("dl", { className: "stats" }, stats.map(([label, n]) => h("div", { key: label }, h("dt", null, label), h("dd", null, n)))),
      h(Report, { title: "Room occupancy", id: "rooms", headers: ["Wing", "Room", "Occupied", "Capacity", "Vacant"], rows: roomRows }),
      h(Report, { title: "Complaints", id: "complaints", headers: ["ID", "Category", "Status", "Reported", "Resolved"], rows: tickets }),
      h(Report, { title: "Fee collections", id: "payments", headers: ["Month", "Payer", "Payments", "Amount"], rows: ledger }))));
}

module.exports = Dashboard;
