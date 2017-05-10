#pragma once

#include "perinclude.h"
#include "Singleton.h"

#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
class WindowsConsole : public TSingleton<WindowsConsole>
{
public:
	WindowsConsole();
	
	~WindowsConsole();

	void read_console_input();

	void write_console(WORD clr, const char* str);

protected:
	// 隐藏光标 
	void hide_cursor();

	// 显示光标  
	void show_cursor();

	void key_event_proc(DWORD i);
	void resize_event_proc(DWORD i);

	void clear_cur_line();

private:
	HANDLE								h_out_;
	HANDLE								h_in_;
	bool								show_cur_;
	//UINT								old_code_page_;
	DWORD								save_old_mode_;

	CONSOLE_SCREEN_BUFFER_INFO			info_;
	INPUT_RECORD						ir_in_buf_[128];
	char*								line_buf_;
	SHORT								line_buf_size_;
};
#endif
