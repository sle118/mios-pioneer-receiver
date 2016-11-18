module("L_PioneerReceiver", package.seeall)

-- some code loosely adapted from http://code.mios.com/trac/mios_squeezebox/browser

local ipAddress
local PRCVRSVC = 'urn:micasaverde-com:serviceId:PioneerReceiver1'
local pendingResponse = {}
local is_DEBUG = '0'
local mappingTable = {
	["InputSelection1"] = {
		["DiscreteinputCable"] = "05FN",    -- TV/SAT
		["DiscreteinputCD1"] = "01FN",      -- CD
		["DiscreteinputCD2"] = "01FN",      -- CD
		["DiscreteinputCDR"] = "03FN",      -- CD-R/TAPE
		["DiscreteinputDAT"] = "03FN",      -- CD-R/TAPE
		["DiscreteinputDVD"] = "04FN",      -- DVD
		["DiscreteinputDVI"] = "19FN",      -- HDMI1
		["DiscreteinputHDTV"] = "05FN",     -- TV/SAT
		["DiscreteinputLD"] = "00FN",       -- PHONO
		["DiscreteinputMD"] = "03FN",       -- CD-R/TAPE
		["DiscreteinputPC"] = "26FN",       -- HOME MEDIA GALLERY(Internet Radio)
		["DiscreteinputPVR"] = "15FN",      -- DVR/BDR
		["DiscreteinputTV"] = "05FN",       -- TV/SAT
		["DiscreteinputVCR"] = "10FN",      -- VIDEO 1(VIDEO)
		["Input1"] = "10FN",                -- VIDEO 1(VIDEO)
		["Input2"] = "14FN",                -- VIDEO 2
		["Input3"] = "19FN",                -- HDMI1
		["Input4"] = "20FN",                -- HDMI2
		["Input5"] = "21FN",                -- HDMI3
		["Input6"] = "22FN",                -- HDMI4
		["Input7"] = "23FN",                -- HDMI5
		["Input8"] = "24FN",                -- HDMI6
		["Input9"] = "25FN",                -- BD
		["Input10"] = "17FN",               -- iPod/USB
		["Source"] = "FU",                  -- INPUT CHANGE (cyclic)
		["ToggleInput"] = "FU",             -- INPUT CHANGE (cyclic)
		},
	["DiscretePower1"] = {
		["Off"] = "PF",                     -- POWER OFF
		["On"] = "PO",                      -- POWER ON
		},
	["MenuNavigation1"] = {
		["Back"] = "CRT",                   -- AMP RETURN
		["Down"] = "CDN",                   -- AMP CURSOR DOWN
		["Exit"] = "CRT",                   -- AMP RETURN
		["Left"] = "CLE",                   -- AMP CURSOR LEFT
		["Menu"] = "HM",                    -- HOME MENU
		["Right"] = "CRI",                  -- AMP CURSOR RIGHT
		["Select"] = "CEN",                 -- AMP CURSOR ENTER
		["Up"] = "CUP",                     -- AMP CURSOR UP
		},
	["Volume1"] = {
		["Down"] = "VD",                    -- VOLUME DOWN
		["Mute"] = "MZ",                    -- MUTE ON/OFF
		["Up"] = "VU",                      -- VOLUME UP
		},
	["Query"]  = {
		["POWER"] = {"command"="?P","var"="power"},
		["VOLUME"] =	{"command"="?V","var"="volume"},
		["MUTE"] = {"command"="?M","var"="mute"},
		["LISTENING_MODE"] = {"command"="?L","var"="listening_mode"},
		["DISPLAY_INFO"] = {"command"="?FL","var"="display_info"},
		["TUNER_PRESET"] = {"command"="?TP","var"="tuner_preset"},
		["ZONE3_MUTE"]=	{"command"="?Z3M","var"="zone3_mute"},
		["ZONE3_VOLUME"]={"command"="?YV","var"="zone3_volume"},
		["ZONE3_INPUT"]={"command"="?ZT","var"="zone3_input"},
		["ZONE3_POWER"]={"command"="?BP","var"="zone3_power""},
		["ZONE2_MUTE"]={"command"="?Z2M","var"="zone2_mute"},
		["ZONE2_VOLUME"]={"command"="?ZV","var"="zone2_volume"},
		["ZONE2_INPUT"]={"command"="?ZS","var"="zone2_input"},
		["ZONE2_POWER"]={"command"="?AP","var"="zone2_power"},
		["SOURCE_QUERY"]={"command"="?F","var"="source_query"},
		["TUNER_FREQ_AM"]={"command"="?FR","var"="tuner_freq_am"},
		["TUNER_FREQ_FM"]={"command"="?FR","var"="tuner_freq_fm"},
		["TREBLE"]={"command"="?TR","var"="treble"},
		["BASS"]={"command"="?BA","var"="bass"},
		["TONE"]={"command"="?TO","var"="tone"}
	}
}

local function debug(text)
	if (is_DEBUG == '1') then
		log("PioneerReceiver debug: " ..text)
	end
end
local function log(text)
	log("PioneerReceiver : " ..text)
end
List = {}
function List.new ()
  return {first = 0, last = -1}
end
function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end

function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end

function List.popleft (list)
  local first = list.first
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
  if list.first > last then 
	return nil
  end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end

local commandQueue = List.new()

--
-- Update variable if changed
-- Return true if changed or false if no change
--
local function setIfChanged(serviceId, name, value, deviceId, default)
	local curValue = luup.variable_get(serviceId, name, deviceId)
	
	if ((value ~= curValue) or (curValue == nil)) then
		luup.variable_set(serviceId, name, value, deviceId)
		return true
		
	else
		return (default or false)
		
	end
end
function check_var (sid, varname, device, default)
	default = default or ''
	if nil == luup.variable_get (sid, varname, device) then
		luup.variable_set (sid, varname, default, device)
	end
end

-- -------------------------------------------------------------------------
-- Perform the appropriate action based on the mapping table for this action

function doAction(deviceType, actionName)
	local code = mappingTable[deviceType][actionName];
	
	local CR = string.char(13)

	-- Do we have a code?
	if( code ~= "") then
		-- Wake up the receiver if it is in standby mode.                  
		luup.io.write(CR)

		if( code.command !~ nil) then
			debug("Code has command : " .. tostring(code))
			code = code.command
		end
		-- Send the code to the receiver
		if( false == luup.io.write(code .. CR)) then
			luup.log("io.write error in action: " .. deviceType .. "-" .. actionName .. " code:" .. code, 1)
			luup.set_failure(true)
			return false
		end

	else
		luup.log("Unimplemented action: " .. deviceType .. "-" .. actionName, 1)
		luup.set_failure(true)
		return false
	end
	return true
end


function try_get_var (sid, varname, device, default)
	default = default or ''
	local var_val = luup.variable_get (sid, varname, device) 
	if nil == var_val then
		debug("existing value not found for "..varname)
		luup.variable_set (sid, varname, default, device)
		var_val = default
	else
		debug("existing value for "..varname.. " was " )
	end
	return var_val
end

function query_status()
	pendingResponse = List.popleft(commandQueue)
	debug("Called to query status")
	if nill == pendingResponse then
		-- init query queue
		for curElement in mappingTable["Query"] do
			debug("Adding to queue : "..tostring(curElement))
			List.pushright(commandQueue,curElement)
		end
		pendingResponse = List.popleft(commandQueue)
	end
	if nill == pendingResponse then
		log("Error. queue could not be created")
	else
		doAction("Query", pendingResponse)
	end

end
-- -------------------------------------------------------------------------
-- Perform the startup for the receiver (i.e. open the telnet port)

function startup(lul_device)
	local TELNET_PORT = 23
	ipAddress = luup.devices[lul_device].ip
	is_DEBUG = check_var (PRCVRSVC, "debug", lul_device, '0')

	if (ipAddress ~= "") then
		luup.log("Running Network Attached I_PioneerReceiver1.xml on " .. ipAddress)
		luup.io.open(lul_device, ipAddress, TELNET_PORT)
	else
		luup.log("Running Serial Attached I_PioneerReceiver1.xml - THIS IS UNTESTED")
	end
	luup.call_delay ('query_status', 2, tostring(device))
end



--   MUTE=    "MO"
--    UNMUTE=    "MF"

--    -- Source / Input channel
--    SOURCE_UP=    "FU"
--    SOURCE_DOWN="FD"
--    SOURCE_SET=    "%02dFN"
--    SOURCE_DVD=    "04FN"
--    SOURCE_BD=    "25FN"
--    SOURCE_TVSAT="05FN"
--    SOURCE_DVR_BDR="15FN"
--    SOURCE_VIDEO1="10FN"
--    SOURCE_VIDEO2="14FN"
--    SOURCE_HDMI1="19FN"
--    SOURCE_HDMI2="20FN"
--    SOURCE_HDMI3="21FN"
--    SOURCE_HDMI4="22FN"
--    SOURCE_HDMI5="23FN"
--    SOURCE_HMG=    "26FN"
--    SOURCE_IPOD_USB="17FN"
--    SOURCE_XMRADIO="18FN"
--    SOURCE_CD="01FN"
--    SOURCE_CDR_TAPE="03FN"
--    SOURCE_TUNER="02FN"
--    SOURCE_PHONO="00FN"
--    SOURCE_MULTICH_IN="12FN"
--    SOURCE_ADAPTER_PORT="33FN"
--    SOURCE_HDMI_CYCL="31FN"
--    
--    -- Listening mode
--    LISTENING_MODE="%04dSR"
--     
--     -- tone control
--     TONE_ON="TO1"
--     TONE_BYPASS="TO0"
--    
--     -- bass control
--     BASS_INCREMENT="BI"
--     BASS_DECREMENT="BD"

--     
--     -- treble control
--     TREBLE_INCREMENT="TI"
--     TREBLE_DECREMENT="TD"

--     
--     -- Speaker configuration
--     SPEAKERS="%01dSPK"
--     SPEAKERS_OFF="0SPK"
--     SPEAKERS_A="1SPK"
--     SPEAKERS_B="2SPK"
--     SPEAKERS_A_B="3SPK"
--     
--     -- HDMI outputs configuration
--     HDMI_OUTPUT="%01dHO"
--     HDMI_OUT_ALL="0HO"
--     HDMI_OUT_1="1HO"
--     HDMI_OUT_2="2HO"
--     
--     -- HDMI audio configuration
--     HDMI_AUDIO_AMP="0HA"
--     HDMI_AUDIO_THROUGH="1HA"
--     
--     -- PQLS setting
--     PQLS_OFF="0PQ"
--     PQLS_AUTO="1PQ"
--     
--     -- Zone 2 control
--     ZONE2_POWER_ON=        "APO"
--     ZONE2_POWER_OFF="APF"

--     ZONE2_INPUT="%02dZS"
--     ZONE2_INPUT_DVD="04ZS"
--     ZONE2_INPUT_TV_SAT="05ZS"
--     ZONE2_INPUT_DVR_BDR="15ZS"
--     ZONE2_INPUT_VIDEO1="10ZS"
--     ZONE2_INPUT_VIDEO2="14ZS"
--     ZONE2_INPUT_HMG="26ZS"
--     ZONE2_INPUT_IPOD="17ZS"
--     ZONE2_INPUT_XMRADIO="18ZS"
--     ZONE2_INPUT_CD=    "01ZS"
--     ZONE2_INPUT_CDR_TAPE="03ZS"
--     ZONE2_INPUT_TUNER="02ZS"
--     ZONE2_INPUT_ADAPTER="33ZS"
--     ZONE2_INPUT_SIRIUS="27ZS"
--     ZONE2_VOLUME_UP="ZU"
--     ZONE2_VOLUME_DOWN="ZD"
--     ZONE2_VOLUME=    "%02ZV",    "ZV"
--     ZONE2_MUTE=        "Z2MO"
--     ZONE2_UNMUTE=    "Z2MF"

--     
--     -- zone 3 control
--     ZONE3_POWER_ON=        "BPO"
--     ZONE3_POWER_OFF="BPF"
--     ZONE3_INPUT="%02dZT"
--     ZONE3_INPUT_DVD="04ZT"
--     ZONE3_INPUT_TV_SAT="05ZT"
--     ZONE3_INPUT_DVR_BDR="15ZT"
--     ZONE3_INPUT_VIDEO1="10ZT"
--     ZONE3_INPUT_VIDEO2="14ZT"
--     ZONE3_INPUT_HMG="26ZT"
--     ZONE3_INPUT_IPOD="17ZT"
--     ZONE3_INPUT_XMRADIO="18ZT"
--     ZONE3_INPUT_CD=    "01ZT"
--     ZONE3_INPUT_CDR_TAPE="03ZT"
--     ZONE3_INPUT_TUNER="02ZT"
--     ZONE3_INPUT_ADAPTER="33ZT"
--     ZONE3_INPUT_SIRIUS="27ZT"
--     ZONE3_VOLUME_UP="YU"
--     ZONE3_VOLUME_DOWN="YD"
--     ZONE3_VOLUME=    "%02YV"


--     ZONE3_MUTE=        "Z3MO"
--     ZONE3_UNMUTE=    "Z3MF"

--     
--     -- radio tuner
--     TUNER_FREQ_INCREMENT="TFI"
--     TUNER_FREQ_DECREMENT="TFD"
--     TUNER_BAND=        "TB"
--     TUNER_PRESET=    "%01dTP"
--     TUNER_CLASS=    "TC"
--     TUNER_PRESET_INCREMENT="TPI"
--     TUNER_PRESET_DECREMENT="TPD"

--     
--     -- iPod control
--     IPOD_PLAY=            "00IP"
--     IPOD_PAUSE=        "01IP"
--     IPOD_STOP=            "02IP"
--     IPOD_PREVIOS=        "03IP"
--     IPOD_NEXT=            "04IP"
--     IPOD_REV=            "05IP"
--     IPOD_FWD=            "06IP"
--     IPOD_REPEAT=        "07IP"
--     IPOD_SHUFFLE=        "08IP"
--     IPOD_DISPLAY=        "09IP"
--     IPOD_CONTROL=        "10IP"
--     IPOD_CURSOR_UP=    "13IP"
--     IPOD_CURSOR_DOWN="14IP"
--     IPOD_CURSOR_LEFT="15IP"
--     IPOD_CURSOR_RIGHT="16IP"
--     IPOD_ENTER=        "17IP"
--     IPOD_RETURN=        "18IP"
--     IPOD_TOP_MENU=        "19IP"
--     IPOD_KEY_OFF=        "KOF"
--     
--     ADAPTER_PLAY_PAUSE="20BT"
--     ADAPTER_PLAY="10BT"
--     ADAPTER_PAUSE="11BT"
--     ADAPTER_STOP="12BT"
--     ADAPTER_PREVIOUS="13BT"
--     ADAPTER_NEXT="14BT"
--     ADAPTER_REV="15BT"
--     ADAPTER_FWD="16BT"
--    
--    -- Home Media Gateway (HMG) control
--    HMG_NUMKEY="%02dNW"
--    HMG_NUMKEY_0="00NW"
--    HMG_NUMKEY_1="01NW"
--    HMG_NUMKEY_2="02NW"
--    HMG_NUMKEY_3="03NW"
--    HMG_NUMKEY_4="04NW"
--    HMG_NUMKEY_5="05NW"
--    HMG_NUMKEY_6="06NW"
--    HMG_NUMKEY_7="07NW"
--    HMG_NUMKEY_8="08NW"
--    HMG_NUMKEY_9="09NW"
--    HMG_PLAY="10NW"
--    HMG_PAUSE="11NW"
--    HMG_PREV="12NW"
--    HMG_NEXT="13NW"
--    HMG_DISPLAY="18NW"
--    HMG_STOP="20NW"
--    HMG_UP=    "26NW"
--    HMG_DOWN="27NW"
--    HMG_RIGHT="28NW"
--    HMG_LEFT="29NW"
--    HMG_ENTER="30NW"
--    HMG_RETURN="31NW"
--    HMG_PROGRAM="32NW"
--    HMG_CLEAR="33NW"
--    HMG_REPEAT="34NW"
--    HMG_RANDOM="35NW"
--    HMG_MENU="36NW"
--    HMG_EDIT="37NW"
--    HMG_CLASS="38NW"
--    
