# flex --outfile="./src/bake_lexr.c" --yylineno --nounistd "./bake_lexr.l"
# bison --output="./src/bake_pasr.c" --header="./header/bake_pasr.h" --locations "./bake_pasr.y"

$SOURCES = @()
$SOURCES += ".\src\bake_ctx.c"
$SOURCES += ".\src\bake_expr.c"
$SOURCES += ".\src\bake_lexr.c"
$SOURCES += ".\src\bake_log.c"
$SOURCES += ".\src\bake_pasr.c"
$SOURCES += "..\core\core\src\core_heap.c"
$SOURCES += "..\core\core\src\core_map.c"
$SOURCES += "..\core\core\src\core_set.c"
$SOURCES += "..\core\core\src\core_str.c"
$SOURCES += "..\core\core\src\core_vec.c"

$OBJECTS = $SOURCES -replace "\.c$", ".obj"

for ($i = 0; $i -lt $SOURCES.Count; $i++)
{
	clang.exe `
		-c $SOURCES[$i] `
		-o $OBJECTS[$i] `
		-Og `
		-g `
		-std=c99 `
		-Wall `
		-pedantic `
		-Wno-comment `
		-Wno-implicit-function-declaration `
		-Wno-unused-function `
		-Wno-long-long `
		-Wno-declaration-after-statement `
		-Wno-deprecated-declarations `
		-Wno-variadic-macros `
		-Wno-c99-extensions `
		-Wno-c23-extensions `
		-D_DEBUG `
		-D_HEAP_TRACE `
		-I ".\" `
		-I ".\header" `
		-I "..\core\core\header" `
		--target=x86_64-pc-windows-msvc
}

# TODO
# -O3
# -march=native
# -flto
# -fomit-frame-pointer

lld-link.exe `
	@OBJECTS `
	/out:"bake.exe" `
	/machine:x64 `
	/subsystem:console `
	"msvcrt.lib"
