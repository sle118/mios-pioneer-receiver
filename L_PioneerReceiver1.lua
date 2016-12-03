module("L_PioneerReceiver1", package.seeall)
-- some code loosely adapted from http://code.mios.com/trac/mios_squeezebox/browser



local socket = require("socket")
local get_current_ms = function () return socket.gettime()*1000 end
local is_debug = true
local pendingResponse = {}

globals = {
  serviceName = 'urn:micasaverde-com:serviceId:PioneerReceiver1',
  ipAddress = "",
  port = 0,
  altuiservice="urn:upnp-org:serviceId:altui1",
  ipAddressRaw = ""
}

fmt = require("L_PioneerReceiverFormats")
if(package.loaded.L_PioneerReceiverFormats == nil ) then
  luup.log('PioneerReceiver plugin failed loading, formats package failed')
  return nil
end
fmt.default_service = globals.serviceName

parms = {
  LogLevel = 0,
  RefreshRate = 1200, -- since the plugin maintains a connection to the amplifier, there really is no need to query more often
  QueueDelay_ms = 100, -- according to docs, 100 ms is the min interval
  command_timeout_ms = 400,
  DisplayLine1Format = "Source: %Source%",
  DisplayLine2Format = "Mute: %Mute%",
  default_port = "23",
  max_timeout_count = 3, -- max timeout for individual parameters.  assuming that more timeouts means unsupported
  ip_monitor_delay = 5 -- the ip address of the device is monitored every x (seconds) for changes
}

List = {}
commandQueue = {}
CurrentRequest = {}
tracelevel = {}
jobReturnCodes = {
  WaitingToStart = 0, -- =job_WaitingToStart: In vera's UI a job in this state is
  -- displayed as a gray icon. It means it's waiting to start.
  -- If you return this value your 'job' code will be run again
  -- in the 'timeout' seconds
  Error = 2,
  Aborted = 3,     -- In vera's UI a job in this state (2 or 3) is displayed as a red icon. This means the job failed. Your code won't be run again.
  Done = 4,      -- In vera's UI a job in this state is displayed as a green icon. This means the job finished ok. Your code won't be run again.
  WaitingForCallback = 5-- In vera's UI a job in this state is displayed as a moving blue icon. This means the job is running and you're waiting for return data.
}


-- -------------------------------------------------------------------------
-- This function parses/validates an ip address format and returns it
-- with a split port number.  If no port number is specified, a default
-- port is returned instead.
--
local function parse_ip_address(ip_string, default_port)
  local address,port = string.match(ip_string or '?',"(%d+%.%d+%.%d+%.%d+):*(%d*)")
  return address, tonumber(port~=nil and port:len()>0 and port or default_port and default_port:len()>0 and default_port or parms.default_port)
end

-- -------------------------------------------------------------------------
-- This function will queue commands to retrieve all known status of the amp
--
function _G.query_status(lul_device)
  log("Called to initiate status refresh from device. ", tracelevel.INFO)

  if(globals.ipAddress ~= nil) then
    if commandQueue.count == 0 then
      log('Preparing items to query...',tracelevel.DEBUG)
      if(fmt.variables_map ~= nil) then
        for key,curElement in pairs(fmt.variables_map) do
          if(curElement.enabled and curElement.command ) then
            curElement.key = key
            List.pushleft(commandQueue,curElement)
          end
        end
      else
        log('No active query command found.', tracelevel.WARNIG)
      end
      if(commandQueue ~= nil and commandQueue.count ~= 0 ) then
        --print_r(commandQueue,"commandQueue",tracelevel.TRACE)
        local resultCode, resultString, job, returnArguments = luup.call_action(globals.serviceName, "processQueue", {}, type(lul_device)=='string' and tonumber(lul_device) or lul_device)
        print_r({resultcode = resultCode, resultString= resultString, job=job,returnArguments=returnArguments},"call_action return ",tracelevel.TRACE)
      end

    else
      log(string.format('The command queue still has %s elements to process',tostring(commandQueue.count)),tracelevel.TRACE)
    end
  else
    log('No ip address setup. Ignoring current refresh request.', tracelevel.WARNING)
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
    local format_val = try_get_var (globals.serviceName, format_var, lul_device, parms[format_var])

    for token in string.gmatch(format_val, "%%[^%%]*%%") do
      -- substitute all variable names from the format string
      local serviceVar = token:gsub("%%","")
      local value = try_get_var (globals.serviceName, serviceVar, lul_device, '?')
      format_val = format_val:gsub('%'..token..'%',value)
    end
    -- statusLine are an altui service, update with the new value
    setIfChanged(globals.altuiservice,whichVariable,format_val,lul_device)
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
  if(parms[lul_Variable] and parms[lul_Variable]~=nil) then
    -- this a parameter which we are tracking locally, so save value
    parms[lul_Variable] = lul_NewValue
  end
  update_status_line(lul_device,1)
  update_status_line(lul_device,2)
