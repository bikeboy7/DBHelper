//
//  SqlBuilder.h
//  DBService
//
//  Created by boy on 2017/9/5.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SQLObject;


@interface SqlInfo : NSObject

@property (strong, nonatomic) NSString *sqlStr; //sql语句

@property (strong, nonatomic) NSDictionary *arguments; //sql参数

@end


@interface SqlBuilder : NSObject

+ (SqlInfo *)createTablesWithClass:(Class)cls;


/**
 插入新数据
 
 @param obj 要插入的对象，可以是SQLObject 或 字典
 @return SqlInfo
 */
+ (SqlInfo *)insert:(Class)cls obj:(id)obj;



/**
 删除数据
 
 @param cls 删除的类
 @param arguments 参数类型有1.@{}；2：@[@{}]；3.@"", 为nil则删除所有
 1. @{@"name": obj, @"age": obj2} 表示 "name = 'obj' AND age = 'obj2'";
 2. @[@{@"name": obj, @"age": obj2}, @{@"name": obj3, @"age": obj4}] 表示 ("name = 'obj' AND age = 'obj2') OR (name = 'obj3' AND age = 'obj4')";
 3. 直接输入条件语句：@"name = 'obj' OR name = 'obj2'"
 @return SqlInfo
 */
+ (SqlInfo *)deleteWithClass:(Class)cls arguments:(id)arguments;



/**
 删除数据

 @param obj 删除的对象
 @return SqlInfo
 */
+ (SqlInfo *)deleteWithObj:(SQLObject *)obj;



/**
 更新数据
 
 @param obj 要更新的对象，可以是SQLObject 或 字典
 @return SqlInfo
 */
+ (SqlInfo *)update:(Class)cls obj:(id)obj;


/**
 更新数据（条件更新）
 
 @param cls 需要更新的类
 @param content 更新的内容 @{@"name": @"newName"}
 @param arguments 刷选条件，@""/@{}/@[@{}]， 为nil则删除所有
 @return SqlInfo
 */
+ (SqlInfo *)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments;



/**
 查询语句
 
 @param cls 查询的类型
 @param arguments 查询条件@""/@{}/@[@{}], 为nil则查询所有
 @return SqlInfo
 */
+ (SqlInfo *)query:(Class)cls arguments:(id)arguments;

@end





