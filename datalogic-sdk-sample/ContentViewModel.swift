//
// ©2025 Datalogic S.p.A. and/or its affiliates. All rights reserved.
//

import DatalogicSDK
import UIKit
import Combine
import CoreBluetooth

class ContentViewModel: ObservableObject, DeviceManagerDelegate {
    private var cancellables: Set<AnyCancellable> = []
    private var formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    @Published var isConnected = false
    @Published var showRestoredAlert = false
    @Published var image: UIImage?
    @Published var deviceDetails: DeviceDetails?
    @Published var batteryData: BatteryData?
    @Published var barcodeData: BarcodeData?
    @Published var eventsLog: [String] = []
    @Published var barcodesLog: [String] = []
    @Published var showDisconnectionAlert: Bool = false
    @Published var showUnlinkAlertName: String? = nil
    @Published var showUnlinkAlert: Bool = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Published var timeRemaining = 60

    let deviceManager: DeviceManager
    let bleStatusService = BLEStatusService()
    
    init() {
        self.deviceManager = DeviceManager()
        setup()
    }
    
    func foreground() {
        Task {
            await deviceManager.appMovedToForeground()
        }
    }
    
    func setup() {
        Task {
            await deviceManager.setDelegate(self)
        }
    }
    
    func startPairing() {
        Task {
            await deviceManager.startPairing()
        }
        timer
            .sink(receiveValue: { [weak self] _ in
                if self?.timeRemaining ?? 0 > 0 {
                    self?.timeRemaining -= 1
                }
            })
            .store(in: &cancellables)
    }
    
    func stopPairing() {
        Task {
            await deviceManager.stopPairing()
        }
    }
    
    func getDeviceDetails() {
        Task {
            deviceDetails = await deviceManager.getDeviceDetails()
        }
    }
    
    func getBatteryData() {
        Task {
            batteryData = await deviceManager.getBatteryData()
        }
    }
    
    func startReadingBarcode() {
        Task {
            await deviceManager.startReadingBarcode()
        }
    }
    
    func stopReadingBarcode() {
        Task {
            await deviceManager.stopReadingBarcode()
        }
    }
    
    func applyConfig(from url: URL) {
        Task {
            await deviceManager.applyConfig(from: url)
        }
    }
    
    func applyDefaultConfig() {
        Task {
            await deviceManager.restoreDefaultConfig()
        }
    }
    
    func findMyDevice() {
        Task {
            await deviceManager.findMyDevice()
        }
    }
    
    func unlinkDevice() {
        Task {
            await deviceManager.unlinkDevice()
        }
    }
    
    // MARK: - DeviceManagerDelegate
    
    func didGeneratePairingBarcode(_ barcode: UIImage) {
        DispatchQueue.main.async {
            self.image = barcode
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Barcode generated", at: 0)
            self.timeRemaining = 60
        }
    }
    
    func didConnect() {
        DispatchQueue.main.async {
            self.showDisconnectionAlert = false
            self.isConnected = true
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Connected", at: 0)
        }
    }
    
    func didRestoreConnection() {
        DispatchQueue.main.async {
            self.showDisconnectionAlert = false
            self.showRestoredAlert = true
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Restored connection with paired device", at: 0)
        }
    }
    
    func didUpdateBatteryData(_ value: BatteryData) {
        DispatchQueue.main.async {
            self.batteryData = value
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Battery data updated", at: 0)
        }
    }
    
    func didUpdateDeviceDetails(_ value: DeviceDetails) {
        DispatchQueue.main.async {
            self.deviceDetails = value
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Device details updated", at: 0)
        }
    }
    
    func didReadBarcodeData(_ value: BarcodeData) {
        DispatchQueue.main.async {
            self.barcodeData = value
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Barcode data updated \(value.data)", at: 0)
            self.barcodesLog.append("\(self.formatter.string(from: Date())) - \(value.data)")

        }
    }
    
    func didSetConfigData(_ values: [ConfigValue]) {
        DispatchQueue.main.async {
            for value in values {
                self.eventsLog.insert("\(self.formatter.string(from: Date())) - Did set \(value.code) \(value.data)", at: 0)
            }
        }
    }
    
    func didGetConfigData(_ values: [ConfigValue]) {
        DispatchQueue.main.async {
            for value in values {
                self.eventsLog.insert("\(self.formatter.string(from: Date())) - Did get \(value.code) \(value.data)", at: 0)
            }
        }
    }
    
    func didDisconnect() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Disconnected", at: 0)
            self.showDisconnectionAlert = true
        }
    }
    
    func didUnlink() {
        DispatchQueue.main.async {
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Unlinked", at: 0)
            self.isConnected = false
            self.showUnlinkAlert = true
        }
    }
    
    func didFailWith(error: DeviceManagerError) {
        DispatchQueue.main.async {
            self.eventsLog.insert("\(self.formatter.string(from: Date())) - Error \(error.localizedDescription)", at: 0)
            if case let .ble(error) = error,
                case let .connectionFailed(error, name) = error,
                (error as NSError).code == 14 {
                self.showUnlinkAlertName = name
                self.showUnlinkAlert = true
            }
        }
    }
}
