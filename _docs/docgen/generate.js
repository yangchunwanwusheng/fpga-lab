// generate.js — 实验1第1次课 上台操作手册 DOCX
// R1 cover (DS-1) + TOC (Roman) + body (Arabic), Profile A fonts
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  ImageRun, PageBreak, Header, Footer, PageNumber, NumberFormat,
  AlignmentType, HeadingLevel, WidthType, BorderStyle, ShadingType,
  SectionType, TableOfContents, LevelFormat, TableLayoutType,
} = require("docx");
const fs = require("fs");

// ── palette DS-1 (Deep Sea) ──
const PAL = {
  bg: "0B1C2C", accent: "529286",
  cover: { titleColor: "FFFFFF", subtitleColor: "B0B8C0", metaColor: "90989F", footerColor: "687078" },
  table: { headerBg: "529286", headerText: "FFFFFF", accentLine: "529286", innerLine: "BECFCC", surface: "E8ECEB" },
};
const INK = "0B1C2C";          // heading ink on white pages
const WARN = "C0392B";         // warning accent
const BODY = "000000";         // body text pure black (Profile A)

const NB = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const noBorders = { top: NB, bottom: NB, left: NB, right: NB };
const allNoBorders = { top: NB, bottom: NB, left: NB, right: NB, insideHorizontal: NB, insideVertical: NB };

