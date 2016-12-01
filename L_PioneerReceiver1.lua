module("L_PioneerReceiver1", package.seeall)
-- some code loosely adapted from http://code.mios.com/trac/mios_squeezebox/browser
fmt = require("L_PioneerReceiverFormats")
if(package.loaded.L_PioneerReceiverFormats == nil ) then
	luup.log('PioneerReceiver plugin failed loading, formats package failed')
	return nil
end
local socket = require("socket")
local get_current_ms = function () return socket.gettime()*1000 end
tracelevel = {}
local is_debug = true
serviceName = 'urn:micasaverde-com:serviceId:PioneerReceiver1'
altuiservice="urn:upnp-org:serviceId:altui1"
local pendingResponse = {}
ipAddress = ""
parms = {}
parms.LogLevel = 0
parms.RefreshRate = 1200 -- since the plugin maintains a connection to the amplifier, there really is no need to query more often
parms.Status = 0
parms.QueueDelay_ms = 300 -- according to docs, 100 ms is the min interval, but polling at that rate would flood the amplifier
parms.DisplayLine1Format = "Source: %Source%"
parms.DisplayLine2Format = "Mute: %Mute%"
List = {}
commandQueue = {}
CurrentRequest = {}

jobReturnCodes_WaitingToStart = 0 -- =job_WaitingToStart: In vera's UI a job in this state is
-- displayed as a gray icon. It means it's waiting to start.
-- If you return this value your 'job' code will be run again
-- in the 'timeout' seconds
jobReturnCodes_Error = 2
jobReturnCodes_Aborted = 3     -- In vera's UI a job in this state (2 or 3) is displayed as a red icon. This means the job failed. Your code won't be run again.
jobReturnCodes_Done = 4      -- In vera's UI a job in this state is displayed as a green icon. This means the job finished ok. Your code won't be run again.
jobReturnCodes_WaitingForCallback = 5-- In vera's UI a job in this state is displayed as a moving blue icon. This means the job is running and you're waiting for return data.


