//
//  AppDelegate.h
//  Otolith Controller
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSWindow *window;
    NSWindow *scanSheet;
    NSArrayController *arrayController;
    
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    NSMutableArray *devices;
    
    IBOutlet NSButton *connectButton;
    BOOL autoConnect;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;

@property (assign) IBOutlet NSTextView *logField;
@property (weak) IBOutlet NSArrayController *arrayController;

@property (retain) NSMutableArray *devices;


- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)cancelScanSheet:(id)sender;
- (IBAction)closeScanSheet:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

@end
