#import "LogRocketNativeModule.h"
#import <React/RCTLog.h>
#import <LogRocket/LogRocket-Swift.h>

@implementation LogRocketNativeModule

RCT_EXPORT_MODULE();

static NSMutableDictionary<NSString *, LROResponseBuilder *> *capturedRequests;

- (id)init {
  self = [super init];

  if (self) {
    capturedRequests = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleError:) name:@"LogRocketSDKError" object:nil];
  }

  return self;
}

-(void)handleError:(NSNotification*)notification {
  NSString *errorMessage = notification.userInfo[@"errorMessage"];
  NSNumber *shouldDisableAndFreeMemory = notification.userInfo[@"shouldDisableAndFreeMemory"];
  NSNumber *shouldWarnAboutReduxSize = notification.userInfo[@"shouldWarnAboutReduxSize"];

  [self sendEventWithName:@"LogRocketSDKOnError" body:@{@"errorMessage": errorMessage, @"shouldDisableAndFreeMemory": shouldDisableAndFreeMemory, @"shouldWarnAboutReduxSize": shouldWarnAboutReduxSize}];
}

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"LogRocketSDKOnError"];
}


RCT_EXPORT_METHOD(addLog:(NSString *)level args:(NSArray *)args)
{
  @try {
    [LROSDK addLogWithLevel:level args:args];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to add log");
  }
}

RCT_EXPORT_METHOD(captureException:(NSString *)message
                  errorType:(NSString *)errorType
                  exceptionType:(NSString *)exceptionType
                  stackTrace:(NSString *)stackTrace)
{
  @try {
    [LROSDK captureExceptionWithErrorMessage:message errorType:errorType exceptionType:exceptionType stackTrace:stackTrace];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture exception");
  }
}

RCT_EXPORT_METHOD(captureReduxAction:(NSDictionary *)data)
{
  @try {
    NSNumber *storeId = data[@"storeId"];
    NSNumber *count = [data objectForKey:@"count"] ? data[@"count"] : 0;
    NSNumber *duration = data[@"duration"];
    NSString *stateDelta = data[@"stateDelta"];
    NSString *action = data[@"action"];

    [LROSDK captureReduxActionWithAction:action storeId:storeId duration:duration stateDelta:stateDelta count:count];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture redux action");
  }
}

RCT_EXPORT_METHOD(captureReduxInitialState:(NSDictionary *)data)
{
  @try {
    NSNumber *storeId = data[@"storeId"];
    NSString *state = data[@"state"];

    [LROSDK captureReduxInitialStateWithState:state storeId:storeId];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture initial redux state");
  }
}

RCT_EXPORT_METHOD(captureRequest:(NSString *)reqID request:(NSDictionary *)request)
{
  @try {
    LRORequestBuilder *builder = [LROSDK newRequestBuilder];
    builder.url = request[@"url"];

    if ([request objectForKey:@"body"]) {
      NSDictionary *arson = [request objectForKey:@"body"];
      if (arson && [arson objectForKey:@"arson"]) {
        builder.arsonBody = [arson objectForKey:@"arson"];
      }
    }

    if ([request objectForKey:@"method"]) {
      builder.method = [request objectForKey:@"method"];
    }

    if ([request objectForKey:@"headers"]) {
      builder.headers = [request objectForKey:@"headers"];
    }

    capturedRequests[reqID] = [builder capture];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture request");
  }
}

RCT_EXPORT_METHOD(captureResponse:(NSString *)reqID response:(NSDictionary *)response)
{
  @try {
    LROResponseBuilder *builder = capturedRequests[reqID];

    if (builder) {
      if ([response objectForKey:@"body"]) {
        NSDictionary *arson = [response objectForKey:@"body"];
        if (arson && [arson objectForKey:@"arson"]) {
          builder.arsonBody = [arson objectForKey:@"arson"];
        }
      }

      if ([response objectForKey:@"statusCode"]) {
        NSNumber *statusCode = (NSNumber *) [response objectForKey:@"statusCode"];
        builder.status = [statusCode longValue];
      }

      if ([response objectForKey:@"headers"]) {
        builder.headers = [response objectForKey:@"headers"];
      }

      [builder capture];
    }

    [capturedRequests removeObjectForKey:reqID];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture response");
  }
}

RCT_EXPORT_METHOD(getSessionURL:(RCTResponseSenderBlock)callback)
{
  void (^completion)(NSString*) = ^(NSString* sessionURL) {
    callback(@[sessionURL]);
  };

  [LROSDK getSessionURL:completion];
}

