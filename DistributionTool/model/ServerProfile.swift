//
//  DistributionConfig.swift
//  DistributionTool
//
//  Created by haihong on 2018/12/7.
//  Copyright © 2018 Sea Rainbow. All rights reserved.
//

import Foundation

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

// 不继承 NSObject ，无法使用 KVC, 异常如下：
// was sent to an object that is not KVC-compliant for the “userName” property
// 另外，该类的对象 也需要用 @objc dynamic 标注

// swift 4.0 之后，继承自 NSObject 已使用KVC时，也需要手动添加 @objc，或在类上添加 @objcMembers
class ServerProfile: NSObject {
    @objc var host: String
    @objc var port: Int
    @objc var userName: String
    @objc var password: String
    @objc var targetPath: String
    @objc var projectName: String
    
    override init() {
        self.host = "127.0.0.1"
        self.port = 22
        self.userName = "root"
        self.password = ""
        self.targetPath = ""
        self.projectName = "未命名"
        
        super.init()
    }
    
    init(dict: [String: Any]) throws {
        guard let host = dict["host"] as? String,
            let port = dict["port"] as? Int,
            let userName = dict["userName"] as? String,
            let password = dict["password"] as? String,
            let targetPath = dict["targetPath"] as? String,
            let projectName = dict["projectName"] as? String
            else {
                throw SerializationError.missing("host")
        }
        
        self.host = host
        self.port = port
        self.userName = userName
        self.password = password
        self.targetPath = targetPath
        self.projectName = projectName
    }
}
