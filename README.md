# 电商零售数据仓库

基于阿里数仓分层架构的电商零售数据仓库项目，适合大数据学习。

## 项目架构

本项目严格遵循阿里数仓五层架构：

- **ODS 层（操作数据层）：** 数据接入、简单清洗
- **DWD 层（明细数据层）：** 数据清洗、规范化、维度退化
- **DWS 层（汇总数据层）：** 轻度汇总、多维度聚合
- **ADS 层（应用数据层）：** 业务指标计算、报表输出
- **DIM 层（维度层）：** 独立维度管理

## 目录结构

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

## 快速开始

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

## 技术栈

- **数据存储：** Hive（ORC 格式）
- **分区策略：** 按日期分区（dt）
- **数据同步：** MySQL（阿里云 RDS）

## 文档

- [数据流转说明文档](data_warehouse/docs/data_flow.md)
- [设计文档](docs/superpowers/specs/2026-05-05-data-warehouse-design.md)

## License

MIT
