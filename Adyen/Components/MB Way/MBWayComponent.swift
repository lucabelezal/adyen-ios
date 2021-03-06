//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// A component that provides a form for MB Way payments.
public final class MBWayComponent: PaymentComponent, PresentableComponent, Localizable {
    /// :nodoc:
    public var paymentMethod: PaymentMethod { mbWayPaymentMethod }
    
    /// :nodoc:
    public weak var delegate: PaymentComponentDelegate?
    
    /// :nodoc:
    public lazy var viewController: UIViewController = SecuredViewController(child: formViewController, style: style)
    
    /// :nodoc:
    public var localizationParameters: LocalizationParameters?
    
    /// Describes the component's UI style.
    public let style: FormComponentStyle
    
    /// Indicates if form will show a large header title. True - show title; False - assign title to a view controller's title.
    /// Defaults to true.
    @available(*, deprecated, message: """
     The `showsLargeTitle` property is deprecated.
     For Component title, please, introduce your own lable implementation.
     You can access componet's title from `viewController.title`.
    """)
    public var showsLargeTitle: Bool {
        get {
            guard !_isDropIn else { return false }
            return _showsLargeTitle
        }

        set {
            _showsLargeTitle = newValue
        }
    }

    /// :nodoc:
    internal var _showsLargeTitle = true // swiftlint:disable:this identifier_name
    
    /// :nodoc:
    public let requiresModalPresentation: Bool = true
    
    /// :nodoc:
    private let mbWayPaymentMethod: MBWayPaymentMethod
    
    /// Initializes the MB Way component.
    ///
    /// - Parameter paymentMethod: The MB Way payment method.
    /// - Parameter style: The Component's UI style.
    public init(paymentMethod: MBWayPaymentMethod, style: FormComponentStyle = FormComponentStyle()) {
        self.mbWayPaymentMethod = paymentMethod
        self.style = style
    }
    
    /// :nodoc:
    public func stopLoading(withSuccess success: Bool, completion: (() -> Void)?) {
        button.showsActivityIndicator = false
        formViewController.view.isUserInteractionEnabled = true
        completion?()
    }
    
    private lazy var formViewController: FormViewController = {
        Analytics.sendEvent(component: paymentMethod.type, flavor: _isDropIn ? .dropin : .components, environment: environment)
        
        let formViewController = FormViewController(style: style)
        formViewController.localizationParameters = localizationParameters
        
        if _showsLargeTitle, !_isDropIn {
            let headerItem = FormHeaderItem(style: style.header)
            headerItem.title = paymentMethod.name
            headerItem.identifier = ViewIdentifierBuilder.build(scopeInstance: self, postfix: paymentMethod.name)
            formViewController.append(headerItem)
        }

        formViewController.title = paymentMethod.name
        formViewController.append(phoneNumberItem)
        formViewController.append(button.withPadding(padding: .init(top: 8, left: 0, bottom: -16, right: 0)))
        
        return formViewController
    }()
    
    /// The full phone number item.
    internal lazy var phoneNumberItem: FormTextInputItem = {
        let item = FormTextInputItem(style: style.textField)
        item.title = ADYLocalizedString("adyen.phoneNumber.title", localizationParameters)
        item.placeholder = ADYLocalizedString("adyen.phoneNumber.placeholder", localizationParameters)
        item.validator = PhoneNumberValidator()
        item.formatter = PhoneNumberFormatter()
        item.validationFailureMessage = ADYLocalizedString("adyen.phoneNumber.invalid", localizationParameters)
        item.keyboardType = .phonePad
        item.identifier = ViewIdentifierBuilder.build(scopeInstance: self, postfix: "phoneNumberItem")
        return item
    }()
    
    /// The footer item.
    internal lazy var button: FormButtonItem = {
        let item = FormButtonItem(style: style.mainButtonItem)
        item.identifier = ViewIdentifierBuilder.build(scopeInstance: self, postfix: "payButtonItem")
        item.title = ADYLocalizedString("adyen.continueTo", localizationParameters, mbWayPaymentMethod.name)
        item.buttonSelectionHandler = { [weak self] in
            self?.didSelectSubmitButton()
        }
        return item
    }()
    
    private func didSelectSubmitButton() {
        guard formViewController.validate() else { return }
        
        let details = MBWayDetails(paymentMethod: paymentMethod,
                                   telephoneNumber: phoneNumberItem.value)
        button.showsActivityIndicator = true
        formViewController.view.isUserInteractionEnabled = false
        
        submit(data: PaymentComponentData(paymentMethodDetails: details))
    }
}
