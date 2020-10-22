import UIKit

extension UIColor {
    static var brandColor: UIColor {
        UIColor(displayP3Red: 133 / 255, green: 90 / 255, blue: 255 / 255, alpha: 1)
    }

    static var background: UIColor {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return .black
            } else {
                return .systemGray6
            }
        }
    }

    static var foreground: UIColor {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return .systemGray6
            } else {
                return .white
            }
        }
    }

    static var secondaryBackground: UIColor {
        UIColor(red: 133 / 255, green: 90 / 255, blue: 255 / 255, alpha: 1)
    }

    // @todo there are probably better names for the following 2
    static var buttonBackground: UIColor {
        UIColor(red: 170 / 255, green: 139 / 255, blue: 255 / 255, alpha: 1)
    }

    static var lightButtonBackground: UIColor {
        UIColor(red: 193 / 255, green: 171 / 255, blue: 255 / 255, alpha: 1.0)
    }

    static var twitter: UIColor {
        UIColor(red: 29 / 255, green: 161 / 255, blue: 242 / 255, alpha: 1.0)
    }

    static var elementBackground: UIColor {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return .black
            } else {
                return .white
            }
        }
    }

    static var exitButtonBackground: UIColor {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return UIColor.systemRed.withAlphaComponent(0.2)
            } else {
                return UIColor.systemRed.withAlphaComponent(0.1)
            }
        }
    }
}
