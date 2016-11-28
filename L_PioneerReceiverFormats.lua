_fmt = {}

function _fmt.resolve_bitstring(bitstring,map)
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
function _fmt.bits(hex,n)
  local nmap = {['0']='0000',['1']='0001',['2']='0010',['3']='0011',['4']='0100',['5']='0101',['6']='0110',['7']='0111',['8']='1000',['9']='1001',['A']='1010',['B']='1011',['C']='1100',['D']='1101',['E']='1110',['F']='1111'}
  local pos = 2-math.ceil(n/4)+1 -- bits 1-8 are in char 1 and 9-16 in char 2
  local _,rem = math.modf(n/4)
  local index = 4-rem*4 -- get position inside 4 bits array
  if(hex:len()<pos) then return '?'end
  return string.sub(nmap[string.sub(hex,pos,pos)],index,index)

end
function _fmt.hextochar(hex)
  local output = ''
  local _,ret = math.modf(hex:len()/2)
  if(hex == nil or (ret~=0)) then return '?'end
  local i=1
  while i<hex:len() do
    local curhex = hex:sub(i,i+1)
    local n = tonumber(curhex,16)+string.byte(' ')
    output = output..string.char(n)
    i=i+2
  end
  return output
end
function _fmt.convert_fl(val,lul_device)
  local values = {['1']='Light', ['0']='Off'}
  local flags=string.sub(val,1,2)
  local output = _fmt.bits(flags,1)=='1' and 'VOL ' or _fmt.bits(flags,0)=='1' and 'GUID ' or ''
  output = output.._fmt.hextochar(string.sub(val,3,30))
  return output:upper()
end
function _fmt.tunerpreset(val,lul_device)
  if(val:len() < 3) then return '?' end
  if(val:sub(1,1):byte() >= string.byte("A") and val:sub(1,1):byte() <= string.byte("Z")  ) then return val end
  local bank=string.char(string.byte('A')+tonumber(val:sub(1,1))-1)
  return bank..val:sub(2,3)
end
function _fmt.zoneinput(val,lul_device)
  local values = {['04']='DVD',['06']='SAT/CBL',['15']='DVR/BDR',['10']='VIDEO 1(VIDEO)',['26']='NETWORK (cyclic)',['38']='INTERNET RADIO',['40']='SiriusXM',['41']='PANDORA',['44']='MEDIA SERVER',['45']='FAVORITES',['17']='iPod/USB',['13']='USB-DAC',['05']='TV',['01']='CD',['02']='TUNER',['33']='ADAPTER PORT'}
  return values[val] or '?'
end
function _fmt.convert_ast(val,lul_device)
  local input_signal_values = {["00"]="ANALOG",["01"]="ANALOG",["02"]="ANALOG",["03"]="PCM",["04"]="PCM",["05"]="DOLBY DIGITAL",["06"]="DTS",["07"]="DTS-ES Matrix",["08"]="DTS-ES Discrete",["09"]="DTS 96/24",["10"]="DTS 96/24 ES Matrix",["11"]="DTS 96/24 ES Discrete",["12"]="MPEG-2 AAC",["13"]="WMA9 Pro",["14"]="DSD->PCM",["15"]="HDMI THROUGH",["16"]="DOLBY DIGITAL PLUS",["17"]="DOLBY TrueHD",["18"]="DTS EXPRESS",["19"]="DTS-HD Master Audio",["20"]="DTS-HD High Resolution",["21"]="DTS-HD High Resolution",["22"]="DTS-HD High Resolution",["23"]="DTS-HD High Resolution",["24"]="DTS-HD High Resolution",["25"]="DTS-HD High Resolution",["26"]="DTS-HD High Resolution",["27"]="DTS-HD Master Audio"  }
  local input_frequency_values={["00"]="32kHz",["01"]="44.1kHz",["02"]="48kHz",["03"]="88.2kHz",["04"]="96kHz",["05"]="176.4kHz",["06"]="192kHz",["07"]="---",  }
  local input_channel_format_values = {[1]="L",[2]="C",[3]="R",[4]="SL",[5]="SR",[6]="SBL",[7]="S",[8]="SBR",[9]="LFE",[10]="FHL",[11]="FHR",[12]="FWL",[13]="FWR",[14]="XL",[15]="XC",[16]="XR"  }
  local output_channel_format_values = {[1]="L",[2]="C",[3]="R",[4]="SL",[5]="SR",[6]="SBL",[7]="SB",[8]="SBR",[9]="SW",[10]="FHL",[11]="FHR",[12]="FWL",[13]="FWR"  }
  local input_signal_code=string.sub(val,1,2)
  local input_frequency_code=string.sub(val,3,4)
  local input_channel_format_code=string.sub(val,5,25)
  local output_channel_format_code=string.sub(val,26,43)

  -- determine input format
  local input_channel = _fmt.resolve_bitstring(input_channel_format_code,input_channel_format_values)
  local output_channel =  _fmt.resolve_bitstring(output_channel_format_code,output_channel_format_values)

  return string.format('%s %s %s => %s',input_channel,input_signal_values[input_signal_code] or '?input',input_frequency_values[input_frequency_code] or '?frequency',output_channel)
