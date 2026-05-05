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
