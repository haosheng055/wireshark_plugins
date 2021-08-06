-- 使用Lua5.2的bit库
require "bit32"
do
    -- 创建一个新的dissector
    local handle_port = 7100
    local sol2 = Proto("sol2", "sol2 protocol")

    ---- 消息头
    -- 一般消息头（音视频+自定义消息）
    local f = sol2.fields
    f.stream_id= ProtoField.uint32("sol2.stream_id","stream_id",base.HEX) --32bits
    f.reliable = ProtoField.uint8("sol2.reliable","reliable",base.DEC)  --1bit
    f.payload_format =  ProtoField.uint8("sol2.payload_format","payload_format",base.HEX,
        { [0x00]="STAP",[0x01]="MTAP",[0x02]="Single Packet",[0x03]="Fragmented Packet"}) --2bits
    f.payload_type = ProtoField.uint8("sol2.payload_type","payload_type",base.HEX,
        { [0x01]="H264",[0x02]="H265",[0x03]="VP8",[0x04]="VP9",[0x05]="AV1",
          [0x06]="H266",[0x11]="AAC",[0x12]="Opus",[0x1D]="Custom Message",
          [0x1E]="Control Message",[0x1F]="Handshake Message"})  --4bits
    f.reserve = ProtoField.uint8("sol2.reserve","reserve",base.HEX) --8bits
    f.seq_number = ProtoField.uint16("sol2.seq_number","seq_number",base.HEX) --16bits
    f.packet_id = ProtoField.uint16("sol2.packet_id","packet_id",base.HEX) --16bits
    f.check_sum = ProtoField.uint16("sol2.check_sum","check_sum",base.HEX) --16bits
    f.timestamp = ProtoField.uint32("sol2.timestamp","timestamp",base.HEX) --32bits
    -- 控制消息头
    -- 握手消息头
    f.sol2 = ProtoField.uint32("sol2.sol2","sol2",base.HEX) --32bits
    f.version = ProtoField.uint8("sol2.version","version",base.HEX) --3bits
    f.hello_id = ProtoField.uint16("sol2.hello_id","hello_id",base.HEX) --16bits
    f.protobuf = ProtoField.bytes("sol2.protobuf","protobuf") --?bits

    ---- payload格式
    f.length = ProtoField.uint16("sol2.length","length",base.HEX) --16bits
    f.time_offset = ProtoField.uint16("sol2.time_offset","time_offset",base.HEX) --16bits
    -- 分片包：没用fec、使用fec
    f.fec_group_count = ProtoField.uint8("sol2.fec_group_count","fec_group_count",base.HEX) --4bits
    f.fp_reserve = ProtoField.uint8("sol2.fp_reserve","fp_reserve",base.HEX) --2bits
    f.s = ProtoField.uint8("sol2.start","s",base.HEX) --1bits
    f.e = ProtoField.uint8("sol2.end","e",base.HEX) --1bits
    f.fec_group_index = ProtoField.uint8("sol2.fec_group_index","fec_group_index",base.HEX) --4bits
    f.fec_total = ProtoField.uint8("sol2.fec_total","fec_total",base.HEX) --8bits
    f.fec_data_total = ProtoField.uint8("sol2.fec_data_total","fec_data_total",base.HEX) --8bits
    f.fec_block_index = ProtoField.uint8("sol2.fec_block_index","fec_block_index",base.HEX) --8bits

    ---- 单包palyload类型
    -- 视频、音频
    f.data_version = ProtoField.uint8("sol2.data_version","data_version",base.HEX) --3bits
    f.data_reserve = ProtoField.uint8("sol2.data_reserve","data_reserve",base.HEX) --3bits
    f.frame_type = ProtoField.uint8("sol2.frame_type","frame_type",base.HEX,
        { [0x00]="保留帧",[0x01]="关键帧",[0x02]="p帧",[0x03]="保留帧"}) --2bits
    f.data_reserve2 = ProtoField.uint8("sol2.data_reserve","data_reserve",base.HEX) --8bits
    f.data_reserve_32bits = ProtoField.uint8("sol2.data_reserve","data_reserve",base.HEX) --32bits
    f.frame_number = ProtoField.uint16("sol2.frame_number","frame_number",base.HEX) --16bits
    f.data = ProtoField.bytes("sol2.data","data") --?bits
    f.channel_count = ProtoField.uint8("sol2.channel_count","channel_count",base.HEX,
        { [0x00]="单声道",[0x01]="双声道",[0x02]="三声道",[0x03]="四声道"}) --2bits
    f.sample_format = ProtoField.uint8("sol2.sample_format","sample_format",base.HEX,
        {[0x00]="uint8",[0x01]="int8",[0x02]="int16",[0x03]="int24",[0x04]="int32",
          [0x05]="float32"}) --4bits
    f.sample_rate = ProtoField.uint8("sol2.sample_rate","sample_rate",base.DEC,
        { [0x00]="8khz",[0x01]="16khz",[0x02]="32khz",[0x03]="44.1khz",[0x04]="48khz",
          [0x05]="88.2khz",[0x06]="96khz"}) --4bits
    -- 自定义消息 复用data_version data_reserve
    -- 控制消息 复用data_version
    f.message_type = ProtoField.uint8("sol2.message_type","message_type",base.HEX,
        { [0x01]="heart bit",[0x02]="sender report",[0x03]="receiver report",
        [0x04]="Receiver Report Acknowledgement",[0x05]="Acknowledgement",
        [0x06]="Negative Acknowledgement",[0x07]="reset",[0x08]="set config"}) --5bits
        -- sr
    f.reserve_sender_report = ProtoField.uint24("sol2.reserve","reserve",base.HEX) --24bits
    f.stream_timestamp = ProtoField.uint32("sol2.stream_timestamp","stream_timestamp",base.DEC) --32bits
    f.reference_timestamp = ProtoField.uint32("sol2.reference_timestamp","reference_timestamp",base.DEC) --32bits
        -- rr
    f.reserve_receiver_report = ProtoField.uint8("sol2.reserve","reserve",base.HEX) --8bits
    f.sender_report_seq_number = ProtoField.uint16("sol2.sender_report_seq_number","sender_report_seq_number",base.HEX) --16bits
    f.fraction_lost = ProtoField.uint8("sol2.fraction_lost","fraction_lost",base.HEX) --8bits
    f.delta_time = ProtoField.uint24("sol2.delta_time","delta_time",base.HEX) --24bits
    f.receiver_estimate_bitrate = ProtoField.uint32("sol2.receiver_estimate_bitrate","receiver_estimate_bitrate",base.HEX) --32bits
    f.interarrival_jitter = ProtoField.uint32("sol2.interarrival_jitter","interarrival_jitter",base.HEX) --32bits
        -- Receiver Report Acknowledgement
    f.receiver_report_seq_number = ProtoField.uint16("sol2.receiver_report_seq_number","receiver_report_seq_number",base.HEX) --16bits
        -- Negative Acknowledgement
    f.nack_seq_number = ProtoField.uint16("sol2.nack_seq_number","nack_seq_number",base.HEX) --16bits
    f.bitmap = ProtoField.uint32("sol2.bitmap","bitmap",base.HEX) --32bits
        -- reset
    f.reason_code = ProtoField.uint8("sol2.reason_code","reason_code",base.HEX,
        { [0x00]="正常终止",[0x01]="需重建链接",[0x02]="状态异常",[0x03]="无效数据",
          [0x04]="过长时间未活跃",[0x05]="拒绝服务"}) --8bits
        -- set config

    local function video_payload_dissector(buf,pkt,tree,begin,v_length)
        local v_version_reser_FT = buf(begin,1):uint()
        tree:add(f.data_version,bit32.rshift(v_version_reser_FT,5))
        tree:add(f.data_reserve,bit32.rshift(bit32.band(v_version_reser_FT,0x1C),2) )
        tree:add(f.frame_type,bit32.band(v_version_reser_FT,0x03))
        tree:add(f.data_reserve2,buf(begin+1,1))
        tree:add(f.frame_number,buf(begin+2,2))
        if(v_length >= 0) then
            tree:add(f.data,buf(begin+4,v_length-4))
            if(begin+v_length >= buf:len()) then
                return false
            else
                return true
            end
        else
            tree:add(f.data,buf(begin+4))
            return true
        end
    end

    local function audio_payload_dissector(buf,pkt,tree,begin,v_length)
        local v_version_reser_CC = buf(begin,1):uint()
        tree:add(f.data_version,bit32.rshift(v_version_reser_CC,5))
        tree:add(f.data_reserve,bit32.rshift(bit32.band(v_version_reser_CC,0x1C),2) )
        tree:add(f.channel_count,bit32.band(v_version_reser_CC,0x03))
        local v_format_rate = buf(begin+1,1):uint()
        tree:add(f.sample_format,bit32.rshift(v_format_rate,4))
        tree:add(f.sample_rate,bit32.band(v_format_rate,0x0F))
        tree:add(f.frame_number,buf(begin+2,2))
        if(v_length >= 0) then
            tree:add(f.data,buf(begin+4,v_length-4))
            if(begin+v_length >= buf:len()) then
                return false
            else
                return true
            end
        else
            tree:add(f.data,buf(begin+4))
            return true
        end
    end

    local function custom_payload_dissector(buf,pkt,tree,begin,v_length)
        local v_version_reserve = buf(begin,1):uint()
        tree:add(f.data_version,bit32.rshift(v_version_reserve,5))
        tree:add(f.data_reserve,bit32.band(v_version_reserve,0x1F))
        tree:add(f.data,buf(begin+1))
        if(v_length >= 0) then
            tree:add(f.data,buf(begin+1,v_length-1))
            if(begin+v_length >= buf:len()) then
                return false
            else
                return true
            end
        else
            tree:add(f.data,buf(begin+1))
            return true
        end
    end

    local function control_payload_dissector(buf,pkt,tree,begin)
        local v_version_massagetype = buf(begin,1):uint()
        local v_message_type = bit32.band(v_version_massagetype,0x1F)
        tree:add(f.data_version,bit32.rshift(v_version_massagetype,5))
        tree:add(f.message_type,v_message_type)
        if ( v_message_type == 0x01 ) then
            
        elseif ( v_message_type == 0x02) then
            tree:add(f.data_reserve_32bits,buf(begin+1,3))
            tree:add(f.stream_timestamp,buf(begin+4,4))
            tree:add(f.reference_timestamp,buf(begin+8,4))
        elseif ( v_message_type == 0x03) then
            tree:add(f.data_reserve,buf(begin+1,1))
            tree:add(f.stream_timestamp,buf(begin+4,4))
            tree:add(f.reference_timestamp,buf(begin+8,4))
        elseif ( v_message_type == 0x07 ) then
            tree:add(f.data_reserve,buf(begin+1,1))
            tree:add(f.receiver_report_seq_number,buf(begin+2,2))
        elseif ( v_message_type == 0x05 ) then
            tree:add(f.data_reserve,buf(begin+1,1))
            tree:add(f.nack_seq_number,buf(begin+2,2))
            tree:add(f.bitmap,buf(begin+4,4))
        elseif ( v_message_type == 0x06 ) then
            tree:add(f.reason_code,buf(begin+1,1))
        elseif ( v_message_type == 0x08 ) then
            tree:add(f.protobuf,buf(begin+1))
        else
            return false
        end
    end
    
    local function payload_type_dispatcher( buf,pkt,tree,begin,v_payload_type,v_length)
        if( (v_payload_type == 0x01) or (v_payload_type == 0x02) or (v_payload_type == 0x03) or
            (v_payload_type == 0x04) or (v_payload_type == 0x05) or (v_payload_type == 0x06) ) then
            return video_payload_dissector(buf,pkt,tree,begin,v_length)
        elseif( (v_payload_type == 0x11) or (v_payload_type == 0x12)) then
            return audio_payload_dissector(buf,pkt,tree,begin,v_length)
        elseif( v_payload_type == 0x1D) then
            return custom_payload_dissector(buf,pkt,tree,begin,v_length) 
        else
            return false
        end
    end
    local function check_header_type(v_payload_type)
        if ( (v_payload_type==0x01) or (v_payload_type==0x02) or (v_payload_type==0x03)
        	or (v_payload_type==0x04) or (v_payload_type==0x05) or (v_payload_type==0x06) 
            or (v_payload_type==0x11) or (v_payload_type==0x12) or (v_payload_type==0x1D) ) then
            return 0 -- 一般消息头（音视频+自定义消息）
        elseif (v_payload_type==0x1E) then
            return 1 -- 控制消息
        elseif (v_payload_type==0x1F) then
            return 2 -- 握手消息
        else
            return -1 --不合法
        end
    end

    local function common_message_dissector(buf,pkt,tree)
        tree:add(f.stream_id,buf(0,4))
        local v_payload_type = bit32.band(buf(4,1):uint(),0x1F)
        local v_reliable = bit32.rshift(buf(4,1):uint(),7)
        local v_payload_format = bit32.rshift(bit32.band(buf(4,1):uint(),0x60),5) 
        tree:add(f.reliable,v_reliable)
        tree:add(f.payload_format,v_payload_format)
        tree:add(f.reserve,buf(5,1))
        tree:add(f.seq_number,buf(6,2))
        tree:add(f.packet_id,buf(8,2))
        tree:add(f.check_sum,buf(10,2))
        tree:add(f.timestamp,buf(12,4))
        -- todo:payload
        if ( v_payload_format == 0x00 ) then
            local ret = true
            local begin = 16
            while(ret) do
                v_length = buf(begin,2):uint()
                tree:add(f.length,buf(16,2))
                ret = payload_type_dispatcher(buf,pkt,tree,begin+2,v_payload_type,v_length)
                begin = begin + v_length + 2
            end
        elseif ( v_payload_format == 0x01 ) then
            local ret = true
            local begin = 16
            while(ret) do
                tree:add(f.time_offset,buf(begin,2))
                tree:add(f.length,buf(begin+2,2))
                v_length = buf(begin+2,2):uint()
                ret = payload_type_dispatcher(buf,pkt,tree,begin+4,v_payload_type,v_length)
                begin = begin + v_length + 4
            end
        elseif ( v_payload_format == 0x02 ) then
            return payload_type_dispatcher(buf,pkt,tree,16,v_payload_type,-1)
        elseif ( v_payload_format == 0x03 ) then
            local v_fec_group_count_S_E_R = buf(16,1):uint();
            tree:add(f.fec_group_count,bit32.rshift(v_fec_group_count_S_E_R,4))
            if( bit32.rshift(v_fec_group_count_S_E_R,4) == 0x00) then
                tree:add(f.s,bit32.rshift(v_fec_group_count_S_E_R,3))
                tree:add(f.e,bit32.band(bit32.rshift(v_fec_group_count_S_E_R,2),0x01))
                tree:add(f.fp_reserve,bit32.band(v_fec_group_count_S_E_R,0x03))
                return payload_type_dispatcher(buf,pkt,tree,17,v_payload_type,-1)
            else
                tree:add(f.fec_group_index,bit32.band(v_fec_group_count_S_E_R,0x0F))
                tree:add(f.fec_total,buf(17,1))
                tree:add(f.fec_data_total,buf(18,1))
                tree:add(f.fec_block_index,buf(19,1))
                return payload_type_dispatcher(buf,pkt,tree,20,v_payload_type,-1)
            end
        else
            return false
        end
        return true;
    end

    local function control_message_dissector(buf,pkt,tree)
        tree:add(f.stream_id,buf(0,4))
        local v_reliable = bit32.rshift(buf(4,1):uint(),7)
        local v_payload_format = bit32.rshift(bit32.band(buf(4,1):uint(),0x60),5) 
        tree:add(f.reliable,v_reliable)
        tree:add(f.payload_format,v_payload_format)
        tree:add(f.reserve,buf(5,1))
        tree:add(f.seq_number,buf(6,2))
        tree:add(f.check_sum,buf(8,2))
        -- todo:payload
        return control_payload_dissector(buf,pkt,tree,10)
    end

    local function shakehand_message_dissector(buf,pkt,tree)
        tree:add(f.sol2,buf(0,4))
        local v_version = bit32.rshift(buf(4,1):uint(),5)
        tree:add(f.version,v_version)
        tree:add(f.reserve,buf(5,1))
        tree:add(f.hello_id,buf(6,2))
        tree:add(f.check_sum,buf(8,2))
        tree:add(f.protobuf,buf(10))
    end


    local function header_dissector(buf,pkt,root)
        local buf_len = buf:len();
        -- 先检查报文长度，过短不是sol2协议
        if buf_len < 10 then 
            return false 
        end

        -- 取得前1字节payload_type字段的值
        local v_payload_type = bit32.band(buf(4,1):uint(),0x1F)
        -- 验证payload_type是否正确
        local v_valid = check_header_type(v_payload_type)
        if (v_valid == -1) then
            return false
        end
        local tree = root:add(sol2,buf)  -- 为sol协议的协议解析树添加一个子节点tree，值为buf
        pkt.cols.protocol = "sol2"
        tree:add(f.payload_type, v_payload_type)

        -- 根据不同的payload_type分别解析
        if (v_valid == 0) then
            return common_message_dissector(buf,pkt,tree)
        elseif (v_valid == 1) then    
            return control_message_dissector(buf,pkt,tree)
        else
            return shakehand_message_dissector(buf,pkt,tree)
        end
        return true
    end

    -- dissector 函数
    function sol2.dissector(buf,pkt,root) 
        if header_dissector(buf,pkt,root) then
            -- 解析sol2协议
        else
            -- 不是sol2协议时，调用data
            local data_dis = Dissector.get("data");
            data_dis:call(buf,pkt,root)
        end
    end

    -- 注册这个dissector
    DissectorTable.get("udp.port"):add(handle_port, sol2)
end
