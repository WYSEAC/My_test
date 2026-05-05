-- =====================================================
-- ODS层（Operation Data Store - 操作数据层）
-- 功能：保持与源系统数据结构一致，进行数据接入和简单清洗
-- 特点：接近源系统数据，保留历史数据
-- =====================================================

-- 创建ODS数据库
CREATE DATABASE IF NOT EXISTS ods;

-- =====================================================
-- 1. 用户信息表（来自业务系统用户表）
-- =====================================================
DROP TABLE IF EXISTS ods.ods_user_info;
CREATE TABLE IF NOT EXISTS ods.ods_user_info (
    user_id         BIGINT          COMMENT '用户ID',
    user_name       STRING          COMMENT '用户姓名',
    gender          STRING          COMMENT '性别',
    age             INT             COMMENT '年龄',
    phone           STRING          COMMENT '手机号',
    email           STRING          COMMENT '邮箱',
    register_time   TIMESTAMP       COMMENT '注册时间',
    user_level      STRING          COMMENT '用户等级',
    region_id       BIGINT          COMMENT '地区ID',
    etl_time        TIMESTAMP       COMMENT 'ETL处理时间'
)
COMMENT '用户信息表-ODS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- =====================================================
-- 2. 商品信息表（来自商品管理系统）
-- =====================================================
DROP TABLE IF EXISTS ods.ods_product_info;
CREATE TABLE IF NOT EXISTS ods.ods_product_info (
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    category_id     BIGINT          COMMENT '分类ID',
    category_name   STRING          COMMENT '分类名称',
    brand_id        BIGINT          COMMENT '品牌ID',
    brand_name      STRING          COMMENT '品牌名称',
    supplier_id     BIGINT          COMMENT '供应商ID',
    price           DECIMAL(10,2)   COMMENT '商品价格',
    cost            DECIMAL(10,2)   COMMENT '商品成本',
    stock_num       INT             COMMENT '库存数量',
    status          STRING          COMMENT '商品状态',
    create_time     TIMESTAMP       COMMENT '创建时间',
    etl_time        TIMESTAMP       COMMENT 'ETL处理时间'
)
COMMENT '商品信息表-ODS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- =====================================================
-- 3. 订单明细表（来自交易系统）
-- =====================================================
DROP TABLE IF EXISTS ods.ods_order_detail;
CREATE TABLE IF NOT EXISTS ods.ods_order_detail (
    order_id        BIGINT          COMMENT '订单ID',
    order_no        STRING          COMMENT '订单编号',
    user_id         BIGINT          COMMENT '用户ID',
    product_id      BIGINT          COMMENT '商品ID',
    product_name    STRING          COMMENT '商品名称',
    quantity        INT             COMMENT '购买数量',
    unit_price      DECIMAL(10,2)   COMMENT '商品单价',
    total_amount    DECIMAL(10,2)   COMMENT '订单金额',
    discount_amount DECIMAL(10,2)   COMMENT '优惠金额',
    pay_amount      DECIMAL(10,2)   COMMENT '实付金额',
    pay_type        STRING          COMMENT '支付方式',
    pay_time        TIMESTAMP       COMMENT '支付时间',
    order_status    STRING          COMMENT '订单状态',
    region_id       BIGINT          COMMENT '地区ID',
    create_time     TIMESTAMP       COMMENT '下单时间',
    etl_time        TIMESTAMP       COMMENT 'ETL处理时间'
)
COMMENT '订单明细表-ODS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- =====================================================
-- 4. 地区信息表（来自基础数据系统）
-- =====================================================
DROP TABLE IF EXISTS ods.ods_region_info;
CREATE TABLE IF NOT EXISTS ods.ods_region_info (
    region_id       BIGINT          COMMENT '地区ID',
    region_name     STRING          COMMENT '地区名称',
    parent_id       BIGINT          COMMENT '父级地区ID',
    region_level    INT             COMMENT '地区层级(1省/2市/3区)',
    etl_time        TIMESTAMP       COMMENT 'ETL处理时间'
)
COMMENT '地区信息表-ODS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;

-- =====================================================
-- 5. 用户行为日志表（来自埋点日志系统）
-- =====================================================
DROP TABLE IF EXISTS ods.ods_user_behavior_log;
CREATE TABLE IF NOT EXISTS ods.ods_user_behavior_log (
    log_id          BIGINT          COMMENT '日志ID',
    user_id         BIGINT          COMMENT '用户ID',
    session_id      STRING          COMMENT '会话ID',
    page_id         STRING          COMMENT '页面ID',
    action_type     STRING          COMMENT '行为类型(浏览/点击/收藏/加购)',
    product_id      BIGINT          COMMENT '商品ID',
    device_type     STRING          COMMENT '设备类型',
    os_type         STRING          COMMENT '操作系统',
    app_version     STRING          COMMENT 'APP版本',
    ip_address      STRING          COMMENT 'IP地址',
    log_time        TIMESTAMP       COMMENT '日志时间',
    etl_time        TIMESTAMP       COMMENT 'ETL处理时间'
)
COMMENT '用户行为日志表-ODS层'
PARTITIONED BY (dt STRING COMMENT '日期分区')
STORED AS ORC;
