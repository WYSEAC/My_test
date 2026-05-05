# 电商零售数仓设计方案

## 一、项目概述

本项目旨在搭建一个完整的电商零售数据仓库，严格遵循阿里数仓分层架构。项目作为大数据学习模板，涵盖从数据接入到应用输出的完整链路，最终将 ADS 层销售概览表同步至阿里云 RDS。

### 业务场景

电商零售业务，包含用户、商品、订单、支付、用户行为等核心业务域。

### 技术选型

- 数据存储：Hive（ORC 格式）
- 分区策略：按日期分区（dt）
- 数据同步：MySQL（阿里云 RDS）

## 二、分层架构设计

### 2.1 架构总览

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

### 2.2 各层职责

| 层级 | 名称 | 职责 | 数据特点 |
|------|------|------|----------|
| ODS | 操作数据层 | 数据接入、简单清洗 | 接近源系统，保留历史 |
| DWD | 明细数据层 | 数据清洗、规范化、维度退化 | 明细粒度，事实表 |
| DWS | 汇总数据层 | 轻度汇总、多维度聚合 | 按天汇总，宽表 |
| ADS | 应用数据层 | 业务指标计算、报表输出 | 面向应用，高度聚合 |
| DIM | 维度层 | 独立维度管理 | 维度表，支持多维分析 |

## 三、表结构设计

### 3.1 ODS 层（操作数据层）

#### 3.1.1 ods_user_info（用户信息表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user_id | BIGINT | 用户ID |
| user_name | STRING | 用户姓名 |
| gender | STRING | 性别 |
| age | INT | 年龄 |
| phone | STRING | 手机号 |
| email | STRING | 邮箱 |
| register_time | TIMESTAMP | 注册时间 |
| user_level | STRING | 用户等级 |
| region_id | BIGINT | 地区ID |
| etl_time | TIMESTAMP | ETL处理时间 |
| dt | STRING | 日期分区 |

#### 3.1.2 ods_product_info（商品信息表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| category_id | BIGINT | 分类ID |
| category_name | STRING | 分类名称 |
| brand_id | BIGINT | 品牌ID |
| brand_name | STRING | 品牌名称 |
| supplier_id | BIGINT | 供应商ID |
| price | DECIMAL(10,2) | 商品价格 |
| cost | DECIMAL(10,2) | 商品成本 |
| stock_num | INT | 库存数量 |
| status | STRING | 商品状态 |
| create_time | TIMESTAMP | 创建时间 |
| etl_time | TIMESTAMP | ETL处理时间 |
| dt | STRING | 日期分区 |

#### 3.1.3 ods_order_detail（订单明细表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| order_id | BIGINT | 订单ID |
| order_no | STRING | 订单编号 |
| user_id | BIGINT | 用户ID |
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| quantity | INT | 购买数量 |
| unit_price | DECIMAL(10,2) | 商品单价 |
| total_amount | DECIMAL(10,2) | 订单金额 |
| discount_amount | DECIMAL(10,2) | 优惠金额 |
| pay_amount | DECIMAL(10,2) | 实付金额 |
| pay_type | STRING | 支付方式 |
| pay_time | TIMESTAMP | 支付时间 |
| order_status | STRING | 订单状态 |
| region_id | BIGINT | 地区ID |
| create_time | TIMESTAMP | 下单时间 |
| etl_time | TIMESTAMP | ETL处理时间 |
| dt | STRING | 日期分区 |

#### 3.1.4 ods_region_info（地区信息表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| region_id | BIGINT | 地区ID |
| region_name | STRING | 地区名称 |
| parent_id | BIGINT | 父级地区ID |
| region_level | INT | 地区层级(1省/2市/3区) |
| etl_time | TIMESTAMP | ETL处理时间 |
| dt | STRING | 日期分区 |

#### 3.1.5 ods_user_behavior_log（用户行为日志表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| log_id | BIGINT | 日志ID |
| user_id | BIGINT | 用户ID |
| session_id | STRING | 会话ID |
| page_id | STRING | 页面ID |
| action_type | STRING | 行为类型(浏览/点击/收藏/加购) |
| product_id | BIGINT | 商品ID |
| device_type | STRING | 设备类型 |
| os_type | STRING | 操作系统 |
| app_version | STRING | APP版本 |
| ip_address | STRING | IP地址 |
| log_time | TIMESTAMP | 日志时间 |
| etl_time | TIMESTAMP | ETL处理时间 |
| dt | STRING | 日期分区 |

