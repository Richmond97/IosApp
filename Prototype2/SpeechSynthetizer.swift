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


    override func viewDidLoad() {
        super.viewDidLoad()
        isAuthorized()
        
        let listeningSession = AVAudioSession.sharedInstance()
        do{
            try listeningSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try listeningSession.setActive(true, options: .notifyOthersOnDeactivation)
        }catch{
            print("Audio session failed to setup")
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
                   //    self.tapGesture.isEnabled = authorize
                print("SR authorized ")
            case .denied:
                print("SR not authorized ")
                authorize = false
                   //    self.tapGesture.isEnabled = authorize
            case .notDetermined:
                authorize = false
                print(" SR permission not granted")
                  //     self.tapGesture.isEnabled = authorize
            case .restricted:
                authorize = false
                print("SR not supported ")
                  //     self.tapGesture.isEnabled = authorize
                       
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
          /*  let listeningSession = AVAudioSession.sharedInstance()
            do{
                try listeningSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try listeningSession.setActive(true, options: .notifyOthersOnDeactivation)
            }catch{
                print("Audio session failed to setup")
            }*/
        
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
                //error != nil ||
                if  error != nil || isLast{
                    
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionReq = nil
                    self.speechReqTask = nil
                  //  self.tapGesture.isEnabled = true
                    let tts = result?.bestTranscription.formattedString
                 //   self.lblDirection.text = tts
                    print("you said: \(tts ?? "error")")
                   // self.instructions = tts!
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
    
    public func startSpeaking(messaage: String){
        DispatchQueue.main.async {
             let synthetizer = AVSpeechSynthesizer()
              //  DispatchQueue.global(qos: .background).sync {
               // if !synthetizer.isSpeaking{
            if self.canSpeak{
                let speechUtterance = AVSpeechUtterance(string: messaage)
                speechUtterance.postUtteranceDelay = 5
                speechUtterance.voice = AVSpeechSynthesisVoice (language: "en-GB")
                speechUtterance.rate = 0.5
               // speechUtterance.pitchMultiplier = 0.1
                speechUtterance.volume = 0.9
                //let synthetizer = AVSpeechSynthesizer()
                synthetizer.speak(speechUtterance)
               // self.canSpeak = false
                    
                }
                else{

                    synthetizer.stopSpeaking(at: AVSpeechBoundary.word)
                  //  DispatchQueue.main.asyncAfter(deadline: .now() + 10){}
                print("can not speak ")
                                        
                }
        }

        
    }
}


extension SpeechSynthetizer:AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance){
        self.canSpeak = true
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        self.canSpeak = false
    }
}
