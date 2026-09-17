# Local-AI-PC-Agent

Local-AI-PC-Agent 是一个基于 Windows PowerShell 开发的 Windows 电脑性能检测、卡顿分析和辅助优化工具。

项目目标是：

**自动检测电脑配置和运行状态 → 分析可能造成卡顿的原因 → 生成优化方案 → 由用户确认后执行安全优化 → 再次检测并验证优化结果。**

---

## 1. 系统要求

- Windows 10 / Windows 11
- Windows PowerShell 5.1 或更高版本
- 部分系统优化操作可能需要相应的 Windows 权限

---

## 2. 快速开始

打开 Windows PowerShell。

进入项目目录：

```powershell
cd C:\AI\Local-AI-PC-Agent
```

启动 Local-AI-PC-Agent：

```powershell
.\run_agent.ps1
```

普通用户主要使用这一条命令即可。

---

## 3. 工作流程

Local-AI-PC-Agent 的主要工作流程：

```text
Windows
   ↓
系统信息采集
   ↓
性能数据采集
   ↓
健康状态分析
   ↓
卡顿原因分析
   ↓
生成优化方案
   ↓
显示优化选项
   ↓
用户确认
   ↓
执行选定优化
   ↓
重新检测
   ↓
生成最终报告
```

完整流程包括：

1. 采集 Windows 系统信息
2. 采集当前性能信息
3. 分析系统健康状态
4. 分析可能造成电脑卡顿的原因
5. 生成结构化优化方案
6. 生成可读健康报告
7. 向用户显示优化选项
8. 只执行用户确认的系统修改操作
9. 优化后重新检测
10. 输出最终结果

---

## 4. 当前检测能力

Local-AI-PC-Agent 当前可以检测：

### 系统信息

- 计算机名称
- Windows 版本
- Windows Build
- 系统架构
- 系统启动时间
- 系统运行时长

### CPU

- CPU 型号
- CPU 制造商
- 物理核心数量
- 逻辑处理器数量
- 当前频率
- 最大频率
- 当前 CPU 负载

### 内存

- 总物理内存
- 已使用内存
- 可用内存
- 当前内存使用率

### 磁盘

- 逻辑磁盘
- 总容量
- 已使用空间
- 剩余空间
- 磁盘使用率
- 物理磁盘信息
- 磁盘介质类型
- 磁盘健康状态

### GPU

- GPU 型号
- GPU 驱动版本
- 显存信息
- 当前视频模式

### 网络

- 活动网卡
- IPv4 地址
- 默认网关
- 网卡描述

### 进程

- 当前进程数量
- 高内存进程
- CPU 使用相关进程
- 进程 PID
- 进程内存占用

### Windows 性能相关信息

- 启动项
- TEMP 临时文件
- TEMP 文件数量
- TEMP 占用空间
- Windows 页面文件
- 当前电源计划
- 系统运行时间

---

## 5. 健康状态与性能状态

Local-AI-PC-Agent 将：

**系统健康状态**

和：

**性能优化状态**

分开判断。

因此可能出现：

```text
Health: Healthy
Performance: OptimizationAvailable
```

这表示：

电脑没有检测到明显的系统健康故障，但是存在可能影响性能、值得进一步优化的因素。

当前健康状态包括：

```text
Healthy
Warning
Critical
```

性能状态包括：

```text
Good
OptimizationAvailable
PerformanceIssue
```

---

## 6. 当前卡顿原因分析

当前版本可以分析的性能因素包括：

### Memory Pressure

内存压力。

例如：

- 当前内存使用率较高
- 多个大型应用同时运行
- 可用物理内存不足

### High Process Count

后台进程数量较多。

大量进程可能增加：

- 内存占用
- CPU 调度负担
- 后台活动
- 系统响应延迟

### Many Startup Programs

Windows 启动项较多。

启动程序过多可能影响：

- Windows 登录速度
- 开机后的响应速度
- 后台内存使用
- 后台进程数量

### TEMP Accumulation

TEMP 临时文件积累。

程序会检测：

- TEMP 文件数量
- TEMP 总容量
- 可清理的旧临时文件

### CPU Pressure

CPU 当前负载较高时，会进一步分析 CPU 相关进程。

### Power Plan

检测 Windows 当前电源计划，并将其作为性能分析参考因素。

---

## 7. 优化方案生成器

优化计划由：

```text
powershell\generate_optimization_plan.ps1
```

生成。

生成结果：

```text
reports\optimization_plan.json
```

优化计划包含：

- 问题类型
- 可能原因
- 实际检测证据
- 严重程度
- 判断可信度
- 推荐优化动作
- 风险等级
- 是否需要管理员权限
- 是否允许自动执行
- 是否需要用户确认

---

## 8. 安全模型

Local-AI-PC-Agent 将操作划分为不同安全等级。

### SAFE

只读检测或低风险分析操作。

例如：

- 查看高内存进程
- 查看后台进程
- 查看启动项
- 扫描 TEMP 文件
- 检查 CPU
- 检查电源计划
- 检查磁盘状态

SAFE 操作不会直接修改 Windows。

### CONFIRM

会改变系统状态的操作。

必须经过用户明确确认。

例如：

- 清理符合条件的 TEMP 文件
- 禁用用户选择的启动项
- 关闭用户选择的应用程序
- 修改某些系统性能设置

程序必须先显示准备执行的操作，再要求用户确认。

