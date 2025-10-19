import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Binding var selectedDeviceName: String
    @Environment(\.dismiss) private var dismiss
    @State private var availableDevices: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("← 返回") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()

            Text("设置")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                Text("请选择你的耳机设备：")
                    .font(.headline)

                Picker("耳机设备", selection: $selectedDeviceName) {
                    ForEach(availableDevices, id: \.self) { device in
                        Text(device)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedDeviceName) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "SelectedDeviceName")
                }
            }
            .padding()

            Spacer()
        }
        .onAppear(perform: loadAudioDevices)
        .frame(width: 400, height: 300)
    }

    func loadAudioDevices() {
        availableDevices = AVCaptureDevice.devices(for: .audio).map { $0.localizedName }
        if !availableDevices.contains(selectedDeviceName) {
            selectedDeviceName = availableDevices.first ?? "未知设备"
        }
    }
}
