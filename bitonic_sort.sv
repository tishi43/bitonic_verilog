//--------------------------------------------------------------------------------------------------
// Copyright (C) 2021 tianqishi
// All rights reserved
// Design    : bitonic_sort
// Author(s) : tianqishi
// Email     : tishi1@126.com
// QQ        : 2483210587
//-------------------------------------------------------------------------------------------------

`include "bitonic_defines.v"

module bitonic_sort
(
    input wire                              clk,
    input wire                              rst,
    output reg   [`PT_RAM_ADDR_BITS-1: 0]   pt_ram_addra,
    output reg   [`PT_RAM_ADDR_BITS-1: 0]   pt_ram_addrb,
    output reg   [`PT_RAM_DATA_WIDTH-1:0]   pt_ram_dia,
    input wire   [`PT_RAM_DATA_WIDTH-1:0]   pt_ram_dob,
    output reg                              pt_ram_we,
    output reg                      [3:0]   stage

);

reg        [`PT_RAM_DATA_WIDTH-1:0]         databuf[7:0]          ;
wire     [`PT_RAM_DATA_WIDTH/2-1:0]         data[15:0]            ;
reg                           [3:0]         step                  ; //step���15��֧��������2^15=4096*3
reg                           [7:0]         ascend                ;
reg                                         ascend_step_gt3       ; //step>=4ʱ��
reg                      [3:0][7:0]         swap                  ;
reg      [`PT_RAM_DATA_WIDTH/2-1:0]         round1_result[15:0]   ;
reg      [`PT_RAM_DATA_WIDTH/2-1:0]         round2_result[15:0]   ;
reg      [`PT_RAM_DATA_WIDTH/2-1:0]         round3_result[15:0]   ;
reg      [`PT_RAM_DATA_WIDTH/2-1:0]         round4_result[15:0]   ;
reg      [`PT_RAM_DATA_WIDTH/2-1:0]         result[15:0]          ;

reg         [`PT_RAM_ADDR_BITS  :0]         interval              ; //ÿ�ο�2�㣬������ٿ������ݣ�ÿ�����������濽2��
reg                           [3:0]         current_rounds        ;
reg                           [3:0]         rounds_remain         ;
reg                           [1:0]         skips                 ;
reg        [`PT_RAM_ADDR_BITS+1: 0]         max_group_size        ; //round������鳤��
reg        [`PT_RAM_ADDR_BITS+1: 0]         step_max_group_size   ; //step������鳤��
reg        [`PT_RAM_ADDR_BITS-2: 0]         step_min_groups       ; //step����С������������ÿ��step round 1����������������С16����������
reg        [`PT_RAM_ADDR_BITS  : 0]         prev_interval         ;


reg        [`PT_RAM_ADDR_BITS+1: 0]         current_group_size    ; //��ǰsize���ۻ���step_max_group_size����0
reg        [`PT_RAM_ADDR_BITS-3: 0]         group                 ; //��ǰ��ţ�������Ǹ���round���ģ�������Comment1,step 3,round 1,������,����С16������
reg        [`PT_RAM_ADDR_BITS-2: 0]         groups                ; //������
reg        [`PT_RAM_ADDR_BITS-3: 0]         sub_group             ; //һ��group��16������Ϊ1��ֳַɼ���,һ��group�ڵ�sub group�ǰ�һ�������16������
reg        [`PT_RAM_ADDR_BITS-2: 0]         sub_groups            ;

reg        [`PT_RAM_ADDR_BITS-1: 0]         group_ram_start_addr  ; //��ĵ�һ�����ݣ���ram�еĵ�ַ
reg                                         store_valid           ; //���1������󣬴���Ч
reg                           [3:0]         fetch_i               ;

localparam Steps=$clog2(`MAX_PTS);

localparam
FetchingFromRam = 2,
Delay1Cycle = 3,
StepDone    =4,
RoundDone   =5,
WaitStoreLast16Data=6,
WaitingSort = 1,
WaitingSort2 = 7,
Done = 0;

integer ii;

//Comment1: N=16
//        5, 7,  15, 4,   0, 3,   11, 9,  12, 8,  1, 14, 13, 2, 6, 10

//         ��      ��       ��       ��    ��      ��       ��    ��
//step 1: [5 7]  [15 4]   [0 3]   [11 9]  [8 12]  [14 1] [2 13] [10 6]

//step 2,   4��������4�����棬����

//           ��          ��           ��              ��
//round 1 [5 4 15 7]  [11 9 0 3]   [8 1 14 12]    [10 13 2 6]
//         ��   ��      ��    ��    ��     ��       ��    ��
//round 2 [4 5][7 15] [11 9][3 0]  [1 8] [12 14]  [13 10] [6 2]