end


-- -------------------------------------------------------------------------
-- Update variable if changed
-- Return true if changed or false if no change
--
function setIfChanged(serviceId, name, value, deviceId)
  if(serviceId == nil or name == nil or deviceId == nil or deviceId == 0 ) then
    log(string.format('Missing parameter : serviceId=%s, variable=%s, value=%s, device=%s',serviceId or 'MISSING',name or 'MISSING',value or '',tostring(deviceID or '')), tracelevel.ERROR )
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
    log(string.format("%s, sending  %s ",command.key or '?', command.command or '?'), tracelevel.INFO)
    -- -- Send the code to the receiver
    if(try_connect(lul_device)) then

      if( false == luup.io.write(command.command)) then
        log("failure when sending command : " .. command.command, tracelevel.ERROR)
        luup.set_failure(1)
        return false
      end
    else
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

  return jobReturnCodes.Done,nil,true
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
    for key,value in pairs(fmt.variables_map) do
      if(value.prefix and lul_data:len() >= value.prefix:len() and lul_data:sub(1,value.prefix:len()) == value.prefix) then
        map = value
        local val =fmt.get_value(lul_data,map.prefix) or lul_data
        for skey,service in pairs(map.services or {}) do
          converted = service.convert and service.convert(val,lul_device) or val
          log(string.format('%s, receiving var: %s, value:  %s',key or '?',service.var or '?', tostring(converted) or '?'), tracelevel.INFO)
          if(service.var ) then
            --log(string.format('Value %s = %s ',map.var, converted or '?'), tracelevel.DEBUG)
            setIfChanged(skey, service.var, converted, lul_device)
          end
        end
        if(CurrentRequest.key and key == CurrentRequest.key) then
          -- unmark current request as is now processed
          CurrentRequest = {}
        elseif ( map.prefix and CurrentRequest.c_pfix and map.prefix == CurrentRequest.c_pfix) then
          CurrentRequest = {}
        end
        break
      end
    end
    if(map == nil) then
      log(string.format('No conversion map for value %s',lul_data or '?'), tracelevel.WARNING)
      setIfChanged(globals.serviceName, 'last_unknown_message', lul_data, lul_device)
    end
  end
  if(CurrentRequest.key == nil) then
    process_queue(lul_device,lul_settings,0)
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
  local map = key~=nil and fmt.variables_map[key] or {}
  local error = fmt.errors_map[lul_data]
  if(error == nil) then return nil end

  log(string.format('%s,          code %s, error : %s',key or '?' ,map.command or '?',error.description),tracelevel.ERROR)
  if(error.requeue and CurrentRequest ~= nil  ) then
    -- if the resource was busy, resend the command in the queue
    -- so that it can be reprocessed right away
    List.pushright(commandQueue,CurrentRequest)
  end
  if(error.save_message and map ~=nil) then
    for skey,service in pairs(map.services or {}) do
      if(service.var ) then setIfChanged(skey, service.var, string.format('%s=>%s',map.command or '?', error.description or '?'), lul_device)        end
    end
  end
  if( error.disable and map ~= nil and var ~= nil ) then
    -- We need to disable querying this variable since there was a fatal error
    set_query_enable(key,false)
    --setIfChanged(globals.serviceName, var, error.description, lul_device)
  end
  -- unmark current request so it doesn't time out.
  CurrentRequest = {}
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

  log('processQueue processing',tracelevel.DEBUG)
  local returnCode = jobReturnCodes.Done
  local submitDelay = nil

  if(CurrentRequest.key ~= nil ) then
    if(is_expired(CurrentRequest)) then
      local timeout_count = fmt.variables_map[CurrentRequest.key].timeout_count or 0
      timeout_count = timeout_count + 1
      fmt.variables_map[CurrentRequest.key].timeout_count = timeout_count
      log(string.format('%s, timeout count is %i',CurrentRequest.key or '?',timeout_count),tracelevel.WARNING)
      -- re-queue the request

      if(fmt.variables_map[CurrentRequest.key].timeout_count <= parms.max_timeout_count ) then
        List.pushright(commandQueue,CurrentRequest)
      end
      -- reset current request
      CurrentRequest = {}
      submitDelay = parms.QueueDelay_ms / 1000
    end
  end
  if (  CurrentRequest.key==nil ) then
    if(commandQueue.count > 0 ) then
      local command = List.popleft(commandQueue)
      print_r(command,string.format('Queue has %u elements to process. Current command : ',commandQueue.count) ,tracelevel.TRACE)
      if(sendCommand(command, lul_device, command, lul_job)) then
        CurrentRequest = copy_obj(command)
        set_expiry_ms(CurrentRequest, (CurrentRequest.prefix ~=nil or CurrentRequest.c_pfix ~=nil) and parms.command_timeout_ms or .01)
        submitDelay = parms.QueueDelay_ms / 1000
        luup.set_failure(0)
      else
        log('run queue job did not succeed',tracelevel.ERROR)
        submitDelay = parms.QueueDelay_ms / 1000
        returnCode= jobReturnCodes.Error
        luup.set_failure(1)
      end
    else
      log('Queue processing Done',tracelevel.INFO)
      submitDelay=0
    end
  else
    log('Current command not complete',tracelevel.DEBUG)
  end

  if(submitDelay ~= nil and submitDelay>0 and lul_job ~= 0) then
    delay_process_queue(lul_device,submitDelay)
  end


  -- we are resubmitting the queue processing job ourselves, so we're going to set the timeout to 0 so vera doesn't call back
  return returnCode,0
