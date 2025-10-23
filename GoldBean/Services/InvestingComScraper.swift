import Foundation
import Combine

// MARK: - Investing.com 数据爬取服务（纯 Swift 实现，无第三方依赖）
class InvestingComScraper {
    static let shared = InvestingComScraper()
    
    private let baseURL = "https://cn.investing.com/currencies/xau-cny-historical-data"
    
    // 历史数据结构
    struct HistoricalData: Codable {
        let date: Date
        let closePrice: Double
        let openPrice: Double
        let highPrice: Double
        let lowPrice: Double
        let changePercent: Double
        
        init(date: Date, close: Double, open: Double, high: Double, low: Double, changePercent: Double) {
            self.date = date
            self.closePrice = close
            self.openPrice = open
            self.highPrice = high
            self.lowPrice = low
            self.changePercent = changePercent
        }
    }
    
    // 获取指定时间范围的历史数据
    func fetchHistoricalData(from startDate: Date, to endDate: Date) -> AnyPublisher<[HistoricalData], Error> {
        // 构建带日期参数的URL
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let startDateStr = dateFormatter.string(from: startDate)
        let endDateStr = dateFormatter.string(from: endDate)
        
        // Investing.com 的日期格式参数
        guard let urlString = "\(baseURL)?start_date=\(startDateStr)&end_date=\(endDateStr)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "URLError", code: 0, 
                                      userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
                .eraseToAnyPublisher()
        }
        
        print("🔄 开始爬取 Investing.com 历史数据...")
        print("📅 日期范围: \(startDateStr) - \(endDateStr)")
        print("🔗 URL: \(urlString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", 
                        forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> [HistoricalData] in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "ResponseError", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
                }
                
                print("📡 HTTP状态码: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "HTTPError", code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: "HTTP错误: \(httpResponse.statusCode)"])
                }
                
