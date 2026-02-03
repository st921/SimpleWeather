
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
    let weathercode: Int
    let is_day: Int
    let windspeed: Double
}

struct ContentView: View {
    @State private var temperature: String = "---"
    @State private var weatherIcon: String = "questionmark"
    @State private var weatherText: String = "読み込み中..."
    @State private var windSpeed: String = "-"
    @State private var isDay: Bool = true
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: isDay ? [.blue, .cyan] : [.black, .gray]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // メインの天気表示
                VStack(spacing: 10) {
                    Image(systemName: weatherIcon)
                        .font(.system(size: 100))
                        .symbolRenderingMode(.multicolor)
                        .shadow(color: .white.opacity(0.5), radius: 10)
                    
                    Text(weatherText)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(temperature) ℃")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // 詳細データのパネル
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "wind")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("風速")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(windSpeed) m/s")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    
                    VStack {
                        Image(systemName: "location.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("場所")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("東京")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                }
                
                Spacer()
                
                Button(action: {
                    Task { await fetchWeather() }
                }) {
                    Text("情報を更新")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .task {
            await fetchWeather()
        }
    }
    
    // データ取得関数
    func fetchWeather() async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=35.6895&longitude=139.6917&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
            
            DispatchQueue.main.async {
                let current = decodedData.current_weather
                
                self.temperature = String(current.temperature)
                self.windSpeed = String(current.windspeed)
                
                let isDaytime = current.is_day == 1
                self.isDay = isDaytime
                
                // ここでエラーが出ていたはずです
                self.weatherIcon = getWeatherIconName(code: current.weathercode, isDay: isDaytime)
                self.weatherText = getWeatherDescription(code: current.weathercode)
            }
            
        } catch {
            print("エラー: \(error)")
        }
    }
    
    // ★ここが抜けていませんでしたか？
    // アイコン変換
    func getWeatherIconName(code: Int, isDay: Bool) -> String {
        if !isDay {
            switch code {
            case 0: return "moon.stars.fill"
            case 1, 2, 3: return "cloud.moon.fill"
            default: break
            }
        }
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67: return "cloud.rain.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "questionmark"
        }
    }
    
    // 天気名変換
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