### 3.2 DWD 层（明细数据层）

#### 3.2.1 dwd_dim_user_info（用户维度表）

维度退化处理，整合地区信息。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user_id | BIGINT | 用户ID |
| user_name | STRING | 用户姓名 |
| gender | STRING | 性别(男/女/未知) |
| age | INT | 年龄 |
| age_range | STRING | 年龄段分组 |
| phone | STRING | 手机号(脱敏) |
| email | STRING | 邮箱(脱敏) |
| register_date | DATE | 注册日期 |
| user_level | STRING | 用户等级 |
| region_id | BIGINT | 地区ID |
| region_name | STRING | 地区名称 |
| is_valid | INT | 是否有效(0无效/1有效) |
| dt | STRING | 日期分区 |

#### 3.2.2 dwd_dim_product_info（商品维度表）

计算毛利率，状态码转义。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| category_id | BIGINT | 分类ID |
| category_name | STRING | 分类名称 |
| brand_id | BIGINT | 品牌ID |
| brand_name | STRING | 品牌名称 |
| supplier_id | BIGINT | 供应商ID |
| price | DECIMAL(10,2) | 商品价格 |
| cost | DECIMAL(10,2) | 商品成本 |
| profit_margin | DECIMAL(5,2) | 毛利率 |
| stock_num | INT | 库存数量 |
| status | STRING | 商品状态 |
| is_valid | INT | 是否有效 |
| dt | STRING | 日期分区 |

#### 3.2.3 dwd_fact_order_detail（订单事实表）

整合用户、商品、地区维度，提取时间维度。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| order_id | BIGINT | 订单ID |
| order_no | STRING | 订单编号 |
| user_id | BIGINT | 用户ID |
| user_name | STRING | 用户姓名 |
| user_level | STRING | 用户等级 |
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| category_id | BIGINT | 分类ID |
| category_name | STRING | 分类名称 |
| brand_id | BIGINT | 品牌ID |
| brand_name | STRING | 品牌名称 |
| quantity | INT | 购买数量 |
| unit_price | DECIMAL(10,2) | 商品单价 |
| total_amount | DECIMAL(10,2) | 订单金额 |
| discount_amount | DECIMAL(10,2) | 优惠金额 |
| pay_amount | DECIMAL(10,2) | 实付金额 |
| pay_type | STRING | 支付方式 |
| pay_time | TIMESTAMP | 支付时间 |
| order_status | STRING | 订单状态 |
| region_id | BIGINT | 地区ID |
| region_name | STRING | 地区名称 |
| create_time | TIMESTAMP | 下单时间 |
| order_date | DATE | 下单日期 |
| order_hour | INT | 下单小时 |
| dt | STRING | 日期分区 |

#### 3.2.4 dwd_fact_user_behavior（用户行为事实表）

整合商品维度，行为类型转义。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| log_id | BIGINT | 日志ID |
| user_id | BIGINT | 用户ID |
| session_id | STRING | 会话ID |
| page_id | STRING | 页面ID |
| action_type | STRING | 行为类型 |
| action_name | STRING | 行为名称 |
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| device_type | STRING | 设备类型 |
| os_type | STRING | 操作系统 |
| app_version | STRING | APP版本 |
| ip_address | STRING | IP地址 |
| log_time | TIMESTAMP | 日志时间 |
| log_date | DATE | 日志日期 |
| log_hour | INT | 日志小时 |
| dt | STRING | 日期分区 |

### 3.3 DWS 层（汇总数据层）

#### 3.3.1 dws_user_day_summary（用户日汇总表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user_id | BIGINT | 用户ID |
| user_name | STRING | 用户姓名 |
| user_level | STRING | 用户等级 |
| region_name | STRING | 地区名称 |
| order_count | INT | 订单数 |
| order_amount | DECIMAL(12,2) | 订单金额 |
| pay_amount | DECIMAL(12,2) | 实付金额 |
| quantity | INT | 购买商品数量 |
| behavior_view | INT | 浏览次数 |
| behavior_click | INT | 点击次数 |
| behavior_collect | INT | 收藏次数 |
| behavior_cart | INT | 加购次数 |
| dt | STRING | 日期分区 |

