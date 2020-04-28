//
//  SpeechSynthetizer.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 27/04/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import Speech

class SpeechSynthetizer: UIViewController, SFSpeechRecognitionDelegate{
    
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "en-uk"))
    var recognitionReq: SFSpeechAudioBufferRecognitionRequest?
    var speechReqTask: SFSpeechRecognitionTask
    let audioEngine = AVAudioEngine

    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization{
            status in
            var authorize = false
            switch status{
            case .authorized:
                authorize = true
                print("SR authorized ")
            case .denied:
                print("SR not authorized ")
                authorize = false
            case .notDetermined:
                authorize = false
                print(" SR permission not granted")
            case .restricted:
                authorize = false
                print("SR not supported ")
                
            }
        }

    }
    
   public func startListening(){
        if speechReqTask != nil{
            speechReqTask?.cancel()
            speechReqTask = nil
        }
        let listeningSession = AVAudioSession.sharedInstance() -> String
        do{
            try listeningSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try listeningSession.setActive(true, options: .notifyOthersOnDeactivation)
        }catch{
            print("Audio session failed to setup")
        }
        
        recognitionReq = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionReg = recognitionReq else {
            fatalError("Request Instance failed")
        }
        
        recognitionReq?.shouldReportPartialResults = true
        speechReqTask = speechRecognizer?.recognitionTask(with: recognitionReq, delegate: recognitionReg){
            result, error in
            var isFinal = false
            if result != nil{
                audioEngine.stop()
                inputNode.removeTap(oneBus: 0)
                
                self.recognitionReq = nil
                self.speechReqTask = nil
                
                let instruction = result? as! String
                return instruction
            }
        }
        
    let audioFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat){
            audioBuffer, _ in
            self.recognitionReq?.append(audioBuffer)
        }
        audioEngine.prepare()
        do{
            try audioEngine.start()
            
        }catch{
            print("failed to start engine")
            
        }
    }
}
