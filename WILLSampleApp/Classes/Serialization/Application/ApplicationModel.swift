//
//  ApplicationModel.swift
//  demoApplication
//
//  Created by nikolay.atanasov on 4.04.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import WacomInk

class ApplicationModel {
    public var sensorDataMaps: [Identifier: SensorData] = [:]
    public var strokes: HashableArray<Identifier, ApplicationStroke> = HashableArray()
    public var devices: [Identifier: InputDevice] = [:]
    public var environments: [Identifier: Environment] = [:]
    public var inkInputProviders: [Identifier: InkInputProvider] = [:]
    public var sensorContexts: [Identifier: SensorContext] = [:]
    public var inputContexts: [Identifier: InputContext] = [:]
    
    public var currentDevice: InputDevice? = nil
    public var currentInkInputProviders: [InkInputType: InkInputProvider]? = nil
    public var currentEnvironment: Environment? = nil
    
    init() {
        initImpl()
    }
    
    init(devices: [InputDevice], environments: [Environment], inkInputProviders: [InkInputProvider] = [], sensorContexts: [SensorContext] = [], inputContexts: [InputContext] = []) {
        initImpl(devices, environments, inkInputProviders, sensorContexts, inputContexts)
    }
    
    static func getTouchType(by inkProvider: InkInputProvider) -> UITouch.TouchType {
        switch inkProvider.type {
        case InkInputType.mouse: return UITouch.TouchType.direct
        case InkInputType.pen: return UITouch.TouchType.pencil
        case InkInputType.touch: return UITouch.TouchType.direct
        case InkInputType.controller: return UITouch.TouchType.indirect
            
        default:
            return UITouch.TouchType.stylus
        }
    }
    
    static func getInkInputType(by touchType: UITouch.TouchType) -> InkInputType {
        switch touchType {
        case .direct:
            #if targetEnvironment(macCatalyst)
            return .mouse
            #else
            return .touch
            #endif
            
        // Fix extra argument to find touch event or pencil
        case UITouch.TouchType.pencil: return InkInputType.pen
        case UITouch.TouchType.indirect: return InkInputType.controller
            //case InkInputType.generic: return UITouch.TouchType.direct
            
        default:
            return .controller
        }
    }
    
    func addSubStroke(_ applicationStroke: ApplicationStroke, from originalApplicationStroke: ApplicationStroke) {
        strokes.insert(key: applicationStroke.inkStroke.id, value: applicationStroke, after: originalApplicationStroke.inkStroke.id)
        applicationStroke.sensorDataId = originalApplicationStroke.sensorDataId
    }
    
    func addStroke(_ applicationStroke: ApplicationStroke, sensorPointerData: [PointerData]? = nil) {
        strokes[applicationStroke.inkStroke.id] = applicationStroke
        
        if let sensorPointerData = sensorPointerData, !sensorPointerData.isEmpty {
            let sensorData = retrieveSensorData(by: sensorPointerData, touchType: applicationStroke.touchType!)
            let sensorDataId = sensorData!.id
            
            sensorDataMaps[sensorDataId] = sensorData!
            applicationStroke.sensorDataId = sensorDataId
        }
    }
    
    func write(to url: URL) {
        let will3Codec = Will3Codec();
        let binaries = will3Codec.encode(inkModel: inkModel)
        let data = Data(binaries)
        
        do {
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
            assert(false)
        }
    }
    
    func read(from url: URL) -> ApplicationModel? {
        do {
            let data = try Data(contentsOf: url)
            let bytes = [UInt8](data)
            let will3Codec = Will3Codec()
            let decodedInkModel = will3Codec.decode(dataBuffer: bytes)
            
            decodedInkModel.printModel()
            
            return decodedInkModel.applicationModel
        } catch {
            NSException(name:NSExceptionName(rawValue: "Could not read url.path: \(url.path)"), reason: "\(error.localizedDescription)", userInfo:nil).raise()
            return nil
        }
    }
    
