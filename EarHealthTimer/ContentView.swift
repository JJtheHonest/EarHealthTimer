//
//  ContentView.swift
//  EarHealthTimer
//
//  Created by 尹家杰 on 2025/10/19.
//

import SwiftUI
import UserNotifications
import CoreAudio
import IOBluetooth

enum AppState {
    case idle
    case wearing
    case resting
}

struct ContentView: View {
    // MARK: - 状态变量
    @State private var isHeadphoneConnected = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var restElapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var checkTimer: Timer? = nil
    
    @State private var state: AppState = .idle
    @State private var limitMinutes: Double = 60
    @State private var restMinutes: Double = 15
    
    // MARK: - 新增设置变量
    @State private var showingSettings = false
    @State private var selectedHeadphoneName: String = UserDefaults.standard.string(forKey: "SelectedHeadphoneName") ?? "AirPods"
    
    // MARK: - 界面布局
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Spacer()
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .padding(8)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.trailing, 10)
            
            Text("Ear Health Timer")
                .font(.largeTitle)
                .bold()
            Text("⏳")
                .font(.largeTitle)
                .bold()
            Text(stateDescription())
                .foregroundColor(colorForState())
                .font(.title2)
                .bold()
            
            Text("当前检测耳机：\(selectedHeadphoneName)")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text("已佩戴时间：\(formattedTime(elapsedTime))")
                .font(.title2)
            Text("已休息时间：\(formattedTime(restElapsed))")
                .font(.title2)
            
            ProgressView(value: progressValue())
                .progressViewStyle(LinearProgressViewStyle(tint: colorForState()))
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("⏰ 提醒间隔（分钟）: \(Int(limitMinutes))")
                Slider(value: $limitMinutes, in: 30...120, step: 5) { Text("") } minimumValueLabel: { Text("30") } maximumValueLabel: { Text("120") }
                
                Text("🛌 休息时间（分钟）: \(Int(restMinutes))")
                Slider(value: $restMinutes, in: 5...60, step: 5) { Text("") } minimumValueLabel: { Text("5") } maximumValueLabel: { Text("60") }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 340, height: 440)
        .sheet(isPresented: $showingSettings) {
            SettingsView(selectedDeviceName: $selectedHeadphoneName)
        }
        .onChange(of: selectedHeadphoneName) { newValue in
            UserDefaults.standard.set(newValue, forKey: "SelectedHeadphoneName")
        }
        .onAppear {
            requestNotificationPermission()
            startMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
            checkTimer?.invalidate()
        }
    }
    
    // MARK: - UI 辅助函数
    func stateDescription() -> String {
        switch state {
        case .idle:
            return isHeadphoneConnected ? "检测到耳机，请开始佩戴" : "等待连接 \(selectedHeadphoneName)..."
        case .wearing:
            return "🎧 正在佩戴耳机"
        case .resting:
            return "👂 请让你的耳朵休息 \(Int(restMinutes)) 分钟"
        }
    }
    
    func colorForState() -> Color {
        switch state {
        case .wearing: return .green
        case .resting: return .orange
        case .idle: return .gray
        }
    }
    
    func progressValue() -> Double {
        switch state {
        case .wearing:
            return elapsedTime / (limitMinutes * 60)
        case .resting:
            return restElapsed / (restMinutes * 60)
        default:
            return 0
        }
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - CoreAudio 检测
    func getCurrentOutputDeviceName() -> String? {
        var defaultDeviceID = AudioDeviceID(0)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size,
            &defaultDeviceID
        )
        guard status == noErr else { return nil }
        
        var deviceName: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let nameStatus = AudioObjectGetPropertyData(
            defaultDeviceID,
            &nameAddress,
            0,
            nil,
            &nameSize,
            &deviceName
        )
        guard nameStatus == noErr else { return nil }
        return deviceName as String
    }
    
    func checkIfHeadphoneConnected() -> Bool {
        if let name = getCurrentOutputDeviceName() {
            return name.contains(selectedHeadphoneName)
        }
        return false
    }
    
    // MARK: - 通知逻辑
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 主监控逻辑
    func startMonitoring() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let connected = checkIfHeadphoneConnected()
            
            switch state {
            case .idle:
                if connected {
                    isHeadphoneConnected = true
                    state = .wearing
                    startWearingTimer()
                }
            case .wearing:
                if !connected {
                    state = .resting
                    stopTimer()
                    restElapsed = 0
                    startRestTimer()
                }
            case .resting:
                if connected {
                    state = .wearing
                    stopTimer()
                    elapsedTime = 0
                    startWearingTimer()
                }
            }
        }
    }
    
    // MARK: - 佩戴计时逻辑
    func startWearingTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            if elapsedTime >= limitMinutes * 60 {
                sendNotification(title: "🎧 休息提醒", body: "你已佩戴 \(Int(limitMinutes)) 分钟，请摘下耳机休息 \(Int(restMinutes)) 分钟。")
                stopTimer()
            }
        }
    }
    
    // MARK: - 休息计时逻辑
    func startRestTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            restElapsed += 1
            if restElapsed >= restMinutes * 60 {
                sendNotification(title: "🟢 休息结束", body: "你已休息 \(Int(restMinutes)) 分钟，可以重新佩戴耳机。")
                stopTimer()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
