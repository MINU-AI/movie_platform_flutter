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
        
    public func view() -> UIView {
        playerView.player = player
        return playerView
    }
    
    deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        player?.removeObserver(self, forKeyPath: "status")
        player?.replaceCurrentItem(with: nil)
        activateAudioSession(activate: false)
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
            keyLoader = try FairplayKeyLoader.create(fromMoviePlatform: moviePlatform, certificateURL: certificateUrl!, licenseUrl: licenseKeyUrl, channel: channel, metadata: metadata)
            asset.resourceLoader.setDelegate(keyLoader, queue: DispatchQueue.global())
        }
        return AVPlayerItem(asset: asset)
    }
    
    private func createPlayer(creationParams: [String:Any]) throws {
        let playItem = try createPlayerItem(creationParams: creationParams)
        player = AVPlayer(playerItem: playItem)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
        player?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        activateAudioSession(activate: true)
        let playWhenReady = creationParams["playWhenReady"] as! Bool
        if playWhenReady {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case "timeControlStatus":
            if let timeControlStatus = change?[NSKeyValueChangeKey.newKey] as? Int {
                let isPlaying = timeControlStatus == 2
                print("Got player playing change: \(isPlaying)")
                let arguments = ["isPlaying": isPlaying]
                channel.invokeMethod(MethodCalls.onPlayingChange.rawValue, arguments: arguments)
                var playerState: PlayerState?
                
                switch timeControlStatus {
                case AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate.rawValue:
                    playerState = .buffering
                case AVPlayer.TimeControlStatus.playing.rawValue:
                    playerState = .ready
                default: break
                }
                if let playerState = playerState {
                    channel.invokeMethod(MethodCalls.onPlaybackStateChanged.rawValue, arguments: playerState.rawValue)
                }
            }
        case "status":
            if let status = change?[NSKeyValueChangeKey.newKey] as? Int {
                print("Got status change: \(status)")
                switch status {
                case AVPlayer.Status.failed.rawValue:
                    var argument: [String:Any] = [:]
                    argument["errorCode"] = 1
                    argument["errorCodeName"] = "player_error"
                    argument["message"] = player?.error?.localizedDescription
                    channel.invokeMethod(MethodCalls.onPlayerError.rawValue, arguments: argument)
                default:
                    break
                }
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
    
    func activateAudioSession(activate: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category to allow media playback
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            
            // Activate the audio session
            try audioSession.setActive(activate)
        } catch {
            print("Got Failed to activate audio session: \(error.localizedDescription)")
        }
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
                case "changeVolume":
                    let volume = params["value"] as! Double
                    self?.player?.volume = Float(volume)
                    
                default:
                    print("Unsupported action: \(action)")
                }
            case .getDuration:
                let duration = self?.player?.currentItem?.duration ?? .zero
                if duration.value == .zero || duration.timescale == .zero {
                    result(0)
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
            case .getBrightness:
                let brightness = Double(UIScreen.main.brightness)
                result(brightness)
            
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


class FairplayKeyLoader: NSObject, AVAssetResourceLoaderDelegate {
    var certificateURL: String
    var licenseURL: String?
    var metadata: [String:Any]?
    
    fileprivate init(licenseURL: String?, certificateURL: String, metadata: [String:Any]? = nil) {
        self.licenseURL = licenseURL
        self.certificateURL = certificateURL
        self.metadata = metadata
        super.init()
    }
    
    static func create(fromMoviePlatform platform: MoviePlatform, certificateURL: String, licenseUrl: String?, channel: FlutterMethodChannel, metadata: [String:Any]? = nil) throws -> FairplayKeyLoader{
        switch platform {
        case .hulu: return HuluKeyLoader(licenseURL: licenseUrl, certificateURL: certificateURL, metadata: metadata)
        case .prime: return PrimeKeyLoader(licenseURL: licenseUrl, certificateURL: certificateURL, metadata: metadata)
        case .disney: return DisneyKeyLoader(licenseURL: licenseUrl, certificateURL: certificateURL, channel: channel, metadata: metadata)
        default: throw "Unsupported movie platform: \(platform)"
        }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url, url.scheme == "skd" else {
            return false
        }
        
        return handleKeyRequest(loadingRequest)
    }
    
    func getContentIdentifier(_ loadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        guard let url = loadingRequest.request.url, let host = url.host else {
            throw "Got handleKeyRequest: host data is nil"
        }
        return host.data(using: .utf8)!
    }
    
    private func handleKeyRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        do {
            let contentIdentifier = try getContentIdentifier(loadingRequest)
            let host = loadingRequest.request.url!.host!
            let certificateData = try getCertificateData()
            let spcData = try loadingRequest.streamingContentKeyRequestData(forApp: certificateData, contentIdentifier: contentIdentifier, options: nil)
            let ckcData = try getCKCData(spc: spcData, assetID: host)
            loadingRequest.dataRequest?.respond(with: ckcData)
            loadingRequest.finishLoading()
            return true
        } catch {
            print("Got handleKeyRequest: error \(error) ")
            loadingRequest.finishLoading(with: error)
        }
        return false
    }
    
    
    func getCKCData(spc: Data, assetID: String) throws -> Data {
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
    override func getCKCData(spc: Data, assetID: String) throws -> Data {
        // Send SPC to the FairPlay license server and receive CKC
        let token = metadata?["token"] as! String
        let base64String = spc.base64EncodedString()

        var request = URLRequest(url: URL(string: licenseURL!)!)
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

class PrimeKeyLoader: FairplayKeyLoader {
    override func getCertificateData() throws -> Data {
        return Data(base64Encoded: certificateURL)!
    }
    
    override func getContentIdentifier(_ loadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        return loadingRequest.request.url!.absoluteString.data(using: .utf8)!
    }
    
    override func getCKCData(spc: Data, assetID: String) throws -> Data {
        let base64String = spc.base64EncodedString()
        
        let deviceId = metadata?["deviceId"] as! String
        let mid = metadata?["mid"] as! String
        let cookies = metadata?["cookies"] as! String
        let movieId = metadata?["movieId"] as! String
                
        let requestData = "fairPlayChallenge=\(base64String)&fairPlayKeyId=skd://\(assetID)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)!
        
        let endpoint = "https://atv-ps.amazon.com/cdp/catalog/GetPlaybackResources"
        
        let httpHeaders = [
            "Cookie": cookies,
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let params = [
            "asin": movieId,
            "deviceTypeID": "AOAGZA014O5RE",
            "firmware": "1",
            "deviceID": deviceId,
            "marketplaceID": mid,
            "format": "json",
            "version": "2",
            "resourceUsage": "ImmediateConsumption",
            "consumptionType": "Streaming",
            "deviceDrmOverride": "FairPlay",
            "deviceStreamingTechnologyOverride": "HLS",
            "deviceProtocolOverride": "Https",
            "deviceBitrateAdaptationsOverride": "CBR,CVBR",
            "videoMaterialType": "Feature",
            "desiredResources": "FairPlayLicense",
//            "deviceVideoCodecOverride": "H264",
//            "deviceVideoQualityOverride": "HD",
//            "operatingSystemName": "Mac OS X",
            "gascEnabled": "false"
            // add gascEnabled because we used fe
        ]
        
        let (data, response, error) = URLSession.shared.synchronousPOSTDataTask(with: endpoint, parameters: params, body: requestData, httpHeaders: httpHeaders)

        try validateReponse(data: data, response: response, error: error)
        
        if let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any] {
            if let error = jsonData["error"] as? [String:Any] {
                throw "Got response with error: \(error)"
            }
            
            if let fairPlayLicense = jsonData["fairPlayLicense"] as? [String:Any], let encodedLicenseResponse = fairPlayLicense["encodedLicenseResponse"] as? String {
                return Data(base64Encoded: encodedLicenseResponse)!
            }
        }
        
        throw "Got ckcData error: Invalid response format"
    }
}

class DisneyKeyLoader: FairplayKeyLoader {
    let channel: FlutterMethodChannel
    var token = ""
    
    init(licenseURL: String?, certificateURL: String, channel: FlutterMethodChannel, metadata: [String : Any]? = nil) {
        self.channel = channel
        super.init(licenseURL: licenseURL, certificateURL: certificateURL, metadata: metadata)
        token = metadata?["token"] as! String
    }
    
    override func getCKCData(spc: Data, assetID: String) throws -> Data {
        
        let httpHeaders = [
            "Content-Type": "application/octet-stream",
            "X-BAMSDK-Platform": "apple/ios/iphone",
            "Accept": "application/json, application/vnd.media-service+json; version=2",
            "X-BAMSDK-Client-ID": "disney-svod-3d9324fc",
            "X-DSS-Edge-Accept": "vnd.dss.edge+json; version=2",
            "Authorization": "Bearer \(token)"
        ]
        
        let (data, response, error) = URLSession.shared.synchronousPOSTDataTask(with: licenseURL!, body: spc, httpHeaders: httpHeaders)
        
        try validateReponse(data: data, response: response, error: error)
        
        if let jsonData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
            if let errors = jsonData["errors"] as? [[String:Any]], !errors.isEmpty, let code = errors.first?["code"] as? String, code == "access-token.invalid" {
                print("Got invalid access token")
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.async { [weak self] in
                    self?.channel.invokeMethod(MethodCalls.refreshToken.rawValue, arguments: MoviePlatform.disney.rawValue) { result in
                        if let token = result as? String {
                            self?.token = token
                        }
                        semaphore.signal()
                    }
                }
                _ = semaphore.wait(timeout: .distantFuture)
                return try getCKCData(spc: spc, assetID: assetID)
            }
            
            if let ckc = jsonData["ckc"] as? String {
                return Data(base64Encoded: ckc)!
            }
        }
        
        throw "Got ckc data error"
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
    case getBrightness
    
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
        case "getBrightness": self = .getBrightness
        default: throw "Unsupported method call: \(rawValue)"
        }
    }
}

enum PlayerState: Int {
    case idle = 1
    case buffering = 2
    case ready = 3
    case end = 4
}

let platformChannel = "com.minu.player/channel"

extension String: Error {
}

extension URLSession {
    func synchronousPOSTDataTask(with urlString: String, parameters: [String: String] = [:], body requestData: Data, httpHeaders: [String: String]) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var components = URLComponents(string: urlString)!
        
        if (!parameters.isEmpty) {
            components.queryItems = parameters.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        for (key, value) in httpHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = requestData

        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
    
    func synchronousGETDataTask(with urlString: String, parameters: [String: String], httpHeaders: [String: String]) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var components = URLComponents(string: urlString)!
        components.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var request = URLRequest(url: components.url!)
        
        request.httpMethod = "GET"
        for (key, value) in httpHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}

