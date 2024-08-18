//
//  OverrideViewModelTests.swift
//  LoopCaregiverTests
//
//  Created by Bill Gestrich on 10/1/23.
//

import Combine
@testable import LoopCaregiver
import NightscoutKit
import XCTest

final class OverrideViewModelTests: XCTestCase {
    // MARK: Loading States

    func testLoading_OverrideActive_SelectsOverride() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let activeOverride = presets.last!
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        XCTAssertEqual(viewModel.pickerSelectedRow?.name, activeOverride.name)
    }

    func testLoading_OverridesInactive_SelectsNoOverride() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        XCTAssertNil(viewModel.activeOverride)
    }

    func testLoading_WhenSuccessful_HasCompleteState() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        switch viewModel.overrideListState {
        case .loadingComplete(let resultingOverrideState):
            XCTAssertEqual(resultingOverrideState, overrideState)
        default:
            XCTFail("Wrong case")
        }
    }

    func testLoading_WhenErrorOccurs_HasErrorState() async throws {
        // Arrange

        let loadingError = OverrideViewDelegateMock.MockError.networkError
        let delegate = OverrideViewDelegateMock(mockState: .error(loadingError))
        let viewModel = OverrideViewModel()

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        switch viewModel.overrideListState {
        case .loadingError(let err):
            XCTAssertEqual(err.localizedDescription, loadingError.localizedDescription)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertNil(viewModel.pickerSelectedRow)
    }

    func testLoading_WhileLoading_HasLoadingState() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        var progressWasLoading = false

        _ = viewModel.$overrideListState.sink { val in
            switch val {
            case .loading:
                progressWasLoading = true
            default:
                break
            }
        }

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        XCTAssertTrue(progressWasLoading)
    }

    // MARK: Enabled Button

    func testPickerChanged_NoActiveOverride_EnablesUpdateButton() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let activeOverride = presets[1]
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        let selectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: activeOverride)

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        viewModel.pickerSelectedRow = selectedRow

        // Assert

        switch viewModel.overrideListState {
        case .loadingComplete(let loadedState):
            XCTAssertEqual(loadedState, overrideState)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertEqual(viewModel.pickerSelectedRow, selectedRow)
    }

    func testPickerChanged_ActiveOverride_DisablesUpdateButton() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let activeOverride = presets[0]
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        // Act

        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)

        // Assert

        switch viewModel.overrideListState {
        case .loadingComplete(let loadedState):
            XCTAssertEqual(loadedState, overrideState)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertEqual(viewModel.pickerSelectedRow?.name, viewModel.activeOverride?.name)
    }

    // MARK: Delivery

    func testDeliver_WhenValid_Succeeds() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let initialActiveOverride = presets[0]
        let overrideState = OverrideState(activeOverride: initialActiveOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()

        // Act

        var deliveryCompletionCalled = false
        await viewModel.setup(delegate: delegate, deliveryCompleted: { deliveryCompletionCalled = true })
        let updatedActiveOverride = presets[1]
        viewModel.pickerSelectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: updatedActiveOverride)
        await viewModel.updateButtonTapped()

        // Assert

        XCTAssertTrue(deliveryCompletionCalled)
        let receivedRequest = delegate.receivedOverrideRequests.first!
        XCTAssertEqual(updatedActiveOverride.name, receivedRequest.overrideName)
        XCTAssertEqual(updatedActiveOverride.duration, receivedRequest.durationTime)
    }

    func testDeliver_WhenInvalid_Fails() async throws {
        // Arrange

        let presets = [
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏃",
                name: "Running"
            ),
            TemporaryScheduleOverride(
                duration: 60.0,
                targetRange: nil,
                insulinNeedsScaleFactor: nil,
                symbol: "🏊",
                name: "Swimming"
            )
        ]
        let initialActiveOverride = presets[0]
        let overrideState = OverrideState(activeOverride: initialActiveOverride, presets: presets)
        let deliveryError = OverrideViewDelegateMock.MockError.networkError
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState), mockDeliveryError: deliveryError)
        let viewModel = OverrideViewModel()

        // Act

        var deliveryCompletionCalled = false
        await viewModel.setup(delegate: delegate, deliveryCompleted: { deliveryCompletionCalled = true })
        let updatedActiveOverride = presets[1]
        viewModel.pickerSelectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: updatedActiveOverride)
        await viewModel.updateButtonTapped()

        // Assert
        let receivedRequest = delegate.receivedOverrideRequests.first!
        XCTAssertEqual(updatedActiveOverride.name, receivedRequest.overrideName)
        XCTAssertEqual(updatedActiveOverride.duration, receivedRequest.durationTime)
        XCTAssertFalse(deliveryCompletionCalled)
        XCTAssertEqual(deliveryError.localizedDescription, viewModel.lastDeliveryError?.localizedDescription)
    }
}
