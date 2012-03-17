
//  GBSettings.m
//  GBCli
//
//  Created by Tomaž Kragelj on 3/13/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

#import "GBSettings.h"

@interface GBSettings ()
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, strong) GBSettings *parent;
@property (nonatomic, strong) NSMutableSet *arrayKeys;
@property (nonatomic, strong) NSMutableDictionary *storage;
@end

#pragma mark -

@implementation GBSettings {
	NSMutableArray *_arguments;
}

@synthesize name = _name;
@synthesize parent = _parent;
@synthesize arrayKeys = _arrayKeys;
@synthesize arguments = _arguments;
@synthesize storage = _storage;

#pragma mark - Initialization & disposal

+ (id)settingsWithName:(NSString *)name parent:(GBSettings *)parent {
	return [[self alloc] initWithName:name parent:parent];
}

- (id)initWithName:(NSString *)name parent:(GBSettings *)parent {
	self = [super init];
	if (self) {
		self.name = name;
		self.parent = parent;
		self.arrayKeys = [NSMutableSet set];
		self.storage = [NSMutableDictionary dictionary];
	}
	return self;
}

#pragma mark - Settings serialization support

- (BOOL)loadSettingsFromPlist:(NSString *)path error:(NSError **)error {
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path]) return YES;
	
	// Load data into dictionary.
	NSData* data = [NSData dataWithContentsOfFile:path options:0 error:error];
	if (!data) return NO;
	NSDictionary *values = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:error];
	if (!values) return NO;
	
	// Copy all values to ourself. Remove - or -- prefix which can optionally be used in the file!
	[self.storage removeAllObjects];
	[values enumerateKeysAndObjectsUsingBlock:^(NSString *key, id result, BOOL *stop) {
		while ([key hasPrefix:@"-"]) key = [key substringFromIndex:1];
		[self setObject:result forKey:key];
	}];
	return YES;
}

- (BOOL)saveSettingsToPlist:(NSString *)path error:(NSError **)error {
	// Note that we only save settings from current level!
	NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.storage format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
	if (!data) return NO;
	return [data writeToFile:path options:NSDataWritingAtomic error:error];
}

#pragma mark - Optional registration helpers

- (void)registerArrayForKey:(NSString *)key {
	[self.arrayKeys addObject:key];
}

#pragma mark - Values handling

- (id)objectForKey:(NSString *)key {
	if ([self isKeyArray:key]) {
		NSMutableArray *allValues = [NSMutableArray array];
		GBSettings *settings = self;
		while (settings) {
			NSArray *currentLevelValues = [settings.storage objectForKey:key];
			[allValues addObjectsFromArray:currentLevelValues];
			settings = settings.parent;
		}
		return allValues;
	}
	GBSettings *level = [self settingsForKey:key];
	return [level.storage objectForKey:key];
}
- (void)setObject:(id)value forKey:(NSString *)key {
	if ([self isKeyArray:key] && ![key isKindOfClass:[NSArray class]]) {
		NSMutableArray *array = [self.storage objectForKey:key];
		if (![array isKindOfClass:[NSMutableArray class]]) {
			id existing = array;
			array = [NSMutableArray array];
			if (existing) [array addObject:existing];
			[self.storage setObject:array forKey:key];
		}
		if ([value isKindOfClass:[NSArray class]])
			[array addObjectsFromArray:value];
		else
			[array addObject:value];
		return;
	}
	return [self.storage setObject:value forKey:key];
}

- (BOOL)boolForKey:(NSString *)key {
	NSNumber *number = [self objectForKey:key];
	return [number boolValue];
}
- (void)setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *number = [NSNumber numberWithBool:value];
	[self setObject:number forKey:key];
}

- (NSInteger)integerForKey:(NSString *)key {
	NSNumber *number = [self objectForKey:key];
	return [number integerValue];
}
- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
	NSNumber *number = [NSNumber numberWithInteger:value];
	[self setObject:number forKey:key];
}

- (NSUInteger)unsignedIntegerForKey:(NSString *)key {
	NSNumber *number = [self objectForKey:key];
	return [number unsignedIntegerValue];
}
- (void)setUnsignedInteger:(NSUInteger)value forKey:(NSString *)key {
	NSNumber *number = [NSNumber numberWithUnsignedInteger:value];
	[self setObject:number forKey:key];
}

- (CGFloat)floatForKey:(NSString *)key {
	NSNumber *number = [self objectForKey:key];
	return [number doubleValue];
}
- (void)setFloat:(CGFloat)value forKey:(NSString *)key {
	NSNumber *number = [NSNumber numberWithDouble:value];
	[self setObject:number forKey:key];
}

#pragma mark - Arguments handling

- (void)addArgument:(NSString *)argument {
	if (!_arguments) _arguments = [[NSMutableArray alloc] init];
	[_arguments addObject:argument];
}

#pragma mark - Introspection

- (void)enumerateSettings:(void(^)(GBSettings *settings, BOOL *stop))handler {
	GBSettings *settings = self;
	BOOL stop = NO;
	while (settings) {
		handler(settings, &stop);
		if (stop) break;
		settings = settings.parent;
	}
}

- (GBSettings *)settingsForKey:(NSString *)key {
	GBSettings *level = self;
	while (level) {
		if ([level.storage objectForKey:key]) break;
		level = level.parent;
	}
	return level;
}

- (BOOL)isKeyPresentAtThisLevel:(NSString *)key {
	if ([self.storage objectForKey:key]) return YES;
	return NO;
}

- (BOOL)isKeyArray:(NSString *)key {
	return [self.arrayKeys containsObject:key];
}

@end