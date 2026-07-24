CREATE DATABASE IF NOT EXISTS IRCTC;
USE IRCTC;

-- Disable FK checks temporarily for clean initialization
SET FOREIGN_KEY_CHECKS = 0;

-- Clear existing tables (ordered by dependency)
DROP TABLE IF EXISTS physical_seats;
DROP TABLE IF EXISTS train_coaches;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS passengers;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS seat_availability;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS trains;
DROP TABLE IF EXISTS stations;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. Master Tables
-- ============================================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stations (
    station_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(6) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(60) NOT NULL,
    state VARCHAR(60) NOT NULL
);

CREATE TABLE trains (
    train_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(6) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL
);

CREATE TABLE classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(4) NOT NULL UNIQUE,
    name VARCHAR(40) NOT NULL,
    fare_per_km DECIMAL(6,2) NOT NULL,
    CHECK (fare_per_km > 0)
);

-- ============================================================
-- 2. Physical Layout & Coach Master
-- ============================================================

CREATE TABLE train_coaches (
    coach_id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    coach_number VARCHAR(10) NOT NULL,
    class_id INT NOT NULL,
    total_seats INT NOT NULL DEFAULT 72,

    CONSTRAINT fk_coach_train FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    CONSTRAINT fk_coach_class FOREIGN KEY (class_id) REFERENCES classes(class_id),
    CONSTRAINT uq_train_coach UNIQUE (train_id, coach_number)
);

CREATE TABLE physical_seats (
    seat_id INT AUTO_INCREMENT PRIMARY KEY,
    coach_id INT NOT NULL,
    seat_number INT NOT NULL,
    berth_type VARCHAR(15) NOT NULL,

    CONSTRAINT fk_seat_coach FOREIGN KEY (coach_id) REFERENCES train_coaches(coach_id) ON DELETE CASCADE,
    CONSTRAINT uq_coach_seat UNIQUE (coach_id, seat_number),
    CHECK (berth_type IN ('LOWER', 'MIDDLE', 'UPPER', 'SIDE_LOWER', 'SIDE_UPPER', 'WINDOW', 'NO_PREF'))
);

-- ============================================================
-- 3. Train Routes & Schedules
-- ============================================================

CREATE TABLE routes (
    route_id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    station_id INT NOT NULL,
    stop_number INT NOT NULL,
    arrival TIME,
    departure TIME,
    distance_km INT NOT NULL,

    CONSTRAINT fk_route_train FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    CONSTRAINT fk_route_station FOREIGN KEY (station_id) REFERENCES stations(station_id),
    CONSTRAINT uq_train_stop UNIQUE (train_id, stop_number),
    CONSTRAINT uq_train_station UNIQUE (train_id, station_id),
    CHECK (distance_km >= 0)
);

CREATE TABLE schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    journey_date DATE NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'ON_TIME',

    CONSTRAINT fk_schedule_train FOREIGN KEY (train_id) REFERENCES trains(train_id),
    CONSTRAINT uq_train_date UNIQUE (train_id, journey_date),
    CHECK (status IN ('ON_TIME', 'DELAYED', 'CANCELLED'))
);

CREATE TABLE seat_availability (
    avail_id INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT NOT NULL,
    class_id INT NOT NULL,
    quota VARCHAR(15) NOT NULL DEFAULT 'GENERAL',
    total_seats INT NOT NULL,
    available INT NOT NULL,

    CONSTRAINT fk_avail_schedule FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id) ON DELETE CASCADE,
    CONSTRAINT fk_avail_class FOREIGN KEY (class_id) REFERENCES classes(class_id),
    CONSTRAINT uq_schedule_class_quota UNIQUE (schedule_id, class_id, quota),
    CHECK (quota IN ('GENERAL', 'TATKAL', 'LADIES', 'SENIOR_CITIZEN')),
    CHECK (total_seats >= 0),
    CHECK (available >= 0),
    CHECK (available <= total_seats)
);

-- ============================================================
-- 4. Bookings, Passengers & Payments
-- ============================================================

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    pnr VARCHAR(10) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    schedule_id INT NOT NULL,
    from_station_id INT NOT NULL,
    to_station_id INT NOT NULL,
    quota VARCHAR(15) NOT NULL DEFAULT 'GENERAL',
    total_fare DECIMAL(10,2) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'CONFIRMED',
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_booking_schedule FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id),
    CONSTRAINT fk_booking_from_station FOREIGN KEY (from_station_id) REFERENCES stations(station_id),
    CONSTRAINT fk_booking_to_station FOREIGN KEY (to_station_id) REFERENCES stations(station_id),
    CHECK (quota IN ('GENERAL', 'TATKAL', 'LADIES', 'SENIOR_CITIZEN')),
    CHECK (status IN ('CONFIRMED', 'WAITLIST', 'RAC', 'CANCELLED')),
    CHECK (total_fare >= 0)
);

CREATE TABLE passengers (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    class_id INT NOT NULL,
    name VARCHAR(80) NOT NULL,
    age INT NOT NULL,
    gender CHAR(1) NOT NULL,
    seat_no VARCHAR(12),
    berth_preference VARCHAR(15),
    status VARCHAR(12) NOT NULL DEFAULT 'CONFIRMED',

    CONSTRAINT fk_passenger_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_passenger_class FOREIGN KEY (class_id) REFERENCES classes(class_id),
    CHECK (age > 0 AND age < 120),
    CHECK (gender IN ('M', 'F', 'O')),
    CHECK (status IN ('CONFIRMED', 'WAITLIST', 'RAC', 'CANCELLED'))
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    transaction_id VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    refund_amount DECIMAL(10,2) DEFAULT 0.00,
    method VARCHAR(15) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'SUCCESS',
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CHECK (amount >= 0),
    CHECK (refund_amount >= 0),
    CHECK (method IN ('UPI', 'CARD', 'NETBANKING', 'WALLET')),
    CHECK (status IN ('SUCCESS', 'PENDING', 'FAILED', 'REFUNDED'))
);

-- ============================================================
-- 5. High-Performance Non-Conflicting Composite Indexes
-- ============================================================

-- Optimizes searching route stops for a train
CREATE INDEX idx_route_stops 
ON routes(station_id, stop_number);

-- Optimizes user booking history lookups
CREATE INDEX idx_user_history 
ON bookings(user_id, booked_at);

-- Optimizes passenger lookup per booking
CREATE INDEX idx_passenger_booking 
ON passengers(booking_id, status);