# JasperGold C2RTL 演示 — 8-Tap FIR 滤波器

一个完整、可移植的 C2RTL 形式验证环境，演示
**C/C++ 到 RTL 的时序等价性检查**（Sequential Equivalence Checking）。

## 目录结构

```
formal_c2rtl/
├── c_model/                  # C/C++ 参考模型（算法规格）
│   ├── fir_filter.h          #   头文件
│   └── fir_filter.cpp        #   实现
├── rtl/                      # RTL 实现（SystemVerilog）
│   └── fir_filter.sv         #   8-tap FIR，4 级流水线
├── cfg/                      # 配置文件
│   ├── dut.f                 #   RTL 文件列表
│   └── c2rtl_setup.tcl       #   C2RTL App 配置脚本
├── run/                      # 运行目录（JG 输出存放于此）
└── README.md
```

## 设计概览

| 组件 | 语言 | 说明 |
|------|------|------|
| 参考模型 | C++ | `fir_filter(input, coeff[8], state[8])` — 纯函数，零延迟 |
| RTL | SystemVerilog | 4 级流水线：移位 → 乘法 → 求和 → 量化 |
| 流水线延迟 | — | `data_in` 到 `data_out` 共 4 个时钟周期 |

### 流水线各级

```
第 1 级 (S1)：移位寄存器 — 锁存输入，移动延迟线
第 2 级 (S2)：乘法        — 8 路并行 16×16→32 带符号乘法
第 3 级 (S3)：求和        — 加法树（8→4→2→1，37-bit）
第 4 级 (S4)：量化        — 算术右移 16 位 → 输出
```

## 快速开始

### 前置条件

- **Cadence JasperGold**（需支持 C2RTL App）
- `jg` 命令位于 `$PATH` 中

### 运行 C2RTL 等价性检查

```bash
cd formal_c2rtl
jg -batch -tcl cfg/c2rtl_setup.tcl
```

脚本执行流程：
1. 读取 C 模型 → `sec_read_c`
2. 读取并综合 RTL → `analyze` + `elaborate`
3. 建立 C 变量到 RTL 信号的映射 → `sec_map`
4. 证明等价性 → `check_sec -app c2rtl`

### 期望结果

```
PROVED: fir_filter — C 模型与 RTL 时序等价。
```

若出现不匹配，可打开 JasperGold Visualize 对比 C 和 RTL 波形：

```bash
jg -tcl cfg/c2rtl_setup.tcl
# 在 JG GUI 中：Visualize → violation trace
```

## 信号映射关系

| C 变量 | RTL 信号 | 流水线延迟 |
|--------|----------|-----------|
| `input` | `data_in` | 0 |
| `coeff[i]` | `coeff[i]` | 0 |
| `state[i]` | `fir_filter.state_reg[i]` | 0 |
| `fir_filter()` 返回值 | `data_out` | **4** |

输出映射上的 `-pipeline 4` 告知工具：RTL 的 `data_out` 比 C 函数的返回值晚 4 个时钟周期。

## 跨机器移植

本项目**完全自包含**，拷贝到另一台机器即可运行：

```bash
# 1. 复制整个 formal_c2rtl/ 目录
scp -r formal_c2rtl/ user@remote:/path/to/

# 2. 运行
cd /path/to/formal_c2rtl
jg -batch -tcl cfg/c2rtl_setup.tcl

# 或者从 GitHub 克隆
git clone https://github.com/a57135713/formal_c2rtl.git
cd formal_c2rtl
jg -batch -tcl cfg/c2rtl_setup.tcl
```

所有路径均为相对于工程根目录的相对路径，无绝对路径，无机器相关配置。
