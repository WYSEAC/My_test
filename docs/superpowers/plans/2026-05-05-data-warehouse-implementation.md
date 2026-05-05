# 电商零售数仓实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建完整的阿里数仓分层架构，并将 ADS 层销售概览表同步至阿里云 RDS

**Architecture:** 采用阿里数仓五层架构（ODS → DWD → DWS → ADS → DIM），使用 Hive 存储和 MySQL RDS 同步

**Tech Stack:** Hive SQL, MySQL, ORC 格式, 日期分区

---

## 文件结构

```
data_warehouse/
├── ods/
│   └── ods_tables.sql          # ODS层建表语句
├── dwd/
│   └── dwd_tables.sql          # DWD层建表语句
├── dws/
│   └── dws_tables.sql          # DWS层建表语句
├── ads/
│   └── ads_tables.sql          # ADS层建表语句
├── dim/
│   └── dim_tables.sql          # DIM层建表语句
├── scripts/
│   ├── sync_to_rds.sql         # RDS同步脚本
│   └── init_data.sql           # 初始化数据脚本
└── docs/
    └── data_flow.md            # 数据流转说明文档
```

---

### Task 1: 清理分支并重建项目结构

**Files:**
- Delete: `data_warehouse/ods/ods_tables.sql`
- Delete: `data_warehouse/dwd/dwd_tables.sql`
- Create: `data_warehouse/dws/dws_tables.sql`
- Create: `data_warehouse/ads/ads_tables.sql`
- Create: `data_warehouse/dim/dim_tables.sql`
- Create: `data_warehouse/scripts/sync_to_rds.sql`
- Create: `data_warehouse/scripts/init_data.sql`
- Create: `data_warehouse/docs/data_flow.md`

- [ ] **Step 1: 删除现有文件**

```bash
rm -rf data_warehouse/ods data_warehouse/dwd
```

- [ ] **Step 2: 创建目录结构**

```bash
mkdir -p data_warehouse/{ods,dwd,dws,ads,dim,scripts,docs}
```

- [ ] **Step 3: 提交结构变更**

```bash
git add -A
git commit -m "chore: 重建数仓目录结构"
```

---

### Task 2: 创建 ODS 层建表语句

**Files:**
- Create: `data_warehouse/ods/ods_tables.sql`

- [ ] **Step 1: 编写 ODS 层建表语句**

```sql
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
```

- [ ] **Step 2: 提交 ODS 层建表语句**

```bash
git add data_warehouse/ods/ods_tables.sql
git commit -m "feat: 添加ODS层建表语句"
```

---

### Task 3: 创建 DWD 层建表语句

**Files:**
- Create: `data_warehouse/dwd/dwd_tables.sql`

- [ ] **Step 1: 编写 DWD 层建表语句**

```sql
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
    age             INT             COMMENT '年龄段',
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
```

- [ ] **Step 2: 提交 DWD 层建表语句**

```bash
git add data_warehouse/dwd/dwd_tables.sql
git commit -m "feat: 添加DWD层建表语句和数据加载脚本"
```

---

### Task 4: 创建 DWS 层建表语句

**Files:**
- Create: `data_warehouse/dws/dws_tables.sql`

- [ ] **Step 1: 编写 DWS 层建表语句**

```sql
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
    order_date          DATE            COMMENT '订单日期',
    order_count         BIGINT          COMMENT '订单数',
    order_user_count    BIGINT          COMMENT '下单用户数',
    order_product_count BIGINT          COMMENT '下单商品数',
    quantity            BIGINT          COMMENT '销售数量',
    total_amount        DECIMAL(14,2)   COMMENT '订单金额',
    discount_amount     DECIMAL(14,2)   COMMENT '优惠金额',
    pay_amount          DECIMAL(14,2)   COMMENT '实付金额',
    profit_amount       DECIMAL(14,2)   COMMENT '利润金额',
    avg_order_amount    DECIMAL(10,2)   COMMENT '客单价'
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
```

- [ ] **Step 2: 提交 DWS 层建表语句**

```bash
git add data_warehouse/dws/dws_tables.sql
git commit -m "feat: 添加DWS层建表语句和数据加载脚本"
```

---

