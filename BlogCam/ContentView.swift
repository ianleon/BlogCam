import SwiftUI
import AVKit
import Speech

class SpeechRecognizer {

    var audioEngine = AVAudioEngine()
    var speechRecognizer = SFSpeechRecognizer()!
    var request = SFSpeechAudioBufferRecognitionRequest()
    var callback: (() -> ())?
    
    func makeRecognitionTask() -> SFSpeechRecognitionTask {
        
        
        // Setup audio session
        let node = self.audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer, _) in
            self.request.append(buffer)
        }
        self.audioEngine.prepare()
        try! self.audioEngine.start()
        let keyPhrase: String = "Take a picture"
        let stopPhrase: String = "Stop Listening"
        
        var left:String.Index?

        speechRecognizer.defaultTaskHint = .confirmation
        
        
        let task = speechRecognizer.recognitionTask(with: request) {
            [weak self]
            (res, err) in
            
            guard let self = self else { return }
                
            print("TASK")
            

            DispatchQueue.main.async {
                guard
                    let result = res,
                    !result.isFinal && err == nil else {
                    // Handle finalizing the recognition task
                    print("ENDING")
                    print(err.debugDescription)
                    print("---")
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionTask = nil
                    return
                }
                
                let transcript: String = result.bestTranscription.formattedString
                
                let start: (String.Index) = (left ?? transcript.startIndex)
                
                
                if transcript[start...].lowercased().contains(stopPhrase.lowercased()) {
                    self.audioEngine.stop()
                    self.recognitionTask?.cancel()
                    self.request.endAudio()
                    
                    print(transcript)
                }
                if transcript[start...].lowercased().contains(keyPhrase.lowercased())  {

                    defer {
                        left = transcript.endIndex
                    }
                    
                    print(start, transcript, "-", transcript[start...])
                    
                    self.callback?()
                
                    return
                }
            }
        }
        
        return task
    }
    
    var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        recognitionTask = makeRecognitionTask()
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
    
    var speechRec = SpeechRecognizer()
    
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
        
        let hole = CIFilter.holeDistortion()
        
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
