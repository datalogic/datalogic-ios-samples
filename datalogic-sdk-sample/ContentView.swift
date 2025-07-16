//
// ©2025 Datalogic S.p.A. and/or its affiliates. All rights reserved.
//

import SwiftUI
import DatalogicSDK

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var viewModel = ContentViewModel()
    @State private var currentTab = 0
    @State private var showExportSheet = false
    @State private var showConfigSheet = false
    @State private var logURL: URL?

    // MARK: - Views
    
    var body: some View {
        VStack {
            headerView
            tabContent
            tabView
        }
        .padding()
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.foreground()
            }
        }
        .onAppear {
            viewModel.startPairing()
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = logURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showConfigSheet) {
            FilePicker { url in
                showConfigSheet = false
                viewModel.applyConfig(from: url)
            }
        }
        .alert("Device disconnected",
               isPresented: $viewModel.showDisconnectionAlert,
               actions: { Button("OK", action: { viewModel.showDisconnectionAlert = false })},
               message: { Text("Disconnected from Codiscan device") })
        .alert("Device unlinked",
               isPresented: $viewModel.showUnlinkAlert,
               actions: {
            Button("Go to settings", action: {
                if let url = URL(string: "App-Prefs:root=General") {
                    UIApplication.shared.open(url)
                }
            })
            Button("Dismiss", action: { viewModel.showUnlinkAlert = false })
        },
               message: { Text("Go to Bluetooth settings and manually forget \(viewModel.showUnlinkAlertName ?? "your Codiscan device") before reconnecting") })
    }
    
    var headerView: some View {
        VStack {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String  {
                Text("App version: \(version) (\(build))")
                Text("Codiscan SDK version: \(Constants.version)")
            }
            if viewModel.isConnected {
                Text("Status: Connected")
                if let deviceDetails = viewModel.deviceDetails {
                    Text("Model: \(deviceDetails.model ?? "")")
                    Text("Serial: \(deviceDetails.serialNumber ?? "")")
                    Text("Sw revision: \(deviceDetails.swRevision ?? "")")
                } else {
                    Text("Device details missing")
                }
            } else {
                Text("Status: Disconnected")
            }
            if let error = viewModel.showError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(.red)
            }
        }
    }
    
    var tabView: some View {
        VStack {
            Picker("", selection: $currentTab) {
                Text("Code").tag(0)
                Text("Config").tag(1)
                Text("Battery").tag(2)
                Text("Logs").tag(3)
            }
            .pickerStyle(.segmented)
        }
    }
    
    var tabContent: some View {
        VStack {
            if currentTab == 0 {
                mainView
            } else if currentTab == 1 {
                configView
            } else if currentTab == 2 {
                batteryView
            } else {
                logView
            }
        }
    }
    
    var mainView: some  View {
        VStack(spacing: 16) {
            Spacer().frame(height: 32)
            switch viewModel.bleStatusService.authorizationStatus {
            case .allowedAlways:
                if let image = viewModel.image, viewModel.isConnected == false {
                    GeometryReader { proxy in
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: proxy.size.width / 2, height: proxy.size.width / 2)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    Text("Code expires in")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(viewModel.timeRemaining)")
                        .font(.system(size: 24, weight: .bold))
                }
            default:
                Text("Bluetooth permission not granted.")
                Button("Go to settings", action: {
                    if let url = URL(string: "App-Prefs:root=General") {
                        UIApplication.shared.open(url)
                    }
                })
            }
            if viewModel.isConnected {
                if let barcodeData = viewModel.barcodeData {
                    Spacer()
                    Text("Barcode ID: \(barcodeData.barcodeID)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Barcode Data: \(barcodeData.data)")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                }
            }
            Spacer()
            HStack {
                Spacer()
                Button("Scan", action: {})
                    .buttonStyle(
                        CustomButtonStyle(
                            onPressed: { viewModel.startReadingBarcode() },
                            onReleased: { viewModel.stopReadingBarcode() })
                    )
                    .disabled(!viewModel.isConnected)
                    .opacity(viewModel.isConnected ? 1 : 0.5)
                Spacer()
                Button("Unlink", action: { viewModel.unlinkDevice() })
                    .buttonStyle(
                        CustomButtonStyle(
                            onPressed: {},
                            onReleased: {})
                    )
                    .disabled(!viewModel.isConnected)
                    .opacity(viewModel.isConnected ? 1 : 0.5)
                Spacer()
            }
            HStack {
                Button("Find my device", action: {
                    viewModel.findMyDevice()
                })
                .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
                .disabled(!viewModel.isConnected)
                .opacity(viewModel.isConnected ? 1 : 0.5)
                Spacer()
                Button("Share Barcodes Log",
                       action: {
                    logURL = exportCSV(from: viewModel.barcodesLog)
                    showExportSheet = logURL != nil
                })
                .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
            }
            Spacer().frame(height: 32)
        }
    }
    
    var configView: some View {
        VStack(spacing: 16) {
            Spacer()
            Button("Load config file",
                   action: {
                showConfigSheet.toggle()
            })
            .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
            .disabled(!viewModel.isConnected)
                        .opacity(viewModel.isConnected ? 1 : 0.5)
            Button("Restore default config",
                   action: { viewModel.applyDefaultConfig() })
            .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
            .disabled(!viewModel.isConnected)
                        .opacity(viewModel.isConnected ? 1 : 0.5)
            Spacer()
        }
    }
    
    var batteryView: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading) {
                    if let batteryData = viewModel.batteryData {
                        let batteryData = Array(batteryData).sorted(by: { $0.key.rawValue < $1.key.rawValue })
                        ForEach(Array(batteryData), id: \.key) { data in
                            if data.key == .batteryCurrent,
                                let intValue = Int(data.value) {
                                Text(data.key.description + ": " + (intValue > 0 ? "Charging" : "Discharging"))
                                    .font(.system(size: 10))
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            } else if data.key == .batteryTemp {
                                Text(data.key.description + ": " + "\((Double(data.value) ?? 0.0)/10)°C")
                                    .font(.system(size: 10))
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            } else {
                                Text(data.key.description + ": " + data.value)
                                    .font(.system(size: 10))
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                            
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke())
        }
    }
    
    var logView: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.eventsLog, id: \.self) {
                        Text($0)
                            .font(.system(size: 10))
                            .frame(maxWidth: .infinity,
                                   alignment: .leading)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke())
            HStack {
                Button("Share",
                       action: {
                    logURL = exportCSV(from: viewModel.eventsLog)
                    showExportSheet = logURL != nil
                })
                .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
                Button("Clear",
                       action: {
                    viewModel.eventsLog.removeAll()
                })
                .buttonStyle(CustomButtonStyle(onPressed: {}, onReleased: {}))
            }
            Spacer()
        }
    }
    
    // MARK: - Functions
    
    func exportCSV(from array: [String]) -> URL? {
        let csvString = array.joined(separator: "\n")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("data.csv")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            debugPrint("Failed to write CSV: \(error.localizedDescription)")
            return nil
        }
    }
}

#Preview {
    ContentView()
}

struct CustomButtonStyle: ButtonStyle {
    var onPressed: () -> Void
    var onReleased: () -> Void
    
    @State private var isPressedWrapper: Bool = false {
        didSet {
            if (isPressedWrapper && !oldValue) {
                onPressed()
            }
            else if (oldValue && !isPressedWrapper) {
                onReleased()
            }
        }
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .padding()
            .frame(minWidth: 100)
            .foregroundStyle(Color.white)
            .background(configuration.isPressed ? Color.gray : Color.black)
            .clipShape(Capsule())
            .frame(height: 44)
            .onChange(of: configuration.isPressed, perform: { newValue in isPressedWrapper = newValue })
    }
}
