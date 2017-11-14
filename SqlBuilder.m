//
//  SqlBuilder.m
//  DBService
//
//  Created by boy on 2017/9/5.
//  Copyright © 2017年 pjy. All rights reserved.
//

#import "SqlBuilder.h"
#import "SQLObject.h"
#import <objc/runtime.h>
//#import "ViewController.h"



@implementation SqlInfo

- (instancetype)initWithSqlStr:(NSString *)sqlStr arguments:(NSDictionary *)arguments {
    self = [super init];
    
    if (self) {
        _sqlStr = sqlStr;
        _arguments = arguments;
    }
    
    return self;
}


@end




@implementation SqlBuilder

// 存储所有子类的属性字典
//static NSMutableDictionary *_properties;

/**
 创建表
 
 @param cls class
 @return SqlInfo
 */
+ (SqlInfo *)createTablesWithClass:(Class)cls{
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", [cls className]];
    
    
    NSString *primaryKey = [cls primaryKey];
    NSDictionary *properties = [cls properties];
    
    for (NSString *key in properties) {
        
        NSString *att = properties[key];
        
        if (primaryKey != nil && [primaryKey isEqualToString:key]) {
            [sql appendFormat:@"%@ INTEGER PRIMARY KEY,", primaryKey];
            continue;
        }
        
        if ([att containsString:@"NSNumber"]) {
            [sql appendFormat:@"%@ INTEGER,", key];
        }else if ([att containsString:@"NSData"]) {
            [sql appendFormat:@"%@ BLOB,", key];
        }else if ([att containsString:@"NSString"]) {
            [sql appendFormat:@"%@ TEXT,", key];
        }else if ([att containsString:@"TB"]) {//bool
            [sql appendFormat:@"%@ INTEGER,", key];
        }else if ([att containsString:@"Tq"]) {//int
            [sql appendFormat:@"%@ INTEGER,", key];
        }else if ([att containsString:@"Tf"]) {//float
            [sql appendFormat:@"%@ REAL,", key];
        }else if ([att containsString:@"Td"]) {//double
            [sql appendFormat:@"%@ REAL,", key];
        }else {//不支持的则忽略不创建
            continue;
        }
    }
    [sql replaceCharactersInRange:NSMakeRange(sql.length - 1, 1) withString:@")"];
    
    ;
    
    
    return [[SqlInfo alloc] initWithSqlStr:sql arguments:nil];
    
}



/**
 插入新数据

 @param obj 要插入的对象，可以是SQLObject 或 字典
 @return SqlInfo
 */
+ (SqlInfo *)insert:(Class)cls obj:(id)obj {

    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", [cls className]];
    
    NSMutableString *valueStr = [[NSMutableString alloc] initWithString:@"values("];
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    NSDictionary *properties = [cls properties];
    
    int i = 0;
    for (NSString *key in properties) {
        
        id value = [obj valueForKey:key];
        
        if (!value) { // 如果为nil，需要转为NSNull
            value = [NSNull null];

        }
        arguments[key] = value;
        
        [sql appendFormat:@"%@", key];
        
        [valueStr appendFormat:@":%@", key];
        
        
        if (i < properties.count - 1) {
            [sql appendString:@","];
            [valueStr appendString:@","];
        }else {
            [sql appendString:@")"];
            [valueStr appendString:@")"];
        }
        
        i ++;
        
    }
    
    [sql appendString:valueStr];
    
    
    
    

    return [[SqlInfo alloc] initWithSqlStr:sql arguments:arguments];

}


/**
 删除数据

 @param cls 删除的类
 @param arguments 参数类型有1.@{}；2：@[@{}]；3.@"", 为nil则删除所有
 1. @{@"name": obj, @"age": obj2} 表示 "name = 'obj' AND age = 'obj2'";
 2. @[@{@"name": obj, @"age": obj2}, @{@"name": obj3, @"age": obj4}] 表示 ("name = 'obj' AND age = 'obj2') OR (name = 'obj3' AND age = 'obj4')";
 3. 直接输入条件语句：@"name = 'obj' OR name = 'obj2'"
 @return SqlInfo
 */
+ (SqlInfo *)deleteWithClass:(Class)cls arguments:(id)arguments {
    
    NSMutableString *sqlStr = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@", [cls className]];
    
    if (arguments != nil) {
        NSString *whereStr = [self _transformWhereStrWithArguments:arguments];
        [sqlStr appendFormat:@" WHERE %@", whereStr];
    }
    
    SqlInfo *info = [[SqlInfo alloc] initWithSqlStr:sqlStr arguments:nil];
    
    NSLog(@"%@", info.sqlStr);
    
    return info;

}


/**
 删除数据
 
 @param obj 删除的对象
 @return SqlInfo
 */
+ (SqlInfo *)deleteWithObj:(SQLObject *)obj {

    NSString *primaryKey = [[obj class] primaryKey];
    
    if (primaryKey != nil) {
        NSString *str = [NSString stringWithFormat:@"DELETE FROME %@ WHERE %@='%@'", [[obj class] className] ,primaryKey, [obj valueForKey:primaryKey]];
        NSLog(@"%@", str);
        return [[SqlInfo alloc] initWithSqlStr:str arguments:nil];
    }
    
    return nil;
}



/**
 更新数据
 
 @param obj 要更新的对象，可以是SQLObject 或 字典
 @return SqlInfo
 */
