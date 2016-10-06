//
//  AKLocationManagerTimeInterval.swift
//
//  Created by Artem Krachulov
//  Copyright (c) 2016 Artem Krachulov. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//
// v. 0.1
//

import Foundation

struct AKLocationManagerTimeInterval {
  /// Updating location will be no earlier than minimum time interval
  var min: NSTimeInterval
  /// Updating location will be no earlier than maximum time interval
  var max: NSTimeInterval
}
