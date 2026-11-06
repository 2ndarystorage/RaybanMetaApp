/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// HomeScreenView.swift
//
// Welcome screen that guides users through the DAT SDK registration process.
// This view is displayed when the app is not yet registered.
//

import MWDATCore
import SwiftUI

struct HomeScreenView: View {
  @ObservedObject var viewModel: WearablesViewModel
  var body: some View {
    UrbanWelcomeContent(isConnecting: viewModel.registrationState == .registering) {
      viewModel.connectGlasses()
    }
    .modifier(VoiceMemoWelcomeEntry())
  }
}

struct VoiceMemoWelcomeEntry: ViewModifier {
  @State private var showVoiceMemo = false

  func body(content: Content) -> some View {
    content.safeAreaInset(edge: .bottom) {
      Button { showVoiceMemo = true } label: {
        Label("音声メモを使う（グラス接続不要）", systemImage: "mic.fill")
          .font(.body.weight(.semibold))
          .frame(maxWidth: .infinity, minHeight: 48)
          .padding(.horizontal)
      }
      .buttonStyle(.bordered)
      .background(.regularMaterial)
    }
    .sheet(isPresented: $showVoiceMemo) { VoiceMemoView() }
  }
}
