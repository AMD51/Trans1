//
//  ViewController.swift
//  NewGemini
//
//  Created by Ammad on 15/01/2024.
//

import UIKit
import GoogleGenerativeAI
import Speech
import AVFoundation
import metamask_ios_sdk

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIDocumentPickerDelegate  {
    @IBOutlet weak var questionText: UILabel!
    var audioRecorder: AVAudioRecorder?

    @IBOutlet weak var answerText: UILabel!
    
    @IBOutlet weak var queestionTextField: UITextField!
    var pickedImage: UIImage? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
            
            // Request speech recognition permission
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == .authorized {
                    print("authorized ")
                    // Speech recognition is authorized, you can use the Speech framework
                }
            }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startStopAction(_ sender: Any) {
        toggleRecording()
    }
    @objc func toggleRecording() {
           if let audioRecorder = audioRecorder, audioRecorder.isRecording {
               // Stop recording if already in progress
               audioRecorder.stop()
               print("Recording stopped.")
           } else {
               // Start recording
               startRecording()
           }
       }
    
    func startRecording() {
          let audioSession = AVAudioSession.sharedInstance()

          do {
              try audioSession.setCategory(.playAndRecord, mode: .default)
              try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
              let audioFilename = documentsDirectory.appendingPathComponent("recording.wav")

              let settings: [String: Any] = [
                  AVFormatIDKey: kAudioFormatLinearPCM,
                  AVSampleRateKey: 44100,
                  AVNumberOfChannelsKey: 2,
                  AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
              ]

              audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
              audioRecorder?.delegate = self
              audioRecorder?.record()
              print("Recording started.")
          } catch {
              print("Error setting up audio recording: \(error.localizedDescription)")
          }
      }

      func convertAudioToText(audioFileURL: URL) {
          let recognizer = SFSpeechRecognizer()

          // Create a recognition request
          let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

          // Perform the recognition on the global background queue
          recognizer?.recognitionTask(with: request) { result, error in
              if let error = error {
                  print("Error: \(error)")
                  // Handle the error appropriately
                  return
              }

              if let result = result {
                  if result.isFinal {
                      let transcription = result.bestTranscription.formattedString
                      print("Transcription: \(transcription)")
                      self.queestionTextField.text = transcription
                      // Use the transcribed text as needed
                  }
              }
          }
      }
    
    @objc func chooseAudioFile() {
           let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
           documentPicker.delegate = self
           present(documentPicker, animated: true, completion: nil)
       }

       func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
           if let audioFileURL = urls.first {
               print("File URL is", audioFileURL)
               convertAudioToTextUsingSpeechFramework(audioFileURL)
           }
       }

       func convertAudioToTextUsingSpeechFramework(_ audioFileURL: URL) {
           let recognizer = SFSpeechRecognizer()

           // Create a recognition request
           let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

           // Perform the recognition on the global background queue
           recognizer?.recognitionTask(with: request) { result, error in
               if let error = error {
                   print("Error: \(error)")
                   // Handle the error appropriately
                   return
               }

               if let result = result {
                   if result.isFinal {
                       let transcription = result.bestTranscription.formattedString
                       print("Transcription: \(transcription)")
                       Task {
                           await self.abc4( transcription)
                               }
                    //   abc4(transcription)
                       // Use the transcribed text as needed
                   }
               }
           }
       }
    
    @IBAction func textAction(_ sender: Any) {
        
        Task {
                    await asyncLoadData()
                }
    }
    @IBAction func uploadImage(_ sender: Any) {
        chooseImage()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            // Use the pickedImage as needed
            // For example, display it in an UIImageView
            self.pickedImage = pickedImage
            print("image is", self.pickedImage)
        }

        picker.dismiss(animated: true, completion: nil)
    }

    func chooseImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary // You can also use .camera for the camera
        present(imagePicker, animated: true, completion: nil)
    }

    
    private func asyncLoadData() async {
            // Call the abc function asynchronously using await.
        self.pickedImage == nil ?   await abc() : await abc2()
        }
    
    
    
    func abc3 () async  {
        let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)

        let prompt = queestionTextField.text!
        let response = try? await model.generateContent(prompt)
        if let text = response?.text {
            queestionTextField.text = ""
            questionText.text = prompt
            answerText.text = text
          print(text)
        }
    }
    
    func abc () async  {
        let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)

        let prompt = queestionTextField.text!
        let response = try? await model.generateContent(prompt)
        if let text = response?.text {
            queestionTextField.text = ""
            questionText.text = prompt
            answerText.text = text
          print(text)
        }
    }

    func abc4 (_ responseText: String) async  {
        let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)

        let prompt = responseText
        let response = try? await model.generateContent(prompt)
        if let text = response?.text {
            
            queestionTextField.text = ""
            questionText.text = prompt
            answerText.text = text
          print(text)
            print("Answer is", text)
            print("Question is", prompt)
        }
    }
    
    func abc2 () async  {
        let model = GenerativeModel(name: "gemini-pro-vision", apiKey: APIKey.default)
        
        let image1 = pickedImage!
        debugPrint("Image is", image1)
        let image2 = UIImage(named: "4")
        
        let prompt = "Explain First Picture"
        let res2 = try? await model.generateContentStream(prompt, image1)
        debugPrint("Response for single image is", res2)
        let response = try? await model.generateContent(prompt, image1, UIImage())
        debugPrint("Response is ", response)
        if let text = response?.text {
            print("Answer text is", text)
            queestionTextField.text = ""
          //  questionText.text = prompt
            answerText.text = text
        }
    }
}

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let audioFileURL = recorder.url
            convertAudioToText(audioFileURL: audioFileURL)
        }
    }
}
