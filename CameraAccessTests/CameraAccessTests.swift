/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import MWDATCore
import MWDATMockDevice
import SwiftUI
import XCTest

@testable import CameraAccess

@MainActor
class ViewModelIntegrationTests: XCTestCase {

  private var mockDevice: MockRaybanMeta?
  private var cameraKit: MockCameraKit?

  override func setUp() async throws {
    try await super.setUp()
    try? Wearables.configure()

    // Pair mock device and set up camera kit
    let pairedMockDevice = MockDeviceKit.shared.pairRaybanMeta()
    mockDevice = pairedMockDevice
    cameraKit = pairedMockDevice.getCameraKit()

    // Power on and unfold the device to make it available
    pairedMockDevice.powerOn()
    pairedMockDevice.unfold()

    // Wait for device to be available in Wearables
    try await Task.sleep(nanoseconds: 1_000_000_000)
  }

  override func tearDown() async throws {
    MockDeviceKit.shared.pairedDevices.forEach { mockDevice in
      MockDeviceKit.shared.unpairDevice(mockDevice)
    }
    mockDevice = nil
    cameraKit = nil
    try await super.tearDown()
  }

  // MARK: - Video Streaming Flow Tests

  func testVideoStreamingFlow() async throws {
    guard let camera = cameraKit else {
      XCTFail("Mock device and camera should be available")
      return
    }

    guard let videoURL = Bundle(for: type(of: self)).url(forResource: "plant", withExtension: "mp4") else {
      XCTFail("Could not find resource in test bundle")
      return
    }

    // Setup camera feed
    await camera.setCameraFeed(fileURL: videoURL)

    let viewModel = StreamSessionViewModel(wearables: Wearables.shared)

    // Initially not streaming
    XCTAssertEqual(viewModel.streamingStatus, .stopped)
    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertFalse(viewModel.hasReceivedFirstFrame)
    XCTAssertNil(viewModel.currentVideoFrame)

    // Start streaming session
    await viewModel.handleStartStreaming()

    // Wait for streaming to establish
    try await Task.sleep(nanoseconds: 10_000_000_000)

    // Verify streaming is active and receiving frames
    XCTAssertTrue(viewModel.isStreaming)
    XCTAssertTrue(viewModel.hasReceivedFirstFrame)
    XCTAssertNotNil(viewModel.currentVideoFrame)
    XCTAssertTrue([.streaming, .waiting].contains(viewModel.streamingStatus))

    // Stop streaming
    await viewModel.stopSession()

    // Wait for session to stop
    try await Task.sleep(nanoseconds: 1_000_000_000)

    // Verify streaming stopped (allow for final states to be stopped or waiting)
    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertTrue([.stopped, .waiting].contains(viewModel.streamingStatus))
  }

  // MARK: - Photo Capture Flow Tests

  func testStreamingAndPhotoCaptureFlow() async throws {
    guard let camera = cameraKit else {
      XCTFail("Mock device and camera should be available")
      return
    }

    guard let videoURL = Bundle(for: type(of: self)).url(forResource: "plant", withExtension: "mp4") else {
      XCTFail("Could not find resource in test bundle")
      return
    }

    guard let imageURL = Bundle(for: type(of: self)).url(forResource: "plant", withExtension: "png") else {
      XCTFail("Could not find resource in test bundle")
      return
    }

    // Setup camera feed
    await camera.setCameraFeed(fileURL: videoURL)
    await camera.setCapturedImage(fileURL: imageURL)

    let viewModel = StreamSessionViewModel(wearables: Wearables.shared)

    // Initially not streaming
    XCTAssertEqual(viewModel.streamingStatus, .stopped)
    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertFalse(viewModel.hasReceivedFirstFrame)
    XCTAssertNil(viewModel.currentVideoFrame)

    // Start streaming session
    await viewModel.handleStartStreaming()

    // Wait for streaming to establish
    try await Task.sleep(nanoseconds: 10_000_000_000)

    // Verify streaming is active and receiving frames
    XCTAssertTrue(viewModel.isStreaming)
    XCTAssertTrue(viewModel.hasReceivedFirstFrame)
    XCTAssertNotNil(viewModel.currentVideoFrame)
    XCTAssertTrue([.streaming, .waiting].contains(viewModel.streamingStatus))

    // Capture photo while streaming
    viewModel.capturePhoto()
    try await Task.sleep(nanoseconds: 10_000_000_000)

    // Verify photo captured while maintaining stream (allow for some timing flexibility)
    XCTAssertTrue(viewModel.capturedPhoto != nil)
    XCTAssertTrue(viewModel.showPhotoPreview)
    XCTAssertTrue(viewModel.isStreaming)

    // Dismiss photo and stop streaming
    viewModel.dismissPhotoPreview()
    XCTAssertFalse(viewModel.showPhotoPreview)
    XCTAssertNil(viewModel.capturedPhoto)

    await viewModel.stopSession()
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertTrue([.stopped, .waiting].contains(viewModel.streamingStatus))
  }
}

