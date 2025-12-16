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

fn createHaloCEToolkitMenu =
(
    try (
        local mm = menuMan
        local mainBar = mm.getMainMenuBar()

        -- Remove existing Halo CE menu if it exists
        local existingMenu = undefined
        local itemCount = mainBar.numItems()
        for i = 1 to itemCount do (
            local menuItem = mainBar.getItem i
            if (menuItem != undefined and menuItem.getTitle() == "Halo CE Toolkit") do (
                existingMenu = menuItem
                exit
            )
        )

        if existingMenu != undefined do (
            mainBar.removeItem existingMenu
            print "Removed existing Halo CE Toolkit menu"
        )

        -- Create the main Halo CE Toolkit menu
        local haloMenu = mm.createMenu "Halo CE Toolkit"
        -- Create Import submenu
        local importMenu = mm.createMenu "Import"
        -- Create Export submenu
        local exportMenu = mm.createMenu "Export"
        -- Create Tools submenu
        local toolsMenu = mm.createMenu "Tools"

        -- Function to add macro to menu
        fn addMacroToMenu theMenu macroCategory macroName menuManager displayName: =
        (
            local menuDisplayName = if displayName != undefined then displayName else macroName

            try (
                local actionItem = menuManager.createActionItem macroName macroCategory
                if actionItem != undefined then (
                    theMenu.addItem actionItem -1
                    print ("Successfully added: " + menuDisplayName)
                    return true
                ) else (
                    print ("Failed to create action item for macro: " + macroName)
                    return false
                )
            ) catch (
                print ("Error adding macro '" + macroName + "' to menu: " + getCurrentException())
                return false
            )
        )

        -- Add Import macros
        print "Adding Import macros..."
        addMacroToMenu importMenu "Halo CE" "ImportAnimationData" mm displayName:"Animation Data"
        addMacroToMenu importMenu "Halo CE" "ImportGBX" mm displayName:"GBX Model"
        addMacroToMenu importMenu "Halo CE" "ImportCollisionGeometry" mm displayName:"Collision Geometry"
        addMacroToMenu importMenu "Halo CE" "ImportPhysics" mm displayName:"Physics"
        addMacroToMenu importMenu "Halo CE" "ImportCameraTrack" mm displayName:"Camera Track"

        -- Add Export macros
        print "Adding Export macros..."
        addMacroToMenu exportMenu "Halo CE" "ExportJMS" mm displayName:"JMS Model"
        addMacroToMenu exportMenu "Halo CE" "ExportJointedModelAnimation" mm displayName:"JMA Animation"
        addMacroToMenu exportMenu "Halo CE" "ExportCameraTrack" mm displayName:"Camera Track"

        -- Add Tools macros
        print "Adding Tools macros..."
        addMacroToMenu toolsMenu "Halo CE" "SphereToHaloMarkerHelper" mm displayName:"Convert Spheres to Halo Helper Markers"


        -- Add submenus to main menu
        local importSubMenu = mm.createSubMenuItem "Import" importMenu
        local exportSubMenu = mm.createSubMenuItem "Export" exportMenu
        local toolsSubMenu = mm.createSubMenuItem "Tools" toolsMenu

        haloMenu.addItem importSubMenu -1

        -- Add separator between Import and Export
        local separator = mm.createSeparatorItem()
        haloMenu.addItem separator -1

        haloMenu.addItem exportSubMenu -1
        
        haloMenu.addItem separator -1
        
        haloMenu.addItem toolsSubMenu -1
        
        -- Add the main menu to the menu bar
        local mainMenuItem = mm.createSubMenuItem "Halo CE Toolkit" haloMenu
        mainBar.addItem mainMenuItem -1

        -- Update the menu bar to show changes
        mm.updateMenuBar()

        print "Halo CE Toolkit menu created successfully!"
        return true

    ) catch (
        print ("Failed to create Halo CE Toolkit menu: " + getCurrentException())
        return false
    )
)

-- Execute the function to create the menu
createHaloCEToolkitMenu()
