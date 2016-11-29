--  local dev = luup.create_device ('', '', "SqueezeBox", "D_SqueezeboxControl1.xml", "I_SqueezeboxControl1.xml")  --  create the device
--  luup.variable_set ("urn:micasaverde-com:serviceId:SqueezeBox1", "serverIP", "192.168.10.201", dev)    -- set SqueezeBox Server IP address
--module("L_PioneerReceiver1", package.seeall)


-- some code loosely adapted from http://code.mios.com/trac/mios_squeezebox/browser
local _pr = {}
_pr.fmt = require("L_PioneerReceiverFormats")
local socket = require("socket")
local get_current_ms = function () return socket.gettime()*1000 end
_pr.tracelevel = {}
local is_debug = true

_pr.serviceName = 'urn:micasaverde-com:serviceId:PioneerReceiver1'
_pr.altuiservice="urn:upnp-org:serviceId:altui1"
local pendingResponse = {}
_pr.ipAddress = ""
_pr.parms = {}
_pr.parms.LogLevel = 0
_pr.ResponseTimeout = 1
_pr.parms.RefreshRate = 1200 -- since the plugin maintains a connection to the amplifier, there really is no need to query more often
_pr.parms.Status = 0
_pr.parms.QueueDelay_ms = 300 -- according to docs, 100 ms is the min interval, but polling at that rate would flood the amplifier
_pr.parms.DisplayLine1Format = "Source: %Source%"
_pr.parms.DisplayLine2Format = "Mute: %Mute%"
_pr.List = {}
_pr.commandQueue = {}
_pr.CurrentRequest = {}

_pr.jobReturnCodes_WaitingToStart = 0 -- =job_WaitingToStart: In vera's UI a job in this state is
-- displayed as a gray icon. It means it's waiting to start.
-- If you return this value your 'job' code will be run again
-- in the 'timeout' seconds
_pr.jobReturnCodes_Error = 2
_pr.jobReturnCodes_Aborted = 3     -- In vera's UI a job in this state (2 or 3) is displayed as a red icon. This means the job failed. Your code won't be run again.
_pr.jobReturnCodes_Done = 4      -- In vera's UI a job in this state is displayed as a green icon. This means the job finished ok. Your code won't be run again.
_pr.jobReturnCodes_WaitingForCallback = 5-- In vera's UI a job in this state is displayed as a moving blue icon. This means the job is running and you're waiting for return data.



-- -------------------------------------------------------------------------
-- This is a global wrapper around the module's process queue
--
function process_queue(lul_device,lul_settings,lul_job)
  _pr.process_queue(lul_device,lul_settings,lul_job)
end

-- -------------------------------------------------------------------------
-- This function will queue commands to retrieve all known status of the amp
--
function query_status(lul_device)
  _pr.log("Called to queue query status. ", _pr.tracelevel.DEBUG)

  if(_pr.ipAddress ~= nil) then
    if _pr.commandQueue.count == 0 then
      _pr.log('Preparing items to query...',_pr.tracelevel.DEBUG)
      if(_pr.fmt.variables_map ~= nil) then
        for key,curElement in pairs(_pr.fmt.variables_map) do
          if(curElement["enabled"] ) then
            curElement['key'] = key
            _pr.List.pushright(_pr.commandQueue,curElement)
          end
        end
      else
        _pr.log('No active query command found.', _pr.tracelevel.WARNIG)
      end
      if(_pr.commandQueue ~= nil and _pr.commandQueue.count ~= 0 ) then
        _pr.print_r(_pr.commandQueue,"commandQueue",_pr.tracelevel.TRACE)
        local resultCode, resultString, job, returnArguments = luup.call_action(_pr.serviceName, "processQueue", {}, lul_device)
      end

    else
      _pr.log(string.format('The command queue still has %s elements to process',tostring(_pr.commandQueue.count)),_pr.tracelevel.TRACE)
    end

  end
  _pr.delay_query_status(lul_device)

end

