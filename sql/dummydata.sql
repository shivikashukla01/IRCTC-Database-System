USE IRCTC;

-- Disable Foreign Key checks temporarily to allow clean batch inserts
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE payments;
TRUNCATE TABLE passengers;
TRUNCATE TABLE bookings;
TRUNCATE TABLE seat_availability;
TRUNCATE TABLE physical_seats;
TRUNCATE TABLE train_coaches;
TRUNCATE TABLE schedules;
TRUNCATE TABLE routes;
TRUNCATE TABLE classes;
TRUNCATE TABLE trains;
TRUNCATE TABLE stations;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. Users (IRCTC Account Holders)
-- ============================================================
INSERT INTO users (user_id, full_name, email, phone) VALUES
(1, 'Vivek Sharma', 'vivek@example.com', '9810011111'),
(2, 'Ananya Rao', 'ananya@example.com', '9820022222'),
(3, 'Rahul Menon', 'rahul@example.com', '9830033333'),
(4, 'Priya Nair', 'priya@example.com', '9840044444'),
(5, 'Amit Kumar', 'amit@example.com', '9850055555');

-- ============================================================
-- 2. Stations
-- ============================================================
INSERT INTO stations (station_id, code, name, city, state) VALUES
(1, 'NDLS', 'New Delhi', 'Delhi', 'Delhi'),
(2, 'BCT', 'Mumbai Central', 'Mumbai', 'Maharashtra'),
(3, 'HWH', 'Howrah Junction', 'Kolkata', 'West Bengal'),
(4, 'MAS', 'Chennai Central', 'Chennai', 'Tamil Nadu'),
(5, 'SBC', 'KSR Bengaluru', 'Bengaluru', 'Karnataka'),
(6, 'CNB', 'Kanpur Central', 'Kanpur', 'Uttar Pradesh'),
(7, 'BPL', 'Bhopal Junction', 'Bhopal', 'Madhya Pradesh'),
(8, 'NGP', 'Nagpur Junction', 'Nagpur', 'Maharashtra');

-- ============================================================
-- 3. Trains
-- ============================================================
INSERT INTO trains (train_id, number, name, type) VALUES
(1, '12951', 'Mumbai Rajdhani', 'Rajdhani'),
(2, '12301', 'Howrah Rajdhani', 'Rajdhani'),
(3, '12002', 'Bhopal Shatabdi', 'Shatabdi'),
(4, '12621', 'Tamil Nadu Express', 'Superfast'),
(5, '12627', 'Karnataka Express', 'Superfast');

-- ============================================================
-- 4. Classes
-- ============================================================
INSERT INTO classes (class_id, code, name, fare_per_km) VALUES
(1, '1A', 'First AC', 4.50),
(2, '2A', 'Second AC', 2.80),
(3, '3A', 'Third AC', 1.90),
(4, 'SL', 'Sleeper', 0.80),
(5, 'CC', 'Chair Car', 1.60),
(6, '2S', 'Second Sitting', 0.50);

-- ============================================================
-- 5. Physical Coaches & Seat Layout
-- ============================================================
INSERT INTO train_coaches (coach_id, train_id, coach_number, class_id, total_seats) VALUES
(1, 1, 'H1', 1, 24),  -- Mumbai Rajdhani 1A
(2, 1, 'A1', 2, 48),  -- Mumbai Rajdhani 2A
(3, 1, 'B1', 3, 64),  -- Mumbai Rajdhani 3A
(4, 3, 'C1', 5, 78);  -- Bhopal Shatabdi CC

INSERT INTO physical_seats (coach_id, seat_number, berth_type) VALUES
(1, 1, 'LOWER'), (1, 2, 'UPPER'), (1, 12, 'LOWER'),
(2, 5, 'SIDE_LOWER'), (2, 6, 'SIDE_UPPER'),
(3, 10, 'MIDDLE'), (3, 11, 'UPPER'),
(4, 18, 'WINDOW'), (4, 19, 'NO_PREF');

-- ============================================================
-- 6. Routes
-- ============================================================
-- Mumbai Rajdhani (BCT → NGP → CNB → NDLS)
INSERT INTO routes (train_id, station_id, stop_number, arrival, departure, distance_km) VALUES
(1, 2, 1, NULL, '17:00:00', 0),
(1, 8, 2, '21:05:00', '21:10:00', 520),
(1, 6, 3, '05:20:00', '05:25:00', 1150),
(1, 1, 4, '08:32:00', NULL, 1384);

