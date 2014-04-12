
local linenoise_example = c.program{'linenoise_example', src='linenoise example', odir='bin'}
local linenoise_utf8_example = c.program{'linenoise_utf8_example', src='linenoise example utf8', odir='bin'}
local linenoise_cpp_example = cpp.program{'linenoise_cpp_example', src='linenoise example', static=true, ext='.c', odir='bin/cpp'}

default {linenoise_example, linenoise_cpp_example, linenoise_utf8_example}