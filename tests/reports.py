"""Check room joins, boundary cases and aggregates in the shipped report catalog."""

import csv
from decimal import Decimal
from io import StringIO
from pathlib import Path
import re
import subprocess
import unittest

CATALOG = (Path(__file__).resolve().parents[1] / "db" / "reports.sql").read_text()
PARTS = re.split(r"(?m)^-- (\d{2})\. [^\n]+\n", CATALOG)[1:]
QUERIES = {int(n): sql.strip().removesuffix("COMMIT;") for n, sql in zip(PARTS[::2], PARTS[1::2])}


def rows(number):
    command = "BEGIN READ ONLY;\nSET LOCAL search_path TO hmc, pg_catalog;\n" + QUERIES[number] + "\nROLLBACK;"
    result = subprocess.run(["psql", "-X", "-q", "--csv", "-v", "ON_ERROR_STOP=1"],
                            input=command, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return list(csv.DictReader(StringIO(result.stdout)))


class ReportTests(unittest.TestCase):
    def test_all_report_numbers_are_unique_and_consecutive(self):
        self.assertEqual(list(QUERIES), list(range(1, 30)))
        self.assertEqual(len(PARTS), 58)

    def test_active_residents_and_attendance_use_the_right_wing(self):
        residents = rows(1)
        self.assertEqual([(r["student_id"], r["wing_name"]) for r in residents],
                         [("101", "North"), ("102", "North"), ("103", "South")])
        self.assertEqual([(r["student_id"], r["wing_name"]) for r in rows(27)],
                         [("101", "North"), ("103", "South")])

    def test_available_inventory_and_empty_wing(self):
        self.assertEqual({(r["wing_name"], r["room_no"], r["vacant_beds"]) for r in rows(2)},
                         {("North", "102", "2"), ("South", "101", "2"), ("South", "102", "1")})
        annex = next(r for r in rows(6) if r["wing_name"] == "Annex")
        self.assertEqual((annex["rooms"], annex["beds"]), ("0", "0"))

    def test_visitors_with_duplicate_room_numbers(self):
        self.assertEqual([(r["visitor_id"], r["wing_name"], r["room_no"]) for r in rows(17)],
                         [("1", "South", "102")])
        self.assertEqual(len(rows(21)), 2)

    def test_resolved_duration_and_attendance_denominator(self):
        electrical = next(r for r in rows(14) if r["type"] == "Electrical")
        self.assertEqual(Decimal(electrical["avg_resolution_days"]), Decimal(2))
        attendance = {r["student_id"]: r for r in rows(29)}
        self.assertEqual(attendance["101"]["attendance_pct"], "66.67")
        self.assertEqual(attendance["105"]["attendance_pct"], "")


if __name__ == "__main__":
    unittest.main()
