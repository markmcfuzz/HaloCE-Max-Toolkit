"""Halo tag editor: a dockable panel that edits the fields of the selected object tag Point.
builders/tag/object/tag_editor.ms calls follow_selection() when the selection changes."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets, shiboken, GetQMaxMainWindow
from .panel import TagEditorPanel
from . import tabs, player

DOCK_NAME = "HCETagEditorDock"

_panel = None


def _is_open():
    return _panel is not None and shiboken.isValid(_panel)


def show():
    """Opens the panel as a tab next to the Command Panel, replacing one already open."""
    global _panel
    main = GetQMaxMainWindow()
    for old in main.findChildren(QtWidgets.QDockWidget, DOCK_NAME):
        if not shiboken.isValid(old):
            continue
        old.close()
        old.deleteLater()

    dock = QtWidgets.QDockWidget("Halo Tag Editor", main)
    dock.setObjectName(DOCK_NAME)
    dock.setAttribute(QtCore.Qt.WA_DeleteOnClose)
    dock.setMinimumWidth(320)
    _panel = TagEditorPanel(dock)
    dock.setWidget(_panel)

    # Docked on the right when the Command Panel is floating or not found
    command_panel = _command_panel(main)
    if command_panel is not None and not command_panel.isFloating():
        main.addDockWidget(main.dockWidgetArea(command_panel), dock)
        main.tabifyDockWidget(command_panel, dock)
    else:
        main.addDockWidget(QtCore.Qt.RightDockWidgetArea, dock)
    dock.show()
    dock.raise_()
    tabs.watch()
    _panel.refresh()


def _command_panel(main):
    # Closed docks can still be listed as deleted objects: skip them
    for dock in main.findChildren(QtWidgets.QDockWidget):
        if not shiboken.isValid(dock):
            continue
        if dock.objectName() == "CommandPanel" or dock.windowTitle() == "Command Panel":
            return dock
    return None


def close_all():
    """New, reset or open scene: the editor and the players belong to the old scene."""
    main = GetQMaxMainWindow()
    for name in (DOCK_NAME, player.DOCK_NAME, player.IMPORT_DOCK_NAME):
        for dock in main.findChildren(QtWidgets.QDockWidget, name):
            if shiboken.isValid(dock):
                dock.close()


def show_model_animations(tag_path):
    """Import > Tag > Model Animations (import_model_animations.ms)."""
    player.show_scene(tag_path, _command_panel)


def follow_selection():
    """Opens the panel when an object tag Point is selected; brings its tab to the front
    when another Point is selected. Otherwise only shows the current selection."""
    if not _is_open():
        if rt.tagEditorSelected() is not None:
            show()
        return
    previous = _panel.handle
    _panel.refresh()
    if _panel.handle is not None and _panel.handle != previous:
        _panel.parent().raise_()
