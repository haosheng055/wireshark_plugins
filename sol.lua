- 使用Lua5.2的bit库
require "bit32"
do
    -- 创建一个新的dissector
    local handle_port = 7001
    local sol = Proto("sol", "sol protocol")

    -- 定义数据协议的各个字段
    local f = sol.fields
    f.s_version_type= ProtoField.uint8("sol.version_type","version_type",base.HEX,
        { [0x11] = "_data_",[0x21] = "_connect_",[0x31] = "_heart_bit_",[0x41] = "_end_",
        [0x51] = "_cmd_",[0x61] = "_connect_result_",[0x71] = "_heart_bit_result_" ,
        [0x81] = "_proxy_",[0x91] = "_probe_"})
    f.s_client_id = ProtoField.uint32("sol.s_client_id","s_client_id",base.DEC)
    f.s_ip =  ProtoField.uint32("sol.s_ip","s_ip",base.DEC)
    f.s_port = ProtoField.uint16("sol.s_port","s_port",base.DEC)
    f.s_connect_status = ProtoField.uint8("sol.s_connect_status","s_connect_status",base.HEX,
        { [1] = "connect_ok" , [0] = "connect_error" })
    f.s_seq_num_ext = ProtoField.uint8("sol.s_seq_num_ext","s_seq_num_ext",base.HEX,
        { [0x00] = "no optional seq num" ,[0x01] = "have optional seq num" })
    f.s_pub_sub_data = ProtoField.uint8("sol.s_pbtype","s_pub_sub",base.HEX
        )

    ---- fec协议
    f.fec_version = ProtoField.uint8("sol.fec.fec_version","fec_version",base.HEX,
        { [0x01] = "version_1" })
    f.fec_msg_type = ProtoField.uint8("sol.fec.fec_msg_type","fec_msg_type",base.HEX,
        { [0x01] = "NO_SPLIT_PACKAGE" ,[0x02] = "SPLIT_PACKAGE",
          [0x03] = "LOSS_RATE_INFO" ,[0x04] = "LOSS_PACKGE_INFO",
          [0x05] = "LOSS_RATE_INFO_RETURN",
          [0x06] = "SYNCHRONOUS_INFO" })
    f.fec_msg_property = ProtoField.uint8("sol.fec.fec_msg_property","fec_msg_property",base.HEX,
        { [0x00] = "-" })
    f.fec_msg_index = ProtoField.uint32("sol.fec.fec_msg_index","fec_msg_index",base.DEC)
    f.fec_msg_realy_len = ProtoField.uint32("sol.fec.fec_msg_realy_len","fec_msg_realy_len",base.DEC)
    f.fec_msg_data_block_nums = ProtoField.uint8("sol.fec.fec_msg_data_block_nums","fec_msg_data_block_nums",base.DEC)
    f.fec_msg_check_block_nums = ProtoField.uint8("sol.fec.fec_msg_check_block_nums","fec_msg_check_block_nums",base.DEC)
    f.fec_msg_block_size = ProtoField.uint32("sol.fec.fec_msg_block_size","fec_msg_block_size",base.DEC)
    f.fec_msg_block_index = ProtoField.uint16("sol.fec.fec_msg_block_index","fec_msg_block_index",base.DEC)
    f.fec_msg_sendpkg = ProtoField.int32("sol.fec.fec_msg_sendpkg","fec_msg_sendpkg",base.DEC)
    f.fec_msg_recvpkg = ProtoField.int32("sol.fec.fec_msg_recvpkg","fec_msg_recvpkg",base.DEC)
    f.fec_msg_rtt = ProtoField.int32("sol.fec.fec_msg_rtt","fec_msg_rtt",base.DEC)
    f.fec_miss_msg_index = ProtoField.uint32("sol.fec.fec_miss_msg_index","fec_miss_msg_index",base.DEC)

    --Paas版本的solServer协议
    f.paas_timestamp = ProtoField.uint32("sol.paas.timestamp","timestamp",base.binary)
    f.paas_version= ProtoField.uint8("sol.paas.version","version",base.HEX) --4bit
    f.paas_av_type = ProtoField.uint8("sol.paas.av_type","av_type",base.HEX, --2bit
        { [0x00] = "custom", [0x01] = "audio" ,[0x02] = "video",
            [0x03] = "reserved" })

    f.paas_a_channel_count = ProtoField.uint8("sol.paas.a_channel_count","audio_channel_count",
        base.binary, { [0x00] = "custom", [0x01] = "mono" ,[0x02] = "stereo",
        [0x03] = "reserved" })
    f.paas_a_code_type = ProtoField.uint8("sol.paas.a_code_type","audio_code_type",
        base.binary, { [0x00] = "custom", [0x01] = "opus" ,[0x02] = "speex",
        [0x03] = "aac", [0x4] = "G.711", [0x5] = "AC-3", [0x6] = "MP3" })
    f.paas_a_sample_rate = ProtoField.uint8("sol.paas.a_sample_rate","audio_sample_rate",
        base.binary,  { [0x00] = "custom", [0x01] = "8khz" ,[0x02] = "16khz",
        [0x03] = "24khz", [0x04] = "32khz", [0x05] ="44.1khz", [0x06] ="48khz" })
    f.paas_a_bit_depth = ProtoField.uint8("sol.paas.a_bit_depth","audio_bit_depth",
        base.binary,  { [0x00] = "custom", [0x01] = "8bit" ,[0x02] = "16bit",
        [0x03] = "32bit" })
    f.paas_reserved = ProtoField.uint8("sol.paas.reserved","reserved",base.binary)
    f.paas_v_channel_count = ProtoField.uint8("sol.paas.v_channel_count","video_channel_count",
        base.binary, { [0x00] = "custom", [0x01] = "keyframe" ,[0x02] = "normalframe",
        [0x03] = "reserved" })
    f.paas_v_code_type = ProtoField.uint8("sol.paas.v_code_type","video_code_type",
        base.binary, { [0x00] = "custom", [0x01] = "h264" ,[0x02] = "h265",
        [0x03] = "vp8", [0x04] = "vp9", [0x05] = "av1" })
    f.paas_v_is_svc = ProtoField.uint8("sol.paas.v_is_svc","video_is_svc",base.binary,
        { [0] = "other", [1] = "svc"})
    f.paas_v_svc_type = ProtoField.uint8("sol.paas.v_svc_type","video_svc_type",base.binary)
    --nbit
    f.paas_data = ProtoField.bytes("sol.pass.data","data")
    f.optional_seq_num = ProtoField.uint32("sol.optional_seq_num","optional_seq_num",base.HEX)

    local function PaaS_dissector(buf,pkt,tree,begin)
        --n byte数据
        tree:add(f.paas_timestamp,buf(begin,4))
        local v_version_avtype_count = buf(begin+4,1):uint()     
        local v_version = bit32.rshift(v_version_avtype_count,4)    --取0-4bit
        local v_avtype = bit32.rshift(bit32.band(v_version_avtype_count,0x0c),2)
        local v_channel_count= bit32.band(v_version_avtype_count,0x03)
        tree:add(f.paas_version,v_version)
        tree:add(f.paas_av_type,v_avtype)
        if(v_avtype == 1) then
            -- audio
            tree:add(f.paas_a_channel_count,v_channel_count)
            local v_audio_codetype_rate = buf(begin+5,1):uint()
            local v_audio_codetype = bit32.rshift(v_audio_codetype_rate,4)
            local v_audio_sampleRate = bit32.band(v_audio_codetype_rate,0x0f)
            tree:add(f.paas_a_code_type,v_audio_codetype)
            tree:add(f.paas_a_sample_rate,v_audio_sampleRate)

            local v_thrd_byte = buf(begin+6,1):uint()
            local v_audio_bit_depth = bit32.rshift(v_thrd_byte,6)
            local v_audio_reserved = bit32.band(v_thrd_byte,0x3f)
            tree:add(f.paas_a_bit_depth,v_audio_bit_depth)
            tree:add(f.paas_reserved,v_audio_reserved)
        elseif(v_avtype == 2) then
            --video
            tree:add(f.paas_v_channel_count,v_channel_count)
            local v_video_23byte = buf(begin+5,2):uint() -- 2byte长度，16位
            local v_video_codetype = bit32.rshift(v_video_23byte,12)
            local v_video_is_svc = bit32.band(v_video_23byte,0x0800)
            tree:add(f.paas_v_code_type,v_video_codetype)
            tree:add(f.paas_v_is_svc,v_video_is_svc)
            if (v_video_is_svc == 1) then
                tree:add(f.paas_v_svc_type,bit32.band(v_video_23byte,0x0600))
                local v_video_reserved_9bit = bit32.band(v_video_23byte,0x01ff)
                tree:add(f.paas_reserved,v_video_reserved_9bit)
            else
                local v_video_reserved_11bit = bit32.band(v_video_23byte,0x07ff)
                tree:add(f.paas_reserved,v_video_reserved_11bit)
            end
        end

    end

    local function ScoreBoard_dissector(buf,pkt,root)
        local buf_len = buf:len();
        -- 先检查报文长度，太短的不是我的协议
        if buf_len < 2 then 
            return false 
        end

        -- 取得前1字节identifier字段的值
        local v_version_type = buf(0,1):uint()
        -- 验证identifier是否正确
        if ((v_version_type~=0x11) and (v_version_type~=0x21) and (v_version_type~=0x31)
        	and (v_version_type~=0x41) and (v_version_type~=0x51) and (v_version_type~=0x61) 
            and (v_version_type~=0x71) and (v_version_type~=0x81) and (v_version_type~=0x91))
            --不正确就不是我的协议
            then return false end

        local tree = root:add(sol,buf)  -- 为sol协议的协议解析树添加一个子节点tree，值为buf
        pkt.cols.protocol = "sol"
        tree:add(f.s_version_type,buf(0,1))

        -- 根据不同的version_type分别解析
        if (v_version_type == 0x11) then
            -- cmd_type = _data_
            if(pkt.dst_port == handle_port) then
                -- 从客户端到服务器
                tree:add(f.s_client_id,buf(1,4))
                local v_pub_sub_data = buf(5,1):uint()
                local v_seq_num_ext = bit32.rshift(bit32.band(v_pub_sub_data,0x04),2)
                local v_pub_sub = bit32.band(v_pub_sub_data,0x03)
                tree:add(f.s_seq_num_ext,v_seq_num_ext)
                tree:add(f.s_pub_sub_data,v_pub_sub)
                tree:add(f.fec_version,buf(6,1))
                tree:add(f.fec_msg_type,buf(7,1))
                tree:add(f.fec_msg_property,buf(8,1))
                tree:add(f.fec_msg_index,buf(9,4))
                if(buf(7,1):uint() == 0x02) then
                    --使用fec拆分的包
                    tree:add(f.fec_msg_realy_len,buf(13,4))
                    tree:add(f.fec_msg_data_block_nums,buf(17,1))
                    tree:add(f.fec_msg_check_block_nums,buf(18,1))
                    tree:add(f.fec_msg_block_size,buf(19,4))
                    tree:add(f.fec_msg_block_index,buf(23,2))

                    local v_msg_block_index=buf(23,2):uint();
                    if(v_msg_block_index == 0) then
                        PaaS_dissector(buf,pkt,tree,25)
                        if (v_seq_num_ext == 0) then
                            tree:add(f.paas_data,buf(32))
                        else
                            tree:add(f.paas_data,buf(32,buf:len()-36))
                            tree:add(f.optional_seq_num,buf(buf:len()-4))
                        end
                    else
                        if (v_seq_num_ext == 0) then
                            tree:add(f.paas_data,buf(25))
                        else
                            tree:add(f.paas_data,buf(25,buf:len()-29))
                            tree:add(f.optional_seq_num,buf(buf:len()-4))
                        end
                    end
                elseif (buf(7,1):uint() == 0x03) then 
                    --丢包率回传包
                    tree:add(f.fec_msg_sendpkg,buf(13,4))
                    tree:add(f.fec_msg_recvpkg,buf(17,4))
                    tree:add(f.fec_msg_rtt,buf(29,4))
                elseif (buf(7,1):uint() == 0x04) then
                    -- 丢包信息传递
                    tree:add(f.fec_miss_msg_index,buf(13,4))
                else
                    -- 没有fec拆分的包
                    PaaS_dissector(buf,pkt,tree,13)
                    if (v_seq_num_ext == 0) then
                        tree:add(f.paas_data,buf(32))
                    else
                        tree:add(f.paas_data,buf(32,buf:len()-36))
                        tree:add(f.optional_seq_num,buf(buf:len()-4))
                    end
                end
            else
                -- 从服务器到客户端
                tree:add(f.fec_version,buf(1,1))
                tree:add(f.fec_msg_type,buf(2,1))
                tree:add(f.fec_msg_property,buf(3,1))
                tree:add(f.fec_msg_index,buf(4,4))
                if(buf(2,1):uint() == 0x02) then
                    tree:add(f.fec_msg_realy_len,buf(8,4))
                    tree:add(f.fec_msg_data_block_nums,buf(12,1))
                    tree:add(f.fec_msg_check_block_nums,buf(13,1))
                    tree:add(f.fec_msg_block_size,buf(14,4))
                    tree:add(f.fec_msg_block_index,buf(18,2))
                elseif (buf(2,1):uint() == 0x03) then 
                    tree:add(f.fec_msg_sendpkg,buf(8,4))
                    tree:add(f.fec_msg_recvpkg,buf(12,4))
                    tree:add(f.fec_msg_rtt,buf(24,4))
                elseif (buf(2,1):uint() == 0x04) then
                end
            end
            
        elseif (v_version_type == 0x81) then    
            -- cmd_type = _proxy_
            tree:add(f.s_ip,buf(1,4))
            tree:add(f.s_port,buf(4,2))
        elseif (v_version_type == 0x61) then
            -- cmd_type = _connect_result_
        	tree:add(f.s_connect_status,buf(1,1))
        	tree:add(f.s_client_id,buf(2,4))
        elseif (v_version_type == 0x31) then
            -- cmd_type = _connect_result_
        	tree:add(f.s_connect_status,buf(1,1))
        	tree:add(f.s_client_id,buf(2,4))
            tree:add(f.optional_seq_num,buf(buf:len()-4))
        end
        return true
    end
    -- dissector 函数
    function sol.dissector(buf,pkt,root) 
        if ScoreBoard_dissector(buf,pkt,root) then
            -- valid ScoreBoard diagram
        else
            -- data这个dissector几乎是必不可少的；当发现不是我的协议时，就应该调用data
            local data_dis = Dissector.get("data");
            data_dis:call(buf,pkt,root)
        end
    end
    -- 注册这个dissector
    DissectorTable.get("udp.port"):add(handle_port, sol)
end