-- -------------------------------------------------------------------------
-- Mappings definition
-- additional documentation can be found here
-- https://www.pioneerelectronics.ca/StaticFiles/Custom%20Install/RS-232%20Codes/Av%20Receivers/Elite%20&%20Pioneer%20FY13AVR%20IP%20&%20RS-232%205-8-12.xls
--
service_map = {
  ["urn:micasaverde-com:serviceId:InputSelection1"] = {
    ["DiscreteinputCable"] = {command="05FN"},    -- TV/SAT
    ["DiscreteinputCD1"] = {command="01FN"},      -- CD
    ["DiscreteinputCD2"] = {command="01FN"},      -- CD
    ["DiscreteinputCDR"] = {command="03FN"},      -- CD-R/TAPE
    ["DiscreteinputDAT"] = {command="03FN"},      -- CD-R/TAPE
    ["DiscreteinputDVD"] = {command="04FN"},      -- DVD
    ["DiscreteinputDVI"] = {command="19FN"},      -- HDMI1
    ["DiscreteinputHDTV"] = {command="05FN"},     -- TV/SAT
    ["DiscreteinputLD"] = {command="00FN"},       -- PHONO
    ["DiscreteinputMD"] = {command="03FN"},       -- CD-R/TAPE
    ["DiscreteinputPC"] = {command="26FN"},       -- HOME MEDIA GALLERY(Internet Radio)
    ["DiscreteinputPVR"] = {command="15FN"},      -- DVR/BDR
    ["DiscreteinputTV"] = {command="05FN"},       -- TV/SAT
    ["DiscreteinputVCR"] = {command="10FN"},      -- VIDEO 1(VIDEO)
    ["Input1"] = {command="10FN"},                -- VIDEO 1(VIDEO)
    ["Input2"] = {command="14FN"},                -- VIDEO 2
    ["Input3"] = {command="19FN"},                -- HDMI1
    ["Input4"] = {command="20FN"},                -- HDMI2
    ["Input5"] = {command="21FN"},                -- HDMI3
    ["Input6"] = {command="22FN"},                -- HDMI4
    ["Input7"] = {command="23FN"},                -- HDMI5
    ["Input8"] = {command="24FN"},                -- HDMI6
    ["Input9"] = {command="25FN"},                -- BD
    ["Input10"] = {command="17FN"},               -- iPod/USB
    ["Source"] = {command="FU"},                  -- INPUT CHANGE (cyclic)
    ["ToggleInput"] = {command="FU"}             -- INPUT CHANGE (cyclic)
  },
  ["urn:upnp-org:serviceId:SwitchPower1"] = {
    ["Off"] =     {command="PF"},                     -- POWER OFF
    ["On"] =      {command="PO\rPO"},                      -- POWER ON
    ["Toggle"] =  {command="PZ"},                     -- POWER TOGGLE
    SetTarget = {
      parm = 'newTargetValue',
      ["0"] =       {command="PF"},                     -- POWER OFF
      ["1"] =       {command="PO\rPO"}
    }
  },
  ["urn:micasaverde-com:serviceId:MenuNavigation1"] = {
    ["Back"] = {command="CRT"},                   -- AMP RETURN
    ["Down"] = {command="CDN"},                   -- AMP CURSOR DOWN
    ["Exit"] = {command="CRT"},                   -- AMP RETURN
    ["Left"] = {command="CLE"},                   -- AMP CURSOR LEFT
    ["Menu"] = {command="HM"},                    -- HOME MENU
    ["Right"] = {command="CRI"},                  -- AMP CURSOR RIGHT
    ["Select"] = {command="CEN"},                 -- AMP CURSOR ENTER
    ["Up"] = {command="CUP"}                     -- AMP CURSOR UP
  },
  ["urn:micasaverde-com:serviceId:Volume1"] = {
    ["Down"] = {command="VD"},                    -- VOLUME DOWN
    ["Mute"] = {command="MZ"},                    -- MUTE ON/OFF
    ["Up"] = {command="VU"},                      -- VOLUME UP
    ["MuteToggle"] = {command="MZ"}
  },
  ["urn:micasaverde-com:serviceId:PioneerReceiver1"] = {
    SetVolumePct = {
      parm = 'NewVolumeTargetPct',
      command="%03.0fVL"
    },
    MuteOn =  {command="MO"},                     -- MuteOn
    MuteOff =  {command="MF"}                     -- Mute Off

  }


}
errors_map = {
  ["E02"] = { description="NOT AVAILABLE NOW", requeue=false, disable=false, save_message=true },
  ["E03"] = {description="INVALID COMMAND", requeue=false, disable=true, save_message=true },
  ["E04"] = {description="COMMAND ERROR", requeue=false, disable=true, save_message=true },
  ["E06"] = {description="PARAMETER ERROR", requeue=false, disable=true, save_message=true },
  ["B00"] = {description="BUSY", requeue=true, save_message=false }
}
responseMap = {}

-- -------------------------------------------------------------------------
-- This is a global wrapper around the module's process queue
--
local function process_queue(lul_device,lul_settings,lul_job)
  process_queue(lul_device,lul_settings,lul_job)
end
-- -------------------------------------------------------------------------
-- This function will queue commands to retrieve all known status of the amp
--
function _G.query_status(lul_device)
  log("Called to queue query status. ", tracelevel.DEBUG)

  if(ipAddress ~= nil) then
    if commandQueue.count == 0 then
      log('Preparing items to query...',tracelevel.DEBUG)
      if(fmt.variables_map ~= nil) then
        for key,curElement in pairs(fmt.variables_map) do
          if(curElement["enabled"] ) then
            curElement['key'] = key
            List.pushright(commandQueue,curElement)
          end
        end
      else 
        log('No active query command found.', tracelevel.WARNIG)
      end
      if(commandQueue ~= nil and commandQueue.count ~= 0 ) then
        --print_r(commandQueue,"commandQueue",tracelevel.TRACE)
        local resultCode, resultString, job, returnArguments = luup.call_action(serviceName, "processQueue", {}, type(lul_device)=='string' and tonumber(lul_device) or lul_device)
		print_r({resultcode = resultCode, resultString= resultString, job=job,returnArguments=returnArguments},"call_action return ",tracelevel.TRACE)
      end

    else
      log(string.format('The command queue still has %s elements to process',tostring(commandQueue.count)),tracelevel.TRACE)
    end

  end
  delay_query_status(lul_device)

