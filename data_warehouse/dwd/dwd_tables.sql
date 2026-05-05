-- =====================================================
-- DWD层（Data Warehouse Detail - 明细数据层）
-- 功能：数据清洗、规范化、维度退化，构建事实表
-- 特点：保持明细粒度，进行数据质量处理
-- =====================================================

-- 创建DWD数据库
CREATE DATABASE IF NOT EXISTS dwd;

-- =====================================================
-- 1. 用户维度表（维度退化处理）
-- =====================================================
DROP TABLE IF EXISTS dwd.dwd_dim_user_info;
CREATE TABLE IF NOT EXISTS dwd.dwd_dim_user_info (
    user_id         BIGINT          COMMENT '用户ID',
    user_name       STRING          COMMENT '用户姓名',
    gender          STRING          COMMENT '性别(男/女/未知)',
    age             INT             COMMENT '年龄',
    age_range       STRING          COMMENT '年龄段分组',
    phone           STRING          COMMENT '手机号(脱敏)',
    email           STRING          COMMENT '邮箱(脱敏)',
    register_date   DATE            COMMENT '注册日期',
    user_level      STRING          COMMENT '用户等级',
    region_id       BIGINT          COMMENT '地区ID',
    region_name     STRING          COMMENT '地区名称',
    is_valid        INT             COMMENT '是否有效(0无效/1有效)'
)
COMMENT '用户维度表-DWD层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 用户维度表数据加载
INSERT OVERWRITE TABLE dwd.dwd_dim_user_info PARTITION(dt='${dt}')
SELECT 
    u.user_id,
    u.user_name,
    CASE 
        WHEN u.gender = 'M' THEN '男'
        WHEN u.gender = 'F' THEN '女'
        ELSE '未知'
    END AS gender,
    u.age,
    CASE 
        WHEN u.age < 18 THEN '18岁以下'
        WHEN u.age >= 18 AND u.age < 25 THEN '18-24岁'
        WHEN u.age >= 25 AND u.age < 35 THEN '25-34岁'
        WHEN u.age >= 35 AND u.age < 45 THEN '35-44岁'
        WHEN u.age >= 45 AND u.age < 55 THEN '45-54岁'
        ELSE '55岁以上'
    END AS age_range,
    CONCAT(SUBSTR(u.phone, 1, 3), '****', SUBSTR(u.phone, 8, 4)) AS phone,
    CONCAT(SUBSTR(u.email, 1, 2), '****', SUBSTR(u.email, INSTR(u.email, '@'))) AS email,
    TO_DATE(u.register_time) AS register_date,
    u.user_level,
    u.region_id,
    r.region_name,
    1 AS is_valid
FROM ods.ods_user_info u
LEFT JOIN ods.ods_region_info r ON u.region_id = r.region_id AND r.dt = '${dt}'
WHERE u.dt = '${dt}';

-- =====================================================
-- 2. 商品维度表（维度退化处理）
-- =====================================================
DROP TABLE IF EXISTS dwd.dwd_dim_product_info;
CREATE TABLE IF NOT EXISTS dwd.dwd_dim_product_info (
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    category_id     BIGINT          COMMENT '分类ID',
    category_name   STRING          COMMENT '分类名称',
    brand_id        BIGINT          COMMENT '品牌ID',
    brand_name      STRING          COMMENT '品牌名称',
    supplier_id     BIGINT          COMMENT '供应商ID',
    price           DECIMAL(10,2)   COMMENT '商品价格',
    cost            DECIMAL(10,2)   COMMENT '商品成本',
    profit_margin   DECIMAL(5,2)    COMMENT '毛利率',
    stock_num       INT             COMMENT '库存数量',
    status          STRING          COMMENT '商品状态',
    is_valid        INT             COMMENT '是否有效'
)
COMMENT '商品维度表-DWD层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 商品维度表数据加载
INSERT OVERWRITE TABLE dwd.dwd_dim_product_info PARTITION(dt='${dt}')
SELECT 
    product_id,
    product_name,
    category_id,
    category_name,
    brand_id,
    brand_name,
    supplier_id,
    price,
    cost,
    CASE 
        WHEN price > 0 THEN ROUND((price - cost) / price * 100, 2)
        ELSE 0
    END AS profit_margin,
    stock_num,
    CASE 
        WHEN status = '1' THEN '上架'
        WHEN status = '0' THEN '下架'
        ELSE '未知'
    END AS status,
    CASE 
        WHEN status = '1' AND stock_num > 0 THEN 1
        ELSE 0
    END AS is_valid
FROM ods.ods_product_info
WHERE dt = '${dt}';