-- -------------------------------------------------------------------------
-- This function attemps to retrieve a device variable and sets it to a
-- default it's not found
--
local function try_get_var (sid, varname, device, default)

  device = device or 'unknown'
  varname = varname or 'unknown'
  _pr.log(string.format('Getting value %s for device %s with default %s',varname or '?',device or '?', tostring(default or '?') ),_pr.tracelevel.DEBUG)

  local var_val = luup.variable_get (sid, varname, device)
  if nil == var_val then
    _pr.log(string.format("no value found for device %s variable %s", device, varname) ,_pr.tracelevel.DEBUG)
    if(default ~= nil) then
      luup.variable_set (sid, varname, default, device)
    end
    var_val = default
  else
    _pr.log(string.format("value %s found for device %s variable %s", tostring(var_val), device, varname) ,_pr.tracelevel.DEBUG)
  end
  return var_val
end

-- -------------------------------------------------------------------------
-- this will update the status lines for alt-ui
--
 function _pr.update_status_line(lul_device,index)

  _pr.try(function()
      -- ",
      --      "Variable": "DisplayLine1",
      local whichVariable = string.format('DisplayLine%i',index)
      local format_var = whichVariable..'Format'
      local format_val = try_get_var (_pr.altuiservice, format_var, lul_device, _pr.parms[format_var])
      
      for token in string.gmatch(format_val, "%%[^%%]*%%") do 
        local serviceVar = token:gsub("%%","")
        local value = try_get_var (_pr.serviceName, serviceVar, lul_device, '?')
        format_val = format_val:gsub('%'..token..'%',value)
        _pr.setIfChanged(_pr.altuiservice,whichVariable,format_val,lul_device)
      end
  end,
  function(e)
    _pr.log(string.format('formatting status line %i failed with return %s', index, e))
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
function _pr.parameter_changed(lul_device,lul_Service,lul_Variable,lul_OldValue,lul_NewValue)
  _pr.log(string.format("variable %s changing from %s to %s",lul_Variable,lul_OldValue,lul_NewValue),_pr.tracelevel.TRACE)
  _pr.parms[lul_Variable] = lul_NewValue
  _pr.update_status_line(lul_device,1)
  _pr.update_status_line(lul_device,2)
end


-- -------------------------------------------------------------------------
-- Update variable if changed
-- Return true if changed or false if no change
--
function _pr.setIfChanged(serviceId, name, value, deviceId)
  if name == nil then
    _pr.log('variable name was nil',_pr.tracelevel.ERROR)
    return false
  end
  local curValue = luup.variable_get(serviceId, name, deviceId)
  if ((value ~= curValue) or (curValue == nil)) then
    _pr.log(string.format(" Updated value of %s from %s to %s  ",name, curValue or ' ', value or ' '),_pr.tracelevel.TRACE)
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
function _pr.sendCommand(command, lul_device, lul_settings, lul_job)
  if( command ~= nil and command.command ~= nil) then
    _pr.log(string.format("sending command %s ",command.command or '?'), _pr.tracelevel.DEBUG)
    -- -- Send the code to the receiver
    if( false == luup.io.write(command.command)) then
      _pr.log("failure when sending command : " .. command.command, _pr.tracelevel.ERROR)
      luup.set_failure(true)
      return false
    end
  else
    _pr.log("no command provided.", _pr.tracelevel.ERROR)
  end

  return true
end

-- -------------------------------------------------------------------------
-- Receives data from the io port and dispatches to a data mapper
--
function _pr.process_response(lul_device, lul_settings, lul_job, lul_data)
  local newVal = lul_data or 'N/A'

  _pr.log(string.format('PioneerReceiver incoming data : %s ', lul_data or ''),_pr.tracelevel.TRACE)

  if(lul_data ~= nil) then
    if(lul_data == 'R') then
      _pr.log('Received ACK', _pr.tracelevel.DEBUG)
    else

      _pr.map_response(lul_data, lul_device)
    end
  else
    _pr.log('Received null data', _pr.tracelevel.ERROR)
  end

  return _pr.jobReturnCodes_Done,nil,true
end

-- -------------------------------------------------------------------------
--
--
function _pr.map_response(lul_data,lul_device)
  local map = nil
  local converted = nil
  local var = _pr.CurrentRequest ~= nil and _pr.CurrentRequest.var ~= nil and  _pr.CurrentRequest.var or ''
  local key = _pr.CurrentRequest ~= nil and _pr.CurrentRequest.key ~= nil and  _pr.CurrentRequest.key or ''

  if(_pr.handle_error(lul_data,lul_device, var,key) == nil) then
    for key,value in pairs(_pr.responseMap) do
      if(lul_data:len() >= key:len() and lul_data:sub(1,key:len()) == key) then
        map = value
        local val = _pr.fmt.get_value(lul_data,map.prefix) or lul_data
        for skey,service in pairs(map.services or {}) do
          converted = service.convert and service.convert(val,lul_device) or val
          _pr.log(string.format('Value for variable %s : %s => %s',service.var or '?', val,converted or '?'), _pr.tracelevel.DEBUG)
          if(service.var ) then
            --_pr.log(string.format('Value %s = %s ',map.var, converted or '?'), _pr.tracelevel.DEBUG)
            _pr.setIfChanged(skey, service.var, converted, lul_device)
            if(map.key and _pr.CurrentRequest and _pr.CurrentRequest.key and map.key == _pr.CurrentRequest.key) then
              -- unmark current request as is now processed
              _pr.CurrentRequest = nil
            end
          end
        end
        break
      end
    end
    if(map == nil) then
      _pr.log(string.format('No conversion map for value %s',lul_data or '?'), _pr.tracelevel.WARNING)
      _pr.setIfChanged(_pr.serviceName, 'last_unknown_message', lul_data, lul_device)
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
function _pr.handle_error(lul_data,lul_device,var,key)

  lul_data = lul_data or '?'
  lul_device = lul_device or '?'
  var = var or '?'
  key = key or '?'

  local error = _pr.errors_map[lul_data]
  if(error == nil) then return nil end

  _pr.log(string.format('%s when processing command %s',error.description,key or '?' ),_pr.tracelevel.ERROR)
  if(error.requeue and _pr.CurrentRequest ~= nil  ) then
    -- if the resource was busy, resend the command in the queue
    -- so that it can be reprocessed right away
    _pr.List.pushleft(_pr.commandQueue,_pr.CurrentRequest)
  end
  if(error.save_message) then
    _pr.setIfChanged(_pr.serviceName, var, error.description, lul_device)
  end
  if( error.disable and key ~= nil and var ~= nil ) then
    -- We need to disable querying this variable since there was a fatal error
    _pr.set_query_enable(key,false)
    _pr.setIfChanged(_pr.serviceName, var, error.description, lul_device)
  end
  -- unmark current request so it doesn't time out.
  _pr.CurrentRequest = nil
  return error
end



-- -------------------------------------------------------------------------
-- This function reads the queue and processes any pending command.
--
-- It will re-submit itself with the following delays
--    no more command :               no re-submit
--    command was sent successfully : _pr.ResponseTimeout to allow receiving
--                                    response from the amplifier
--    send failure :                  idle refresh rate - if send failed,
--                                    we're going to throttle
--
function _pr.process_queue(lul_device,lul_settings,lul_job)
  -- ***** doc
  -- wrapper is
  -- function job(lul_device, lul_settings, lul_job)
  --    luup.log('device: ' .. tostring(lul_device) .. ' value: ' .. tostring(lul_settings.newTargetValue) .. ' job ID#: ' .. lul_job)
  --    -- 5 = job_WaitingForCallback
  --    -- and we'll wait 10 seconds for incoming data
  --    return 5, 10
  -- end
  -- ***** end doc
  _pr.log('processQueue processing',_pr.tracelevel.DEBUG)
  local returnCode = _pr.jobReturnCodes_Done
  local submitDelay = nil
  if(_pr.CurrentRequest ~= nil and _pr.CurrentRequest.key ~= nil) then
    _pr.log(string.format('last command %s for variable %s did not receive response',_pr.CurrentRequest.command or '?', _pr.CurrentRequest.var or '?'),_pr.tracelevel.WARNING)
    -- turn off that option to avoid flooding the device with unsupported queries
    _pr.set_query_enable(_pr.CurrentRequest.key,false)
    -- reset current request
    _pr.CurrentRequest = nil
  end
  if _pr.commandQueue.count > 0 then
    local command = _pr.List.popleft(_pr.commandQueue)
    _pr.print_r(command,string.format('Queue has %u elements to process. Current command : ',_pr.commandQueue.count) ,_pr.tracelevel.TRACE)
    if(_pr.sendCommand(command, lul_device, command, lul_job)) then
      -- the response should come really quick
      _pr.log('run queue job success',_pr.tracelevel.TRACE)
      _pr.CurrentRequest = command
      returnCode= _pr.jobReturnCodes_WaitingForCallback
      submitDelay = _pr.parms.QueueDelay_ms / 1000
    else
      _pr.log('run queue job did not succeed',_pr.tracelevel.ERROR)
      submitDelay = _pr.parms.RefreshRate
      returnCode= _pr.jobReturnCodes_Error
    end

  else
    _pr.log('Nothing in the queue',_pr.tracelevel.DEBUG)
    returnCode= _pr.jobReturnCodes_Done
    submitDelay=0
  end
  if(submitDelay ~= nil and submitDelay>0 ) then
    _pr.delay_process_queue(lul_device,submitDelay)
  end

  return returnCode,submitDelay
end

-- -------------------------------------------------------------------------
--
--
function _pr.delay_process_queue(lul_device,delay)
  local calculated_delay = delay or tonumber((luup.io.is_connected and _pr.parms.QueueDelay_ms ) )
  if( luup.call_delay ('process_queue', calculated_delay , lul_device) ~= 0) then
    _pr.log('FATAL setting up a call delay to process queue',_pr.tracelevel.ERROR)
    luup.set_failure(true)
    return false
  else
    _pr.log(string.format('Process queue will run in %u (s) ',calculated_delay),_pr.tracelevel.TRACE)
    luup.set_failure(false)
    return true
  end
end

-- -------------------------------------------------------------------------
--
--
function _pr.delay_query_status(lul_device,delay)
  local calculated_delay = delay or tonumber(_pr.parms.RefreshRate or 60*20 )
  if(luup.call_delay ('query_status', calculated_delay , lul_device) ~= 0) then
    _pr.log('FATAL setting up a call delay to query status',_pr.tracelevel.ERROR)
    luup.set_failure(true)
    return false
  else
    _pr.log(string.format('Status query will run in %u (s) ',calculated_delay),_pr.tracelevel.DEBUG)
    luup.set_failure(false)
    return true
  end
end

-- -------------------------------------------------------------------------
-- Gets a parameter value (or default) and monitor for changes
--
function _pr.register_parameter(name,lul_device,default)
  local value = try_get_var(_pr.serviceName, name, lul_device, default)
  luup.variable_watch("parameter_changed",_pr.serviceName, name,lul_device)
  return value
end
-- -------------------------------------------------------------------------
-- Monitors ip address change and reset the plugin if this happens
--
function handle_ipaddress_change(lul_device)
  local ipAddress = string.match(luup.attr_get("ip",lul_device) or '?',"(%d+%.%d+%.%d+%.%d+)")
  if(ipAddress and _pr.ipAddress and ipAddress ~= _pr.ipAddress ) then
    -- change of ip address which we need to take care of
    _pr.log(string.format('Ip address was changed from %s to %s. Restarting plugin',_pr.ipAddress or '?', ipAddress),_pr.tracelevel.INFO)
    _pr.CurrentRequest = nil
    if(_pr.commandQueue ~= nil and _pr.commandQueue.count ~= 0 ) then
      _pr.commandQueue = _pr.ListNew()
    end
    -- save the new address
    _pr.ipAddress = ipAddress
    _pr.try_connect(lul_device, false)
    -- trigger new status query
    _pr.delay_query_status(lul_device,1)
  end

  -- monitor address change every 5 seconds
  if(luup.call_delay ('handle_ipaddress_change', 5 , lul_device) ~= 0) then
    _pr.log('FATAL setting up a call delay to monitor ip address',_pr.tracelevel.ERROR)
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
function _pr.startup(lul_device, serviceName)
  _pr.parms.LogLevel = _pr.tracelevel.INFO
  _pr.serviceName = serviceName
  _pr.log('Initializing...',_pr.tracelevel.INFO)
  --luup.log(string.format('l_pioneerreceiver1 callback DUMP: %s',getdebug2()))
  -- for c in string.gmatch("nfSlu",".") do
  -- for i = 0, 3 do
  -- luup.log(string.format('L_PioneerReceiver1 DUMP(%u,%s): %s',i,c,getdebug(i,c)))
  -- end
  -- end

  _pr.commandQueue = _pr.ListNew()

  _pr.parms.LogLevel =  tonumber(_pr.register_parameter("LogLevel",lul_device, tostring(is_debug and _pr.tracelevel.DEBUG or _pr.tracelevel.INFO)))
  _pr.parms.RefreshRate =  tonumber(_pr.register_parameter("RefreshRate",lul_device,_pr.parms.RefreshRate))
  _pr.parms.Status = _pr.register_parameter("Status",lul_device,_pr.parms.Status)
  _pr.parms.QueueDelay_ms  =  tonumber(_pr.register_parameter("QueueDelay_ms",lul_device,_pr.parms.QueueDelay_ms))
  _pr.parms.DisplayLine1Format = _pr.register_parameter("DisplayLine1Format",lul_device,_pr.parms.DisplayLine1Format)
  _pr.parms.DisplayLine2Format = _pr.register_parameter("DisplayLine2Format",lul_device,_pr.parms.DisplayLine2Format)
  luup.variable_watch("parameter_changed",_pr.serviceName, name,lul_device)
  if (_pr.fmt == nil)  then
    _pr.log("Plugin is not installed correctly. Library L_PioneerReceiverFormats cannot be loaded.",_pr.tracelevel.ERROR)
    return false,'Start failure','L_PioneerReceiver1'
  end

  _pr.ipAddress = string.match(luup.attr_get("ip",lul_device) or '?',"(%d+%.%d+%.%d+%.%d+)")
  if (_pr.ipAddress ~= "") then
    _pr.log("Running Network Attached on " .. _pr.ipAddress,_pr.tracelevel.INFO)
    _pr.try_connect(lul_device, true)

    if(_pr.delay_query_status(lul_device,1) ~= true) then
      return false,'delay start failure','L_PioneerReceiver1'
    end
  else
    _pr.log("IP address missing.",_pr.tracelevel.WARNIG)
  end
  handle_ipaddress_change(lul_device)
  _pr.log("Initializing complete.",_pr.tracelevel.INFO)
  return true,'ok','L_PioneerReceiver1'
end

-- -------------------------------------------------------------------------
-- Connects and/or checks that the connection can be established
--
function _pr.try_connect(lul_device, disconnect)
  local TELNET_PORT = 23
  if(luup.io.is_connected ~= true and _pr.ipAddress) then
    _pr.log(string.format('Connecting to %s:%s',_pr.ipAddress,TELNET_PORT),_pr.tracelevel.INFO)
    luup.io.open(lul_device, _pr.ipAddress, TELNET_PORT)
  end
  if(luup.io.is_connected ~= true) then
    _pr.log(string.format('Connecting to the device failed. IP Address is %s',_pr.ipAddress or '?'),_pr.tracelevel.INFO)
    return false
  end
  if( disconnect == true) then
  -- d'oh!   this is not implemented in openluup??
  -- TODO:  implement!
  -- luup.io.close()
  end
  return true
end



-- -------------------------------------------------------------------------
--
--
function _pr.get_service_variabble(lul_device,  varname, lul_settings)
  local serviceName = lul_settings.serviceId or '?'
  _pr.print_r(lul_settings,"service variable data receid : ", _pr.tracelevel.DEBUG)
  -- nothing to do here, really.
  -- maybe we could poll the receiver for a refreshed value?

  return true
end

-- -------------------------------------------------------------------------
-- Queue the appropriate action based on the mapping table for this action
-- lul_device,true,"DiscretePower1", lul_settings
function _pr.queueAction(lul_device, priority,  lul_settings)
  _pr.print_r(lul_settings,"action Data : ", _pr.tracelevel.DEBUG)
  local resultCode, resultString, job, returnArguments,code
  priority = priority or false
  local service = _pr.service_map[lul_settings.serviceId or '?']
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
      code = _pr.copy_obj(action[value] and action[value] or action or '?')

      if ( code == nil or code.command == nil) then
        resultCode=false
        resultString = string.format('Invalid action %s for service %s with %s=%s (command not found)',lul_settings.action or '?',lul_settings.serviceId or '?',action.parm or '?', value or '?')
      else
        if(code.command:find("%%") and code.command:find("%%")>0) then
          -- this command is a substitute
          code.command = code.command:format(value)
        end
        _pr.log(string.format('Queuing command %s for action %s for service %s with %s=%s',code.command or '?',lul_settings.action or '?',lul_settings.serviceId or '?',action.parm or '?', value or '?'), _pr.tracelevel.DEBUG)
        if(priority == true) then
          _pr.List.pushleft(_pr.commandQueue,code)
        else
          _pr.List.pushright(_pr.commandQueue,code)
        end
        if(_pr.commandQueue.count <= 1 ) then
          -- nothing processing currently. add a wakeup command and process queue
          _pr.List.pushleft(_pr.commandQueue,_pr.fmt.variables_map["WAKE"])
          luup.call_action(_pr.serviceName, "processQueue", {}, lul_device)
        end
        if(action.parm) then
          _pr.setIfChanged(lul_settings.serviceId, action.parm, value, lul_device)
        end
      end
      resultCode = true
      resultString = ''

    end
  end



  --        if( code ~= "") then
  --        )
  --      else
  --        local resultString = try_get_var (lul_settings.serviceId or '?', varname, lul_device, nil)
  --        resultCode=false
  --        resultString = string.format('Unsupported action type %s name %s with parameter %s ',action_type_prefix or '?',action_name or '', value or '')
  --      end

  -- return format should be  ok, response, error_msg
  return resultCode,_pr.jobReturnCodes_Done,string.format(resultCode and 'action call success %s' or 'action call error %s',resultString or '')