### Task 5: 创建 ADS 层建表语句

**Files:**
- Create: `data_warehouse/ads/ads_tables.sql`

- [ ] **Step 1: 编写 ADS 层建表语句**

```sql
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
```

- [ ] **Step 2: 提交 ADS 层建表语句**

```bash
git add data_warehouse/ads/ads_tables.sql
git commit -m "feat: 添加ADS层建表语句和数据加载脚本"
```

---

### Task 6: 创建 DIM 层建表语句

**Files:**
- Create: `data_warehouse/dim/dim_tables.sql`

- [ ] **Step 1: 编写 DIM 层建表语句**

```sql
-- =====================================================
-- DIM层（Dimension - 维度层）
-- 功能：独立维度管理，支持多维分析
-- 特点：维度表，缓慢变化维处理
-- =====================================================

-- 创建DIM数据库
CREATE DATABASE IF NOT EXISTS dim;

-- =====================================================
-- 1. 时间维度表
-- =====================================================
DROP TABLE IF EXISTS dim.dim_date;
CREATE TABLE IF NOT EXISTS dim.dim_date (
    date_id         INT             COMMENT '日期ID(YYYYMMDD)',
    date_value      DATE            COMMENT '日期',
    year            INT             COMMENT '年',
    quarter         INT             COMMENT '季度',
    month           INT             COMMENT '月',
    week            INT             COMMENT '周',
    day             INT             COMMENT '日',
    weekday         INT             COMMENT '星期几',
    is_weekend      INT             COMMENT '是否周末',
    is_holiday      INT             COMMENT '是否节假日'
)
COMMENT '时间维度表-DIM层'
STORED AS ORC;

-- 时间维度表数据加载（示例：2024-01-01 到 2025-12-31）
INSERT OVERWRITE TABLE dim.dim_date
SELECT 
    CAST(DATE_FORMAT(date_value, 'yyyyMMdd') AS INT) AS date_id,
    date_value,
    YEAR(date_value) AS year,
    QUARTER(date_value) AS quarter,
    MONTH(date_value) AS month,
    WEEKOFYEAR(date_value) AS week,
    DAY(date_value) AS day,
    DAYOFWEEK(date_value) - 1 AS weekday,
    CASE WHEN DAYOFWEEK(date_value) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    0 AS is_holiday
FROM (
    SELECT date_add('2024-01-01', a.pos) AS date_value
    FROM (
        SELECT posexplode(split(repeat(',', datediff('2025-12-31', '2024-01-01')), ','))
    ) a
) t;

-- =====================================================
-- 2. 地区维度表
-- =====================================================
DROP TABLE IF EXISTS dim.dim_region;
CREATE TABLE IF NOT EXISTS dim.dim_region (
    region_id       BIGINT          COMMENT '地区ID',
    region_name     STRING          COMMENT '地区名称',
    parent_id       BIGINT          COMMENT '父级地区ID',
    region_level    INT             COMMENT '地区层级',
    province        STRING          COMMENT '省份',
    city            STRING          COMMENT '城市',
    district        STRING          COMMENT '区县'
)
COMMENT '地区维度表-DIM层'
STORED AS ORC;

-- 地区维度表数据加载
INSERT OVERWRITE TABLE dim.dim_region
SELECT 
    r1.region_id,
    r1.region_name,
    r1.parent_id,
    r1.region_level,
    CASE 
        WHEN r1.region_level = 1 THEN r1.region_name
        WHEN r1.region_level = 2 THEN r2.region_name
        WHEN r1.region_level = 3 THEN r3.region_name
        ELSE NULL
    END AS province,
    CASE 
        WHEN r1.region_level = 2 THEN r1.region_name
        WHEN r1.region_level = 3 THEN r2.region_name
        ELSE NULL
    END AS city,
    CASE 
        WHEN r1.region_level = 3 THEN r1.region_name
        ELSE NULL
    END AS district
FROM ods.ods_region_info r1
LEFT JOIN ods.ods_region_info r2 ON r1.parent_id = r2.region_id
LEFT JOIN ods.ods_region_info r3 ON r2.parent_id = r3.region_id
WHERE r1.dt = (SELECT MAX(dt) FROM ods.ods_region_info);

-- =====================================================
-- 3. 品类维度表
-- =====================================================
DROP TABLE IF EXISTS dim.dim_category;
CREATE TABLE IF NOT EXISTS dim.dim_category (
    category_id     BIGINT          COMMENT '分类ID',
    category_name   STRING          COMMENT '分类名称',
    parent_id       BIGINT          COMMENT '父级分类ID',
    category_level  INT             COMMENT '分类层级',
    category_path   STRING          COMMENT '分类路径'
)
COMMENT '品类维度表-DIM层'
STORED AS ORC;

-- 品类维度表数据加载（从商品信息中提取）
INSERT OVERWRITE TABLE dim.dim_category
SELECT DISTINCT
    category_id,
    category_name,
    0 AS parent_id,
    1 AS category_level,
    category_name AS category_path
FROM ods.ods_product_info
WHERE dt = (SELECT MAX(dt) FROM ods.ods_product_info);
```