    func findStroke(by strokeIndex: Identifier) -> ApplicationStroke? {
        return strokes[strokeIndex]
    }
    
    func removeStroke(by strokeIndex: Identifier) -> ApplicationStroke? {
        return strokes.remove(key: strokeIndex)
    }
    
    func removeCanvases() {
        if let strokes = strokes.values {
            for stroke in strokes {
                stroke.canvas!.removeFromSuperlayer()
            }
        }
    }
 
    private func initImpl(_ devices: [InputDevice] = [],_ environments: [Environment] = [],_ inkInputProviders: [InkInputProvider] = [],_ sensorContexts: [SensorContext] = [],_ inputContexts: [InputContext] = []) {
        
        initInputDevices(by: devices)
        initEnvironments(by: environments)
        initInkInputProviders(by: inkInputProviders)
        
        for sensorContext in sensorContexts {
            self.sensorContexts[sensorContext.id] = sensorContext
        }
        
        for inputContext in inputContexts {
            self.inputContexts[inputContext.id] = inputContext
        }
    }
    
    private func initInputDevices(by devices: [InputDevice] = []) {
        for device in devices {
            self.devices[device.id] = device
        }
        
        currentDevice = InputDevice();
        currentDevice!.properties!["dev.id"] = UIDevice.current.identifierForVendor!.description
        currentDevice!.properties!["dev.name"] = UIDevice.current.name //m_eas.FriendlyName;
        currentDevice!.properties!["dev.model"] = UIDevice.current.model
        currentDevice!.properties!["dev.manufacturer"] = "Apple Corporation" //m_eas.SystemManufacturer;
        currentDevice!.seal();
        
        if let device = self.devices[currentDevice!.id], device == currentDevice {
            print("Already have input device: \(device)")
        } else {
            self.devices[currentDevice!.id] = currentDevice!
        }
    }
    
    private func initEnvironments(by environments: [Environment] = []) {
        for env in environments {
            self.environments[env.id] = env
        }
        
        currentEnvironment = Environment();
        currentEnvironment!.properties!["os.name"] = UIDevice.current.systemName //m_eas.OperatingSystem;
        currentEnvironment!.properties!["os.version.code"] = UIDevice.current.systemVersion
        currentEnvironment!.seal()
        
        if let env = self.environments[currentEnvironment!.id], env == currentEnvironment {
            print("Already have environment: \(env)")
        } else {
            self.environments[currentEnvironment!.id] = currentEnvironment!
        }
    }
    
    private func initInkInputProviders(by inkInputProviders: [InkInputProvider] = []) {
        for inkInputProvider in inkInputProviders {
            self.inkInputProviders[inkInputProvider.id] = inkInputProvider
        }
        
        currentInkInputProviders = [:]
        for inkInputType in [InkInputType.mouse, InkInputType.touch, InkInputType.pen] {
            let currentInkInputProvider = InkInputProvider(type: inkInputType)
            currentInkInputProvider.seal()
            currentInkInputProviders![inkInputType] = currentInkInputProvider
            
            if let value = self.inkInputProviders[currentInkInputProvider.id], value == currentInkInputProvider {
                print("Already have currentInkInputProvider: \(currentInkInputProvider)")
            } else {
                self.inkInputProviders[currentInkInputProvider.id] = currentInkInputProvider
            }
        }
    }
    