// ── cover helpers (from design-system.md) ──
function splitTitleLines(title, charsPerLine) {
  if (title.length <= charsPerLine) return [title];
  const breakAfter = new Set([...'，。、；：！？', ...'的与和及之在于为', ...'-_—–·/', ...' \t']);
  const lines = [];
  let remaining = title;
  while (remaining.length > charsPerLine) {
    let breakAt = -1;
    for (let i = charsPerLine; i >= Math.floor(charsPerLine * 0.6); i--) {
      if (i < remaining.length && breakAfter.has(remaining[i - 1])) { breakAt = i; break; }
    }
    if (breakAt === -1) {
      const limit = Math.min(remaining.length, Math.ceil(charsPerLine * 1.3));
      for (let i = charsPerLine + 1; i < limit; i++) {
        if (breakAfter.has(remaining[i - 1])) { breakAt = i; break; }
      }
    }
    if (breakAt === -1) {
      breakAt = charsPerLine;
      const prevChar = remaining[breakAt - 1], nextChar = remaining[breakAt];
      if (prevChar && nextChar && !breakAfter.has(prevChar) && !breakAfter.has(nextChar) &&
          /[\u4e00-\u9fff]/.test(prevChar) && /[\u4e00-\u9fff]/.test(nextChar)) breakAt -= 1;
    }
    lines.push(remaining.slice(0, breakAt).trim());
    remaining = remaining.slice(breakAt).trim();
  }
  if (remaining) lines.push(remaining);
  if (lines.length > 1 && lines[lines.length - 1].length <= 2) {
    const last = lines.pop();
    lines[lines.length - 1] += last;
  }
  return lines;
}
function calcTitleLayout(title, maxWidthTwips, preferredPt = 40, minPt = 24) {
  const charWidth = (pt) => pt * 20;
  const charsPerLine = (pt) => Math.floor(maxWidthTwips / charWidth(pt));
  let titlePt = preferredPt, lines;
  while (titlePt >= minPt) {
    const cpl = charsPerLine(titlePt);
    if (cpl < 2) { titlePt -= 2; continue; }
    lines = splitTitleLines(title, cpl);
    if (lines.length <= 3) break;
    titlePt -= 2;
  }
  if (!lines || lines.length > 3) {
    lines = splitTitleLines(title, charsPerLine(minPt));
    titlePt = minPt;
  }
  return { titlePt, titleLines: lines };
}
function calcCoverSpacing(params) {
  const { titleLineCount = 1, titlePt = 36, hasSubtitle = false, hasEnglishLabel = false,
    metaLineCount = 0, fixedHeight = 800, pageHeight = 16838, marginTop = 0, marginBottom = 0 } = params;
  const SAFETY = 1200;
  const usableHeight = pageHeight - marginTop - marginBottom - SAFETY;
  const titleHeight = titleLineCount * (titlePt * 23 + 200);
  const subtitleHeight = hasSubtitle ? (12 * 23 + 600) : 0;
  const englishLabelHeight = hasEnglishLabel ? (9 * 23 + 600) : 0;
  const metaHeight = metaLineCount * (10 * 23 + 100);
  const implicitParaHeight = 3 * 300;
  const contentHeight = titleHeight + subtitleHeight + englishLabelHeight + metaHeight + fixedHeight + implicitParaHeight;
  const remainingSpace = usableHeight - contentHeight;
  const safeRemaining = Math.max(remainingSpace, 400);
  const FOOTER_MIN = 800;
  const rawTop = Math.floor(safeRemaining * 0.45);
  const rawBottom = Math.floor(safeRemaining * 0.45);
  const bottomSpacing = Math.max(rawBottom, FOOTER_MIN);
  const topSpacing = Math.max(rawTop - Math.max(0, FOOTER_MIN - rawBottom), 400);
  const midSpacing = Math.max(safeRemaining - topSpacing - bottomSpacing, 0);
  return { topSpacing, midSpacing, bottomSpacing };
}
function buildCoverR1(config) {
  const P = config.palette;
  const padL = 1200, padR = 800;
  const availableWidth = 11906 - padL - padR - 300;
  const { titlePt, titleLines } = calcTitleLayout(config.title, availableWidth, 40, 24);
  const titleSize = titlePt * 2;
  const spacing = calcCoverSpacing({
    titleLineCount: titleLines.length, titlePt,
    hasSubtitle: !!config.subtitle, hasEnglishLabel: !!config.englishLabel,
    metaLineCount: (config.metaLines || []).length, fixedHeight: 400,
  });
  const accentLeft = { style: BorderStyle.SINGLE, size: 8, color: P.accent, space: 12 };
  const children = [];
  children.push(new Paragraph({ spacing: { before: spacing.topSpacing } }));
  if (config.englishLabel) {
    children.push(new Paragraph({
      indent: { left: padL, right: padR }, spacing: { after: 500 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: P.accent, space: 8 } },
      children: [new TextRun({ text: config.englishLabel.split("").join("  "),
        size: 18, color: P.accent, font: { ascii: "Calibri", eastAsia: "SimHei" }, characterSpacing: 40 })],
    }));
  }
  for (let i = 0; i < titleLines.length; i++) {
    children.push(new Paragraph({
      indent: { left: padL },
      spacing: { after: i < titleLines.length - 1 ? 100 : 300, line: Math.ceil(titlePt * 23), lineRule: "atLeast" },
      children: [new TextRun({ text: titleLines[i], size: titleSize, bold: true,
        color: P.cover.titleColor, font: { eastAsia: "SimHei", ascii: "Arial" } })],
    }));
  }
  if (config.subtitle) {
    children.push(new Paragraph({
      indent: { left: padL }, spacing: { after: 800 },
      children: [new TextRun({ text: config.subtitle, size: 24, color: P.cover.subtitleColor,
        font: { eastAsia: "Microsoft YaHei", ascii: "Arial" } })],
    }));
  }
  for (const line of (config.metaLines || [])) {
    children.push(new Paragraph({
      indent: { left: padL + 200 }, spacing: { after: 80 },
      border: { left: accentLeft },
      children: [new TextRun({ text: line, size: 24, color: P.cover.metaColor,
        font: { eastAsia: "Microsoft YaHei", ascii: "Arial" } })],
    }));
  }
  children.push(new Paragraph({ spacing: { before: spacing.bottomSpacing } }));
  children.push(new Paragraph({
    indent: { left: padL, right: padR },
    border: { top: { style: BorderStyle.SINGLE, size: 2, color: P.accent, space: 8 } },
    spacing: { before: 200 },
    children: [
      new TextRun({ text: config.footerLeft || "", size: 16, color: P.cover.footerColor, font: { ascii: "Arial", eastAsia: "Microsoft YaHei" } }),
      new TextRun({ text: "                                        " }),
      new TextRun({ text: config.footerRight || "", size: 16, color: P.cover.footerColor, font: { ascii: "Arial", eastAsia: "Microsoft YaHei" } }),
    ],
  }));
  return [new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    layout: TableLayoutType.FIXED,
    borders: allNoBorders,
    rows: [new TableRow({
      height: { value: 16838, rule: "exact" },
      children: [new TableCell({
        shading: { type: ShadingType.CLEAR, fill: P.bg }, borders: noBorders,
        children,
      })],
    })],
  })];
}

