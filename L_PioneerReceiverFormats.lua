module("L_PioneerReceiverFormats", package.seeall)

default_service = 'urn:micasaverde-com:serviceId:PioneerReceiver1'
sources_desc = {    ['25']="BD",['04']="DVD",['06']="SAT/CBL",['15']="DVR/BDR",['10']="VIDEO 1(VIDEO)",['19']="HDMI 1",['20']="HDMI 2",['21']="HDMI 3",['22']="HDMI 4",['23']="HDMI 5",['24']="HDMI 6",['34']="HDMI 7",['26']="NETWORK (cyclic)",['38']="INTERNET RADIO",['40']="SiriusXM",['41']="PANDORA",['44']="MEDIA SERVER",['45']="FAVORITES",['17']="iPod/USB",['05']="TV",['01']="CD",['13']="USB-DAC",['02']="TUNER",['00']="PHONO",['12']="MULTI CH IN",['33']="ADAPTER PORT",['48']="MHL",['31']="HDMI (cyclic)"}
function store_desc(val,lul_device)
  local index = string.sub(val or '',1,2)
  local newValue = string.sub(val or '',4,val:len())
  sources_desc[index]=newValue
  return newValue
end

function conv_mcacc_memory(val,lul_device)
  local values = { ['0']='MCACC MEMORY (cyclic)', ['1']='MEMORY 1', ['2']='MEMORY 2', ['3']='MEMORY 3', ['4']='MEMORY 4', ['5']='MEMORY 5', ['6']='MEMORY 6', ['9']='MCACC MEMORY (cyclic reverse)'  }
  return values[val] or '?'
end
function convert_on_off_cycl(val,lul_device)
  local values = {
    ['0']='Off',
    ['1']='On',
    ['8']='(cyclic reverse)',
    ['9']='(cyclic)'
  }
  return values[val] or '?'
end

function conv_signal_select(val,lul_device)
  local values = {['0']='Auto',['1']='Analog',['2']='Digital',['3']='HDMI',['9']='Signal Select (cyclic)'}
  return values[val] or '?'
end

function conv_phase_control_plus(val,lul_device)
  --[[
    00 to 16 by ASCII code. (1step=1ms)
     00:0ms
     01:1ms
    ...:...
     15:15ms
     16:16ms
     97:AUTO
     98:DOWN
     99:UP
 ]]--
  local values = { ['97'] = 'Auto', ['98']='Down', ['99']='Up'  }
  return values[val] or val
end
function conv_sound_delay(val,lul_device)
  --[[
000 to 100 by ASCII code.(1step=0.1frame)
 000:0.0frame
 001:0.1ftame
 ...:...
 099:9.9frame
 100:10.0frame
 998:DOWN
 999:UP

]]--
  local values = {['998']='Down', ['999']='Up'  }
  return values[val] or string.format('%.2f',tonumber(val)/10) or '?'..val..'?'
end
function conv_dialog_enhacement(val,lul_device)
  local values = {['0']='Off',['1']='Flat',['2']='Up1',['3']='Up2',['4']='Up3',['5']='Up4',['8']='Down (cyclic)',['9']='Up (cyclic)' }
  return values[val] or '?'..val or '?'..'?'
end
function conv_dual_mono(val,lul_device)
  local values = {['0']='CH1&CH2',['1']='CH1',['2']='CH2',['8']='DOWN (cyclic)',['9']='UP (cyclic)'    }
  return values[val] or '?'..val or '?'..'?'
end

function conv_drc(val,lul_device)
  local values = { ['0']='Off',['1']='Auto',['2']='Mid',['3']='Max',['8']='DOWN (cyclic)',['9']='UP (cyclic)'}
  return values[val] or '?'..val or '?'..'?'
end
function conv_lfe_att(val,lul_device)
  local values = {['0']='0dB',['1']='-5dB',['2']='-10dB',['3']='-15dB',['4']='-20dB',['5']='OFF',['8']='DOWN',['9']='UP'}
  return values[val] or '?'..val or '?'..'?'
