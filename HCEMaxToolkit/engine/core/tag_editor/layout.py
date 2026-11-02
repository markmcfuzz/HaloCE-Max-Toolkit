"""Tag group layouts (fields in tag order) from lua\\bridge\\tag_ui.lua, loaded once per group."""
import json
import os
import subprocess
import tempfile

ENGINE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUAJIT = os.path.join(ENGINE_DIR, "runtime", "bin", "luajit.exe")
RUN_LUA = os.path.join(ENGINE_DIR, "lua", "run.lua")

_layouts = {}


def group_layout(group):
    """{group, title, sections: [{title, fields}]}; raises RuntimeError when Lua fails."""
    if group not in _layouts:
        out_path = os.path.join(tempfile.gettempdir(), "hce_layout_%s.json" % group)
        result = subprocess.run([LUAJIT, RUN_LUA, "bridge.tag_ui", "layout", group, out_path],
                                capture_output=True, text=True,
                                creationflags=subprocess.CREATE_NO_WINDOW)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "Lua layout failed")
        with open(out_path, encoding="utf-8") as f:
            _layouts[group] = json.load(f)
        os.remove(out_path)
    return _layouts[group]
