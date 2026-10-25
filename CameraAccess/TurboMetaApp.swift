/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// CameraAccessApp.swift
//
// Main entry point for the CameraAccess sample app demonstrating the Meta Wearables DAT SDK.
// This app shows how to connect to wearable devices (like Ray-Ban Meta smart glasses),
// stream live video from their cameras, and capture photos. It provides a complete example
// of DAT SDK integration including device registration, permissions, and media streaming.
//

import Foundation
import MWDATCore
import SwiftUI

@main
struct TurboMetaApp: App {
  private let wearables: WearablesInterface?
  @State private var showSetupNotice = false

  init() {
    do {
      try Wearables.configure()
      wearables = Wearables.shared
    } catch {
      // Accessing Wearables.shared after a failed configure() traps inside the SDK.
      // Keep the welcome screen available until this app's Meta configuration is supplied.
      wearables = nil
    }
  }

  var body: some Scene {
    WindowGroup {
      if let wearables {
        ConfiguredWearablesRoot(wearables: wearables)
      } else {
        UrbanWelcomeContent(isConnecting: false) { showSetupNotice = true }
          .alert("グラスの接続設定が必要です", isPresented: $showSetupNotice) {
            Button("OK", role: .cancel) {}
          } message: {
            Text("Metaとの接続を初期化できませんでした。このアプリのMeta App ID・Client TokenとiPhoneの対応状況を確認してください。")
          }
      }
    }
  }
}

private struct ConfiguredWearablesRoot: View {
  let wearables: WearablesInterface
  @StateObject private var viewModel: WearablesViewModel

  init(wearables: WearablesInterface) {
    self.wearables = wearables
    _viewModel = StateObject(wrappedValue: WearablesViewModel(wearables: wearables))
  }

  var body: some View {
    MainAppView(wearables: wearables, viewModel: viewModel)
      .alert("Error", isPresented: $viewModel.showError) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage)
      }
      .background { RegistrationView(viewModel: viewModel) }
  }
}
