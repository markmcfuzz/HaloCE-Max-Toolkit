------------------------------------------------------------------------------
--	Copyright (C) 2026 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------


-- Create Physics Tag: opens the Qt dialog (core\tag_editor\new_physics.py), which lists the templates
-- of lua\generators\templates by category and creates their physics and .vehicle
-- (builders\tag\physics\new_from_template.ms, loaded at startup).

scriptName = getFilenameFile (getThisScriptFilename())
logger.loadConfig callerScriptName:scriptName

-- Python opens from here (a macro), never from scene code
try ((tagEditorModule()).show_new_physics())
catch
(
	logger.error "Create Physics Tag failed: {}" args:#(getCurrentException())
	messageBox "Could not open Create Physics Tag! See the log for details." title:"Create Physics Tag"
)