end

-- -------------------------------------------------------------------------
-- This function attemps to retrieve a device variable and sets it to a
-- default it's not found
--
local function try_get_var (sid, varname, device, default)

  device = device or 'unknown'
  varname = varname or 'unknown'
  log(string.format('Getting value %s for device %s with default %s',varname or '?',device or '?', tostring(default or '?') ),tracelevel.DEBUG)

  local var_val = luup.variable_get (sid, varname, device)
  if nil == var_val then
    log(string.format("no value found for device %s variable %s", device, varname) ,tracelevel.DEBUG)
    if(default ~= nil) then
      luup.variable_set (sid, varname, default, device)
    end
    var_val = default
  else
    log(string.format("value %s found for device %s variable %s", tostring(var_val), device, varname) ,tracelevel.DEBUG)
  end
  return var_val
end

-- -------------------------------------------------------------------------
-- this will update the status lines for alt-ui
--
 function update_status_line(lul_device,index)

  try(function()
      -- ",
      --      "Variable": "DisplayLine1",
      local whichVariable = string.format('DisplayLine%i',index)
      local format_var = whichVariable..'Format'
      local format_val = try_get_var (altuiservice, format_var, lul_device, parms[format_var])
      
      for token in string.gmatch(format_val, "%%[^%%]*%%") do 
        local serviceVar = token:gsub("%%","")
        local value = try_get_var (serviceName, serviceVar, lul_device, '?')
        format_val = format_val:gsub('%'..token..'%',value)
        setIfChanged(altuiservice,whichVariable,format_val,lul_device)
      end
  end,
  function(e)
    log(string.format('formatting status line %i failed with return %s', index, e))
    debug.traceback()
    -- Except block. E.g.:
    -- Use e for conditional catch
    -- Re-raise with error(e)
  end
  )
end
-- -------------------------------------------------------------------------
-- Variable change listener callback
--
function parameter_changed(lul_device,lul_Service,lul_Variable,lul_OldValue,lul_NewValue)
  log(string.format("variable %s changing from %s to %s",lul_Variable,lul_OldValue,lul_NewValue),tracelevel.TRACE)
  parms[lul_Variable] = lul_NewValue
  update_status_line(lul_device,1)
  update_status_line(lul_device,2)
end


-- -------------------------------------------------------------------------
-- Update variable if changed
-- Return true if changed or false if no change
--
function setIfChanged(serviceId, name, value, deviceId)
  if name == nil then
    log('variable name was nil',tracelevel.ERROR)
    return false
  end
  local curValue = luup.variable_get(serviceId, name, deviceId)
  if ((value ~= curValue) or (curValue == nil)) then
    log(string.format(" Updated value of %s from %s to %s  ",name, curValue or ' ', value or ' '),tracelevel.TRACE)
    luup.variable_set(serviceId, name, value, deviceId)
    return true
  else
    return  false
  end
end

-- -------------------------------------------------------------------------
-- Send commands to the Pioneer receiver's interface
--
-- --------
-- Notes
-- --------
-- The documentation of the pioneer RS232 protocol states that the
-- receiver needs 100mn to wake up from certain states and that
-- during this time period, the amplifier cannot receive commands.
--
-- In order to avoid blocking the job thread, we're doing this by
-- by inserting a "wake" command every time an action is sent or
-- every time the status query is run and therefore no special
-- logic is required here
--
function sendCommand(command, lul_device, lul_settings, lul_job)
  if( command ~= nil and command.command ~= nil) then
    log(string.format("sending command %s ",command.command or '?'), tracelevel.DEBUG)
    -- -- Send the code to the receiver
    if( false == luup.io.write(command.command)) then
      log("failure when sending command : " .. command.command, tracelevel.ERROR)
      luup.set_failure(true)
      return false
    end
  else
    log("no command provided.", tracelevel.ERROR)
  end

  return true
end

