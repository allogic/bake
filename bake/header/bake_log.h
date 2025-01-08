#ifndef BAKE_LOG_H
#define BAKE_LOG_H

#include "bake_config.h"

extern void log_prologue(void);
extern void log_printf(char const* fmt, ...);
extern void log_epilogue(void);

#endif // BAKE_LOG_H
