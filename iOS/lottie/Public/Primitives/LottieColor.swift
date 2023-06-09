// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - ColorFormatDenominator

public enum ColorFormatDenominator: Hashable {
  case One
  case OneHundred
  case TwoFiftyFive

  var value: Double {
    switch self {
    case .One:
      return 1.0
    case .OneHundred:
      return 100.0
    case .TwoFiftyFive:
      return 255.0
    }
  }
}

// MARK: - LottieColor

public struct LottieColor: Hashable {
  public var r: Double
  public var g: Double
  public var b: Double
  public var a: Double

  public init(r: Double, g: Double, b: Double, a: Double, denominator: ColorFormatDenominator = .One) {
    self.r = r / denominator.value
    self.g = g / denominator.value
    self.b = b / denominator.value
    self.a = a / denominator.value
  }
}