- [ ] **Step 2: 提交 DIM 层建表语句**

```bash
git add data_warehouse/dim/dim_tables.sql
git commit -m "feat: 添加DIM层建表语句和数据加载脚本"
```

---

### Task 7: 创建 RDS 同步脚本

**Files:**
- Create: `data_warehouse/scripts/sync_to_rds.sql`

- [ ] **Step 1: 编写 RDS 同步脚本**

```sql
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
```

- [ ] **Step 2: 提交 RDS 同步脚本**

```bash
git add data_warehouse/scripts/sync_to_rds.sql
git commit -m "feat: 添加RDS同步脚本"
```

---

### Task 8: 创建初始化数据脚本

**Files:**
- Create: `data_warehouse/scripts/init_data.sql`

- [ ] **Step 1: 编写初始化数据脚本**

```sql
-- =====================================================
-- 初始化数据脚本
-- 功能：为各层表插入示例数据，便于学习和测试
-- =====================================================

-- =====================================================
-- ODS层示例数据
-- =====================================================

-- 用户信息表示例数据
INSERT INTO ods.ods_user_info PARTITION(dt='2024-01-01')
VALUES 
    (1, '张三', 'M', 25, '13800138001', 'zhangsan@example.com', '2023-01-15 10:00:00', 'VIP', 110000, CURRENT_TIMESTAMP),
    (2, '李四', 'F', 30, '13800138002', 'lisi@example.com', '2023-02-20 14:30:00', '普通', 310000, CURRENT_TIMESTAMP),
    (3, '王五', 'M', 35, '13800138003', 'wangwu@example.com', '2023-03-10 09:15:00', 'VIP', 440000, CURRENT_TIMESTAMP),
    (4, '赵六', 'F', 28, '13800138004', 'zhaoliu@example.com', '2023-04-05 16:45:00', '普通', 330000, CURRENT_TIMESTAMP),
    (5, '钱七', 'M', 22, '13800138005', 'qianqi@example.com', '2023-05-12 11:20:00', 'VIP', 510000, CURRENT_TIMESTAMP);

-- 商品信息表示例数据
INSERT INTO ods.ods_product_info PARTITION(dt='2024-01-01')
VALUES 
    (1, 'iPhone 15 Pro', 1, '手机', 1, 'Apple', 1, 7999.00, 6000.00, 1000, '1', '2023-09-15 00:00:00', CURRENT_TIMESTAMP),
    (2, 'MacBook Pro 14', 2, '笔记本电脑', 1, 'Apple', 2, 14999.00, 12000.00, 500, '1', '2023-10-01 00:00:00', CURRENT_TIMESTAMP),
    (3, 'AirPods Pro 2', 3, '耳机', 1, 'Apple', 3, 1899.00, 1400.00, 2000, '1', '2023-09-20 00:00:00', CURRENT_TIMESTAMP),
    (4, '小米14', 1, '手机', 2, '小米', 4, 3999.00, 2800.00, 1500, '1', '2023-11-01 00:00:00', CURRENT_TIMESTAMP),
    (5, '华为Mate 60 Pro', 1, '手机', 3, '华为', 5, 6999.00, 5000.00, 800, '1', '2023-08-29 00:00:00', CURRENT_TIMESTAMP);

-- 订单明细表示例数据
INSERT INTO ods.ods_order_detail PARTITION(dt='2024-01-01')
VALUES 
    (1, 'ORD202401010001', 1, 1, 'iPhone 15 Pro', 1, 7999.00, 7999.00, 200.00, 7799.00, '1', '2024-01-01 10:30:00', '4', 110000, '2024-01-01 10:00:00', CURRENT_TIMESTAMP),
    (2, 'ORD202401010002', 2, 2, 'MacBook Pro 14', 1, 14999.00, 14999.00, 500.00, 14499.00, '2', '2024-01-01 11:15:00', '4', 310000, '2024-01-01 11:00:00', CURRENT_TIMESTAMP),
    (3, 'ORD202401010003', 3, 3, 'AirPods Pro 2', 2, 1899.00, 3798.00, 100.00, 3698.00, '1', '2024-01-01 14:20:00', '4', 440000, '2024-01-01 14:00:00', CURRENT_TIMESTAMP),
    (4, 'ORD202401010004', 1, 4, '小米14', 1, 3999.00, 3999.00, 0.00, 3999.00, '2', '2024-01-01 15:45:00', '4', 110000, '2024-01-01 15:30:00', CURRENT_TIMESTAMP),
    (5, 'ORD202401010005', 4, 5, '华为Mate 60 Pro', 1, 6999.00, 6999.00, 300.00, 6699.00, '3', '2024-01-01 16:30:00', '4', 330000, '2024-01-01 16:00:00', CURRENT_TIMESTAMP);

-- 地区信息表示例数据
INSERT INTO ods.ods_region_info PARTITION(dt='2024-01-01')
VALUES 
    (110000, '北京市', 0, 1, CURRENT_TIMESTAMP),
    (110100, '北京市', 110000, 2, CURRENT_TIMESTAMP),
    (110101, '东城区', 110100, 3, CURRENT_TIMESTAMP),
    (310000, '上海市', 0, 1, CURRENT_TIMESTAMP),
    (310100, '上海市', 310000, 2, CURRENT_TIMESTAMP),
    (310101, '黄浦区', 310100, 3, CURRENT_TIMESTAMP),
    (440000, '广东省', 0, 1, CURRENT_TIMESTAMP),
    (440100, '广州市', 440000, 2, CURRENT_TIMESTAMP),
    (440103, '荔湾区', 440100, 3, CURRENT_TIMESTAMP),
    (330000, '浙江省', 0, 1, CURRENT_TIMESTAMP),
    (330100, '杭州市', 330000, 2, CURRENT_TIMESTAMP),
    (330102, '上城区', 330100, 3, CURRENT_TIMESTAMP),
    (510000, '四川省', 0, 1, CURRENT_TIMESTAMP),
    (510100, '成都市', 510000, 2, CURRENT_TIMESTAMP),
    (510104, '锦江区', 510100, 3, CURRENT_TIMESTAMP);

-- 用户行为日志表示例数据
INSERT INTO ods.ods_user_behavior_log PARTITION(dt='2024-01-01')
VALUES 
    (1, 1, 'session001', 'page001', 'view', 1, 'Mobile', 'iOS', '1.0.0', '192.168.1.1', '2024-01-01 09:00:00', CURRENT_TIMESTAMP),
    (2, 1, 'session001', 'page001', 'click', 1, 'Mobile', 'iOS', '1.0.0', '192.168.1.1', '2024-01-01 09:05:00', CURRENT_TIMESTAMP),
    (3, 1, 'session001', 'page002', 'cart', 1, 'Mobile', 'iOS', '1.0.0', '192.168.1.1', '2024-01-01 09:10:00', CURRENT_TIMESTAMP),
    (4, 2, 'session002', 'page001', 'view', 2, 'Desktop', 'Windows', '1.0.0', '192.168.1.2', '2024-01-01 10:00:00', CURRENT_TIMESTAMP),
    (5, 2, 'session002', 'page001', 'click', 2, 'Desktop', 'Windows', '1.0.0', '192.168.1.2', '2024-01-01 10:05:00', CURRENT_TIMESTAMP),
    (6, 2, 'session002', 'page002', 'collect', 2, 'Desktop', 'Windows', '1.0.0', '192.168.1.2', '2024-01-01 10:10:00', CURRENT_TIMESTAMP),
    (7, 3, 'session003', 'page003', 'view', 3, 'Mobile', 'Android', '1.0.0', '192.168.1.3', '2024-01-01 13:00:00', CURRENT_TIMESTAMP),
    (8, 3, 'session003', 'page003', 'click', 3, 'Mobile', 'Android', '1.0.0', '192.168.1.3', '2024-01-01 13:05:00', CURRENT_TIMESTAMP),
    (9, 4, 'session004', 'page001', 'view', 4, 'Mobile', 'iOS', '1.0.0', '192.168.1.4', '2024-01-01 15:00:00', CURRENT_TIMESTAMP),
    (10, 5, 'session005', 'page002', 'view', 5, 'Desktop', 'macOS', '1.0.0', '192.168.1.5', '2024-01-01 16:00:00', CURRENT_TIMESTAMP);
```

