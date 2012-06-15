//
//  MethodGroupInfo.h
//  appledoc
//
//  Created by Tomaž Kragelj on 4/13/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

/** Holds the data for a method group.
 
 This is helper object that provides information about the name of the group and an array of all methods or properties of the group. Methods listed in methodGroupMethods are instances of either PropertyInfo or MethodInfo.
 */
@interface MethodGroupInfo : NSObject

+ (id)MethodGroupInfoWithName:(NSString *)name;

@property (nonatomic, copy) NSString *nameOfMethodGroup;
@property (nonatomic, strong) NSMutableArray *methodGroupMethods;

@end

#pragma mark - 

/** Provides convenience methods for finding MethodGroupInfo in an array by its name.
 */
@interface NSArray (MethodGroupInfoExtensions)

- (BOOL)gb_containsMethodGroupInfoWithName:(NSString *)name;
- (NSUInteger)gb_indexOfMethodGroupInfoWithName:(NSString *)name;

@end