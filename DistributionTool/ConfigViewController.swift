//
//  ConfigViewController.swift
//  DistributionTool
//
//  Created by haihong on 2018/12/3.
//  Copyright © 2018 Sea Rainbow. All rights reserved.
//

import Cocoa

fileprivate enum CellIdentifiers {
    static let ProfileCell = "ProfileCellID"
}

class ConfigViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var profileTable: NSTableView!
    
    // Closure 用于传值给父Controller
    var completionHandler: ((Int) -> Void)?
    
    // 允许KVC，绑定到UI
    @objc dynamic var selectedProfile: ServerProfile!
    var selectedProfileIndex = 0
    var profiles = [ServerProfile]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        profileTable.dataSource = self
        profileTable.delegate = self
        
        // 读取配置项
        let defaults = UserDefaults.standard
        
        if let profilesDefaults = defaults.array(forKey: "profiles"), profilesDefaults.count > 0 {
            for profileDict in profilesDefaults {
                if let newProfile = try? ServerProfile(dict: profileDict as! [String : Any]) {
                    profiles.append(newProfile)
                }
            }
        }
        
        profileTable.reloadData()
        
        if profiles.count > 0 {
            selectedProfile = profiles[selectedProfileIndex]
            profileTable.selectRowIndexes(IndexSet(integer: selectedProfileIndex), byExtendingSelection: false)
        }
    }
    
    @IBAction func saveConfig(_ sender: Any) {
        var savingProfiles: [[String: Any]] = []
        for profile in profiles {
            let profileDict = ["host": profile.host, "port": profile.port, "userName": profile.userName, "password": profile.password, "targetPath":profile.targetPath, "projectName": profile.projectName] as [String : Any]
            savingProfiles.append(profileDict)
        }
        // 保存到首选项
        UserDefaults.standard.set(savingProfiles, forKey: "profiles")
        // 传值给父Controller
        completionHandler?(selectedProfileIndex);
        // 关闭窗口
        self.dismiss(sender)
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(sender)
    }
    
    @IBAction func addOrRemoveProject(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            // 新增配置
            addNewConfg()
        case 1:
            removeConfig()
        default: break
            
        }
    }
    
    func addNewConfg () {
        // 列表添加
        let newProfile = ServerProfile()
        profiles.append(newProfile)
        profileTable.reloadData()
        selectedProfileIndex = profiles.endIndex - 1
        selectedProfile = profiles[selectedProfileIndex]
        profileTable.selectRowIndexes(IndexSet(integer: selectedProfileIndex), byExtendingSelection: false)
        
    }
    
    func removeConfig () {
        // 列表删除
        if profiles.count > 0 {
            selectedProfileIndex = profileTable.selectedRow
            profiles.remove(at: selectedProfileIndex)
            profileTable.reloadData()
            
            if profiles.count > 0 {
                selectedProfileIndex = selectedProfileIndex == 0 ? 0 : selectedProfileIndex - 1
                selectedProfile = profiles[selectedProfileIndex]
                profileTable.selectRowIndexes(IndexSet(integer: selectedProfileIndex), byExtendingSelection: false)
            } else {
                selectedProfileIndex = -1
                selectedProfile = nil
            }
        }
    }
    
    // MARK: - profileTable data source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return profiles.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let profile = profiles[row]
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.ProfileCell), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = profile.projectName
            return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let view = notification.object as? NSTableView {
            if view == profileTable {
                selectedProfileIndex = view.selectedRow
                if selectedProfileIndex >= 0 {
                    selectedProfile = profiles[selectedProfileIndex]
                }
            }
        }
    }
}