                guard let html = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "EncodingError", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "HTML编码错误"])
                }
                
                // 解析HTML
                return try self.parseHistoricalDataFromHTML(html)
            }
            .eraseToAnyPublisher()
    }
    
    // 解析HTML中的历史数据表格（使用正则表达式，无需第三方库）
    private func parseHistoricalDataFromHTML(_ html: String) throws -> [HistoricalData] {
        var results: [HistoricalData] = []
        
        print("📊 开始解析 HTML 数据...")
        
        // 调试：保存HTML到文件（仅用于调试）
        #if DEBUG
        saveHTMLForDebug(html)
        #endif
        
        // 方法1: 使用正则表达式提取表格行数据
        // Investing.com 的表格行通常包含在 <tr> 标签中
        let rowPattern = #"<tr[^>]*>(.*?)</tr>"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法创建正则表达式"])
        }
        
        let nsString = html as NSString
        let rowMatches = rowRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        print("📊 找到 \(rowMatches.count) 个表格行")
        
        // 多种日期格式支持
        let dateFormatters = createDateFormatters()
        
        var processedRows = 0
        for match in rowMatches {
            let rowRange = match.range(at: 1)
            guard rowRange.location != NSNotFound else { continue }
            
            let rowHTML = nsString.substring(with: rowRange)
            
            // 提取所有 <td> 单元格的内容
            let cells = extractTableCells(from: rowHTML)
            
            // 调试：打印前几行的单元格数量和内容
            if processedRows < 3 {
                print("📋 第 \(processedRows + 1) 行: \(cells.count) 个单元格")
                if !cells.isEmpty {
                    print("   内容: \(cells.prefix(6))")
                }
                processedRows += 1
            }
            
            // 表格结构: 日期 | 收盘 | 开盘 | 高 | 低 | 涨跌幅
            guard cells.count >= 6 else { 
                if processedRows <= 3 && !cells.isEmpty {
                    print("⚠️ 单元格数量不足: \(cells.count) < 6")
                }
                continue 
            }
            
            let dateStr = cells[0].trimmingCharacters(in: .whitespaces)
            let closeStr = cells[1].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            let openStr = cells[2].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            let highStr = cells[3].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            let lowStr = cells[4].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            let changeStr = cells[5].replacingOccurrences(of: "%", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            
            // 跳过表头行（通常包含"日期"、"收盘"等文字）
            if dateStr.contains("日期") || dateStr.contains("Date") || closeStr.contains("收盘") {
                if processedRows <= 3 {
                    print("⏭️ 跳过表头行: \(dateStr)")
                }
                continue
            }
            
            // 尝试用多种格式解析日期
            var parsedDate: Date?
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateStr) {
                    parsedDate = date
                    break
                }
            }
            
            guard let date = parsedDate,
                  let close = Double(closeStr),
                  let open = Double(openStr),
                  let high = Double(highStr),
                  let low = Double(lowStr),
                  let change = Double(changeStr) else {
                continue
            }
            
            let data = HistoricalData(
                date: date,
                close: close,
                open: open,
                high: high,
                low: low,
                changePercent: change
            )
            
            results.append(data)
        }
        
        print("✅ 成功解析 \(results.count) 条历史数据")
        
        if results.isEmpty {
            throw NSError(domain: "ParseError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "未能解析到任何历史数据"])
        }
        
        return results
    }
    
    // 提取表格单元格内容
    private func extractTableCells(from rowHTML: String) -> [String] {
        var cells: [String] = []
        
        // 提取 <td> 标签中的内容
        let cellPattern = #"<td[^>]*>(.*?)</td>"#
        guard let cellRegex = try? NSRegularExpression(pattern: cellPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return cells
        }
        
        let nsString = rowHTML as NSString
        let cellMatches = cellRegex.matches(in: rowHTML, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in cellMatches {
            let cellRange = match.range(at: 1)
            guard cellRange.location != NSNotFound else { continue }
            
            var cellContent = nsString.substring(with: cellRange)
            
            // 移除 HTML 标签
            cellContent = removeHTMLTags(from: cellContent)
            
            // 移除多余的空白字符
            cellContent = cellContent.trimmingCharacters(in: .whitespacesAndNewlines)
            
            cells.append(cellContent)
        }
        
        return cells
    }
    
    // 移除 HTML 标签
    private func removeHTMLTags(from text: String) -> String {
        var result = text
        
        // 移除所有 HTML 标签
        let tagPattern = #"<[^>]+>"#
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: []) {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: result.count), withTemplate: "")
        }
        
        // 解码 HTML 实体
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        
        return result
    }
    
    // 创建多种日期格式解析器
    private func createDateFormatters() -> [DateFormatter] {
        var formatters: [DateFormatter] = []
        
        let formats = [
            "yyyy年M月d日",      // 2024年1月10日
            "yyyy-MM-dd",         // 2024-01-10
            "yyyy/MM/dd",         // 2024/01/10
            "M月d日, yyyy",       // 1月10日, 2024
            "MMM d, yyyy",        // Jan 10, 2024
            "dd/MM/yyyy"          // 10/01/2024
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "zh_CN")
            formatters.append(formatter)
            
            // 也添加英文环境的formatter
            let enFormatter = DateFormatter()
            enFormatter.dateFormat = format
            enFormatter.locale = Locale(identifier: "en_US")
            formatters.append(enFormatter)
        }
        
        return formatters
    }
    
    // 调试：保存HTML到文件
    private func saveHTMLForDebug(_ html: String) {
        let fileName = "investing_debug_\(Date().timeIntervalSince1970).html"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsPath.appendingPathComponent(fileName)
            do {
                try html.write(to: fileURL, atomically: true, encoding: .utf8)
                print("🐛 HTML已保存到: \(fileURL.path)")
                print("🐛 HTML前500字符: \(String(html.prefix(500)))")
            } catch {
                print("⚠️ 保存HTML失败: \(error.localizedDescription)")
            }
        }
    }
    
}

