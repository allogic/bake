#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#ifdef _WIN32
	#include <windows.h>
#endif // _WIN32

#include "bake_log.h"

#ifdef _WIN32
static uint32_t s_orig_cp;
#endif // _WIN32

void log_prologue(void)
{
#ifdef _WIN32
	s_orig_cp = GetConsoleOutputCP();
	SetConsoleOutputCP(CP_UTF8);
#endif // _WIN32
}
void log_printf(char const* fmt, ...)
{
#ifdef _WIN32
	static char fmt_buffer[LOG_FMT_BUFFER_SIZE];
	va_list args;
	va_start(args, fmt);
	uint32_t fmt_buffer_size = vsnprintf(fmt_buffer, LOG_FMT_BUFFER_SIZE, fmt, args);
	va_end(args);
	WriteConsoleA(GetStdHandle(STD_OUTPUT_HANDLE), fmt_buffer, fmt_buffer_size, 0, 0);
#endif // _WIN32
}
void log_epilogue(void)
{
#ifdef _WIN32
	SetConsoleOutputCP(s_orig_cp);
#endif // _WIN32
}
