-- =====================================================
-- DWS层（Data Warehouse Summary - 汇总数据层）
-- 功能：轻度汇总、多维度聚合
-- 特点：按天汇总，宽表设计
-- =====================================================

-- 创建DWS数据库
CREATE DATABASE IF NOT EXISTS dws;

-- =====================================================
-- 1. 用户日汇总表
-- =====================================================
DROP TABLE IF EXISTS dws.dws_user_day_summary;
CREATE TABLE IF NOT EXISTS dws.dws_user_day_summary (
    user_id         BIGINT          COMMENT '用户ID',
    user_name       STRING          COMMENT '用户姓名',
    user_level      STRING          COMMENT '用户等级',
    region_name     STRING          COMMENT '地区名称',
    order_count     INT             COMMENT '订单数',
    order_amount    DECIMAL(12,2)   COMMENT '订单金额',
    pay_amount      DECIMAL(12,2)   COMMENT '实付金额',
    quantity        INT             COMMENT '购买商品数量',
    behavior_view   INT             COMMENT '浏览次数',
    behavior_click  INT             COMMENT '点击次数',
    behavior_collect INT            COMMENT '收藏次数',
    behavior_cart   INT             COMMENT '加购次数'
)
COMMENT '用户日汇总表-DWS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 用户日汇总表数据加载
INSERT OVERWRITE TABLE dws.dws_user_day_summary PARTITION(dt='${dt}')
SELECT 
    u.user_id,
    u.user_name,
    u.user_level,
    u.region_name,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(o.order_amount, 0) AS order_amount,
    COALESCE(o.pay_amount, 0) AS pay_amount,
    COALESCE(o.quantity, 0) AS quantity,
    COALESCE(b.behavior_view, 0) AS behavior_view,
    COALESCE(b.behavior_click, 0) AS behavior_click,
    COALESCE(b.behavior_collect, 0) AS behavior_collect,
    COALESCE(b.behavior_cart, 0) AS behavior_cart
FROM dwd.dwd_dim_user_info u
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(total_amount) AS order_amount,
        SUM(pay_amount) AS pay_amount,
        SUM(quantity) AS quantity
    FROM dwd.dwd_fact_order_detail
    WHERE dt = '${dt}' AND order_status IN ('已支付', '已发货', '已完成')
    GROUP BY user_id
) o ON u.user_id = o.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(CASE WHEN action_type = 'view' THEN 1 ELSE 0 END) AS behavior_view,
        SUM(CASE WHEN action_type = 'click' THEN 1 ELSE 0 END) AS behavior_click,
        SUM(CASE WHEN action_type = 'collect' THEN 1 ELSE 0 END) AS behavior_collect,
        SUM(CASE WHEN action_type = 'cart' THEN 1 ELSE 0 END) AS behavior_cart
    FROM dwd.dwd_fact_user_behavior
    WHERE dt = '${dt}'
    GROUP BY user_id
) b ON u.user_id = b.user_id
WHERE u.dt = '${dt}';

-- =====================================================
-- 2. 商品日汇总表
-- =====================================================
DROP TABLE IF EXISTS dws.dws_product_day_summary;
CREATE TABLE IF NOT EXISTS dws.dws_product_day_summary (
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    category_name   STRING          COMMENT '分类名称',
    brand_name      STRING          COMMENT '品牌名称',
    order_count     INT             COMMENT '订单数',
    quantity        INT             COMMENT '销售数量',
    total_amount    DECIMAL(12,2)   COMMENT '销售额',
    discount_amount DECIMAL(12,2)   COMMENT '优惠金额',
    pay_amount      DECIMAL(12,2)   COMMENT '实付金额',
    profit_amount   DECIMAL(12,2)   COMMENT '利润金额',
    behavior_view   INT             COMMENT '浏览次数',
    behavior_click  INT             COMMENT '点击次数',
    behavior_collect INT            COMMENT '收藏次数',
    behavior_cart   INT             COMMENT '加购次数'
)
COMMENT '商品日汇总表-DWS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 商品日汇总表数据加载
INSERT OVERWRITE TABLE dws.dws_product_day_summary PARTITION(dt='${dt}')
SELECT 
    p.product_id,
    p.product_name,
    p.category_name,
    p.brand_name,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(o.quantity, 0) AS quantity,
    COALESCE(o.total_amount, 0) AS total_amount,
    COALESCE(o.discount_amount, 0) AS discount_amount,
    COALESCE(o.pay_amount, 0) AS pay_amount,
    COALESCE(o.profit_amount, 0) AS profit_amount,
    COALESCE(b.behavior_view, 0) AS behavior_view,
    COALESCE(b.behavior_click, 0) AS behavior_click,
    COALESCE(b.behavior_collect, 0) AS behavior_collect,
    COALESCE(b.behavior_cart, 0) AS behavior_cart
