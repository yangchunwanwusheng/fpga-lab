# FPGA 数字逻辑实验工作区

哈尔滨工程大学计算机实验教学中心《基本组合、时序逻辑电路实验》等系列实验工作区。
软件相关操作（建模、编译、仿真、引脚分配、下载）由 ZCode 通过 computer-use 操控 Quartus Prime 完成；实验台接线、按键/听音等物理操作由人工完成。

## 环境与约定

- 工具：Quartus Prime **25.1std Lite**（`D:\QP\quartus\bin64`）；仿真用 University Program VWF（*.vwf）
- **仿真器**：Questa 25.1（`D:\QP\questa_fse`）与 VWF 流程的 `-novopt` 参数不兼容（vsim-12110 错误）；已在 Tools→Options→EDA Tool Options→"Questa Altera" 改指向 **ModelSim ASE 10.5b**（`D:\intelFPGA\17.1\modelsim_ase\win32aloem`），VWF 功能仿真可用
- 目标芯片：Cyclone IV E **EP4CE55F23C8**（484 pin，speed grade 8）
- 实验台：KX-CDS，电路模式 No.5，下载器 USB-Blaster（JTAG）；硬件检查：`D:\QP\quartus\bin64\jtagconfig.exe`
- **路径必须纯英文、无空格**；工程名 = 顶层实体名 = 文件名
- **实体名规则：在原名后加两人学号的后两位**。已确认本组后缀 **2223**（mux21a2223 / mux81a2223），全链路改名+重编译已完成
- 每个工程单独文件夹；验收需截图：电路图(RTL/原理图)、代码图、波形图、引脚锁定图、实验台图（已存各工程 `shots\`；实验台图需现场手机/截图）
- 按组验收（2人）+ 智慧树实验后测试；**课内 + 选做都要做**

## 目录结构

```
D:\FPGA_Lab\
├── exp1\                      实验1：基本组合、时序逻辑电路
│   ├── class1_mux21a\         第1次课 课内：VHDL 2选1选择器（mux21a.vhd）
│   ├── class2_decoder24\      第2次课 课内：原理图 2-4译码器（decoder24.bdf）
│   ├── class2_counter\        第2次课 课内：lpm_counter 计数器（LabCounter.bdf）
│   ├── class2_reg8\           第2次课 课内：74273 改造 8位寄存器（LabReg.bdf + Reg8 自定义元件）
│   ├── optional_81mux_verilog\ 第1次课 选做：Verilog 8选1选择器 + 波形仿真
│   └── optional_verilog\      第2次课 选做：Verilog 实现 2-4译码器/计数器/8位寄存器
└── _docs\                     实验指导书文字版（PDF 提取）、报告素材
```

## 实验1 任务清单

### 第1次课（课内：mux21a）✅ 软件流程已完成，待实验台验证
- [x] **上台操作手册已生成**：`_docs\exp1_class1_bench_guide.docx`（11 页：进度表、上台前清单、操作六步含本机按钮截图、材料清单、故障速查；同目录有同名 PDF）
- [x] 新建工程 mux21a2223（VHDL 文本输入，`exp1\class1_mux21a\`）
- [x] 选器件 EP4CE55F23C8，编译通过（1 LE / 4 pins），RTL Viewer 截图 `shots\01_rtl_mux21a.png`
- [x] VWF 波形仿真通过（a/b/s 三时钟 0-800ns 覆盖真值表 8 行；y 波形与真值表逐项吻合）`shots\03_wave_mux21a.png`
- [x] 代码截图 `shots\02_code_mux21a.png`；引脚分配并编译 `shots\04_pins_mux21a.png`（a=W22, b=W21, s=N1, y=AA8）
- [x] **USB-Blaster 下载 sof，实验台听音验证**（2026-09-09 实测通过：驱动本机已装好，jtagconfig 检测到 EP4CE55，`quartus_pgm` 下载 mux21a2223.sof 成功，s=0→1024Hz 高音、s=1→256Hz 低音，音调随按键切换）
- [x] 选做（**2026 版要求 8bit 数据宽度**）：mux81a2223 = d0..d7 各 [7:0]、s[2:0]、y[7:0]，case 实现；编译 40 LE / 75 pins；VWF 仿真通过（d_i=00,11,…,77，s 每 80ns 计数 0-7，y 二进制显示恰为对应通道值）；截图 `optional_81mux_verilog\shots\02_code_mux81a.png`、`03_wave_mux81a.png`（选做只要求波形仿真；如需 RTL 图：Tools→Netlist Viewers→RTL Viewer 手动截取）
- [x] 已核对 2026 版指导书（33 页）：功能/芯片/引脚/流程与 2025 版一致；新增驱动安装页（p22-24）与波形仿真失败修复方法（p30-32，方法3 同样指向 modelsim_ase\win32aloem，与本项目仿真器切换方案一致）
- [x] Programmer 界面已实机确认：`shots\05_programmer_mux21a.png`（SOF 已挂载、JTAG 模式、Program/Configure 已勾选，仅缺 USB-Blaster 硬件；工程另存链文件 mux21a2223.cdf）
- [x] **学号后缀已确认 22/23 → 2223**：全链路改名（源码/qpf/qsf/vwf）+ 全新编译（0 错误）+ 仿真重跑验证 + 截图全部重拍（2026-09-09）

### 第2次课（课内三个工程，均为原理图 .bdf 输入）
- [ ] decoder24：基本门（and2/not 等）搭 2-4 译码器，编译+仿真（对照真值表 BA→F3..F0）
- [ ] LabCounter：IP Catalog 调 lpm_counter（8位、含 aclr/aload），仿真覆盖置数/计数/清零
- [ ] LabReg：修改 74273 库元件另存 Reg8.bdf→生成 Reg8.bsf→顶层例化，仿真时钟打入数据
- [ ] 选做：三个电路的 Verilog 版本 + 编译仿真
- [ ] 预习提示：下次实验是运算器、ROM/RAM（教材 221-264 页）

## 队友克隆上手指南

1. **克隆**：`git clone https://github.com/yangchunwanwusheng/fpga-lab.git`（私有仓库，需先在仓库 Settings→Collaborators 里被邀请）。
2. **软件**：工程由 Quartus Prime **25.1std Lite** 创建，建议本机安装同版本（免费，器件库勾选 Cyclone IV E）。机房 17.1 版打开会有版本差异警告，能用但界面按钮位置略有差异。
3. **直接可用**：`exp1\class1_mux21a\mux21a2223.qpf` 打开即用——`output_files\mux21a2223.sof` 已随仓库提供，上台时 Tools→Programmer 直接下载即可，无需重新编译。引脚锁定（a=W22、b=W21、s=N1、y=AA8）已在工程里。
4. **如需重新编译/仿真**：编译直接 Processing→Start Compilation；VWF 仿真前需配置仿真器：Tools→Options→EDA Tool Options→"Questa Altera" 指向 ModelSim 安装目录的 `modelsim_ase\win32aloem`（本机为 `D:\intelFPGA\17.1\modelsim_ase\win32aloem`，Questa 25.1 与 VWF 的 `-novopt` 参数不兼容勿用）。
5. **上台操作**：照 `_docs\exp1_class1_bench_guide.docx` 第三节的六步走（含接线表、驱动安装、下载、听音验收）。
6. **实体名后缀 2223**（学号 22+23）两人通用，所有文件名已一致，克隆后无需任何改动。

## 待确认信息

- [x] 本机 Quartus Prime 版本与安装路径（25.1std Lite @ `D:\QP\quartus`；ModelSim ASE @ `D:\intelFPGA\17.1`）
- [x] 两人学号后两位：已确认 22、23 → 后缀 **2223**，全链路改名完成（2026-09-09）
- [ ] 实验报告格式/模板