-- -------------------------------------------------------------------------
-- Receives data from the io port and dispatches to a data mapper
--
function process_response(lul_device, lul_settings, lul_job, lul_data)
  local newVal = lul_data or 'N/A'

  log(string.format('PioneerReceiver incoming data : %s ', lul_data or ''),tracelevel.TRACE)

  if(lul_data ~= nil) then
    if(lul_data == 'R') then
      log('Received ACK', tracelevel.DEBUG)
    else

      map_response(lul_data, lul_device)
    end
  else
    log('Received null data', tracelevel.ERROR)
  end

  return jobReturnCodes_Done,nil,true
end

-- -------------------------------------------------------------------------
--
--
function map_response(lul_data,lul_device)
  local map = nil
  local converted = nil
  local var = CurrentRequest ~= nil and CurrentRequest.var ~= nil and  CurrentRequest.var or ''
  local key = CurrentRequest ~= nil and CurrentRequest.key ~= nil and  CurrentRequest.key or ''

  if(handle_error(lul_data,lul_device, var,key) == nil) then
    for key,value in pairs(responseMap) do
      if(lul_data:len() >= key:len() and lul_data:sub(1,key:len()) == key) then
        map = value
        local val =fmt.get_value(lul_data,map.prefix) or lul_data
        for skey,service in pairs(map.services or {}) do
          converted = service.convert and service.convert(val,lul_device) or val
          log(string.format('Value for variable %s : %s => %s',service.var or '?', val,converted or '?'), tracelevel.DEBUG)
          if(service.var ) then
            --log(string.format('Value %s = %s ',map.var, converted or '?'), tracelevel.DEBUG)
            setIfChanged(skey, service.var, converted, lul_device)
            if(map.key and CurrentRequest and CurrentRequest.key and map.key == CurrentRequest.key) then
              -- unmark current request as is now processed
              CurrentRequest = nil
            end
          end
        end
        break
      end
    end
    if(map == nil) then
      log(string.format('No conversion map for value %s',lul_data or '?'), tracelevel.WARNING)
      setIfChanged(serviceName, 'last_unknown_message', lul_data, lul_device)
    end
  end
  return converted, map
end
-- -------------------------------------------------------------------------
-- This function is called by the response mapper to check for any error
-- condition and take actions on them
--
-- Error              Action
-- ------------------ ------------------------------------------
-- BUSY               Re-queue the command for reprocessing
-- NOT AVAILABLE NOW  Changes the current value to 'UNAVAIL'
--                    next polling will attempt to retrieve
--                    the value again.
-- OTHER              Other errors will disable polling variables
--                    and set the variable witht he error code
--                    received. The variable is assumed to be
--                    the last polled value.
--
function handle_error(lul_data,lul_device,var,key)

  lul_data = lul_data or '?'
  lul_device = lul_device or '?'
  var = var or '?'
  key = key or '?'

  local error = errors_map[lul_data]
  if(error == nil) then return nil end

  log(string.format('%s when processing command %s',error.description,key or '?' ),tracelevel.ERROR)
  if(error.requeue and CurrentRequest ~= nil  ) then
    -- if the resource was busy, resend the command in the queue
    -- so that it can be reprocessed right away
    List.pushleft(commandQueue,CurrentRequest)
  end
  if(error.save_message) then
    setIfChanged(serviceName, var, error.description, lul_device)
  end
  if( error.disable and key ~= nil and var ~= nil ) then
    -- We need to disable querying this variable since there was a fatal error
    set_query_enable(key,false)
    setIfChanged(serviceName, var, error.description, lul_device)
  end
  -- unmark current request so it doesn't time out.
  CurrentRequest = nil
  return error
end



