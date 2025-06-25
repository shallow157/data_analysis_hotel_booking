-- 导入数据表后，发现三列时间格式不对
-- 1. 修改字段为date
ALTER TABLE hotel_bookings_processed
MODIFY COLUMN reservation_status_date DATE;

ALTER TABLE hotel_bookings_processed
MODIFY COLUMN arrival_date DATE;

ALTER TABLE hotel_bookings_processed
MODIFY COLUMN booking_date DATE;

-- 2. 转换字符串为日期格式
UPDATE hotel_bookings_processed
SET reservation_status_date = STR_TO_DATE(reservation_status_date, '%Y-%m-%d'),
    arrival_date = STR_TO_DATE(arrival_date, '%Y-%m-%d'),
    booking_date = STR_TO_DATE(booking_date, '%Y-%m-%d');