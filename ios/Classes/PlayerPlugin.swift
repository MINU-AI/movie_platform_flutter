import Flutter
import UIKit
import Foundation
import AVFoundation



public class PlayerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      let viewFactory = NativeViewFactory(mesenger: registrar.messenger())
      registrar.register(viewFactory, withId: PlatformViewType.widevinePlayer)
  }
    
}


public class NativeViewFactory: NSObject, FlutterPlatformViewFactory {
    let mesenger: FlutterBinaryMessenger
    
    init(mesenger: FlutterBinaryMessenger) {
        self.mesenger = mesenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> any FlutterPlatformView {
        return NativePlayerView(arguments: args, messenger: mesenger)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
         return FlutterStandardMessageCodec.sharedInstance()
    }
}


public class NativePlayerView: NSObject, FlutterPlatformView {
    
    public init(arguments args: Any?, messenger: FlutterBinaryMessenger) {
        let params = args as! [String:Any]
        self.channel = FlutterMethodChannel(name: platformChannel, binaryMessenger: messenger)
        super.init()
        try! self.createPlayer(creationParams: params)
        self.channel.setMethodCallHandler(methodCallHandler)
    }
    
    private var player: AVPlayer?
    
    private let channel: FlutterMethodChannel
    
    private let playerView = VideoPlayerView()
    
    private var systemBrightness: Double?
    
    private var keyLoader: FairplayKeyLoader?
    
    private lazy var contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
    
    public func view() -> UIView {
        playerView.player = player
        return playerView
    }
    
    deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        player?.removeObserver(self, forKeyPath: "status")
        if let systemBrightness = systemBrightness {
            UIScreen.main.brightness = systemBrightness
        }
    }
    
}

extension NativePlayerView {
    private func createPlayerItem(creationParams: [String:Any]) throws -> AVPlayerItem {
        let platformId = creationParams[PlatformViewParams.platformId] as! String
        let playbackUrl = creationParams[PlatformViewParams.playbackUrl] as! String
        let licenseKeyUrl = creationParams[PlatformViewParams.licenseUrl] as? String
        let certificateUrl = creationParams[PlatformViewParams.certificateUrl] as? String
        let metadata = creationParams[PlatformViewParams.metadata] as? [String:Any]
        let moviePlatform: MoviePlatform = try! .init(rawValue: platformId)
        let asset = AVURLAsset(url: URL(string: playbackUrl)!)
        if moviePlatform != .youtube {
            keyLoader = try FairplayKeyLoader.create(fromMoviePlatform: moviePlatform, certificateURL: certificateUrl!, licenseUrl: licenseKeyUrl!, metadata: metadata)
            contentKeySession.setDelegate(keyLoader, queue: DispatchQueue(label: "ContentSessionKey"))
            contentKeySession.addContentKeyRecipient(asset)
        }
        return AVPlayerItem(asset: asset)
    }
    
    private func createPlayer(creationParams: [String:Any]) throws {
        let playItem = try createPlayerItem(creationParams: creationParams)
        player = AVPlayer(playerItem: playItem)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
        player?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        player?.play()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case "timeControlStatus":
            if let timeControlStatus = change?[NSKeyValueChangeKey.newKey] as? Int {
                let isPlaying = timeControlStatus == 2
                print("Got player playing change: \(isPlaying)")
                let arguments = ["isPlaying": isPlaying]
                channel.invokeMethod(MethodCalls.onPlayingChange.rawValue, arguments: arguments)
            }
        case "status":
            if let status = change?[NSKeyValueChangeKey.newKey] as? Int {
                let playbackState = status == 1 ? 3 : 4
                print("Got status change: \(status), \(playbackState)")
                switch status {
                case AVPlayer.Status.readyToPlay.rawValue:
                    player?.play()
                case AVPlayer.Status.failed.rawValue:
                    var argument: [String:Any] = [:]
                    argument["errorCode"] = 1
                    argument["errorCodeName"] = "player_error"
                    argument["message"] = player?.error?.localizedDescription
                    channel.invokeMethod(MethodCalls.onPlayerError.rawValue, arguments: argument)
                default:
                    break
                }
                
                channel.invokeMethod(MethodCalls.onPlaybackStateChanged.rawValue, arguments: playbackState)
            }
        default: return
        }
        
    }
    
    // Function to calculate buffered percentage
    var bufferedPercentage: Double {
        // Get the total duration of the video
        guard let duration = player?.currentItem?.duration else {
            return 0.0
        }

        // Convert CMTime to seconds
        let totalDuration = CMTimeGetSeconds(duration)

        // Get the buffered ranges
        guard let timeRange = player?.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
            return 0.0
        }

        // Calculate the buffered duration
        let bufferedDuration = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)

        // Calculate the buffered percentage
        if totalDuration > 0 {
            let percentage = (bufferedDuration / totalDuration) * 100
            return percentage
        }

        return 0.0
    }
}