-- -------------------------------------------------------------------------
-- This function reads the queue and processes any pending command.
--
-- It will re-submit itself with the following delays
--    no more command :               no re-submit
--    command was sent successfully : ResponseTimeout to allow receiving
--                                    response from the amplifier
--    send failure :                  idle refresh rate - if send failed,
--                                    we're going to throttle
--
function _G.process_queue(lul_device,lul_settings,lul_job)
  -- ***** doc
  -- wrapper is
  -- function job(lul_device, lul_settings, lul_job)
  --    luup.log('device: ' .. tostring(lul_device) .. ' value: ' .. tostring(lul_settings.newTargetValue) .. ' job ID#: ' .. lul_job)
  --    -- 5 = job_WaitingForCallback
  --    -- and we'll wait 10 seconds for incoming data
  --    return 5, 10
  -- end
  -- ***** end doc
  log('processQueue processing',tracelevel.DEBUG)
  local returnCode = jobReturnCodes_Done
  local submitDelay = nil
  if(CurrentRequest ~= nil and CurrentRequest.key ~= nil) then
    log(string.format('last command %s for variable %s did not receive response',CurrentRequest.command or '?', CurrentRequest.var or '?'),tracelevel.WARNING)
    -- turn off that option to avoid flooding the device with unsupported queries
    set_query_enable(CurrentRequest.key,false)
    -- reset current request
    CurrentRequest = nil
  end
  if commandQueue.count > 0 then
    local command = List.popleft(commandQueue)
    print_r(command,string.format('Queue has %u elements to process. Current command : ',commandQueue.count) ,tracelevel.TRACE)
    if(sendCommand(command, lul_device, command, lul_job)) then
      -- the response should come really quick
      log('run queue job success',tracelevel.TRACE)
      CurrentRequest = command
      returnCode= jobReturnCodes_WaitingForCallback
      submitDelay = parms.QueueDelay_ms / 1000
    else
      log('run queue job did not succeed',tracelevel.ERROR)
      submitDelay = parms.RefreshRate
      returnCode= jobReturnCodes_Error
    end

  else
    log('Nothing in the queue',tracelevel.DEBUG)
    returnCode= jobReturnCodes_Done
    submitDelay=0
  end
  if(submitDelay ~= nil and submitDelay>0 ) then
    delay_process_queue(lul_device,submitDelay)
  end

  return returnCode,submitDelay
end

-- -------------------------------------------------------------------------
--
--
function delay_process_queue(lul_device,delay)
  local calculated_delay = math.ceil(delay  or (luup.io.is_connected and parms.QueueDelay_ms ) )
  if( luup.call_delay ('process_queue', calculated_delay , lul_device) ~= 0) then
    log('FATAL setting up a call delay to process queue',tracelevel.ERROR)
    luup.set_failure(true)
    return false
  else
    log(string.format('Process queue will run in %u (s) ',calculated_delay),tracelevel.TRACE)
    luup.set_failure(false)
    return true
  end
end

-- -------------------------------------------------------------------------
--
--
function delay_query_status(lul_device,delay)
  local calculated_delay = math.ceil(delay or math.ceil(parms.RefreshRate or 60*20 ))
  if(luup.call_delay ('query_status', calculated_delay , lul_device) ~= 0) then
    log('FATAL setting up a call delay to query status',tracelevel.ERROR)
    luup.set_failure(true)
    return false
  else
    log(string.format('Status query will run in %u (s) ',calculated_delay),tracelevel.DEBUG)
    luup.set_failure(false)
    return true
  end
end

-- -------------------------------------------------------------------------
-- Gets a parameter value (or default) and monitor for changes
--
function register_parameter(name,lul_device,default)
  local value = try_get_var(serviceName, name, lul_device, default)
  luup.variable_watch("parameter_changed",serviceName, name,lul_device)
  return value
end
-- -------------------------------------------------------------------------
-- Monitors ip address change and reset the plugin if this happens
--
function _G.handle_ipaddress_change(lul_device)
  local ipAddress = string.match(luup.attr_get("ip",lul_device) or '?',"(%d+%.%d+%.%d+%.%d+)")
  if(ipAddress and ipAddress and ipAddress ~= ipAddress ) then
    -- change of ip address which we need to take care of
    log(string.format('Ip address was changed from %s to %s. Restarting plugin',ipAddress or '?', ipAddress),tracelevel.INFO)
    CurrentRequest = nil
    if(commandQueue ~= nil and commandQueue.count ~= 0 ) then
      commandQueue = ListNew()
    end
    -- save the new address
    ipAddress = ipAddress
    try_connect(lul_device, false)
    -- trigger new status query
    delay_query_status(lul_device,1)
  end

  -- monitor address change every 5 seconds
  if(luup.call_delay ('handle_ipaddress_change', 5 , lul_device) ~= 0) then
    log('FATAL setting up a call delay to monitor ip address',tracelevel.ERROR)
    luup.set_failure(true)
  end