-- Bhopal Shatabdi (NDLS → CNB → BPL)
INSERT INTO routes (train_id, station_id, stop_number, arrival, departure, distance_km) VALUES
(3, 1, 1, NULL, '06:00:00', 0),
(3, 6, 2, '08:20:00', '08:25:00', 440),
(3, 7, 3, '13:35:00', NULL, 700);

-- ============================================================
-- 7. Running Schedules
-- ============================================================
INSERT INTO schedules (schedule_id, train_id, journey_date, status) VALUES
(1, 1, '2026-08-01', 'ON_TIME'),
(2, 1, '2026-08-02', 'DELAYED'),
(3, 3, '2026-08-01', 'ON_TIME'),
(4, 4, '2026-08-03', 'CANCELLED');

-- ============================================================
-- 8. Seat Availability (With Quota Support)
-- ============================================================
INSERT INTO seat_availability (schedule_id, class_id, quota, total_seats, available) VALUES
(1, 1, 'GENERAL', 20, 3),
(1, 1, 'TATKAL', 4, 1),
(1, 2, 'GENERAL', 40, 10),
(1, 2, 'TATKAL', 8, 0), -- Sold out
(1, 3, 'GENERAL', 64, 0), -- Sold out (Triggers Waitlist)
(3, 5, 'GENERAL', 78, 30),
(3, 2, 'GENERAL', 52, 22);

-- ============================================================
-- 9. Bookings
-- ============================================================
INSERT INTO bookings (booking_id, pnr, user_id, schedule_id, from_station_id, to_station_id, quota, total_fare, status) VALUES
(1, '4200000001', 1, 1, 2, 1, 'GENERAL', 6228.00, 'CONFIRMED'),  -- Vivek: Mumbai to Delhi
(2, '4200000002', 2, 1, 2, 6, 'GENERAL', 3875.00, 'CONFIRMED'),  -- Ananya: Mumbai to Kanpur
(3, '4200000003', 3, 1, 2, 1, 'GENERAL', 2629.00, 'WAITLIST'),   -- Rahul: Waitlisted
(4, '4200000004', 4, 3, 1, 7, 'GENERAL', 1120.00, 'CONFIRMED'),  -- Priya: Delhi to Bhopal
(5, '4200000005', 5, 1, 2, 1, 'TATKAL', 7500.00, 'CANCELLED');  -- Amit: Cancelled ticket

-- ============================================================
-- 10. Passengers (Multiple Passengers per Booking)
-- ============================================================
INSERT INTO passengers (passenger_id, booking_id, class_id, name, age, gender, seat_no, berth_preference, status) VALUES
-- Booking 1 (Vivek + Family traveling)
(1, 1, 1, 'Vivek Sharma', 29, 'M', 'H1-12', 'LOWER', 'CONFIRMED'),
(2, 1, 1, 'Sunita Sharma', 27, 'F', 'H1-13', 'UPPER', 'CONFIRMED'),

-- Booking 2 (Ananya)
(3, 2, 2, 'Ananya Rao', 34, 'F', 'A1-05', 'SIDE_LOWER', 'CONFIRMED'),

-- Booking 3 (Rahul - Waitlisted)
(4, 3, 3, 'Rahul Menon', 41, 'M', NULL, 'NO_PREF', 'WAITLIST'),

-- Booking 4 (Priya)
(5, 4, 5, 'Priya Nair', 26, 'F', 'C1-18', 'WINDOW', 'CONFIRMED'),

-- Booking 5 (Amit - Cancelled)
(6, 5, 1, 'Amit Kumar', 32, 'M', 'H1-01', 'LOWER', 'CANCELLED');

-- ============================================================
-- 11. Payments (Including Refund Details)
-- ============================================================
INSERT INTO payments (payment_id, booking_id, transaction_id, amount, refund_amount, method, status) VALUES
(1, 1, 'TXN9900112233', 6228.00, 0.00, 'UPI', 'SUCCESS'),
(2, 2, 'TXN9900112234', 3875.00, 0.00, 'CARD', 'SUCCESS'),
(3, 3, 'TXN9900112235', 2629.00, 0.00, 'NETBANKING', 'PENDING'),
(4, 4, 'TXN9900112236', 1120.00, 0.00, 'WALLET', 'SUCCESS'),
(5, 5, 'TXN9900112237', 7500.00, 6500.00, 'UPI', 'REFUNDED'); -- Cancellation with ₹1000 fee deducted