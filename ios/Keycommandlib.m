#import "Keycommandlib.h"
#import <UIKit/UIKit.h>

#import <objc/message.h>
#import <objc/runtime.h>
#import "RCTDefines.h"
#import "RCTUtils.h"

@interface CustomKeyCommands : NSObject

+ (instancetype)sharedInstance;

/**
 * Register a keyboard command.
 */
- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)flags
                             action:(void (^)(UIKeyCommand *command))block;

/**
 * Unregister a keyboard command.
 */
- (void)unregisterKeyCommandWithInput:(NSString *)input modifierFlags:(UIKeyModifierFlags)flags;

/**
 * Check if a command is registered.
 */
- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input modifierFlags:(UIKeyModifierFlags)flags;

@end


@interface UIEvent (UIPhysicalKeyboardEvent)

@property (nonatomic) NSString *_modifiedInput;
@property (nonatomic) NSString *_unmodifiedInput;
@property (nonatomic) UIKeyModifierFlags _modifierFlags;
@property (nonatomic) BOOL _isKeyDown;
@property (nonatomic) long _keyCode;

@end

@interface CustomKeyCommand : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, readonly) UIKeyModifierFlags flags;
@property (nonatomic, copy) void (^block)(UIKeyCommand *);

@end

@implementation CustomKeyCommand

- (instancetype)init:(NSString *)key flags:(UIKeyModifierFlags)flags block:(void (^)(UIKeyCommand *))block
{
  if ((self = [super init])) {
    _key = key;
    _flags = flags;
    _block = block;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(-(instancetype)init)

- (id)copyWithZone:(__unused NSZone *)zone
{
  return self;
}

- (NSUInteger)hash
{
  return _key.hash ^ _flags;
}

- (BOOL)isEqual:(CustomKeyCommand *)object
{
  if (![object isKindOfClass:[CustomKeyCommand class]]) {
    return NO;
  }
  return [self matchesInput:object.key flags:object.flags];
}

- (BOOL)matchesInput:(NSString *)input flags:(UIKeyModifierFlags)flags
{
  // We consider the key command a match if the modifier flags match
  // exactly or is there are no modifier flags. This means that for
  // `cmd + r`, we will match both `cmd + r` and `r` but not `opt + r`.
  return [_key isEqual:input] && _flags == flags;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@:%p input=\"%@\" flags=%lld hasBlock=%@>",
                                    [self class],
                                    self,
                                    _key,
                                    (long long)_flags,
                                    _block ? @"YES" : @"NO"];
}

@end

@interface CustomKeyCommands ()

@property (nonatomic, strong) NSMutableSet<CustomKeyCommand *> *commands;

@end

@implementation CustomKeyCommands

+ (void)initialize
{
  SEL originalKeyEventSelector = NSSelectorFromString(@"handleKeyUIEvent:");
  SEL swizzledKeyEventSelector = NSSelectorFromString(
      [NSString stringWithFormat:@"_rct_swizzle_%x_%@", arc4random(), NSStringFromSelector(originalKeyEventSelector)]);

  void (^handleKeyUIEventSwizzleBlock)(UIApplication *, UIEvent *) = ^(UIApplication *slf, UIEvent *event) {
    [[[self class] sharedInstance] handleKeyUIEventSwizzle:event];

    ((void (*)(id, SEL, id))objc_msgSend)(slf, swizzledKeyEventSelector, event);
  };

  RCTSwapInstanceMethodWithBlock(
      [UIApplication class], originalKeyEventSelector, handleKeyUIEventSwizzleBlock, swizzledKeyEventSelector);
}

- (void)handleKeyUIEventSwizzle:(UIEvent *)event
{
  NSString *modifiedInput = nil;
  UIKeyModifierFlags modifierFlags = 0;
  BOOL isKeyDown = NO;

  if ([event respondsToSelector:@selector(_modifiedInput)]) {
    modifiedInput = [event _modifiedInput];
  }

  if ([event respondsToSelector:@selector(_modifierFlags)]) {
    modifierFlags = [event _modifierFlags];
  }

  if ([event respondsToSelector:@selector(_isKeyDown)]) {
    isKeyDown = [event _isKeyDown];
  }

  BOOL interactionEnabled = !UIApplication.sharedApplication.isIgnoringInteractionEvents;
  BOOL hasFirstResponder = NO;

  if (isKeyDown && modifiedInput.length > 0 && interactionEnabled) {
    UIResponder *firstResponder = nil;
    for (UIWindow *window in [self allWindows]) {
      firstResponder = [window valueForKey:@"firstResponder"];
      if (firstResponder) {
        hasFirstResponder = YES;
        break;
      }
    }

    // Ignore key commands (except escape) when there's an active responder
    if (!firstResponder) {
      [self RCT_handleKeyCommand:modifiedInput flags:modifierFlags];
    }
  }
};

- (NSArray<UIWindow *> *)allWindows
{
  BOOL includeInternalWindows = YES;
  BOOL onlyVisibleWindows = NO;

  // Obfuscating selector allWindowsIncludingInternalWindows:onlyVisibleWindows:
  NSArray<NSString *> *allWindowsComponents =
      @[ @"al", @"lWindo", @"wsIncl", @"udingInt", @"ernalWin", @"dows:o", @"nlyVisi", @"bleWin", @"dows:" ];
  SEL allWindowsSelector = NSSelectorFromString([allWindowsComponents componentsJoinedByString:@""]);

  NSMethodSignature *methodSignature = [[UIWindow class] methodSignatureForSelector:allWindowsSelector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

  invocation.target = [UIWindow class];
  invocation.selector = allWindowsSelector;
  [invocation setArgument:&includeInternalWindows atIndex:2];
  [invocation setArgument:&onlyVisibleWindows atIndex:3];
  [invocation invoke];

  __unsafe_unretained NSArray<UIWindow *> *windows = nil;
  [invocation getReturnValue:&windows];
  return windows;
}

- (void)RCT_handleKeyCommand:(NSString *)input flags:(UIKeyModifierFlags)modifierFlags
{
  for (CustomKeyCommand *command in [CustomKeyCommands sharedInstance].commands) {
    if ([command matchesInput:input flags:modifierFlags]) {
      if (command.block) {
        command.block(nil);
      }
    }
  }
}

+ (instancetype)sharedInstance
{
  static CustomKeyCommands *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });

  return sharedInstance;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _commands = [NSMutableSet new];
  }
  return self;
}

- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)flags
                             action:(void (^)(UIKeyCommand *))block
{
  RCTAssertMainQueue();

  CustomKeyCommand *keyCommand = [[CustomKeyCommand alloc] init:input flags:flags block:block];
  [_commands removeObject:keyCommand];
  [_commands addObject:keyCommand];
}

- (void)unregisterKeyCommandWithInput:(NSString *)input modifierFlags:(UIKeyModifierFlags)flags
{
  RCTAssertMainQueue();

  for (CustomKeyCommand *command in _commands.allObjects) {
    if ([command matchesInput:input flags:flags]) {
      [_commands removeObject:command];
      break;
    }
  }
}

- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input modifierFlags:(UIKeyModifierFlags)flags
{
  RCTAssertMainQueue();

  for (CustomKeyCommand *command in _commands) {
    if ([command matchesInput:input flags:flags]) {
      return YES;
    }
  }
  return NO;
}

@end


@implementation Keycommandlib

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onKeyCommand"];
}

- (NSDictionary *)constantsToExport {
    return @{
         @"keyModifierShift": @(UIKeyModifierAlphaShift),
         @"keyModifierControl": @(UIKeyModifierControl),
         @"keyModifierAlternate": @(UIKeyModifierAlternate),
         @"keyModifierCommand": @(UIKeyModifierCommand),
         @"keyModifierNumericPad": @(UIKeyModifierNumericPad),
         @"keyInputUpArrow": UIKeyInputUpArrow,
         @"keyInputDownArrow": UIKeyInputDownArrow,
         @"keyInputLeftArrow": UIKeyInputLeftArrow,
         @"keyInputRightArrow": UIKeyInputRightArrow,
         @"keyInputEscape": UIKeyInputEscape
    };
}

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_REMAP_METHOD(registerKeyCommand,
                 registerKeyCommand:(NSArray *)json
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
  
  NSArray<NSDictionary *> *commandsArray = json;
  
  for (NSDictionary *commandJSON in commandsArray) {
      NSString *input = commandJSON[@"input"];
      NSNumber *flags = commandJSON[@"modifierFlags"];

      if (!flags) {
          flags = @0;
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        [[CustomKeyCommands sharedInstance]
           registerKeyCommandWithInput:@"k"
            modifierFlags:UIKeyModifierCommand
            action:^(__unused UIKeyCommand *command) {
              [self sendEventWithName:@"onKeyCommand" body:@{
                   @"input": input,
                   @"modifierFlags": flags
              }];
            }];
      });
  }
  
  resolve(nil);
}

@end
