USE IRCTC;

DELIMITER //

DROP PROCEDURE IF EXISTS sp_book_ticket //

CREATE PROCEDURE sp_book_ticket(
    IN p_user_id INT,
    IN p_schedule_id INT,
    IN p_from_station_id INT,
    IN p_to_station_id INT,
    IN p_class_id INT,
    IN p_quota VARCHAR(15),
    IN p_passenger_name VARCHAR(80),
    IN p_passenger_age INT,
    IN p_passenger_gender CHAR(1),
    IN p_fare DECIMAL(10,2),
    IN p_pnr VARCHAR(10)
)
BEGIN
    DECLARE v_available INT;
    DECLARE v_booking_id INT;

    -- Rollback handler if any SQL error occurs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking failed due to a database/transaction error.';
    END;

    START TRANSACTION;

    -- 1. Pessimistic Row Lock: Read available seats while blocking concurrent writes on this row
    SELECT available INTO v_available
    FROM seat_availability
    WHERE schedule_id = p_schedule_id 
      AND class_id = p_class_id 
      AND quota = p_quota
    FOR UPDATE;

    -- 2. Verify availability
    IF v_available > 0 THEN
        -- Decrement seat count safely
        UPDATE seat_availability
        SET available = available - 1
        WHERE schedule_id = p_schedule_id 
          AND class_id = p_class_id 
          AND quota = p_quota;

        -- Create booking
        INSERT INTO bookings (pnr, user_id, schedule_id, from_station_id, to_station_id, quota, total_fare, status)
        VALUES (p_pnr, p_user_id, p_schedule_id, p_from_station_id, p_to_station_id, p_quota, p_fare, 'CONFIRMED');

        SET v_booking_id = LAST_INSERT_ID();

        -- Insert passenger details
        INSERT INTO passengers (booking_id, class_id, name, age, gender, status)
        VALUES (v_booking_id, p_class_id, p_passenger_name, p_passenger_age, p_passenger_gender, 'CONFIRMED');

        COMMIT;
    ELSE
        -- No seats remaining
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking failed: Seats are sold out for this class/quota.';
    END IF;

END //

DELIMITER ;