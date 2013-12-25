class BeaconViewController < UIViewController

  attr_accessor :beaconTableView

  attr_reader :detectedBeacons, :advertisingSwitch, :rangingSwitch

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
        @detectedBeacons.count
      else
        @detectedBeacons.count
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

end