end
function conv_sacd_gain(val,lul_device)
  local values = { ['0']='0dB',['1']='+6dB',['9']='SACD GAIN (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_formatnum_3digits(val,lul_device)
  return string.format('%3f',tonumber(val or '0'))
end
function conv_number_base50(val,lul_device)
  local dim = tonumber(val)-50
  return  string.format('%2.0f',dim or 0)
end
function conv_dimension(val,lul_device)
  return  conv_number_base50(val,lul_device)
end
function conv_center_image_neo_option(val,lul_device)
  local values = {['98']='Down', ['99']='Up'  }
  return values[val] or string.format('%.1f',tonumber(val)/10) or '?'..val..'?'
end
function conv_low_mid_high(val,lul_device)
  local values = { ['0']='Low',['1']='Mid',['2']='High',['8']='DOWN (cyclic)',['9']='UP (cyclic)'  }
  return values[val] or '?'..val or '?'..'?'
end
function conv_min_mid_max(val,lul_device)
  local values = { ['0']='Min',['1']='Mid',['2']='Max',['8']='DOWN (cyclic)',['9']='UP (cyclic)'  }
  return values[val] or '?'..val or '?'..'?'
end
function conv_slow_sharp_short(val,lul_device)
  local values = { 'Slow','Sharp','Short',['8']='DOWN (cyclic)',['9']='UP (cyclic)'  }
  return values[val] or '?'..val or '?'..'?'
end
function conv_amp_speakers(val,lul_device)
  local values = { ['0']='Off',['1']='A On',['2']='B On',['3']='A+B On'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_amp_hdmi_output(val,lul_device)
  local values = { ['0']='HDMI OUT ALL',['1']='HDMI OUT 1',['2']='HDMI OUT 2',['9']='HDMI OUT (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_amp_hdmi_audio(val,lul_device)
  local values = { ['0']='Amp',['1']='Through',['9']='HDMI AUDIO (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_amp_pqls_setting(val,lul_device)
  local values = { ['0']='Off',['1']='Auto',['9']='PQLS (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_amp_sleep_remain_time(val,lul_device)
  return string.format('%3f',tonumber(val or '0'))
end
function conv_amp(val,lul_device)
  local values = { ['0']='AMP On',['1']='AMP Front Off',['2']='AMP Front & Center Off',['3']='AMP Off',['98']='DOWN (cyclic)',['99']='UP (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_panel_key_lock(val,lul_device)
  local values = { ['0']='Off',['1']='KEY LOCK On',['2']='KEY & VOLUME LOCK On'  }
  return values[val] or '?'..val or '?'..'?'
end
function conv_remote_lock_(val,lul_device)
  local values = { ['0']='Off',['1']='On'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_video_converter(val,lul_device)
  local values = { ['0']='Off',['1']='On',['9']='VIDEO CONVERTER (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_video_resolution(val,lul_device)
  local values = { ['0']='Auto',['1']='PURE',['2']='Reserved ',['3']='480/576p',['4']='720p',['5']='1080i',['6']='1080p',['7']='1080/24p',['98']='RESOLUTION DOWN (cyclic)',['99']='RESOLUTION UP (cyclic)',   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_video_pure_cinema(val,lul_device)
  local values = { ['0']='Auto',['1']='On',['2']='Off',['8']='PURE CINEMA DOWN (cyclic)',['9']='PURE CINEMA UP (cyclic)',   }
  return values[val] or '?'..val or '?'..'?'
end

function conv_video_prog_motion(val,lul_device)
  return  conv_number_base50(val,lul_device)
end
function conv_video_stream_smoother(val,lul_device)
  local values = { ['0']='Off',['1']='On',['2']='Auto',['8']='STREAM SMOOTHER DOWN',['9']='STREAM SMOOTHER UP '   }
  return values[val] or '?'..val or '?'..'?'
end

function conv_video_advanced_video_adjust(val,lul_device)
  local values = { ['0']='PDP',['1']='LCD',['2']='FPJ',['3']='Professional',['4']='Memory',['8']='VIDEO PRESET DOWN (cyclic)',['9']='VIDEO PRESET UP (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end
function conv_video_black_setup(val,lul_device)
  local values = { ['12']='0',['1']='7.5',['9']='BLACK SETUP (cyclic)'  }
  return values[val] or '?'..val or '?'..'?'
end
function conv_video_aspect(val,lul_device)
  local values = { ['0']='Through',['1']='Normal',['9']='ASPECT (cyclic)'   }
  return values[val] or '?'..val or '?'..'?'
end

function convert_is(val,lul_device)
  local values = {    ['0']='Off',    ['1']='On',    ['2']='Full Band',    ['9']='(cyclic)'  }
  return values[val] or '?'
end
function resolve_bitstring(bitstring,map)
  local output = ''
  if(map == nil or bitstring == nil ) then return '?'end
  for i = 1, #bitstring do
    local char = bitstring:sub(i,i)
    if(map[i]~=nil) then
      output=output..(char=='1' and output:len()>0 and '.' or '')..(char=='1' and map[i] or '')
    end
  end
  return output
end
function bits(hex,n)
  local nmap = {['0']='0000',['1']='0001',['2']='0010',['3']='0011',['4']='0100',['5']='0101',['6']='0110',['7']='0111',['8']='1000',['9']='1001',['A']='1010',['B']='1011',['C']='1100',['D']='1101',['E']='1110',['F']='1111'}
  local pos = 2-math.ceil(n/4)+1 -- bits 1-8 are in char 1 and 9-16 in char 2
  local _,rem = math.modf(n/4)
  local index = 4-rem*4 -- get position inside 4 bits array
  if(hex:len()<pos) then return '?'end
  return string.sub(nmap[string.sub(hex,pos,pos)],index,index)

end
function hextochar(hex)
  local output = ''
  -- ensure that we are getting a series of
  -- 2 digits hex numbers
  local _,ret = math.modf(hex:len()/2)
  if(hex == nil or (ret~=0)) then return '?'end
  -- decode each number into a char
  local i=1
  while i<hex:len() do
    local curhex = hex:sub(i,i+1)
    local n = tonumber(curhex,16)
    if(n>0) then
      --n=n+string.byte(' ')
      output = output..string.char(n)
    end
    i=i+2
  end
  if(output and output:len() >0) then
    output = output:gsub("^%s*(.-)%s*$", "%1")
  end
  return output or ''
end
function convert_fl(val,lul_device)
  local values = {['1']='Light', ['0']='Off'}
  local flags=string.sub(val,1,2)
  local output = bits(flags,1)=='1' and '[+V+] ' or '[-V-] ' and bits(flags,0)=='1' and '[+G+] ' or '[-G-] '
  output = output..hextochar(string.sub(val,3,30))
  return output:upper()
end
function tunerpreset(val,lul_device)
  if(val:len() < 3) then return '?' end
  if(val:sub(1,1):byte() >= string.byte("A") and val:sub(1,1):byte() <= string.byte("Z")  ) then return val end
  local bank=string.char(string.byte('A')+tonumber(val:sub(1,1))-1)
  return bank..val:sub(2,3)
end
function zoneinput(val,lul_device)
  --local values = {['04']='DVD',['06']='SAT/CBL',['15']='DVR/BDR',['10']='VIDEO 1(VIDEO)',['26']='NETWORK (cyclic)',['38']='INTERNET RADIO',['40']='SiriusXM',['41']='PANDORA',['44']='MEDIA SERVER',['45']='FAVORITES',['17']='iPod/USB',['13']='USB-DAC',['05']='TV',['01']='CD',['02']='TUNER',['33']='ADAPTER PORT'}
  --return values[val] or '?'
  return sources_desc[val] or '?'
end
function convert_ast(val,lul_device)
  local input_signal_values = {["00"]="ANALOG",["01"]="ANALOG",["02"]="ANALOG",["03"]="PCM",["04"]="PCM",["05"]="DOLBY DIGITAL",["06"]="DTS",["07"]="DTS-ES Matrix",["08"]="DTS-ES Discrete",["09"]="DTS 96/24",["10"]="DTS 96/24 ES Matrix",["11"]="DTS 96/24 ES Discrete",["12"]="MPEG-2 AAC",["13"]="WMA9 Pro",["14"]="DSD->PCM",["15"]="HDMI THROUGH",["16"]="DOLBY DIGITAL PLUS",["17"]="DOLBY TrueHD",["18"]="DTS EXPRESS",["19"]="DTS-HD Master Audio",["20"]="DTS-HD High Resolution",["21"]="DTS-HD High Resolution",["22"]="DTS-HD High Resolution",["23"]="DTS-HD High Resolution",["24"]="DTS-HD High Resolution",["25"]="DTS-HD High Resolution",["26"]="DTS-HD High Resolution",["27"]="DTS-HD Master Audio"  }
  local input_frequency_values={["00"]="32kHz",["01"]="44.1kHz",["02"]="48kHz",["03"]="88.2kHz",["04"]="96kHz",["05"]="176.4kHz",["06"]="192kHz",["07"]="---",  }
  local input_channel_format_values = {[1]="L",[2]="C",[3]="R",[4]="SL",[5]="SR",[6]="SBL",[7]="S",[8]="SBR",[9]="LFE",[10]="FHL",[11]="FHR",[12]="FWL",[13]="FWR",[14]="XL",[15]="XC",[16]="XR"  }
  local output_channel_format_values = {[1]="L",[2]="C",[3]="R",[4]="SL",[5]="SR",[6]="SBL",[7]="SB",[8]="SBR",[9]="SW",[10]="FHL",[11]="FHR",[12]="FWL",[13]="FWR"  }
  local input_signal_code=string.sub(val,1,2)
  local input_frequency_code=string.sub(val,3,4)
  local input_channel_format_code=string.sub(val,5,25)
  local output_channel_format_code=string.sub(val,26,43)

  -- determine input format
  local input_channel = resolve_bitstring(input_channel_format_code,input_channel_format_values)
  local output_channel =  resolve_bitstring(output_channel_format_code,output_channel_format_values)

  return string.format('%s %s %s => %s',input_channel,input_signal_values[input_signal_code] or '?input',input_frequency_values[input_frequency_code] or '?frequency',output_channel)
end

function convert_vst(val,lul_device)

  local Input_Terminal_values = {["0"]="---",["1"]="VIDEO",["2"]="S-VIDEO",["3"]="COMPONENT",["4"]="HDMI",["5"]="Self OSD/JPEG"}
  local Input_Resolution_values = {["00"]="---",["01"]="480/60i",["02"]="576/50i",["03"]="480/60p",["04"]="576/50p",["05"]="720/60p",["06"]="720/50p",["07"]="1080/60i",["08"]="1080/50i",["09"]="1080/60p",["10"]="1080/50p",["11"]="1080/24p",["12"]="4Kx2K/24Hz",["13"]="4Kx2K/25Hz",["14"]="4Kx2K/30Hz",["15"]="4Kx2K/24Hz(SMPTE)"}
  local Input_aspect_values = {["0"]="---",["1"]="4:3",["2"]="16:9",["3"]="14:9"}
  local Input_color_format_HDMI_only_values = {["0"]="---",["1"]="RGB Limit",["2"]="RGB Full",["3"]="YcbCr444",["4"]="YcbCr422"}
  local Input_bit_HDMI_only_values = {["0"]="---",["1"]="24bit (8bit*3)",["2"]="30bit (10bit*3)",["3"]="36bit (12bit*3)",["4"]="48bit (16bit*3)"}
  local Input_extend_color_space_HDMI_only_values = {["0"]="---",["1"]="Standard",["2"]="xvYCC601",["3"]="xvYCC709",["4"]="sYCC",["5"]="AdobeYCC601",["6"]="AdobeRGB"}
  local Output_Resolution_values = {["00"]="---",["01"]="480/60i",["02"]="576/50i",["03"]="480/60p",["04"]="576/50p",["05"]="720/60p",["06"]="720/50p",["07"]="1080/60i",["08"]="1080/50i",["09"]="1080/60p",["10"]="1080/50p",["11"]="1080/24p",["12"]="4Kx2K/24Hz",["13"]="4Kx2K/25Hz",["14"]="4Kx2K/30Hz",["15"]="4Kx2K/24Hz(SMPTE)"}
  local Output_aspect_values = {["0"]="---",["1"]="4:3",["2"]="16:9",["3"]="14:9"}
  local Output_color_format_HDMI_only_values = {["0"]="---",["1"]="RGB Limit",["2"]="RGB Full",["3"]="YcbCr444",["4"]="YcbCr422"}
  local Output_bit_HDMI_only_values = {["0"]="---",["1"]="24bit (8bit*3)",["2"]="30bit (10bit*3)",["3"]="36bit (12bit*3)",["4"]="48bit (16bit*3)"}
  local Output_extend_color_space_HDMI_only_values = {["0"]="---",["1"]="Standard",["2"]="xvYCC601",["3"]="xvYCC709",["4"]="sYCC",["5"]="AdobeYCC601",["6"]="AdobeRGB"}
  local HDMI_1_Monitor_Recommend_Resolution_Information_values = {["00"]="---",["01"]="480/60i",["02"]="576/50i",["03"]="480/60p",["04"]="576/50p",["05"]="720/60p",["06"]="720/50p",["07"]="1080/60i",["08"]="1080/50i",["09"]="1080/60p",["10"]="1080/50p",["11"]="1080/24p",["12"]="4Kx2K/24Hz",["13"]="4Kx2K/25Hz",["14"]="4Kx2K/30Hz",["15"]="4Kx2K/24Hz(SMPTE)"}
  local HDMI_1_Monitor_DeepColor_values = {["0"]="---",["1"]="24bit (8bit*3)",["2"]="30bit (10bit*3)",["3"]="36bit (12bit*3)",["4"]="48bit (16bit*3)"}
  local HDMI_1_Monitor_Extend_Color_Space_values = {[1]="xvYCC601",[2]="xvYCC709",[3]="sYCC",[4]="AdobeYCC601",[5]="AdobeRGB"}
  local HDMI_2_Monitor_Recommend_Resolution_Information_values = {["00"]="---",["01"]="480/60i",["02"]="576/50i",["03"]="480/60p",["04"]="576/50p",["05"]="720/60p",["06"]="720/50p",["07"]="1080/60i",["08"]="1080/50i",["09"]="1080/60p",["10"]="1080/50p",["11"]="1080/24p",["12"]="4Kx2K/24Hz",["13"]="4Kx2K/25Hz",["14"]="4Kx2K/30Hz",["15"]="4Kx2K/24Hz(SMPTE)"}
  local HDMI_2_Monitor_DeepColor_values = {["0"]="---",["1"]="24bit (8bit*3)",["2"]="30bit (10bit*3)",["3"]="36bit (12bit*3)",["4"]="48bit (16bit*3)"}
  local HDMI_2_Monitor_Extend_Color_Space_values = {[1]="xvYCC601",[2]="xvYCC709",[3]="sYCC",[4]="AdobeYCC601",[5]="AdobeRGB"}
  local Input_3D_format_HDMI_only_values = {["00"]="---",["01"]="Frame packing",["02"]="Field alternative",["03"]="Line alternative",["04"]="Side-by-Side(Full)",["05"]="L + depth",["06"]="L + depth + graphics",["07"]="Top-and-Bottom",["08"]="Side-by-Side(Half)"}
  local Output_3D_format_HDMI_only_values = {["00"]="---",["01"]="Frame packing",["02"]="Field alternative",["03"]="Line alternative",["04"]="Side-by-Side(Full)",["05"]="L + depth",["06"]="L + depth + graphics",["07"]="Top-and-Bottom",["08"]="Side-by-Side(Half)"}
  local HDMI_ZONE_Monitor_Recommend_Resolution_Information_values = {["00"]="---",["01"]="480/60i",["02"]="576/50i",["03"]="480/60p",["04"]="576/50p",["05"]="720/60p",["06"]="720/50p",["07"]="1080/60i",["08"]="1080/50i",["09"]="1080/60p",["10"]="1080/50p",["11"]="1080/24p",["12"]="4Kx2K/24Hz",["13"]="4Kx2K/25Hz",["14"]="4Kx2K/30Hz",["15"]="4Kx2K/24Hz(SMPTE)"}
  local HDMI_ZONE_Monitor_DeepColor_values = {["0"]="---",["1"]="24bit (8bit*3)",["2"]="30bit (10bit*3)",["3"]="36bit (12bit*3)",["4"]="48bit (16bit*3)"}
  local HDMI_ZONE_Monitor_Extend_Color_Space_values = {[1]="xvYCC601",[2]="xvYCC709",[3]="sYCC",[4]="AdobeYCC601",[5]="AdobeRGB"}

  local Input_Terminal_code = string.sub(val,1,1)
  local Input_Resolution_code = string.sub(val,2,3)
  local Input_aspect_code = string.sub(val,4,4)
  local Input_color_format_HDMI_only_code = string.sub(val,5,5)
  local Input_bit_HDMI_only_code = string.sub(val,6,6)
  local Input_extend_color_space_HDMI_only_code = string.sub(val,7,7)
  local Output_Resolution_code = string.sub(val,8,9)
  local Output_aspect_code = string.sub(val,10,10)
  local Output_color_format_HDMI_only_code = string.sub(val,11,11)
  local Output_bit_HDMI_only_code = string.sub(val,12,12)
  local Output_extend_color_space_HDMI_only_code = string.sub(val,13,13)
  local HDMI_1_Monitor_Recommend_Resolution_Information_code = string.sub(val,14,15)
  local HDMI_1_Monitor_DeepColor_code = string.sub(val,16,16)
  local HDMI_1_Monitor_Extend_Color_Space_code = string.sub(val,17,21)
  local HDMI_2_Monitor_Recommend_Resolution_Information_code = string.sub(val,22,23)
  local HDMI_2_Monitor_DeepColor_code = string.sub(val,24,24)
  local HDMI_2_Monitor_Extend_Color_Space_code = string.sub(val,25,29)
  local Input_3D_format_HDMI_only_code = string.sub(val,30,31)
  local Output_3D_format_HDMI_only_code = string.sub(val,32,33)
  local HDMI_ZONE_Monitor_Recommend_Resolution_Information_code = string.sub(val,34,35)
  local HDMI_ZONE_Monitor_DeepColor_code = string.sub(val,36,36)
  local HDMI_ZONE_Monitor_Extend_Color_Space_code = string.sub(val,37,41)


  local Input_Terminal_val = Input_Terminal_values[Input_Terminal_code] or '?'
  local Input_Resolution_val = Input_Resolution_values[Input_Resolution_code] or '?'
  local Input_aspect_val = Input_aspect_values[Input_aspect_code] or '?'
  local Input_color_format_HDMI_only_val = Input_color_format_HDMI_only_code ~='0' and Input_color_format_HDMI_only_values[Input_color_format_HDMI_only_code] or ''
  local Input_bit_HDMI_only_val = Input_bit_HDMI_only_code ~='0' and Input_bit_HDMI_only_values[Input_bit_HDMI_only_code] or ''
  local Input_extend_color_space_HDMI_only_val = Input_extend_color_space_HDMI_only_code ~='0' and Input_extend_color_space_HDMI_only_values[Input_extend_color_space_HDMI_only_code] or '?'
  local Output_Resolution_val = Output_Resolution_code ~='0' and Output_Resolution_values[Output_Resolution_code] or '?'
  local Output_aspect_val = Output_aspect_code ~='0' and Output_aspect_values[Output_aspect_code] or '?'
  local Output_color_format_HDMI_only_val = Output_color_format_HDMI_only_code ~='0' and Output_color_format_HDMI_only_values[Output_color_format_HDMI_only_code] or '?'
  local Output_bit_HDMI_only_val = Output_bit_HDMI_only_code ~='0' and Output_bit_HDMI_only_values[Output_bit_HDMI_only_code] or '?'
  local Output_extend_color_space_HDMI_only_val = Output_extend_color_space_HDMI_only_code ~='0' and Output_extend_color_space_HDMI_only_values[Output_extend_color_space_HDMI_only_code] or '?'
  local HDMI_1_Monitor_Recommend_Resolution_Information_val = HDMI_1_Monitor_Recommend_Resolution_Information_code ~='0' and HDMI_1_Monitor_Recommend_Resolution_Information_values[HDMI_1_Monitor_Recommend_Resolution_Information_code] or '?'
  local HDMI_1_Monitor_DeepColor_val = HDMI_1_Monitor_DeepColor_code ~='0' and HDMI_1_Monitor_DeepColor_values[HDMI_1_Monitor_DeepColor_code] or '?'
  local HDMI_1_Monitor_Extend_Color_Space_val = resolve_bitstring(HDMI_1_Monitor_Extend_Color_Space_code,HDMI_1_Monitor_Extend_Color_Space_values)
  local HDMI_2_Monitor_Recommend_Resolution_Information_val = HDMI_2_Monitor_Recommend_Resolution_Information_code ~='0' and HDMI_2_Monitor_Recommend_Resolution_Information_values[HDMI_2_Monitor_Recommend_Resolution_Information_code] or '?'
  local HDMI_2_Monitor_DeepColor_val = HDMI_2_Monitor_DeepColor_code ~='0' and HDMI_2_Monitor_DeepColor_values[HDMI_2_Monitor_DeepColor_code] or '?'
  local HDMI_2_Monitor_Extend_Color_Space_val = resolve_bitstring(HDMI_2_Monitor_Extend_Color_Space_code,HDMI_2_Monitor_Extend_Color_Space_values)
  local Input_3D_format_HDMI_only_val = Input_3D_format_HDMI_only_code ~='0' and Input_3D_format_HDMI_only_values[Input_3D_format_HDMI_only_code] or '?'
  local Output_3D_format_HDMI_only_val = Output_3D_format_HDMI_only_code ~='0' and Output_3D_format_HDMI_only_values[Output_3D_format_HDMI_only_code] or '?'
  local HDMI_ZONE_Monitor_Recommend_Resolution_Information_val = HDMI_ZONE_Monitor_Recommend_Resolution_Information_code ~='0' and HDMI_ZONE_Monitor_Recommend_Resolution_Information_values[HDMI_ZONE_Monitor_Recommend_Resolution_Information_code] or '?'
  local HDMI_ZONE_Monitor_DeepColor_val = HDMI_ZONE_Monitor_DeepColor_code ~='0' and HDMI_ZONE_Monitor_DeepColor_values[HDMI_ZONE_Monitor_DeepColor_code] or '?'
  local HDMI_ZONE_Monitor_Extend_Color_Space_val = resolve_bitstring(HDMI_ZONE_Monitor_Extend_Color_Space_code,HDMI_ZONE_Monitor_Extend_Color_Space_values)
  --Input HDMI[YcbCr444,24bit (8bit*3),Standard]  16:9@1080/60p,  ,



  return string.format('Input: %s[%s,%s,%s] %s@%s 3D %s=>[%s,%s,%s] %s@%s 3D %s, '..
    'HDMIZONE Recommended : [%s,%s]  %s, '..
    'HDMI1 Recommended : [%s,%s]  %s, '..
    'HDMI2 Recommended : [%s,%s]  %s, ',
    Input_Terminal_val,
    Input_color_format_HDMI_only_val,
    Input_bit_HDMI_only_val,
    Input_extend_color_space_HDMI_only_val,
    Input_aspect_val,
    Input_Resolution_val,
    Input_3D_format_HDMI_only_val,

    Output_color_format_HDMI_only_val,
    Output_bit_HDMI_only_val,
    Output_extend_color_space_HDMI_only_val,
    Output_aspect_val,
    Output_Resolution_val,
    Output_3D_format_HDMI_only_val,

    HDMI_1_Monitor_DeepColor_val,
    HDMI_1_Monitor_Extend_Color_Space_val,
    HDMI_1_Monitor_Recommend_Resolution_Information_val,

    HDMI_2_Monitor_DeepColor_val,
    HDMI_2_Monitor_Extend_Color_Space_val,
    HDMI_2_Monitor_Recommend_Resolution_Information_val,

    HDMI_ZONE_Monitor_DeepColor_val,
    HDMI_ZONE_Monitor_Extend_Color_Space_val,
    HDMI_ZONE_Monitor_Recommend_Resolution_Information_val)

end

function get_value(val,prefix)
  return string.sub(val,prefix:len()+1,val:len())
end
function volume(val,lul_device)
  local volval = math.ceil(tonumber(val)*0.5-80.5)
  --return  string.format('%ldB',(volval or 0)*0.5-80.5) or '?'
  return  tonumber(val) == 0 and '--dB(MIN)' or ( string.format('%s%idB',(volval>0 and '+' or (volval==0 and '±' or '')),volval) or '?')
end
function volume_pct(val,lul_device)
  return  math.ceil(tonumber(val)/185*100)
end
function zonevolume(val,lul_device)
  local volval = tonumber(val)-81
  return  tonumber(val) == 0 and '--dB(MIN)' or (string.format('%s%idB',(volval>0 and '+' or (volval==0 and '±' or '')),volval) or '?')
end
function zonelevel(val,lul_device)
  local volval = tonumber(val)-50
  return  tonumber(val) == 0 and '--dB(MIN)' or (string.format('%s%idB',(volval>0 and '+' or (volval==0 and '±' or '')),volval) or '?')
end
function zonevolume_pct(val,lul_device)
  return  math.ceil(tonumber(val)/81*100)
end
function mute(val,lul_device)
  local values = {['0']='On', ['1']='Off'}
  return values[val] or '?'
end
function tunerfreq(val,lul_device)
  local values = {['A']='AM', ['F']='FM'}
  local af = val:sub(1,1) or ''

  local freq = af=='A' and string.format('%u',tonumber(val:sub(2,6))) or af=='F' and string.format('%.2f',tonumber(val:sub(2,6))/100) or ''
  local freqtxt = af=='A' and 'kHz' or af=='F' and 'MHz' or '?'

  output = string.format('%s %s%s',values[af] or '',freq,freqtxt)

  return output
end
function listeningmode(val,lul_device)
  local values = {["0101"]="[)(]PLIIx MOVIE",["0102"]="[)(]PLII MOVIE",["0103"]="[)(]PLIIx MUSIC",["0104"]="[)(]PLII MUSIC",["0105"]="[)(]PLIIx GAME",["0106"]="[)(]PLII GAME",["0107"]="[)(]PROLOGIC",["0108"]="Neo:6 CINEMA",["0109"]="Neo:6 MUSIC",["010a"]="XM HD Surround",["010b"]="NEURAL SURR  ",["010c"]="2ch Straight Decode",["010d"]="[)(]PLIIz HEIGHT",["010e"]="WIDE SURR MOVIE",["010f"]="WIDE SURR MUSIC",["0110"]="STEREO",["0111"]="Neo:X CINEMA",["0112"]="Neo:X MUSIC",["0113"]="Neo:X GAME",["0114"]="NEURAL SURROUND+Neo:X CINEMA",["0115"]="NEURAL SURROUND+Neo:X MUSIC",["0116"]="NEURAL SURROUND+Neo:X GAMES",["1101"]="[)(]PLIIx MOVIE",["1102"]="[)(]PLIIx MUSIC",["1103"]="[)(]DIGITAL EX",["1104"]="DTS +Neo:6 / DTS-HD +Neo:6",["1105"]="ES MATRIX",["1106"]="ES DISCRETE",["1107"]="DTS-ES 8ch ",["1108"]="multi ch Straight Decode",["1109"]="[)(]PLIIz HEIGHT",["110a"]="WIDE SURR MOVIE",["110b"]="WIDE SURR MUSIC",["110c"]="Neo:X CINEMA ",["110d"]="Neo:X MUSIC",["110e"]="Neo:X GAME",["0201"]="ACTION",["0202"]="DRAMA",["0203"]="SCI-FI",["0204"]="MONOFILM",["0205"]="ENT.SHOW",["0206"]="EXPANDED",["0207"]="TV SURROUND",["0208"]="ADVANCEDGAME",["0209"]="SPORTS",["020a"]="CLASSICAL   ",["020b"]="ROCK/POP   ",["020c"]="UNPLUGGED   ",["020d"]="EXT.STEREO  ",["020e"]="PHONES SURR. ",["020f"]="FRONT STAGE SURROUND ADVANCE FOCUS",["0210"]="FRONT STAGE SURROUND ADVANCE WIDE",["0211"]="SOUND RETRIEVER AIR",["0301"]="[)(]PLIIx MOVIE +THX",["0302"]="[)(]PLII MOVIE +THX",["0303"]="[)(]PL +THX CINEMA",["0304"]="Neo:6 CINEMA +THX",["0305"]="THX CINEMA",["0306"]="[)(]PLIIx MUSIC +THX",["0307"]="[)(]PLII MUSIC +THX",["0308"]="[)(]PL +THX MUSIC",["0309"]="Neo:6 MUSIC +THX",["030a"]="THX MUSIC",["030b"]="[)(]PLIIx GAME +THX",["030c"]="[)(]PLII GAME +THX",["030d"]="[)(]PL +THX GAMES",["030e"]="THX ULTRA2 GAMES",["030f"]="THX SELECT2 GAMES",["0310"]="THX GAMES",["0311"]="[)(]PLIIz +THX CINEMA",["0312"]="[)(]PLIIz +THX MUSIC",["0313"]="[)(]PLIIz +THX GAMES",["0314"]="Neo:X CINEMA + THX CINEMA",["0315"]="Neo:X MUSIC + THX MUSIC",["0316"]="Neo:X GAMES + THX GAMES",["1301"]="THX Surr EX",["1302"]="Neo:6 +THX CINEMA",["1303"]="ES MTRX +THX CINEMA",["1304"]="ES DISC +THX CINEMA",["1305"]="ES 8ch +THX CINEMA ",["1306"]="[)(]PLIIx MOVIE +THX",["1307"]="THX ULTRA2 CINEMA",["1308"]="THX SELECT2 CINEMA",["1309"]="THX CINEMA",["130a"]="Neo:6 +THX MUSIC",["130b"]="ES MTRX +THX MUSIC",["130c"]="ES DISC +THX MUSIC",["130d"]="ES 8ch +THX MUSIC",["130e"]="[)(]PLIIx MUSIC +THX",["130f"]="THX ULTRA2 MUSIC",["1310"]="THX SELECT2 MUSIC",["1311"]="THX MUSIC",["1312"]="Neo:6 +THX GAMES",["1313"]="ES MTRX +THX GAMES",["1314"]="ES DISC +THX GAMES",["1315"]="ES 8ch +THX GAMES",["1316"]="[)(]EX +THX GAMES",["1317"]="THX ULTRA2 GAMES",["1318"]="THX SELECT2 GAMES",["1319"]="THX GAMES",["131a"]="[)(]PLIIz +THX CINEMA",["131b"]="[)(]PLIIz +THX MUSIC",["131c"]="[)(]PLIIz +THX GAMES",["131d"]="Neo:X CINEMA + THX CINEMA",["131e"]="Neo:X MUSIC + THX MUSIC",["131f"]="Neo:X GAME + THX GAMES",["0401"]="STEREO",["0402"]="[)(]PLII MOVIE",["0403"]="[)(]PLIIx MOVIE",["0404"]="Neo:6 CINEMA",["0405"]="AUTO SURROUND Straight Decode",["0406"]="[)(]DIGITAL EX",["0407"]="[)(]PLIIx MOVIE",["0408"]="DTS +Neo:6",["0409"]="ES MATRIX",["040a"]="ES DISCRETE",["040b"]="DTS-ES 8ch ",["040c"]="XM HD Surround",["040d"]="NEURAL SURR  ",["040e"]="RETRIEVER AIR",["040f"]="Neo:X CINEMA",["0410"]="Neo:X CINEMA ",["0501"]="STEREO",["0502"]="[)(]PLII MOVIE",["0503"]="[)(]PLIIx MOVIE",["0504"]="Neo:6 CINEMA",["0505"]="ALC Straight Decode",["0506"]="[)(]DIGITAL EX",["0507"]="[)(]PLIIx MOVIE",["0508"]="DTS +Neo:6",["0509"]="ES MATRIX",["050a"]="ES DISCRETE",["050b"]="DTS-ES 8ch ",["050c"]="XM HD Surround",["050d"]="NEURAL SURR  ",["050e"]="RETRIEVER AIR",["050f"]="Neo:X CINEMA",["0510"]="Neo:X CINEMA ",["0601"]="STEREO",["0602"]="[)(]PLII MOVIE",["0603"]="[)(]PLIIx MOVIE",["0604"]="Neo:6 CINEMA",["0605"]="STREAM DIRECT NORMAL Straight Decode",["0606"]="[)(]DIGITAL EX",["0607"]="[)(]PLIIx MOVIE",["0608"]="(nothing)",["0609"]="ES MATRIX",["060a"]="ES DISCRETE",["060b"]="DTS-ES 8ch ",["060c"]="Neo:X CINEMA",["060d"]="Neo:X CINEMA ",["0701"]="STREAM DIRECT PURE 2ch",["0702"]="[)(]PLII MOVIE",["0703"]="[)(]PLIIx MOVIE",["0704"]="Neo:6 CINEMA",["0705"]="STREAM DIRECT PURE Straight Decode",["0706"]="[)(]DIGITAL EX",["0707"]="[)(]PLIIx MOVIE",["0708"]="(nothing)",["0709"]="ES MATRIX",["070a"]="ES DISCRETE",["070b"]="DTS-ES 8ch ",["070c"]="Neo:X CINEMA",["070d"]="Neo:X CINEMA ",["0881"]="OPTIMUM",["0e01"]="HDMI THROUGH",["0f01"]="MULTI CH IN"}
  return values[val] or val or '?'
end
function power(val,lul_device)
  local values={['0']='On', ['1']='Off'}
  return values[val] or val or '?'
end
function power_raw(val,lul_device)
  local values={['0']='1', ['1']='0'}
  return values[val] or val or '?'
end
function source(val,lul_device)
  return sources_desc[val] or val or '?'
end
function simpledb(val,lul_device)
  local value = (tonumber(val)-6)*-1
  return  string.format('%s%idB',(value>0 and '+' or (value==0 and '±' or '')),value) or '?'
end
function tone(val,lul_device)
  local values={['0']='Bypass',['1']='On',['9']='Tone'}
  return values[val] or val or '?'
end



























variables_map={
WAKE={command="\r"},
    --get input names first, as they will be used for source queries below
    Get_name=                            {prefix='RGB',                       enabled=false,services={loc_update={convert=store_desc}}},
    Get_name_bd=                         {c_pfix='RGB',command='?RGB25',      enabled=true},
    Get_name_dvd=                        {c_pfix='RGB',command='?RGB04',      enabled=true},
    Get_name_sat_cbl=                    {c_pfix='RGB',command='?RGB06',      enabled=true},
    Get_name_dvr_bdr=                    {c_pfix='RGB',command='?RGB15',      enabled=true},
    Get_name_video_1video=               {c_pfix='RGB',command='?RGB10',      enabled=true},
    Get_name_hdmi_1=                     {c_pfix='RGB',command='?RGB19',      enabled=true},
    Get_name_hdmi_2=                     {c_pfix='RGB',command='?RGB20',      enabled=true},
    Get_name_hdmi_3=                     {c_pfix='RGB',command='?RGB21',      enabled=true},
    Get_name_hdmi_4=                     {c_pfix='RGB',command='?RGB22',      enabled=true},
    Get_name_hdmi_5=                     {c_pfix='RGB',command='?RGB23',      enabled=true},
    Get_name_hdmi_6=                     {c_pfix='RGB',command='?RGB24',      enabled=true},
    Get_name_hdmi_7=                     {c_pfix='RGB',command='?RGB34',      enabled=true},
    Get_name_internet_radio=             {c_pfix='RGB',command='?RGB38',      enabled=true},
    Get_name_siriusxm=                   {c_pfix='RGB',command='?RGB40',      enabled=true},
    Get_name_pandora=                    {c_pfix='RGB',command='?RGB41',      enabled=true},
    Get_name_media_server=               {c_pfix='RGB',command='?RGB44',      enabled=true},
    Get_name_favorites=                  {c_pfix='RGB',command='?RGB45',      enabled=true},
    Get_name_ipod_usb=                   {c_pfix='RGB',command='?RGB17',      enabled=true},
    Get_name_usb_dac=                    {c_pfix='RGB',command='?RGB13',      enabled=true},
    Get_name_tv=                         {c_pfix='RGB',command='?RGB05',      enabled=true},
    Get_name_cd=                         {c_pfix='RGB',command='?RGB01',      enabled=true},
    Get_name_cdr_tape=                   {c_pfix='RGB',command='?RGB03',      enabled=true},
    Get_name_tuner=                      {c_pfix='RGB',command='?RGB02',      enabled=true},
    Get_name_phono=                      {c_pfix='RGB',command='?RGB00',      enabled=true},
    Get_name_multi_ch_in=                {c_pfix='RGB',command='?RGB12',      enabled=true},
    Get_name_adapter_port=               {c_pfix='RGB',command='?RGB33',      enabled=true},
    Power=                               {prefix='PWR',command="?P",          enabled=true,services={[default_service]={var="Power"                        ,convert=power},
                                                                                                     ['urn:upnp-org:serviceId:SwitchPower1']={var="Status" ,convert=power_raw}}},
    Volume=                              {prefix="VOL",command="?V",          enabled=true,services={[default_service]={var="Volume"                       ,convert=volume},
                                                                                                     [default_service]={var="VolumePct"                    ,convert=volume_pct}}},
    Mute=                                {prefix="MUT",command="?M",          enabled=true,services={[default_service]={var="Mute"                         ,convert=mute}}},
    ListeningMode=                       {prefix="LM",command="?L",           enabled=true,services={[default_service]={var="ListeningMode"                ,convert=listeningmode}}},
    DisplayInfo=                         {prefix="FL",command="?FL",          enabled=true,services={[default_service]={var="DisplayInfo"                  ,convert=convert_fl}}},
    TunerPreset=                         {prefix="PR",command="?PR",          enabled=true,services={[default_service]={var="TunerPreset"                  ,convert=tunerpreset}}},
    TunerFreq=                           {prefix="FR",command="?FR",          enabled=true,services={[default_service]={var="TunerFreq"                    ,convert=tunerfreq}}},
    Zone2Mute=                           {prefix="Z2MUT",command="?Z2M",      enabled=true,services={[default_service]={var="Zone2Mute"                    ,convert=mute}}},
    Zone2Volume=                         {prefix="ZV",command="?ZV",          enabled=true,services={[default_service]={var="Zone2VolumePct"               ,convert=zonevolume_pct},
                                                                                                     [default_service]={var="Zone2Volume"                  ,convert=zonevolume}}},
    Zone2Input=                          {prefix="Z2F",command="?ZS",         enabled=true,services={[default_service]={var="Zone2Input"                   ,convert=zoneinput}}},
    Zone2Power=                          {prefix="APR",command="?AP",         enabled=true,services={[default_service]={var="Zone2Power"                   ,convert=power}}},
    Zone2Tone=                           {prefix='ZGA',command='?ZGA',        enabled=true,services={[default_service]={var='Zone2Tone'                    ,convert=tone}}},
    Zone2Bass=                           {prefix='ZGB',command='?ZGB',        enabled=true,services={[default_service]={var='Zone2Bass'                    ,convert=simpledb}}},
    Zone2Treble=                         {prefix='ZGC',command='?ZGC',        enabled=true,services={[default_service]={var='Zone2Treble'                  ,convert=simpledb}}},
    Zone2ChL_Level=                      {prefix='ZGEL__',command='?ZGEL__',  enabled=true,services={[default_service]={var='Zone2ChL_Level'               ,convert=zonelevel}}},
    Zone2ChR_Level=                      {prefix='ZGER__',command='?ZGER__',  enabled=true,services={[default_service]={var='Zone2ChR_Level'               ,convert=zonelevel}}},
                                                                                                                                                           
    Zone3Mute=                           {prefix="Z3MUT",command="?Z3M",      enabled=true,services={[default_service]={var="Zone3Mute"                    ,convert=mute}}},
    Zone3Volume=                         {prefix="YV",command="?YV",          enabled=true,services={[default_service]={var="Zone3VolumePct"               ,convert=zonevolume_pct},
                                                                                                     [default_service]={var="Zone3Volume"                  ,convert=zonevolume}}},
    Zone3Input=                          {prefix="Z3F",command="?ZT",         enabled=true,services={[default_service]={var="Zone3Input"                   ,convert=zoneinput}}},
    Zone3Power=                          {prefix="BPR",command="?BP",         enabled=true,services={[default_service]={var="Zone3Power"                   ,convert=power}}},
    Zone3Tone=                           {prefix='ZHA',command='?ZHA',        enabled=true,services={[default_service]={var='Zone3Tone'                    ,convert=tone}}},
    Zone3Bass=                           {prefix='ZHB',command='?ZHB',        enabled=true,services={[default_service]={var='Zone3Bass'                    ,convert=simpledb}}},
    Zone3Treble=                         {prefix='ZHC',command='?ZHC',        enabled=true,services={[default_service]={var='Zone3Treble'                  ,convert=simpledb}}},
    Zone3ChL_Level=                      {prefix='ZHEL__',command='?ZHEL__',  enabled=true,services={[default_service]={var='Zone3ChL_Level'               ,convert=zonelevel}}},
    Zone3ChR_Level=                      {prefix='ZHER__',command='?ZHER__',  enabled=true,services={[default_service]={var='Zone3ChR_Level'               ,convert=zonelevel}}},
                                                                                                                                                           
    Zone3Mute=                           {prefix="Z4MUT",command="?Z4M",      enabled=true,services={[default_service]={var="Zone4Mute"                    ,convert=mute}}},
    Zone3Volume=                         {prefix="XV",command="?XV",          enabled=true,services={[default_service]={var="Zone4VolumePct"               ,convert=zonevolume_pct},
                                                                                                     [default_service]={var="Zone4Volume"                  ,convert=zonevolume}}},
    Zone3Input=                          {prefix="ZEA",command="?ZEA",        enabled=true,services={[default_service]={var="Zone4Input"                   ,convert=zoneinput}}},
    Zone3Power=                          {prefix="ZEP",command="?ZEP",        enabled=true,services={[default_service]={var="Zone4Power"                   ,convert=power}}},
    Zone3Tone=                           {prefix='ZIA',command='?ZIA',        enabled=true,services={[default_service]={var='Zone4Tone'                    ,convert=tone}}},
    Zone3Bass=                           {prefix='ZIB',command='?ZIB',        enabled=true,services={[default_service]={var='Zone4Bass'                    ,convert=simpledb}}},
    Zone3Treble=                         {prefix='ZIC',command='?ZIC',        enabled=true,services={[default_service]={var='Zone4Treble'                  ,convert=simpledb}}},
    Zone3ChL_Level=                      {prefix='ZIEL__',command='?ZIEL__',  enabled=true,services={[default_service]={var='Zone4ChL_Level'               ,convert=zonelevel}}},
    Zone3ChR_Level=                      {prefix='ZIER__',command='?ZIER__',  enabled=true,services={[default_service]={var='Zone4ChR_Level'               ,convert=zonelevel}}},
    Source=                              {prefix="FN",command="?F",           enabled=true,services={[default_service]={var="Source"                       ,convert=source}}},
    Treble=                              {prefix="TR",command="?TR",          enabled=true,services={[default_service]={var="Treble"                       ,convert=simpledb}}},
    Bass=                                {prefix="BA",command="?BA",          enabled=true,services={[default_service]={var="Bass"                         ,convert=simpledb}}},
    Tone=                                {prefix="TO",command="?TO",          enabled=true,services={[default_service]={var="Tone"                         ,convert=tone}}},
    AudioInfo=                           {prefix="AST",command="?AST",        enabled=true,services={[default_service]={var="AudioInfo"                    ,convert=convert_ast}}},
    VideoInfo=                           {prefix="VST",command="?VST",        enabled=true,services={[default_service]={var="VideoInfo"                    ,convert=convert_vst}}},
    IS=                                  {prefix="IS",command="?IS",          enabled=true,services={[default_service]={var="phase_control"                ,convert=convert_is}}},
    mcacc_memory=                        {prefix='MC',command='?MC',          enabled=true,services={[default_service]={var='mcacc_memory'                 ,convert=conv_mcacc_memory}}},
    virtual_sb=                          {prefix='VSB',command='?VSB',        enabled=true,services={[default_service]={var='virtual_sb'                   ,convert=convert_on_off_cycl}}},
    virtual_height=                      {prefix='VHT',command='?VHT',        enabled=true,services={[default_service]={var='virtual_height'               ,convert=convert_on_off_cycl}}},
    sound_retriever=                     {prefix='ATA',command='?ATA',        enabled=true,services={[default_service]={var='sound_retriever'              ,convert=convert_on_off_cycl}}},
    signal_select=                       {prefix='SDA',command='?SDA',        enabled=true,services={[default_service]={var='signal_select'                ,convert=conv_signal_select}}},
    analog_input_att=                    {prefix='SDB',command='?SDB',        enabled=true,services={[default_service]={var='analog_input_att'             ,convert=convert_on_off_cycl}}},
    eq=                                  {prefix='ATC',command='?ATC',        enabled=true,services={[default_service]={var='eq'                           ,convert=convert_on_off_cycl}}},
    standing_wave=                       {prefix='ATD',command='?ATD',        enabled=true,services={[default_service]={var='standing_wave'                ,convert=convert_on_off_cycl}}},
    phase_control_plus=                  {prefix='ATE',command='?ATE',        enabled=true,services={[default_service]={var='phase_control_plus'           ,convert=conv_phase_control_plus}}},
    sound_delay=                         {prefix='ATF',command='?ATF',        enabled=true,services={[default_service]={var='sound_delay'                  ,convert=conv_sound_delay}}},
    digital_noise_reduction=             {prefix='ATG',command='?ATG',        enabled=true,services={[default_service]={var='digital_noise_reduction'      ,convert=convert_on_off_cycl}}},
    dialog_enhacement=                   {prefix='ATH',command='?ATH',        enabled=true,services={[default_service]={var='dialog_enhacement'            ,convert=conv_dialog_enhacement}}},
    hi_bit=                              {prefix='ATI',command='?ATI',        enabled=true,services={[default_service]={var='hi_bit'                        ,convert=convert_on_off_cycl}}},
    dual_mono=                           {prefix='ATJ',command='?ATJ',        enabled=true,services={[default_service]={var='dual_mono'                     ,convert=conv_dual_mono}}},
    fixed_pcm=                           {prefix='ATK',command='?ATK',        enabled=true,services={[default_service]={var='fixed_pcm'                     ,convert=convert_on_off_cycl}}},
    drc=                                 {prefix='ATL',command='?ATL',        enabled=true,services={[default_service]={var='drc'                           ,convert=conv_drc}}},
    lfe_att=                             {prefix='ATM',command='?ATM',        enabled=true,services={[default_service]={var='lfe_att'                       ,convert=conv_lfe_att}}},
    sacd_gain=                           {prefix='ATN',command='?ATN',        enabled=true,services={[default_service]={var='sacd_gain'                     ,convert=conv_sacd_gain}}},
    auto_delay=                          {prefix='ATO',command='?ATO',        enabled=true,services={[default_service]={var='auto_delay'                    ,convert=convert_on_off_cycl}}},
    center_width_pl2_music_option=       {prefix='ATP',command='?ATP',        enabled=true,services={[default_service]={var='center_width_pl2_music_option' ,convert=conv_formatnum_3digits}}},
    panorama_pl2_music_option=           {prefix='ATQ',command='?ATQ',        enabled=true,services={[default_service]={var='panorama_pl2_music_option'     ,convert=convert_on_off_cycl}}},
    dimension_pl2_music_option=          {prefix='ATR',command='?ATR',        enabled=true,services={[default_service]={var='dimension_pl2_music_option'    ,convert=conv_dimension}}},
    center_image_neo_option=             {prefix='ATS',command='?ATS',        enabled=true,services={[default_service]={var='center_image_neo_option'       ,convert=conv_center_image_neo_option}}},
    effect=                              {prefix='ATT',command='?ATT',        enabled=true,services={[default_service]={var='effect'                        ,convert=conv_formatnum_3digits}}},
    height_gain_pl2z_height_option=      {prefix='ATU',command='?ATU',        enabled=true,services={[default_service]={var='height_gain_pl2z_height_option',convert=conv_low_mid_high}}},
    virtual_depth=                       {prefix='VDP',command='?VDP',        enabled=true,services={[default_service]={var='virtual_depth'                 ,convert=conv_min_mid_max}}},
    digital_filter=                      {prefix='ATV',command='?ATV',        enabled=true,services={[default_service]={var='digital_filter'                ,convert=conv_slow_sharp_short}}},
    loudness_management=                 {prefix='ATW',command='?ATW',        enabled=true,services={[default_service]={var='loudness_management'           ,convert=convert_on_off_cycl}}},
    virtual_wide=                        {prefix='VWD',command='?VWD',        enabled=true,services={[default_service]={var='virtual_wide'                  ,convert=convert_on_off_cycl}}},
    ch_level_L=                          {prefix='CLVL__',command='?L__CLV',  enabled=true,services={[default_service]={var='ch_level_L'                    ,convert=conv_ch_level}}},
    ch_level_R=                          {prefix='CLVR__',command='?R__CLV',  enabled=true,services={[default_service]={var='ch_level_R'                    ,convert=conv_ch_level}}},
    ch_level_C=                          {prefix='CLVC__',command='?C__CLV',  enabled=true,services={[default_service]={var='ch_level_C'                    ,convert=conv_ch_level}}},
    ch_level_SL=                         {prefix='CLVSL_',command='?SL_CLV',  enabled=true,services={[default_service]={var='ch_level_SL'                   ,convert=conv_ch_level}}},
    ch_level_SR=                         {prefix='CLVSR_',command='?SR_CLV',  enabled=true,services={[default_service]={var='ch_level_SR'                   ,convert=conv_ch_level}}},
    ch_level_SBL=                        {prefix='CLVSBL',command='?SBLCLV',  enabled=true,services={[default_service]={var='ch_level_SBL'                  ,convert=conv_ch_level}}},
    ch_level_SBR=                        {prefix='CLVSBR',command='?SBRCLV',  enabled=true,services={[default_service]={var='ch_level_SBR'                  ,convert=conv_ch_level}}},
    ch_level_SW=                         {prefix='CLVSW_',command='?SW_CLV',  enabled=true,services={[default_service]={var='ch_level_SW'                   ,convert=conv_ch_level}}},
    ch_level_LH=                         {prefix='CLVLH_',command='?LH_CLV',  enabled=true,services={[default_service]={var='ch_level_LH'                   ,convert=conv_ch_level}}},
    ch_level_RH=                         {prefix='CLVRH_',command='?RH_CLV',  enabled=true,services={[default_service]={var='ch_level_RH'                   ,convert=conv_ch_level}}},
    ch_level_LW=                         {prefix='CLVLW_',command='?LW_CLV',  enabled=true,services={[default_service]={var='ch_level_LW'                   ,convert=conv_ch_level}}},
    ch_level_RW=                         {prefix='CLVRW_',command='?RW_CLV',  enabled=true,services={[default_service]={var='ch_level_RW'                   ,convert=conv_ch_level}}},
    amp_speakers=                        {prefix='SPK',command='?SPK',        enabled=true,services={[default_service]={var='amp_speakers'                  ,convert=conv_amp_speakers}}},
    amp_hdmi_output=                     {prefix='HO',command='?HO',          enabled=true,services={[default_service]={var='amp_hdmi_output'               ,convert=conv_amp_hdmi_output}}},
    amp_hdmi_audio=                      {prefix='HA',command='?HA',          enabled=true,services={[default_service]={var='amp_hdmi_audio'                ,convert=conv_amp_hdmi_audio}}},
    amp_pqls_setting=                    {prefix='PQ',command='?PQ',          enabled=true,services={[default_service]={var='amp_pqls_setting'              ,convert=conv_amp_pqls_setting}}},
    amp_sleep_remain_time=               {prefix='SAB',command='?SAB',        enabled=true,services={[default_service]={var='amp_sleep_remain_time'         ,convert=conv_amp_sleep_remain_time}}},
    amp=                                 {prefix='SAC',command='?SAC',        enabled=true,services={[default_service]={var='amp'                           ,convert=conv_amp}}},
    panel_key_lock=                      {prefix='PKL',command='?PKL',        enabled=true,services={[default_service]={var='panel_key_lock'                ,convert=conv_panel_key_lock}}},
    remote_lock=                         {prefix='RML',command='?RML',        enabled=true,services={[default_service]={var='remote_lock'                   ,convert=conv_remote_lock}}},
    video_converter=                     {prefix='VTB',command='?VTB',        enabled=true,services={[default_service]={var='video_converter'               ,convert=conv_video_converter}}},
    video_resolution=                    {prefix='VTC',command='?VTC',        enabled=true,services={[default_service]={var='video_resolution'              ,convert=conv_video_resolution}}},
    video_pure_cinema=                   {prefix='VTD',command='?VTD',        enabled=true,services={[default_service]={var='video_pure_cinema'             ,convert=conv_video_pure_cinema}}},
    video_prog_motion=                   {prefix='VTE',command='?VTE',        enabled=true,services={[default_service]={var='video_prog_motion'             ,convert=conv_video_prog_motion}}},
    video_stream_smoother=               {prefix='VTF',command='?VTF',        enabled=true,services={[default_service]={var='video_stream_smoother'         ,convert=conv_video_stream_smoother}}},
    video_advanced_video_adjust=         {prefix='VTG',command='?VTG',        enabled=true,services={[default_service]={var='video_advanced_video_adjust'   ,convert=conv_video_advanced_video_adjust}}},
    video_ynr=                           {prefix='VTH',command='?VTH',        enabled=true,services={[default_service]={var='video_ynr'                     ,convert=conv_number_base50}}},
    video_cnr=                           {prefix='VTI',command='?VTI',        enabled=true,services={[default_service]={var='video_cnr'                     ,convert=conv_number_base50}}},
    video_bnr=                           {prefix='VTJ',command='?VTJ',        enabled=true,services={[default_service]={var='video_bnr'                     ,convert=conv_number_base50}}},
    video_mnr=                           {prefix='VTK',command='?VTK',        enabled=true,services={[default_service]={var='video_mnr'                     ,convert=conv_number_base50}}},
    video_detail=                        {prefix='VTL',command='?VTL',        enabled=true,services={[default_service]={var='video_detail'                  ,convert=conv_number_base50}}},
    video_sharpness=                     {prefix='VTM',command='?VTM',        enabled=true,services={[default_service]={var='video_sharpness'               ,convert=conv_number_base50}}},
    video_brightness=                    {prefix='VTN',command='?VTN',        enabled=true,services={[default_service]={var='video_brightness'              ,convert=conv_number_base50}}},
    video_contrast=                      {prefix='VTO',command='?VTO',        enabled=true,services={[default_service]={var='video_contrast'                ,convert=conv_number_base50}}},
    video_hue=                           {prefix='VTP',command='?VTP',        enabled=true,services={[default_service]={var='video_hue'                     ,convert=conv_number_base50}}},
    video_chroma_level=                  {prefix='VTQ',command='?VTQ',        enabled=true,services={[default_service]={var='video_chroma_level'            ,convert=conv_number_base50}}},
    video_black_setup=                   {prefix='VTR',command='?VTR',        enabled=true,services={[default_service]={var='video_black_setup'             ,convert=conv_video_black_setup}}},
    video_aspect=                        {prefix='VTS',command='?VTS',        enabled=true,services={[default_service]={var='video_aspect'                  ,convert=conv_video_aspect}}}

}

-- -------------------------------------------------------------------------
-- Mappings definition
-- additional documentation can be found here
-- https://www.pioneerelectronics.ca/StaticFiles/Custom%20Install/RS-232%20Codes/Av%20Receivers/Elite%20&%20Pioneer%20FY13AVR%20IP%20&%20RS-232%205-8-12.xls
--
service_map = {
  ["urn:micasaverde-com:serviceId:InputSelection1"] = {
    ["DiscreteinputCable"] = {command="06FN"},    -- TV/SAT
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
function test()

  luup.log(string.format('PioneerReceiverFormats Tuner preset A01,G09,I11   : %s,%s,%s',tunerpreset('A01'),tunerpreset('G09'),tunerpreset('I11')))
  luup.log(string.format('PioneerReceiverFormats Tuner test AM 530kHz       : %s',tunerfreq('A00530')))
  luup.log(string.format('PioneerReceiverFormats Tuner test AM 1700kHz      : %s',tunerfreq('A01700')))
  luup.log(string.format('PioneerReceiverFormats Tuner test FM 87.50MHz     : %s',tunerfreq('F08750')))
  luup.log(string.format('PioneerReceiverFormats Tuner test FM 108.00MHz    : %s',tunerfreq('F10800')))
  luup.log(string.format('PioneerReceiverFormats FL  [)(]DIGITAL EX  test   : %s',convert_fl('000005094449474954414C00455800')))
  luup.log(string.format('PioneerReceiverFormats Bit 1,0 test               : %s,%s',bits('80',7),bits('FD',1)))
  luup.log(string.format('PioneerReceiverFormats VOL123 val extract Test    : %s',get_value('VOL123','VOL')))
  luup.log(string.format('PioneerReceiverFormats Volume test 12,11,0,-80,min: %s,%s,%s,%s,%s',volume('185'),volume('184'),volume('161'),volume('001'),volume('000')))
  luup.log(string.format('PioneerReceiverFormats Volume pct test 0,10,30,100: %s,%s,%s,%s',volume_pct('0'),volume_pct('18'),volume_pct('55'),volume_pct('185')))
  luup.log(string.format('PioneerReceiverFormats Zone Volume test 0,-80,min : %s,%s,%s',zonevolume('81'),zonevolume('01'),zonevolume('00')))
  luup.log(string.format('PioneerReceiverFormats Audio Format Test          : %s',convert_ast('0502111110001000000000000111111011000000000')))
  luup.log(string.format('PioneerReceiverFormats Audio Format Test          : %s',convert_vst('10123221122210310100009110000050606100100')))
  luup.log()
  luup.log(string.format('PioneerReceiverFormats PLIIx listening mode Test  : %s',listeningmode('0103')))
  luup.log(string.format('PioneerReceiverFormats Mute On,Off Test           : %s,%s',mute('0'),mute('1')))
  luup.log(string.format('PioneerReceiverFormats Power On,Off Test          : %s,%s',power('0'),power('1')))
  luup.log(string.format('PioneerReceiverFormats Source SAT/CBL Test        : %s',source('06')))
  luup.log(string.format('PioneerReceiverFormats Simple DB -6,0,+6 Test     : %s,%s,%s',simpledb('12'),simpledb('6'),simpledb('0')))
  luup.log(string.format('PioneerReceiverFormats Tone Bypass,On,Tone Test   : %s,%s,%s',tone('0'),tone('1'),tone('9')))
end
--test()

