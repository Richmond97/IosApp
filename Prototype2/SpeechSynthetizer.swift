//
//  SpeechSynthetizer.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 27/04/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import Speech

class SpeechSynthetizer: UIViewController, SFSpeechRecognizerDelegate{
    
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "en-GB"))
    var recognitionReq: SFSpeechAudioBufferRecognitionRequest?
    var speechReqTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var instructions: String = "nil"
    let serialQueue = DispatchQueue(label: "swiftlee.serial.queue")
    var canSpeak = true
    var synthetizer = AVSpeechSynthesizer()
    

    


    override func viewDidLoad() {
        super.viewDidLoad()
        isAuthorized()
        
        let listeningSession = AVAudioSession.sharedInstance()
        do{
            try listeningSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try listeningSession.setActive(true, options: .notifyOthersOnDeactivation)
        }catch{
            print("Audio session failed to setup")
            synthetizer.delegate = self
        }
    }
    

    func isAuthorized() -> Bool {
        var authorize = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization{
            status in
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
                       
            @unknown default:
                       fatalError()
                }
        }
        return authorize
    }
    public func startListening(withCompletionHandler completionHandler: @escaping((_ instructions: String, _ finshed: Bool) -> Void)){
        if speechReqTask != nil{
                speechReqTask?.cancel()
                speechReqTask = nil
            }
            recognitionReq = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode
            guard let recognitionReg = recognitionReq else {
                fatalError("Request Instance failed")
            }
        
            recognitionReq?.shouldReportPartialResults = true
            speechReqTask = speechRecognizer?.recognitionTask(with: recognitionReg){
                result, error in
                var isLast = false
                if result != nil{
                    isLast = (result?.isFinal)!
                }
                if  error != nil || isLast{
                    
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionReq = nil
                    self.speechReqTask = nil
                    let tts = result?.bestTranscription.formattedString
                    print("you said: \(tts ?? "error")")
                    completionHandler(tts ?? "something went wrong",true)
                }
                else if error != nil{
                    print(error!)
                }
            }
        let audioFormat = inputNode.outputFormat(forBus: 0)
         inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat){
           (audioBuffer: AVAudioPCMBuffer, when: AVAudioTime)
            in
             self.recognitionReq?.append(audioBuffer)
         }
             self.audioEngine.prepare()
         do{
             try self.audioEngine.start()
             
         }catch{
             print("failed to start engine")
             
             }
    completionHandler("",false)
        }
    
    public func startSpeaking(messaage: String, type: String ){
      DispatchQueue.main.async {
             
            self.synthetizer.delegate = self
        //allow speech only when the previus session has been completed
        if self.canSpeak{
                let speechUtterance = AVSpeechUtterance(string: messaage)
                speechUtterance.voice = AVSpeechSynthesisVoice (language: "en-GB")
                speechUtterance.rate = 0.5
                speechUtterance.volume = 0.9
                self.synthetizer.speak(speechUtterance)
                self.canSpeak = true
              }
                else{
                    if type == "obj"{
                            self.synthetizer.stopSpeaking(at: AVSpeechBoundary.immediate)
                        
                    }
                }
        }
    }
}

extension SpeechSynthetizer: AVSpeechSynthesizerDelegate{
    //avoid speech synthetizer to have 2 utterance in one session
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance){
            self.canSpeak = true
            print("finished speaking")
        
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        self.canSpeak = false
        print("started speaking ")
    }
}
