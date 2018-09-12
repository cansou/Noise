//
//  NFHandshakeState.m
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFHandshakeState.h"
#import "NFProtocol+Package.h"
#import "NFUtil.h"
#import <noise/protocol.h>
#import "NFKeyPair.h"
#import "NFKey+Package.h"

@implementation NFHandshakeState {
    NoiseHandshakeState *_handshakeState;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    self = nil;
    return nil;
}
#pragma clang diagnostic pop

- (instancetype)initWithProtocol:(NFProtocol *)protocol role:(NFSessionRole)role
{
    self = [super init];
    if (self) {
        _protocol = protocol;
        _role = role;
        noise_handshakestate_new_by_id(&_handshakeState, protocol.protocolId, NFSessionRoleToNoiseRole(role));
    }
    return self;
}

- (void)dealloc
{
    if (_handshakeState) {
        noise_handshakestate_free(_handshakeState);
        _handshakeState = NULL;
    }
}

- (void)setPrologue:(NSData *)prologue
{
    noise_handshakestate_set_prologue(_handshakeState, [prologue bytes], [prologue length]);
}

- (void)setPreSharedKey:(NFKey *)preSharedKey
{
    NSData *km = [preSharedKey keyMaterial];
    if ([preSharedKey keyRole] != NFKeyRoleSymmetric || [km length] != 32) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"%@ is not symmetric or is not 32 bytes in length" userInfo:nil] raise];
        return;
    }
    noise_handshakestate_set_pre_shared_key(_handshakeState, [km bytes], [km length]);
}


- (BOOL)preSharedKeyMissing
{
    return noise_handshakestate_needs_pre_shared_key(_handshakeState);
}

- (NFKeyPair *)localKeyPair
{
    if (!noise_handshakestate_has_local_keypair(_handshakeState)) {
        return nil;
    }
    
    NoiseDHState *dh = noise_handshakestate_get_local_keypair_dh(_handshakeState);
    size_t priv_key_len = noise_dhstate_get_private_key_length(dh);
    size_t pub_key_len = noise_dhstate_get_public_key_length(dh);
    uint8_t *priv_key = (uint8_t *)malloc(priv_key_len);
    uint8_t *pub_key = (uint8_t *)malloc(pub_key_len);
    
    BOOL ok = YES;
    int err = noise_dhstate_get_keypair(dh, priv_key, priv_key_len, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    NFKeyPair *keyPair = nil;
    if (ok) {
        NFKey *publicKey = [NFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                             role:NFKeyRolePublic
                                             algo:self.protocol.keyAlgo];
        NFKey *privateKey = [NFKey keyWithMaterial:[NSData dataWithBytes:priv_key length:priv_key_len]
                                              role:NFKeyRolePrivate
                                              algo:self.protocol.keyAlgo];
        keyPair = [[NFKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    }
    
    noise_free(priv_key, priv_key_len);
    noise_free(pub_key, pub_key_len);
    
    return keyPair;
}

- (void)setLocalKeyPair:(NFKeyPair *)localKeyPair
{
    if ([localKeyPair.privateKey.keyAlgo compare:self.protocol.keyAlgo] != NSOrderedSame) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"KeyAlgo differs: %@ != %@", localKeyPair.privateKey.keyAlgo, self.protocol.keyAlgo]
                               userInfo:nil] raise];
        return;
    }
    NoiseDHState *dh = noise_handshakestate_get_local_keypair_dh(_handshakeState);
    NSData *privKeyMaterial = [localKeyPair.privateKey keyMaterial];
    NSData *pubKeyMaterial = [localKeyPair.publicKey keyMaterial];
    noise_dhstate_set_keypair(dh, [privKeyMaterial bytes], [privKeyMaterial length], [pubKeyMaterial bytes], [pubKeyMaterial length]);
}

- (BOOL)localKeyPairMissing
{
    return noise_handshakestate_needs_local_keypair(_handshakeState);
}

- (NFKey *)remotePublicKey
{
    if (!noise_handshakestate_has_remote_public_key(_handshakeState)) {
        return nil;
    }
    NoiseDHState *dh = noise_handshakestate_get_remote_public_key_dh(_handshakeState);
    size_t pub_key_len = noise_dhstate_get_public_key_length(dh);
    uint8_t *pub_key = (uint8_t *)malloc(pub_key_len);
    
    BOOL ok = YES;
    int err = noise_dhstate_get_public_key(dh, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    NFKey *key = nil;
    if (ok) {
        key = [NFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                role:NFKeyRolePublic
                                algo:self.protocol.keyAlgo];
    }
    
    noise_free(pub_key, pub_key_len);
    return key;
}

- (void)setRemotePublicKey:(NFKey *)remotePublicKey
{
    if ([remotePublicKey.keyAlgo compare:self.protocol.keyAlgo] != NSOrderedSame) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"KeyAlgo differs: %@ != %@", remotePublicKey.keyAlgo, self.protocol.keyAlgo]
                               userInfo:nil] raise];
        return;
    }
    if (remotePublicKey.keyRole != NFKeyRolePublic) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"Expecing a public key got: %lu", (unsigned long)remotePublicKey.keyRole]
                               userInfo:nil] raise];
        return;
    }
    
    NoiseDHState *dh = noise_handshakestate_get_remote_public_key_dh(_handshakeState);
    NSData *pubKeyMaterial = [remotePublicKey keyMaterial];
    noise_dhstate_set_public_key(dh, [pubKeyMaterial bytes], [pubKeyMaterial length]);
}

- (BOOL)remotePublicKeyMissing
{
    return noise_handshakestate_needs_remote_public_key(_handshakeState);
}

@end
