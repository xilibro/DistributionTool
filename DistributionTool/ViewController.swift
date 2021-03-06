//
//  ViewController.swift
//  DistributionTool
//
//  Created by haihong on 2018/11/16.
//  Copyright © 2018 Sea Rainbow. All rights reserved.
//

import Cocoa
import SystemConfiguration
import SSZipArchive

class ViewController: NSViewController, NSComboBoxDelegate, NSComboBoxDataSource {
    
    @IBOutlet weak var resultView: NSScrollView!
    @IBOutlet weak var targetPathTF: NSTextField!
    @IBOutlet weak var userNameTF: NSTextField!
    
    @IBOutlet weak var passwordTF: NSSecureTextField!
    @IBOutlet weak var hostTF: NSTextField!
    @IBOutlet weak var portTF: NSTextField!
    @IBOutlet weak var projectNamesCmb: NSComboBox!
    
    var profiles = [ServerProfile]()
    var selectedProfileIndex = 0
    var selectedProfile: ServerProfile? {
        didSet {
            if selectedProfile != nil {
                hostTF.stringValue = selectedProfile!.host
                portTF.stringValue = String(selectedProfile!.port)
                userNameTF.stringValue = selectedProfile!.userName
                passwordTF.stringValue = selectedProfile!.password
                targetPathTF.stringValue  = selectedProfile!.targetPath
                projectNamesCmb.stringValue = selectedProfile!.projectName
            } else {
                hostTF.stringValue = ""
                portTF.stringValue = ""
                userNameTF.stringValue = ""
                passwordTF.stringValue = ""
                targetPathTF.stringValue  = ""
                projectNamesCmb.stringValue = ""
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        projectNamesCmb.usesDataSource = true
        projectNamesCmb.dataSource = self
        projectNamesCmb.delegate = self
        projectNamesCmb.completes = true
        
        // Do any additional setup after loading the view.
        printProcessingInfo(info: "欢迎使用网站发布小工具 :)")
        
        // 读取配置项
        profiles = readDefaults()
        
        if profiles.count > 0 {
            projectNamesCmb.reloadData()
            projectNamesCmb.selectItem(at: selectedProfileIndex)
        }
    }
    
    @IBAction func connect(_ sender: NSButton) {
        
        var session: NMSSHSession!
        
        let password = passwordTF.stringValue
        let userName = userNameTF.stringValue
        let host = hostTF.stringValue
        let port = portTF.integerValue
        let targetPath = targetPathTF.stringValue + "/"
        
        self.printProcessingInfo(info: "准备连接服务器...")
        
        DispatchQueue.global().async {
            
            session = NMSSHSession.connect(toHost: host, port: port, withUsername: userName)
            
            if !session.isConnected {
                
                self.printProcessingInfo(info: "无法连接到服务器")
                return
            }
            
            if (session.isConnected) {
                
                session.authenticate(byPassword: password)
                
                if !session.isAuthorized {
                    self.printProcessingInfo(info: "登录失败，请确认密码是否正确")
                    session.disconnect()
                    return
                }
                
                self.printProcessingInfo(info: "连接成功")
            }
            
            self.printProcessingInfo(info: "请选择要发布的文件所在的文件夹或已经打包好的压缩包")
            
            DispatchQueue.main.async {
                
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = true
                openPanel.canCreateDirectories = false
                openPanel.canChooseFiles = true
                let i = openPanel.runModal()
                
                if(i == NSApplication.ModalResponse.OK){
                    
                    DispatchQueue.global().async {
                        
                        var response = ""
                        let error: NSErrorPointer = nil;
                        
                        if let localFile = openPanel.url {
                            
                            // TODO: 判断选择的文件还是文件夹
                            let pathExtension = localFile.pathExtension
                            var localPath = ""
                            var fileName = ""
                            
                            // 选择的是目录
                            if pathExtension.isEmpty {
                                // 压缩该目录下的文件
                                // let zipPath = "\(localFile.path)/\(UUID().uuidString).zip" // 路径可用
                                // let zipPath = "\(localFile.deletingLastPathComponent().path)/\(UUID().uuidString).zip" // 路径不可行 权限问题？？
                                fileName = "\(localFile.lastPathComponent).zip"
                                var zipPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                                zipPath += "/\(fileName)" // 路径可用
                                let contentsPath = localFile.path
                                self.printProcessingInfo(info: "开始打包文件...")
                                let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: contentsPath)
                                
                                if success {
                                    
                                    localPath = zipPath
                                    self.printProcessingInfo(info: "文件打包完成")
                                    
                                } else {
                                    
                                    self.printProcessingInfo(info: "文件打包失败")
                                    return
                                }
                                
                            } else {
                                
                                // 设置要被上传文件路径
                                localPath = localFile.path
                                fileName = localFile.lastPathComponent
                            }
                            
                            self.printProcessingInfo(info: "开始上传打包文件")
                            
                            let result = session.channel.uploadFile(localPath, to: targetPath) { (bytes) -> Bool in
                                
                                self.printProcessingInfo(info: "文件上传字节数:\(bytes)")
                                if bytes == 0 {
                                    return false
                                }
                                
                                return true
                            }
                            
                            if result {
                                
                                self.printProcessingInfo(info: "文件上传完毕")
                                self.printProcessingInfo(info: "文件即将被解压缩")
                                
                                let cdCommand = "cd \(targetPath)"
                                let unzipCommand = "unzip -o \(fileName)"  // 覆盖解压
                                let rmCommand = "rm \(fileName)"
                                let bash:NSMutableString = ""
                                bash.append(cdCommand)
                                bash.append(unzipCommand)
                                // 解压文件
                                response = session.channel.execute("\(cdCommand);\(unzipCommand);\(rmCommand);", error: error)
                                
                                self.printProcessingInfo(info: response)
                                self.printProcessingInfo(info: "文件解压缩完毕，发布完成，服务器连接已关闭")
                                
                                session.disconnect();
                                
                            } else {
                                
                                session.disconnect();
                                self.printProcessingInfo(info: "文件上传失败，服务器连接已关闭")
                            }
                        }
                    }
                } else {
                    session.disconnect();
                    self.printProcessingInfo(info: "服务器连接已关闭")
                }
            }
        }
    }
    
    @IBAction func config(_ sender: NSButton) {
        let settingVC = ConfigViewController.init(nibName:"ConfigViewController", bundle: nil)
        settingVC.selectedProfileIndex = selectedProfileIndex >= 0 ? selectedProfileIndex : 0
        settingVC.completionHandler = { index in
            // 读取配置项
            self.profiles = self.readDefaults()
            self.projectNamesCmb.reloadData()
            
            if index >= 0 && self.profiles.count > 0 {
                self.selectedProfileIndex = index
                self.selectedProfile = self.profiles[self.selectedProfileIndex]
                self.projectNamesCmb.selectItem(at: self.selectedProfileIndex)
            } else {
                self.selectedProfile = nil
            }
        }
        self.presentAsModalWindow(settingVC)
    }
    
    // MARK- ComboBox 数据源

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return profiles.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return profiles[index].projectName
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        selectedProfileIndex = projectNamesCmb.indexOfSelectedItem
        if selectedProfileIndex >= 0 {
            selectedProfile = profiles[selectedProfileIndex]
        } else {
            selectedProfile = nil
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func printProcessingInfo(info: String) {
        if !info.isEmpty {
            DispatchQueue.main.async {
                self.resultView.documentView?.insertText(info)
                self.resultView.documentView?.insertNewline(nil)
            }
        }
    }
    
    func readDefaults() -> [ServerProfile] {
        var myProfiles = [ServerProfile]()
        let defaults = UserDefaults.standard
        
        if let profilesDefaults = defaults.array(forKey: "profiles"), profilesDefaults.count > 0 {
            for profileDict in profilesDefaults {
                if let newProfile = try? ServerProfile(dict: profileDict as! [String : Any]) {
                    myProfiles.append(newProfile)
                }
            }
        }
        return myProfiles
    }
}

