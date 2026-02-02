
//
//  ContentView.swift
//  SimpleWeather
//
//  Created by しょう on 2026/01/31.
//

import SwiftUI

struct WeatherData: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
    // ★追加：昼(1)か夜(0)かのデータ
    let is_day: Int
}

struct ContentView: View {
    @State private var temperature: String = "---"
    @State private var weatherIcon: String = "questionmark"
    @State private var weatherText: String = "読み込み中..."
    // 背景色を変えるためにも使えるので、状態として持っておく
    @State private var isDay: Bool = true
    
    var body: some View {
        ZStack {
            // ★背景色も昼夜で変えてみる（おまけ）
            LinearGradient(
                gradient: Gradient(colors: isDay ? [.blue, .cyan] : [.black, .gray]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: weatherIcon)
                    .font(.system(size: 100))
                    .symbolRenderingMode(.multicolor)
                    .padding()
                    // 影をつけて見やすくする
                    .shadow(color: .white.opacity(0.5), radius: 10)
                
                Text(weatherText)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white) // 背景があっても見えるように白文字
                
                Text("\(temperature) ℃")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                Button(action: {
                    Task { await fetchWeather() }
                }) {
                    Text("更新する")
                        .padding()
                        .background(Color.white.opacity(0.2)) // 半透明ボタン
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
        }
        .task {
            await fetchWeather()
        }
    }
    
    func fetchWeather() async {
        // URLは同じ
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=35.6895&longitude=139.6917&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
            
            DispatchQueue.main.async {
                let current = decodedData.current_weather
                
                self.temperature = String(current.temperature)
                // 1ならtrue(昼)、0ならfalse(夜)
                let isDaytime = current.is_day == 1
                self.isDay = isDaytime
                
                // アイコンを決める関数に「昼か夜か」の情報も渡す
                self.weatherIcon = getWeatherIconName(code: current.weathercode, isDay: isDaytime)
                
                self.weatherText = getWeatherDescription(code: current.weathercode)
            }
            
        } catch {
            print("エラー: \(error)")
        }
    }
    
    // ★引数に isDay: Bool を追加
    func getWeatherIconName(code: Int, isDay: Bool) -> String {
        // もし「夜」なら、特定のアイコンを月にする
        if !isDay {
            switch code {
            case 0: return "moon.stars.fill"       // 夜の快晴
            case 1, 2, 3: return "cloud.moon.fill" // 夜の曇り
            default: break // 雨などは昼夜共通にする（そのまま下のswitchへ）
            }
        }
        
        // 昼（または夜でも雨など共通のもの）
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