extension NativePlayerView {
    var methodCallHandler: FlutterMethodCallHandler {
        { [weak self] call, result in
            let methodName = call.method
            let args = call.arguments as? [String:Any]
            let method: MethodCalls = try! .init(rawValue: methodName)
            switch method {
            case .controlPlayer:
                let params = args!
                let action = params["action"] as! String
                switch action {
                case "play": self?.player?.play()
                case "pause": self?.player?.pause()
                case "stop": self?.player?.replaceCurrentItem(with: nil)
                case "seek":
                    let value = params["value"] as! Int
                    self?.seekToTime(seconds: Double(value) / 1000.0)
                case "changePlayback":
                    let passedParams = params["value"] as! [String:Any]
                    let playerItem = try! self?.createPlayerItem(creationParams: passedParams)
                    self?.player?.replaceCurrentItem(with: playerItem)
                    self?.player?.play()
                    
                default:
                    print("Unsupported action: \(action)")
                }
            case .getDuration:
                let duration = self?.player?.currentItem?.duration ?? .zero
                if duration.value == .zero || duration.timescale == .zero {
                    return
                }
                result(Int(duration.seconds) * 1000)
            case .getCurrentPosition:
                let currentPosition = self?.player?.currentTime() ?? .zero
                result(Int(currentPosition.seconds) * 1000)
            case .getBufferedPercentage:
                result(Int(self?.bufferedPercentage ?? 0))
            case .setBrightness:
                let params = args!
                let brightness = params["value"] as! Double
                self?.systemBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = brightness
            default:
                print("Unsupported method: \(methodName)")
                
            }
        }
    }
    
    func seekToTime(seconds: Double) {
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: targetTime)
    }
}


class FairplayKeyLoader: NSObject, AVContentKeySessionDelegate {
    var certificateURL: String
    var licenseURL: String
    var metadata: [String:Any]?
    
    fileprivate init(licenseURL: String, certificateURL: String, metadata: [String:Any]? = nil) {
        self.licenseURL = licenseURL
        self.certificateURL = certificateURL
        self.metadata = metadata
        super.init()
    }
    
    static func create(fromMoviePlatform platform: MoviePlatform, certificateURL: String, licenseUrl: String, metadata: [String:Any]? = nil) throws -> FairplayKeyLoader{
        switch platform {
        case .hulu: return HuluKeyLoader(licenseURL: licenseUrl, certificateURL: certificateURL, metadata: metadata)
        default: throw "Unsupported movie platform: \(platform)"
        }
    }
    
