//
//  ProductsViewController.swift
//  Easy Digital Downloads
//
//  Created by Sunny Ratilal on 01/09/2016.
//  Copyright © 2016 Easy Digital Downloads. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let sharedDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

class ProductsViewController: SiteTableViewController, ManagedObjectContextSettable, UIViewControllerPreviewingDelegate {

    var managedObjectContext: NSManagedObjectContext!
    
    var site: Site?
    var products: [JSON]?
    
    var hasMoreProducts: Bool = true {
        didSet {
            if (!hasMoreProducts) {
                activityIndicatorView.stopAnimating()
            } else {
                activityIndicatorView.startAnimating()
            }
        }
    }
    
    var operation = false
    
    var lastDownloadedPage =  1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.leftBarButtonItem = true
        
        let searchNavigationItemImage = UIImage(named: "NavigationBar-Search")
        let searchNavigationItemButton = HighlightButton(type: .custom)
        searchNavigationItemButton.tintColor = .white
        searchNavigationItemButton.setImage(searchNavigationItemImage, for: UIControlState())
        searchNavigationItemButton.addTarget(self, action: #selector(ProductsViewController.searchButtonPressed), for: .touchUpInside)
        searchNavigationItemButton.sizeToFit()
        
        let searchNavigationBarButton = UIBarButtonItem(customView: searchNavigationItemButton)
        searchNavigationBarButton.accessibilityIdentifier = "Search"
        
        navigationItem.rightBarButtonItems = [searchNavigationBarButton]
        
        registerForPreviewing(with: self, sourceView: view)
        
        setupInfiniteScrollView()
        setupTableView()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    init(site: Site) {
        super.init(style: .plain)
        
        self.site = site
        self.managedObjectContext = AppDelegate.sharedInstance.managedObjectContext
        
        title = NSLocalizedString("Products", comment: "Products title")
        
        let titleLabel = ViewControllerTitleLabel()
        titleLabel.setTitle(NSLocalizedString("Products", comment: "Products title"))
        navigationItem.titleView = titleLabel
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        networkOperations()
    }
    
    func searchButtonPressed() {
        navigationController?.pushViewController(SearchViewController(site: Site.activeSite()), animated: true)
    }
    
    func networkOperations() {
        products = [JSON]()
        
        operation = true
        
        EDDAPIWrapper.sharedInstance.requestProducts([:], success: { (json) in
            if let items = json["products"].array {
                self.products = items
                self.updateLastDownloadedPage()
            }
            
            self.persistProducts()
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
            self.operation = false
        }) { (error) in
            NSLog(error.localizedDescription)
        }
    }
    
    fileprivate func updateLastDownloadedPage() {
        self.lastDownloadedPage = self.lastDownloadedPage + 1;
    }
    
    // MARK: Scroll View Delegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let actualPosition: CGFloat = scrollView.contentOffset.y
        let contentHeight: CGFloat = scrollView.contentSize.height - tableView.frame.size.height;
        
        if actualPosition >= contentHeight && !operation {
            self.requestNextPage()
        }
    }
    
    // MARK: Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let product = dataSource.selectedObject else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        navigationController?.pushViewController(ProductsDetailViewController(product: product), animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Private
    
    fileprivate func requestNextPage() {
        if (operation) {
            return
        }
        
        self.operation = true

        EDDAPIWrapper.sharedInstance.requestProducts([ "page": lastDownloadedPage as AnyObject ], success: { (json) in
            if let items = json["products"].array {
                if items.count == 10 {
                    self.hasMoreProducts = true
                } else {
                    self.hasMoreProducts = false
                }
                for item in items {
                    self.products?.append(item)
                }
                self.updateLastDownloadedPage()
            }

            self.persistProducts()
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
            self.operation = false
        }) { (error) in
            print(error.localizedDescription)
        }

    }
    
    fileprivate func persistProducts() {
        guard let products_ = products else {
            return
        }
        
        for item in products_.unique {
            if Product.productForId(item["info"]["id"].int64Value) !== nil {
                continue
            }
            
            var stats: Data?
            if Site.hasPermissionToViewReports() {
                stats = NSKeyedArchiver.archivedData(withRootObject: item["stats"].asData())
            } else {
                stats = nil
            }
            
            var files: Data?
            var notes: String?
            if Site.hasPermissionToViewSensitiveData() {
                if item["files"].arrayObject != nil {
                    files = NSKeyedArchiver.archivedData(withRootObject: item["files"].arrayObject!).asData()
                } else {
                    files = nil
                }
                
                notes = item["notes"].stringValue
            } else {
                files = nil
                notes = nil
            }
     
            var hasVariablePricing = false
            if item["pricing"].dictionary?.count > 1 {
                hasVariablePricing = true
            }
            
            let pricing = NSKeyedArchiver.archivedData(withRootObject: item["pricing"].dictionaryObject!)
            
            let licensing = item["licensing"].dictionaryObject as [String: AnyObject]?
            
            Product.insertIntoContext(managedObjectContext, content: item["info"]["content"].stringValue, createdDate: sharedDateFormatter.date(from: item["info"]["create_date"].stringValue)!, files: files, hasVariablePricing: hasVariablePricing as NSNumber, link: item["info"]["link"].stringValue, modifiedDate: sharedDateFormatter.date(from: item["info"]["modified_date"].stringValue)!, notes: notes, pid: item["info"]["id"].int64Value, pricing: pricing, stats: stats, status: item["info"]["status"].stringValue, thumbnail: item["info"]["thumbnail"].string, title: item["info"]["title"].stringValue, licensing: licensing)
        }
        
        do {
            try managedObjectContext.save()
            managedObjectContext.processPendingChanges()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    fileprivate typealias DataProvider = FetchedResultsDataProvider<ProductsViewController>
    fileprivate var dataSource: TableViewDataSource<ProductsViewController, DataProvider, ProductsTableViewCell>!
    
    fileprivate func setupTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(ProductsTableViewCell.self, forCellReuseIdentifier: "ProductCell")
        tableView.register(ProductsTableViewCell.self, forCellReuseIdentifier: "ProductThumbnailCell")
        setupDataSource()
    }
    
    fileprivate func setupDataSource() {
        let request = Product.defaultFetchRequest()
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        let dataProvider = FetchedResultsDataProvider(fetchedResultsController: frc, delegate: self)
        dataSource = TableViewDataSource(tableView: tableView, dataProvider: dataProvider, delegate: self)
    }
    
    // MARK: 3D Touch
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            guard let product = dataSource.objectAtIndexPath(indexPath) else {
                return nil
            }
            return ProductsDetailViewController(product: product)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }

}

extension ProductsViewController: DataProviderDelegate {
    
    func dataProviderDidUpdate(_ updates: [DataProviderUpdate<Product>]?) {
        dataSource.processUpdates(updates)
    }
    
}

extension ProductsViewController: DataSourceDelegate {
    
    func cellIdentifierForObject(_ object: Product) -> String {
        if object.thumbnail?.characters.count > 5 && object.thumbnail != "false" {
            return "ProductThumbnailCell"
        } else {
            return "ProductCell"
        }
    }
    
}


extension ProductsViewController : InfiniteScrollingTableView {
    
    func setupInfiniteScrollView() {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 44))
        footerView.backgroundColor = .clear
        
        activityIndicatorView.startAnimating()
        
        footerView.addSubview(activityIndicatorView)
        
        tableView.tableFooterView = footerView
    }
    
}
