import SwiftUI

/// The "Ember" data palette: warm greys carry the data, one orange marks the thing that matters, and red
/// is kept for a real warning. Selected by `ChartStyle.ember`; every value is read through the
/// `StrandPalette` accessors, so screens pick it up with no call-site changes.
enum Ember {
    static let orange      = Color(light: "#A94C0C", dark: "#F19340")
    static let orangeDeep  = Color(light: "#8A3D08", dark: "#B4561A")
    static let orangeLight = Color(light: "#C8641E", dark: "#F5A866")
    static let red         = Color(light: "#C0392B", dark: "#E5483B")

    static let grey1 = Color(light: "#D6D3CC", dark: "#3A3936")
    static let grey2 = Color(light: "#AEAAA2", dark: "#57554F")
    static let grey3 = Color(light: "#86827A", dark: "#8A8882")
    static let grey4 = Color(light: "#5E5A53", dark: "#A3A19B")
    static let grey5 = Color(light: "#3A3732", dark: "#C9C7C1")
    static let grey6 = Color(light: "#17150F", dark: "#E8E6E1")

    // Recovery: dim to bright orange, so a low day reads quiet and a good day reads lit.
    static let recoveryStops: [Gradient.Stop] = [
        .init(color: grey2, location: 0.00), .init(color: orangeDeep, location: 0.45),
        .init(color: orange, location: 0.78), .init(color: orangeLight, location: 1.00),
    ]
    // Strain: grey to near white, effort as brightness rather than a second hue.
    static let strainStops: [Gradient.Stop] = [
        .init(color: grey2, location: 0.00), .init(color: grey3, location: 0.33),
        .init(color: grey4, location: 0.66), .init(color: grey6, location: 1.00),
    ]

    static let sleepAwake = grey4
    static let sleepLight = grey2
    static let sleepDeep  = orangeDeep
    static let sleepREM   = orange

    static let zone1 = grey2
    static let zone2 = grey3
    static let zone3 = grey4
    static let zone4 = orangeDeep
    static let zone5 = orange

    static let statusPositive = grey6
    static let statusWarning  = orange
    static let statusCritical = red

    static let metricCyan   = grey4
    static let metricPurple = grey5
    static let metricAmber  = orange
    static let metricRose   = red

    static let chargeColor  = orange
    static let chargeDeep   = orangeDeep
    static let chargeBright = orangeLight
    static let chargeGlow   = orange

    static let effortColor  = grey6
    static let effortDeep   = grey3
    static let effortBright = grey6
    static let effortGlow   = grey4

    static let restColor  = grey4
    static let restDeep   = grey2
    static let restBright = grey5
    static let restGlow   = grey3

    static let stressColor  = orange
    static let stressDeep   = grey2
    static let stressBright = red
    static let stressGlow   = orange
}
