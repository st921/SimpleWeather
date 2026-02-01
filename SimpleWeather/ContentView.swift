
//
//  ContentView.swift
//  SimpleWeather
//
//  Created by しょう on 2026/01/31.
//

import SwiftUI

// データモデル
struct WeatherData: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int //これを使って天気アイコンを決める
}

struct ContentView: View {
    @State private var temperature: String = "---"
    @State private var weatherIcon: String = "questionmark" // アイコンの名前
    @State private var weatherText: String = "読み込み中..."
    
    var body: some View {
        VStack(spacing: 20) {
            // 天気アイコン
            Image(systemName: weatherIcon)
                .font(.system(size: 100))
                .symbolRenderingMode(.multicolor) //アイコンをカラフルにする
                .padding()
            
            Text(weatherText)
                .font(.title)
                .bold()
            
            Text("\(temperature) ℃")
                .font(.system(size: 60, weight: .bold))
            
            Button(action: {
                Task { await fetchWeather() }
            }) {
                Text("更新する")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .task {
            await fetchWeather()
        }
    }
    
    func fetchWeather() async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=35.6895&longitude=139.6917&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
            
            // 画面を更新
            DispatchQueue.main.async {
                let code = decodedData.current_weather.weathercode
                let temp = decodedData.current_weather.temperature
                
                self.temperature = String(temp)
                self.weatherIcon = getWeatherIconName(code: code)
                self.weatherText = getWeatherDescription(code: code)
            }
            
        } catch {
            print("エラー: \(error)")
        }
    }
    
    //数字をアイコン名(String)に変換する翻訳機
    func getWeatherIconName(code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"       // 快晴
        case 1, 2, 3: return "cloud.sun.fill" // 晴れ〜曇り
        case 45, 48: return "cloud.fog.fill"  // 霧
        case 51...67: return "cloud.rain.fill" // 雨
        case 71...77: return "cloud.snow.fill" // 雪
        case 80...82: return "cloud.heavyrain.fill" // にわか雨
        case 95...99: return "cloud.bolt.rain.fill" // 雷雨
        default: return "questionmark"
        }
    }
    
    //数字を日本語の説明に変換する翻訳機
    func getWeatherDescription(code: Int) -> String {
        switch code {
        case 0: return "快晴"
        case 1, 2, 3: return "晴れ/曇り"
        case 45, 48: return "霧"
        case 51...67: return "雨"
        case 71...77: return "雪"
        case 95...99: return "雷雨"
        default: return "不明"
        }
    }
}

#Preview {
    ContentView()
}
