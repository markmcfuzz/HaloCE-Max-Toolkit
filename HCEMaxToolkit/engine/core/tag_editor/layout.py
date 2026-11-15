"""Tag group layouts (fields in tag order) from lua\\bridge\\tag_ui.lua, loaded once per group."""
import json
import os
import subprocess
import tempfile

ENGINE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUAJIT = os.path.join(ENGINE_DIR, "runtime", "bin", "luajit.exe")
RUN_LUA = os.path.join(ENGINE_DIR, "lua", "run.lua")

_layouts = {}


def run_lua_json(module, function, *args):
    """Runs a Lua function whose last argument is the JSON file it writes; returns its
    contents. Raises RuntimeError when Lua fails."""
    out_path = os.path.join(tempfile.gettempdir(), "hce_%s_%s.json" % (module.replace(".", "_"), function))
    result = subprocess.run([LUAJIT, RUN_LUA, module, function] + list(args) + [out_path],
                            capture_output=True, text=True,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Lua %s.%s failed" % (module, function))
    with open(out_path, encoding="utf-8") as f:
        data = json.load(f)
    os.remove(out_path)
    return data


def group_layout(group):
    """{group, title, sections: [{title, fields}]}; raises RuntimeError when Lua fails."""
    if group not in _layouts:
        _layouts[group] = run_lua_json("bridge.tag_ui", "layout", group)
    return _layouts[group]
