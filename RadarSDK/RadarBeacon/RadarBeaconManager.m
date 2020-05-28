
#import "RadarBeaconManager.h"
#import "RadarBeaconManager+Internal.h"

#import "RadarBeaconScanRequest.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

static double const kRadarBeaconMonitorTimeoutSecond = 10.00f;
static NSUInteger const kRadarBeaconMonitorLimit = 20;

dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

@implementation RadarBeaconManager {
    NSMutableArray<RadarBeaconScanRequest *> *_queuedRequests;
    RadarBeaconScanRequest *_runningRequest;

    NSMutableDictionary<NSString *, RadarBeaconMonitorCompletionHandler> *_completionHandlers;

    BOOL _isMonitoring;

    dispatch_source_t _timer;

    dispatch_queue_t _workQueue;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [[RadarBeaconManager alloc] init];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [[RadarBeaconManager alloc] init];
            });
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _beaconScanner = [[RadarBeaconScanner alloc] initWithDelegate:self locationManager:[CLLocationManager new] permissionsHelper:[RadarPermissionsHelper new]];

        _workQueue = dispatch_queue_create_with_target("com.radar.beaconManager", DISPATCH_QUEUE_SERIAL, DISPATCH_TARGET_QUEUE_DEFAULT);
        _queuedRequests = [NSMutableArray array];
        _completionHandlers = [NSMutableDictionary dictionary];
        [self _startTimer];
    }
    return self;
}

- (void)dealloc {
    if (_timer) {
        [self _cancelTimer];
    }
}

#pragma mark - track Once with timer

- (void)monitorOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconMonitorCompletionHandler)block {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        if (radarBeacons.count == 0) {
            return block(RadarStatusSuccess, @[]);
        }
        NSArray *beaconsToMonitor = [radarBeacons subarrayWithRange:NSMakeRange(0, MIN(kRadarBeaconMonitorLimit, radarBeacons.count))];
        NSTimeInterval expiration = [[NSDate date] timeIntervalSince1970] + kRadarBeaconMonitorTimeoutSecond;
        RadarBeaconScanRequest *request = [[RadarBeaconScanRequest alloc] initWithIdentifier:[[NSUUID UUID] UUIDString] expiration:expiration beacons:beaconsToMonitor];
        [self->_queuedRequests addObject:request];
        self->_completionHandlers[request.identifier] = block;

        [self _scheduleRequest];
    });
}

- (void)_startTimer {
    if (!_timer) {
        weakify(self);
        _timer = CreateDispatchTimer(kRadarBeaconMonitorTimeoutSecond / 2.0, _workQueue, ^{
            strongify_else_return(self);
            [self _cancelTimedOutRequests];
        });
    }
}

- (void)_cancelTimer {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)_cancelTimedOutRequests {
    if (!_runningRequest && _queuedRequests.count == 0) {
        return;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSArray *queuedRequestsCopy = [_queuedRequests copy];
    for (RadarBeaconScanRequest *request in queuedRequestsCopy) {
        if (now >= request.expiration) {
            RadarBeaconMonitorCompletionHandler completion = _completionHandlers[request.identifier];
            if (completion) {
                completion(RadarStatusErrorBeacon, nil);
                [_completionHandlers removeObjectForKey:request.identifier];
            }
            [_queuedRequests removeObject:request];
        }
    }

    if (_runningRequest && now >= _runningRequest.expiration) {
        [self _didFinishMonitoringWithStatus:RadarStatusErrorBeacon nearbyBeacons:nil];
    }
}

#pragma mark - scheduling
- (void)_scheduleRequest {
    if (_isMonitoring) {
        return;
    }

    if (_queuedRequests.count == 0) {
        return;
    }

    RadarBeaconScanRequest *request = [_queuedRequests firstObject];
    [_queuedRequests removeObjectAtIndex:0];

    _runningRequest = request;
    _isMonitoring = YES;
    [_beaconScanner startMonitoringWithRequest:request];
}

#pragma mark - RadarBeaconScannerDelegate

- (void)didFinishMonitoring:(RadarBeaconScanRequest *)request status:(RadarStatus)status nearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        [self _didFinishMonitoringWithStatus:status nearbyBeacons:nearbyBeacons];
    });
}

- (void)_didFinishMonitoringWithStatus:(RadarStatus)status nearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    RadarBeaconMonitorCompletionHandler completion = _completionHandlers[_runningRequest.identifier];
    if (completion) {
        completion(status, nearbyBeacons);
        [_completionHandlers removeObjectForKey:_runningRequest.identifier];
    }
    [_beaconScanner stopMonitoring];
    _isMonitoring = NO;
    _runningRequest = nil;
    [self _scheduleRequest];
}

@end

NS_ASSUME_NONNULL_END