    private func createSensorChannelContext(by sensorPointerData: [PointerData], touchType: UITouch.TouchType) -> SensorChannelsContext {
        let precision: UInt32 = 2
        
        // Add all sensor channels except 'Custom'
        var sensorChannels: [SensorChannel] = [
            SensorChannel(InkSensorType.x, metric: InkSensorMetricType.length, resolution: nil, min: 0.0, max: 0.0, precision: precision),
            SensorChannel(InkSensorType.y,  metric: InkSensorMetricType.length, resolution: nil, min: 0.0, max: 0.0, precision: precision),
            SensorChannel(InkSensorType.timestamp, metric: InkSensorMetricType.time, resolution: nil, min: 0.0, max: 0.0, precision: 0)
        ]
        
        if sensorPointerData.first!.force != nil {
            sensorChannels.append(SensorChannel(InkSensorType.pressure, metric: InkSensorMetricType.normalized, resolution: nil, min: 0.0, max: 1.0, precision: precision))
        }
        
        if sensorPointerData.first!.radius != nil {
            sensorChannels.append(SensorChannel(InkSensorType.radiusX, metric: InkSensorMetricType.length, resolution: nil, min: 0.0, max: 0.0, precision: precision))
        }
        
        if sensorPointerData.first!.azimuthAngle != nil {
            sensorChannels.append(SensorChannel(InkSensorType.azimuth, metric: InkSensorMetricType.angle, resolution: nil, min: 0.0, max: 2 * Float.pi, precision: precision))
        }
        
        if sensorPointerData.first!.altitudeAngle != nil {
            sensorChannels.append(SensorChannel(InkSensorType.altitude, metric: InkSensorMetricType.angle, resolution: nil, min: 0.0, max: 2 * Float.pi, precision: precision))
        }
        
        let sensorChannelGroup = SensorChannelsContext(
            currentInkInputProviders![ApplicationModel.getInkInputType(by: touchType)]!,
            currentDevice!,
            sensorChannels);
        
        return sensorChannelGroup;
    }
    
    private func retrieveSensorData(by sensorPointerData: [PointerData], touchType: UITouch.TouchType) -> SensorData? {
        if sensorPointerData.count == 0 {
            return nil
        }
        
        // Create the sensor channel groups using the input provider and device
        let defaultSensorChannelsContext = createSensorChannelContext(by: sensorPointerData, touchType: touchType)
        
        // Create the sensor context using the sensor channels contexts
        let sensorContext = SensorContext();
        sensorContext.addSensorChannelsContext(sensorChannelsContext: defaultSensorChannelsContext);
        
        if sensorContexts[sensorContext.id] == nil {
            sensorContexts[sensorContext.id] = sensorContext
        }
        
        let inputContext = InputContext(environmentId: currentEnvironment!.id, sensorContextId: sensorContext.id);
        
        if inputContexts[inputContext.id] == nil {
            inputContexts[inputContext.id] = inputContext
        }
        
        // Create sensor data using the input context
        let sensorData = SensorData(
            id: Identifier.fromNewUUID(),
            inputContextId: inputContext.id,
            state: InkState.plane);
        
        // Fill the default channels with the sensor data
        let channels = sensorContext.defaultSensorChannelsContext!;
        
        sensorData.addData(channels.getChannel(typeUri: InkSensorType.x)!, sensorPointerData.map({$0.x}))
        sensorData.addData(channels.getChannel(typeUri: InkSensorType.y)!, sensorPointerData.map({$0.y}))
        sensorData.addTimestampData(sensorChannel: channels.getChannel(typeUri: InkSensorType.timestamp)!, values: sensorPointerData.map({UInt64($0.timestamp)}))

        if sensorPointerData.first!.force != nil {
            sensorData.addData(channels.getChannel(typeUri: InkSensorType.pressure)!, sensorPointerData.map({$0.force!}))
        }
        
        if sensorPointerData.first!.radius != nil {
            sensorData.addData(channels.getChannel(typeUri: InkSensorType.radiusX)!, sensorPointerData.map({$0.radius!}))
        }
        
        if sensorPointerData.first!.azimuthAngle != nil {
            sensorData.addData(channels.getChannel(typeUri: InkSensorType.azimuth)!, sensorPointerData.map({$0.azimuthAngle!}))
        }
        
        if sensorPointerData.first!.altitudeAngle != nil {
            sensorData.addData(channels.getChannel(typeUri: InkSensorType.altitude)!, sensorPointerData.map({$0.altitudeAngle!}))
        }
    
        return sensorData
    }
}