end
function _pr.copy_obj(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[_pr.copy_obj(k, s)] = _pr.copy_obj(v, s) end
  return res
end
-- -------------------------------------------------------------------------
-- Utilities
-- -------------------------------------------------------------------------
function _pr.try(f, catch_f)
  local status, exception = pcall(f)
  if not status then
    catch_f(exception)
  end
end
-- -------------------------------------------------------------------------
-- Prints tables and objects recursively
--
function _pr.print_r( t,prefix,lvl)
  prefix = prefix or '.'
  local output_string = desc or ''
  local print_r_cache={}
  local function sub_print_r(t,indent,prefix,lvl)
    if (print_r_cache[tostring(t)]) then
      _pr.log(indent.."*"..tostring(t),lvl)
    else
      print_r_cache[tostring(t)]=true
      if (type(t)=="table") then
        for pos,val in pairs(t) do
          if (type(val)=="table") then
            _pr.log(prefix .. indent.."["..pos.."] => "..tostring(t).." {",lvl)
            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8),prefix,lvl)
            _pr.log(prefix .. indent..string.rep(" ",string.len(pos)+6).."}",lvl)
          elseif (type(val)=="string") then
            _pr.log(prefix .. indent.."["..pos..'] => "'..val..'"',lvl)
          else
            _pr.log(prefix .. indent.."["..pos.."] => "..tostring(val),lvl)
          end
        end
      else
        _pr.log(prefix .. indent..tostring(t),lvl)
      end
    end
  end
  if (type(t)=="table") then
    _pr.log(prefix..tostring(t).." {",lvl)
    sub_print_r(t,"  ",prefix,lvl)
    _pr.log(prefix.."}",lvl)
  else
    sub_print_r(t,"  ",prefix,lvl)
  end