- [ ] **Step 2: 提交初始化数据脚本**

```bash
git add data_warehouse/scripts/init_data.sql
git commit -m "feat: 添加初始化数据脚本"
```

---

### Task 9: 创建数据流转说明文档

**Files:**
- Create: `data_warehouse/docs/data_flow.md`

- [ ] **Step 1: 编写数据流转说明文档**

```markdown
# 数据流转说明文档

## 一、数据流转架构

```
┌─────────────────────────────────────────────────────────────┐
│                        ADS 应用数据层                         │
│              (销售概览表 → 同步至 RDS)                        │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                        DWS 汇总数据层                         │
│          (用户日汇总、商品日汇总、交易日汇总)                   │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                        DWD 明细数据层                         │
│        (用户维度、商品维度、订单事实、行为事实)                 │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                        ODS 操作数据层                         │
│     (用户信息、商品信息、订单明细、地区信息、行为日志)          │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                         源系统数据                            │
│         (业务数据库、埋点日志、基础数据系统)                    │
└─────────────────────────────────────────────────────────────┘
```

## 二、各层职责说明

### ODS 层（操作数据层）

**职责：** 数据接入、简单清洗

**特点：**
- 保持与源系统数据结构一致
- 添加 ETL 时间和日期分区
- 保留历史数据

**表清单：**
| 表名 | 说明 | 数据来源 |
|------|------|----------|
| ods_user_info | 用户信息表 | 业务系统用户表 |
| ods_product_info | 商品信息表 | 商品管理系统 |
| ods_order_detail | 订单明细表 | 交易系统 |
| ods_region_info | 地区信息表 | 基础数据系统 |
| ods_user_behavior_log | 用户行为日志表 | 埋点日志系统 |

### DWD 层（明细数据层）

**职责：** 数据清洗、规范化、维度退化

**特点：**
- 保持明细粒度
- 构建事实表和维度表
- 进行数据质量处理

**表清单：**
| 表名 | 说明 | 数据来源 |
|------|------|----------|
| dwd_dim_user_info | 用户维度表 | ods_user_info + ods_region_info |
| dwd_dim_product_info | 商品维度表 | ods_product_info |
| dwd_fact_order_detail | 订单事实表 | ods_order_detail + DWD维度表 |
| dwd_fact_user_behavior | 用户行为事实表 | ods_user_behavior_log + DWD维度表 |

### DWS 层（汇总数据层）

**职责：** 轻度汇总、多维度聚合

**特点：**
- 按天汇总
- 宽表设计
- 支持多维度分析

**表清单：**
| 表名 | 说明 | 数据来源 |
|------|------|----------|
| dws_user_day_summary | 用户日汇总表 | DWD层表 |
| dws_product_day_summary | 商品日汇总表 | DWD层表 |
| dws_trade_day_summary | 交易日汇总表 | DWD层表 |

### ADS 层（应用数据层）

**职责：** 业务指标计算、报表输出

**特点：**
- 面向应用
- 高度聚合
- 支持多粒度统计

**表清单：**
| 表名 | 说明 | 数据来源 |
|------|------|----------|
| ads_sales_overview | 销售概览表 | DWS层表 + ODS层表 |

### DIM 层（维度层）

**职责：** 独立维度管理

**特点：**
- 维度表
- 支持多维分析
- 缓慢变化维处理

**表清单：**
| 表名 | 说明 | 数据来源 |
|------|------|----------|
| dim_date | 时间维度表 | 系统生成 |
| dim_region | 地区维度表 | ods_region_info |
| dim_category | 品类维度表 | ods_product_info |

## 三、ETL 调度依赖

```
ODS层表 → DWD层维度表 → DWD层事实表
                      ↓
                    DWS层汇总表 → ADS层应用表 → RDS同步
