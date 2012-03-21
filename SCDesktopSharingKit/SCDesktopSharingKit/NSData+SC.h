//
//  NSData+SC.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Ullrich Schäfer on 01.04.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    SCCryptoOperationEncrypt = 0,
    SCCrypotOperationDecrypt
};
typedef uint32_t SCCryptoOperation;
/*
 * This is mapped to CCOperation from CommonCryptor.h
 * so that we can just cast it and do not have to import
 * <CommonCrypto/CommonCryptor.h> here.
 */

extern NSData* SCSHA1(NSData *bytes);
extern NSData* SCSHA256(NSData *bytes);
extern NSData* SCAES128(NSData *key, NSData *inputBuffer, SCCryptoOperation operation);

@interface NSData (SC)

#pragma mark Base64

+ (id)sc_dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
- (NSString *)sc_base64EncodedString;


#pragma mark Encryption

- (NSData *)sc_encrypt:(NSData *)keyData;
- (NSData *)sc_encryptWithString:(NSString*)keyString;
- (NSData *)sc_decrypt:(NSData *)keyData;
- (NSData *)sc_decryptWithString:(NSString*)keyString;


#pragma mark Digest

- (NSData *)sc_SHA1Digest;
- (NSData *)sc_SHA256Digest;
- (NSString *)sc_SHA1Hexdigest;
- (NSString *)sc_SHA256Hexdigest;


#pragma mark Other

- (NSString *)sc_hexString;

@end