//step 3,8��������8������

//                  ��                       ��
//round 1  [4 5 3 0    11 9 7  15]    [13 10 12 14    1 8 6 2]
//            ��          ��                ��          ��
//round 2  [3 0 4 5]   [7 9 11 15]    [13 14 12 10]   [6 8 1 2]
//          ��   ��      ��   ��        ��     ��       ��  ��
//round 3  [0 3][4 5]  [7 9][11 15]  [14 13][12 10]  [8 6][2 1]


//step 4, 16��������16�����棬Ҳ����ȫ����
//round 1:  [ 0  3  4  5   7  6  2 1    14  13  12  10  8  9  11 15 ]
//round 2    [ 0  3 2 1    7  6 4 5 ]  [8 9 11 10    14 13 12 15]
//round 3    [0  1 2 3]    [4  5 7  6]  [8 9  11 10]  [12 13 14 15]
//round 4    [0 1] [2 3]   [4 5] [6 7]  [8 9] [10 11]  [12 13] [14 15]




//Comment2: N=256,
//���һ��step��step 8
//0,1  32,33   64,65   96,97   128,129   160,161   192,193    224,225
//round 1    0,1��128,129   32,33��160,161  64,65��192,193   96,97��224,225
//round 2    0,1��64,65     32,33��96,97    128,129��192,193  160,161��224,225
//round 3    0,1��32,33     64,65��96,97    128,129��160,161  192,193��224,225
//round 4    0,1���ܱȽ�

//   3��round֮���������256���256/8=32��32buf�Ų��£����2����
//round 4
//round 5
//round 6

// ��3��round֮���������4,�����С�ڵ���16֮�󣬶���16��16������˳��
//round 7
//round 8

//step=7
//round 1    0,1   16,17  32,33  48,49  64,65   80,81  96,97   112,113    ��
//           128,129 ...                                                   ��

assign {data[1],data[0]} = databuf[0];
assign {data[3],data[2]} = databuf[1];
assign {data[5],data[4]} = databuf[2];
assign {data[7],data[6]} = databuf[3];
assign {data[9],data[8]} = databuf[4];
assign {data[11],data[10]} = databuf[5];
assign {data[13],data[12]} = databuf[6];
assign {data[15],data[14]} = databuf[7];

