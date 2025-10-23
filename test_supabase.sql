-- 🔍 Supabase 数据库诊断 SQL

-- 1. 检查表是否存在
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'gold_historical_prices'
) AS table_exists;

-- 2. 检查表中有多少数据
SELECT COUNT(*) AS total_records 
FROM gold_historical_prices;

-- 3. 查看最新的 5 条数据
SELECT 
    date,
    price_cny_per_gram,
    data_source,
    created_at
FROM gold_historical_prices
ORDER BY date DESC
LIMIT 5;

-- 4. 检查日期范围
SELECT 
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date,
    COUNT(*) AS total_records
FROM gold_historical_prices;

-- 5. 检查 RLS 策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'gold_historical_prices';

-- 📋 如果表不存在或无数据，需要：
-- 1. 创建表（运行之前提供的 SQL schema）
-- 2. 运行 Edge Function 获取数据
-- 3. 或者手动插入测试数据：

-- 插入测试数据示例：
/*
INSERT INTO gold_historical_prices 
    (date, price_usd_per_ounce, exchange_rate_usd_cny, data_source)
VALUES 
    ('2025-10-10', 2650.00, 7.25, 'Manual Test'),
    ('2025-10-09', 2645.00, 7.24, 'Manual Test'),
    ('2025-10-08', 2640.00, 7.23, 'Manual Test');
*/

-- 📋 如果 RLS 策略阻止访问，添加允许 SELECT 的策略：
/*
CREATE POLICY "Allow public read access" 
ON gold_historical_prices 
FOR SELECT 
USING (true);
*/

