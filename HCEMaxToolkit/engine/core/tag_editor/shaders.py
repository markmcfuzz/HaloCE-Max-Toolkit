"""Shaders tab: the Animation Preview and the shader tags of the selected object's (or mesh's)
GlyphFX materials (builders\\tag\\shared\\shader_tag_ca.ms). A click edits one, with the same
field editors as the tag editor."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets, shiboken, GetQMaxMainWindow
from . import preview, tabs
from .fields import flat_button
from .layout import group_layout
from .panel import TagEditorPanel

DOCK_NAME = "HCEShadersDock"
EDITOR_DOCK_NAME = "HCETagEditorDock"  # see __init__.py
TITLE = "Shaders"
LIST_TITLE = "Shaders"

_panel = None


def shader_list(panel, materials):
    """One button per material: "name  (shader_transparent_generic)". Materials made by hand
    have no tag fields yet: the click makes them first."""
    widget = QtWidgets.QWidget()
    column = QtWidgets.QVBoxLayout(widget)
    column.setContentsMargins(6, 2, 0, 2)
    column.setSpacing(0)
    for mat in materials:
        has_fields, group = list(rt.shaderEditorListInfo(mat))
        if has_fields:
            button = flat_button("%s  (%s)" % (mat.name, group), QtCore.Qt.RightArrow)
            button.setToolTip("Edit this shader's tag fields")
            button.clicked.connect(lambda checked=False, mat=mat: panel.open_shader(mat))
        else:
            button = flat_button("%s  (%s, no tag fields yet)" % (mat.name, group), QtCore.Qt.RightArrow)
            button.setToolTip("Made by hand: click to create its tag fields from the material")
            button.clicked.connect(lambda checked=False, mat=mat: panel.create_shader_fields(mat))
        column.addWidget(button)
    return widget


class ShaderPanel(TagEditorPanel):
    """The list of the selection's shaders, or the shader opened from it (Back returns)."""

    def __init__(self, parent=None):
        super().__init__(parent)
        # Open at first in this tab
        self.expanded[preview.TITLE] = True
        self.expanded[LIST_TITLE] = True

    def open_shader(self, mat):
        """Shows a material's shader tag fields until its node is deselected or Back."""
        self.shader = mat
        self.shader_from = self.handle
        self.back_title = self.title.text()
        QtCore.QTimer.singleShot(0, self.refresh)  # the clicked button is rebuilt

    def create_shader_fields(self, mat):
        """A GlyphFX material made by hand: makes every tag field (undoable), then opens it."""
        ok, warnings = list(rt.shaderEditorCreateFields(mat))
        warnings = list(warnings)
        if not ok:
            QtWidgets.QMessageBox.warning(self, "Create Tag Fields",
                                          "\n".join(warnings) or "Failed, see the log.")
            return
        if warnings:
            QtWidgets.QMessageBox.information(self, "Create Tag Fields",
                                              "Created, with warnings:\n\n" + "\n".join(warnings))
        self.open_shader(mat)

    def _preview(self, handle):
        """The Animation Preview section, at the top in both views (when it has materials)."""
        node = rt.maxOps.getNodeByHandle(handle)
        if node is None or rt.tagEditorPreviewState(node) is None:
            return []
        return [(preview.TITLE, lambda: preview.preview_box(node))]

    def _show_header(self, title, info, back, export):
        self.title.setText(title)
        self.info.setText(info)
        self.back_button.setVisible(back)
        self.select_button.setVisible(False)
        self.shaders_button.setVisible(False)
        self.export_button.setVisible(export)

    def _show_shader(self):
        mat_id, name, group, tag_file, keys, values, folder = list(rt.shaderEditorFields(self.shader))
        values = dict(zip(list(keys), list(values)))
        if folder:
            self.remember_tags_root(folder.replace("\\", "/"))  # a new tag: "..." browses there
        same = self._set_view(("shader", mat_id))
        # Undo / redo changed the fields: the GlyphFX parameters follow
        if same and values != self.values:
            rt.shaderEditorApply(self.shader)
        try:
            layout = group_layout(group)
        except RuntimeError as error:
            self._show_message(name, "Could not read the %s definitions:\n%s" % (group, error))
            return
        self.node, self.handle = None, self.shader_from
        self.values = values
        self.tag_file = tag_file
        self.back_button.setText(self.back_title)
        self._show_header(name, "%s\n%s" % (group, tag_file or "New tag, not exported yet"), True, True)
        # The shader type's own section (after the parent 'shader' one) starts open
        self._show_sections(layout["sections"], min(1, len(layout["sections"]) - 1), same,
                            self._preview(self.shader_from))

    def _show_list(self, handle, materials):
        same = self._set_view(("list", handle))
        self.node, self.handle = None, handle
        self.values = {}
        self._show_header(rt.maxOps.getNodeByHandle(handle).name,
                          "Click a shader to edit its tag fields.", False, False)
        extra = self._preview(handle) + [(LIST_TITLE, lambda: shader_list(self, materials))]
        self._show_sections([], -1, same, extra)

    def refresh(self):
        """Shows the selection's shaders, or the one opened from them; called on selection
        change, undo and redo."""
        selected = int(rt.tagEditorSelectedHandle())
        # Undoing "Create Tag Fields" takes the fields away
        if self.shader is not None and selected == self.shader_from and rt.hasShaderTagFields(self.shader):
            self._show_shader()
            return
        self.shader = None
        materials = list(rt.shaderEditorSelectionShaders())
        if materials:
            self._show_list(selected, materials)
        else:
            self._show_message("No shaders selected",
                               "Select the Point of an imported object tag, or a mesh with GlyphFX shaders.")


def _dock(main, name):
    for dock in main.findChildren(QtWidgets.QDockWidget, name):
        if shiboken.isValid(dock):
            return dock
    return None


def current():
    """The open panel, or None."""
    return _panel if _panel is not None and shiboken.isValid(_panel) else None


def show():
    """Opens the tab beside the tag editor (right side when it's floating or closed) or brings
    it to the front, showing the selection."""
    global _panel
    main = GetQMaxMainWindow()
    if current() is None:
        beside = _dock(main, EDITOR_DOCK_NAME)
        dock = QtWidgets.QDockWidget(TITLE, main)
        dock.setObjectName(DOCK_NAME)
        dock.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        dock.setMinimumWidth(320)
        _panel = ShaderPanel(dock)
        dock.setWidget(_panel)
        if beside is not None and not beside.isFloating():
            main.addDockWidget(main.dockWidgetArea(beside), dock)
            main.tabifyDockWidget(beside, dock)
        else:
            main.addDockWidget(QtCore.Qt.RightDockWidgetArea, dock)
    dock = _panel.parent()
    dock.show()
    dock.raise_()
    tabs.watch()
    _panel.refresh()
