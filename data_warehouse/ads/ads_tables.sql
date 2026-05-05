-- =====================================================
-- ADS层（Application Data Store - 应用数据层）
-- 功能：业务指标计算、报表输出
-- 特点：面向应用，高度聚合
-- =====================================================

-- 创建ADS数据库
CREATE DATABASE IF NOT EXISTS ads;

-- =====================================================
-- 销售概览表（同步至阿里云RDS）
-- =====================================================
DROP TABLE IF EXISTS ads.ads_sales_overview;
CREATE TABLE IF NOT EXISTS ads.ads_sales_overview (
    stat_date       DATE            COMMENT '统计日期',
    stat_type       STRING          COMMENT '统计类型(日/周/月)',
    order_count     BIGINT          COMMENT '订单数',
    order_user_count BIGINT         COMMENT '下单用户数',
    new_user_count  BIGINT          COMMENT '新增用户数',
    total_amount    DECIMAL(14,2)   COMMENT '订单金额',
    pay_amount      DECIMAL(14,2)   COMMENT '实付金额',
    discount_amount DECIMAL(14,2)   COMMENT '优惠金额',
    profit_amount   DECIMAL(14,2)   COMMENT '利润金额',
    avg_order_amount DECIMAL(10,2)  COMMENT '客单价',
    profit_margin   DECIMAL(5,2)    COMMENT '毛利率',
    pay_rate        DECIMAL(5,2)    COMMENT '支付率'
)
COMMENT '销售概览表-ADS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 销售概览表数据加载（日统计）
INSERT OVERWRITE TABLE ads.ads_sales_overview PARTITION(dt='${dt}')
SELECT 
    t.order_date AS stat_date,
    '日' AS stat_type,
    t.order_count,
    t.order_user_count,
    COALESCE(n.new_user_count, 0) AS new_user_count,
    t.total_amount,
    t.pay_amount,
    t.discount_amount,
    t.profit_amount,
    t.avg_order_amount,
    CASE 
        WHEN t.pay_amount > 0 THEN ROUND(t.profit_amount / t.pay_amount * 100, 2)
        ELSE 0
    END AS profit_margin,
    CASE 
        WHEN t.total_amount > 0 THEN ROUND(t.pay_amount / t.total_amount * 100, 2)
        ELSE 0
    END AS pay_rate
FROM dws.dws_trade_day_summary t
LEFT JOIN (
    SELECT 
        TO_DATE(register_time) AS register_date,
        COUNT(*) AS new_user_count
    FROM ods.ods_user_info
    WHERE dt = '${dt}'
    GROUP BY TO_DATE(register_time)
) n ON t.order_date = n.register_date
WHERE t.dt = '${dt}';

-- 销售概览表数据加载（周统计）
INSERT INTO TABLE ads.ads_sales_overview PARTITION(dt='${dt}')
SELECT 
    DATE_SUB(TO_DATE('${dt}'), 6) AS stat_date,
    '周' AS stat_type,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(new_user_count) AS new_user_count,
    SUM(total_amount) AS total_amount,
    SUM(pay_amount) AS pay_amount,
    SUM(discount_amount) AS discount_amount,
    SUM(profit_amount) AS profit_amount,
    ROUND(AVG(avg_order_amount), 2) AS avg_order_amount,
    CASE 
        WHEN SUM(pay_amount) > 0 THEN ROUND(SUM(profit_amount) / SUM(pay_amount) * 100, 2)
        ELSE 0
    END AS profit_margin,
    CASE 
        WHEN SUM(total_amount) > 0 THEN ROUND(SUM(pay_amount) / SUM(total_amount) * 100, 2)
        ELSE 0
    END AS pay_rate
FROM ads.ads_sales_overview
WHERE dt = '${dt}' AND stat_type = '日'
AND stat_date >= DATE_SUB(TO_DATE('${dt}'), 6);

-- 销售概览表数据加载（月统计）
INSERT INTO TABLE ads.ads_sales_overview PARTITION(dt='${dt}')
SELECT 
    DATE_SUB(TO_DATE('${dt}'), 29) AS stat_date,
    '月' AS stat_type,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(new_user_count) AS new_user_count,
    SUM(total_amount) AS total_amount,
    SUM(pay_amount) AS pay_amount,
    SUM(discount_amount) AS discount_amount,
    SUM(profit_amount) AS profit_amount,
    ROUND(AVG(avg_order_amount), 2) AS avg_order_amount,
    CASE 
        WHEN SUM(pay_amount) > 0 THEN ROUND(SUM(profit_amount) / SUM(pay_amount) * 100, 2)
        ELSE 0
    END AS profit_margin,
    CASE 
        WHEN SUM(total_amount) > 0 THEN ROUND(SUM(pay_amount) / SUM(total_amount) * 100, 2)
        ELSE 0
    END AS pay_rate
FROM ads.ads_sales_overview
WHERE dt = '${dt}' AND stat_type = '日'
AND stat_date >= DATE_SUB(TO_DATE('${dt}'), 29);
