//
//  NSData+SC.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Ullrich Schäfer on 01.04.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "NSData+SC.h"


static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSData (SC)

#pragma mark Base64

+ (id)sc_dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
{
    if ([string length] == 0)
        return [NSData data];
    
    static char *decodingTable = NULL;
    if (decodingTable == NULL)
    {
        decodingTable = malloc(256);
        if (decodingTable == NULL)
            return nil;
        memset(decodingTable, CHAR_MAX, 256);
        NSUInteger i;
        for (i = 0; i < 64; i++)
            decodingTable[(short)base64EncodingTable[i]] = i;
    }
    
    const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL)     //  Not an ASCII string!
        return nil;
    char *bytes = malloc((([string length] + 3) / 4) * 3);
    if (bytes == NULL)
        return nil;
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (YES)
    {
        char buffer[4];
        short bufferLength;
        for (bufferLength = 0; bufferLength < 4; i++)
        {
            if (characters[i] == '\0')
                break;
            if (isspace(characters[i]) || characters[i] == '=')
                continue;
            buffer[bufferLength] = decodingTable[(short)characters[i]];
            if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
            {
                free(bytes);
                return nil;
            }
        }
        
        if (bufferLength == 0)
            break;
        if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
        {
            free(bytes);
            return nil;
        }
        
        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2)
            bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
        if (bufferLength > 3)
            bytes[length++] = (buffer[2] << 6) | buffer[3];
    }
    
    realloc(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length];
}

- (NSString *)sc_base64EncodedString;
{
    if ([self length] == 0)
        return @"";
    
    char *characters = malloc((([self length] + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (i < [self length])
    {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        while (bufferLength < 3 && i < [self length])
            buffer[bufferLength++] = ((char *)[self bytes])[i++];
        
        //  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
        characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
        characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        if (bufferLength > 1)
            characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        else characters[length++] = '=';
        if (bufferLength > 2)
            characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
        else characters[length++] = '=';
    }
    
    return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];
}


#pragma mark Encryption

- (NSData *)sc_encrypt:(NSData *)keyData;
{
    return SCAES128(keyData, self, kCCEncrypt);
}

- (NSData *)sc_encryptWithString:(NSString*)keyString;
{
    return [self sc_encrypt:[keyString dataUsingEncoding:NSASCIIStringEncoding]];
}

- (NSData *)sc_decrypt:(NSData *)keyData;
{
    return SCAES128(keyData, self, kCCDecrypt);
}

- (NSData *)sc_decryptWithString:(NSString*)keyString;
{
    return [self sc_decrypt:[keyString dataUsingEncoding:NSASCIIStringEncoding]];
}


#pragma mark Digest

- (NSData *)sc_SHA1Digest;
{
    return SCSHA1(self);
}

- (NSData *)sc_SHA256Digest;
{
    return SCSHA256(self);
}

- (NSString *)sc_SHA1Hexdigest;
{
    return [[self sc_SHA1Digest] sc_hexString];
}

- (NSString *)sc_SHA256Hexdigest;
{
    return [[self sc_SHA256Digest] sc_hexString];
}


#pragma mark Other

- (NSString *)sc_hexString;
{
    uint8_t digest[[self length]];
    [self getBytes:digest length:[self length]];
    
    NSMutableString* output = [NSMutableString stringWithCapacity:[self length] * 2];
    
    for (NSUInteger i = 0; i < [self length]; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return [[output copy] autorelease];
}

@end


NSData* SCSHA1(NSData *bytes) {
    NSMutableData *buffer = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    unsigned char *result = [buffer mutableBytes];
    CC_SHA1([bytes bytes], (CC_LONG)[bytes length], result);
    return buffer;
}

NSData* SCSHA256(NSData *bytes) {
    NSMutableData *buffer = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    unsigned char *result = [buffer mutableBytes];
    CC_SHA256([bytes bytes], (CC_LONG)[bytes length], result);
    return buffer;
}

NSData* SCAES128(NSData *key,
                 NSData *inputBuffer,
                 SCCryptoOperation nx_operation) {
    CCOperation operation = (CCOperation)nx_operation;
    
    // SHA256 the key if it is not long enough
    if (kCCKeySizeAES256 != [key length]) {
        key = SCSHA256(key);
    }
    
    int len = (int)[inputBuffer length];
    int capacity = (int)(len / kCCBlockSizeAES128 + 1) * kCCBlockSizeAES128;
    NSMutableData *outputData = [NSMutableData dataWithLength:capacity];
    NSMutableData *iv = [NSMutableData dataWithLength:kCCBlockSizeAES128];
    
    size_t dataOutMoved;
    CCCryptorStatus result = CCCrypt(operation,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     (const char *)[key bytes],
                                     [key length],
                                     [iv bytes],
                                     (const void *)[inputBuffer bytes],
                                     [inputBuffer length],
                                     (void *)[outputData mutableBytes],
                                     capacity,
                                     &dataOutMoved);
    
    if (dataOutMoved < [outputData length]) {
        [outputData setLength:dataOutMoved];
    }
    
    
    if (result == kCCSuccess) {
        return [[outputData copy] autorelease];
    }
    
    return nil;
}


