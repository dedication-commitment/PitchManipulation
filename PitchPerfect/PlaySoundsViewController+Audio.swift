//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Copyright 漏 2016 Udacity. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - PlaySoundsViewController: AVAudioPlayerDelegate

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState { case playing, notPlaying }
    
    // MARK: Audio Functions
    
    func setupAudio() {
        // initialize (recording) audio file
        do {
            // AVAudioFile 可以将其打开并进行读或写的音频文件
            // init(forReading fileURL: URL)  打开文件，进行读取
            // @fileURL 要读取的文件路径
            // 返回值：用于读取的初始化音频文件对象
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        // initialize audio engine components
        // 初始化音频引擎组件
        // AVAudioEngine  一组连接的音频节点对象，用于生成并处理音频信号，并执行音频输入与输出
        // You create each audio node separately and attach it to the audio engine.
        // 单独创建每个音频节点，并将其附接到音频引擎。
        // You can perform all operations on audio nodes during runtime——connecting them,
        // disconnecting them, and removing them——with only minor limitations：
        // Reconnect audio nodes only when they're upstream of a mixer.
        // If you remove an audio node that has differing input and output channel counts, or that
        // is a mixer, the result is likely to be a broken graph.
        
        // 在运行时，可以在音频节点上执行所有操作——连接它们、
        // 断开连接、移除它们——只有微小的限制：
        // 只有当它们是音频混合器的上游时，才重新连接音频节点
        
        audioEngine = AVAudioEngine()
        
        // node for playing audio  播放音频的节点
        // AVAudioPlayerNode,它是个类，用于播放音频文件的缓冲或部分。
        audioPlayerNode = AVAudioPlayerNode()
        // func attach(_ node: AVAudioNode) 附接新的音频节点到音频引擎上
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch 调整频率或音调的节点
        // class AVAudioUnitTimePitch : AVAudioUnitTimeEffect
        // 提供高质量的回放速率和音调偏移，这两种偏移是相互独立的
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            // var pitch: Float { get set }  输入信号的音调所偏移的数量
            // The pitch is measured in "cents", a logarithmic value used
            // for measuring musical intervals. One octave is equal to 1200 cents. One musical semitone is equal to 100 cents.
            // 音调用"cent"来度量，cent是用于测量音程的对数值。
            // 一个八度音阶等于1200个cent.
            // 一个半音程等于100个cent.
            // The default value is 0.0. The range of values is -2400 to 2400
            // 默认的值是0.0。该值的范围是-2400 到 2400
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            // var rate: Float { get set }
            // 输入信号的回放频率
            // 默认的值是1.0。支持的值范围是：1/32到32.0。
            changeRatePitchNode.rate = rate
        }
        // func attach(_ node:AVAudioNode)
        // 参数
        // node 附接到音频引擎的音频节点
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo 用于回声的节点
        // AVAudioUnitDistortion
        // A class that implements a multistage distortion effect.
        // 实现多级失真效应的类
        let echoNode = AVAudioUnitDistortion()
        // func loadFactoryPreset(_ preset: AVAudioUnitDistortionPreset)
        // @preset 失真预设。
        // AVAudioUnitDistortionPreset 表示预设音频失真的常量
        // enum AVAudioUnitDistortionPreset:Int
        // AVAudioUnitDistortionPreset.multiEcho1
        // 预先设置会提供一个"MultiEcho1"失真
        // case multiEcho1 = 12
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb 用于混响的节点
        // AVAudioUnitReverb 实现混响效应的类
        // class AVAudioUnitReverb: AVAudioUnitEffect
        // A reverb simulates the acoustic characteristics of a
        // particular environment.
        // 它是混响，模拟了特定环境传声效果的特征。
        // Use the different presets to simulate a particular space
        // and blend it in with the original signal using the wetDryMix property.
        // 使用不同的预设值来模拟特定的空间，并使用wetDryMix属性将它
        // 混合至原始信号。
        let reverbNode = AVAudioUnitReverb()
        // func loadFactoryPreset(_ preset: AVAudioUnitReverbPreset)
        // 为音频单元配置混响预设
        // @preset 混响预设。
        // AVAudioUnitReverbPreset 描述混响预设的常量
        // enum AVAudioUnitReverbPreset:Int
        // AVAudioUnitReverbPreset.cathedral
        // The reverb preset with the acoustic characteristics of
        // a cathedral environment.
        // 
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    @objc func stopAudio() {
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.notPlaying)
                        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: UI Functions

    func configureUI(_ playState: PlayingState) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
            stopButton.isEnabled = true
        case .notPlaying:
            setPlayButtonsEnabled(true)
            stopButton.isEnabled = false
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        snailButton.isEnabled = enabled
        chipmunkButton.isEnabled = enabled
        rabbitButton.isEnabled = enabled
        vaderButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }

    func showAlert(_ title: String, message: String) {
        // UIAlertController :对象，它展示警告信息给用户
        // init(title:message:preferredStyle:)  创建并返回视图控制器，用于展示警示信息给用户
        // @title 警示信息的标题
        // @message
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        // present(_:animated:completion:)
        // func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil)
        // viewControllerToPresent 
        // 模态地展示一个视图控制器
        self.present(alert, animated: true, completion: nil)
    }
}
