// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation
import QuartzCore

extension FillRule {
  var cgFillRule: CGPathFillRule {
    switch self {
    case .evenOdd:
      return .evenOdd
    default:
      return .winding
    }
  }

  var caFillRule: CAShapeLayerFillRule {
    switch self {
    case .evenOdd:
      return CAShapeLayerFillRule.evenOdd
    default:
      return CAShapeLayerFillRule.nonZero
    }
  }
}

// MARK: - FillRenderer

/// A rendered for a Path Fill
final class FillRenderer: PassThroughOutputNode, Renderable {
  var shouldRenderInContext = false

  var color: CGColor? {
    didSet {
      hasUpdate = true
    }
  }

  var opacity: CGFloat = 0 {
    didSet {
      hasUpdate = true
    }
  }

  var fillRule: FillRule = .none {
    didSet {
      hasUpdate = true
    }
  }

  func render(_: CGContext) {
    // do nothing
  }

  func setupSublayers(layer _: CAShapeLayer) {
    // do nothing
  }

  func updateShapeLayer(layer: CAShapeLayer) {
    layer.fillColor = color
    layer.opacity = Float(opacity)
    layer.fillRule = fillRule.caFillRule
    hasUpdate = false
  }
}
