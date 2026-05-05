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
```

### 4. 同步数据到 RDS

```bash
# 使用 DataX 或 Sqoop 等工具同步
# 参考 data_warehouse/scripts/sync_to_rds.sql
```
