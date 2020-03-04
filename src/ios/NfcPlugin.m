//
//  NfcPlugin.m
//  PhoneGap NFC - Cordova Plugin
//
//  (c) 2107 Don Coleman

#import "NfcPlugin.h"

@interface NfcPlugin() {
    NSString* ndefStartSessionCallbackId;
}
@property (strong, nonatomic) NFCNDEFReaderSession *nfcSession;
@property (strong, nonatomic) id<NFCNDEFTag> connectedTag;
@end

@implementation NfcPlugin

- (void)pluginInitialize {

    NSLog(@"PhoneGap NFC - Cordova Plugin");
    NSLog(@"(c)2017 Don Coleman MWAHAHAHA! :D");

    [super pluginInitialize];
    
    // TODO fail quickly if not supported
    if (![NFCNDEFReaderSession readingAvailable]) {
        NSLog(@"NFC Support is NOT available");
    }
}

#pragma mark -= Cordova Plugin Methods

// Unfortunately iOS users need to start a session to read tags
- (void)beginSession:(CDVInvokedUrlCommand*)command {
    NSLog(@"beginSession MWAHAHAHA! :D");

    _nfcSession = [[NFCNDEFReaderSession new]initWithDelegate:self queue:nil invalidateAfterFirstRead:TRUE];
    ndefStartSessionCallbackId = [command.callbackId copy];
    [_nfcSession beginSession];
}

- (void)invalidateSession:(CDVInvokedUrlCommand*)command {
    NSLog(@"invalidateSession");
    if (_nfcSession) {
        [_nfcSession invalidateSession];
    }
    // Always return OK. Alternately could send status from the NFCNDEFReaderSessionDelegate
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Nothing happens here, the event listener is registered in JavaScript
- (void)registerNdef:(CDVInvokedUrlCommand *)command {
    NSLog(@"registerNdef");
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// Nothing happens here, the event listener is removed in JavaScript
- (void)removeNdef:(CDVInvokedUrlCommand *)command {
    NSLog(@"removeNdef");
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)enabled:(CDVInvokedUrlCommand *)command {
    NSLog(@"enabled");
    CDVPluginResult *pluginResult;
    if ([NFCNDEFReaderSession readingAvailable]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"NO_NFC"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)writeTag:(CDVInvokedUrlCommand*)command {
    NSLog(@"1");
    NSLog(@"%@", [command arguments][0][0][@"type"]);
    NSString *strType = @"84";
    NSLog(@"2");
    NSString *strId = @"10";
    NSLog(@"3");
    NSArray<NSNumber *> *strPayload = [[NSArray alloc] initWithArray:[command arguments][0][0][@"payload"]];
    NSLog(@"%@", strPayload);
    NSLog(@"4");
    NSMutableArray<NFCNDEFPayload*> * mutRecords;
    NSLog(@"5");
    NSLog(@"%@", [strPayload[1] class]);
    for (NSNumber* payloadRecord in strPayload) {
        NSLog(@"6*");
        [mutRecords addObject:[[NFCNDEFPayload alloc]
        initWithFormat:NFCTypeNameFormatNFCWellKnown
        type:[strType dataUsingEncoding:NSUTF8StringEncoding]
        identifier:[strId dataUsingEncoding:NSUTF8StringEncoding]
                            payload:payloadRecord]];
    }
    NSLog(@"7");
    NSArray<NFCNDEFPayload*> * records = [NSArray arrayWithObject:mutRecords];
    NSLog(@"8");
//
//    NSArray<NFCNDEFPayload *> *payload = [command arguments][0][0][@"payload"];
    NFCNDEFMessage *message;
    NSLog(@"9");
//    NFCNDEFMessage *message;
    message = [message initWithNDEFRecords:records];
    NSLog(@"10");
    [self.connectedTag writeNDEF:message completionHandler:^(NSError * _Nullable error) {
        NSLog(@"There was an error while writing to the tag");
        NSLog(@"%@", error);
        [_nfcSession invalidateSession];
    }];
    NSLog(@"11");
    [_nfcSession invalidateSession];
}

- (void)channel:(CDVInvokedUrlCommand *)command {
    NSLog(@"CHANNELING!!!!!!!!!!!!!!!! or whatever...");
}

#pragma mark - NFCNDEFReaderSessionDelegate

- (void) readerSession:(NFCNDEFReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCNDEFTag>> *)tags {
    NSLog(@"NFCNDEFReaderSession didDetectTags");
    
    for (id<NFCNDEFTag> tag in tags) {
        [_nfcSession connectToTag:tag completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                [tag readNDEFWithCompletionHandler:^(NFCNDEFMessage * _Nullable message, NSError * _Nullable error) {
                    if (!error) {
                        self.connectedTag = tag;
                        [self fireNdefEvent: message];
                        NSLog(@"we have connected a tag");
                    }
                    else {
                        NSLog(@"%@", error);
                    }
                }];
            }
        }];
    }
}

- (void) readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error {
    // NSLog(@"didInvalidateWithError %@ %@", error.localizedDescription, error.localizedFailureReason);
    if (ndefStartSessionCallbackId) {
        NSString* errorMessage = [NSString stringWithFormat:@"error: %@", error.localizedDescription];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:ndefStartSessionCallbackId];
    }
}

