"""Halo tag editor: a dockable panel that edits the fields of the selected object tag Point.
builders/tag/object/tag_editor.ms calls follow_selection() when the selection changes."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets, shiboken, GetQMaxMainWindow
from .panel import TagEditorPanel
from . import tabs, player, shaders

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
    """New, reset or open scene: the editor, the Shaders tab and the players belong to the old scene."""
    main = GetQMaxMainWindow()
    for name in (DOCK_NAME, shaders.DOCK_NAME, player.DOCK_NAME, player.IMPORT_DOCK_NAME):
        for dock in main.findChildren(QtWidgets.QDockWidget, name):
            if shiboken.isValid(dock):
                dock.close()


def show_model_animations(tag_path):
    """Import > Tag > Model Animations (import_model_animations.ms)."""
    player.show_scene(tag_path, _command_panel)


def _refresh(panel, force):
    """Shows the selection; True when it moved to another node. Selection change, same node:
    rebuilding would delete an open eye menu (and is slow)."""
    previous = panel.handle
    if not force and previous is not None and int(rt.tagEditorSelectedHandle()) == previous:
        return False
    panel.refresh()
    return panel.handle is not None and panel.handle != previous


def follow_selection(force=True):
    """Opens the panel when an object tag Point is selected; brings its tab to the front
    when another Point is selected (not over the Shaders tab while it is the one shown).
    Otherwise only shows the current selection. The Shaders tab follows it too."""
    shader_panel = shaders.current()
    if shader_panel is not None:
        _refresh(shader_panel, force)
    if not _is_open():
        if rt.tagEditorSelected() is not None:
            show()
        return
    if _refresh(_panel, force) and (shader_panel is None or not shader_panel.isVisible()):
        _panel.parent().raise_()
