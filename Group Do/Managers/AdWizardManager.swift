//
//  AdWizardManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 5/2/24.
//

import Foundation
import AdWizard

enum AdWizardEvent: String {
    case registration
    case taskGroupCreated
    case personalTaskCategoryCreated
}

final class AdWizardManager {
    
    static let shared = AdWizardManager()
    private init() {}
    
    private let adWizard = AdWizard(apiKey: "675c7c37-e8b2-4cbb-8402-984195a4450c")
    
    func registerDownload() {
        adWizard.registerDowload()
    }
    
    func registerEvent(event: AdWizardEvent) {
        adWizard.sendEvent(eventName: event.rawValue)
    }
}
