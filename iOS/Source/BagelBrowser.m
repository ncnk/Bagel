//
// Copyright (c) 2018 Bagel (https://github.com/yagiz/Bagel)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BagelBrowser.h"
#import "BagelConfiguration.h"
#import "BGPTChannel.h"
#import "BGPTProtocol.h"
#import "BGPTUSBHub.h"

#pragma mark -

@interface BagelBrowser (Bonjour)
- (void)startBonjourBrowsing;
- (void)sendDataByBonjour:(NSData *)packetData;
@end

#pragma mark -

@interface BagelBrowser (USB)
- (void)startUSBBrowsing;
- (void)sendDataByUSB:(NSData *)packetData;
@end

#pragma mark -
#pragma mark -

@interface BagelBrowser () <
GCDAsyncSocketDelegate,
NSNetServiceDelegate,
NSNetServiceBrowserDelegate,
BGPTChannelDelegate
>
@end

@implementation BagelBrowser {
    NSMutableArray* services;
    NSNetServiceBrowser* serviceBrowser;
    NSMutableArray* sockets;
    BagelRequestPacket* deviceExtendInfoPacket;
    __weak BGPTChannel *peerChannel;
}

- (instancetype)initWithConfiguration:(BagelConfiguration*)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        [self startBonjourBrowsing];
        [self startUSBBrowsing];
    }
    return self;
}

- (void)sendPacket:(BagelRequestPacket*)packet {
    NSError *error;
    NSData *packetData = [NSJSONSerialization dataWithJSONObject:[packet toJSON] options:0 error:&error];
    if (error) {
        NSLog(@"Bagel -> Error: %@", error.localizedDescription);
        return;
    }
    [self sendDataByBonjour:packetData];
    [self sendDataByUSB:packetData];
    
}

- (void)resendDeviceInfo {
    [self sendPacket:[self deviceInfoPacket]];
}

#pragma mark -

- (BagelRequestPacket *)deviceInfoPacket {
    BagelRequestPacket *packet = [[BagelRequestPacket alloc] init];
    packet.packetId = BagelUtility.UUID;
    packet.project = self.configuration.project;
    packet.device = self.configuration.device;
    packet.isDeviceExtendInfo = YES;
    return packet;
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(BGPTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return NO;
}

- (void)ioFrameChannel:(BGPTChannel*)channel didEndWithError:(NSError*)error {
}

- (void)ioFrameChannel:(BGPTChannel*)channel didAcceptConnection:(BGPTChannel*)otherChannel fromAddress:(BGPTAddress*)address {
    if (peerChannel) {
        [peerChannel cancel];
    }
    peerChannel = otherChannel;
    peerChannel.userInfo = address;
    [self resendDeviceInfo];
}

- (void)ioFrameChannel:(BGPTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(NSData *)payload {
}

@end

@implementation BagelBrowser (USB)

- (void)startUSBBrowsing {
    BGPTChannel *channel = [BGPTChannel channelWithDelegate:self];
    [channel listenOnPort:43210 IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        NSLog(@"%@", error ? error : @"");
    }];
}

- (void)sendDataByUSB:(NSData*)data {
    if (data) {
        [peerChannel sendFrameOfType:101 tag:0 withPayload:data callback:^(NSError *error) {
        }];
    }
}

@end

#pragma mark -
#pragma mark -
#pragma mark -

@implementation BagelBrowser (Bonjour)

- (void)startBonjourBrowsing {
    if (services) {
        [services removeAllObjects];
    } else {
        services = [[NSMutableArray alloc] init];
    }
    if (sockets) {
        [sockets removeAllObjects];
    } else {
        sockets = [[NSMutableArray alloc] init];
    }
    serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [serviceBrowser stop];
    [serviceBrowser setDelegate:self];
    [serviceBrowser searchForServicesOfType:self.configuration.netserviceType inDomain:self.configuration.netserviceDomain];
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser*)serviceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
    [services addObject:service];
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)serviceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
    [services removeObject:service];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService*)service {
    if ([self connectWithService:service]) {
        [self resendDeviceInfo];
    }
}

- (BOOL)connectWithService:(NSNetService*)service {
    BOOL _isConnected = NO;
    NSArray* addresses = [[service addresses] mutableCopy];
    GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    while (!_isConnected && [addresses count]) {
        NSData* address = [addresses objectAtIndex:0];
        NSError* error = nil;
        if ([socket connectToAddress:address error:&error]) {
            [sockets addObject:socket];
            _isConnected = YES;
        } else if (error) {
        }
    }
    return _isConnected;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket*)socket didConnectToHost:(NSString*)host port:(UInt16)port {
    [socket readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)socket withError:(NSError*)error {
    [socket setDelegate:nil];
    [sockets removeObject:socket];
}

#pragma mark - private method

- (void)sendDataByBonjour:(NSData *)packetData {
    if (packetData) {
        NSMutableData* buffer = [[NSMutableData alloc] init];
        uint64_t headerLength = [packetData length];
        [buffer appendBytes:&headerLength length:sizeof(uint64_t)];
        [buffer appendBytes:[packetData bytes] length:[packetData length]];
        for (GCDAsyncSocket* socket in sockets) {
            [socket writeData:buffer withTimeout:-1.0 tag:0];
        }
    }
}

@end
