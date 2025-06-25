-- 1. 酒店对比基础表
-- 创建永久对比分析表
CREATE TABLE hotel_comparison AS
SELECT 
    hotel,
    -- 基础指标
    COUNT(*) AS total_bookings,
    AVG(is_canceled) AS cancel_rate,
    AVG(lead_time) AS avg_lead_time,
    AVG(adr) AS avg_adr,
    
    -- 关键差异指标
    AVG(CASE WHEN deposit_type = 'Non Refund' THEN 1 ELSE 0 END) AS non_refund_ratio,
    AVG(CASE WHEN market_segment = 'Groups' THEN 1 ELSE 0 END) AS groups_channel_ratio,
    AVG(CASE WHEN DATEDIFF(arrival_date, booking_date) > 180 THEN 1 ELSE 0 END) AS long_lead_ratio,
    
    -- 客户行为指标
    AVG(previous_cancellations) AS avg_prev_cancellations,
    AVG(total_of_special_requests) AS avg_special_requests
FROM hotel_bookings_processed
GROUP BY hotel;

-- 1.1 画图数据准备
CREATE TABLE key_factor_comparison AS
SELECT 
    factor_name,
    city_value,
    resort_value,
    city_value / resort_value AS ratio
FROM (
    SELECT 
        'Groups渠道占比' AS factor_name,
        (SELECT groups_channel_ratio FROM hotel_comparison WHERE hotel = 'City Hotel') AS city_value,
        (SELECT groups_channel_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel') AS resort_value
    
    UNION ALL
    
    SELECT 
        '长提前期订单占比',
        (SELECT long_lead_ratio FROM hotel_comparison WHERE hotel = 'City Hotel'),
        (SELECT long_lead_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel')
    
    UNION ALL
    
    SELECT 
        '不可退款政策占比',
        (SELECT non_refund_ratio FROM hotel_comparison WHERE hotel = 'City Hotel'),
        (SELECT non_refund_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel')
    
    UNION ALL
    
    SELECT 
        '取消率',
        (SELECT cancel_rate FROM hotel_comparison WHERE hotel = 'City Hotel'),
        (SELECT cancel_rate FROM hotel_comparison WHERE hotel = 'Resort Hotel')
) AS factors;

-- 1.2 创建统一视图
-- 在数据库中创建整合视图
CREATE VIEW unified_analysis AS
SELECT 
    '原始数据' AS source_type,
    hotel,
    is_canceled,
    lead_time,
    -- 其他原始字段...
    NULL AS factor_name,  -- 新表字段占位
    NULL AS ratio
FROM hotel_bookings_processed

UNION ALL

SELECT 
    '对比指标' AS source_type,
    CASE 
        WHEN factor_name LIKE '%City%' THEN 'City Hotel'
        ELSE 'Resort Hotel'
    END AS hotel,
    NULL AS is_canceled,
    NULL AS lead_time,
    factor_name,
    ratio
FROM key_factor_comparison;


-- 2. 渠道对比分析表
CREATE TABLE channel_comparison AS
SELECT 
    hotel,
    market_segment,
    COUNT(*) AS segment_bookings,
    AVG(is_canceled) AS segment_cancel_rate,
    AVG(adr) AS segment_avg_adr,
    AVG(adr * (1 - is_canceled)) AS segment_net_adr,
    -- 计算渠道对整体取消率的贡献
    (COUNT(*) * AVG(is_canceled)) / 
        (SELECT SUM(is_canceled) FROM hotel_bookings_processed WHERE hotel = main.hotel) 
        AS cancel_contribution
FROM hotel_bookings_processed main
-- WHERE hotel IN ('City Hotel', 'Resort Hotel')
GROUP BY hotel, market_segment
HAVING segment_bookings > 100;  -- 过滤小样本

-- 瀑布图需要重新建表
-- 新逻辑：渠道取消率与酒店平均取消率的差值 × 订单占比
-- 1. 计算酒店平均取消率
WITH hotel_avg AS (
    SELECT 
        hotel,
        AVG(is_canceled) AS hotel_cancel_rate,
        COUNT(*) AS total_bookings
    FROM hotel_bookings_processed
    GROUP BY hotel
),

-- 2. 计算渠道对取消率的影响
channel_impact AS (
    SELECT 
        main.hotel,
        main.market_segment,
        COUNT(*) AS segment_bookings,
        AVG(is_canceled) AS segment_cancel_rate,
        -- 新贡献度：(渠道取消率 - 酒店平均取消率) × 渠道订单占比
        (AVG(is_canceled) - h.hotel_cancel_rate) * (COUNT(*) / h.total_bookings) AS cancel_rate_impact
    FROM hotel_bookings_processed main
    JOIN hotel_avg h ON main.hotel = h.hotel
    GROUP BY main.hotel, main.market_segment, h.hotel_cancel_rate, h.total_bookings
    HAVING segment_bookings > 100
)

-- -- 3. 创建新表
-- CREATE TABLE channel_comparison_impact AS
-- SELECT * FROM channel_impact;
-- 
-- SELECT VERSION()

-- 方法二修正版（MySQL 8.0+ 用）
-- 方法二兼容版（MySQL 5.7 用）
-- CREATE TABLE channel_comparison_impact AS
-- SELECT 
--     main.hotel,
--     main.market_segment,
--     COUNT(*) AS segment_bookings,
--     AVG(is_canceled) AS segment_cancel_rate,
--     (AVG(is_canceled) - h.hotel_cancel_rate) * (COUNT(*) / h.total_bookings) AS cancel_rate_impact
-- FROM hotel_bookings_processed main
-- JOIN (
--     SELECT 
--         hotel,
--         AVG(is_canceled) AS hotel_cancel_rate,
--         COUNT(*) AS total_bookings
--     FROM hotel_bookings_processed
--     GROUP BY hotel
-- ) h ON main.hotel = h.hotel
-- GROUP BY main.hotel, main.market_segment, h.hotel_cancel_rate, h.total_bookings
-- HAVING COUNT(*) > 100;


-- 3. 时间维度对比表
CREATE TABLE timing_comparison AS
SELECT 
    hotel,
    FLOOR(DATEDIFF(reservation_status_date, booking_date)/30) AS cancel_month,
    -- 取消行为指标
    COUNT(*) AS cancel_count,
    AVG(adr) AS avg_cancel_adr,
    -- 计算价格偏差
    AVG(adr) - (SELECT AVG(adr) FROM hotel_bookings_processed p2 
                WHERE p2.hotel = main.hotel AND p2.is_canceled = 0) 
                AS price_deviation
FROM hotel_bookings_processed main
WHERE is_canceled = 1
  -- AND hotel IN ('City Hotel', 'Resort Hotel')
GROUP BY hotel, cancel_month;


-- 4. 客户类型对比表
DROP TABLE customer_comparison;
CREATE TABLE customer_comparison AS
SELECT 
    hotel,
    customer_type,
		
    -- 基础指标
    COUNT(*) AS customer_count,
    AVG(is_canceled) AS cancel_rate,
    AVG(adr) AS avg_adr,
    -- 行为特征
    AVG(lead_time) AS avg_lead_time,
    AVG(previous_cancellations) AS avg_prev_cancellations
		-- 标准化指标
-- 		AVG(lead_time) / MAX(AVG(lead_time)) AS sta_lead_time,
-- 		AVG(adr) / MAX(AVG(adr)) AS sta_adr
-- 		AVG(previous_cancellations) / MAX(AVG(previous_cancellations)) AS sta_previous_cancellations
FROM hotel_bookings_processed
GROUP BY hotel, customer_type;

DROP TABLE IF EXISTS customer_comparison;



-- 5. 押金政策对比表
CREATE TABLE deposit_comparison AS
SELECT 
    hotel,
    deposit_type,
    -- 关键指标
    AVG(lead_time) AS avg_lead_time,
    AVG(DATEDIFF(arrival_date, booking_date)) AS actual_lead_days,
    AVG(CASE WHEN MONTH(arrival_date) IN (7,8) THEN 1 ELSE 0 END) AS summer_ratio,
    COUNT(*) AS bookings,
    AVG(is_canceled) AS cancel_rate
FROM hotel_bookings_processed
GROUP BY hotel, deposit_type;


-- 对比分析专用视图
CREATE VIEW vw_hotel_contrast AS
SELECT 
    'City Hotel' AS hotel_type,
    (SELECT cancel_rate FROM hotel_comparison WHERE hotel = 'City Hotel') AS overall_cancel_rate,
    (SELECT groups_channel_ratio FROM hotel_comparison WHERE hotel = 'City Hotel') AS groups_ratio,
    (SELECT long_lead_ratio FROM hotel_comparison WHERE hotel = 'City Hotel') AS long_lead_ratio,
    (SELECT non_refund_ratio FROM hotel_comparison WHERE hotel = 'City Hotel') AS non_refund_ratio
    
UNION ALL

SELECT 
    'Resort Hotel' AS hotel_type,
    (SELECT cancel_rate FROM hotel_comparison WHERE hotel = 'Resort Hotel'),
    (SELECT groups_channel_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel'),
    (SELECT long_lead_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel'),
    (SELECT non_refund_ratio FROM hotel_comparison WHERE hotel = 'Resort Hotel');
		


-- 创建建模数据集视图（整合所有分析表）
CREATE VIEW model_dataset AS
SELECT 
    b.hotel,
    b.is_canceled AS target,
    
    -- 基础特征
    b.lead_time,
    b.adr,
    b.deposit_type,
    b.customer_type,
    b.market_segment,
    b.previous_cancellations,
    b.required_car_parking_spaces,
    b.total_of_special_requests,
    
    -- 来自hotel_comparison的衍生特征
    hc.long_lead_ratio AS hotel_long_lead_ratio,
    hc.non_refund_ratio AS hotel_non_refund_ratio,
    
    -- 来自key_factor_comparison的特征
    kfc.ratio AS groups_ratio_diff,
    
    -- 来自channel_comparison_impact的特征
    cci.segment_cancel_rate AS channel_cancel_rate,
    cci.cancel_rate_impact AS channel_impact,
    
    -- 来自timing_comparison的特征
    tc.cancel_month,
    tc.price_deviation,
    
    -- 来自customer_comparison的特征
    cc.cancel_rate AS customer_type_cancel_rate,
    cc.avg_adr AS customer_type_avg_adr,
    cc.avg_lead_time AS customer_type_avg_lead_time,
    
    -- 来自deposit_comparison的特征
    dc.avg_lead_time AS deposit_avg_lead_time,
    dc.summer_ratio AS deposit_summer_ratio,
    dc.cancel_rate AS deposit_cancel_rate
    
FROM hotel_bookings_processed b
-- 连接所有分析表
LEFT JOIN hotel_comparison hc ON b.hotel = hc.hotel
LEFT JOIN key_factor_comparison kfc ON kfc.factor_name = 'Groups渠道占比'
LEFT JOIN channel_comparison_impact cci 
    ON b.hotel = cci.hotel AND b.market_segment = cci.market_segment
LEFT JOIN timing_comparison tc 
    ON b.hotel = tc.hotel 
    AND FLOOR(DATEDIFF(b.reservation_status_date, b.booking_date)/30) = tc.cancel_month
LEFT JOIN customer_comparison cc 
    ON b.hotel = cc.hotel AND b.customer_type = cc.customer_type
LEFT JOIN deposit_comparison dc 
    ON b.hotel = dc.hotel AND b.deposit_type = dc.deposit_type
WHERE b.hotel = 'City Hotel'; 

-- 导出为CSV文件
SELECT * 
FROM model_dataset
INTO OUTFILE 'G:\data\Project\Hotel_Booking_Demand\code\city_hotel_model_data.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';