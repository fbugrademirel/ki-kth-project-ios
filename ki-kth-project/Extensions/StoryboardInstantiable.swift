//
//  StoryboardInstantiable.swift
//  KarmaCase
//
//  Created by Charlie Tuna on 2020-01-18.
//

import UIKit

public protocol StoryboardInstantiable {
    static var storyboardName: String { get }
}

public extension StoryboardInstantiable where Self: UIViewController {
    static func instantiate() -> Self {
        let storyboard = UIStoryboard(name: self.storyboardName, bundle: Bundle(for: self))
        guard let viewController = storyboard.instantiateInitialViewController() else {
            fatalError("Expected storyboard \(storyboardName) to have an initial view controller")
        }
        guard let typedViewController = viewController as? Self else {
            fatalError("Expected storyboard \(storyboardName) with an initial view controller of class \(self) – found \(type(of: viewController))")
        }
        return typedViewController
    }
}