// ── body helpers ──
function pngSize(p) { const b = fs.readFileSync(p); return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) }; }
let figNo = 0;
function figure(path, displayW, captionText) {
  figNo += 1;
  const { w, h } = pngSize(path);
  const dh = Math.round(displayW * h / w);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER, keepNext: true, spacing: { before: 160, after: 60 },
      children: [new ImageRun({ data: fs.readFileSync(path), type: "png", transformation: { width: displayW, height: dh } })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: "图" + figNo + "  " + captionText, size: 21, color: "606060", font: { eastAsia: "SimSun", ascii: "Times New Roman" } })],
    }),
  ];
}
function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1, spacing: { before: 360, after: 160, line: 312 },
    children: [new TextRun({ text, bold: true, size: 32, color: INK, font: { eastAsia: "SimHei", ascii: "Times New Roman" } })],
  });
}
function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2, spacing: { before: 260, after: 120, line: 312 },
    children: [new TextRun({ text, bold: true, size: 28, color: INK, font: { eastAsia: "SimHei", ascii: "Times New Roman" } })],
  });
}
function prose(runsOrText, opts = {}) {
  const runs = typeof runsOrText === "string"
    ? [new TextRun({ text: runsOrText, size: 24, color: BODY, font: { eastAsia: "SimSun", ascii: "Times New Roman" } })]
    : runsOrText;
  return new Paragraph({
    alignment: AlignmentType.JUSTIFIED, indent: { firstLine: opts.noIndent ? 0 : 480 },
    spacing: { line: 312, after: opts.after ?? 80 }, keepNext: opts.keepNext || false, children: runs,
  });
}
function r(text, o = {}) {
  return new TextRun({ text, size: o.size || 24, bold: o.bold || false, color: o.color || BODY,
    font: { eastAsia: o.hei ? "SimHei" : "SimSun", ascii: "Times New Roman" } });
}
function numItem(ref, text, boldPrefix) {
  const children = boldPrefix
    ? [new TextRun({ text: boldPrefix, bold: true, size: 24, color: BODY, font: { eastAsia: "SimHei", ascii: "Times New Roman" } }),
       new TextRun({ text, size: 24, color: BODY, font: { eastAsia: "SimSun", ascii: "Times New Roman" } })]
    : [new TextRun({ text, size: 24, color: BODY, font: { eastAsia: "SimSun", ascii: "Times New Roman" } })];
  return new Paragraph({
    numbering: { reference: ref, level: 0 }, spacing: { line: 312, after: 60 }, children,
  });
}
function caption(text) {
  return new Paragraph({
    keepNext: true, spacing: { before: 160, after: 80 },
    children: [new TextRun({ text, bold: true, size: 21, color: INK, font: { eastAsia: "SimHei", ascii: "Times New Roman" } })],
  });
}
function mkTable(widths, header, rows, opts = {}) {
  const cellMargins = { top: 60, bottom: 60, left: 120, right: 120 };
  const headerRow = new TableRow({
    tableHeader: true, cantSplit: true,
    children: header.map((t, i) => new TableCell({
      shading: { type: ShadingType.CLEAR, fill: PAL.table.headerBg },
      margins: cellMargins, width: { size: widths[i], type: WidthType.PERCENTAGE },
      children: [new Paragraph({ spacing: { line: 276 },
        children: [new TextRun({ text: t, bold: true, size: 21, color: PAL.table.headerText, font: { eastAsia: "SimHei", ascii: "Times New Roman" } })] })],
    })),
  });
  const dataRows = rows.map((row, ri) => new TableRow({
    cantSplit: true,
    children: row.map((t, i) => new TableCell({
      shading: (opts.zebra && ri % 2 === 1) ? { type: ShadingType.CLEAR, fill: PAL.table.surface } : undefined,
      margins: cellMargins, width: { size: widths[i], type: WidthType.PERCENTAGE },
      children: [new Paragraph({ spacing: { line: 276 },
        children: [new TextRun({ text: t, size: 21, color: BODY, font: { eastAsia: "SimSun", ascii: "Times New Roman" } })] })],
    })),
  }));
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 4, color: PAL.table.accentLine },
      bottom: { style: BorderStyle.SINGLE, size: 4, color: PAL.table.accentLine },
      left: NB, right: NB,
      insideHorizontal: { style: BorderStyle.SINGLE, size: 1, color: PAL.table.innerLine },
      insideVertical: NB,
    },
    rows: [headerRow, ...dataRows],
  });
}
function pageNumFooter() {
  return new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER,
    children: [new TextRun({ children: [PageNumber.CURRENT], size: 18, color: "808080" })] })] });
}

