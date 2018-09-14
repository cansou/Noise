//
//  NFSession.h
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NFSessionRole) {
    NFSessionRoleInitiator,
    NFSessionRoleResponder
} NS_SWIFT_NAME(NoiseSessionRole);

typedef NS_ENUM(NSUInteger, NFSessionState) {
    NFSessionStateInitializing,
    NFSessionStateHandshaking,
    NFSessionStateEstablished,
    NFSessionStateClosed,
    NFSessionStateError
} NS_SWIFT_NAME(NoiseSessionState);

@class NFProtocol, NFHandshakeState, NFKeyPair, NFKey;
@protocol NFSessionDelegate, NFSessionSetup;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseSession)
@interface NFSession : NSObject

/**
 Convenience initializer.

 @param protocolName the name of the protocol to use in this session
 @param role the session role for this peer (initiator or responder)
 @return a newly initialized session object or nil of protocolName is not supported
 */
- (nullable instancetype)initWithProtocolName:(NSString *)protocolName role:(NFSessionRole)role;

/**
 Designated initializer for a new session protocol

 @param protocol the protocol to use for this session
 @param role the session role for this peer (initiator or responder)
 @return a newly initialized session object
 */
- (instancetype)initWithProtocol:(NFProtocol *)protocol role:(NFSessionRole)role NS_DESIGNATED_INITIALIZER;

/** The protocol for this session. */
@property (strong, readonly) NFProtocol *protocol;

/** The role for this session. */
@property (readonly) NFSessionRole role;

/** The current state of this session. This is KVO-compatible. */
@property (readonly) NFSessionState state;


/** An optional delegate for this session */
@property (nullable, weak) id<NFSessionDelegate> delegate;

/** The queue where delegate methods are called. Defaults to the main queue. */
@property (strong) NSOperationQueue *delegateQueue;


/**
 You should call this method before starting a session to setup all the required data for the
 chosen protocol such as static or pre-shared keys, and other data like the prologue.
 This method will throw if called when session state is not NFSessionStateInitializing
 
 @param block the single block parameter of NFSessionSetup is you interface to setup the session
 @return YES if all required data has been provided, NO if there's data missing
 @throw if session state is not NFSessionStateInitializing
 */
- (BOOL)setup:(void(^)(id<NFSessionSetup>))block;

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



NS_SWIFT_NAME(NoiseSessionSetup)
@protocol NFSessionSetup <NSObject>

/**
 Prologue to use before starting the handshake.
 This data is never sent to the server. It's only hashed in the handshake phase.
 If the peer doesn't use the same prologue the handshake will fail.
 
 @param prologue the prologue to use. Must not be nil.
 */
- (void)setPrologue:(NSData *)prologue;

/** A pre-shared symmetric key that must be 32 bytes in length.
 @param key a symmetric key of 32 bytes
 @throw if key is not symmetric and doesn't have 32 bytes in length
 */
- (void)setPreSharedKey:(NFKey *)key;
/** @return YES if this protocol requires a pre-shared key but it hasn't been set yet */
@property (nonatomic, readonly) BOOL preSharedKeyMissing;


/** The static DH key for this peer */
@property (nullable, nonatomic, strong) NFKeyPair *localKeyPair;
/** @return YES if this protocol requires a static key pair but it hasn't been set yet */
@property (nonatomic, readonly) BOOL localKeyPairMissing;

/**
 The remote DH public key.
 On protocols where the remote public key isn't know, this value is set automatically for you after the handshake phase.
 */
@property (nullable, nonatomic, strong) NFKey *remotePublicKey;
/** @return YES if this protocol requires the remove static public key but it hasn't been set yet */
@property (nonatomic, readonly) BOOL remotePublicKeyMissing;

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



NS_SWIFT_NAME(NoiseSessionDelegate)
@protocol NFSessionDelegate <NSObject>

@optional

/**
 Sent when the session has started.
 
 @param session the session instance
 */
- (void)sessionDidStart:(NFSession *)session;

/**
 Sent before sending each of the handshake message patterns for the chosen protocol.
 You can optionally return a payload here, but you should be wary of it's size.
 Returning a payload that doesn't fit the message will cause the session to fail.
 
 @param session the session instance
 @param pattern the handshake message pattern we're about to send
 @return an optional payload to send along with the message
 */
- (nullable NSData *)session:(NFSession *)session willSendHandshakeMessagePattern:(NSString *)pattern;

/**
 Sent after a handshake message pattern was received.
 If you are expecting a payloads during handshake you must implement this method.
 
 @param session the session instance
 @param pattern the handshake message pattern we just received
 @param payload the payload sent along with the message pattern (can be empty)
 */
- (void)session:(NFSession *)session didReceiveHandshakeMessage:(NSString *)pattern payload:(NSData *)payload;


/**
 Informs the delegate the handshake phase has completed.
 You may want to inspect the passed handshakeState to grab/inspect the peer's static key.
 
 @param session the session instance
 @param handshakeState the final NFHandshakeState object
 */
- (void)session:(NFSession *)session handshakeComplete:(NFHandshakeState *)handshakeState;

/**
 Notifies the delegate of received data.
 
 @param session the session instance
 @param data the received data after decryption
 */
- (void)session:(NFSession *)session didReceiveData:(NSData *)data;


/**
 Notifies the delegate the session was closed either due to an error,
 or if the it was explicitely closed.
 
 @param session the session instance
 @param error an optional error object
 */
- (void)sessionDidClose:(NFSession *)session error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END