end

-- -------------------------------------------------------------------------
-- Perform the startup for the receiver (checks settings, checks connection,
-- etc.
-- The plugin does not keep the telnet port opened, as it prevents other
-- devices on the network to control the amplifier.
-- mios Documentation ***
-- variables: lul_device
-- return values: return 3 variables with the syntax return a,b,c where the
-- first is true if the startup was successful or false if not, followed by 2
-- strings for the comments and the name of the module
-- -- If this function is called in the startup sequence specified in the
-- 'startup' XML tag, return true if the startup was ok, false if it wasn't,
-- followed by some comments and the name of the module, like this: return
-- false,'Cannot get state','gc100' or return true,'ok','gc100'
--
function startup(lul_device, serviceName)
  
  serviceName = serviceName
  log('Initializing...',tracelevel.INFO)
  --luup.log(string.format('l_pioneerreceiver1 callback DUMP: %s',getdebug2()))
  -- for c in string.gmatch("nfSlu",".") do
  -- for i = 0, 3 do
  -- luup.log(string.format('L_PioneerReceiver1 DUMP(%u,%s): %s',i,c,getdebug(i,c)))
  -- end
  -- end

  commandQueue = ListNew()

  parms.LogLevel =  tonumber(register_parameter("LogLevel",lul_device, tostring(is_debug and tracelevel.DEBUG or tracelevel.INFO)))
  parms.RefreshRate =  tonumber(register_parameter("RefreshRate",lul_device,parms.RefreshRate))
  parms.Status = register_parameter("Status",lul_device,parms.Status)
  parms.QueueDelay_ms  =  math.ceil(register_parameter("QueueDelay_ms",lul_device,parms.QueueDelay_ms))
  parms.DisplayLine1Format = register_parameter("DisplayLine1Format",lul_device,parms.DisplayLine1Format)
  parms.DisplayLine2Format = register_parameter("DisplayLine2Format",lul_device,parms.DisplayLine2Format)
  luup.variable_watch("parameter_changed",serviceName, name,lul_device)
  if (fmt == nil)  then
    log("Plugin is not installed correctly. Library L_PioneerReceiverFormats cannot be loaded.",tracelevel.ERROR)
    return false,'Start failure','L_PioneerReceiver1'
  end

  ipAddress = string.match(luup.attr_get("ip",lul_device) or '?',"(%d+%.%d+%.%d+%.%d+)")
  if (ipAddress ~= "") then
    log("Running Network Attached on " .. ipAddress,tracelevel.INFO)
    try_connect(lul_device, true)

    if(delay_query_status(lul_device,1) ~= true) then
      return false,'delay start failure','L_PioneerReceiver1'
    end
  else
    log("IP address missing.",tracelevel.WARNIG)
  end
  handle_ipaddress_change(lul_device)
  log("Initializing complete.",tracelevel.INFO)
  return true,'ok','L_PioneerReceiver1'
end

-- -------------------------------------------------------------------------
-- Connects and/or checks that the connection can be established
--
function try_connect(lul_device, disconnect)
  local TELNET_PORT = 23
  if(string.find(ipAddress,":") == nil) then
	
  end
  if(luup.io.is_connected ~= true and ipAddress) then
    log(string.format('Connecting to %s:%s',ipAddress,TELNET_PORT),tracelevel.INFO)
    luup.io.open(lul_device, ipAddress, TELNET_PORT)
  end

  if( disconnect == true) then
  -- TODO:  implement!
  -- luup.io.close()
  end
  return true
end



-- -------------------------------------------------------------------------
--
--
function get_service_variabble(lul_device,  varname, lul_settings)
  local serviceName = lul_settings.serviceId or '?'
  print_r(lul_settings,"service variable data receid : ", tracelevel.DEBUG)
  -- nothing to do here, really.
  -- maybe we could poll the receiver for a refreshed value?

  return true
end

-- -------------------------------------------------------------------------
-- Queue the appropriate action based on the mapping table for this action
-- lul_device,true,"DiscretePower1", lul_settings
function queueAction(lul_device, priority,  lul_settings)
  print_r(lul_settings,"action Data : ", tracelevel.DEBUG)
  local resultCode, resultString, job, returnArguments,code
  priority = priority or false
  local service = service_map[lul_settings.serviceId or '?']
  local action = service and service[lul_settings.action or '?'] or '?'

  if(action == '?' ) then
    resultCode=false
    resultString = string.format('Invalid action %s for service %s',lul_settings.action or '?',lul_settings.serviceId or '?')
  else
    local value = action.parm and lul_settings[action.parm] or '?'
    if(value == nil) then
      resultCode=false
      resultString = string.format('Invalid action %s for service %s with %s=%s',lul_settings.action or '?',lul_settings.serviceId or '?',action.parm or '?', value or '?')
    else
      code = copy_obj(action[value] and action[value] or action or '?')

      if ( code == nil or code.command == nil) then
        resultCode=false
        resultString = string.format('Invalid action %s for service %s with %s=%s (command not found)',lul_settings.action or '?',lul_settings.serviceId or '?',action.parm or '?', value or '?')
      else
        if(code.command:find("%%") and code.command:find("%%")>0) then
          -- this command is a substitute
          code.command = code.command:format(value)
        end
        log(string.format('Queuing command %s for action %s for service %s with %s=%s',code.command or '?',lul_settings.action or '?',lul_settings.serviceId or '?',action.parm or '?', value or '?'), tracelevel.DEBUG)
        if(priority == true) then
          List.pushleft(commandQueue,code)
        else
          List.pushright(commandQueue,code)
        end
        if(commandQueue.count <= 1 ) then
          -- nothing processing currently. add a wakeup command and process queue
          List.pushleft(commandQueue,fmt.variables_map["WAKE"])
          luup.call_action(serviceName, "processQueue", {}, type(lul_device)=='string' and tonumber(lul_device) or lul_device)
        end
        if(action.parm) then
          setIfChanged(lul_settings.serviceId, action.parm, value, lul_device)
        end
      end
      resultCode = true
      resultString = ''

    end
  end
  -- return format should be  ok, response, error_msg
  return resultCode,jobReturnCodes_Done,string.format(resultCode and 'action call success %s' or 'action call error %s',resultString or '')
end
function copy_obj(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy_obj(k, s)] = copy_obj(v, s) end
  return res
end
-- -------------------------------------------------------------------------
-- Utilities
-- -------------------------------------------------------------------------
function try(f, catch_f)
  local status, exception = pcall(f)
  if not status then
    catch_f(exception)
  end
end
-- -------------------------------------------------------------------------
-- Prints tables and objects recursively
--
function print_r( t,prefix,lvl)
  prefix = prefix or '.'
  local output_string = desc or ''
  local print_r_cache={}
  local function sub_print_r(t,indent,prefix,lvl)
    if (print_r_cache[tostring(t)]) then
      log(indent.."*"..tostring(t),lvl)
    else
      print_r_cache[tostring(t)]=true
      if (type(t)=="table") then
        for pos,val in pairs(t) do
          if (type(val)=="table") then
            log(prefix .. indent.."["..pos.."] => "..tostring(t).." {",lvl)
            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8),prefix,lvl)
            log(prefix .. indent..string.rep(" ",string.len(pos)+6).."}",lvl)
          elseif (type(val)=="string") then
            log(prefix .. indent.."["..pos..'] => "'..val..'"',lvl)
          else
            log(prefix .. indent.."["..pos.."] => "..tostring(val),lvl)
          end
        end
      else
        log(prefix .. indent..tostring(t),lvl)
      end
    end
  end
  if (type(t)=="table") then
    log(prefix..tostring(t).." {",lvl)
    sub_print_r(t,"  ",prefix,lvl)
    log(prefix.."}",lvl)
  else
    sub_print_r(t,"  ",prefix,lvl)
  end
