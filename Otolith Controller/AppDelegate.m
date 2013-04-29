//
//  AppDelegate.m
//  Otolith Controller
//
//  Based on Apple's BLE Heart Rate Monitor sample
//      (developer.apple.com/library/mac/#samplecode/HeartRateMonitor/)
//
//

#import "AppDelegate.h"
#import "StepCounter.h"
#import "UserAlarm.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    autoConnect = FALSE;
    
    self.devices = [NSMutableArray array];
    
    StepCounter *sc = [[StepCounter alloc] init];
    [self setStepCounter:sc];
    
    UserAlarm *ua = [[UserAlarm alloc] init];
    [self setUserAlarm:ua];
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    if( autoConnect )
    {
        [self startScan];
    }
}

- (void) dealloc
{
    [self stopScan];
    
    [peripheral setDelegate:nil];
}


/*
 Disconnect peripheral when application terminate
 */
- (void) applicationWillTerminate:(NSNotification *)notification
{
    if(peripheral)
    {
        [manager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Scan sheet methods

/*
 Open scan sheet to discover peripherals if it is LE capable hardware
 */
- (IBAction)openScanSheet:(id)sender
{
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [arrayController removeObjects:devices];
        [NSApp beginSheet:self.scanSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self startScan];
    }
}

/*
 Close scan sheet once device is selected
 */
- (IBAction)closeScanSheet:(id)sender
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
    [self.scanSheet orderOut:self];
}

/*
 Close scan sheet without choosing any device
 */
- (IBAction)cancelScanSheet:(id)sender
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
    [self.scanSheet orderOut:self];
}

/*
 This method is called when Scan sheet is closed. Initiate connection to selected peripheral
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self stopScan];
    if( returnCode == NSAlertDefaultReturn )
    {
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0)
        {
            NSUInteger anIndex = [indexes firstIndex];
            peripheral = [self.devices objectAtIndex:anIndex];
            [connectButton setTitle:@"Cancel"];
            [manager connectPeripheral:peripheral options:nil];
        }
    }
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    NSLog(@"received a connectButtonPressed: message");
    
    if(peripheral && ([peripheral isConnected]))
    {
        /* Disconnect if it's already connected */
        [manager cancelPeripheralConnection:peripheral];
    }
    else if (peripheral)
    {
        /* Device is not connected, cancel pendig connection */
        [connectButton setTitle:@"Connect"];
        [manager cancelPeripheralConnection:peripheral];
        [self openScanSheet:nil];
    }
    else
    {   /* No outstanding connection, open scan sheet */
        [self openScanSheet:nil];
    }
}

- (int)convertToInt:(NSDate*)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    int hour = (int)[components hour];
    int minute = (int)[components minute];
    NSLog(@"Hour: %d Minute: %d\n", hour, minute);
    return hour*60 + minute;
}

/*
 Returns the number of minutes from the current time that the user
 wants the alarm to go off.
 */
- (int)getAlarmTimeDelta
{
    NSString *time = [self.alarmTimeField stringValue];
    //NSLog(@"Alarm set for %@\n", time);
    
    /* This didn't work... sigh (fails to get correct hour) */
    //NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    //[formatter setLocale:enUSPOSIXLocale];
    //[formatter setDateFormat:@"hh:mm a"];
    //[formatter setTimeZone:[NSTimeZone  localTimeZone]];
    //NSDate *convDate = [formatter dateFromString:time];
    //NSLog(@"Converted to %@\n", convDate);
    //int userTime = [self convertToInt:convDate];
    //NSLog(@"User time: %d\n", userTime);
    
    /* The ugly, terrible, 24-hour-only way */
    NSString *trimmed = [time stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int colonIndex = [trimmed length] == 4 ? 1 : 2;
    NSString *hour = [trimmed substringToIndex:colonIndex];
    NSString *minute = [trimmed substringFromIndex:(colonIndex+1)];
    //NSLog(@"Hour: %@ Minute: %@\n", hour, minute);
    int userTime = [hour intValue]*60 + [minute intValue];
    //NSLog(@"User time: %d\n", userTime);
    
    /* Get the current time to compare it to */
    NSDate *currentDate = [NSDate date];
    int currentTime = [self convertToInt:currentDate];
    //NSLog(@"Current time 2: %d\n", currentTime);
    
    int delta = userTime - currentTime;
    if (delta < 0)
        delta = 24*60 + delta;
    
    return delta;
}

- (IBAction)setAlarmButtonPressed:(id)sender
{
    NSLog(@"setAlarmButtonPressed");
    
    // delta should never be negative
    uint16_t delta = [self getAlarmTimeDelta];
    NSLog(@"Alarm time delta: %d\n", delta);
    
    NSData* valData = [NSData dataWithBytes:(void*)&delta length:sizeof(uint16_t)];
    [peripheral writeValue:valData forCharacteristic:alarmChar type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)resetCountButtonPressed:(id)sender
{
    NSLog(@"resetCountButtonPressed");
    
    [self.stepCounter resetStepCount];
    [self updateUserInterface];
}


#pragma mark - Step Count Data

/*
 Update UI with step count data received from device
 */
- (void) updateWithStepData:(NSData *)data
{    
    const uint8_t *stepData = [data bytes];
    
    uint8_t stepCount = stepData[0];
    
    NSLog(@"Received step count: %d\n", stepCount);
    
    [self.stepCounter updateWithCount:stepCount];
    [self updateUserInterface];
    
    //NSMutableString *msg = [NSMutableString stringWithFormat:@"Received: %d\n", stepCount];
    //[self.logField insertText:msg];

}

- (void)updateUserInterface
{
    [self.stepCountField setIntValue:[self.stepCounter latestStepCount]];
    [self.totalStepCountField setIntValue:[self.stepCounter totalStepCount]];
}


#pragma mark - Start/Stop Scan methods

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    [self cancelScanSheet:nil];
    
    return FALSE;
}

/*
 Request CBCentralManager to scan for otolith peripherals using service UUID 0x1000
 */
- (void) startScan
{
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"1000"]] options:nil];
}

/*
 Request CBCentralManager to stop scanning for peripherals
 */
- (void) stopScan
{
    [manager stopScan];
}


#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"devices"];
    if( ![self.devices containsObject:aPeripheral] )
        [peripherals addObject:aPeripheral];
    
    /* Retreive already known devices */
    if(autoConnect)
    {
        [manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        peripheral = [peripherals objectAtIndex:0];
        [connectButton setTitle:@"Cancel"];
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
    
    // Save reference to connected peripheral
    peripheral = aPeripheral;
	
    [connectButton setTitle:@"Disconnect"];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    [connectButton setTitle:@"Connect"];
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect"];
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"1000"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"1001"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* GAP (Generic Access Profile) for Device Name */
        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1000"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read step count */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2000"]])
            {
                NSLog(@"Found a Step Count Characteristic");
                
                // This will only read once
                //[aPeripheral readValueForCharacteristic:aChar];
                
                // This will read every time data is sent
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1001"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Write alarm time */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2001"]])
            {
                NSLog(@"Found a Alarm Time Characteristic");
                
                // Store reference to this characteristic
                alarmChar = aChar;
            }
        }
    }
    
    
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read manufacturer name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* Updated value for step count received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2000"]])
    {
       [self updateWithStepData:characteristic.value];
    }
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    {
        NSString * deviceName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Device Name = %@", deviceName);
    }
}

@end