end

-- -------------------------------------------------------------------------
--
--
function delay_process_queue(lul_device,delay)
  local calculated_delay = math.ceil(delay  or (luup.io.is_connected() and parms.QueueDelay_ms ) )
  if( luup.call_delay ('process_queue', calculated_delay , lul_device) ~= 0) then
    log('FATAL setting up a call delay to process queue',tracelevel.ERROR)
    luup.set_failure(1)
    return false
  else
    log(string.format('Process queue will run in %u (s) ',calculated_delay),tracelevel.TRACE)
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
    luup.set_failure(1)
    return false
  else
    log(string.format('Status query will run in %u (s) ',calculated_delay),tracelevel.DEBUG)
    return true
  end
end


-- -------------------------------------------------------------------------
-- Gets a parameter value (or default) and monitor for changes
--
function get_typed_parameter(name,lul_device,default)
  local cast = default == "nil" and tostring or
    type(default) == "number" and tonumber or
    type(default) == "string" and tostring or
    type(default) ==  "boolean" and function(e) return e==nil and false or type(e) == 'string' and (e=='1' or e=='X') and true or type(e) == 'number' and e>0  and true or false end or
    -- TODO : this could be helpful for storing compressed parameters
    --        type(default) == "table" and parse_json
    nil
  local value = try_get_var(globals.serviceName, name, lul_device, default)
  return cast and cast(value) or value
