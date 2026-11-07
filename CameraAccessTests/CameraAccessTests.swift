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

private final class LatencyURLProtocol: URLProtocol {
  static var chunks: [Data] = []
  static var mimeType = "text/event-stream"
  static var status = 200
  private let lock = NSLock()
  private var stopped = false

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil,
                                   headerFields: ["Content-Type": Self.mimeType])!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    let chunks = Self.chunks
    if let first = chunks.first { client?.urlProtocol(self, didLoad: first) }
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
      guard let self else { return }
      self.lock.lock()
      let stopped = self.stopped
      self.lock.unlock()
      guard !stopped else { return }
      for chunk in chunks.dropFirst() { self.client?.urlProtocol(self, didLoad: chunk) }
      self.client?.urlProtocolDidFinishLoading(self)
    }
  }

  override func stopLoading() {
    lock.lock()
    stopped = true
    lock.unlock()
  }
}

@MainActor
final class LatencyImprovementTests: XCTestCase {
  private func image(size: CGSize = CGSize(width: 3200, height: 2400), scale: CGFloat = 1) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }

  private func service() -> QuickVisionService {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [LatencyURLProtocol.self]
    LatencyURLProtocol.mimeType = "text/event-stream"
    LatencyURLProtocol.status = 200
    return QuickVisionService(apiKey: "test-key", session: URLSession(configuration: configuration))
  }

  func testSentencesAcrossChunksPreserveOrderAndRemainder() {
    var buffer = VisionSentenceBuffer()
    XCTAssertEqual(buffer.append("目の前に"), [])
    XCTAssertEqual(buffer.append("机があります。右に椅子"), ["目の前に机があります。"])
    XCTAssertEqual(buffer.append("があります！\n"), ["右に椅子があります！"])
    XCTAssertEqual(buffer.append("残りの説明"), [])
    XCTAssertEqual(buffer.finish(), "残りの説明")
    XCTAssertNil(buffer.finish())
  }

  func testEnglishDecimalIsNotSplit() {
    var buffer = VisionSentenceBuffer()
    XCTAssertEqual(buffer.append("It costs 3."), [])
    XCTAssertEqual(buffer.append("50. Next sentence."), ["It costs 3.50."])
    XCTAssertEqual(buffer.finish(), "Next sentence.")
  }

  func testSSECommentsAndMultilineData() {
    var buffer = VisionEventBuffer()
    XCTAssertNil(buffer.append(": keep-alive"))
    XCTAssertNil(buffer.append("event: message"))
    XCTAssertNil(buffer.append("data: {"))
    XCTAssertEqual(buffer.append("data: \"value\":1}"), "{\n\"value\":1}")
    XCTAssertNil(buffer.append(""))
    XCTAssertNil(buffer.finishEvent())
  }

  func testUploadPixelBoundsAndNoUpscaling() throws {
    let large = image()
    let scene = try XCTUnwrap(UIImage(data: XCTUnwrap(ImageUploadPreparation.jpeg(large, purpose: .scene))))
    let document = try XCTUnwrap(UIImage(data: XCTUnwrap(ImageUploadPreparation.jpeg(large, purpose: .document))))
    XCTAssertEqual(scene.size, CGSize(width: 1280, height: 960))
    XCTAssertEqual(document.size, CGSize(width: 2048, height: 1536))
    let small = try XCTUnwrap(UIImage(data: XCTUnwrap(ImageUploadPreparation.jpeg(image(size: CGSize(width: 100, height: 50), scale: 2), purpose: .scene))))
    XCTAssertEqual(small.size, CGSize(width: 200, height: 100))
  }

  func testRotatedImageKeepsPortraitOrientation() throws {
    let source = image(size: CGSize(width: 2400, height: 3200))
    let rotated = UIImage(cgImage: try XCTUnwrap(source.cgImage), scale: 1, orientation: .right)
    let prepared = try XCTUnwrap(UIImage(data: XCTUnwrap(ImageUploadPreparation.jpeg(rotated, purpose: .scene))))
    XCTAssertEqual(prepared.size, CGSize(width: 1280, height: 960))
    XCTAssertEqual(prepared.imageOrientation, .up)
  }

  func testFirstDeltaArrivesBeforeResponseFinishes() async throws {
    let service = service()
    LatencyURLProtocol.chunks = [
      Data("data: {\"choices\":[{\"delta\":{\"content\":\"机です。\"}}]}\n\n".utf8),
      Data("data: {\"choices\":[{\"delta\":{\"content\":\"椅子です。\"}}]}\n\ndata: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n".utf8)
    ]
    let firstDelta = expectation(description: "First text before completion")
    var received: [String] = []
    var completed = false
    let task = Task {
      let result = try await service.analyzeImage(image(size: CGSize(width: 10, height: 10))) { delta in
        received.append(delta)
        if received.count == 1 { firstDelta.fulfill() }
      }
      completed = true
      return result
    }
    await fulfillment(of: [firstDelta], timeout: 1.2)
    XCTAssertFalse(completed)
    let result = try await task.value
    XCTAssertEqual(result, "机です。椅子です。")
    XCTAssertEqual(received, ["机です。", "椅子です。"])
  }

  func testTruncatedStreamIsNotSuccessful() async throws {
    let service = service()
    LatencyURLProtocol.chunks = [Data("data: {\"choices\":[{\"delta\":{\"content\":\"途中\"}}]}\n\n".utf8)]
    do {
      _ = try await service.analyzeImage(image(size: CGSize(width: 10, height: 10)))
      XCTFail("Incomplete response must fail")
    } catch { XCTAssertTrue(error is QuickVisionError) }
  }

  func testCancellationDoesNotDeliverLaterDeltas() async throws {
    let service = service()
    LatencyURLProtocol.chunks = [
      Data("data: {\"choices\":[{\"delta\":{\"content\":\"最初。\"}}]}\n\n".utf8),
      Data("data: {\"choices\":[{\"delta\":{\"content\":\"遅延。\"}}]}\n\ndata: [DONE]\n\n".utf8)
    ]
    let firstDelta = expectation(description: "First delta")
    var received: [String] = []
    let task = Task {
      try await service.analyzeImage(image(size: CGSize(width: 10, height: 10))) { delta in
        received.append(delta)
        firstDelta.fulfill()
      }
    }
    await fulfillment(of: [firstDelta], timeout: 1.2)
    task.cancel()
    do { _ = try await task.value; XCTFail("Expected cancellation") } catch {}
    XCTAssertEqual(received, ["最初。"])
  }

  func testFinalMemoTextUpdatesSameSavedRecord() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let storage = VoiceMemoStorage(url: folder.appendingPathComponent("memos.json"))
    let model = VoiceMemoModel(storage: storage)
    model.text = "停止時点の文章"
    XCTAssertTrue(model.save())
    let first = try XCTUnwrap(storage.load().first)
    model.text = "停止時点の文章。最後のことば。"
    XCTAssertTrue(model.save())
    let records = try storage.load()
    XCTAssertEqual(records.count, 1)
    XCTAssertEqual(records.first?.id, first.id)
    XCTAssertEqual(records.first?.text, model.text)
  }
}
