//
//  ViewController.swift
//  EmptyViewDemo
//
//  Created by Derrick on 2020/1/16.
//  Copyright © 2020 winter. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private lazy var titleAttributedString:NSAttributedString = {
        let text: String = "Haven‘t finish the homework yet"
        let font: UIFont = UIFont.systemFont(ofSize: 16)
        let textColor: UIColor = UIColor.darkGray
        var attributes:[NSAttributedString.Key:Any] = [:]
        attributes[.font] = font
        attributes[.foregroundColor] = textColor
        return NSAttributedString(string: text, attributes: attributes)
    }()
    private var shouldDisplay:Bool = false
    private var scrollView:UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        scrollView = UIScrollView()
//        scrollView.frame = self.view.bounds
//        scrollView.contentSize = self.view.frame.size
//        view.addSubview(scrollView)

        view.emptyDataView { [weak self] (view) in
            guard let `self` = self else {return}
            view.titleLabelString(self.titleAttributedString)
                .shouldDisplay(self.shouldDisplay)
            .image(UIImage(named: "placeholder_image"))
            .shouldFadeIn(true)
            .isScrollAllowed(self.shouldDisplay)
        }
        
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: switchView)
        
        let leftButton = UIButton()
        leftButton.setTitle("next", for: .normal)
        leftButton.setTitleColor(.black, for: .normal)
        leftButton.addTarget(self, action: #selector(leftButtonDidClick), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
    }

    @objc func switchValueDidChange(_ sender: UISwitch) {
        self.shouldDisplay = sender.isOn
        self.view.reloadEmptyDataView()
    }
    
    @objc func leftButtonDidClick() {
        let vc = TableViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

