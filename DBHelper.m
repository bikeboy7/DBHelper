//
//  DBHelper.m
//  DBService
//
//  Created by boy on 2017/9/13.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import "DBHelper.h"
#import "FMDB.h"
#import "SQLObject.h"
#import "SqlBuilder.h"

static DBHelper *_helper = nil;

@implementation DBHelper {    
    
    FMDatabaseQueue *_dbQueue;
    
    int test;

}


#pragma mark - init
+ (instancetype)share {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (_helper == nil) {
            _helper = [[super allocWithZone:NULL] initWithDBName:@"mydb"];
        }
    });
    
    return _helper;

}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self share];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [DBHelper share];
}

- (instancetype)initWithDBName:(NSString *)name
{
    self = [super init];
    if (self) {
        
        NSString *dbPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"sql"];
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
        
        NSLog(@"---dbPath--- %@", dbPath);

    }
    return self;
}

#pragma mark - private

// 同步
- (BOOL)transcationWithItems:(NSArray<id> *)items infoBlock:(SqlInfo *(^)(id item))infoBlock {
    
    __block BOOL isSuccess = YES;
    
    [_dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSError *error = nil;
        
        for (id item in items) {
            
            SqlInfo *info = infoBlock(item);
            
            isSuccess = [db executeUpdate:info.sqlStr withParameterDictionary:info.arguments];
            
            if (!isSuccess) {
               
                *rollback = YES;
                error = db.lastError;
                break;
            }
        }
        
    }];
    
    return isSuccess;
}

// 异步
- (void)transcationWithItems:(NSArray<id> *)items infoBlock:(SqlInfo *(^)(id item))infoBlock success:(DBHelperSuccess)success fail:(DBHelperFail)fail {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [_dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            BOOL isSuccess = YES;
            NSError *error = nil;
            
            for (id item in items) {
                
                SqlInfo *info = infoBlock(item);
                
                isSuccess = [db executeUpdate:info.sqlStr withParameterDictionary:info.arguments];
                
                if (!isSuccess) {
                    break;
                }
            }
            
            if (isSuccess) {
                
                if (success) {
                    success();
                }
                
            }else {
                
                *rollback = YES;
                error = db.lastError;
                
                if (fail) {
                    fail(error);
                }
            }
            
        }];

    });
    
}

#pragma mark - public

/**
 创建表

 @param classes 对应的类
 @param fail fail description
 @param success success description
 */
- (void)createTable:(NSArray<Class> *)classes fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    [self transcationWithItems:classes infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder createTablesWithClass:item];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)createTable:(NSArray<Class> *)classes {
    return [self transcationWithItems:classes infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder createTablesWithClass:item];
    }];
}

/**
 插入新数据

 @param objs 要插入的对象，可以是@[SQLObject] 或 @[@{}]
 @param cls 对应的类, 如果objs不是@[SQLObject]，cls不可为nil
 @param fail fail description
 @param success success description
 */
- (void)insertWithObjs:(NSArray<id> *)objs class:(Class)cls fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    if (cls == nil && objs.count > 0) {
        cls = [objs[0] class];
    }
   
    [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder insert:cls obj:item];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)insertWithObjs:(NSArray<id> *)objs class:(Class)cls {
    
    if (cls == nil && objs.count > 0) {
        cls = [objs[0] class];
    }
    
    return [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder insert:cls obj:item];
    }];
    
}


/**
 删除

 @param objs 需要删除的对象数组
 @param fail fail description
 @param success success description
 */
- (void)deleteWithObjs:(NSArray<SQLObject *> *)objs fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder deleteWithObj:item];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)deleteWithObjs:(NSArray<SQLObject *> *)objs {
    
    return [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder deleteWithObj:item];
    }];
    
}

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
- (void)deleteWithClass:(Class)cls arguments:(id)arguments fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    [self transcationWithItems:@[cls] infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder deleteWithClass:item arguments:arguments];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)deleteWithClass:(Class)cls arguments:(id)arguments {
    
    return [self transcationWithItems:@[cls] infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder deleteWithClass:item arguments:arguments];
    }];
    
}



/**
 更新

 @param cls 需要更新的类
 @param objs 要更新的对象，可以是SQLObject 或 字典
 @param fail fail description
 @param success success description
 */
- (void)upDateWithCls:(Class)cls objs:(NSArray<SQLObject *> *)objs fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder update:cls obj:item];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)upDateWithCls:(Class)cls objs:(NSArray<SQLObject *> *)objs {
    
    return [self transcationWithItems:objs infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder update:cls obj:item];
    }];
    
}


/**
 更新数据（条件更新）
 
 @param cls 需要更新的类
 @param content 更新的内容 @{@"name": @"newName"}
 @param arguments 刷选条件，@""/@{}/@[@{}]， 为nil则删除所有
 @param fail fail description
 @param success success description
 */
- (void)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments fail:(DBHelperFail)fail success:(DBHelperSuccess)success {
    
    [self transcationWithItems:@[cls] infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder update:cls content:content arguments:arguments];
    } success:success fail:fail];
    
}

// 同步
- (BOOL)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments {
    
    return [self transcationWithItems:@[cls] infoBlock:^SqlInfo *(id item) {
        return [SqlBuilder update:cls content:content arguments:arguments];
    }];
    
}

/**
 查询

 @param cls 需要查询的类
 @param arguments 查询条件，@""/@{}/@[@{}]， 为nil则查询所有
 @return return @[SQLObject]
 */
- (NSArray<SQLObject *> *)queryWithCls:(Class)cls arguments:(id)arguments {
    SqlInfo *info = [SqlBuilder query:cls arguments:arguments];
    
    NSMutableArray<SQLObject *> *retArr = [NSMutableArray array];

    
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
       
        
        FMResultSet *set = [db executeQuery:info.sqlStr];
    
        
        while ([set next]) {
            
            SQLObject *obj = [[cls alloc] init];
            [obj setValuesForKeysWithDictionary:set.resultDictionary];
            
            [retArr addObject:obj];
            
        }
        
    }];

    return retArr;
}
// 异步
- (void)queryWithCls:(Class)cls arguments:(id)arguments result:(void(^)(NSArray<SQLObject *> * objs))result {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *arr = [self queryWithCls:cls arguments:arguments];
       
        result(arr);
        
    });
    
}





@end
