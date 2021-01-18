import SwiftUI
import AVKit
import Speech

extension String {
    func occurrences(_ keyPhrase:String) -> Int {
        self.components(separatedBy: keyPhrase).count - 1
    }
}

struct Microphone {
    static let audioEngine = AVAudioEngine()
    static func tap(block: @escaping AVAudioNodeTapBlock) throws {
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let node = Microphone.audioEngine.inputNode
        let fmt = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt, block: block)
        try audioEngine.start()
    }
    
    static func untap() {
        Microphone.audioEngine.inputNode.removeTap(onBus: 0)
    }
}

class VoiceTrigger {

    var speechRecognizer = SFSpeechRecognizer()!
    var request = SFSpeechAudioBufferRecognitionRequest()
    var task: SFSpeechRecognitionTask!
    var callback: (() -> ())?
    var picturesTaken = 0
    
    let keyPhrase = "Take a picture"
    let stopPhrase = "Stop Listening"
    
    func makeRecognitionTask() {
        
        self.picturesTaken = 0
        
        // Setup audio session
        try! Microphone.tap {
            [weak self]
            (buffer, _) in
            self?.request.append(buffer)
        }
        
        request.contextualStrings = [keyPhrase, stopPhrase]
                
        self.task = speechRecognizer.recognitionTask(with: request) {
            [weak self]
            
            (res, err) in
            
            guard let self = self else {
                print("")
                return
            }
            
            DispatchQueue.main.async {
                guard
                    let result = res,
                    err == nil,
                    !result.isFinal
                
                    else {
                    // Handle finalizing the recognition task
                    print("ENDING ", err?.localizedDescription, " --- res ", res?.isFinal)
                    Microphone.untap()
                    self.request.endAudio()
                    self.task.cancel()
                    self.makeRecognitionTask()
                    return
                }
                
                let transcript: String = result.bestTranscription.formattedString
                
//                let start: (String.Index) = (left ?? transcript.startIndex)
//                print("TASK", self.picturesTaken, transcript)
                
                
                if transcript.occurrences(self.stopPhrase) > 0 {
                    self.request.endAudio()
                    self.task.finish()
                    Microphone.untap()
                    print(transcript)
                }
                if transcript.occurrences(self.keyPhrase) > self.picturesTaken  {

                    defer {
                        self.picturesTaken += 1
                    }
                    print(self.picturesTaken, transcript)
                    self.callback?()
                    return
                }
            }
        }
    }
    
    
    
    init() {
        makeRecognitionTask()
    }
}

struct ContentView: View  {
    var session = AVCaptureSession()
    
    var framesOut = AVCaptureVideoDataOutput()
    var photoOut = AVCapturePhotoOutput()
    let framesQueue = DispatchQueue(
        label: "com.ianleon.blogcam",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    let viewfinder = Viewfinder(
        frame: .zero,
        device: MTLCreateSystemDefaultDevice()!
    )
    
    var speechRec = VoiceTrigger()
    
    func takePicture() {
        photoOut.capturePhoto(
            with: AVCapturePhotoSettings(),
            delegate: viewfinder
        )
    }
    
    var body: some View {
        
        // START Setting configuration properties
        session.beginConfiguration()
        
        // Get the capture device
        DEVICE : if let frontCameraDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) {

            // Set the capture device
            do {
                try! session.addInput(AVCaptureDeviceInput(device: frontCameraDevice))
            }
        }
        
        if session.canAddOutput(framesOut) {
            session.addOutput(framesOut)
        }
        
        if session.canAddOutput(photoOut) {
            session.addOutput(photoOut)
        }
        
        framesOut.setSampleBufferDelegate(
            viewfinder,
            queue: framesQueue
        )
        
        // Connection configuratoins
        CONNECTION : for connection in session.connections {
            
            // Handle orientation and mirroring properly
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        // END Setting configuration properties
        session.commitConfiguration()

        // Start the AVCapture session
        session.startRunning()
        
        let pixellate = CIFilter.pixellate()
        pixellate.scale = 40
        
        let invert = CIFilter.colorInvert()
        
        _ = CIFilter.holeDistortion()
        
        let hue = CIFilter.hueAdjust()
        hue.angle = .pi
        
        let sharp = CIFilter.sharpenLuminance()
        sharp.sharpness = 40
        
        let unsharp = CIFilter.unsharpMask()
        unsharp.radius = 40
                
        let bloom = CIFilter.bloom()
        bloom.radius = 25
        
        let convolution = CIFilter.convolution3X3()
        convolution.weights = .init(values: [  0, 1,0,
                                              -1, 0,1,
                                               0,-1,0], count: 9)
        convolution.bias = 0.6
        
        let motionBlur = CIFilter.motionBlur()
        motionBlur.radius = 20
        
        let zoom = CIFilter.zoomBlur()
        zoom.amount = 20
        zoom.center = .init(x: 500, y: 500)
        
        viewfinder.filter = invert
        
        speechRec.callback = {
            self.takePicture()
        }
        
        return Rep(view: viewfinder)
    }
}
