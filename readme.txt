bitonic排序verilog实现
C参考代码在https://github.com/tishi43/bitonic_my

bitonic sort
C reference code is at https://github.com/tishi43/bitonic_my

1. Design
    In this example, data is 50bit width, in real case, the data count is often very huge, for example 2048,
it should be stored in bram, in this example, the bram data width is 100bit, each item contains two data,
and there is a local buffer, can holds 16 data items, it takes 8 cycles to read 16 data from bram to local reg,
the processing takes 1 or 2 cycles, after processing the data is written back to bram, read and write of bram is pipelined.
why 2 cycles? just to meet 150M performance goals in my Zynq7035 board.

Some explanation how local buffer works.

Many documents describe how bitonic sort works, the below is an example of data count=16

Example 1: N=16
original data  5, 7,  15, 4,   0, 3,   11, 9,  12, 8,  1, 14, 13, 2, 6, 10

        ascend  descend  ascend  descend  ascend descend ascend  descend
step 1: [5 7]   [15 4]   [0 3]   [11 9]  [8 12]  [14 1]  [2 13]  [10 6]

step 2,   4 data is a group, first group ascend, second group descend, third ascend, and so on.

           ascend      descend            ascend         descend
round 1 [5 4 15 7]    [11 9 0 3]       [8 1 14 12]     [10 13 2 6]
        ascend ascend descend descend  ascend ascend   descend descend
round 2 [4 5] [7 15]  [11 9]  [3 0]    [1 8] [12 14]   [13 10] [6 2]


step 3, 8 data is a group

                  ascend                       descend
round 1  [4 5 3 0    11 9 7  15]    [13 10 12 14    1 8 6 2]
            ascend      ascend        descend           descend
round 2  [3 0 4 5]    [7 9 11 15]    [13 14 12 10]     [6 8 1 2]
        ascend ascend ascend  ascend   descend  descend descend descend
round 3  [0 3][4 5]   [7 9]  [11 15]  [14 13]  [12 10]  [8 6]  [2 1]


step 4, all data is a group, all are sorted as ascend
round 1:  [ 0  3  4  5   7  6  2 1    14  13  12  10  8  9  11 15 ]
round 2    [ 0  3 2 1    7  6 4 5 ]  [8 9 11 10    14 13 12 15]
round 3    [0  1 2 3]    [4  5 7  6]  [8 9  11 10]  [12 13 14 15]
round 4    [0 1] [2 3]   [4 5] [6 7]  [8 9] [10 11]  [12 13] [14 15]

For data count <= 16, all groups fit into the local buffer.
For data count > 16, for example 256, let's take the last second step, step 7 as an example,
the number below is data index, not real number.
In step 7, 128 data is group, local buffer can not hold 128 data, they are divided into 8 sub groups, each sub group contains 16 data,
because each item contains two data, 8 cycles are taken to fetch 16 data from bram,
the first group [0,1,...     126,127],
sub group 1 is [0,1,  16,17,  32,33,  48,49,  64,65,  80,81,  96,97,  112,113]
sub group 2 is [2,3,  18,19,  34,35,  50,51,  66,67,  82,83,  98,99,  114,115]
...
sub group 8 is [14,15,  30,31,  46,47,  62,63,  78,79,  94,95,  110,111,  126,127]

each sub group is processed in local buffer, 3 rounds in a cycle, and if the remain rounds is less than or equal to 4, 
another cycle is taken to get the last round result.



Example 2 N=256
...
step 7
                ascend                     descend
round 1    [0,1,...     126,127]      [128,129,...254,255]
round 2    [0,1,...63][64,...127]    [128,...190][191,...255]
...

step 8
                   ascend
round 1   [0,1,...                254,255]


2. Performance
    Sorting 2048 items takes abount 30000 cycles.
    To get better performance, you can increase the bram data width or increase the local buffer size.

3.Resource utilization
+-------------------------+------+-------+-----------+-------+

|        Site Type        | Used | Fixed | Available | Util% |

+-------------------------+------+-------+-----------+-------+

| Slice LUTs*             | 4238 |     0 |    171900 |  2.47 |

|   LUT as Logic          | 4238 |     0 |    171900 |  2.47 |

|   LUT as Memory         |    0 |     0 |     70400 |  0.00 |

| Slice Registers         | 1860 |     0 |    343800 |  0.54 |

|   Register as Flip Flop | 1860 |     0 |    343800 |  0.54 |

|   Register as Latch     |    0 |     0 |    343800 |  0.00 |

| F7 Muxes                |    0 |     0 |    109300 |  0.00 |

| F8 Muxes                |    0 |     0 |     54650 |  0.00 |

+-------------------------+------+-------+-----------+-------+

