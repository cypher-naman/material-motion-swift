/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import XCTest
import MaterialMotion

class MotionRuntimeTests: XCTestCase {

  func testReactiveObjectCacheSupportsSubclassing() {
    let shapeLayer = CAShapeLayer()
    let castedLayer: CALayer = shapeLayer

    let runtime = MotionRuntime(containerView: UIView())

    let reactiveShapeLayer = runtime.get(shapeLayer)
    let reactiveCastedLayer = runtime.get(castedLayer)

    XCTAssertTrue(reactiveShapeLayer === reactiveCastedLayer)
  }

  func testInteractionsReturnsEmptyArrayWithoutAnyAddedInteractions() {
    let runtime = MotionRuntime(containerView: UIView())

    let results = runtime.interactions(for: UIView(), ofType: Draggable.self)
    XCTAssertEqual(results.count, 0)
  }

  func testOnlyReturnsInteractionsOfTheCorrectType() {
    let runtime = MotionRuntime(containerView: UIView())

    let view = UIView()
    runtime.add(Draggable(), to: view)
    runtime.add(Rotatable(), to: view)

    let results = runtime.interactions(for: view, ofType: Draggable.self)
    XCTAssertEqual(results.count, 1)
  }

  public class MockTween<T>: Togglable, Stateful {
    let _state = createProperty("Tween._state", withInitialValue: MotionState.atRest)
    public let enabled = createProperty("Tween.enabled", withInitialValue: true)
    public func setState(state: MotionState) {
      _state.value = state
    }
    public var state: MotionObservable<MotionState> {
      return _state.asStream()
    }
  }

  func testRuntimeStart() {
    let promise = expectation(description: "start interaction B when interaction A is at state")

    let view = UIView()
    let runtime = MotionRuntime(containerView: view)
    let tweenA = MockTween<CGFloat>()
    tweenA.setState(state: .active)

    let tweenB = MockTween<CGFloat>()
    tweenB.setState(state: .atRest)
    tweenB.enabled.value = false
    runtime.start(tweenB, when: tweenA, is: .atRest)

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
      tweenA.setState(state: MotionState.atRest)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(15)) {
      XCTAssertEqual(tweenB.enabled.value, true)
      promise.fulfill()
    }

    waitForExpectations(timeout: 100, handler: nil)
  }
}
