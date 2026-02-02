----------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
----------------------------------------------------------------------------

-- Menu callback function that contains our custom menu code
function menuCallback =
(
    -- Retrieve the menu manager, that's currently loading the menu structure, from the callback parameters
    local menuMgr = callbacks.notificationParam()
    -- Append our new test menu to the 3dsMax main menubar
    local mainMenuBar = menuMgr.mainMenuBar
    local mainMenu = mainMenuBar.CreateSubMenu "F8FFB827-741C-4A81-8C89-BBF856DCF56D" "Halo CE Toolkit"
    local importMenu = mainMenu.CreateSubMenu "7F3E8E53-4127-4CBA-B6B1-18371C025102" "Import"
    local separatorA = mainMenu.CreateSeparator("9C5CD48A-13C7-4DF1-96BC-9BC7B34FE710")
    local exportMenu = mainMenu.CreateSubMenu "7CA87C65-7C87-466F-9B19-FD69CEBB07ED" "Export"
    local separatorA = mainMenu.CreateSeparator("CB9A97AC-16FA-4EBF-9BB6-7A7ABA07EA4F")
    local toolsMenu = mainMenu.CreateSubMenu "05038BDC-3AFB-4279-BBFD-655AAACF8B1B" "Tools"
    -- Add our test macro script action item to our menu
    local macroScriptTableId = 647394
    -- Our action identifier for the test action is the with '`' concatinated string of our macro script name and category
    -- Add Import submenu actions
    local importAnimDataId = "ImportAnimationData`Halo CE"
    local importGbxId = "ImportGBX`Halo CE"
    local importCollisionId = "ImportCollisionGeometry`Halo CE"
    local importPhysicsId = "ImportPhysics`Halo CE"
    local importCameraTrackId = "ImportCameraTrack`Halo CE"
    local importJmsId = "ImportJMS`Halo CE"
    importMenu.CreateAction "2B3C4D5E-6F70-8192-A3B4-C5D6E7F8091A" macroScriptTableId importJmsId
    importMenu.CreateAction "EFD414B5-0B36-4092-BE7E-39D785F91B05" macroScriptTableId importAnimDataId
    importMenu.CreateAction "ADB41E81-D249-4539-8F5B-2406E02D8352" macroScriptTableId importGbxId
    importMenu.CreateAction "3C4D1F2E-1C7C-4D2C-8F1E-4F6D1E2B8C9A" macroScriptTableId importCollisionId
    importMenu.CreateAction "5F6A7B8C-9D0E-4F1A-8B2C-3D4E5F6A7B8C" macroScriptTableId importPhysicsId
    importMenu.CreateAction "1A2B3C4D-5E6F-7081-92A3-B4C5D6E7F809" macroScriptTableId importCameraTrackId
    -- Add Export submenu actions
    local exportJmsId = "ExportJMS`Halo CE"
    local exportJmaId = "ExportJointedModelAnimation`Halo CE"
    local exportCameraTrackId = "ExportCameraTrack`Halo CE"
    exportMenu.CreateAction "9A8B7C6D-5E4F-3A2B-1C0D-EF1A2B3C4D5E" macroScriptTableId exportJmsId
    exportMenu.CreateAction "6F5E4D3C-2B1A-0D9C-8B7A-6E5F4D3C2B1A" macroScriptTableId exportJmaId
    exportMenu.CreateAction "0A1B2C3D-4E5F-6071-8293-A4B5C6D7E8F9" macroScriptTableId exportCameraTrackId
    -- Add Tools submenu actions
    local sphereToHaloHelperId = "SphereToHaloMarkerHelper`Halo CE"
    local jmsFormatterId = "JmsFormatter`Halo CE"
    toolsMenu.CreateAction "05C59238-B2A9-47D1-BA72-A781492FEDB4" macroScriptTableId sphereToHaloHelperId
    toolsMenu.CreateAction "D4E5F6A7-B8C9-4D1E-2B3C-4F5A6B7C8D9E" macroScriptTableId jmsFormatterId
)
-- Register our menu creation callback so that it can be executed whenever the menu structure is evaluated.
callbacks.removeScripts id:#haloceToolkitMenu
callbacks.addScript #cuiRegisterMenus menuCallback id:#haloceToolkitMenu

