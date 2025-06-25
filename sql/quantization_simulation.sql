## 2. **策略效果模拟（SQL）**
-- **目标**：量化优化策略的潜在收益
-- 策略1：长提前期订单定金政策
WITH policy_simulation AS (
  SELECT 
    hotel,
    is_canceled,
    lead_time,
    deposit_type,
    adr,
		-- 计算入住天数：周末入住天数 + 工作日入住天数
    stays_in_weekend_nights + stays_in_week_nights AS stayed_nights, 
    CASE 
      WHEN lead_time > 180 AND deposit_type = 'Non Refund' 
      THEN 0.65  -- 假设收取定金后取消率下降35%
      ELSE is_canceled 
    END AS simulated_cancel
  FROM hotel_bookings_processed
  WHERE hotel = 'City Hotel'
)
SELECT 
  AVG(is_canceled) AS original_cancel_rate,
  AVG(simulated_cancel) AS simulated_cancel_rate,
  SUM(adr * stayed_nights) * (AVG(is_canceled) - AVG(simulated_cancel)) AS estimated_revenue_gain
FROM policy_simulation;


-- 策略2：高危渠道优化
-- 策略 2：高危渠道优化
SELECT 
    market_segment,
    cancel_rate,
    total_bookings,
    total_revenue,
    total_revenue * 0.25 AS potential_savings  -- 假设减少 25% 该渠道订单
FROM (
    SELECT 
        market_segment,
        AVG(is_canceled) AS cancel_rate,
        COUNT(*) AS total_bookings,
        -- 计算总收益：adr *（周末入住天数 + 工作日入住天数） 的总和
        SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)) AS total_revenue  
    FROM hotel_bookings_processed
    WHERE hotel = 'City Hotel'
    GROUP BY market_segment
) seg_data
WHERE cancel_rate > 0.4;
