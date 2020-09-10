//
//  UIDocumentPickerSaveModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 1.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import Foundation

class UIDocumentPickerSaveModel {
    var selectedFolderURL: URL? = nil
    var selectedFileName: String? = nil
    
    var isValid: Bool {
        if selectedFileName != nil && !selectedFileName!.isEmpty && selectedFolderURL != nil {
            return true
        }
        else {
            return false
        }
    }
    
    var validateMessage: String {
        if selectedFileName != nil && !selectedFileName!.isEmpty {
            if selectedFolderURL != nil {
                return "\(selectedFolderURL!)\(selectedFileName!).uim"
            } else {
                return "Choose folder to save"
            }
        } else {
            return "Choose file name to save"
        }
    }
}