end

function _fmt.convert_vst(val,lul_device)

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
  local HDMI_1_Monitor_Extend_Color_Space_val = _fmt.resolve_bitstring(HDMI_1_Monitor_Extend_Color_Space_code,HDMI_1_Monitor_Extend_Color_Space_values)
  local HDMI_2_Monitor_Recommend_Resolution_Information_val = HDMI_2_Monitor_Recommend_Resolution_Information_code ~='0' and HDMI_2_Monitor_Recommend_Resolution_Information_values[HDMI_2_Monitor_Recommend_Resolution_Information_code] or '?'
  local HDMI_2_Monitor_DeepColor_val = HDMI_2_Monitor_DeepColor_code ~='0' and HDMI_2_Monitor_DeepColor_values[HDMI_2_Monitor_DeepColor_code] or '?'
  local HDMI_2_Monitor_Extend_Color_Space_val = _fmt.resolve_bitstring(HDMI_2_Monitor_Extend_Color_Space_code,HDMI_2_Monitor_Extend_Color_Space_values)
  local Input_3D_format_HDMI_only_val = Input_3D_format_HDMI_only_code ~='0' and Input_3D_format_HDMI_only_values[Input_3D_format_HDMI_only_code] or '?'
  local Output_3D_format_HDMI_only_val = Output_3D_format_HDMI_only_code ~='0' and Output_3D_format_HDMI_only_values[Output_3D_format_HDMI_only_code] or '?'
  local HDMI_ZONE_Monitor_Recommend_Resolution_Information_val = HDMI_ZONE_Monitor_Recommend_Resolution_Information_code ~='0' and HDMI_ZONE_Monitor_Recommend_Resolution_Information_values[HDMI_ZONE_Monitor_Recommend_Resolution_Information_code] or '?'
  local HDMI_ZONE_Monitor_DeepColor_val = HDMI_ZONE_Monitor_DeepColor_code ~='0' and HDMI_ZONE_Monitor_DeepColor_values[HDMI_ZONE_Monitor_DeepColor_code] or '?'
  local HDMI_ZONE_Monitor_Extend_Color_Space_val = _fmt.resolve_bitstring(HDMI_ZONE_Monitor_Extend_Color_Space_code,HDMI_ZONE_Monitor_Extend_Color_Space_values)
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

function _fmt.get_value(val,prefix)
  return string.sub(val,prefix:len()+1,val:len())
end
function _fmt.volume(val,lul_device)
  local volval = tonumber(val)*0.5-80.5
  --return  string.format('%ldB',(volval or 0)*0.5-80.5) or '?'
  return  tonumber(val) == 0 and '--dB(MIN)' or ( string.format('%s%idB',(volval>0 and '+' or (volval==0 and '±' or '')),volval) or '?')
end
function _fmt.volume_pct(val,lul_device)
  return  math.ceil(tonumber(val)/185*100)
end
function _fmt.zonevolume(val,lul_device)
  local volval = tonumber(val)-81
  return  tonumber(val) == 0 and '--dB(MIN)' or (string.format('%s%idB',(volval>0 and '+' or (volval==0 and '±' or '')),volval) or '?')
end
function _fmt.mute(val,lul_device)
  local values = {['0']='On', ['1']='Off'}
  return values[val] or '?'
