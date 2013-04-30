//
//  AppDelegate.h
//  Otolith Controller
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@class StepCounter;
@class UserAlarm;

@interface AppDelegate : NSObject <NSApplicationDelegate,CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSWindow *window;
    NSWindow *scanSheet;
    NSArrayController *arrayController;
    
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    CBCharacteristic *alarmChar;
    
    NSMutableArray *devices;
    
    IBOutlet NSButton *connectButton;
    BOOL autoConnect;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;

@property (assign) IBOutlet NSTextView *logField;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTextField *alarmTimeField;
@property (assign) IBOutlet NSTextField *stepCountField;
@property (assign) IBOutlet NSTextField *totalStepCountField;

@property (retain) NSMutableArray *devices;
@property (strong) StepCounter *stepCounter;
@property (strong) UserAlarm *userAlarm;


- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)cancelScanSheet:(id)sender;
- (IBAction)closeScanSheet:(id)sender;
- (IBAction)setAlarmButtonPressed:(id)sender;
- (IBAction)resetCountButtonPressed:(id)sender;

- (int)convertToInt:(NSDate*)date;
- (int)getAlarmTimeDelta;
- (void)updateUserInterface;
- (void)startScan;
- (void)stopScan;
- (BOOL)isLECapableHardware;

@end
