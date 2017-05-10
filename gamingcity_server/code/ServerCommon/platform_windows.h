#pragma once

// linux todo
#ifdef PLATFORM_WINDOWS
/// 获得CPU的核数  
int get_processor_number();

/// 得到进程cpu占用
int get_cpu_usage(int pid);

/// 得到当前内存使用信息
void get_memory_info(int& workingSetSize, int& peakWorkingSetSize, int& pagefileUsage, int& peakPagefileUsage);
#endif
