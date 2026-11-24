# Source and schema notes

The ER diagram, relational diagram, normalization analysis and retrieval questions accompanied a university DBMS submission. The submitted query report and sample-data header credit a five-member course group. Shivam Thanki maintains this repository.

The diagram PDFs reproduce the supplied diagrams. The public normalization document uses synthetic student numbers in its attendance example. The query catalog renders all 29 reporting questions against the current schema. It uses consecutive numbers because the submitted report repeated several query numbers. The database ships with fictional records and reserved example email addresses.

## Reading the academic design alongside the SQL

| Design topic | Rule in the runnable database |
| --- | --- |
| Room identity | Rooms use the pair `(wing_id, room_no)`. Student and visitor room references require both fields together. |
| Optional identifiers | Student email and visitor identity number can be absent. Their unique constraints apply to recorded values. |
| Parcel identity | `parcel_id` is the primary key. The attribute list at the end of the academic document reflects an earlier draft. |
| Maintenance | `assigned_by` records who assigned the work. A terminal complaint has a `resolved_on` date, which makes resolution duration measurable. |
| Payment specialization | The parent declares its payer type. Each payment subtype has a generated type column and a composite foreign key to the parent. Inserts and updates use the same constraint, including concurrent writes. |
| Attendance | `(student_id, date)` permits one observation per student per day. The weekly attendance report uses recorded observations as its denominator. |
| Visit dates | The current-stay report treats checkout as the departure date. A missing checkout on an approved, already-started stay leaves it open. |

The schema and field names used by the dashboard and tests are defined in [db/schema.sql](../db/schema.sql).
