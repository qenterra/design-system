import AppKit
import CoreGraphics
import Darwin
import Foundation
import IOKit.graphics

/// Disposable-CI inventory only. This file deliberately contains no display-mode setter.
enum DisplayInventoryFailure: Error {
    case invalidArguments
    case displayListQuery(CGError)
    case unsupportedDisplayCount(UInt32)
}

struct ScreenObservation {
    let displayID: CGDirectDisplayID?
    let beforeScale: Double
    let afterScale: Double
    let matchesTargetScreen: Bool
    let record: [String: Any]
}

func jsonOptional(_ value: Any?) -> Any {
    value ?? NSNull()
}

func processArchitecture() -> String {
    #if arch(arm64)
        "arm64"
    #elseif arch(x86_64)
        "x86_64"
    #else
        "other"
    #endif
}

func onlineDisplayIDs() throws -> [CGDirectDisplayID] {
    var count: UInt32 = 0
    let countResult = CGGetOnlineDisplayList(0, nil, &count)
    guard countResult == .success else { throw DisplayInventoryFailure.displayListQuery(countResult) }
    guard count <= 256 else { throw DisplayInventoryFailure.unsupportedDisplayCount(count) }
    guard count > 0 else { return [] }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    var returnedCount: UInt32 = 0
    let result = displays.withUnsafeMutableBufferPointer {
        CGGetOnlineDisplayList(count, $0.baseAddress, &returnedCount)
    }
    guard result == .success else { throw DisplayInventoryFailure.displayListQuery(result) }
    return Array(displays.prefix(Int(returnedCount)))
}

func modeRecord(_ mode: CGDisplayMode, currentID: Int32?) -> [String: Any] {
    let flags = mode.ioFlags
    let ratioX = mode.width > 0 ? Double(mode.pixelWidth) / Double(mode.width) : 0
    let ratioY = mode.height > 0 ? Double(mode.pixelHeight) / Double(mode.height) : 0
    return [
        "modeID": mode.ioDisplayModeID,
        "logicalWidthPoints": mode.width,
        "logicalHeightPoints": mode.height,
        "pixelWidth": mode.pixelWidth,
        "pixelHeight": mode.pixelHeight,
        "pixelToPointRatioX": ratioX,
        "pixelToPointRatioY": ratioY,
        "advertisedTwoToOneGeometry": ratioX == 2 && ratioY == 2,
        "refreshRateHz": mode.refreshRate,
        "isUsableForDesktopGUI": mode.isUsableForDesktopGUI(),
        "ioFlags": flags,
        "ioFlagsHex": String(format: "0x%08x", flags),
        "validFlag": flags & UInt32(kDisplayModeValidFlag) != 0,
        "safeFlag": flags & UInt32(kDisplayModeSafeFlag) != 0,
        "interlacedFlag": flags & UInt32(kDisplayModeInterlacedFlag) != 0,
        "stretchedFlag": flags & UInt32(kDisplayModeStretchedFlag) != 0,
        "validForHiResFlag": flags & UInt32(kDisplayModeValidForHiResFlag) != 0,
        "matchesCurrentModeID": mode.ioDisplayModeID == currentID,
    ]
}

func displayRecord(_ display: CGDirectDisplayID) -> [String: Any] {
    let current = CGDisplayCopyDisplayMode(display)
    let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
    let modes = CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode]
    let defaults = CGDisplayCopyAllDisplayModes(display, nil) as? [CGDisplayMode]
    return [
        "displayID": display,
        "isMain": CGDisplayIsMain(display) != 0,
        "isActive": CGDisplayIsActive(display) != 0,
        "isOnline": CGDisplayIsOnline(display) != 0,
        "isBuiltIn": CGDisplayIsBuiltin(display) != 0,
        "isInMirrorSet": CGDisplayIsInMirrorSet(display) != 0,
        "mirrorsDisplayID": CGDisplayMirrorsDisplay(display),
        "bounds": NSStringFromRect(CGDisplayBounds(display)),
        "currentMode": jsonOptional(current.map { modeRecord($0, currentID: $0.ioDisplayModeID) }),
        "duplicateLowResolutionQuerySucceeded": modes != nil,
        "defaultQuerySucceeded": defaults != nil,
        "defaultQueryModeCount": defaults?.count ?? 0,
        "allModesIncludingDuplicateLowResolution": (modes ?? []).map {
            modeRecord($0, currentID: current?.ioDisplayModeID)
        },
    ]
}

@MainActor
func screenID(_ screen: NSScreen) -> CGDirectDisplayID? {
    if #available(macOS 26.0, *) {
        return screen.cgDirectDisplayID
    }
    return (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
}