end
function _fmt.tunerfreq(val,lul_device)
  local values = {['A']='AM', ['F']='FM'}
  local af = val:sub(1,1) or ''
  
  local freq = af=='A' and string.format('%u',tonumber(val:sub(2,6))) or af=='F' and string.format('%.2f',tonumber(val:sub(2,6))/100) or ''
  local freqtxt = af=='A' and 'kHz' or af=='F' and 'MHz' or '?'
  
  output = string.format('%s %s%s',values[af] or '',freq,freqtxt)
  
  return output
end
function _fmt.listeningmode(val,lul_device)
  local values = {["0101"]="[)(]PLIIx MOVIE",["0102"]="[)(]PLII MOVIE",["0103"]="[)(]PLIIx MUSIC",["0104"]="[)(]PLII MUSIC",["0105"]="[)(]PLIIx GAME",["0106"]="[)(]PLII GAME",["0107"]="[)(]PROLOGIC",["0108"]="Neo:6 CINEMA",["0109"]="Neo:6 MUSIC",["010a"]="XM HD Surround",["010b"]="NEURAL SURR  ",["010c"]="2ch Straight Decode",["010d"]="[)(]PLIIz HEIGHT",["010e"]="WIDE SURR MOVIE",["010f"]="WIDE SURR MUSIC",["0110"]="STEREO",["0111"]="Neo:X CINEMA",["0112"]="Neo:X MUSIC",["0113"]="Neo:X GAME",["0114"]="NEURAL SURROUND+Neo:X CINEMA",["0115"]="NEURAL SURROUND+Neo:X MUSIC",["0116"]="NEURAL SURROUND+Neo:X GAMES",["1101"]="[)(]PLIIx MOVIE",["1102"]="[)(]PLIIx MUSIC",["1103"]="[)(]DIGITAL EX",["1104"]="DTS +Neo:6 / DTS-HD +Neo:6",["1105"]="ES MATRIX",["1106"]="ES DISCRETE",["1107"]="DTS-ES 8ch ",["1108"]="multi ch Straight Decode",["1109"]="[)(]PLIIz HEIGHT",["110a"]="WIDE SURR MOVIE",["110b"]="WIDE SURR MUSIC",["110c"]="Neo:X CINEMA ",["110d"]="Neo:X MUSIC",["110e"]="Neo:X GAME",["0201"]="ACTION",["0202"]="DRAMA",["0203"]="SCI-FI",["0204"]="MONOFILM",["0205"]="ENT.SHOW",["0206"]="EXPANDED",["0207"]="TV SURROUND",["0208"]="ADVANCEDGAME",["0209"]="SPORTS",["020a"]="CLASSICAL   ",["020b"]="ROCK/POP   ",["020c"]="UNPLUGGED   ",["020d"]="EXT.STEREO  ",["020e"]="PHONES SURR. ",["020f"]="FRONT STAGE SURROUND ADVANCE FOCUS",["0210"]="FRONT STAGE SURROUND ADVANCE WIDE",["0211"]="SOUND RETRIEVER AIR",["0301"]="[)(]PLIIx MOVIE +THX",["0302"]="[)(]PLII MOVIE +THX",["0303"]="[)(]PL +THX CINEMA",["0304"]="Neo:6 CINEMA +THX",["0305"]="THX CINEMA",["0306"]="[)(]PLIIx MUSIC +THX",["0307"]="[)(]PLII MUSIC +THX",["0308"]="[)(]PL +THX MUSIC",["0309"]="Neo:6 MUSIC +THX",["030a"]="THX MUSIC",["030b"]="[)(]PLIIx GAME +THX",["030c"]="[)(]PLII GAME +THX",["030d"]="[)(]PL +THX GAMES",["030e"]="THX ULTRA2 GAMES",["030f"]="THX SELECT2 GAMES",["0310"]="THX GAMES",["0311"]="[)(]PLIIz +THX CINEMA",["0312"]="[)(]PLIIz +THX MUSIC",["0313"]="[)(]PLIIz +THX GAMES",["0314"]="Neo:X CINEMA + THX CINEMA",["0315"]="Neo:X MUSIC + THX MUSIC",["0316"]="Neo:X GAMES + THX GAMES",["1301"]="THX Surr EX",["1302"]="Neo:6 +THX CINEMA",["1303"]="ES MTRX +THX CINEMA",["1304"]="ES DISC +THX CINEMA",["1305"]="ES 8ch +THX CINEMA ",["1306"]="[)(]PLIIx MOVIE +THX",["1307"]="THX ULTRA2 CINEMA",["1308"]="THX SELECT2 CINEMA",["1309"]="THX CINEMA",["130a"]="Neo:6 +THX MUSIC",["130b"]="ES MTRX +THX MUSIC",["130c"]="ES DISC +THX MUSIC",["130d"]="ES 8ch +THX MUSIC",["130e"]="[)(]PLIIx MUSIC +THX",["130f"]="THX ULTRA2 MUSIC",["1310"]="THX SELECT2 MUSIC",["1311"]="THX MUSIC",["1312"]="Neo:6 +THX GAMES",["1313"]="ES MTRX +THX GAMES",["1314"]="ES DISC +THX GAMES",["1315"]="ES 8ch +THX GAMES",["1316"]="[)(]EX +THX GAMES",["1317"]="THX ULTRA2 GAMES",["1318"]="THX SELECT2 GAMES",["1319"]="THX GAMES",["131a"]="[)(]PLIIz +THX CINEMA",["131b"]="[)(]PLIIz +THX MUSIC",["131c"]="[)(]PLIIz +THX GAMES",["131d"]="Neo:X CINEMA + THX CINEMA",["131e"]="Neo:X MUSIC + THX MUSIC",["131f"]="Neo:X GAME + THX GAMES",["0401"]="STEREO",["0402"]="[)(]PLII MOVIE",["0403"]="[)(]PLIIx MOVIE",["0404"]="Neo:6 CINEMA",["0405"]="AUTO SURROUND Straight Decode",["0406"]="[)(]DIGITAL EX",["0407"]="[)(]PLIIx MOVIE",["0408"]="DTS +Neo:6",["0409"]="ES MATRIX",["040a"]="ES DISCRETE",["040b"]="DTS-ES 8ch ",["040c"]="XM HD Surround",["040d"]="NEURAL SURR  ",["040e"]="RETRIEVER AIR",["040f"]="Neo:X CINEMA",["0410"]="Neo:X CINEMA ",["0501"]="STEREO",["0502"]="[)(]PLII MOVIE",["0503"]="[)(]PLIIx MOVIE",["0504"]="Neo:6 CINEMA",["0505"]="ALC Straight Decode",["0506"]="[)(]DIGITAL EX",["0507"]="[)(]PLIIx MOVIE",["0508"]="DTS +Neo:6",["0509"]="ES MATRIX",["050a"]="ES DISCRETE",["050b"]="DTS-ES 8ch ",["050c"]="XM HD Surround",["050d"]="NEURAL SURR  ",["050e"]="RETRIEVER AIR",["050f"]="Neo:X CINEMA",["0510"]="Neo:X CINEMA ",["0601"]="STEREO",["0602"]="[)(]PLII MOVIE",["0603"]="[)(]PLIIx MOVIE",["0604"]="Neo:6 CINEMA",["0605"]="STREAM DIRECT NORMAL Straight Decode",["0606"]="[)(]DIGITAL EX",["0607"]="[)(]PLIIx MOVIE",["0608"]="(nothing)",["0609"]="ES MATRIX",["060a"]="ES DISCRETE",["060b"]="DTS-ES 8ch ",["060c"]="Neo:X CINEMA",["060d"]="Neo:X CINEMA ",["0701"]="STREAM DIRECT PURE 2ch",["0702"]="[)(]PLII MOVIE",["0703"]="[)(]PLIIx MOVIE",["0704"]="Neo:6 CINEMA",["0705"]="STREAM DIRECT PURE Straight Decode",["0706"]="[)(]DIGITAL EX",["0707"]="[)(]PLIIx MOVIE",["0708"]="(nothing)",["0709"]="ES MATRIX",["070a"]="ES DISCRETE",["070b"]="DTS-ES 8ch ",["070c"]="Neo:X CINEMA",["070d"]="Neo:X CINEMA ",["0881"]="OPTIMUM",["0e01"]="HDMI THROUGH",["0f01"]="MULTI CH IN"}
  return values[val] or val or '?'
