local join = path.join
local projects = {}

c.defaults { odir = 'bin', static = true }

function program (args)
	local p = c.program(args)
	projects[#projects+1] = p
	return p
end

local function make_sources(args)
	-- variable declarations
	local dir, result = args.directory, {}
	-- join the source files
	for i = 1, #args do
		local file = join(dir, args[i])
		table.insert(result, file)
	end
	-- return result
	return result
end

--------------------------------------------------
--------------------------------------------------

---
-- Zlib
---
local zlib = {}
zlib.DIR = 'zlib-1.2.8'
zlib.SOURCES = make_sources {
	directory = zlib.DIR;
	'adler32',  'compress', 'crc32',  'deflate',  'gzclose', 'gzlib',  'gzread', 
    'gzwrite',  'infback',  'inffast',  'inflate',  'inftrees', 'trees',  'uncompr', 'zutil'
}
zlib.INCLUDE = zlib.DIR

zlib.lib = c.library{'z', src=zlib.SOURCES, incdir=zlib.INCLUDE}
zlib.def = file.group{src=join(zlib.DIR, 'win32', 'zlib.def'), odir='.'}
zlib.dll = c.shared {'zlib', src=zlib.SOURCES, incdir=zlib.INCLUDE, compile_deps=zlib.def}

---
-- PNG
---
local png = {}
png.DIR = 'lpng1616'
png.SOURCES = make_sources {
	directory = png.DIR;
	'png', 'pngerror', 'pngget', 'pngmem', 'pngpread', 'pngread', 'pngrio', 'pngrtran', 'pngrutil', 'pngset',
	'pngtrans', 'pngwio', 'pngwrite', 'pngwtran', 'pngwutil'
}
png.INCLUDE = {png.DIR, zlib.DIR}

png.lib = c.library{'png', src=png.SOURCES, incdir=png.INCLUDE}
png.def = file.group{src=join(png.DIR, 'scripts', 'symbols.def'), odir='.'}
png.dll = c.shared {'libpng', src=png.SOURCES, incdir=png.INCLUDE, zlib.dll, compile_deps=png.def}

png.test = program {'pngtest', src=join(png.DIR, 'pngtest'), incdir=png.INCLUDE, png.dll}


---
-- HARU PDF
---
local harupdf = {}
harupdf.DIR = 'libharu-libharu-e190f3e'
harupdf.SOURCES = make_sources {
	directory = join(harupdf.DIR, 'src');
	'hpdf_utils', 'hpdf_error', 'hpdf_mmgr', 'hpdf_list', 'hpdf_streams', 'hpdf_objects', 'hpdf_null', 'hpdf_boolean',
	'hpdf_number', 'hpdf_real', 'hpdf_name', 'hpdf_array', 'hpdf_dict', 'hpdf_xref', 'hpdf_encoder', 'hpdf_string',
	'hpdf_binary', 'hpdf_encrypt', 'hpdf_encryptdict', 'hpdf_fontdef', 'hpdf_fontdef_tt', 'hpdf_fontdef_type1', 'hpdf_fontdef_base14',
	'hpdf_fontdef_cid', 'hpdf_font', 'hpdf_font_type1', 'hpdf_font_tt', 'hpdf_font_cid', 'hpdf_doc', 'hpdf_info', 'hpdf_catalog',
	'hpdf_page_label', 'hpdf_gstate', 'hpdf_pages', 'hpdf_page_operator', 'hpdf_destination', 'hpdf_annotation', 'hpdf_outline',
	'hpdf_image', 'hpdf_encoder_jp', 'hpdf_encoder_kr', 'hpdf_encoder_cns', 'hpdf_encoder_cnt', 'hpdf_fontdef_jp', 'hpdf_fontdef_kr',
	'hpdf_fontdef_cns', 'hpdf_fontdef_cnt', 'hpdf_image_png', 'hpdf_image_ccitt', 'hpdf_doc_png', 'hpdf_ext_gstate', 'hpdf_3dmeasure',
	'hpdf_exdata', 'hpdf_namedict', 'hpdf_u3d', }
harupdf.INCLUDE = {join(harupdf.DIR, 'include'), join(harupdf.DIR, 'win32', 'include'), png.DIR, zlib.DIR}

harupdf.res = wresource.group {src=join(harupdf.DIR, 'win32', 'mingw', 'libhpdf_mingw'), odir='bin'}
harupdf.SOURCES[#harupdf.SOURCES+1] = harupdf.res

harupdf.lib = c.library{'hpdf', src=harupdf.SOURCES, incdir=harupdf.INCLUDE}
harupdf.dll = c.shared {'libhpdf', src=harupdf.SOURCES, incdir=harupdf.INCLUDE, png.dll, zlib.dll}

local harupdf_demo = join(harupdf.DIR, 'demo')
harupdf.line_demo = program {'line_demo', src=join(harupdf_demo, 'line_demo'), incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}
-- harupdf.grid_sheet = program {'grid_sheet', src=join(harupdf_demo, 'grid_sheet'), incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}, defines='STAND_ALONE'}
harupdf.image_demo = program {'image_demo', src=join(harupdf_demo, 'image_demo'), incdir=harupdf.INCLUDE, deps = harupdf.dll}
harupdf.jpeg_demo = program {'jpeg_demo', src=join(harupdf_demo, 'jpeg_demo'), incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}
harupdf.font_demo = program {'font_demo', src=join(harupdf_demo, 'font_demo'), incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}
harupdf.encryption = program {'encryption', src=join(harupdf_demo, 'encryption'), incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}
harupdf.text_demo = program {'text_demo', src={join(harupdf_demo, 'text_demo'), join(harupdf_demo, 'grid_sheet')}, incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}
harupdf.arc_demo = program {'arc_demo', src={join(harupdf_demo, 'arc_demo'), join(harupdf_demo, 'grid_sheet')}, incdir=harupdf.INCLUDE, deps = {harupdf.lib, png.lib, zlib.lib}}



--------------------------------------------------
--------------------------------------------------

default(projects)