end

-- -------------------------------------------------------------------------
-- Queue support functions
--

function ListNew ()
  return {first = 0, last = -1, count = 0}
end
function List.pushleft (list, value)
  local first = list.first - 1
  list.count = list.count + 1
  list.first = first
  list[first] = value
end

function List.pushright (list, value)
  local last = list.last + 1
  list.count = list.count + 1
  list.last = last
  list[last] = value
end

function List.popleft (list)
  local first = list.first
  list.count = list.count - 1
  if first > list.last then
    return nil
  end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

function List.popright (list)
  local last = list.last
  list.count = list.count - 1
  if list.first > last then
    return nil
  end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end
function List.count(list)
  if(list == nil or list.count == nil) then return 0 end
  return list.count or 0
end
-- -------------------------------------------------------------------------
-- Tracing, debugging functions
--
tracelevel.INFO = 0
tracelevel.DEBUG = 1
tracelevel.TRACE = 2
tracelevel.ERROR = -1
tracelevel.WARNING = -2
local levelText = {}
levelText[tracelevel.ERROR] = "ERROR"
levelText[tracelevel.WARNING] = "WARNING"
levelText[tracelevel.INFO] = "INFO"
levelText[tracelevel.DEBUG] = "DEBUG"
levelText[tracelevel.TRACE] = "TRACE"
parms.LogLevel = tracelevel.INFO

