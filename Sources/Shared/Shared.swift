//
//  Shared.swift
//  Shared
//
//  Shared framework module entry point
//  Re-exports os.log so consumers don't need to import it separately
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@_exported import os.log

/// Shared framework - Common models, utilities, and logging infrastructure
/// This file serves as the module entry point and re-exports os.log
/// so that Logger extensions are available when importing Shared
