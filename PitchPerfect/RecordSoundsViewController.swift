//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by danglisheng on 2020/8/20.
//  Copyright © 2020 dang lisheng. All rights reserved.
//

import UIKit
import AVFoundation

// AVAudioRecorderDelegate  音频录音器对象的代理
// 该协议中的所有方法都是可选的。它们允许代理响应音频中断、音频解码错误以及录音的完成
// A class in Swift can only inherit from one single superclass, but it can conform to as many
// as protocols as we want.
class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {
    
    var audioRecorder: AVAudioRecorder!

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordButton:UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("viewDidLoad")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear called")
        stopRecordingButton.isEnabled = false
    }
   

    @IBAction func recordAudio(_ sender: Any) {
        
        recordingLabel.text = "Recording in Progress"
        stopRecordingButton.isEnabled = true
        recordButton.isEnabled = false
        
        print(AVCaptureDevice.authorizationStatus(for: .audio).rawValue)
        switch AVCaptureDevice.authorizationStatus(for: .audio){
        case .authorized:
            print("authorized")
        case .notDetermined:
            print("not determined")
            AVCaptureDevice.requestAccess(for: .audio) { (granted) in
                print("request over")
                if(granted){
                    print("granted")
                }
            }
        case .denied:
            return
        case .restricted:
            return
        @unknown default:
            return
        }
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        print(filePath!)
        
        // 该对象就如何在App中使用音频与系统沟通
        let session = AVAudioSession.sharedInstance()
        
        // func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions = []) throws
        // category: 应用在音频会话上的类型
        // mode:应用有音频会话上的音频会话模式
        // options:
        // playAndRecord 用于音频录制（输入）及回放（输出）的类别
        // static let playAndRecord: AVAudioSession.Category
        // AVAudioSession.Category 它是个结构体，是音频会话类别标识符
        // 音频会话类别标识符定义了一组音频行为。
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options:AVAudioSession.CategoryOptions.defaultToSpeaker)
        
        // AVAudioRecorder 该类提供了在App中进行音频录制能力。
        //
        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        // isMeteringEnabled
        // 它是布尔值，用于标识是否启用了声音级别测量
        audioRecorder.isMeteringEnabled = true
        // 创建音频文件，让系统准备好录音。
        // 创建的音频文件地址由传入init(url:settings:)方法的url参数指定。
        // 若在该位置已经有文件，则这个方法会覆盖
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        recordButton.isEnabled = true
        stopRecordingButton.isEnabled = false
        recordingLabel.text = "Tap to Record"
        
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    // 当录音停止或因为达到时间限制而终止时，由系统调用audioRecorderDidFinishRecording
    // @recorder  停止录音的音频录音器
    // @flag 录音成功完成返回true; 如果因为音频编码错误而停止录音，则返回false
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("finished recording")
        if flag {
            performSegue(withIdentifier: "stopRecording", sender: audioRecorder.url)
        } else {
            print("recording was not successful")
        }
        
    }
    // prepare(for:sender:)
    // 通知视图控制器将要执行无间断切换
    // @segue 无间断切换对象，它包含无间断切换中涉及的视图控制器的信息
    // @sender 启动无间断切换的对象。你可能根据哪个控件（或其他对象）启动了无间断切换，使用该参数
    // 执行不同的动作。
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            let playSoundsVC = segue.destination as! PlaySoundsViewController
            let recordedAudioURL = sender as! URL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
}