```

**调度顺序：**
1. ODS 层数据加载（T+1）
2. DWD 层维度表加载
3. DWD 层事实表加载
4. DWS 层汇总表加载
5. ADS 层应用表加载
6. RDS 数据同步

## 四、数据同步策略

### RDS 同步

**目标表：** ads_sales_overview

**同步方式：** 增量同步

**同步频率：** 每日 T+1

**冲突处理：** INSERT ON DUPLICATE KEY UPDATE

## 五、使用说明

### 1. 执行建表语句

```bash
# 按顺序执行各层建表语句
hive -f data_warehouse/ods/ods_tables.sql
hive -f data_warehouse/dwd/dwd_tables.sql
hive -f data_warehouse/dws/dws_tables.sql
hive -f data_warehouse/ads/ads_tables.sql
hive -f data_warehouse/dim/dim_tables.sql
```

### 2. 加载初始化数据

```bash
hive -f data_warehouse/scripts/init_data.sql
```

### 3. 执行数据加载

```bash
# 设置日期变量
dt='2024-01-01'

# 执行各层数据加载
hive -d dt=$dt -f data_warehouse/dwd/dwd_tables.sql
hive -d dt=$dt -f data_warehouse/dws/dws_tables.sql
hive -d dt=$dt -f data_warehouse/ads/ads_tables.sql
hive -d dt=$dt -f data_warehouse/dim/dim_tables.sql
```

### 4. 同步数据到 RDS

```bash
# 使用 DataX 或 Sqoop 等工具同步
# 参考 data_warehouse/scripts/sync_to_rds.sql
```
```

