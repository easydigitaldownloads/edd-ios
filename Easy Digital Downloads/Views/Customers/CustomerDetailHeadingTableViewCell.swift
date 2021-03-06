//
//  CustomerDetailHeadingTableViewCell.swift
//  Easy Digital Downloads
//
//  Created by Sunny Ratilal on 21/09/2016.
//  Copyright © 2016 Easy Digital Downloads. All rights reserved.
//

import UIKit

class CustomerDetailHeadingTableViewCell: UITableViewCell {

    lazy var stackView : UIStackView! = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 3.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        return stack
    }()
    
    lazy var containerView: UIView! = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate let headingLabel = UILabel(frame: CGRect.zero)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        backgroundColor = .EDDGreyColor()
        
        headingLabel.textColor = .EDDBlackColor()
        headingLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightLight)
        headingLabel.textAlignment = .left
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func layout() {
        stackView.addArrangedSubview(headingLabel)
        
        containerView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.alignment = .top
        
        contentView.addSubview(containerView)
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(headingLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1.0))
        constraints.append(headingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10))
        constraints.append(containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10))
        constraints.append(containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10))
        constraints.append(containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10))
        constraints.append(containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10))
        constraints.append(stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10))
        constraints.append(stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10))
        constraints.append(stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10))
        constraints.append(stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func configure(_ heading: String) {
        headingLabel.text = heading.uppercased()
        
        layout()
    }

}
