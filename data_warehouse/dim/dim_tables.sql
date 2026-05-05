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
    is_weekend     INT             COMMENT '是否周末',
    is_holiday     INT             COMMENT '是否节假日'
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
