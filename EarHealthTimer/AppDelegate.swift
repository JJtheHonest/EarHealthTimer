//
//  AppDelegate.swift
//  EarHealthTimer
//
//  Created by 尹家杰 on 2025/10/19.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 设置窗口代理
        if let window = NSApplication.shared.windows.first {
            self.window = window
            window.delegate = self
        }

        // 2. 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: nil)
            button.action = #selector(toggleWindow)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let alert = NSAlert()
        alert.messageText = "是否退出程序？"
        alert.informativeText = "选择“后台运行”将继续检测耳机状态并发送提醒。"
        alert.addButton(withTitle: "退出")
        alert.addButton(withTitle: "后台运行")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 用户选择退出
            NSApplication.shared.terminate(nil)
            return true
        } else {
            // 用户选择后台运行
            sender.orderOut(nil) // 关闭窗口但保持应用运行
            return false
        }
    }
    
    @objc func toggleWindow() {
        if let window = self.window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

}