end
-- -------------------------------------------------------------------------
-- Monitors ip address change and reset the plugin if this happens
--
function _G.monitor_ip_address(lul_device, startup)

  local result = true
  local ipAddressRawNew = luup.attr_get("ip",lul_device)
  local ipAddressNew,portNew = parse_ip_address(ipAddressRawNew, parms.default_port)
  log(string.format('Ip check. old is %s, new is %s',globals.ipAddress or '?', ipAddressNew or '?'),tracelevel.TRACE)
  if(ipAddressRawNew and ipAddressRawNew ~= globals.ipAddressRaw) then
    -- change of ip address which we need to take care of
    if(startup ~= true) then
      -- need to reset the process queue and re-scan the device
      log(string.format('Ip address was changed from %s to %s. Restarting plugin',globals.ipAddressRaw or '?', ipAddressRawNew),tracelevel.INFO)
      CurrentRequest = {}
      if(commandQueue ~= nil and commandQueue.count ~= 0 ) then
        commandQueue = ListNew()
      end
      -- now reset all query variables to true to probe the new device
      set_query_all(true)
    end

    -- save the new address
    globals.ipAddress = ipAddressNew
    globals.port = portNew
    globals.ipAddressRaw = ipAddressRawNew
    -- schedule a status query
    if(delay_query_status(lul_device,1) ~= true) then
      luup.set_failure(1)
      result = false
    end

    if(not try_connect(lul_device, true)) then
      result = false
    end

  end

  -- reschedule  address change monitoring
  if(luup.call_delay ('monitor_ip_address', parms.ip_monitor_delay , lul_device) ~= 0) then
    log('FATAL setting up a call delay to monitor ip address',tracelevel.ERROR)
    luup.set_failure(1)
    result = false
  end
  return result
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

  globals.serviceName = serviceName
  log('Initializing...',tracelevel.INFO)
  commandQueue = ListNew()

  -- register a few variables which we want to monitor specifically
  parms.LogLevel =  get_typed_parameter("LogLevel",lul_device, is_debug and tracelevel.DEBUG or tracelevel.INFO)
  parms.RefreshRate =  get_typed_parameter("RefreshRate",lul_device,parms.RefreshRate)
  parms.QueueDelay_ms  =  get_typed_parameter("QueueDelay_ms",lul_device,parms.QueueDelay_ms)
  parms.DisplayLine1Format = get_typed_parameter("DisplayLine1Format",lul_device,parms.DisplayLine1Format)
  parms.DisplayLine2Format = get_typed_parameter("DisplayLine2Format",lul_device,parms.DisplayLine2Format)
  parms.command_timeout_ms = get_typed_parameter("command_timeout_ms",lul_device,parms.command_timeout_ms)

  -- register for all variable changes
  luup.variable_watch("parameter_changed",globals.serviceName, nil,lul_device)

  monitor_ip_address(lul_device, true)
  if (globals.ipAddress ~= nil) then
    log(string.format("Running Network Attached on %s:%s", globals.ipAddress or '?', tostring(globals.port or 0)),tracelevel.INFO)
  else
    log("IP address missing.",tracelevel.WARNIG)
  end

  log("Initializing complete.",tracelevel.INFO)
  return true,'ok','L_PioneerReceiver1'
end

-- -------------------------------------------------------------------------
-- Connects and/or checks that the connection can be established
--
function try_connect(lul_device, force)
  if( globals.ipAddress ~= nil and (not luup.io.is_connected() or force~= nil and force) ) then
    log(string.format('Connecting to %s:%s',globals.ipAddress,globals.port),tracelevel.INFO)
    luup.io.open(lul_device, globals.ipAddress, globals.port)
  end
  if( not luup.io.is_connected() ) then
    luup.set_failure(1)
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
  local service = fmt.service_map[lul_settings.serviceId or '?']
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
          List.pushright(commandQueue,code)
        else
          List.pushleft(commandQueue,code)
        end
        if(commandQueue.count <= 1 ) then
          -- nothing processing currently. add a wakeup command and process queue
          List.pushright(commandQueue,fmt.variables_map["WAKE"])
          luup.call_action(globals.serviceName, "processQueue", {}, type(lul_device)=='string' and tonumber(lul_device) or lul_device)
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
  return resultCode,jobReturnCodes.Done,string.format(resultCode and 'action call success %s' or 'action call error %s',resultString or '')
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
levelText[tracelevel.ERROR] =   "ERROR  "
levelText[tracelevel.WARNING] = "WARNING"
levelText[tracelevel.INFO] =    "INFO   "
levelText[tracelevel.DEBUG] =   "DEBUG  "
levelText[tracelevel.TRACE] =   "TRACE  "
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

function set_query_all(enable_flag)
  enable_flag = enable_flag or true
  log(string.format('Changing query enable flag for ALL keys to %s', tostring(enable_flag)),tracelevel.DEBUG)
  for k,v in pairs(fmt.variables_map) do
    set_query_enable(k,enable_flag)
  end

end

function set_query_enable(key,enable_flag)
  if(key ~= nil and fmt.variables_map[key]) then
    log(string.format('Changing query enable flag for %s to %s', key or '?',tostring(enable_flag)),tracelevel.TRACE)
    fmt.variables_map[key].enabled = enable_flag
  else
    log(string.format('Error. Could set query enable flag for key %s enable flag %s', key or '?', enable_flag or '?'),tracelevel.ERROR)
  end
end

function get_query_enable(key)
  if(key ~= nil and fmt.variables_map[key].enabled ~= nil) then
    return fmt.variables_map[key].enabled
  else
    log(string.format('Error. Could get query enable flag for key %s', key or '?'),tracelevel.ERROR)
  end
  return true
end

function is_expired(object)
  local current_ms = get_current_ms()
  local command_expiry = object.expiry
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
  object.expiry=expTime
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
  return subservice ~= nil and command ~= nil and fmt.service_map[subservice] ~= nil and fmt.service_map[subservice][command] ~= nil
end

