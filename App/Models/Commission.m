//
//  Commission.m
//  EDDSalesTracker
//
//  Created by Matthew Strickland on 2/24/14.
//  Copyright (c) 2014 Easy Digital Downloads. All rights reserved.
//

#import "Commission.h"

@implementation Commission

@synthesize amount = _amount;
@synthesize rate = _rate;
@synthesize currency = _currency;
@synthesize item = _item;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
	
    _amount = [[attributes valueForKeyPath:@"amount"] floatValue];
    _rate = [[attributes valueForKeyPath:@"rate"] floatValue];
    _currency = [attributes valueForKeyPath:@"currency"];
    _item = [attributes valueForKeyPath:@"item"];
	
	return self;
}

+ (void)globalCommissionsWithBlock:(void (^)(NSArray *unpaid, NSArray *paid, float unpaidTotal, float paidTotal, NSError *error))block {
	NSMutableDictionary *params = [EDDAPIClient defaultParams];
	[params setValue:@"commissions" forKey:@"edd-api"];
	
	[[EDDAPIClient sharedClient] getPath:@"" parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
		NSArray *unpaidFromResponse = [JSON valueForKeyPath:@"unpaid"];
		NSArray *paidFromResponse = [JSON valueForKeyPath:@"paid"];
		NSDictionary *totalsFromResponse = [JSON valueForKeyPath:@"totals"];
		
        NSMutableArray *mutableUnpaid = [NSMutableArray arrayWithCapacity:[unpaidFromResponse count]];
        NSMutableArray *mutablePaid = [NSMutableArray arrayWithCapacity:[paidFromResponse count]];
		
        for (NSDictionary *attributes in unpaidFromResponse) {
            Commission *commission = [[Commission alloc] initWithAttributes:attributes];
            [mutableUnpaid addObject:commission];
        }
		
        for (NSDictionary *attributes in paidFromResponse) {
            Commission *commission = [[Commission alloc] initWithAttributes:attributes];
            [mutablePaid addObject:commission];
        }
		
		float unpaidTotal = [[totalsFromResponse valueForKeyPath:@"unpaid"] floatValue];
		float paidTotal = [[totalsFromResponse valueForKeyPath:@"paid"] floatValue];
		      
        if (block) {
            block([NSArray arrayWithArray:mutableUnpaid], [NSArray arrayWithArray:mutablePaid], unpaidTotal, paidTotal, nil);
        }
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) {
			block([NSArray array], [NSArray array], 0.0f, 0.0f, error);
		}
	}];
}

@end