@MainActor
func observeWindow(on screen: NSScreen) -> ScreenObservation {
    let frame = NSRect(x: screen.frame.midX - 64, y: screen.frame.midY - 48, width: 128, height: 96)
    let window = NSWindow(
        contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen
    )
    window.isReleasedWhenClosed = false
    window.contentView = NSView(frame: NSRect(origin: .zero, size: frame.size))
    defer {
        window.orderOut(nil)
        window.contentView = nil
        window.close()
    }
    let beforeScale = Double(window.backingScaleFactor)
    let beforeScreen = window.screen.flatMap { screenID($0) }
    window.orderFront(nil)
    window.contentView?.layoutSubtreeIfNeeded()
    window.contentView?.displayIfNeeded()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
    let afterScale = Double(window.backingScaleFactor)
    let afterScreen = window.screen.flatMap { screenID($0) }
    let matchesTargetScreen = beforeScreen == screenID(screen) && afterScreen == screenID(screen)
    let backingRect = window.convertToBacking(NSRect(origin: .zero, size: frame.size))
    return ScreenObservation(
        displayID: screenID(screen), beforeScale: beforeScale, afterScale: afterScale,
        matchesTargetScreen: matchesTargetScreen,
        record: [
            "displayID": jsonOptional(screenID(screen)),
            "name": screen.localizedName,
            "frame": NSStringFromRect(screen.frame),
            "visibleFrame": NSStringFromRect(screen.visibleFrame),
            "screenBackingScale": Double(screen.backingScaleFactor),
            "windowTargetRectPoints": NSStringFromRect(frame),
            "windowBackingScaleBeforeOrderFront": beforeScale,
            "windowBackingScaleAfterDisplay": afterScale,
            "windowBackingScaleStable": beforeScale == afterScale,
            "windowScreenDisplayIDBefore": jsonOptional(beforeScreen),
            "windowScreenDisplayIDAfter": jsonOptional(afterScreen),
            "windowMatchesTargetScreen": matchesTargetScreen,
            "windowConvertedBackingRect": NSStringFromRect(backingRect),
        ]
    )
}

@MainActor
func emitInventory(requiredMainScale: Double?) throws -> Bool {
    _ = NSApplication.shared
    let initialIDs = try onlineDisplayIDs()
    let initialModes = initialIDs.map { CGDisplayCopyDisplayMode($0)?.ioDisplayModeID }
    let displays = initialIDs.map(displayRecord)
    let screens = NSScreen.screens.map(observeWindow)
    let finalIDs = try onlineDisplayIDs()
    let finalModes = initialIDs.map { CGDisplayCopyDisplayMode($0)?.ioDisplayModeID }
    let stable = initialIDs == finalIDs && initialModes == finalModes
    let main = screens.first { $0.displayID == CGMainDisplayID() }
    let requirementMet = requiredMainScale.map { wanted in
        stable && main?.matchesTargetScreen == true && main?.beforeScale == wanted && main?.afterScale == wanted
    } ?? true
    let environment = ProcessInfo.processInfo.environment
    let report: [String: Any] = [
        "schemaVersion": 1,
        "scope": "Read-only disposable-CI advertised-mode and actual-window inventory; not Design System image acceptance",
        "timestampUTC": ISO8601DateFormatter().string(from: Date()),
        "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
        "processArchitecture": processArchitecture(),
        "displayModesChangedByProbe": false,
        "duplicateLowResolutionModesRequested": true,
        "onlineDisplayIDsAtStart": initialIDs,
        "onlineDisplayIDsAtEnd": finalIDs,
        "topologyAndCurrentModesStable": stable,
        "displays": displays,
        "nativeScreenAndWindowObservations": screens.map(\.record),
        "requiredMainWindowBackingScale": jsonOptional(requiredMainScale),
        "requirementMet": requirementMet,
        "provider": [
            "RUNNER_OS": environment["RUNNER_OS"] ?? "unknown",
            "ImageOS": environment["ImageOS"] ?? "unknown",
            "ImageVersion": environment["ImageVersion"] ?? "unknown",
        ],
    ]
    let encoded = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(encoded)
    FileHandle.standardOutput.write(Data([0x0A]))
    return requirementMet
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let requiredScale: Double?
    switch arguments {
    case [], ["--inventory"]:
        requiredScale = nil
    case ["--require-main-window-scale", "1"]:
        requiredScale = 1
    case ["--require-main-window-scale", "2"]:
        requiredScale = 2
    default:
        throw DisplayInventoryFailure.invalidArguments
    }
    let met = try MainActor.assumeIsolated { try emitInventory(requiredMainScale: requiredScale) }
    if !met {
        exit(2)
    }
} catch {
    FileHandle.standardError.write(Data("Display inventory failed: \(error)\n".utf8))
    exit(1)
}