const SHOTS = "D:/FPGA_Lab/exp1/class1_mux21a/shots/";
const TOOLS = "D:/FPGA_Lab/_tools/";

// ── body content ──
const body = [];

// 一、当前进度
body.push(h1("一、当前进度：本机已完成的软件流程"));
body.push(prose("实验一第1次课的全部软件环节已经在本机完成。工程、实体名均按规定采用 mux21a2223（两人学号后两位 22、23，见第二节），目标器件为 Cyclone IV E 系列 EP4CE55F23C8，与 2026 版指导书一致。编程下载所需的 SOF 文件已经生成，上台后只剩硬件连接、驱动安装和下载验收三个环节。"));
body.push(caption("表1  软件流程完成情况"));
body.push(mkTable([8, 38, 12, 42],
  ["序", "环节", "状态", "产物位置"],
  [
    ["1", "新建工程 mux21a2223，VHDL 文本输入 2选1选择器", "已完成", "exp1/class1_mux21a/mux21a2223.vhd"],
    ["2", "选择器件 EP4CE55F23C8 并全编译", "已完成", "output_files/mux21a2223.sof（下载文件）"],
    ["3", "引脚锁定 a=W22、b=W21、s=N1、y=AA8", "已完成", "shots/04_pins_mux21a.png"],
    ["4", "University Program VWF 波形仿真（真值表8种组合全覆盖）", "已完成", "shots/03_wave_mux21a.png"],
    ["5", "验收截图：电路图、代码图、波形图、引脚锁定图", "已完成", "shots/ 目录（共4张）"],
    ["6", "选做：Verilog 8选1选择器（数据宽度8bit）编译+仿真", "已完成", "exp1/optional_81mux_verilog/"],
    ["7", "USB-Blaster 驱动安装 + 下载 SOF 到实验台", "上台完成", "见第三节操作步骤"],
    ["8", "实验台功能验收，补拍实验台图", "上台完成", "见第四节材料清单"],
  ], { zebra: true }));
body.push(prose("仿真结论：mux21a2223 在 0 至 800ns 内以三路不同周期的时钟信号遍历真值表全部 8 行，输出 y 与真值表完全一致，即 s=0 时 y=a，s=1 时 y=b。选做的 mux81a2223 按 2026 版要求做成 8 位数据宽度，仿真中 y 依次等于被选中的 d0 至 d7（00、11、22、……、77），功能正确。", { after: 120 }));

// 二、上台前准备
body.push(h1("二、上台前准备"));
body.push(h2("2.1  实体名后缀已确认为 2223（两人学号后两位 22、23）"));
body.push(prose([
  r("2026 版指导书第 33 页规定：两人一组，实体名后加两个学号的后两位，且其他文件名都要与实体名保持一致。", { bold: true }),
  r("本组两人学号后两位已确认为 22 和 23，实体名后缀取 2223：课内工程为 mux21a2223，选做工程为 mux81a2223。"),
]));
body.push(prose("全链路改名已经完成：源文件、工程文件、波形文件、仿真设置已统一为 2223 后缀，两个工程均已重新全编译（0 错误），全部截图已按新实体名重新截取。上台验收时实体名与学号可以直接对应。若后缀需要再改，需对源文件、工程、波形文件整体改名并重新编译。"));
body.push(h2("2.2  需要携带与确认的物品"));
body.push(numItem("list-bring", "本笔记本电脑（工程已全部就绪）；若改用机房电脑，请拷贝整个 exp1/class1_mux21a 文件夹。"));
body.push(numItem("list-bring", "实验台电源线与 USB 线（实验台通常自带，用于连接 JTAG 与电脑）。"));
body.push(numItem("list-bring", "三名一组验收时的实验单；手机用于现场拍摄实验台图。"));
body.push(h2("2.3  若在机房电脑操作"));
body.push(prose("机房电脑的 Quartus 为 17.1 版，安装路径为 D:\\intelFPGA_lite\\17.1，与本机截图（25.1 版，D:\\QP\\quartus）界面略有差异，但菜单与按钮位置基本一致。机房电脑装有还原卡，每次重启后都需要重新安装实验台驱动（见第 2 步）。若在机房电脑重建工程并仿真失败，按第五节故障速查处理。"));