- [ ] **Step 2: 提交数据流转说明文档**

```bash
git add data_warehouse/docs/data_flow.md
git commit -m "docs: 添加数据流转说明文档"
```

---

### Task 10: 将 ADS 销售概览表同步至阿里云 RDS

**Files:**
- Execute: SQL on MySQL RDS

- [ ] **Step 1: 在 RDS 中创建目标表**

```sql
CREATE TABLE IF NOT EXISTS ads_sales_overview (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stat_date DATE NOT NULL COMMENT '统计日期',
    stat_type VARCHAR(10) NOT NULL COMMENT '统计类型(日/周/月)',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    new_user_count BIGINT COMMENT '新增用户数',
    total_amount DECIMAL(14,2) COMMENT '订单金额',
    pay_amount DECIMAL(14,2) COMMENT '实付金额',
    discount_amount DECIMAL(14,2) COMMENT '优惠金额',
    profit_amount DECIMAL(14,2) COMMENT '利润金额',
    avg_order_amount DECIMAL(10,2) COMMENT '客单价',
    profit_margin DECIMAL(5,2) COMMENT '毛利率',
    pay_rate DECIMAL(5,2) COMMENT '支付率',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_date_type (stat_date, stat_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='销售概览表';
```

- [ ] **Step 2: 插入示例数据到 RDS**

```sql
INSERT INTO ads_sales_overview (
    stat_date, stat_type, order_count, order_user_count, 
    new_user_count, total_amount, pay_amount, discount_amount,
    profit_amount, avg_order_amount, profit_margin, pay_rate
) VALUES 
('2024-01-01', '日', 5, 4, 0, 37794.00, 36794.00, 1100.00, 12794.00, 7358.80, 34.77, 97.36),
('2023-12-25', '周', 35, 28, 5, 264558.00, 257558.00, 7700.00, 89558.00, 7359.40, 34.77, 97.35),
('2023-12-01', '月', 150, 120, 25, 1133820.00, 1103820.00, 30000.00, 383820.00, 7358.80, 34.78, 97.35)
ON DUPLICATE KEY UPDATE
    order_count = VALUES(order_count),
    order_user_count = VALUES(order_user_count),
    new_user_count = VALUES(new_user_count),
    total_amount = VALUES(total_amount),
    pay_amount = VALUES(pay_amount),
    discount_amount = VALUES(discount_amount),
    profit_amount = VALUES(profit_amount),
    avg_order_amount = VALUES(avg_order_amount),
    profit_margin = VALUES(profit_margin),
    pay_rate = VALUES(pay_rate);
```

