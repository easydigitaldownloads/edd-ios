//
//  EDDSitesViewController.h
//  EDDSalesTracker
//
//  Created by Matthew Strickland on 5/28/13.
//  Copyright (c) 2013 Easy Digital Downloads. All rights reserved.
//

#import "EDDBaseTableViewController.h"

@interface EDDSitesViewController : EDDBaseTableViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIBarButtonItem *editButton;

@end
