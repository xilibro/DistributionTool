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

class ViewController: NSViewController {
    
    @IBOutlet weak var resultView: NSScrollView!
    @IBOutlet weak var targetPathTF: NSTextField!
    @IBOutlet weak var userNameTF: NSTextField!
    
    @IBOutlet weak var passwordTF: NSSecureTextField!
    @IBOutlet weak var hostTF: NSTextField!
    @IBOutlet weak var portTF: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        printProcessingInfo(info: "欢迎使用网站发布小工具 :)")
    }
    
    @IBAction func connect(_ sender: NSButton) {
        printProcessingInfo(info: "准备连接服务器...")
        
        let password = passwordTF.stringValue
        let userName = userNameTF.stringValue
        let host = hostTF.stringValue
        let port = portTF.integerValue
        let targetPath = targetPathTF.stringValue
        
        let session = NMSSHSession.connect(toHost: host, port: port, withUsername: userName)
        
        if !session.isConnected {
            printProcessingInfo(info: "无法连接到服务器")
            return
        }
        
        if (session.isConnected) {
            session.authenticate(byPassword: password)
            
            if !session.isAuthorized {
                printProcessingInfo(info: "登录失败，请确认密码是否有误")
                session.disconnect()
                return
            }
            
            printProcessingInfo(info: "连接成功")
            
            let error: NSErrorPointer = nil;
            var response = ""
            
            /**
             // 开启模式匹配功能，允许删除命令 rm -rf !(backup)
             let error: NSErrorPointer = nil;
             var response = session.channel.execute("shopt -s extglob", error: error)
             resultView.stringValue = resultView.stringValue + "\n" + response + "\n模式匹配功能已开启"
             */
            
            /**
             // 创建备份文件夹，备份文件
             // 判断文件夹是否存在的命令
             //haihong@127.0.0.1 test -d /Users/haihong/yuexl/work/macOS/sshtemp/backup && echo exists
             response = session.channel.execute("cd /Users/haihong/yuexl/work/macOS/sshtemp/server/; mkdir ../backup;", error: error)
             */
            
            /**
             // 是否备份
             // 进入到指定目录，备份
             let backup = false
             if backup {
             response = session.channel.execute("cd \(targetPath);mkdir ../backup; zip -r ../backup/xxx.zip ./\*; rm -rf \*;", error: error) // 这里的 * 匹配符与注释中的*号冲突了，故加了转义符
             }
             
             */
            
            /**
             // 是否清空部署目录
             // 清空部署目录 -- 选择覆盖解压，而不是清空目录
             response = session.channel.execute("cd \(targetPath); rm -rf !(MEIF);", error: error)
             printProcessingInfo(info: response)
             printProcessingInfo(info: "部署目录已清空")
             */
            
            printProcessingInfo(info: "请选择要发布的文件所在的文件夹或已经打包好的压缩包")
            
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            let i = openPanel.runModal()
            if(i == NSApplication.ModalResponse.OK){
                print(openPanel.url ?? "")
                if let localFile = openPanel.url {
                    // TODO: 判断选择的文件还是文件夹
                    let pathExtension = localFile.pathExtension
                    var localPath = ""
                    var fileName = ""
                    // 选择的是目录
                    if pathExtension.isEmpty {
                        // 压缩该目录下的文件
                        //                            let zipPath = "\(localFile.path)/\(UUID().uuidString).zip" // 路径可用
                        //                            let zipPath = "\(localFile.deletingLastPathComponent().path)/\(UUID().uuidString).zip" // 路径不可行 权限问题？？
                        fileName = "\(localFile.lastPathComponent).zip"
                        var zipPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                        zipPath += "/\(fileName)" // 路径可用
                        
                        let contentsPath = localFile.path
                        printProcessingInfo(info: "开始打包文件...")
                        let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: contentsPath)
                        if success {
                            localPath = zipPath
                            printProcessingInfo(info: "文件打包完成")
                        } else {
                            self.printProcessingInfo(info: "文件打包失败")
                            return
                        }
                    } else {
                        // 设置要被上传文件路径
                        localPath = localFile.path
                        fileName = localFile.lastPathComponent
                    }
                    
                    printProcessingInfo(info: "开始上传打包文件")
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
                        self.printProcessingInfo(info: "文件解压缩完毕，发布完成")
                        
                        session.disconnect();
                        
                    } else {
                        self.printProcessingInfo(info: "文件上传失败")
                        session.disconnect();
                    }
                }
            } else {
                session.disconnect();
            }
        }
    }
    
    @IBAction func config(_ sender: NSButton) {
        let settingVC = SettingViewController.init(nibName:"SettingViewController", bundle: nil)
        self.presentAsModalWindow(settingVC)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func printProcessingInfo(info: String) {
        if !info.isEmpty {
            resultView.documentView?.insertText(info)
            resultView.documentView?.insertNewline(nil)
        }
    }
    
}

