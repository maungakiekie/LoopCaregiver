//
//  Image+Resources.swift
//
//
//  Created by Bill Gestrich on 8/4/24.
//

import Foundation
import SwiftUI

public extension Image {
    static var workout: Image {
        return Image("workout", bundle: Bundle.module)
    }
    
    static var workoutSelected: Image {
        return Image("workout-selected", bundle: Bundle.module)
    }
}
