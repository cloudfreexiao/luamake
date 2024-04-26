local globals = require "globals"

local function format_path(path)
    if path:match " " then
        return '"'..path..'"'
    end
    return path
end

local gcc = {
    flags = {
    },
    ldflags = {
    },
    optimize = {
        off      = "",
        size     = "-Os",
        speed    = "-O2",
        maxspeed = "-O3",
    },
    warnings = {
        off    = "-w",
        on     = "-Wall",
        all    = "-Wall -Wextra",
        error  = "-Wall -Werror",
        strict = "-Wall -Wextra -Werror",
    },
    cxx = {
        [""] = "",
        ["c++11"] = "-std=c++11",
        ["c++14"] = "-std=c++14",
        ["c++17"] = "-std=c++17",
        ["c++20"] = "-std=c++20",
        ["c++23"] = "-std=c++23",
        ["c++2a"] = "-std=c++2a",
        ["c++2b"] = "-std=c++2b",
        ["c++latest"] = "-std=c++2b",
    },
    c = {
        [""] = "",
        ["c89"] = "",
        ["c99"] = "-std=c99",
        ["c11"] = "-std=c11",
        ["c17"] = "-std=c17",
        ["c23"] = "-std=c23",
        ["c2x"] = "-std=c2x",
        ["clatest"] = "-std=c2x",
    },
    define = function (macro)
        if macro == "" then
            return
        end
        return "-D"..macro
    end,
    undef = function (macro)
        return "-U"..macro
    end,
    includedir = function (dir)
        return "-I"..format_path(dir)
    end,
    sysincludedir = function (dir)
        return "-isystem "..format_path(dir)
    end,
    link = function (lib)
        return "-l"..lib
    end,
    linkdir = function (dir)
        return "-L"..format_path(dir)
    end,
}

function gcc.rule_asm(w, name, flags)
    w:rule("asm_"..name, ([[$cc -MMD -MT $out -MF $out.d %s -o $out -c $in]])
        :format(flags),
        {
            description = "Compile ASM $out",
            deps = "gcc",
            depfile = "$out.d"
        })
end

function gcc.rule_c(w, name, flags, cflags)
    w:rule("c_"..name, ([[$cc -MMD -MT $out -MF $out.d %s %s -o $out -c $in]])
        :format(cflags, flags),
        {
            description = "Compile C   $out",
            deps = "gcc",
            depfile = "$out.d"
        })
end

function gcc.rule_cxx(w, name, flags, cxxflags)
    w:rule("cxx_"..name, ([[$cc -MMD -MT $out -MF $out.d %s %s -o $out -c $in]])
        :format(cxxflags, flags),
        {
            description = "Compile C++ $out",
            deps = "gcc",
            depfile = "$out.d"
        })
end

function gcc.rule_lib(w, name)
    if globals.os == "windows" and globals.hostshell == "sh" then
        -- mingw
        w:rule("link_"..name, [[sh -c "rm -f $out && $ar rcs $out @$out.rsp"]],
            {
                description = "Link    Lib $out",
                rspfile = "$out.rsp",
                rspfile_content = "$in",
            })
    elseif globals.hostshell == "cmd" then
        w:rule("link_"..name, [[cmd /c $ar rcs $out @$out.rsp]],
            {
                description = "Link    Lib $out",
                rspfile = "$out.rsp",
                rspfile_content = "$in_newline",
            })
    else
        w:rule("link_"..name, [[rm -f $out && $ar rcs $out $in]],
            {
                description = "Link    Lib $out"
            })
    end
end

return gcc
