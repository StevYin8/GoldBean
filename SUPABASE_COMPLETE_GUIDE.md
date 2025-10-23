# Supabase 完整使用教程（小白版）
## 以「黄金价格历史数据获取」为实战案例

---

## 📚 目录

1. [什么是 Supabase](#1-什么是-supabase)
2. [创建 Supabase 项目](#2-创建-supabase-项目)
3. [创建数据库表](#3-创建数据库表)
4. [生成和管理 API Key](#4-生成和管理-api-key)
5. [什么是 Edge Function](#5-什么是-edge-function)
6. [创建和部署 Edge Function](#6-创建和部署-edge-function)
7. [配置定时任务（Cron Job）](#7-配置定时任务cron-job)
8. [在 iOS App 中调用 Supabase](#8-在-ios-app-中调用-supabase)
9. [常见问题和解决方案](#9-常见问题和解决方案)
10. [完整工作流程总结](#10-完整工作流程总结)

---

## 1. 什么是 Supabase？

### 1.1 简单理解

**Supabase** 就像一个「在线数据库 + 后端服务器」的组合包，你可以：

- ✅ **存储数据**：像 Excel 表格一样存储数据（但更强大）
- ✅ **定时任务**：每天自动执行某些操作（比如每6小时抓取一次金价）
- ✅ **API 接口**：让你的 iOS/Android App 可以读取和写入数据
- ✅ **免费使用**：小项目完全免费

### 1.2 为什么用 Supabase？

| 传统方式 | 使用 Supabase |
|---------|--------------|
| 需要自己搭建服务器 | ✅ 不需要，全部在线 |
| 需要购买域名和主机 | ✅ 免费提供 |
| 需要配置数据库 | ✅ 开箱即用 |
| 需要编写复杂的后端代码 | ✅ 提供简单的工具 |

### 1.3 在我们的项目中，Supabase 做什么？

```
┌─────────────────────────────────────────────────────────┐
│               Supabase（在线后端服务）                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1️⃣ 数据库表（存储金价历史数据）                        │
│     - gold_historical_prices （黄金价格表）              │
│     - exchange_rate_history  （汇率历史表）              │
│     - api_call_logs          （API调用日志表）           │
│                                                         │
│  2️⃣ Edge Function（定时抓取数据）                       │
│     - 每6小时自动运行                                   │
│     - 从 Alpha Vantage / 12data 获取金价                │
│     - 自动保存到数据库                                  │
│                                                         │
│  3️⃣ API 接口（供 App 调用）                             │
│     - App 从这里读取历史金价                            │
│     - 实时同步，无需手动维护                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
         ↓ API 调用
    ┌───────────┐
    │  iOS App  │  ← 用户看到的金价趋势图
    └───────────┘
```

---

## 2. 创建 Supabase 项目

### 2.1 注册账号

1. **打开浏览器**，访问：https://supabase.com
2. **点击右上角「Start your project」**
3. **选择登录方式**：
   - 推荐使用 GitHub 账号登录（更方便）
   - 也可以用邮箱注册

### 2.2 创建新项目

登录后，你会看到控制台（Dashboard）：

```
┌────────────────────────────────────────────┐
│  Supabase Dashboard                        │
├────────────────────────────────────────────┤
│                                            │
│   [New Project]  ← 点击这里创建新项目       │
│                                            │
└────────────────────────────────────────────┘
```

**填写项目信息：**

| 字段 | 填什么 | 示例 |
|------|--------|------|
| **Name（项目名称）** | 随便起个名字 | `GoldBeanBackend` |
| **Database Password** | 设置一个强密码 | `MySecurePass123!` |
| **Region（服务器位置）** | 选择离你最近的 | `Northeast Asia (Tokyo)` |
| **Pricing Plan** | 选择 Free | `Free - $0/month` |

**点击「Create new project」**，等待 1-2 分钟创建完成。

### 2.3 项目创建完成后

你会看到项目主页，记住这些重要信息：

```
┌─────────────────────────────────────────────────┐
│  Project: GoldBeanBackend                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  Project URL:                                   │
│  https://xxxxxxxxxxxx.supabase.co               │
│  ↑ 这个就是你的 API 地址                         │
│                                                 │
│  API Keys:                                      │
│  - anon public (公开密钥)                       │
│  - service_role (服务密钥，不要泄露)             │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 3. 创建数据库表

### 3.1 进入 SQL 编辑器

在左侧菜单中：

```
🗂️ Table Editor      ← 可视化表格编辑器
📝 SQL Editor        ← ⭐ 我们用这个！更灵活
🔧 Database
⚙️ Settings
```

**点击「SQL Editor」** → **点击「New query」**

### 3.2 创建第一张表：黄金历史价格表

复制以下 SQL 代码，粘贴到编辑器中：

```sql
-- =============================================
-- 表 1: 黄金历史价格表
-- =============================================
CREATE TABLE gold_historical_prices (
    -- 主键（每条记录的唯一标识）
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 日期（格式：2024-10-10）
    date DATE NOT NULL UNIQUE,
    
    -- 美元价格（单位：美元/盎司）
    price_usd_per_ounce NUMERIC(10, 2),
    open_price_usd NUMERIC(10, 2),
    close_price_usd NUMERIC(10, 2),
    high_price_usd NUMERIC(10, 2),
    low_price_usd NUMERIC(10, 2),
    volume BIGINT,
    
    -- 汇率（美元兑人民币）
    exchange_rate_usd_cny NUMERIC(10, 4),
    
    -- 人民币价格（自动计算，单位：元/克）
    price_cny_per_gram NUMERIC(10, 2) GENERATED ALWAYS AS (
        ROUND((price_usd_per_ounce * exchange_rate_usd_cny) / 31.1035, 2)
    ) STORED,
    
    -- 数据来源标记
    data_source TEXT,
    exchange_rate_source TEXT,
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引（提高查询速度）
CREATE INDEX idx_gold_date ON gold_historical_prices(date DESC);

-- 创建更新触发器（自动更新 updated_at）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_gold_prices_updated_at
    BEFORE UPDATE ON gold_historical_prices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**点击右下角「Run」** ✅ 表创建成功！

### 3.3 创建第二张表：汇率历史表

再新建一个 Query，复制以下代码：

```sql
-- =============================================
-- 表 2: 汇率历史表
-- =============================================
CREATE TABLE exchange_rate_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    currency_pair TEXT NOT NULL,  -- 例如 'USD-CNY'
    rate NUMERIC(10, 4) NOT NULL,
    data_source TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 确保每个日期的每个货币对只有一条记录
    UNIQUE(date, currency_pair)
);

CREATE INDEX idx_exchange_rate_date ON exchange_rate_history(date DESC);
```

**点击「Run」** ✅

### 3.4 创建第三张表：API 调用日志表

```sql
-- =============================================
-- 表 3: API 调用日志表（用于监控和调试）
-- =============================================
CREATE TABLE api_call_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_provider TEXT,           -- 例如 'Alpha Vantage', '12data'
    endpoint TEXT,               -- 调用的具体 API
    status_code INTEGER,         -- HTTP 状态码
    success BOOLEAN,             -- 是否成功
    error_message TEXT,          -- 错误信息
    records_fetched INTEGER,     -- 获取的记录数
    records_inserted INTEGER,    -- 插入的记录数
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_api_logs_created ON api_call_logs(created_at DESC);
```

**点击「Run」** ✅

### 3.5 配置数据访问权限（RLS）

Supabase 默认开启了 **Row Level Security（行级安全）**，我们需要配置权限：

```sql
-- =============================================
-- 配置访问权限
-- =============================================

-- 允许所有人读取金价数据（因为这是公开数据）
ALTER TABLE gold_historical_prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "允许所有人读取金价" ON gold_historical_prices
    FOR SELECT
    USING (true);

-- 允许所有人读取汇率数据
ALTER TABLE exchange_rate_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "允许所有人读取汇率" ON exchange_rate_history
    FOR SELECT
    USING (true);

-- API 日志只允许服务端读取
ALTER TABLE api_call_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "服务端可读写日志" ON api_call_logs
    FOR ALL
    USING (auth.role() = 'service_role');
```

**点击「Run」** ✅

### 3.6 验证表是否创建成功

点击左侧菜单 **「Table Editor」**，你应该看到：

```
✅ gold_historical_prices
✅ exchange_rate_history
✅ api_call_logs
```

点击任意表格，可以看到表结构和数据（现在是空的）。

---

## 4. 生成和管理 API Key

### 4.1 什么是 API Key？

API Key 就像「钥匙」，用来证明「你有权限访问这个数据库」。

Supabase 有两种 Key：

| Key 类型 | 用途 | 安全级别 |
|---------|------|---------|
| **anon (public)** | 给 App 用户使用 | ⭐ 可以公开 |
| **service_role** | 给服务器/Edge Function 使用 | 🔒 绝对不能泄露！ |

### 4.2 在哪里找到 API Key？

1. 点击左侧菜单 **「Settings」**（最底部）
2. 点击 **「API」**
3. 你会看到：

```
┌─────────────────────────────────────────────────┐
│  Project API keys                               │
├─────────────────────────────────────────────────┤
│                                                 │
│  Project URL:                                   │
│  https://fqckfusbjabhlmkogesv.supabase.co       │
│                                                 │
│  anon public:                                   │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...        │
│  ↑ 这个给 iOS App 用                            │
│                                                 │
│  service_role:                                  │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...        │
│  ↑ 这个给 Edge Function 用                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 4.3 如何使用 API Key？

**在 iOS App 中：**

```swift
// GoldBean/Core/SupabaseConfig.swift
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    let client: SupabaseClient
    
    private init() {
        // 项目 URL
        let supabaseURL = "https://你的项目.supabase.co"
        
        // 公开密钥（anon key）
        let supabaseKey = "你的 anon key"
        
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
}
```

**在 Edge Function 中：**

```typescript
// 使用环境变量（更安全）
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
```

---

## 5. 什么是 Edge Function？

### 5.1 简单理解

**Edge Function** 就是「在云端自动运行的代码」，你可以理解为：

```
┌──────────────────────────────────────────┐
│   Edge Function = 云端小助手             │
├──────────────────────────────────────────┤
│                                          │
│  你可以让它：                            │
│  ✅ 定时执行任务（每天、每小时）          │
│  ✅ 抓取外部 API 数据                    │
│  ✅ 处理复杂的业务逻辑                    │
│  ✅ 自动保存到数据库                     │
│                                          │
│  优点：                                  │
│  - 24小时自动运行                        │
│  - 不需要你的电脑一直开着                │
│  - 免费额度很大                          │
│                                          │
└──────────────────────────────────────────┘
```

### 5.2 在我们的项目中，Edge Function 做什么？

```
每 6 小时执行一次：

1️⃣ 调用 Alpha Vantage API 获取金价
2️⃣ 调用 12data API（备用）
3️⃣ 获取 USD-CNY 汇率
4️⃣ 计算人民币金价
5️⃣ 保存到 Supabase 数据库
6️⃣ 记录日志

┌─────────────────────────────────────┐
│  定时执行：每天 00:00, 06:00,        │
│           12:00, 18:00              │
└─────────────────────────────────────┘
```

### 5.3 Edge Function 的运行环境

- **语言**：TypeScript / JavaScript
- **运行时**：Deno（类似 Node.js，但更安全）
- **超时限制**：免费版 10 秒，付费版可延长
- **调用限制**：免费版每月 500,000 次

---

## 6. 创建和部署 Edge Function

### 6.1 安装 Supabase CLI（命令行工具）

**macOS 安装：**

```bash
# 使用 Homebrew 安装
brew install supabase/tap/supabase

# 验证安装
supabase --version
```

**Windows 安装：**

```powershell
# 使用 Scoop 安装
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### 6.2 登录 Supabase

```bash
# 在终端中运行
supabase login

# 会打开浏览器，让你授权
# 授权后，终端会显示：Logged in!
```

### 6.3 初始化项目

在你的项目目录中（比如 `GoldBean/`）：

```bash
cd /Users/stev/Desktop/Cursor/GoldBean

# 初始化 Supabase
supabase init

# 会创建一个 supabase/ 文件夹
```

你会看到：

```
GoldBean/
├── supabase/
│   ├── config.toml         ← 配置文件
│   └── functions/          ← Edge Functions 放这里
├── GoldBean/               ← iOS App 代码
└── ...
```

### 6.4 链接到你的在线项目

```bash
# 获取项目引用 ID（在 Supabase Dashboard 的 Settings → General 中找到）
# 例如：fqckfusbjabhlmkogesv

supabase link --project-ref fqckfusbjabhlmkogesv

# 会要求输入数据库密码（就是你创建项目时设置的密码）
```

### 6.5 创建 Edge Function

```bash
# 创建一个名为 fetch-gold-prices 的 Function
supabase functions new fetch-gold-prices
```

会创建：

```
supabase/functions/fetch-gold-prices/
└── index.ts    ← 代码写在这里
```

### 6.6 编写 Edge Function 代码

打开 `supabase/functions/fetch-gold-prices/index.ts`，写入以下代码：

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

// 从环境变量获取 API Keys
const ALPHA_VANTAGE_API_KEY = Deno.env.get('ALPHA_VANTAGE_API_KEY');
const TWELVE_DATA_API_KEY = Deno.env.get('TWELVE_DATA_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

serve(async (req) => {
  try {
    console.log('🔄 开始获取黄金历史数据...');
    
    // 创建 Supabase 客户端
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    
    // 1️⃣ 获取金价数据
    const goldData = await fetchGoldPrices();
    
    // 2️⃣ 获取汇率数据
    const exchangeRates = await fetchExchangeRates();
    
    // 3️⃣ 合并数据
    const completeData = goldData.map(item => ({
      ...item,
      exchange_rate_usd_cny: exchangeRates.get(item.date) || 7.13
    }));
    
    // 4️⃣ 保存到数据库
    const { error } = await supabase
      .from('gold_historical_prices')
      .upsert(completeData, { onConflict: 'date' });
    
    if (error) throw error;
    
    console.log(`✅ 成功插入 ${completeData.length} 条数据`);
    
    return new Response(JSON.stringify({
      success: true,
      records: completeData.length
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });
    
  } catch (error) {
    console.error('❌ 错误:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});

// 获取金价的函数
async function fetchGoldPrices() {
  const url = `https://www.alphavantage.co/query?function=FX_DAILY&from_symbol=XAU&to_symbol=USD&apikey=${ALPHA_VANTAGE_API_KEY}&outputsize=compact`;
  
  const response = await fetch(url);
  const data = await response.json();
  
  const timeSeries = data['Time Series FX (Daily)'];
  const goldPrices = [];
  
  for (const [date, values] of Object.entries(timeSeries)) {
    goldPrices.push({
      date,
      price_usd_per_ounce: parseFloat(values['4. close']),
      open_price_usd: parseFloat(values['1. open']),
      close_price_usd: parseFloat(values['4. close']),
      high_price_usd: parseFloat(values['2. high']),
      low_price_usd: parseFloat(values['3. low']),
      data_source: 'Alpha Vantage (XAU/USD)'
    });
  }
  
  return goldPrices;
}

// 获取汇率的函数
async function fetchExchangeRates() {
  const url = `https://www.alphavantage.co/query?function=FX_DAILY&from_symbol=USD&to_symbol=CNY&apikey=${ALPHA_VANTAGE_API_KEY}&outputsize=compact`;
  
  const response = await fetch(url);
  const data = await response.json();
  
  const timeSeries = data['Time Series FX (Daily)'];
  const rates = new Map();
  
  for (const [date, values] of Object.entries(timeSeries)) {
    rates.set(date, parseFloat(values['4. close']));
  }
  
  return rates;
}
```

### 6.7 配置环境变量（API Keys）

在 Supabase Dashboard 中：

1. 进入 **Settings → Edge Functions**
2. 找到 **「Secrets」** 部分
3. 添加以下环境变量：

```
ALPHA_VANTAGE_API_KEY = 你的 Alpha Vantage Key
TWELVE_DATA_API_KEY = 你的 12data Key
```

**或者用命令行：**

```bash
# 设置 Alpha Vantage API Key
supabase secrets set ALPHA_VANTAGE_API_KEY=你的Key

# 设置 12data API Key
supabase secrets set TWELVE_DATA_API_KEY=你的Key
```

### 6.8 部署 Edge Function

```bash
# 部署到 Supabase
supabase functions deploy fetch-gold-prices

# 看到以下输出表示成功：
# ✅ Deployed Function fetch-gold-prices
# 🔗 https://你的项目.supabase.co/functions/v1/fetch-gold-prices
```

### 6.9 测试 Edge Function

**方法 1：用浏览器访问**

```
https://你的项目.supabase.co/functions/v1/fetch-gold-prices
```

**方法 2：用命令行**

```bash
curl -X POST https://你的项目.supabase.co/functions/v1/fetch-gold-prices \
  -H "Authorization: Bearer 你的anon密钥"
```

**方法 3：在 Supabase Dashboard 中**

1. 进入 **Edge Functions**
2. 点击 **「fetch-gold-prices」**
3. 点击右上角 **「Invoke」**

成功后，去 **Table Editor** 查看 `gold_historical_prices` 表，应该有数据了！

---

## 7. 配置定时任务（Cron Job）

### 7.1 什么是 Cron Job？

Cron Job 就是「定时闹钟」，可以让 Edge Function 定时自动执行。

### 7.2 启用 pg_cron 扩展

在 **SQL Editor** 中运行：

```sql
-- 启用定时任务扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

### 7.3 启用 pg_net 扩展（用于发起 HTTP 请求）

```sql
-- 启用网络请求扩展
CREATE EXTENSION IF NOT EXISTS pg_net;
```

### 7.4 创建定时任务

```sql
-- 每6小时执行一次（00:00, 06:00, 12:00, 18:00）
SELECT cron.schedule(
    'fetch-gold-prices-every-6-hours',  -- 任务名称
    '0 */6 * * *',                      -- Cron 表达式
    $$
    SELECT net.http_post(
        url := 'https://你的项目.supabase.co/functions/v1/fetch-gold-prices',
        headers := jsonb_build_object(
            'Authorization', 'Bearer ' || '你的service_role密钥'
        )
    );
    $$
);
```

**Cron 表达式说明：**

```
0 */6 * * *
│  │  │ │ │
│  │  │ │ └─ 星期几 (0-7, 0和7都是周日)
│  │  │ └─── 月份 (1-12)
│  │  └───── 日期 (1-31)
│  └──────── 小时 (0-23)
└─────────── 分钟 (0-59)

常见示例：
- 0 */6 * * *  → 每6小时执行（00:00, 06:00, 12:00, 18:00）
- 0 0 * * *    → 每天午夜执行
- 0 12 * * *   → 每天中午12点执行
- */30 * * * * → 每30分钟执行
```

### 7.5 查看定时任务列表

```sql
-- 查看所有定时任务
SELECT * FROM cron.job;
```

### 7.6 删除定时任务

```sql
-- 如果需要删除任务
SELECT cron.unschedule('fetch-gold-prices-every-6-hours');
```

### 7.7 查看任务执行历史

```sql
-- 查看最近10次执行记录
SELECT * FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 10;
```

---

## 8. 在 iOS App 中调用 Supabase

### 8.1 安装 Supabase Swift SDK

在 Xcode 中：

1. **File → Add Package Dependencies...**
2. 输入：`https://github.com/supabase/supabase-swift`
3. 点击 **Add Package**

### 8.2 创建 Supabase 配置文件

创建 `GoldBean/Core/SupabaseConfig.swift`：

```swift
import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    let client: SupabaseClient
    
    private init() {
        // 你的 Supabase 项目 URL
        let supabaseURL = "https://fqckfusbjabhlmkogesv.supabase.co"
        
        // Anon Key（公开密钥，可以放在代码中）
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        print("✅ Supabase 客户端初始化完成")
    }
}
```

### 8.3 创建数据模型

创建 `GoldBean/Models/SupabaseModels.swift`：

```swift
import Foundation

// Supabase 数据库表模型
struct SupabaseGoldPrice: Codable, Identifiable {
    let id: String?
    let date: String
    let priceUsdPerOunce: Double?
    let exchangeRateUsdCny: Double?
    let priceCnyPerGram: Double?
    let dataSource: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case priceUsdPerOunce = "price_usd_per_ounce"
        case exchangeRateUsdCny = "exchange_rate_usd_cny"
        case priceCnyPerGram = "price_cny_per_gram"
        case dataSource = "data_source"
    }
    
    // 转换为 App 内部使用的数据模型
    func toGoldPriceHistory() -> GoldPriceHistory? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let parsedDate = dateFormatter.date(from: date) ?? Date()
        
        guard let cnyPrice = priceCnyPerGram else {
            return nil
        }
        
        return GoldPriceHistory(
            date: parsedDate,
            price: cnyPrice,
            source: "Supabase (\(dataSource ?? "Unknown"))"
        )
    }
}
```

### 8.4 创建 Supabase 服务类

创建 `GoldBean/Services/SupabaseGoldService.swift`：

```swift
import Foundation
import Supabase
import Combine

class SupabaseGoldService {
    static let shared = SupabaseGoldService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseConfig.shared.client
        print("✅ SupabaseGoldService 初始化完成")
    }
    
    // 获取历史价格数据
    func fetchHistoricalPrices(
        startDate: Date,
        endDate: Date = Date()
    ) async throws -> [GoldPriceHistory] {
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        print("📊 从 Supabase 获取历史数据: \(startDateString) 到 \(endDateString)")
        
        // 查询数据库
        let response: [SupabaseGoldPrice] = try await client
            .from("gold_historical_prices")
            .select()
            .gte("date", value: startDateString)
            .lte("date", value: endDateString)
            .order("date", ascending: true)
            .execute()
            .value
        
        print("✅ 成功获取 \(response.count) 条数据")
        
        // 转换为 App 数据模型
        let history = response.compactMap { $0.toGoldPriceHistory() }
        
        return history
    }
    
    // Combine 版本（兼容现有代码）
    func fetchHistoricalPricesPublisher(
        startDate: Date,
        endDate: Date = Date()
    ) -> AnyPublisher<[GoldPriceHistory], Error> {
        
        return Future { promise in
            Task {
                do {
                    let result = try await self.fetchHistoricalPrices(
                        startDate: startDate,
                        endDate: endDate
                    )
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取最新价格
    func fetchLatestPrice() async throws -> GoldPriceHistory? {
        let response: [SupabaseGoldPrice] = try await client
            .from("gold_historical_prices")
            .select()
            .order("date", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return response.first?.toGoldPriceHistory()
    }
}
```

### 8.5 在现有服务中集成

修改 `GoldBean/Services/GoldPriceService.swift`：

```swift
class GoldPriceService: ObservableObject {
    // ... 其他代码 ...
    
    private let supabaseService = SupabaseGoldService.shared
    
    // 获取历史数据
    private func fetchRealHistoryData(timeRange: ChartTimeRange) {
        let endDate = Date()
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -timeRange.days,
            to: endDate
        ) ?? endDate
        
        supabaseService.fetchHistoricalPricesPublisher(
            startDate: startDate,
            endDate: endDate
        )
        .timeout(.seconds(30), scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoadingHistory = false
            
            switch completion {
            case .finished:
                print("✅ Supabase 数据获取完成")
            case .failure(let error):
                print("❌ Supabase 获取失败: \(error.localizedDescription)")
                self?.priceHistory = []
                self?.errorMessage = "暂时无法获取历史数据，请稍后重试"
            }
        } receiveValue: { [weak self] history in
            guard let self = self else { return }
            
            if history.isEmpty {
                print("⚠️ Supabase 数据库中暂无数据")
                self.priceHistory = []
                self.errorMessage = "历史数据暂时不可用，请稍后重试"
            } else {
                print("✅ 成功获取 \(history.count) 条 Supabase 历史数据")
                self.priceHistory = history
                self.updateTrendIndicators(for: timeRange)
                self.cachePriceHistory(history)
                self.errorMessage = nil
            }
        }
        .store(in: &cancellables)
    }
}
```

### 8.6 测试 App 集成

运行 App，你应该能看到：

```
✅ Supabase 客户端初始化完成
✅ SupabaseGoldService 初始化完成
📊 从 Supabase 获取历史数据: 2024-10-10 到 2025-10-10
✅ 成功获取 180 条数据
✅ 成功获取 180 条 Supabase 历史数据
```

---

## 9. 常见问题和解决方案

### 9.1 Edge Function 超时

**问题：** Edge Function 执行超过 10 秒被中断

**解决方案：**

1. **分批获取数据**（我们的实现中已包含）：

```typescript
// 首次运行：获取1年数据
// 回填运行：每次1年
// 增量运行：只获取新数据
```

2. **使用 `outputsize=compact`**：

```typescript
// 只获取最近 100 条数据，速度更快
const url = `...&outputsize=compact`;
```

3. **添加超时控制**：

```typescript
const response = await fetch(url, {
  signal: AbortSignal.timeout(20000)  // 20秒超时
});
```

### 9.2 API 速率限制

**问题：** Alpha Vantage 免费版每天只能调用 25 次

**解决方案：**

1. **使用多个 API 备用**（已实现）：
   - 优先使用 12data (800次/天)
   - 备用 Alpha Vantage (25次/天)

2. **优先从数据库获取**：

```typescript
// 先查数据库，只获取缺失的日期
const { data: existingData } = await supabase
  .from('gold_historical_prices')
  .select('date')
  .gte('date', startDate);

// 只获取数据库中没有的日期
const missingDates = calculateMissingDates(existingData);
```

3. **记录 API 调用次数**：

```sql
-- 查看今天调用了多少次
SELECT api_provider, COUNT(*)
FROM api_call_logs
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

### 9.3 数据解码错误

**问题：** `typeMismatch` 或 `keyNotFound`

**解决方案：**

1. **使用可选类型**：

```swift
// ❌ 错误
let id: Int  // 数据库是 UUID，无法解码

// ✅ 正确
let id: String?  // UUID 返回字符串
```

2. **使用 `compactMap` 过滤无效数据**：

```swift
let history = response.compactMap { $0.toGoldPriceHistory() }
```

3. **添加详细日志**：

```swift
do {
    let response = try await client.from("...").execute().value
} catch let error as DecodingError {
    switch error {
    case .typeMismatch(let type, let context):
        print("类型不匹配: 期望 \(type)")
        print("位置: \(context.codingPath)")
    case .keyNotFound(let key, _):
        print("缺少字段: \(key.stringValue)")
    default:
        print("其他错误: \(error)")
    }
}
```

### 9.4 RLS 策略阻止访问

**问题：** 查询返回空数据，但数据库中有数据

**解决方案：**

```sql
-- 检查 RLS 策略
SELECT * FROM pg_policies
WHERE tablename = 'gold_historical_prices';

-- 如果没有策略，添加一个：
CREATE POLICY "允许所有人读取" ON gold_historical_prices
    FOR SELECT
    USING (true);
```

### 9.5 Cron Job 不执行

**问题：** 定时任务创建成功，但从不运行

**解决方案：**

1. **检查任务状态**：

```sql
SELECT * FROM cron.job WHERE jobname = 'fetch-gold-prices-every-6-hours';
```

2. **检查执行历史**：

```sql
SELECT * FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'fetch-gold-prices-every-6-hours')
ORDER BY start_time DESC
LIMIT 5;
```

3. **手动触发测试**：

```sql
-- 删除旧任务
SELECT cron.unschedule('fetch-gold-prices-every-6-hours');

-- 重新创建
SELECT cron.schedule(...);
```

### 9.6 汇率/金价计算不准确

**问题：** 显示 837 元/克，但实际应该是 900+ 元/克

**原因：**

1. 使用了 GLD ETF 作为代理（不准确）
2. 使用了固定汇率（不准确）

**解决方案：**

1. **使用真实金价 API**：

```typescript
// ✅ 正确：直接获取 XAU/USD
function=FX_DAILY&from_symbol=XAU&to_symbol=USD

// ❌ 错误：使用 GLD ETF
symbol=GLD
```

2. **使用真实历史汇率**：

```typescript
// ✅ 优先从数据库获取
const { data } = await supabase
  .from('exchange_rate_history')
  .select('rate')
  .eq('date', date)
  .single();

// ✅ 备用：从 API 获取
function=FX_DAILY&from_symbol=USD&to_symbol=CNY
```

3. **验证计算公式**：

```sql
-- 在数据库中验证
SELECT 
    date,
    price_usd_per_ounce AS "美元/盎司",
    exchange_rate_usd_cny AS "汇率",
    price_cny_per_gram AS "人民币/克",
    ROUND((price_usd_per_ounce * exchange_rate_usd_cny) / 31.1035, 2) AS "验证值"
FROM gold_historical_prices
ORDER BY date DESC
LIMIT 5;
```

---

## 10. 完整工作流程总结

### 10.1 数据流向图

```
┌─────────────────────────────────────────────────────────────┐
│                    外部数据源                                │
│  ┌──────────────────┐        ┌──────────────────┐           │
│  │ Alpha Vantage    │        │ 12data           │           │
│  │ - 金价 (XAU/USD) │        │ - 金价 (XAU/USD) │           │
│  │ - 汇率 (USD/CNY) │        │ - 汇率 (USD/CNY) │           │
│  └──────────────────┘        └──────────────────┘           │
└─────────────────────────────────────────────────────────────┘
           ↓ 每6小时自动调用
┌─────────────────────────────────────────────────────────────┐
│               Supabase Edge Function                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  fetch-gold-prices                                    │  │
│  │  1. 获取金价数据                                       │  │
│  │  2. 获取汇率数据                                       │  │
│  │  3. 计算人民币价格                                     │  │
│  │  4. 保存到数据库                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
           ↓ 保存数据
┌─────────────────────────────────────────────────────────────┐
│               Supabase Database                             │
│  ┌──────────────────────────────────────┐                   │
│  │ gold_historical_prices               │                   │
│  │ - date: 2024-10-10                   │                   │
│  │ - price_usd_per_ounce: 2650.00      │                   │
│  │ - exchange_rate_usd_cny: 7.13       │                   │
│  │ - price_cny_per_gram: 607.23        │ ← 自动计算        │
│  └──────────────────────────────────────┘                   │
│                                                             │
│  ┌──────────────────────────────────────┐                   │
│  │ exchange_rate_history                │                   │
│  └──────────────────────────────────────┘                   │
│                                                             │
│  ┌──────────────────────────────────────┐                   │
│  │ api_call_logs                        │                   │
│  └──────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
           ↓ API 查询
┌─────────────────────────────────────────────────────────────┐
│                    iOS App                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  GoldPriceService                                     │  │
│  │    ↓                                                  │  │
│  │  SupabaseGoldService                                  │  │
│  │    ↓                                                  │  │
│  │  Supabase Swift SDK                                   │  │
│  │    ↓                                                  │  │
│  │  SupabaseConfig (anon key)                            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  用户看到：                                                 │
│  📈 金价趋势图（6个月、1年、3年、5年）                      │
│  💰 当前金价：¥607.23/克                                   │
└─────────────────────────────────────────────────────────────┘
```

### 10.2 时间线

```
时间点                    发生的事情
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Day 1, 00:00          Cron Job 触发 Edge Function
                      ↓
                      获取金价和汇率（Alpha Vantage）
                      ↓
                      保存到 Supabase 数据库
                      ↓
                      记录日志到 api_call_logs

Day 1, 06:00          Cron Job 再次触发
                      ↓
                      增量更新（只获取新数据）

Day 1, 08:00          用户打开 iOS App
                      ↓
                      App 查询 Supabase
                      ↓
                      获取最近6个月数据
                      ↓
                      绘制趋势图

Day 1, 12:00          Cron Job 触发（第3次）

Day 1, 18:00          Cron Job 触发（第4次）

Day 2, 00:00          循环继续...
```

### 10.3 核心文件清单

**Supabase 端：**

```
supabase/
├── config.toml                          ← 项目配置
└── functions/
    └── fetch-gold-prices/
        └── index.ts                     ← Edge Function 主代码
```

**iOS App 端：**

```
GoldBean/
├── Core/
│   ├── SupabaseConfig.swift             ← Supabase 客户端配置
│   └── CoreDataManager.swift            ← 本地缓存管理
├── Models/
│   ├── SupabaseModels.swift             ← Supabase 数据模型
│   └── GoldPrice.swift                  ← App 数据模型
└── Services/
    ├── SupabaseGoldService.swift        ← Supabase 服务类
    └── GoldPriceService.swift           ← 金价服务（主服务）
```

### 10.4 关键配置总结

| 配置项 | 位置 | 值 |
|-------|------|-----|
| **Supabase URL** | SupabaseConfig.swift | `https://xxx.supabase.co` |
| **Anon Key** | SupabaseConfig.swift | `eyJhbGc...` |
| **Service Role Key** | Supabase Secrets | `eyJhbGc...` |
| **Alpha Vantage Key** | Supabase Secrets | `U2KVUQNN91A9W8Q4` |
| **12data Key** | Supabase Secrets | `你的Key` |
| **Cron 表达式** | SQL Cron Job | `0 */6 * * *` |
| **Edge Function URL** | 自动生成 | `https://xxx.supabase.co/functions/v1/fetch-gold-prices` |

### 10.5 监控和维护

**每日检查清单：**

```sql
-- 1. 检查数据是否正常更新
SELECT date, price_cny_per_gram, data_source
FROM gold_historical_prices
ORDER BY date DESC
LIMIT 5;

-- 2. 检查 API 调用是否成功
SELECT created_at, api_provider, success, error_message
FROM api_call_logs
ORDER BY created_at DESC
LIMIT 10;

-- 3. 检查 Cron Job 执行情况
SELECT jobname, last_run_time, status
FROM cron.job
WHERE jobname LIKE '%gold%';

-- 4. 检查数据完整性
SELECT COUNT(*) AS total_records,
       MIN(date) AS earliest_date,
       MAX(date) AS latest_date
FROM gold_historical_prices;
```

---

## 🎉 恭喜你！

你已经学会了：

✅ 创建 Supabase 项目
✅ 设计和创建数据库表
✅ 配置 Row Level Security
✅ 生成和管理 API Key
✅ 编写和部署 Edge Function
✅ 配置定时任务（Cron Job）
✅ 在 iOS App 中集成 Supabase
✅ 调试和监控数据流

**下一步：**

1. 优化 Edge Function 性能
2. 添加更多数据源
3. 实现数据分析功能
4. 添加用户通知功能

---

## 📚 参考资源

- [Supabase 官方文档](https://supabase.com/docs)
- [Edge Functions 指南](https://supabase.com/docs/guides/functions)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Alpha Vantage API 文档](https://www.alphavantage.co/documentation/)
- [12data API 文档](https://twelvedata.com/docs)

---

**作者：** GoldBean Team  
**更新日期：** 2025-10-10  
**版本：** 1.0

如有问题，请查看 [常见问题](#9-常见问题和解决方案) 章节。

