USE IRCTC;

-- ============================================================
-- View 1: Complete Train Schedule
-- ============================================================

DROP VIEW IF EXISTS v_train_schedule;

CREATE VIEW v_train_schedule AS
SELECT
    t.number AS train_no,
    t.name AS train_name,
    t.type AS train_type,
    r.stop_number,
    s.code AS station_code,
    s.name AS station_name,
    r.arrival,
    r.departure,
    r.distance_km
FROM trains t
JOIN routes r
    ON t.train_id = r.train_id
JOIN stations s
    ON r.station_id = s.station_id;


-- ============================================================
-- View 2: Live Seat Availability (With Quota Support)
-- ============================================================

DROP VIEW IF EXISTS v_seat_availability;

CREATE VIEW v_seat_availability AS
SELECT
    t.number AS train_no,
    t.name AS train_name,
    sc.journey_date,
    sc.status AS run_status,
    c.code AS class_code,
    c.name AS class_name,
    sa.quota,
    sa.total_seats,
    sa.available,
    ROUND(
        (100.0 * sa.available) / NULLIF(sa.total_seats, 0),
        1
    ) AS pct_free
FROM seat_availability sa
JOIN schedules sc
    ON sa.schedule_id = sc.schedule_id
JOIN trains t
    ON sc.train_id = t.train_id
JOIN classes c
    ON sa.class_id = c.class_id;


-- ============================================================
-- View 3: Detailed PNR & Passenger Status Lookup
-- ============================================================

DROP VIEW IF EXISTS v_pnr_status;

CREATE VIEW v_pnr_status AS
SELECT
    b.pnr,
    u.full_name AS booked_by_user,
    p.name AS passenger_name,
    p.age,
    p.gender,
    t.number AS train_no,
    t.name AS train_name,
    sc.journey_date,
    st_from.code AS origin_station,
    st_to.code AS dest_station,
    c.code AS class_code,
    p.seat_no,
    b.quota,
    p.status AS passenger_status,
    b.status AS pnr_status,
    pay.amount AS total_paid,
    pay.status AS payment_status
FROM bookings b
JOIN users u
    ON b.user_id = u.user_id
JOIN passengers p
    ON b.booking_id = p.booking_id
JOIN schedules sc
    ON b.schedule_id = sc.schedule_id
JOIN trains t
    ON sc.train_id = t.train_id
JOIN stations st_from
    ON b.from_station_id = st_from.station_id
JOIN stations st_to
    ON b.to_station_id = st_to.station_id
JOIN classes c
    ON p.class_id = c.class_id
LEFT JOIN payments pay
    ON b.booking_id = pay.booking_id;


-- ============================================================
-- View 4: Net Revenue Per Train Per Journey
-- ============================================================

DROP VIEW IF EXISTS v_revenue_by_run;

CREATE VIEW v_revenue_by_run AS
SELECT
    t.number AS train_no,
    t.name AS train_name,
    sc.journey_date,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    SUM(pay.amount) AS gross_revenue,
    SUM(pay.refund_amount) AS total_refunded,
    SUM(pay.amount - pay.refund_amount) AS net_revenue
FROM schedules sc
JOIN trains t
    ON sc.train_id = t.train_id
JOIN bookings b
    ON sc.schedule_id = b.schedule_id
JOIN payments pay
    ON b.booking_id = pay.booking_id
WHERE pay.status IN ('SUCCESS', 'REFUNDED')
GROUP BY
    t.number,
    t.name,
    sc.journey_date;


-- ============================================================
-- View 5: Waitlisted Passengers Monitoring
-- ============================================================

DROP VIEW IF EXISTS v_waitlist;

CREATE VIEW v_waitlist AS
SELECT
    b.pnr,
    p.name AS passenger_name,
    u.phone AS user_phone,
    t.number AS train_no,
    sc.journey_date,
    c.code AS class_code,
    b.quota,
    sa.available AS seats_now_free
FROM bookings b
JOIN users u
    ON b.user_id = u.user_id
JOIN passengers p
    ON b.booking_id = p.booking_id
JOIN schedules sc
    ON b.schedule_id = sc.schedule_id
JOIN trains t
    ON sc.train_id = t.train_id
JOIN classes c
    ON p.class_id = c.class_id
LEFT JOIN seat_availability sa
    ON sa.schedule_id = sc.schedule_id
   AND sa.class_id = p.class_id
   AND sa.quota = b.quota
WHERE p.status = 'WAITLIST' OR b.status = 'WAITLIST';