function log(text, level)
  local w = debug.getinfo(2, "Sl")
  local lvlText = levelText[level] or 'UNKNOWN'
  local short_src = w.short_src or 'L_PioneerReceiver1'
  local linedefined = w.currentline or 'UNKNOWN'

  try(function()
    if(level == nil) then level = tracelevel.INFO end
    if(parms.LogLevel == nil) then parms.LogLevel = tracelevel.INFO end
    if((type(level)=="string")) then level = tonumber(level) end
    if((type(parms.LogLevel)=="string")) then parms.LogLevel = tonumber(parms.LogLevel) end
    if(parms.LogLevel >= level) then
      text = text or ''
      luup.log(string.format('%s: [%s:%s] %s',lvlText, short_src, linedefined,text))
    end
  end,
  function(e)
    luup.log(string.format('%s: [%s:%s] %s','EXCEPTION: ', short_src, linedefined,e))
    debug.traceback()
    luup.log(string.format('%s: [%s:%s] %s','EXCEPTION-text: ', short_src, linedefined,text))
    -- Except block. E.g.:
    -- Use e for conditional catch
    -- Re-raise with error(e)
  end
  )

end

function set_query_enable(key,enable_flag)
  if(key ~= nil and enable_flag ~= nil and fmt.variables_map[key]) then
    fmt.variables_map[key]['enabled'] = enable_flag
  else
    log(string.format('Error. Could set query enable flag for key %s enable flag %s', key or '?', enable_flag or '?'),tracelevel.ERROR)
  end
end

function get_query_enable(key)
  if(key ~= nil and fmt.variables_map[key]['enabled'] ~= nil) then
    return fmt.variables_map[key]['enabled']
  else
    log(string.format('Error. Could get query enable flag for key %s', key or '?'),tracelevel.ERROR)
  end
  return true
end

function is_expired(object)
  local current_ms = get_current_ms()
  local command_expiry = object["expiry"]
  if( command_expiry ~= nil and current_ms > command_expiry ) then
    return true
  else
    return false
  end
end
function set_expiry_s(object, delay)
  set_expiry_ms(object, delay*1000)
end

function set_expiry_ms(object, delay_ms)
  local current_ms = get_current_ms()
  local expTime = socket.gettime() + delay_ms
  object["expiry"]=expTime
end

function push_expiry_ms(object,delay_ms)
  local command_expiry = object["expiry"]
  if( command_expiry ~= nil  ) then
    -- calculate the offset based on the current time
    local newdelay =   command_expiry-get_current_ms() + delay_ms
    if(newdelay > 0) then     set_expiry_ms(object,newdelay) end
  else
    set_expiry_ms(object,delay_ms)
  end
end

function is_action_value_valid(subservice,command)
  return subservice ~= nil and command ~= nil and service_map[subservice] ~= nil and service_map[subservice][command] ~= nil
end

-- build a reverse lookup index
for key,value in pairs(fmt.variables_map) do
  if(value.prefix ~= nil) then
    responseMap[value.prefix] = value
  end
end