RCT_EXPORT_METHOD(initWithConfig:(NSString *)appID
                  config:(NSDictionary *)config
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSString *serverURL = config[@"serverURL"];
    NSMutableSet<NSString *> *tags = [NSMutableSet setWithArray:config[@"redactionTags"]];
    [tags addObject:@"lr-hide"];

    LROConfiguration *configuration = [[LROConfiguration alloc] initWithAppID:appID];

    configuration.serverURL = serverURL;
    configuration.redactionTags = tags;
    configuration.viewScanningEnabled = YES;
    configuration.networkCaptureEnabled = NO;
    configuration.logCaptureEnabled = NO;
    configuration.requestSanitizer = nil;
    configuration.responseSanitizer = nil;
    configuration.registerTouchHandlers = YES;

    // Entries in the dictionary can be NSNull. Especially, on React-Native, this can happen.
    id enablePersistence = config[@"enablePersistence"];
    if (enablePersistence != nil && ![enablePersistence isEqual:[NSNull null]]) {
      configuration.persistenceEnabled = [enablePersistence boolValue];
    } else {
      configuration.persistenceEnabled = YES;
    }

    if ([config[@"textSanitizer"] isEqualToString:@"excluded"]) {
      configuration.textSanitizer = LROSanitizerTypeExcluded;
    } else {
      configuration.textSanitizer = LROSanitizerTypeNone;
    }

    id enableIPCapture = config[@"enableIPCapture"];
    if (enableIPCapture != nil && ![enableIPCapture isEqual:[NSNull null]]) {
      configuration.ipCaptureEnabled = [enableIPCapture boolValue];
    } else {
      configuration.ipCaptureEnabled = YES;
    }

    id experimentalBidiCapture = config[@"experimentalBidiCapture"];
    if (experimentalBidiCapture != nil && ![experimentalBidiCapture isEqual:[NSNull null]]) {
      configuration.experimentalBidiCapture = [experimentalBidiCapture boolValue];
    } else {
      configuration.experimentalBidiCapture = NO;
    }

    id proxyConfiguration = config[@"iosProxyConfiguration"];
    if (
        proxyConfiguration != nil &&
        ![proxyConfiguration isEqual:[NSNull null]] &&
        [proxyConfiguration isKindOfClass: [NSDictionary class]]
        ) {
      LROProxyConfigurationBuilder *builder = [[LROProxyConfigurationBuilder alloc] init];

      if (proxyConfiguration[@"proxyUsername"]) {
        [builder proxyUsername:proxyConfiguration[@"proxyUsername"]];
      }

      if (proxyConfiguration[@"proxyPassword"]) {
        [builder proxyPassword:proxyConfiguration[@"proxyPassword"]];
      }

      if (proxyConfiguration[@"httpEnable"]) {
        [builder httpEnable:proxyConfiguration[@"httpEnable"]];
      }

      if (proxyConfiguration[@"httpProxy"]) {
        [builder httpProxy:proxyConfiguration[@"httpProxy"]];
      }

      if (proxyConfiguration[@"httpPort"]) {
        [builder httpPort: [proxyConfiguration[@"httpPort"] unsignedIntValue]];
      }

      configuration.proxyConfiguration = builder;
    }

    if ([config[@"uploadIntervalMs"] isKindOfClass:[NSNumber class]]) {
      configuration.uploadIntervalMs = [config[@"uploadIntervalMs"] unsignedIntValue];
    }

    BOOL result = [LROSDK initializeInternalWithConfiguration:configuration];
    resolve(@(result));
  }

  @catch (NSException *e) {
    NSLog(@"Failed to start LogRocket SDK");
    resolve(@(false));
  }
}

RCT_EXPORT_METHOD(identifyWithTraits:(NSString *)userID
                  userInfo:(NSDictionary *)userInfo
                  isAnonymous:(BOOL *)isAnonymous)
{
    @try {
        if (isAnonymous) {
          [LROSDK identifyAsAnonymousWithUserID:userID userInfo:userInfo];
        } else {
          [LROSDK identifyWithUserID:userID userInfo:userInfo];
        }
    }
    @catch (NSException *e) {
        NSLog(@"LogRocket: Failed to identify user.");
    }
}

RCT_EXPORT_METHOD(shutdown:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    [LROSDK shutdown];
    resolve(@(true));
  }

  @catch (NSException *e) {
    NSLog(@"Failed to shutdown LogRocket SDK");
    resolve(@(false));
  }
}

RCT_EXPORT_METHOD(track:(NSString *)customEventName eventProperties:(NSDictionary *)eventProperties)
{
  @try {
    LROCustomEventBuilder *builder = [[LROCustomEventBuilder alloc] init:customEventName];

    for (NSString *key in eventProperties) {
      NSDictionary *value = [eventProperties objectForKey:key];

      if ([value objectForKey:@"doubleVal"]) {
        NSArray *doubleArray = [value objectForKey:@"doubleVal"];
        [builder putDoubleArray:key value:doubleArray];
      } else if ([value objectForKey:@"boolVal"]) {
        NSArray *boolArray = [value objectForKey:@"boolVal"];
        [builder putBoolArray:key value:boolArray];
      } else if ([value objectForKey:@"stringVal"]) {
        NSArray *stringArray = [value objectForKey:@"stringVal"];
        [builder putStringArray:key value:stringArray];
      }
    }
    [LROSDK track:builder];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to track custom event");
  }
}

RCT_EXPORT_METHOD(captureMessage:(NSString *)message options:(NSDictionary *)options)
{
  @try {
    LROCaptureMessageBuilder *builder = [[LROCaptureMessageBuilder alloc] init:message];

    for (NSString *key in options) {
      if ([key isEqualToString:@"tags"] || [key isEqualToString:@"extra"]) {
        NSDictionary *tagsOrExtras = [options objectForKey:key];

        for (NSString *tagKey in tagsOrExtras) {
          NSString *tagValue = [tagsOrExtras objectForKey:tagKey];
          if ([key isEqualToString:@"tags"]) {
            [builder putTagString:tagKey value:tagValue];
          } else {
            [builder putExtraString:tagKey value:tagValue];
          }
        }
      }
    }
    [LROSDK captureMessage:builder];
  }
  @catch (NSException *e) {
    NSLog(@"Failed to capture message");
  }
}

RCT_EXPORT_METHOD(pauseViewCapture)
{
  @try {
    [LROSDK pauseViewCapture];
  }

  @catch (NSException *e) {
    NSLog(@"Failed to pause view capture");
  }
}

RCT_EXPORT_METHOD(unpauseViewCapture)
{
  @try {
    [LROSDK unpauseViewCapture];
  }

  @catch (NSException *e) {
    NSLog(@"Failed to unpause view capture");
  }
}

@end