// 三、六步操作
body.push(h1("三、实验台操作六步（对应 2026 版指导书第 22 至 28 页）"));

body.push(h2("第 1 步  实验台上电并连接 JTAG（指导书 p22）"));
body.push(prose("打开实验台电源（电源开关在实验台右侧面），用 USB 线把实验台的 JTAG 接口与电脑相连。连接后电脑会识别出 USB 设备；未装驱动时设备管理器中会显示带黄色感叹号的 USB-Blaster。"));

body.push(h2("第 2 步  安装 USB-Blaster 驱动（指导书 p23-p24）"));
body.push(prose("打开设备管理器，右键 USB-Blaster 设备，选择更新驱动程序，选择浏览我的电脑以查找驱动程序，路径指定为驱动所在目录后点击下一步即可。本机驱动目录为 D:\\QP\\quartus\\drivers（图1）；指导书中写的 D:\\intelFPGA_lite\\17.1\\quartus\\drivers 是机房电脑的路径。"));
body.push(...figure(SHOTS + "06_driver_folder.png", 540, "本机驱动目录 D:\\QP\\quartus\\drivers（含 usb-blaster 子目录）"));
body.push(prose([
  r("注意：", { bold: true, color: WARN }),
  r("机房电脑有还原卡，每次重启计算机后，使用实验台前都要重新安装一次驱动；个人笔记本如安装失败可多试几次或更换 USB 口。"),
]));

body.push(h2("第 3 步  时钟、蜂鸣器接线与电路模式（指导书 p26、p28）"));
body.push(prose("按表 2 用单线把时钟源和蜂鸣器接到实验台对应区域，s 使用板上按键 1，无需接线。接好后把实验台右侧的电路模式选择按键按到 No.5。", { keepNext: true }));
body.push(caption("表2  KX-CDS 实验台接线表（电路模式 No.5，EP4CE55F23C8）"));
body.push(mkTable([10, 14, 18, 12, 46],
  ["信号", "FPGA引脚", "外设/引脚名", "单线", "接线方法"],
  [
    ["a", "W22", "时钟 CLKB0", "黄色", "J13 标准时钟源 1024Hz 输出，接 J17 区 CLKB0"],
    ["b", "W21", "时钟 CLKB1", "棕色", "J13 标准时钟源 256Hz 输出，接 J17 区 CLKB1"],
    ["s", "N1", "按键 1（PIO0）", "—", "板载按键，无需接线"],
    ["y", "AA8", "扬声器 DBT1", "绿色", "J7 区 DBT1，接 J16 区蜂鸣器信号输入（两引脚任插一个）"],
  ]));
body.push(prose("引脚锁定已在工程中完成（图2），无需再改动；此图即报告中所需的引脚锁定图。", { after: 60 }));
body.push(...figure(SHOTS + "04_pins_mux21a.png", 540, "引脚锁定（Pin Planner）：a=W22、b=W21、s=N1、y=AA8"));

body.push(h2("第 4 步  打开工程并启动 Programmer（指导书 p25）"));
body.push(prose("双击打开 D:\\FPGA_Lab\\exp1\\class1_mux21a\\mux21a2223.qpf，在主菜单选择 Tools 中的 Programmer（图3），打开编程器窗口（图4）。"));
body.push(...figure(TOOLS + "tools_menu_clean.png", 280, "Tools 菜单中的 Programmer 项"));
body.push(...figure(SHOTS + "05_programmer_mux21a.png", 540, "Programmer 窗口（本机截图）：SOF 已就绪，仅缺硬件"));

body.push(h2("第 5 步  选择硬件并下载（指导书 p27）"));
body.push(numItem("list-step5", "点击左上角 Hardware Setup 按钮，在弹出窗口的下拉列表中选择 USB-Blaster，点击 Close 关闭。连接成功后，原来显示 No Hardware 的位置会变为 USB-Blaster [USB-0]。", "选硬件："));
body.push(numItem("list-step5", "确认 Mode 为 JTAG；文件列表中已有 output_files/mux21a2223.sof，器件为 EP4CE55F23，Program/Configure 已勾选（图4 中均已就绪）。", "查设置："));
body.push(numItem("list-step5", "点击左侧 Start 按钮，等待右侧 Progress 进度到 100%，下载完成。", "下载："));

