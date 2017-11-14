//
//  Person.h
//  DBService
//
//  Created by boy on 2017/9/6.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import "SQLObject.h"

@interface Person : SQLObject

@property (assign, nonatomic) int pid;

@property (assign, nonatomic) float height;

@property (assign, nonatomic) double weight;

@property (copy, nonatomic) NSString *name;

@property (retain, nonatomic) NSData *data;

@property (retain, nonatomic) NSString *nickName;

@end
