//
// ©2025 Datalogic S.p.A. and/or its affiliates. All rights reserved.
//

import CoreBluetooth
import Foundation

class BLEStatusService: NSObject, ObservableObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?

    @Published var authorizationStatus: CBManagerAuthorization = CBCentralManager.authorization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.authorizationStatus = CBCentralManager.authorization
    }
}