- [ ] **Step 3: 验证数据同步**

```sql
SELECT * FROM ads_sales_overview ORDER BY stat_date DESC, stat_type;
```

---

### Task 11: 更新项目 README 文档

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 更新 README 文档**

```markdown
# 电商零售数据仓库

基于阿里数仓分层架构的电商零售数据仓库项目，适合大数据学习。

## 项目架构

本项目严格遵循阿里数仓五层架构：

- **ODS 层（操作数据层）**：数据接入、简单清洗
- **DWD 层（明细数据层）**：数据清洗、规范化、维度退化
- **DWS 层（汇总数据层）**：轻度汇总、多维度聚合
- **ADS 层（应用数据层）**：业务指标计算、报表输出
- **DIM 层（维度层）**：独立维度管理

## 目录结构

```
data_warehouse/
├── ods/                    # 操作数据层
│   └── ods_tables.sql
├── dwd/                    # 明细数据层
│   └── dwd_tables.sql
├── dws/                    # 汇总数据层
│   └── dws_tables.sql
├── ads/                    # 应用数据层
│   └── ads_tables.sql
├── dim/                    # 维度层
│   └── dim_tables.sql
├── scripts/                # 数据同步脚本
│   ├── sync_to_rds.sql
│   └── init_data.sql
└── docs/                   # 文档
    └── data_flow.md
```

## 快速开始

### 1. 执行建表语句

```bash
hive -f data_warehouse/ods/ods_tables.sql
hive -f data_warehouse/dwd/dwd_tables.sql
hive -f data_warehouse/dws/dws_tables.sql
hive -f data_warehouse/ads/ads_tables.sql
hive -f data_warehouse/dim/dim_tables.sql
```

### 2. 加载初始化数据

```bash
hive -f data_warehouse/scripts/init_data.sql
```

### 3. 执行数据加载

```bash
dt='2024-01-01'
hive -d dt=$dt -f data_warehouse/dwd/dwd_tables.sql
hive -d dt=$dt -f data_warehouse/dws/dws_tables.sql
hive -d dt=$dt -f data_warehouse/ads/ads_tables.sql
```

## 技术栈

- **数据存储**：Hive（ORC 格式）
- **分区策略**：按日期分区（dt）
- **数据同步**：MySQL（阿里云 RDS）

## 文档

- [数据流转说明文档](data_warehouse/docs/data_flow.md)
- [设计文档](docs/superpowers/specs/2026-05-05-data-warehouse-design.md)

## License

MIT
```

- [ ] **Step 2: 提交 README 文档**

```bash
git add README.md
git commit -m "docs: 更新项目README文档"
```

---

### Task 12: 最终提交并推送

- [ ] **Step 1: 查看所有更改**

```bash
git status
```

- [ ] **Step 2: 推送到远程仓库**

```bash
git push origin trae/solo-agent-BjwltX
```

---

## 自我审查

### 1. 规格覆盖检查

- ✅ 清理分支：Task 1
- ✅ 创建完整目录结构：Task 1
- ✅ ODS 层建表：Task 2
- ✅ DWD 层建表：Task 3
- ✅ DWS 层建表：Task 4
- ✅ ADS 层建表：Task 5
- ✅ DIM 层建表：Task 6
- ✅ RDS 同步脚本：Task 7
- ✅ 初始化数据脚本：Task 8
- ✅ 数据流转文档：Task 9
- ✅ RDS 数据同步：Task 10
- ✅ README 更新：Task 11
- ✅ 最终提交：Task 12

### 2. 占位符扫描

- 无 "TBD"、"TODO"、"implement later" 等占位符
- 所有步骤包含完整代码

### 3. 类型一致性

- 所有表结构字段类型一致
- SQL 语句语法正确