#### 3.3.2 dws_product_day_summary（商品日汇总表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| product_id | BIGINT | 商品ID |
| product_name | STRING | 商品名称 |
| category_name | STRING | 分类名称 |
| brand_name | STRING | 品牌名称 |
| order_count | INT | 订单数 |
| quantity | INT | 销售数量 |
| total_amount | DECIMAL(12,2) | 销售额 |
| discount_amount | DECIMAL(12,2) | 优惠金额 |
| pay_amount | DECIMAL(12,2) | 实付金额 |
| profit_amount | DECIMAL(12,2) | 利润金额 |
| behavior_view | INT | 浏览次数 |
| behavior_click | INT | 点击次数 |
| behavior_collect | INT | 收藏次数 |
| behavior_cart | INT | 加购次数 |
| dt | STRING | 日期分区 |

#### 3.3.3 dws_trade_day_summary（交易日汇总表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| order_date | DATE | 订单日期 |
| order_count | BIGINT | 订单数 |
| order_user_count | BIGINT | 下单用户数 |
| order_product_count | BIGINT | 下单商品数 |
| quantity | BIGINT | 销售数量 |
| total_amount | DECIMAL(14,2) | 订单金额 |
| discount_amount | DECIMAL(14,2) | 优惠金额 |
| pay_amount | DECIMAL(14,2) | 实付金额 |
| profit_amount | DECIMAL(14,2) | 利润金额 |
| avg_order_amount | DECIMAL(10,2) | 客单价 |
| dt | STRING | 日期分区 |

### 3.4 ADS 层（应用数据层）

#### 3.4.1 ads_sales_overview（销售概览表）

**此表将同步至阿里云 RDS**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| stat_date | DATE | 统计日期 |
| stat_type | STRING | 统计类型(日/周/月) |
| order_count | BIGINT | 订单数 |
| order_user_count | BIGINT | 下单用户数 |
| new_user_count | BIGINT | 新增用户数 |
| total_amount | DECIMAL(14,2) | 订单金额 |
| pay_amount | DECIMAL(14,2) | 实付金额 |
| discount_amount | DECIMAL(14,2) | 优惠金额 |
| profit_amount | DECIMAL(14,2) | 利润金额 |
| avg_order_amount | DECIMAL(10,2) | 客单价 |
| profit_margin | DECIMAL(5,2) | 毛利率 |
| pay_rate | DECIMAL(5,2) | 支付率 |
| dt | STRING | 日期分区 |

### 3.5 DIM 层（维度层）

#### 3.5.1 dim_date（时间维度表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| date_id | INT | 日期ID(YYYYMMDD) |
| date_value | DATE | 日期 |
| year | INT | 年 |
| quarter | INT | 季度 |
| month | INT | 月 |
| week | INT | 周 |
| day | INT | 日 |
| weekday | INT | 星期几 |
| is_weekend | INT | 是否周末 |
| is_holiday | INT | 是否节假日 |

#### 3.5.2 dim_region（地区维度表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| region_id | BIGINT | 地区ID |
| region_name | STRING | 地区名称 |
| parent_id | BIGINT | 父级地区ID |
| region_level | INT | 地区层级 |
| province | STRING | 省份 |
| city | STRING | 城市 |
| district | STRING | 区县 |

#### 3.5.3 dim_category（品类维度表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| category_id | BIGINT | 分类ID |
| category_name | STRING | 分类名称 |
| parent_id | BIGINT | 父级分类ID |
| category_level | INT | 分类层级 |
| category_path | STRING | 分类路径 |

## 四、数据流转设计

### 4.1 数据流转路径

```
源系统 → ODS层（数据接入）
       → DWD层（数据清洗、规范化）
       → DWS层（轻度汇总）
       → ADS层（业务指标计算）
       → RDS（数据同步）
```

### 4.2 ETL 调度依赖

```
ODS层表 → DWD层维度表 → DWD层事实表
                      ↓
                    DWS层汇总表 → ADS层应用表 → RDS同步
```

## 五、RDS 同步设计

### 5.1 目标表结构

在阿里云 RDS 中创建 MySQL 表：

```sql
CREATE TABLE ads_sales_overview (
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

### 5.2 同步策略

- 增量同步：按日期分区增量写入
- 冲突处理：使用 INSERT ON DUPLICATE KEY UPDATE
- 同步频率：每日 T+1 同步

## 六、项目目录结构

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

## 七、实施计划

1. 清理现有分支，保留 main 分支
2. 创建完整目录结构
3. 编写各层建表语句
4. 编写数据加载脚本
5. 编写 RDS 同步脚本
6. 更新项目文档
7. 将 ADS 销售概览表同步至阿里云 RDS