### PROTECTED / BLOCKED

Local-AI-PC-Agent 不应为了普通性能优化自动执行以下操作：

- 禁用 Windows 安全软件
- 随意关闭 Windows Defender
- 停止关键 Windows 服务
- 删除任意用户文件
- 删除未知系统文件
- 随意修改注册表
- 自动结束关键 Windows 进程
- 未经用户确认关闭应用
- 未经用户确认禁用启动项

---

## 9. TEMP 安全清理

TEMP 优化模块：

```text
powershell\optimize_temp.ps1
```

当前策略：

1. 只扫描当前用户 TEMP 目录
2. 只处理普通文件
3. 默认选择超过一定时间未修改的旧文件
4. 计算候选文件数量
5. 计算预计释放空间
6. 显示给用户
7. 要求 Y/N 确认
8. 用户确认后逐个删除
9. 无法删除的占用文件自动跳过
10. 输出实际释放空间

不会直接清空整个磁盘或任意用户目录。

---

## 10. 启动项优化

启动项优化模块：

```text
powershell\optimize_startup.ps1
```

功能：

1. 扫描 Windows 启动项
2. 保护已知系统或基础组件
3. 显示可选启动项
4. 用户选择具体启动项
5. 显示启动命令和位置
6. 二次确认
7. 修改前创建备份
8. 禁用选中的启动项

禁用启动项：

**不会卸载应用程序。**

也不会自动结束当前已经运行的程序。

---

## 11. 启动项恢复

恢复模块：

```text
powershell\restore_startup.ps1
```

启动项修改前会生成备份：

```text
reports\startup_backup.json
```

恢复模块可以读取备份，并将最近一次备份的启动项重新写回原位置。

项目设计原则：

```text
修改前备份
   ↓
执行修改
   ↓
需要时恢复
```

---

## 12. 高内存应用优化

高内存应用模块：

```text
powershell\optimize_process.ps1
```

工作方式：

1. 扫描高内存进程
2. 排除部分关键 Windows 进程
3. 显示候选应用
4. 显示 PID
5. 显示当前内存占用
6. 用户选择具体应用
7. 提示可能存在未保存数据
8. 要求 Y/N 确认
9. 用户确认后才结束该进程

Local-AI-PC-Agent 不会因为发现某个程序内存较高就自动结束它。

---

## 13. 优化后验证

执行优化操作后，主程序会重新进行：

```text
系统检测
   ↓
性能检测
   ↓
健康分析
   ↓
卡顿原因分析
   ↓
优化计划生成
   ↓
报告生成
```

这样可以重新判断：

- CPU 是否变化
- 内存是否变化
- 进程数量是否变化
- TEMP 是否减少
- 启动项是否变化
- 剩余性能问题有哪些

---

## 14. 主程序

最终用户主要运行：

```powershell
.\run_agent.ps1
```

主菜单包括：

```text
[1] TEMP cleanup

[2] Startup optimization

[3] High-memory application optimization

[4] Restore startup entry

[5] Re-run diagnostics only

[0] Exit
```

---

## 15. 项目结构

```text
Local-AI-PC-Agent
│
├── run_agent.ps1
├── run_health_check.ps1
├── README.md
├── .gitignore
│
├── powershell
│   ├── system_info.ps1
│   ├── performance_check.ps1
│   ├── analyze_health.ps1
│   ├── generate_report.ps1
│   ├── generate_optimization_plan.ps1
│   ├── execute_optimization_plan.ps1
│   ├── optimize_temp.ps1
│   ├── optimize_startup.ps1
│   ├── restore_startup.ps1
│   └── optimize_process.ps1
│
└── reports
```

---

## 16. 运行报告

运行过程中会在：

```text
reports\
```

生成机器相关报告。

例如：

```text
system_info.json
performance_report.json
health_report.json
health_report.txt
optimization_plan.json
execution_result.json
startup_backup.json
```

这些文件可能包含：

- 计算机名称
- 硬件信息
- IP 信息
- 进程信息
- 启动项信息

因此 `reports` 中的运行报告默认不应该提交到公共 GitHub 仓库。

项目通过 `.gitignore` 排除运行报告。

---

## 17. Git 开发流程

推荐修改代码以后按照以下流程操作：

```text
修改代码
   ↓
运行测试
   ↓
git status
   ↓
git diff
   ↓
git add .
   ↓
git commit
   ↓
git push
```

查看当前状态：

```powershell
git status
```

查看具体代码差异：

```powershell
git diff
```

加入暂存区：

```powershell
git add .
```

创建提交：

```powershell
git commit -m "your commit message"
```

上传 GitHub：

```powershell
git push
```

---

## 18. 当前版本

当前稳定版本：

```text
v1.0.0
```

---

## 19. 当前设计原则

Local-AI-PC-Agent 遵循以下原则：

```text
Detect First
     ↓
Explain Second
     ↓
Plan Third
     ↓
Ask Permission
     ↓
Execute
     ↓
Verify
```

即：

**先检测，再解释，再规划；涉及系统修改时先获得用户确认；执行后重新检测验证。**

---

## 20. Important

系统优化存在环境差异。

在执行任何会改变 Windows 状态的操作前，应查看程序显示的：

- 操作对象
- 风险等级
- 当前状态
- 预计影响

对于重要工作环境，应确保重要数据已经保存。

---

## License

No license has been specified for this project yet.