//
//  ViewController.swift
//  accelerometer_test
//
//  Created by Andrew Wagenmaker on 5/2/20.
//  Copyright © 2020 Andrew Wagenmaker. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    let tiltLabel: UILabel = {
        let label = UILabel()
        label.text = "Label text"
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: label.font.fontName, size: 60)
        return label
    }()
    
    let motion = CMMotionManager()
    var timer: Timer!
    
    let X_REST = 0.0119
    let Y_REST = -0.0201
    let Z_REST = -1.0087
    let PI = 3.14159
    
    var x_mean = 0.0
    var y_mean = 0.0
    var z_mean = 0.0
    var x_ang_mean = 0.0
    var y_ang_mean = 0.0
    var z_ang_mean = 0.0
    
    var x_sos = 0.0
    var y_sos = 0.0
    var z_sos = 0.0
    var x_ang_sos = 0.0
    var y_ang_sos = 0.0
    var z_ang_sos = 0.0
    
    var x_var = 0.0
    var y_var = 0.0
    var z_var = 0.0
    var x_ang_var = 0.0
    var y_ang_var = 0.0
    var z_ang_var = 0.0
    
    var acc_count = 0
    var gyr_count = 0
    
    var gyr_x = 0.0
    var gyr_y = 0.0
    var gyr_z = 0.0
    
    var acc_x = Array(repeating: 0.0, count: 20)
    var acc_y = Array(repeating: 0.0, count: 20)
    var acc_z = Array(repeating: 0.0, count: 20)
    var acc_idx = 0
    
    var full_tilt = 0.0
    var last_acc_tilt = 0.0
    var acc_tilt = 0.0
    var last_gyr_tilt = 0.0
    var gyr_tilt = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.addSubview(tiltLabel)
        tiltLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tiltLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
       
        // Do any additional setup after loading the view.
        startAccelerometers()
    }

    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
          self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
          self.motion.startAccelerometerUpdates()
       }
        
        if self.motion.isGyroAvailable {
            self.motion.gyroUpdateInterval = 1.0 / 60.0
            self.motion.startGyroUpdates()
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(timer_handler), userInfo: nil, repeats: true)
    }
    
    
    func stopGyros() {
       if self.timer != nil {
          self.timer?.invalidate()
          self.timer = nil

          self.motion.stopGyroUpdates()
       }
    }
    
    
    func dispatch_main(closure:@escaping ()->()) {
        DispatchQueue.main.async {
            closure()
        }
    }

    
    @objc func timer_handler() {
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var x_ang = 0.0
        var y_ang = 0.0
        var z_ang = 0.0
        
        if let data = self.motion.accelerometerData, let data_gyr = self.motion.gyroData {
            x = data.acceleration.x
            y = data.acceleration.y
            z = data.acceleration.z
            
            acc_x[acc_idx] = x
            acc_y[acc_idx] = y
            acc_z[acc_idx] = z
            acc_idx = acc_idx + 1
            if acc_idx == 20 {
                acc_idx = 0
            }
            
            x_mean = 0.0
            y_mean = 0.0
            z_mean = 0.0
            
            for i in 0...19 {
                x_mean = x_mean + acc_x[i]
                y_mean = y_mean + acc_y[i]
                z_mean = z_mean + acc_z[i]
            }
            x_mean = x_mean / 20.0
            y_mean = -y_mean / 20.0
            z_mean = z_mean / 20.0
            
            last_acc_tilt = acc_tilt
            let ip = x_mean*X_REST + y_mean*Y_REST + z_mean*Z_REST
            let mag1 = sqrt(x_mean*x_mean + y_mean*y_mean + z_mean*z_mean)
            let mag2 = sqrt(X_REST*X_REST + Y_REST*Y_REST + Z_REST*Z_REST)
            acc_tilt = acos(ip/(mag1*mag2))*180.0/PI
            
            
            gyr_count += 1
            x_ang = data_gyr.rotationRate.x
            y_ang = data_gyr.rotationRate.y
            z_ang = data_gyr.rotationRate.z
            
            gyr_x += (x_ang/60.0)*(180.0/PI)
            gyr_y += (y_ang/60.0)*(180.0/PI)
            gyr_z += (z_ang/60.0)*(180.0/PI)
            
            var zest = -cos(gyr_x*PI/180.0)*cos(gyr_y*PI/180.0)
            var yest = cos(gyr_x*PI/180.0)*sin(gyr_y*PI/180.0)
            var xest = -sin(gyr_x*PI/180.0)
            
            last_gyr_tilt = gyr_tilt
            let ip_gyr = xest*X_REST + yest*Y_REST + zest*Z_REST
            let mag1_gyr = sqrt(xest*xest + yest*yest + zest*zest)
            let mag2_gyr = sqrt(X_REST*X_REST + Y_REST*Y_REST + Z_REST*Z_REST)
            gyr_tilt = acos(ip_gyr/(mag1_gyr*mag2_gyr))*180.0/PI
        
            var delta_gyr = gyr_tilt - last_gyr_tilt
            if acc_tilt - last_acc_tilt < 0 && delta_gyr > 0 {
                delta_gyr = -delta_gyr
            } else if acc_tilt - last_acc_tilt > 0 && delta_gyr < 0 {
                delta_gyr = -delta_gyr
            }
            full_tilt = 0.2*acc_tilt + 0.8*(full_tilt + delta_gyr)
                
            print(acc_tilt,gyr_tilt,full_tilt)
            tiltLabel.text = String(format:"%.3f", full_tilt)
        }
    
    }
    
    
    
    
    @objc func timer_handler_var() {
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var x_ang = 0.0
        var y_ang = 0.0
        var z_ang = 0.0
        
        if let data = self.motion.accelerometerData {
            x = data.acceleration.x
            y = data.acceleration.y
            z = data.acceleration.z
            
            acc_x[acc_idx] = x
            acc_y[acc_idx] = y
            acc_z[acc_idx] = z
            
            let f1 = Double(acc_count) / Double(acc_count + 1)
            let f2 = 1.0 / Double(acc_count + 1)
            x_mean = f1 * x_mean + f2 * x
            x_sos = f1 * x_sos + f2 * x * x
            x_var = x_sos - x_mean*x_mean
            
            y_mean = f1 * y_mean + f2 * y
            y_sos = f1 * y_sos + f2 * y * y
            y_var = y_sos - y_mean*y_mean
            
            z_mean = f1 * z_mean + f2 * z
            z_sos = f1 * z_sos + f2 * z * z
            z_var = z_sos - z_mean*z_mean
            
            acc_count = acc_count + 1
            
//            print("means")
//            print(x_mean,y_mean,z_mean)
//            print("variance")
//            print(x_var,y_var,z_var)
        }
        
        if let data = self.motion.gyroData {
            x_ang = data.rotationRate.x
            y_ang = data.rotationRate.y
            z_ang = data.rotationRate.z
            
            let f1 = Double(gyr_count) / Double(gyr_count + 1)
            let f2 = 1.0 / Double(gyr_count + 1)
            x_ang_mean = f1 * x_ang_mean + f2 * x_ang
            x_ang_sos = f1 * x_ang_sos + f2 * x_ang * x_ang
            x_ang_var = x_ang_sos - x_ang_mean*x_ang_mean
            
            y_ang_mean = f1 * y_ang_mean + f2 * y_ang
            y_ang_sos = f1 * y_ang_sos + f2 * y_ang * y_ang
            y_ang_var = y_ang_sos - y_ang_mean*y_ang_mean
            
            z_ang_mean = f1 * z_ang_mean + f2 * z_ang
            z_ang_sos = f1 * z_ang_sos + f2 * z_ang * z_ang
            z_ang_var = z_ang_sos - z_ang_mean*z_ang_mean
            
            gyr_count = gyr_count + 1
            
            print("means")
            print(x_ang_mean,y_ang_mean,z_ang_mean)
            print("variance")
            print(x_ang_var,y_ang_var,z_ang_var)
        }
    }
}

