// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - Renderer

final class GradientStrokeRenderer: PassThroughOutputNode, Renderable {
  // MARK: Lifecycle

  override init(parent: NodeOutput?) {
    strokeRender = StrokeRenderer(parent: nil)
    gradientRender = LegacyGradientFillRenderer(parent: nil)
    strokeRender.color = .rgb(1, 1, 1)
    super.init(parent: parent)
  }

  // MARK: Internal

  var shouldRenderInContext = true

  let strokeRender: StrokeRenderer
  let gradientRender: LegacyGradientFillRenderer

  override func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    let updates = super.hasOutputUpdates(forFrame)
    return updates || strokeRender.hasUpdate || gradientRender.hasUpdate
  }

  func updateShapeLayer(layer _: CAShapeLayer) {
    /// Not Applicable
  }

  func setupSublayers(layer _: CAShapeLayer) {
    /// Not Applicable
  }

  func render(_ inContext: CGContext) {
    guard inContext.path != nil, inContext.path!.isEmpty == false else {
      return
    }

    strokeRender.hasUpdate = false
    hasUpdate = false
    gradientRender.hasUpdate = false

    strokeRender.setupForStroke(inContext)

    inContext.replacePathWithStrokedPath()

    /// Now draw the gradient.
    gradientRender.render(inContext)
  }

  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect {
    strokeRender.renderBoundsFor(boundingBox)
  }
}