end
function _fmt.power(val,lul_device)
  local values={['0']='On', ['1']='Off'}
  return values[val] or val or '?'
end
function _fmt.power_raw(val,lul_device)
  local values={['0']='1', ['1']='0'}
  return values[val] or val or '?'
end
function _fmt.source(val,lul_device)
  local values = {    ['25']="BD",['04']="DVD",['06']="SAT/CBL",['15']="DVR/BDR",['10']="VIDEO 1(VIDEO)",['19']="HDMI 1",['20']="HDMI 2",['21']="HDMI 3",['22']="HDMI 4",['23']="HDMI 5",['24']="HDMI 6",['34']="HDMI 7",['26']="NETWORK (cyclic)",['38']="INTERNET RADIO",['40']="SiriusXM",['41']="PANDORA",['44']="MEDIA SERVER",['45']="FAVORITES",['17']="iPod/USB",['05']="TV",['01']="CD",['13']="USB-DAC",['02']="TUNER",['00']="PHONO",['12']="MULTI CH IN",['33']="ADAPTER PORT",['48']="MHL",['31']="HDMI (cyclic)"}
  return values[val] or val or '?'
end
function _fmt.simpledb(val,lul_device)
  local value = (tonumber(val)-6)*-1
  return  string.format('%s%idB',(value>0 and '+' or (value==0 and '±' or '')),value) or '?'