always @ (posedge clk) begin
    if (rst) begin
        step                           <= 1;
        pt_ram_addrb                   <= 0;
        pt_ram_addra                   <= 0;
        interval                       <= 2;
        fetch_i                        <= 0;
        ascend_step_gt3                <= 1;
        max_group_size                 <= 16;
        group                          <= 0;
        groups                         <= `MAX_PTS/16;
        sub_group                      <= 0;
        sub_groups                     <= 1;
        step_min_groups                <= `MAX_PTS/16;
        group_ram_start_addr           <= 0;
        step_max_group_size            <= 2;
        store_valid                    <= 0;
        current_group_size             <= 0;
        current_rounds                 <= 1; //step 1,rounds=1
        rounds_remain                  <= 1;
        skips                          <= 3;
        stage                          <= Delay1Cycle;
    end
    else if (stage==Delay1Cycle) begin
        pt_ram_addrb                   <= pt_ram_addrb+(interval>>1);
        fetch_i                        <= 0;
        stage                          <= FetchingFromRam;
    end
    else if (stage==FetchingFromRam||stage==WaitStoreLast16Data)begin
        pt_ram_addrb                   <= pt_ram_addrb+(interval>>1);
        if (step==1) begin
            ascend                     <= 8'b01010101;
        end
        else if (step==2) begin
            ascend                     <= 8'b00110011;
        end
        else if (step==3) begin
            ascend                     <= 8'b00001111;
        end
        else begin
            ascend                     <= {8{ascend_step_gt3}};
        end
        fetch_i                        <= fetch_i+1;
        if (fetch_i==7)
            stage                      <= stage==WaitStoreLast16Data?Done:WaitingSort;

        databuf                        <= {pt_ram_dob,databuf[7:1]};

        result                         <= {`PT_RAM_DATA_WIDTH/2'd0,`PT_RAM_DATA_WIDTH/2'd0,result[15:2]};
        if (fetch_i)
            pt_ram_addra               <= pt_ram_addra+(prev_interval>>1);
        pt_ram_dia                     <= {result[1],result[0]}; //Cannot assign an unpacked type 'reg[49:0] $[1:0]' to a packed type 'reg[99:0]'.
        pt_ram_we                      <= store_valid?1:0;

    end
    else if (stage==WaitingSort||stage==WaitingSort2) begin
        pt_ram_we                      <= 0;
        if (stage==WaitingSort)
            result                     <= round3_result;
        if (stage==WaitingSort2)
            result                     <= round4_result;

        if (rounds_remain<=4&&stage==WaitingSort) begin
            stage                      <= WaitingSort2;
        end
        else begin
            sub_group                  <= sub_group+1;
            store_valid                <= 1;
            pt_ram_addra               <= group_ram_start_addr+sub_group;
            prev_interval              <= interval;
            if (sub_group==sub_groups-1) begin
                group                  <= group+1;

                pt_ram_addrb           <= group_ram_start_addr+max_group_size/2;
                group_ram_start_addr   <= group_ram_start_addr+max_group_size/2;
                group                  <= group+1;
                sub_group              <= 0;
                current_group_size     <= current_group_size+max_group_size;
                if (current_group_size+max_group_size==step_max_group_size) begin
                    current_group_size <= 0;
                    ascend_step_gt3    <= ~ascend_step_gt3;
                end

                if (group==groups-1)
                    stage              <= RoundDone;
                else
                    stage              <= Delay1Cycle;
            end
            else begin
                //group: 0~255
                //sub group 0:0,1  32,33   64,65   96,97   128,129   160,161   192,193    224,225
                //sub group 1:2,3  34,35   66,67   ...
                //16�����ݵ�sub group��ɱȽ�,��һ��sub group
                pt_ram_addrb           <= group_ram_start_addr+sub_group+1;
                stage                  <= Delay1Cycle;
            end
        end
    end
    else if (stage==StepDone) begin
        step_max_group_size            <= step_max_group_size*2;
        max_group_size                 <= step_max_group_size*2<16?16:step_max_group_size*2;
        interval                       <= step_max_group_size*2<16?2:step_max_group_size*2/8;
        if (step>=4)
            step_min_groups            <= step_min_groups/2;
        groups                         <= step>=4?step_min_groups/2:step_min_groups;
        group                          <= 0;
        sub_group                      <= 0;
        sub_groups                     <= step_max_group_size*2<16?1:step_max_group_size*2/16; //sub_groups=max_group_size/16
        pt_ram_addrb                   <= 0;
        group_ram_start_addr           <= 0;
        current_group_size             <= 0;
        ascend_step_gt3                <= 1;
        current_rounds                 <= step+1>4?3:step+1;
        rounds_remain                  <= step+1;
        step                           <= step+1;
        skips                          <= step+1>=4?0:4-(step+1); //rounds=1,skip 3,rounds=2,skip 2,rounds=3,skip 1,rounds>=4,skip 0
        if (step==Steps) begin
            stage                      <= WaitStoreLast16Data;
            fetch_i                    <= 0;
        end
        else
            stage                      <= Delay1Cycle;
    end
    else if (stage==RoundDone) begin
        group                          <= 0;
        max_group_size                 <= max_group_size/8>16?max_group_size/8:16;
        //��ǰmax_group_size=256,��һ��max_group_size=256/8=32,interval=4
        interval                       <= max_group_size/8<=16?2:max_group_size/64;//C:interval = max_group_size<=16?2:max_group_size/8
        groups                         <= groups>`MAX_PTS/128?`MAX_PTS/16:groups*8; //groups*8>`MAX_PTS/16��groups>`MAX_PTS/128
        sub_groups                     <= sub_groups>8?sub_groups/8:1;
        current_rounds                 <= rounds_remain>4 ? 3 : rounds_remain;
        skips                          <= rounds_remain>=7?0:7-rounds_remain; //rounds_remain-3>=4?0:4-(rounds_remain-3)
        rounds_remain                  <= rounds_remain-3;
        pt_ram_addrb                   <= 0;
        group_ram_start_addr           <= 0;
        current_group_size             <= 0;
        ascend_step_gt3                <= 1;
        if (rounds_remain<=4)
            stage                      <= StepDone;
        else
            stage                      <= Delay1Cycle;
    end
    else if (stage==Done)
        pt_ram_we                      <= 0;

end


//skips=3:����ǰ��3����ֱ������2�������Ƚ�
//skips=2:����ǰ��2��,...
//0��8��1��9��2��10��3��11��4��12��5��13��6��14��7��15
//0��4��1��5��2��6��3��7��8��12��9��13��10��14��11��15
//0��2��1��3��4��6��5��7��8��10��9��11��12��14��13��15
//0��1��2��3��4��5��6��7��8��9��10��11��12��13��14��15

//���Լٶ�ÿ�������е�ǰ22bit�����Ƚϴ�С
always @ (*) begin
    for (ii=0;ii<8;ii=ii+1) begin
        swap[0][ii]    = ascend[ii]?data[ii][21:0]>=data[ii+8][21:0]:data[ii][21:0]<=data[ii+8][21:0];
    end
end

always @ (*) begin
    for (ii=0;ii<4;ii=ii+1) begin
        swap[1][ii]    = ascend[ii]?round1_result[ii][21:0]>=round1_result[ii+4][21:0]:
                                    round1_result[ii][21:0]<=round1_result[ii+4][21:0];
        swap[1][ii+4]  = ascend[ii+4]?round1_result[ii+8][21:0]>=round1_result[ii+12][21:0]:
                                      round1_result[ii+8][21:0]<=round1_result[ii+12][21:0];
    end
end

always @ (*) begin
    for (ii=0;ii<4;ii=ii+1) begin
        swap[2][ii*2]   = ascend[ii*2]?round2_result[ii*4][21:0]>=round2_result[ii*4+2][21:0]:
                                       round2_result[ii*4][21:0]<=round2_result[ii*4+2][21:0];
        swap[2][ii*2+1]   = ascend[ii*2]?round2_result[ii*4+1][21:0]>=round2_result[ii*4+3][21:0]:
                                       round2_result[ii*4+1][21:0]<=round2_result[ii*4+3][21:0];
    end
end

always @ (*) begin
    for (ii=0;ii<8;ii=ii+1) begin
        swap[3][ii]   = ascend[ii]?result[ii*2][21:0]>=result[ii*2+1][21:0]:
                                   result[ii*2][21:0]<=result[ii*2+1][21:0];

    end
end


//current_rounds=1,2,buf����round1_result
//current_rounds=1,  buf����round2_result
always @ (*) begin
    for (ii=0;ii<8;ii=ii+1) begin
        if (swap[0][ii]) begin
            //0��8,1��9
            round1_result[ii]        = skips>0?data[ii]:data[ii+8];
            round1_result[ii+8]      = skips>0?data[ii+8]:data[ii];
        end
        else begin
            round1_result[ii]        = data[ii];
            round1_result[ii+8]      = data[ii+8];
        end
    end

end

always @ (*) begin
    for (ii=0;ii<4;ii=ii+1) begin
        if (swap[1][ii]) begin
            //0��4,1��5,2��6,3��7��      8��12��9��13��10��14��11��15
            round2_result[ii]        = skips>1?data[ii]:round1_result[ii+4];
            round2_result[ii+4]      = skips>1?data[ii+4]:round1_result[ii];
        end
        else begin
            round2_result[ii]        = skips>1?data[ii]:round1_result[ii];
            round2_result[ii+4]      = skips>1?data[ii+4]:round1_result[ii+4];
        end

        if (swap[1][ii+4]) begin
            round2_result[ii+8]      = skips>1?data[ii+8]:round1_result[ii+12];
            round2_result[ii+12]     = skips>1?data[ii+12]:round1_result[ii+8];
        end
        else begin
            round2_result[ii+8]      = skips>1?data[ii+8]:round1_result[ii+8];
            round2_result[ii+12]     = skips>1?data[ii+12]:round1_result[ii+12];
        end
    end

end


always @ (*) begin
    for (ii=0;ii<4;ii=ii+1) begin
        if (swap[2][ii*2]) begin
            //0��2��1��3��  4��6��5��7��    8��10��9��11��    12��14��13��15
            round3_result[ii*4]        = skips==3?data[ii*4]:round2_result[ii*4+2];
            round3_result[ii*4+2]      = skips==3?data[ii*4+2]:round2_result[ii*4];
        end
        else begin
            round3_result[ii*4]        = skips==3?data[ii*4]:round2_result[ii*4];
            round3_result[ii*4+2]      = skips==3?data[ii*4+2]:round2_result[ii*4+2];
        end

        if (swap[2][ii*2+1]) begin
            round3_result[ii*4+1]      = skips==3?data[ii*4+1]:round2_result[ii*4+3];
            round3_result[ii*4+3]      = skips==3?data[ii*4+3]:round2_result[ii*4+1];
        end
        else begin
            round3_result[ii*4+1]      = skips==3?data[ii*4+1]:round2_result[ii*4+1];
            round3_result[ii*4+3]      = skips==3?data[ii*4+3]:round2_result[ii*4+3];
        end
    end
end

always @ (*) begin
    for (ii=0;ii<8;ii=ii+1) begin
        if (swap[3][ii]) begin
            round4_result[ii*2]        = result[ii*2+1];
            round4_result[ii*2+1]      = result[ii*2];
        end
        else begin
            round4_result[ii*2]        = result[ii*2];
            round4_result[ii*2+1]      = result[ii*2+1];
        end
    end

end



endmodule