    public func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        handleKeyRequest(keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        handleKeyRequest(keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error) {
        print("Got contentKeySession error: \(err)")
    }
    
    private func handleKeyRequest(_ keyRequest: AVContentKeyRequest) {
        do {
            guard let contentKeyIdentifierString = keyRequest.identifier as? String,
                  let contentKeyIdentifierURL = URL(string: contentKeyIdentifierString),
                  let assetIDString = contentKeyIdentifierURL.host,
                  let assetIDData = assetIDString.data(using: .utf8)
            else {
                throw "Failed to retrieve the assetID from the keyRequest"
            }
            
            let certificateData = try getCertificateData()
            var responseData: (Data?, Error?)?
            let semaphore = DispatchSemaphore(value: 0)
            keyRequest.makeStreamingContentKeyRequestData(forApp: certificateData, contentIdentifier: assetIDData) { data, error in
                responseData = (data, error)
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .distantFuture)
            
            guard let spcData = responseData!.0 else {
                throw "spcData error: \(String(describing: responseData?.1))"
            }
            
            let ckcData = try getCKCData(spc: spcData)
            let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
            keyRequest.processContentKeyResponse(keyResponse)
        } catch {
            print("Got contentKeySession error: \(error)")
            keyRequest.processContentKeyResponseError(error)
        }
    }
    
    
    func getCKCData(spc: Data) throws -> Data {
        throw "Unimplemented"
    }
    
    func getCertificateData() throws -> Data {
        return try Data(contentsOf: URL(string: certificateURL)!)
    }
    
    func validateReponse(data: Data?, response: URLResponse?, error: Error?) throws {
        guard error == nil else {
            throw "Finish request with error: \(String(describing: error))"
        }
        
        guard data != nil else {
            throw "Finish request with data is nil"
        }
        
        guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
            throw "Finish request with status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
        }
    }
}

class HuluKeyLoader: FairplayKeyLoader {
    override func getCKCData(spc: Data) throws -> Data {
        // Send SPC to the FairPlay license server and receive CKC
        let token = metadata?["token"] as! String
        let base64String = spc.base64EncodedString()

        var request = URLRequest(url: URL(string: licenseURL)!)
        request.addValue("text/plain;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = base64String.data(using: .utf8)
        
        var responseData : (Data?, URLResponse?, Error?)?
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            responseData = (data, response, error)
            semaphore.signal()
        }
        dataTask.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        try validateReponse(data: responseData?.0, response: responseData?.1, error: responseData?.2)
        let ckcData = Data(base64Encoded: String(data: responseData!.0!, encoding: .utf8)!)!
        return ckcData
    }
}

class VideoPlayerView: UIView {
    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}


public class PlatformViewType {
    static let widevinePlayer = "widevinePlayer"
}

public class PlatformViewParams {
    static let playbackUrl = "playbackUrl"
    static let licenseUrl = "licenseUrl"
    static let certificateUrl = "certificateUrl"
    static let platformId = "platformId"
    static let metadata = "metadata"
}

public enum MoviePlatform: String  {
    case youtube
    case disney
    case prime
    case hulu
    
    public init(rawValue: String) throws {
        switch rawValue {
        case "youtube" : self = .youtube
        case "disney" : self = .disney
        case "prime" : self = .prime
        case "hulu" : self = .hulu
        default: throw "Unsupported movie platform: \(rawValue)"
        }
    }
}

public enum MethodCalls: String {
    case refreshToken
    case onPlaybackStateChanged
    case onPlayerError
    case onPlayingChange
    case getDuration
    case getCurrentPosition
    case getBufferedPosition
    case getBufferedPercentage
    case setBrightness
    case controlPlayer
    
    public init(rawValue: String) throws {
        switch rawValue {
        case "refreshToken": self = .refreshToken
        case "onPlaybackStateChanged": self = .onPlaybackStateChanged
        case "onPlayerError": self = .onPlayerError
        case "onPlayingChange": self = .onPlayingChange
        case "getDuration": self = .getDuration
        case "getCurrentPosition": self = .getCurrentPosition
        case "getBufferedPosition": self = .getBufferedPosition
        case "getBufferedPercentage": self = .getBufferedPercentage
        case "setBrightness": self = .setBrightness
        case "controlPlayer": self = .controlPlayer
        default: throw "Unsupported method call: \(rawValue)"
        }
    }
}

let platformChannel = "com.minu.player/channel"

extension String: Error {
}