end

-- -------------------------------------------------------------------------
-- Queue support functions
--

function _pr.ListNew ()
  return {first = 0, last = -1, count = 0}
end
function _pr.List.pushleft (list, value)
  local first = list.first - 1
  list.count = list.count + 1
  list.first = first
  list[first] = value
end

function _pr.List.pushright (list, value)
  local last = list.last + 1
  list.count = list.count + 1
  list.last = last
  list[last] = value
end

function _pr.List.popleft (list)
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

function _pr.List.popright (list)
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
function _pr.List.count(list)
  if(list == nil or list.count == nil) then return 0 end
  return list.count or 0
end
-- -------------------------------------------------------------------------
-- Tracing, debugging functions
--
_pr.tracelevel.INFO = 0
_pr.tracelevel.DEBUG = 1
_pr.tracelevel.TRACE = 2
_pr.tracelevel.ERROR = -1
_pr.tracelevel.WARNING = -2
local levelText = {}
levelText[_pr.tracelevel.ERROR] = "ERROR"
levelText[_pr.tracelevel.WARNING] = "WARNING"
levelText[_pr.tracelevel.INFO] = "INFO"
levelText[_pr.tracelevel.DEBUG] = "DEBUG"
levelText[_pr.tracelevel.TRACE] = "TRACE"