// Book summaries use a mocked HTTPS transport; these tests never call OpenAI.
private final class BookSummaryURLProtocol: URLProtocol {
  static var handler: ((URLRequest) throws -> (Int, Data))?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let (status, data) = try Self.handler!(request)
      let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  override func stopLoading() {}
}

@MainActor
final class BookSummaryTests: XCTestCase {
  private func response(_ summary: String, readable: Bool = true) throws -> Data {
    let content = try JSONSerialization.data(withJSONObject: ["readable": readable, "summary": summary])
    return try JSONSerialization.data(withJSONObject: [
      "choices": [["message": ["content": String(decoding: content, as: UTF8.self)]]]
    ])
  }

  private func service() -> BookSummaryService {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [BookSummaryURLProtocol.self]
    return BookSummaryService(session: URLSession(configuration: configuration))
  }

  private func image() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
  }

  func testCharacterLimitsIncludeEmojiAndPunctuation() {
    for limit in [50, 200, 1000] {
      let text = String(repeating: "本👨‍👩‍👧‍👦。", count: 600)
      let result = BookSummaryService.fit(text, limit: limit)
      XCTAssertLessThanOrEqual(result.count, limit)
      XCTAssertTrue(result.hasSuffix("。"))
      XCTAssertEqual(BookSummaryService.fit(String(repeating: "あ", count: limit), limit: limit).count, limit)
      XCTAssertEqual(BookSummaryService.fit(String(repeating: "あ", count: limit + 1), limit: limit).count, limit)
    }
    XCTAssertEqual(BookSummaryService.fit("本", limit: 0), "")
  }

  func testReadablePageNeedsOneRequest() async throws {
    let data = try response("本の内容を短くまとめます。")
    var calls = 0
    BookSummaryURLProtocol.handler = { request in
      calls += 1
      XCTAssertEqual(request.url?.host, "api.openai.com")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      return (200, data)
    }
    let result = try await service().summarize(image: image(), apiKey: "test-key", limit: 200)
    XCTAssertEqual(result, "本の内容を短くまとめます。")
    XCTAssertEqual(calls, 1)
  }

  func testOverlongSummaryRetriesOnceThenEnforcesLimit() async throws {
    let data = try response(String(repeating: "あ", count: 300))
    var calls = 0
    BookSummaryURLProtocol.handler = { _ in calls += 1; return (200, data) }
    let result = try await service().summarize(image: image(), apiKey: "test-key", limit: 50)
    XCTAssertEqual(calls, 2)
    XCTAssertEqual(result.count, 50)
  }

  func testUnreadablePageShowsRetakeGuidance() async throws {
    let data = try response("", readable: false)
    BookSummaryURLProtocol.handler = { _ in (200, data) }
    do {
      _ = try await service().summarize(image: image(), apiKey: "test-key", limit: 200)
      XCTFail("Unreadable page must fail")
    } catch {
      XCTAssertTrue(error.localizedDescription.contains("文章を十分に読み取れませんでした"))
    }
  }

  func testAPIKeyAndQuotaErrors() async {
    for (status, message) in [(401, "APIキー"), (429, "利用上限")] {
      BookSummaryURLProtocol.handler = { _ in (status, Data()) }
      do {
        _ = try await service().summarize(image: image(), apiKey: "test-key", limit: 200)
        XCTFail("HTTP error must fail")
      } catch {
        XCTAssertTrue(error.localizedDescription.contains(message))
      }
    }
  }

  func testMissingKeyDoesNotStartRequest() {
    let reader = BookReaderModel(readAPIKey: { " " }, summarize: { _, _, _ in
      XCTFail("Missing key must not send a request")
      return ""
    })
    reader.read(image: image(), limit: 200)
    XCTAssertFalse(reader.isWorking)
    XCTAssertNotNil(reader.errorMessage)
  }

  func testCancellationDiscardsLateResult() async throws {
    let reader = BookReaderModel(readAPIKey: { "test-key" }, summarize: { _, _, _ in
      try? await Task.sleep(nanoseconds: 50_000_000)
      return "キャンセル後に届いた要約"
    })
    reader.read(image: image(), limit: 200)
    await Task.yield()
    reader.stop()
    try await Task.sleep(nanoseconds: 100_000_000)
    XCTAssertFalse(reader.isWorking)
    XCTAssertTrue(reader.summary.isEmpty)
    XCTAssertNil(reader.errorMessage)
  }
}
