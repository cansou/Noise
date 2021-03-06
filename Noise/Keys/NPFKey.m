//
//  NPFKey.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFKey.h"

NPFKeyAlgo const NPFKeyAlgoCurve25519   = @"25519";
NPFKeyAlgo const NPFKeyAlgoCurve448     = @"448";

static NSString *const kKeyMaterialCodingKey = @"km";
static NSString *const kKeyAlgoCodingKey = @"ka";
static NSString *const kKeyRoleCodingKey = @"kr";

@implementation NPFKey

+ (instancetype)keyWithMaterial:(NSData *)material role:(NPFKeyRole)role algo:(NPFKeyAlgo)algo
{
    return [[self alloc] initWithKeyMaterial:material role:role algo:algo];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithKeyMaterial:(NSData *)material role:(NPFKeyRole)role algo:(NPFKeyAlgo)algo
{
    self = [super init];
    if (self) {
        _keyMaterial = [material copy];
        _keyRole = role;
        _keyAlgo = algo;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _keyMaterial = [aDecoder decodeObjectOfClass:[NSData class] forKey:kKeyMaterialCodingKey];
        _keyAlgo = [aDecoder decodeObjectOfClass:[NSString class] forKey:kKeyAlgoCodingKey];
        _keyRole = [aDecoder decodeIntegerForKey:kKeyRoleCodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.keyMaterial forKey:kKeyMaterialCodingKey];
    [aCoder encodeObject:self.keyAlgo forKey:kKeyAlgoCodingKey];
    [aCoder encodeInteger:self.keyRole forKey:kKeyRoleCodingKey];
}


@end
