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

import Foundation
import IndefiniteObservable

/**
 A Spring can pull a value from an initial position to a destination using a physical simulation.

 This class defines the expected shape of a Spring for use in creating a Spring source.
 */
public class Spring<T: Zeroable>: ViewInteraction, PropertyInteraction {

  /** Creates a spring with the provided properties and an initial velocity of zero. */
  public convenience init<O: MotionObservableConvertible>(to destination: O, threshold: CGFloat, system: @escaping SpringToStream<T>) where O.T == T {
    let initialVelocity = createProperty(withInitialValue: T.zero() as! T)
    self.init(to: destination, initialVelocity: initialVelocity, threshold: threshold, system: system)
  }

  /** Creates a spring with the provided properties and an initial velocity. */
  public init<O1: MotionObservableConvertible, O2: MotionObservableConvertible>(to destination: O1,
              initialVelocity: O2,
              threshold: CGFloat,
              system: @escaping SpringToStream<T>) where O1.T == T, O2.T == T {
    self.destination = destination.asStream()
    self.initialVelocity = initialVelocity.asStream()
    self.system = system

    self.threshold = createProperty(withInitialValue: threshold)
  }

  /** The destination value of the spring represented as a property. */
  public let destination: MotionObservable<T>

  /** The initial velocity of the spring represented as a stream. */
  public private(set) var initialVelocity: MotionObservable<T>

  /** The tension configuration of the spring represented as a property. */
  public let tension = createProperty(withInitialValue: defaultSpringTension)

  /** The friction configuration of the spring represented as a property. */
  public let friction = createProperty(withInitialValue: defaultSpringFriction)

  /** The mass configuration of the spring represented as a property. */
  public let mass = createProperty(withInitialValue: defaultSpringMass)

  /**
   The suggested duration of the spring represented as a property.

   This property may not be supported by all animation systems.

   A value of 0 means this property will be ignored.
   */
  public let suggestedDuration = createProperty(withInitialValue: TimeInterval(0))

  /** The value used when determining completion of the spring simulation. */
  public let threshold: ReactiveProperty<CGFloat>

  public var system: SpringToStream<T>

  /** The stream of values generated by this spring. */
  public func stream<O: MotionObservableConvertible>(withInitialValue initialValue: O) -> MotionObservable<T> where O.T == T {
    return compositions.reduce(system(self, initialValue.asStream())) { $1($0) }
  }

  public func compose(stream: @escaping (MotionObservable<T>) -> MotionObservable<T>) {
    compositions.append(stream)
  }
  private var compositions: [(MotionObservable<T>) -> MotionObservable<T>] = []

  public func add(to reactiveView: ReactiveUIView, withRuntime runtime: MotionRuntime) {
    if let castedSelf = self as? Spring<CGPoint> {
      let position = reactiveView.reactiveLayer.position
      runtime.add(castedSelf.stream(withInitialValue: position), to: position)
    }
  }

  public func add(to property: ReactiveProperty<T>, withRuntime runtime: MotionRuntime) {
    runtime.add(stream(withInitialValue: property), to: property)
  }

  public func add(initialVelocityStream stream: MotionObservable<T>) {
    initialVelocity = initialVelocity.merge(with: stream)
  }
}

/** The default tension configuration. */
public let defaultSpringTension: CGFloat = 342

/** The default friction configuration. */
public let defaultSpringFriction: CGFloat = 30

/** The default mass configuration. */
public let defaultSpringMass: CGFloat = 1
