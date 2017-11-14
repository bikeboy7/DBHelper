//
//  DBHelper.h
//  DBService
//
//  Created by boy on 2017/9/13.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SQLObject;

typedef void(^DBHelperSuccess)();
typedef void(^DBHelperFail)(NSError *error);

@interface DBHelper : NSObject

+ (instancetype)share;
    

/**
 创建表
 
 @param classes 对应的类
 @param fail fail description
 @param success success description
 */
- (void)createTable:(NSArray<Class> *)classes fail:(DBHelperFail)fail success:(DBHelperSuccess)success;

// 同步
- (BOOL)createTable:(NSArray<Class> *)classes;

/**
 插入新数据
 
 @param objs 要插入的对象，可以是@[SQLObject] 或 @[@{}]
 @param cls 对应的类
 @param fail fail description
 @param success success description
 */
- (void)insertWithObjs:(NSArray<id> *)objs class:(Class)cls fail:(DBHelperFail)fail success:(DBHelperSuccess)success;

// 同步
- (BOOL)insertWithObjs:(NSArray<id> *)objs class:(Class)cls;


/**
 删除
 
 @param objs 需要删除的对象数组
 @param fail fail description
 @param success success description
 */
- (void)deleteWithObjs:(NSArray<SQLObject *> *)objs fail:(DBHelperFail)fail success:(DBHelperSuccess)success;


// 同步
- (BOOL)deleteWithObjs:(NSArray<SQLObject *> *)objs;


/**
 删除
 
 @param cls 删除的类
 @param arguments 参数类型有1.@{}；2：@[@{}]；3.@"", 为nil则删除所有
 1. @{@"name": obj, @"age": obj2} 表示 "name = 'obj' AND age = 'obj2'";
 2. @[@{@"name": obj, @"age": obj2}, @{@"name": obj3, @"age": obj4}] 表示 ("name = 'obj' AND age = 'obj2') OR (name = 'obj3' AND age = 'obj4')";
 3. 直接输入条件语句：@"name = 'obj' OR name = 'obj2'"
 @param fail fail description
 @param success success description
 */
- (void)deleteWithClass:(Class)cls arguments:(id)arguments fail:(DBHelperFail)fail success:(DBHelperSuccess)success;


// 同步
- (BOOL)deleteWithClass:(Class)cls arguments:(id)arguments;



/**
 更新
 
 @param cls 需要更新的类
 @param objs 要更新的对象，可以是SQLObject 或 字典
 @param fail fail description
 @param success success description
 */
- (void)upDateWithCls:(Class)cls objs:(NSArray<SQLObject *> *)objs fail:(DBHelperFail)fail success:(DBHelperSuccess)success;


// 同步
- (BOOL)upDateWithCls:(Class)cls objs:(NSArray<SQLObject *> *)objs;


/**
 更新数据（条件更新）
 
 @param cls 需要更新的类
 @param content 更新的内容 @{@"name": @"newName"}
 @param arguments 刷选条件，@""/@{}/@[@{}]， 为nil则删除所有
 @param fail fail description
 @param success success description
 */
- (void)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments fail:(DBHelperFail)fail success:(DBHelperSuccess)success;


// 同步
- (BOOL)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments;



/**
 查询
 
 @param cls 需要查询的类
 @param arguments 查询条件，@""/@{}/@[@{}]， 为nil则查询所有
 @return return @[SQLObject]
 */
- (NSArray<SQLObject *> *)queryWithCls:(Class)cls arguments:(id)arguments;

// 异步
- (void)queryWithCls:(Class)cls arguments:(id)arguments result:(void(^)(NSArray<SQLObject *> * objs))result;


@end