FROM dwd.dwd_dim_product_info p
LEFT JOIN (
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(quantity) AS quantity,
        SUM(total_amount) AS total_amount,
        SUM(discount_amount) AS discount_amount,
        SUM(pay_amount) AS pay_amount,
        SUM(pay_amount - quantity * (SELECT cost FROM dwd.dwd_dim_product_info WHERE product_id = dwd.dwd_fact_order_detail.product_id AND dt = '${dt}' LIMIT 1)) AS profit_amount
    FROM dwd.dwd_fact_order_detail
    WHERE dt = '${dt}' AND order_status IN ('已支付', '已发货', '已完成')
    GROUP BY product_id
) o ON p.product_id = o.product_id
LEFT JOIN (
    SELECT 
        product_id,
        SUM(CASE WHEN action_type = 'view' THEN 1 ELSE 0 END) AS behavior_view,
        SUM(CASE WHEN action_type = 'click' THEN 1 ELSE 0 END) AS behavior_click,
        SUM(CASE WHEN action_type = 'collect' THEN 1 ELSE 0 END) AS behavior_collect,
        SUM(CASE WHEN action_type = 'cart' THEN 1 ELSE 0 END) AS behavior_cart
    FROM dwd.dwd_fact_user_behavior
    WHERE dt = '${dt}'
    GROUP BY product_id
) b ON p.product_id = b.product_id
WHERE p.dt = '${dt}';

-- =====================================================
-- 3. 交易日汇总表
-- =====================================================
DROP TABLE IF EXISTS dws.dws_trade_day_summary;
CREATE TABLE IF NOT EXISTS dws.dws_trade_day_summary (
    order_date      DATE            COMMENT '订单日期',
    order_count     BIGINT          COMMENT '订单数',
    order_user_count BIGINT         COMMENT '下单用户数',
    order_product_count BIGINT     COMMENT '下单商品数',
    quantity        BIGINT          COMMENT '销售数量',
    total_amount    DECIMAL(14,2)   COMMENT '订单金额',
    discount_amount DECIMAL(14,2)   COMMENT '优惠金额',
    pay_amount      DECIMAL(14,2)   COMMENT '实付金额',
    profit_amount   DECIMAL(14,2)   COMMENT '利润金额',
    avg_order_amount DECIMAL(10,2)  COMMENT '客单价'
)
COMMENT '交易日汇总表-DWS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 交易日汇总表数据加载
INSERT OVERWRITE TABLE dws.dws_trade_day_summary PARTITION(dt='${dt}')
SELECT 
    order_date,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT user_id) AS order_user_count,
    COUNT(DISTINCT product_id) AS order_product_count,
    SUM(quantity) AS quantity,
    SUM(total_amount) AS total_amount,
    SUM(discount_amount) AS discount_amount,
    SUM(pay_amount) AS pay_amount,
    SUM(pay_amount - quantity * cost) AS profit_amount,
    ROUND(SUM(pay_amount) / COUNT(DISTINCT order_id), 2) AS avg_order_amount
FROM (
    SELECT 
        o.order_id,
        o.order_date,
        o.user_id,
        o.product_id,
        o.quantity,
        o.total_amount,
        o.discount_amount,
        o.pay_amount,
        p.cost
    FROM dwd.dwd_fact_order_detail o
    LEFT JOIN dwd.dwd_dim_product_info p ON o.product_id = p.product_id AND p.dt = '${dt}'
    WHERE o.dt = '${dt}' AND o.order_status IN ('已支付', '已发货', '已完成')
) t
GROUP BY order_date;