function _pr.log(text, level)
  local w = debug.getinfo(2, "Sl")
  local lvlText = levelText[level] or 'UNKNOWN'
  local short_src = w.short_src or 'L_PioneerReceiver1'
  local linedefined = w.currentline or 'UNKNOWN'

  _pr.try(function()
    if(level == nil) then level = _pr.tracelevel.INFO end
    if(_pr.parms.LogLevel == nil) then _pr.parms.LogLevel = _pr.tracelevel.INFO end
    if((type(level)=="string")) then level = tonumber(level) end
    if((type(_pr.parms.LogLevel)=="string")) then _pr.parms.LogLevel = tonumber(_pr.parms.LogLevel) end
    if(_pr.parms.LogLevel >= level) then
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

function _pr.set_query_enable(key,enable_flag)
  if(key ~= nil and enable_flag ~= nil and _pr.fmt.variables_map[key]) then
    _pr.fmt.variables_map[key]['enabled'] = enable_flag
  else
    _pr.log(string.format('Error. Could set query enable flag for key %s enable flag %s', key or '?', enable_flag or '?'),_pr.tracelevel.ERROR)
  end
end

function _pr.get_query_enable(key)
  if(key ~= nil and _pr.fmt.variables_map[key]['enabled'] ~= nil) then
    return _pr.fmt.variables_map[key]['enabled']
  else
    _pr.log(string.format('Error. Could get query enable flag for key %s', key or '?'),_pr.tracelevel.ERROR)
  end
  return true
end

function _pr.is_expired(object)
  local current_ms = get_current_ms()
  local command_expiry = object["expiry"]
  if( command_expiry ~= nil and current_ms > command_expiry ) then
    return true
  else
    return false
  end
end
function _pr.set_expiry_s(object, delay)
  _pr.set_expiry_ms(object, delay*1000)
end

function _pr.set_expiry_ms(object, delay_ms)
  local current_ms = get_current_ms()
  local expTime = socket.gettime() + delay_ms
  object["expiry"]=expTime
end

function _pr.push_expiry_ms(object,delay_ms)
  local command_expiry = object["expiry"]
  if( command_expiry ~= nil  ) then
    -- calculate the offset based on the current time
    local newdelay =   command_expiry-get_current_ms() + delay_ms
    if(newdelay > 0) then     _pr.set_expiry_ms(object,newdelay) end
  else
    _pr.set_expiry_ms(object,delay_ms)
  end
end

function _pr.is_action_value_valid(subservice,command)
  return subservice ~= nil and command ~= nil and _pr.service_map[subservice] ~= nil and _pr.service_map[subservice][command] ~= nil
end
-- -------------------------------------------------------------------------
-- Mappings definition
-- additional documentation can be found here
-- https://www.pioneerelectronics.ca/StaticFiles/Custom%20Install/RS-232%20Codes/Av%20Receivers/Elite%20&%20Pioneer%20FY13AVR%20IP%20&%20RS-232%205-8-12.xls
--
_pr.service_map = {
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
_pr.errors_map = {
  ["E02"] = { description="NOT AVAILABLE NOW", requeue=false, disable=false, save_message=true },
  ["E03"] = {description="INVALID COMMAND", requeue=false, disable=true, save_message=true },
  ["E04"] = {description="COMMAND ERROR", requeue=false, disable=true, save_message=true },
  ["E06"] = {description="PARAMETER ERROR", requeue=false, disable=true, save_message=true },
  ["B00"] = {description="BUSY", requeue=true, save_message=false }
}

_pr.responseMap = {}

for key,value in pairs(_pr.fmt.variables_map) do
  if(value.prefix ~= nil) then
    _pr.responseMap[value.prefix] = value
  end
end

return _pr
