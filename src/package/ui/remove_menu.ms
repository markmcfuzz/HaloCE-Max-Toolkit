-- Create Halo CE Toolkit Menu
-- Simple script to remove the Halo CE Toolkit menu in 3ds Max

fn removeHaloCEToolkitMenu = 
(
    try (
        local mm = menuMan
        local mainBar = mm.getMainMenuBar()
        local menuRemoved = false
        
        -- Remove from menu bar
        local itemCount = mainBar.numItems()
        for i = 1 to itemCount do (
            local menuItem = mainBar.getItem i
            if (menuItem != undefined and menuItem.getTitle() == "Halo CE Toolkit") do (
                mainBar.removeItem menuItem
                menuRemoved = true
                print "Menu removed from menu bar"
                exit
            )
        )
        
        -- Remove menu definition from system
        try (
            local menuObj = mm.findMenu "Halo CE Toolkit"
            if menuObj != undefined then (
                mm.unregisterMenu menuObj
                print "Menu definition removed from system"
            )
        ) catch ()
        
        -- Clean up submenus
        local submenuNames = #("Import", "Export", "Tools")
        for submenuName in submenuNames do (
            try (
                local submenuObj = mm.findMenu submenuName
                if submenuObj != undefined then (
                    mm.unregisterMenu submenuObj
                    print ("Submenu " + submenuName + " removed from system")
                )
            ) catch (
                print ("Could not remove submenu: " + submenuName)
            )
        )
        
        -- Update menu system
        mm.updateMenuBar()
        
        if menuRemoved then (
            print "Halo CE Toolkit menu completely removed!"
        )
        
    ) catch (
        print ("Failed to remove Halo CE Toolkit menu: " + getCurrentException())
    )
)

-- Execute the function
removeHaloCEToolkitMenu()