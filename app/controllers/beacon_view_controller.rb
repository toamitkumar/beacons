class BeaconViewController < UIViewController

  attr_accessor :beaconTableView

  attr_reader :detectedBeacons, :advertisingSwitch, :rangingSwitch, :beaconRegion, :peripheralManager, :locationManager

  NTOperationsSection = 0
  NTDetectedBeaconsSection = 1

  NTAdvertisingRow = 0
  NTRangingRow = 1

  KNumberOfAvailableOperations = 2

  def tableView(tableView, numberOfRowsInSection:section)
    case section
      when NTOperationsSection
        KNumberOfAvailableOperations
      when NTDetectedBeaconsSection
        @detectedBeacons.size
      else
        @detectedBeacons.size
      end
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    case indexPath.section
    when NTOperationsSection
      cell = tableView.dequeueReusableCellWithIdentifier("OperationCell")
      case indexPath.row
      when NTAdvertisingRow
        cell.textLabel.text = "Advertising"
        @advertisingSwitch  = cell.accessoryView
        @advertisingSwitch.addTarget(self, 
                                      action: "changeAdvertisingState:", 
                                      forControlEvents:UIControlEventValueChanged)
      when NTRangingRow
        cell.textLabel.text = "Ranging"
        @rangingSwitch      = cell.accessoryView
        @rangingSwitch.addTarget(self, 
                                  action: "changeRangingState:", 
                                  forControlEvents:UIControlEventValueChanged)
      else
      end
    when NTDetectedBeaconsSection
      beacon  = @detectedBeacons[indexPath.row]
      cell    = tableView.dequeueReusableCellWithIdentifier("BeaconCell")
      
      unless (cell)
        cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:"BeaconCell")
      end
      
      cell.textLabel.text             = beacon.proximityUUID.UUIDString
      cell.detailTextLabel.text       = detailsStringForBeacon(beacon)
      cell.detailTextLabel.textColor  = UIColor.GrayColor
    else
    end

    cell
  end

  def numberOfSectionsInTableView(tableView)
    @rangingSwitch.on? ? 2 : 1
  end

  def tableView(tableView, numberOfRowsInSection:section)
    case section
    when NTOperationsSection
      2
    when NTDetectedBeaconsSection
      
    else 
      @detectedBeacons.size
    end
  end

  def tableView(tableView, titleForHeaderInSection:section)
    case section
    when NTOperationsSection
      nil
    when NTDetectedBeaconsSection
      "Looking for beacon..."
    else 
      "Looking for beacon..."
    end
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath)
    case indexPath.section
    when NTOperationsSection
      44
    when NTDetectedBeaconsSection
      52
    else 
      52
    end
  end

  def tableView(tableView, viewForHeaderInSection:section)
    headerView = UITableViewHeaderFooterView.alloc.initWithReuseIdentifier("BeaconsHeader")
    indicatorView = UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(initWithActivityIndicatorStyle)
    headerView.addSubview(indicatorView)
    indicatorView.frame = CGRect(CGPoint(205, 12), indicatorView.frame.size)

    indicatorView.startAnimating
    headerView
  end

  def detailsStringForBeacon(beacon)
    proximity = case beacon.proximity
                when CLProximityNear then "Near"
                when CLProximityImmediate then "Immediate"
                when CLProximityFar then "Far"
                when CLProximityUnknown then "Unknown"
                else "Unknown"
                end

    format = "%@, %@ • %@ • %f • %li"
    String.stringWithFormat(format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi)
  end

  def changeAdvertisingState(switch)
    switch.on? ? startAdvertisingBeacon : stopAdvertisingBeacon
  end

  def changeRangingState(switch)
    switch.on? ? startRangingForBeacons : stopRangingForBeacons
  end

  def startAdvertisingBeacon
    createBeaconRegion

    unless(@peripheralManager)
      @peripheralManager = CBPeripheralManager.alloc.initWithDelegate(self, queue:nil, options:nil)
    end
    turnOnAdvertising
  end

  def stopAdvertisingBeacon
    @peripheralManager.stopAdvertising
    p "Turned off advertising."
  end

  def startRangingForBeacons
    @locationManager = CLLocationManager.alloc.init
    @locationManager.delegate = self

    @detectedBeacons = []
    turnOnRanging
  end

  def stopRangingForBeacons
    if(@locationManager.rangedRegions.size == 0)
      p "Didn't turn off ranging: Ranging already off."
      return
    end

    @locatioManager.stopRangingBeaconsInRegion(@beaconRegion)

    @detectedBeacons = []
    sectionsToBeDeleted = deletedSections

    @beaconTableView.beginUpdates
    if(sectionsToBeDeleted)
      @beaconTableView..deleteSections(sectionsToBeDeleted, withRowAnimation:UITableViewRowAnimationFade) 
    end     

    @beaconTableView.endUpdates

    p "Turned off ranging."
  end

  def deletedSections
    if(not @rangingSwitch.on? and @beaconTableView.numberOfSections == 1)
      NSIndexSet.indexSetWithIndex(1)
    else
      nil
    end
  end

  def insertedSections
    if(@rangingSwitch.on? and @beaconTableView.numberOfSections == 1)
      1
    else
      nil
    end
  end

  def filteredBeacons(beacons)
    dupBeacons = beacons.mutableCopy

    dupBeacons.uniq{|beacon| beacon.major and beacon.minor}
  end


  def turnOnRanging
    p "Turning on ranging..."

    unless(CLLocationManager.isRangingAvailable)
      p "Couldn't turn on ranging: Ranging is not available."
      @rangingSwitch.on = false
    end

    if(@locationManager.rangedRegions.count > 0)
      p "Didn't turn on ranging: Ranging already on."
      return
    end

    createBeaconRegion
    @locationManager.startRangingBeaconsInRegion(@beaconRegion)

    p "Ranging turned on for region: #{@beaconRegion}"
  end

  def createBeaconRegion
    return if(@beaconRegion)

    proximityUUID = NSUUID.alloc.initWithUUIDString("00000000-0000-0000-0000-000000000000")
    @beaconRegion = CLBeaconRegion.alloc.initWithProximityUUID(proximityUUID, identifier:"UniqueIdentifier")
  end

  def turnOnAdvertising
    if(@peripheralManager.state != CBPeripheralManagerStatePoweredOn)
      p "Peripheral manager is off."
      @advertisingSwitch.on = false
      return
    end

    region = CLBeaconRegion.alloc.initWithProximityUUID(@beaconRegion.proximityUUID, major:rand(), minor:rand(), identifier:@beaconRegion.identifier)
    @peripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
    p "Turning on advertising for region #{region}"
  end

  #pragma mark - Beacon advertising delegate methods
  def peripheralManagerDidStartAdvertising(peripheralManager, error:error)
    if(error)
      p error
      @advertisingSwitch.on = false
      return
    end

    if (peripheralManager.isAdvertising)
      p "Turned advertising"
      @advertisingSwitch.on = true
    end
  end

  def peripheralManagerDidUpdateState(peripheralManager)
    if(peripheralManager.state != CBPeripheralManagerStatePoweredOn)
      p "Peripheral manager is off."
      @advertisingSwitch.on = false
      return
    end

    p "Peripheral manager is on."
    turnOnAdvertising
  end

  #pragma mark - Beacon ranging delegate methods
  def locationManager(manager, didChangeAuthorizationStatus:status)
    unless(CLLocationManager.locationServicesEnabled)
      p "Couldn't turn on ranging: Location services are not enabled."
      @rangingSwitch.on = false
      return
    end

    if(CLLocationManager.authorizationStatus != KCLAuthorizationStatusAuthorized)
      p "Couldn't turn on ranging: Location services not authorised."
      @rangingSwitch.on = false
      return
    end

    @rangingSwitch.on = true
  end

  def locationManager(manager, didRangeBeacons:beacons, inRegion:region)
    uniqueBeacons = filteredBeacons(beacons)

    if(uniqueBeacons.size == 0)
      p "No beacons found nearby"
    else
      p "Found #{uniqueBeacons.size}"
    end

    newSections     = insertedSections
    removedSections = deletedSections
    deletedRows     = indexPathsOfRemovedBeacons(uniqueBeacons)
    insertedRows    = indexPathsOfInsertedBeacons(uniqueBeacons)
    reloadedRows    = nil

    if(not deletedRows and not insertedRows)
      reloadedRows = indexPathsForBeacons(uniqueBeacons)
    end

    @detectedBeacons = uniqueBeacons

    @beaconTableView.beginUpdates
    if (newSections)
      @beaconTableView.insertSections(newSections withRowAnimation:UITableViewRowAnimationFade)
    end

    if(removedSections)
      @beaconTableView.deleteSections(removedSections withRowAnimation:UITableViewRowAnimationFade)
    end

    if(insertedRows)
      @beaconTableView.insertRowsAtIndexPaths(insertedRows withRowAnimation:UITableViewRowAnimationFade)
    end

    if(deletedRows)
      @beaconTableView.deleteRowsAtIndexPaths(deletedRows withRowAnimation:UITableViewRowAnimationFade)
    end

    if(reloadedRows)
      @beaconTableView.reloadRowsAtIndexPaths(reloadedRows withRowAnimation:UITableViewRowAnimationFade)
    end
    @beaconTableView.endUpdates
  end

  # pragma mark - Index path management
  def indexPathsOfRemovedBeacons(beacons)
    
  end

  # - (NSArray *)indexPathsOfRemovedBeacons:(NSArray *)beacons
  # {
  #     NSMutableArray *indexPaths = nil;
      
  #     NSUInteger row = 0;
  #     for (CLBeacon *existingBeacon in self.detectedBeacons) {
  #         BOOL stillExists = NO;
  #         for (CLBeacon *beacon in beacons) {
  #             if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
  #                 (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
  #                 stillExists = YES;
  #                 break;
  #             }
  #         }
  #         if (!stillExists) {
  #             if (!indexPaths)
  #                 indexPaths = [NSMutableArray new];
  #             [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
  #         }
  #         row++;
  #     }
      
  #     return indexPaths;
  # }

  # - (NSArray *)indexPathsOfInsertedBeacons:(NSArray *)beacons
  # {
  #     NSMutableArray *indexPaths = nil;
      
  #     NSUInteger row = 0;
  #     for (CLBeacon *beacon in beacons) {
  #         BOOL isNewBeacon = YES;
  #         for (CLBeacon *existingBeacon in self.detectedBeacons) {
  #             if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
  #                 (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
  #                 isNewBeacon = NO;
  #                 break;
  #             }
  #         }
  #         if (isNewBeacon) {
  #             if (!indexPaths)
  #                 indexPaths = [NSMutableArray new];
  #             [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
  #         }
  #         row++;
  #     }
      
  #     return indexPaths;
  # }

  # - (NSArray *)indexPathsForBeacons:(NSArray *)beacons
  # {
  #     NSMutableArray *indexPaths = [NSMutableArray new];
  #     for (NSUInteger row = 0; row < beacons.count; row++) {
  #         [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
  #     }
      
  #     return indexPaths;
  # }

end