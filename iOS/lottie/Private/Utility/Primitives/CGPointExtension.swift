// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics

extension CGPoint: AnyInitializable {
  // MARK: Lifecycle

  init(value: Any) throws {
    if let dictionary = value as? [String: CGFloat] {
      let x: CGFloat = try dictionary.value(for: CodingKeys.x)
      let y: CGFloat = try dictionary.value(for: CodingKeys.y)
      self.init(x: x, y: y)
    } else if
      let array = value as? [CGFloat],
      array.count > 1 {
      self.init(x: array[0], y: array[1])
    } else {
      throw InitializableError.invalidInput
    }
  }

  // MARK: Private

  private enum CodingKeys: String {
    case x
    case y
  }
}