+ (SqlInfo *)update:(Class)cls obj:(id)obj {
    
    NSMutableString *sqlStr = [[NSMutableString alloc] initWithFormat:@"UPADTE %@ SET", [cls className]];
    
    NSString *primaryKey = [cls primaryKey];
    
    if (primaryKey == nil ) {
        return nil;
    }
    
    if ([obj valueForKey:primaryKey] == nil) {
        return nil;
    }
    
    [sqlStr appendString:[self _transformWithObj:obj]];
    
    [sqlStr appendFormat:@" WHERE %@=%@", primaryKey, [obj valueForKey:primaryKey]];
    
    NSLog(@"%@", sqlStr);
    
    return [[SqlInfo alloc] initWithSqlStr:sqlStr arguments:nil];

}


/**
 更新数据（条件更新）

 @param cls 需要更新的类
 @param content 更新的内容 @{@"name": @"newName"}
 @param arguments 刷选条件，@""/@{}/@[@{}]， 为nil则删除所有
 @return SqlInfo
 */
+ (SqlInfo *)update:(Class)cls content:(NSDictionary *)content arguments:(id)arguments {
    
    NSMutableString *sqlStr = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", [cls className]];
    
    
    [sqlStr appendString:[self _transformWithObj:content]];
    
    if (arguments != nil) {
        NSString *whereStr = [self _transformWhereStrWithArguments:arguments];
        [sqlStr appendFormat:@" WHERE %@", whereStr];
    }
    
    SqlInfo *info = [[SqlInfo alloc] initWithSqlStr:sqlStr arguments:nil];
    
    NSLog(@"%@", info.sqlStr);
    
    return info;
    
}


/**
 查询语句

 @param cls 查询的类型
 @param arguments 查询条件@""/@{}/@[@{}], 为nil则查询所有
 @return SqlInfo
 */
+ (SqlInfo *)query:(Class)cls arguments:(id)arguments {

    NSMutableString *sqlStr = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@", [cls className]];
    
    if (arguments != nil) {
        NSString *whereStr = [self _transformWhereStrWithArguments:arguments];
        [sqlStr appendFormat:@" WHERE %@", whereStr];
    }
    
    NSLog(@"%@", sqlStr);
    
    return [[SqlInfo alloc] initWithSqlStr:sqlStr arguments:nil];
    
}



#pragma mark - private

/**
 由输入的各种形式的条件转换为条件语句

 @param arguments @{} / @{@[]} / @""
 @return 条件语句
 */
+ (NSString *)_transformWhereStrWithArguments:(id)arguments{
    
    if (arguments == nil) {
        return nil;
    }
    
    
    NSMutableString *whereStr = [[NSMutableString alloc] init];
    
    if ([[arguments class] isSubclassOfClass:[NSDictionary class]]) {
        
        [whereStr appendString:[self _transformWithDic:(NSDictionary *)arguments]];
        
    }else if ([[arguments class] isSubclassOfClass:[NSArray class]]) {
        
        [whereStr appendString:[self _transformWithArray:(NSArray *)arguments]];
        
    }else if ([arguments isKindOfClass:[NSString class]]) {
        [whereStr appendString:(NSString *)arguments];
    }
    
    return whereStr;

}


/**
 字典转换为条件语句

 @param dic 字典
 @return 条件语句
 */
+ (NSString *)_transformWithDic:(NSDictionary *)dic {
    
    NSMutableString *retStr = [[NSMutableString alloc] init];
   
    int i = 0;
    
    for (NSString *key in dic) {
        [retStr appendFormat:@"%@='%@'", key, dic[key]];
        
        if (i < [dic count] - 1) {
            [retStr appendString:@" AND "];
        }
        
        i ++;
    }
    
    return retStr;
}


/**
 数组转换为条件语句

 @param arr 数组 @[@{}]
 @return 条件语句
 */
+ (NSString *)_transformWithArray:(NSArray<NSDictionary *> *)arr {
    
    NSMutableString *retStr = [[NSMutableString alloc] init];
    
    for (int i = 0; i < arr.count; i ++) {
        
        if ([arr[i] isKindOfClass:[NSDictionary class]]) {
           
            NSDictionary * dic = (NSDictionary *)arr[i];
            NSString *str = [self _transformWithDic:dic];
            [retStr appendFormat:@"(%@)",str];
            
        }else {
            NSLog(@"输入的参数有误，数组条件里面装的应该是字典");
            return nil;
        }
        
        if (i < arr.count - 1) {
            [retStr appendString:@" OR "];
        }
        
    }
    
    return retStr;
}


/**
 SQLObject或字典转换为更新的内容语句

 @param obj SQLObject或字典
 @return 内容语句
 */
+ (NSString *)_transformWithObj:(id)obj {
    
    NSMutableString *sql = [[NSMutableString alloc] init];

    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if ([[obj class] isSubclassOfClass:[SQLObject class]]) {
        dic = [[NSMutableDictionary alloc] initWithDictionary:[[obj class] properties]];
    }else {
        dic = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)obj];
    }
    
    int i = 0;
    for (NSString *key in dic) {
        
        
        id value = [obj valueForKey:key];
        
        if (value == nil) {
            continue;
        }
        
        [sql appendFormat:@"%@='%@'", key, value];
        
        if (i < dic.count - 1) {
            [sql appendString:@","];
        }
        
        i ++;
    }
    
    return sql;
}




@end



