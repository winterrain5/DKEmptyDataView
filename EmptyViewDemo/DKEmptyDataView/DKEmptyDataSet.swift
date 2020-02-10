//
//  EmptyDataDelegate.swift
//  EmptViewDemo
//
//  Created by Derrick on 2020/1/16.
//  Copyright © 2020 winter. All rights reserved.
//

import Foundation
import UIKit


private var kEmptyDataView =             "emptyDataView"
private var kConfigureEmptyDataView =    "configureEmptyDataView"

extension UIView {
    
    private var configureEmptyDataView: ((DKEmptyDataView) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &kConfigureEmptyDataView) as? (DKEmptyDataView) -> Void
        }
        set {
            objc_setAssociatedObject(self, &kConfigureEmptyDataView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UIScrollView.swizzleReloadData
            if self is UITableView {
                UIScrollView.swizzleEndUpdates
            }
        }
    }
    
    
    public var isEmptyDataVisible: Bool {
        if let view = objc_getAssociatedObject(self, &kEmptyDataView) as? DKEmptyDataView {
            return !view.isHidden
        }
        return false
    }
    
    //MARK: - privateProperty
    public func emptyDataView(_ closure: @escaping (DKEmptyDataView) -> Void) {
        configureEmptyDataView = closure
    }
    
    private var emptyDataView: DKEmptyDataView? {
        get {
            if let view = objc_getAssociatedObject(self, &kEmptyDataView) as? DKEmptyDataView {
                return view
            } else {
                let view = DKEmptyDataView.init(frame: frame)
                view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                view.isHidden = true
                objc_setAssociatedObject(self, &kEmptyDataView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return view
            }
        }
        set {
            objc_setAssociatedObject(self, &kEmptyDataView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    
    private var itemsCount: Int {
       var items = 0
       
       // UITableView support
       if let tableView = self as? UITableView {
           var sections = 1
           
           if let dataSource = tableView.dataSource {
               if dataSource.responds(to: #selector(UITableViewDataSource.numberOfSections(in:))) {
                   sections = dataSource.numberOfSections!(in: tableView)
               }
               if dataSource.responds(to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:))) {
                   for i in 0 ..< sections {
                       items += dataSource.tableView(tableView, numberOfRowsInSection: i)
                   }
               }
           }
       } else if let collectionView = self as? UICollectionView {
           var sections = 1
           
           if let dataSource = collectionView.dataSource {
               if dataSource.responds(to: #selector(UICollectionViewDataSource.numberOfSections(in:))) {
                   sections = dataSource.numberOfSections!(in: collectionView)
               }
               if dataSource.responds(to: #selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:))) {
                   for i in 0 ..< sections {
                       items += dataSource.collectionView(collectionView, numberOfItemsInSection: i)
                   }
               }
           }
       }
       
       return items
    }
    
    //MARK: - Reload APIs (Public)
    public func reloadEmptyDataView() {
        guard (configureEmptyDataView != nil) else {
            return
        }
        
        if let view = emptyDataView {
            
            if view.superview == nil {
                // Send the view all the way to the back, in case a header and/or footer is present, as well as for sectionHeaders or any other content
                if (self is UITableView) || (self is UICollectionView) {
                    insertSubview(view, at: 0)
                } else {
                    addSubview(view)
                }
            }
            
            // Removing view resetting the view and its constraints it very important to guarantee a good state
            // If a non-nil custom view is available, let's configure it instead
            view.prepareForReuse()
            
            
            if let config = configureEmptyDataView {
                config(view)
            }
            
            view.setupConstraints()
            view.layoutIfNeeded()
        }else if isEmptyDataVisible {
            invalidate()
        }
    }
    
    private func invalidate() {
        
        if let view = emptyDataView {
            view.prepareForReuse()
            view.isHidden = true
        }
        
    }
    
    //MARK: - Method Swizzling
    @objc private func tableViewSwizzledReloadData() {
        tableViewSwizzledReloadData()
        reloadEmptyDataView()
    }
    
    @objc private func tableViewSwizzledEndUpdates() {
        tableViewSwizzledEndUpdates()
        reloadEmptyDataView()
    }
    
    @objc private func collectionViewSwizzledReloadData() {
        collectionViewSwizzledReloadData()
        reloadEmptyDataView()
    }
    
    private class func swizzleMethod(for aClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(aClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(aClass, swizzledSelector)
        
        let didAddMethod = class_addMethod(aClass, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        
        if didAddMethod {
            class_replaceMethod(aClass, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    private static let swizzleReloadData: () = {
        let tableViewOriginalSelector = #selector(UITableView.reloadData)
        let tableViewSwizzledSelector = #selector(UIScrollView.tableViewSwizzledReloadData)
        
        swizzleMethod(for: UITableView.self, originalSelector: tableViewOriginalSelector, swizzledSelector: tableViewSwizzledSelector)
        
        let collectionViewOriginalSelector = #selector(UICollectionView.reloadData)
        let collectionViewSwizzledSelector = #selector(UIScrollView.collectionViewSwizzledReloadData)
        
        swizzleMethod(for: UICollectionView.self, originalSelector: collectionViewOriginalSelector, swizzledSelector: collectionViewSwizzledSelector)
    }()
    
    private static let swizzleEndUpdates: () = {
        let originalSelector = #selector(UITableView.endUpdates)
        let swizzledSelector = #selector(UIScrollView.tableViewSwizzledEndUpdates)
        
        swizzleMethod(for: UITableView.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }()
    
}



