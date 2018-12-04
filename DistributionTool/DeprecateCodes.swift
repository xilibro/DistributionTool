//
//  DeprecateCodes.swift
//  DistributionTool
//
//  Created by haihong on 2018/12/4.
//  Copyright © 2018 Sea Rainbow. All rights reserved.
//

import Foundation

// ####### SSH 命令 ##########
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
