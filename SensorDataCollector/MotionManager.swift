//
//  MotionManager.swift
//  SensorDataCollector
//
//  Created by Roman Mazeev on 28/05/22.
//

import CoreMotion
import CSV

final class MotionManager {
    enum MotionManagerError: Error {
        case deviceMotionIsNotAvailable
        case outputStreamCreation
    }
    
    let filePath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        return documentsDirectory.appendingPathComponent("KATA.csv")
    }()

    private lazy var manager: CMMotionManager = {
        let motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = TimeInterval(1 / 50)
        return motionManager
    }()
    
    func getAndSaveMotions(framesCount: Int, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        getMotions(count: framesCount) { result in
            switch result {
            case .success(let motions):
                guard let outputStream = OutputStream(toFileAtPath: self.filePath, append: false) else {
                    completionHandler(.failure(MotionManagerError.outputStreamCreation))
                    return
                }
                
                do {
                    let csvWriter = try CSVWriter(stream: outputStream)
                    try csvWriter.write(field: "AccelerationX")
                    try csvWriter.write(field: "AccelerationY")
                    try csvWriter.write(field: "AccelerationZ")
                    try csvWriter.write(field: "GyroX")
                    try csvWriter.write(field: "GyroY")
                    try csvWriter.write(field: "GyroZ")
                    for motion in motions {
                        try csvWriter.write(row: [
                            String(motion.userAcceleration.x),
                            String(motion.userAcceleration.y),
                            String(motion.userAcceleration.z),
                            String(motion.rotationRate.x),
                            String(motion.rotationRate.y),
                            String(motion.rotationRate.z)
                        ])
                    }
                    csvWriter.stream.close()
                    completionHandler(.success(()))
                } catch {
                    completionHandler(.failure(error))
                }

            
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    private func getMotions(count: Int, completionHandler: @escaping (Result<[CMDeviceMotion], Error>) -> Void) {
        guard manager.isDeviceMotionAvailable else {
            completionHandler(.failure(MotionManagerError.deviceMotionIsNotAvailable))
            return
        }
        
        var currentMotions: [CMDeviceMotion] = []

        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let motion = motion {
                currentMotions.append(motion)
                if currentMotions.count == count {
                    completionHandler(.success(currentMotions))
                }
            }
        }
    }
}
