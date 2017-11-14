//
//  SQLObject.h
//  DBService
//
//  Created by boy on 2017/9/5.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLObject : NSObject

/**
 子类重写此方法才有会主键，默认是没有主键
 
 @return 主键
 */
+ (NSString *)primaryKey;


/**
 获取类名
 
 @return @"SQLObject"
 */
+ (NSString *)className;

/**
 获取该类的所有属性与之对应类型
 
 @return 该类的所有属性与之对应类型
 */
+ (NSDictionary *)properties;

@end
