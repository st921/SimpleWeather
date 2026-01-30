
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

// その中にある「今の天気」の形
struct CurrentWeather: Codable {
    let temperature: Double // 気温
    let weathercode: Int    // 天気コード（晴れとか曇りとか）
}

struct ContentView: View {
    // 画面に表示するデータ
    @State private var temperature: String = "---"
    
    var body: some View {
        VStack {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .padding()
            
            Text("東京の気温")
                .font(.title)
                .foregroundColor(.gray)
            
            // 気温を表示
            Text("\(temperature) ℃")
                .font(.system(size: 60, weight: .bold))
                .padding()
            
            Button("更新") {
                // ボタンを押したら天気を取得
                Task {
                    await fetchWeather()
                }
            }
        }
        // アプリ起動時にも自動で取得
        .task {
            await fetchWeather()
        }
    }
    
    // 2. データを取ってくる機能 (API通信)
    func fetchWeather() async {
        // 1. URLの準備（東京の場所を指定）
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=35.6895&longitude=139.6917&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        do {
            //インターネット経由でデータを取ってくる
            let (data, _) = try await URLSession.shared.data(from: url)
            
            //JSONをSwiftのデータ(WeatherData)に変換する
            let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
            
            //画面を更新する
            temperature = String(decodedData.current_weather.temperature)
            
        } catch {
            print("エラーが出ました: \(error)")
        }
    }
}
#Preview {
    ContentView()
}