body.push(h2("第 6 步  实验台功能验收（指导书 p28）"));
body.push(prose("下载完成后即可在实验台上验证 2选1选择器功能：s=0（松开按键 1）时输出 a，蜂鸣器发出 1024Hz 较高音；s=1（按住按键 1）时输出 b，蜂鸣器发出 256Hz 较低音。反复按放按键 1，音调应随之切换。仿真阶段同样验证了这组选择关系（图5）。"));
body.push(...figure(SHOTS + "03_wave_mux21a.png", 540, "功能仿真波形：y 随 s 在 a、b 间正确选通（真值表 8 行全覆盖）"));

// 四、材料清单
body.push(h1("四、验收截图与实验报告材料"));
body.push(prose("指导书第 29 页要求实验截图包含电路图、代码图、波形图、引脚锁定图、实验台图五类，建议采用电脑屏幕截屏方式。前四类已经完成，实验台图需在现场补拍。", { keepNext: true }));
body.push(caption("表3  截图与材料清单"));
body.push(mkTable([22, 44, 12, 22],
  ["材料", "对应文件", "状态", "说明"],
  [
    ["电路图（RTL）", "shots/01_rtl_mux21a.png", "已有", "RTL Viewer 截屏"],
    ["代码图", "shots/02_code_mux21a.png", "已有", "VHDL 源码截屏"],
    ["波形图", "shots/03_wave_mux21a.png", "已有", "真值表 8 行全覆盖"],
    ["引脚锁定图", "shots/04_pins_mux21a.png", "已有", "Pin Planner 截屏"],
    ["实验台图", "现场拍摄", "上台补拍", "含模式 No.5、接线与下载界面"],
    ["选做代码图", "optional_81mux_verilog/shots/02_code_mux81a.png", "已有", "8 位数据宽度 8选1"],
    ["选做波形图", "optional_81mux_verilog/shots/03_wave_mux81a.png", "已有", "y 依次输出 00 至 77"],
  ], { zebra: true }));
body.push(prose("实验台图建议拍摄一张全景：能看清电路模式选择按键处于 No.5、J17/J13/J16 三处接线，以及电脑屏幕上 Programmer 进度 100% 的画面。选做部分只需波形仿真，无需下载，可直接写入报告。", { after: 120 }));

// 五、故障速查
body.push(h1("五、常见故障速查"));
body.push(prose("以下前两条对应下载环节，后三条整理自指导书第 30 至 32 页与本机调试经验。", { keepNext: true }));
body.push(caption("表4  常见故障与处理"));
body.push(mkTable([26, 32, 42],
  ["现象", "可能原因", "处理方法"],
  [
    ["Programmer 显示 No Hardware", "驱动未装、USB 线未接或实验台未上电", "重做第 1、2 步；设备管理器中确认 USB-Blaster 无感叹号"],
    ["点 Start 后 JTAG 连接报错", "连接不稳或硬件选择错误", "重新 Hardware Setup 选择 USB-Blaster；换 USB 口；确认实验台已上电"],
    ["蜂鸣器不响或音调不变", "接线松脱、电路模式不对", "检查 J16 绿线与 J13 两根时钟线；确认模式为 No.5；重新下载 SOF"],
    ["波形仿真失败", "仿真器未配置或文件位置不对", "按指导书 p30-p32 三种方法；本机方案：Tools 的 Options 中把 Questa Altera 路径指向 modelsim_ase 的 win32aloem 目录"],
    ["改名或重编译后报错", "文件名与实体名不一致", "所有文件名、工程名、实体名统一为同一名称（指导书 p33）"],
  ], { zebra: true }));