- (void) readerSessionDidBecomeActive:(nonnull NFCReaderSession *)session {
    NSLog(@"readerSessionDidBecomeActive");
    if (ndefStartSessionCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        //[pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:ndefStartSessionCallbackId];
        ndefStartSessionCallbackId = NULL;
    }
}

- (void)readerSession:(nonnull NFCNDEFReaderSession *)session didDetectNDEFs:(nonnull NSArray<NFCNDEFMessage *> *)messages { 
}


#pragma mark - internal implementation

// Create a JSON description of the NFC NDEF tag and call a JavaScript function fireNfcTagEvent.
// The event handler registered by addNdefListener will handle the JavaScript event fired by fireNfcTagEvent().
// This is a bit convoluted and based on how PhoneGap 0.9 worked. A new implementation would send the data
// in a success callback.
-(void) fireNdefEvent:(NFCNDEFMessage *) ndefMessage {
    NSString *ndefMessageAsJSONString = [self ndefMessagetoJSONString:ndefMessage];
    NSLog(@"%@", ndefMessageAsJSONString);

    // construct string to call JavaScript function fireNfcTagEvent(eventType, tagAsJson);
    NSString *function = [NSString stringWithFormat:@"fireNfcTagEvent('ndef', '%@')", ndefMessageAsJSONString];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self webView] isKindOfClass:WKWebView.class])
          [(WKWebView*)[self webView] evaluateJavaScript:function completionHandler:^(id result, NSError *error) {}];
        else
          [(UIWebView*)[self webView] stringByEvaluatingJavaScriptFromString: function];
    });
}

-(NSString *) ndefMessagetoJSONString:(NFCNDEFMessage *) ndefMessage {
    
    NSMutableArray *array = [NSMutableArray new];
    for (NFCNDEFPayload *record in ndefMessage.records){
        NSDictionary* recordDictionary = [self ndefRecordToNSDictionary:record];
        [array addObject:recordDictionary];
    }
    
    // The JavaScript tag object expects a key with ndefMessage
    NSMutableDictionary *wrapper = [NSMutableDictionary new];
    [wrapper setObject:array forKey:@"ndefMessage"];
    return dictionaryAsJSONString(wrapper);
}

-(NSDictionary *) ndefRecordToNSDictionary:(NFCNDEFPayload *) ndefRecord {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"tnf"] = [NSNumber numberWithInt:(int)ndefRecord.typeNameFormat];
    dict[@"type"] = uint8ArrayFromNSData(ndefRecord.type);
    dict[@"id"] = uint8ArrayFromNSData(ndefRecord.identifier);
    dict[@"payload"] = uint8ArrayFromNSData(ndefRecord.payload);
    NSDictionary *copy = [dict copy];
    return copy;
}

// returns an NSArray of uint8_t representing the bytes in the NSData object.
NSArray *uint8ArrayFromNSData(NSData *data) {
    const void *bytes = [data bytes];
    NSMutableArray *array = [NSMutableArray array];
    for (NSUInteger i = 0; i < [data length]; i += sizeof(uint8_t)) {
        uint8_t elem = OSReadLittleInt(bytes, i);
        [array addObject:[NSNumber numberWithInt:elem]];
    }
    return array;
}

NSString* dictionaryAsJSONString(NSDictionary *dict) {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    NSString *jsonString;
    if (! jsonData) {
        jsonString = [NSString stringWithFormat:@"Error creating JSON for NDEF Message: %@", error];
        NSLog(@"%@", jsonString);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

@end
