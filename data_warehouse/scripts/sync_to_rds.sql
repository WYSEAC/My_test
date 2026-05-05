-- =====================================================
-- RDS同步脚本
-- 功能：将ADS层销售概览表同步至阿里云RDS
-- =====================================================

-- 目标表结构（MySQL）
-- CREATE TABLE ads_sales_overview (
--     id BIGINT AUTO_INCREMENT PRIMARY KEY,
--     stat_date DATE NOT NULL COMMENT '统计日期',
--     stat_type VARCHAR(10) NOT NULL COMMENT '统计类型(日/周/月)',
--     order_count BIGINT COMMENT '订单数',
--     order_user_count BIGINT COMMENT '下单用户数',
--     new_user_count BIGINT COMMENT '新增用户数',
--     total_amount DECIMAL(14,2) COMMENT '订单金额',
--     pay_amount DECIMAL(14,2) COMMENT '实付金额',
--     discount_amount DECIMAL(14,2) COMMENT '优惠金额',
--     profit_amount DECIMAL(14,2) COMMENT '利润金额',
--     avg_order_amount DECIMAL(10,2) COMMENT '客单价',
--     profit_margin DECIMAL(5,2) COMMENT '毛利率',
--     pay_rate DECIMAL(5,2) COMMENT '支付率',
--     create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     UNIQUE KEY uk_date_type (stat_date, stat_type)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='销售概览表';

-- 数据同步SQL（使用DataX或Sqoop等工具执行）
-- 以下为Hive导出数据的查询语句

-- 导出日统计数据
SELECT 
    stat_date,
    stat_type,
    order_count,
    order_user_count,
    new_user_count,
    total_amount,
    pay_amount,
    discount_amount,
    profit_amount,
    avg_order_amount,
    profit_margin,
    pay_rate
FROM ads.ads_sales_overview
WHERE dt = '${dt}' AND stat_type = '日';

-- 导出周统计数据
SELECT 
    stat_date,
    stat_type,
    order_count,
    order_user_count,
    new_user_count,
    total_amount,
    pay_amount,
    discount_amount,
    profit_amount,
    avg_order_amount,
    profit_margin,
    pay_rate
FROM ads.ads_sales_overview
WHERE dt = '${dt}' AND stat_type = '周';

-- 导出月统计数据
SELECT 
    stat_date,
    stat_type,
    order_count,
    order_user_count,
    new_user_count,
    total_amount,
    pay_amount,
    discount_amount,
    profit_amount,
    avg_order_amount,
    profit_margin,
    pay_rate
FROM ads.ads_sales_overview
WHERE dt = '${dt}' AND stat_type = '月';

-- =====================================================
-- MySQL INSERT 语句（同步后执行）
-- =====================================================
-- INSERT INTO ads_sales_overview (
--     stat_date, stat_type, order_count, order_user_count, 
--     new_user_count, total_amount, pay_amount, discount_amount,
--     profit_amount, avg_order_amount, profit_margin, pay_rate
-- ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
-- ON DUPLICATE KEY UPDATE
--     order_count = VALUES(order_count),
--     order_user_count = VALUES(order_user_count),
--     new_user_count = VALUES(new_user_count),
--     total_amount = VALUES(total_amount),
--     pay_amount = VALUES(pay_amount),
--     discount_amount = VALUES(discount_amount),
--     profit_amount = VALUES(profit_amount),
--     avg_order_amount = VALUES(avg_order_amount),
--     profit_margin = VALUES(profit_margin),
--     pay_rate = VALUES(pay_rate);