// 六、文件位置
body.push(h1("六、关键文件位置"));
body.push(prose("以下均为本机绝对路径，拷贝工程时至少带上工程文件夹整体（含 db、output_files 子目录可直接省去重新编译）。", { keepNext: true }));
body.push(caption("表5  关键文件"));
body.push(mkTable([30, 70],
  ["文件", "路径"],
  [
    ["工程文件", "D:\\FPGA_Lab\\exp1\\class1_mux21a\\mux21a2223.qpf"],
    ["VHDL 源码", "D:\\FPGA_Lab\\exp1\\class1_mux21a\\mux21a2223.vhd"],
    ["下载文件 SOF", "D:\\FPGA_Lab\\exp1\\class1_mux21a\\output_files\\mux21a2223.sof"],
    ["仿真波形文件", "D:\\FPGA_Lab\\exp1\\class1_mux21a\\mux21a2223.vwf"],
    ["验收截图（4张+2张）", "D:\\FPGA_Lab\\exp1\\class1_mux21a\\shots\\ 等"],
    ["选做工程", "D:\\FPGA_Lab\\exp1\\optional_81mux_verilog\\mux81a2223.qpf"],
    ["工作区说明", "D:\\FPGA_Lab\\README.md"],
  ]));
body.push(prose([
  r("剩余待办：", { bold: true }),
  r("到实验台完成驱动安装、SOF 下载与功能验收，补拍实验台图。其余流程（含实体名后缀 2223 的全链路改名与重编译）均已完成并验证。"),
]));

// ── document assembly ──
const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: { ascii: "Times New Roman", eastAsia: "SimSun" }, size: 24, color: BODY },
        paragraph: { spacing: { line: 312 } },
      },
      heading1: {
        run: { font: { ascii: "Times New Roman", eastAsia: "SimHei" }, size: 32, bold: true, color: INK },
        paragraph: { spacing: { before: 360, after: 160, line: 312 } },
      },
      heading2: {
        run: { font: { ascii: "Times New Roman", eastAsia: "SimHei" }, size: 28, bold: true, color: INK },
        paragraph: { spacing: { before: 260, after: 120, line: 312 } },
      },
    },
  },
  numbering: {
    config: ["list-bring", "list-step5"].map((ref) => ({
      reference: ref,
      levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } } }],
    })),
  },
  sections: [
    { // Section 1: cover — margin 0, no footer
      properties: {
        page: { size: { width: 11906, height: 16838 }, margin: { top: 0, bottom: 0, left: 0, right: 0 } },
      },
      children: buildCoverR1({
        title: "实验一 上台操作手册",
        subtitle: "第1次课 · 2选1多路选择器 mux21a2223 下载与实验台验收",
        englishLabel: "FPGA BENCH GUIDE",
        metaLines: [
          "工程：D:\\FPGA_Lab\\exp1\\class1_mux21a\\mux21a2223.qpf",
          "器件：Cyclone IV E  EP4CE55F23C8（KX-CDS 实验台 · 电路模式 No.5）",
          "工具：Quartus Prime 25.1std Lite（D:\\QP\\quartus）",
          "依据：2026-实验1-数字系统设计基础实验（第1次课）",
        ],
        footerLeft: "数字系统设计基础实验",
        footerRight: "2026.09",
        palette: PAL,
      }),
    },
    { // Section 2: TOC — Roman
      properties: {
        type: SectionType.NEXT_PAGE,
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, bottom: 1440, left: 1701, right: 1417 },
          pageNumbers: { start: 1, formatType: NumberFormat.UPPER_ROMAN },
        },
      },
      footers: { default: pageNumFooter() },
      children: [
        new Paragraph({
          alignment: AlignmentType.CENTER, spacing: { before: 480, after: 360 },
          children: [new TextRun({ text: "目  录", bold: true, size: 32, font: { eastAsia: "SimHei", ascii: "Times New Roman" }, color: INK })],
        }),
        new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-2" }),
        new Paragraph({
          spacing: { before: 200 },
          children: [new TextRun({
            text: "说明：本目录由域代码生成。打开文档后请在目录上右键选择更新域，以刷新页码。",
            italics: true, size: 18, color: "888888", font: { eastAsia: "SimSun", ascii: "Times New Roman" } })],
        }),
      ],
    },
    { // Section 3: body — Arabic from 1
      properties: {
        type: SectionType.NEXT_PAGE,
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, bottom: 1440, left: 1701, right: 1417 },
          pageNumbers: { start: 1, formatType: NumberFormat.DECIMAL },
        },
      },
      footers: { default: pageNumFooter() },
      children: body,
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("D:/FPGA_Lab/_docs/exp1_class1_bench_guide.docx", buf);
  console.log("OK docx written, figures:", figNo);
});
