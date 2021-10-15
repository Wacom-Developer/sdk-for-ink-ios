//
//  FileManager.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 1.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import MobileCoreServices
import WacomInk

extension SerializationQuartz2DController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let url = urls.first!
        if isLoad {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    // Handle the failure here.
                    throw "Could not access security scoped resources"
                }
                
                // Make sure you release the security-scoped resource when you are done.
                defer { url.stopAccessingSecurityScopedResource() }
            
                try serializationModel!.load(url: url, viewLayer: view.layer)
            } catch {
                NSException(name:NSExceptionName(rawValue: "SerializationQuartz2DController.documentPicker"), reason:"\(error)", userInfo:nil).raise()
            }
            isRTreeLeavesShowHandler()
        } else {
            saveModel!.selectedFolderURL = url
            absolutePathLabel.text = saveModel!.validateMessage//result.message
        }
    }
    
    func clickSaveButtonHandler() throws {
        //let validate = saveModel!.validate()
        if saveModel!.isValid {//, fileName = fileNameTextField.text {
            
            var urlToSave = saveModel!.selectedFolderURL!.appendingPathComponent("\(saveModel!.selectedFileName!).uim")
            if urlToSave.checkFileExist() {
                let date = Date()
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let formattedDate = format.string(from: date)
                urlToSave = saveModel!.selectedFolderURL!.appendingPathComponent("\(saveModel!.selectedFileName!)_\(formattedDate).uim")
            }
            
            guard saveModel!.selectedFolderURL!.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                assert(false, "Could not access security scoped context")
                return
            }
            
            defer { saveModel!.selectedFolderURL!.stopAccessingSecurityScopedResource() }
            
            try serializationModel!.save(urlToSave)//, name: saveNameFile)
            absolutePathLabel.text = "Saved successfully in \(urlToSave.path)"
            print("Saved successfully")
        } else {
            absolutePathLabel.text = saveModel!.validateMessage
        }
    }
    
    func clickBrowseButtonHandler() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        
        isLoad = false
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    func clickLoadButtonHandler() {
        let documentPicker: UIDocumentPickerViewController!
        
        documentPicker =  UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        isLoad = true
        documentPicker.delegate = self
        
        present(documentPicker, animated: true, completion: nil)
    }
}
