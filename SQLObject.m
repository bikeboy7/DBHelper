//
//  SQLObject.m
//  DBService
//
//  Created by boy on 2017/9/5.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import "SQLObject.h"
#import <objc/runtime.h>

@implementation SQLObject


// 存储所有子类的属性字典
static NSMutableDictionary *_properties;

/**
 子类重写此方法才有会主键，默认是没有主键

 @return 主键
 */
+ (NSString *)primaryKey {
    return nil;
}


/**
 获取类名
 
 @return @"SQLObject"
 */
+ (NSString *)className {
    
    return @(object_getClassName(self));
    
}


/**
 获取该类的所有属性与之对应类型

 @return 该类的所有属性与之对应类型
 */
+ (NSDictionary *)properties {
    if (_properties == nil) {
        _properties = [[NSMutableDictionary alloc] init];
    }
    
    
    if ([_properties[[self className]] isKindOfClass:[NSDictionary class]]) {
        return _properties[[self className]];
    }
    
    unsigned int count = 0;
    
    objc_property_t * propertyList = class_copyPropertyList(self, &count);
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (int i = 0; i < count; i ++) {
        objc_property_t property = propertyList[i];
        NSString *name = @(property_getName(property));
        NSString *attributes = @(property_getAttributes(property));
        dic[name] = attributes;
    }

    free(propertyList);
    
    _properties[[self className]] = dic;
    
    return dic;
    
}


@end
