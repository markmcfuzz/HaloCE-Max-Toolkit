# HALO CE MAX TOOLKIT

A toolkit for Autodesk 3ds Max that allows you to **import and export source and tag files** for Halo Custom Edition.

This toolkit is based on [BlueStreak](https://github.com/Sledmine/bluestreak/tree/main) but introduces several major improvements and quality-of-life features.


## Features  
- Import Halo CE **GBX models**, **Camera Tracks** and **Animation Data** directly into 3ds Max.  
- Export **JMS**, **Animation Data** and **Camera Track** files compatible with Halo CE.
- Integrated directly into 3ds Max menus for easy access (no need to manually run scripts).  
- Additional validations and error handling compared to the original BlueStreak scripts.  
- Adds a new **Halo CE Toolkit** menu section inside 3ds Max for quick access to import/export tools.
- Uninstall the Toolkit with installer dialog.
---

## Installation  

1. Download the latest **`HaloCE_Max_Toolkit.mzp`** from the [Releases](https://github.com/markmcfuzz/HaloCE-Max-Toolkit/releases) page.  
2. In 3ds Max, go to **Scripting → Run Script**, select the `.mzp` file.  
3. Follow the installer dialog to install the toolkit.  

After installation, the new **Halo CE Toolkit** menu will appear automatically.  

## Screenshots
### Installer UI
![Installer](docs/images\installer_dialog.png)

### Halo CE Toolkit Menu 
![Installer](docs/images\toolkit_menu.png)

### Import Options 
![Installer](docs/images\import_menu.png)

### Export Options 
![Installer](docs/images\export_menu.png)

## FAQ / Troubleshooting

Q: The Halo CE Toolkit menu does not appear after installing.
A: Make sure 3ds Max is restarted. If it still does not appear, run the installer again or check that HaloCE_Toolbar.cuix was copied to your \UI folder.

Q: The script says “file not found”.
A: Check that the scripts/halo folder exists in your \userscripts directory.

Q: Can I install this in older versions of 3ds Max?
A: The toolkit is built for 3ds Max 2023 and later, but may work on older versions (2020+)

## Credits

- Original scripts from BlueStreak
- Adapted, improved and integrated by MarkMcFuzz