end
function _fmt.tone(val,lul_device)
  local values={['0']='Bypass',['1']='On',['9']='Tone'}
  return values[val] or val or '?'
end
_fmt.variables_map = {
  ["WAKE"] =    {
    command="\r"},
  ["POWER"] =   {
    prefix="PWR",   
    command="?P",   
    enabled="true",
    services = {
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={ 
        var ="Power", 
        convert=_fmt.power 
      },
      ['urn:upnp-org:serviceId:SwitchPower1'] = { 
        var ="Status", 
        convert=_fmt.power_raw 
      }
    }
  },
  ["VOLUME"]= {
    prefix="VOL",   
    command="?V",   
    enabled=true, 
    services = { 
      ['urn:micasaverde-com:serviceId:PioneerReceiver1'] = {
        var ="Volume", 
        convert=_fmt.volume
      },
      ['urn:micasaverde-com:serviceId:PioneerReceiver1'] = {
        var ="VolumePct", 
        convert=_fmt.volume_pct
      }      
    }
  },
  ["MUTE"]= {
    prefix="MUT",   
    command="?M",   
    enabled=true, 
    services ={ 
      ['urn:micasaverde-com:serviceId:PioneerReceiver1'] = {
        var ="Mute", 
        convert=_fmt.mute
      }
    }
  },
  ["LISTENINGMODE"]= {
    prefix="LM",    
    command="?L",   
    enabled=true, 
    services ={ 
      ['urn:micasaverde-com:serviceId:PioneerReceiver1'] = {
        var ="ListeningMode", 
        convert=_fmt.listeningmode
      }
    }
  },
  ["DISPLAYINFO"]= {
    prefix="FL",    
    command="?FL",  
    enabled=true, 
    services ={ 
      ['urn:micasaverde-com:serviceId:PioneerReceiver1'] = { 
        var ="DisplayInfo", convert=_fmt.convert_fl 
      }
    }
  },
  ["TUNERPRESET"]=  {
    prefix="PR",
    command="?PR",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="TunerPreset",
        convert=_fmt.tunerpreset
      }
    }
  },
  ["TUNERFREQ"]={
    prefix="FR",
    command="?FR",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="TunerFreq",
        convert=_fmt.tunerfreq
      }
    }
  },
  ["ZONE3MUTE"]=    {
    prefix="Z3MUT",
    command="?Z3M",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone3Mute"
        ,convert=_fmt.mute
      }
    }
  },
  ["ZONE3VOLUME"]=  {
      prefix="YV",
      command="?YV",
      enabled=true,
      services={
        ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
          var="zone3volume",
          convert=_fmt.zonevolume
        }
      }
    },
  ["ZONE3INPUT"]= {
    prefix="Z3F",
    command="?ZT",
    enabled=true,
    services={
        ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
          var="Zone3Input",
          convert=_fmt.zoneinput
        }
      }
    },
  ["ZONE3POWER"]= {
    prefix="BPR",
    command="?BP",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone3Power",
        convert=_fmt.power
      }
    }
  },
  ["ZONE2MUTE"]=    {
    prefix="Z2MUT",
    command="?Z2M",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone2Mute",
        convert=_fmt.mute
      }
    }
  },
  ["ZONE2VOLUME"]=  {
    prefix="ZV",
    command="?ZV",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone2Volume",
        convert=_fmt.zonevolume
      }
    }
  },
  ["ZONE2INPUT"]= {
    prefix="Z2F",
    command="?ZS",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone2Input",
        convert=_fmt.zoneinput
      }
    }
  },
  ["ZONE2POWER"]= {
    prefix="APR",
    command="?AP",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Zone2Power",
        convert=_fmt.power
      }
    }
  },
  ["SOURCE"]= {
    prefix="FN",
    command="?F", enabled=true, 
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Source",
        convert=_fmt.source
      }
    }
  },
  ["TREBLE"]=     {
    prefix="TR",
    command="?TR",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Treble",
        convert=_fmt.simpledb
      }
    }
  },
  ["BASS"]=     {
    prefix="BA",
    command="?BA",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Bass",
        convert=_fmt.simpledb
      }
    }
  },
  ["TONE"]=     {
    prefix="TO",
    command="?TO",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="Tone",
        convert=_fmt.tone
      }
    }
  },
  ["AST"]={
    prefix="AST",
    command="?AST",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="AudioInfo",
        convert=_fmt.convert_ast
      }
    }
  },
  ["VST"]={
    prefix="VST",
    command="?VST",
    enabled=true,
    services={
      ['urn:micasaverde-com:serviceId:PioneerReceiver1']={
        var="VideoInfo",
        convert=_fmt.convert_vst
      }
    }
  }
}
function _fmt.test()

  print(string.format('Tuner preset A01,G09,I11   : %s,%s,%s',_fmt.tunerpreset('A01'),_fmt.tunerpreset('G09'),_fmt.tunerpreset('I11')))
  print(string.format('Tuner test AM 530kHz       : %s',_fmt.tunerfreq('A00530')))
  print(string.format('Tuner test AM 1700kHz      : %s',_fmt.tunerfreq('A01700')))
  print(string.format('Tuner test FM 87.50MHz     : %s',_fmt.tunerfreq('F08750')))
  print(string.format('Tuner test FM 108.00MHz    : %s',_fmt.tunerfreq('F10800')))
  print(string.format('FL  [)(]DIGITAL EX  test   : %s',_fmt.convert_fl('000005094449474954414C00455800')))
  print(string.format('Bit 1,0 test               : %s,%s',_fmt.bits('80',7),_fmt.bits('FD',1)))
  print(string.format('VOL123 val extract Test    : %s',_fmt.get_value('VOL123','VOL')))
  print(string.format('Volume test 12,11,0,-80,min: %s,%s,%s,%s,%s',_fmt.volume('185'),_fmt.volume('184'),_fmt.volume('161'),_fmt.volume('001'),_fmt.volume('000')))
  print(string.format('Volume pct test 0,10,30,100: %s,%s,%s,%s',_fmt.volume_pct('0'),_fmt.volume_pct('18'),_fmt.volume_pct('55'),_fmt.volume_pct('185')))
  print(string.format('Zone Volume test 0,-80,min : %s,%s,%s',_fmt.zonevolume('81'),_fmt.zonevolume('01'),_fmt.zonevolume('00')))
  print(string.format('Audio Format Test          : %s',_fmt.convert_ast('0502111110001000000000000111111011000000000')))
  print(string.format('Audio Format Test          : %s',_fmt.convert_vst('10123221122210310100009110000050606100100')))
  print()
  print(string.format('PLIIx listening mode Test  : %s',_fmt.listeningmode('0103')))
  print(string.format('Mute On,Off Test           : %s,%s',_fmt.mute('0'),_fmt.mute('1')))
  print(string.format('Power On,Off Test          : %s,%s',_fmt.power('0'),_fmt.power('1')))
  print(string.format('Source SAT/CBL Test        : %s',_fmt.source('06')))
  print(string.format('Simple DB -6,0,+6 Test     : %s,%s,%s',_fmt.simpledb('12'),_fmt.simpledb('6'),_fmt.simpledb('0')))
  print(string.format('Tone Bypass,On,Tone Test   : %s,%s,%s',_fmt.tone('0'),_fmt.tone('1'),_fmt.tone('9')))
end
--_fmt.test()

return _fmt