-- =====================================================
-- 3. 订单事实表（交易事实）
-- =====================================================
DROP TABLE IF EXISTS dwd.dwd_fact_order_detail;
CREATE TABLE IF NOT EXISTS dwd.dwd_fact_order_detail (
    order_id        BIGINT          COMMENT '订单ID',
    order_no        STRING          COMMENT '订单编号',
    user_id         BIGINT          COMMENT '用户ID',
    user_name       STRING          COMMENT '用户姓名',
    user_level      STRING          COMMENT '用户等级',
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    category_id     BIGINT          COMMENT '分类ID',
    category_name   STRING          COMMENT '分类名称',
    brand_id        BIGINT          COMMENT '品牌ID',
    brand_name      STRING          COMMENT '品牌名称',
    quantity        INT             COMMENT '购买数量',
    unit_price      DECIMAL(10,2)   COMMENT '商品单价',
    total_amount    DECIMAL(10,2)   COMMENT '订单金额',
    discount_amount DECIMAL(10,2)   COMMENT '优惠金额',
    pay_amount      DECIMAL(10,2)   COMMENT '实付金额',
    pay_type        STRING          COMMENT '支付方式',
    pay_time        TIMESTAMP       COMMENT '支付时间',
    order_status    STRING          COMMENT '订单状态',
    region_id       BIGINT          COMMENT '地区ID',
    region_name     STRING          COMMENT '地区名称',
    create_time     TIMESTAMP       COMMENT '下单时间',
    order_date      DATE            COMMENT '下单日期',
    order_hour      INT             COMMENT '下单小时'
)
COMMENT '订单事实表-DWD层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 订单事实表数据加载
INSERT OVERWRITE TABLE dwd.dwd_fact_order_detail PARTITION(dt='${dt}')
SELECT 
    o.order_id,
    o.order_no,
    o.user_id,
    u.user_name,
    u.user_level,
    o.product_id,
    p.product_name,
    p.category_id,
    p.category_name,
    p.brand_id,
    p.brand_name,
    o.quantity,
    o.unit_price,
    o.total_amount,
    o.discount_amount,
    o.pay_amount,
    CASE 
        WHEN o.pay_type = '1' THEN '支付宝'
        WHEN o.pay_type = '2' THEN '微信'
        WHEN o.pay_type = '3' THEN '银行卡'
        ELSE '其他'
    END AS pay_type,
    o.pay_time,
    CASE 
        WHEN o.order_status = '1' THEN '待支付'
        WHEN o.order_status = '2' THEN '已支付'
        WHEN o.order_status = '3' THEN '已发货'
        WHEN o.order_status = '4' THEN '已完成'
        WHEN o.order_status = '5' THEN '已取消'
        ELSE '未知'
    END AS order_status,
    o.region_id,
    r.region_name,
    o.create_time,
    TO_DATE(o.create_time) AS order_date,
    HOUR(o.create_time) AS order_hour
FROM ods.ods_order_detail o
LEFT JOIN dwd.dwd_dim_user_info u ON o.user_id = u.user_id AND u.dt = '${dt}'
LEFT JOIN dwd.dwd_dim_product_info p ON o.product_id = p.product_id AND p.dt = '${dt}'
LEFT JOIN ods.ods_region_info r ON o.region_id = r.region_id AND r.dt = '${dt}'
WHERE o.dt = '${dt}';

-- =====================================================
-- 4. 用户行为事实表（行为事实）
-- =====================================================
DROP TABLE IF EXISTS dwd.dwd_fact_user_behavior;
CREATE TABLE IF NOT EXISTS dwd.dwd_fact_user_behavior (
    log_id          BIGINT          COMMENT '日志ID',
    user_id         BIGINT          COMMENT '用户ID',
    session_id      STRING          COMMENT '会话ID',
    page_id         STRING          COMMENT '页面ID',
    action_type     STRING          COMMENT '行为类型',
    action_name     STRING          COMMENT '行为名称',
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    device_type     STRING          COMMENT '设备类型',
    os_type         STRING          COMMENT '操作系统',
    app_version     STRING          COMMENT 'APP版本',
    ip_address      STRING          COMMENT 'IP地址',
    log_time        TIMESTAMP       COMMENT '日志时间',
    log_date        DATE            COMMENT '日志日期',
    log_hour        INT             COMMENT '日志小时'
)
COMMENT '用户行为事实表-DWD层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- 用户行为事实表数据加载
INSERT OVERWRITE TABLE dwd.dwd_fact_user_behavior PARTITION(dt='${dt}')
SELECT 
    l.log_id,
    l.user_id,
    l.session_id,
    l.page_id,
    l.action_type,
    CASE 
        WHEN l.action_type = 'view' THEN '浏览'
        WHEN l.action_type = 'click' THEN '点击'
        WHEN l.action_type = 'collect' THEN '收藏'
        WHEN l.action_type = 'cart' THEN '加购'
        ELSE '其他'
    END AS action_name,
    l.product_id,
    p.product_name,
    l.device_type,
    l.os_type,
    l.app_version,
    l.ip_address,
    l.log_time,
    TO_DATE(l.log_time) AS log_date,
    HOUR(l.log_time) AS log_hour
FROM ods.ods_user_behavior_log l
LEFT JOIN dwd.dwd_dim_product_info p ON l.product_id = p.product_id AND p.dt = '${dt}'
WHERE l.dt = '${dt}';
