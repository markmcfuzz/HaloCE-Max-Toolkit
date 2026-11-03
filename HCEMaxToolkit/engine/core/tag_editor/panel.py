"""Panel with the fields of the selected object tag Point, in tag order. Values are read and
written through the MAXScript functions of builders\\tag\\object\\tag_editor.ms."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets
from . import elements
from .layout import group_layout
from .fields import ComboBox, field_editor, field_label, ref_path, set_help, tags_root_of, to_int


class Section(QtWidgets.QWidget):
    """Title that shows or hides its fields; they are built the first time it opens."""

    def __init__(self, title, build, expanded, on_toggle):
        super().__init__()
        self._build = build
        self._content = None
        self._on_toggle = on_toggle
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.button = QtWidgets.QToolButton()
        self.button.setText(title)
        self.button.setCheckable(True)
        self.button.setChecked(expanded)
        self.button.setToolButtonStyle(QtCore.Qt.ToolButtonTextBesideIcon)
        self.button.setSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        self.button.setStyleSheet("QToolButton { font-weight: bold; text-align: left; }")
        self.button.toggled.connect(self._toggled)
        layout.addWidget(self.button)
        self._show(expanded)

    def _toggled(self, checked):
        self._show(checked)
        self._on_toggle(checked)

    def _show(self, visible):
        self.button.setArrowType(QtCore.Qt.DownArrow if visible else QtCore.Qt.RightArrow)
        if visible and self._content is None:
            self._content = self._build()
            self.layout().addWidget(self._content)
        if self._content is not None:
            self._content.setVisible(visible)


class Block(QtWidgets.QGroupBox):
    """A tag block: element picker and the selected element's fields."""

    def __init__(self, panel, field, count_key):
        super().__init__()
        self.panel = panel
        self.field = field
        self.count_key = count_key  # "unit.seats"; elements are "unit.seats[0]. ..."
        self.body = None
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        # Bold name as a label: a style sheet on the box loses Max's theme color
        self.title_label = QtWidgets.QLabel()
        font = self.title_label.font()
        font.setBold(True)
        self.title_label.setFont(font)
        layout.addWidget(self.title_label)
        self.picker = ComboBox()
        self.picker.currentIndexChanged.connect(self._select)
        layout.addWidget(self.picker)
        self.buttons = {}
        if not field.get("fixed"):
            # Arrays have a fixed count: no buttons
            row = QtWidgets.QHBoxLayout()
            for name, action in (("Add", panel.add_element), ("Duplicate", panel.duplicate_element),
                                 ("Delete", panel.delete_element)):
                button = QtWidgets.QPushButton(name)
                button.clicked.connect(
                    lambda checked=False, action=action: action(self.field, self.count_key,
                                                                self.picker.currentIndex()))
                row.addWidget(button)
                self.buttons[name] = button
            layout.addLayout(row)
        panel.value_changed.connect(self._value_changed)
        self._fill()

    def _count(self):
        return max(0, to_int(self.panel.value(self.count_key)))

    def _label(self, i):
        """"0", or "0: W-driver" when the element has a name or tag reference."""
        label_key = self.field.get("label")
        text = self.panel.value("%s[%d].%s" % (self.count_key, i, label_key)) if label_key else ""
        if text and self.field.get("labelIsRef"):
            text = ref_path(text).split("\\")[-1]
        # Lettered blocks: "0: A out (name)" for functions, "0: A" for change colors
        letters = self.field.get("letters")
        if letters is not None and i < 26:
            letter = chr(ord("A") + i) + letters
            return "%d: %s (%s)" % (i, letter, text) if text else "%d: %s" % (i, letter)
        return "%d: %s" % (i, text) if text else str(i)

    def _fill(self):
        count = self._count()
        set_help(self.title_label, self.field, "%s (%d)" % (self.field["name"].upper(), count))
        index = min(self.panel.block_index.get(self.count_key, 0), count - 1)
        self.picker.blockSignals(True)
        self.picker.clear()
        self.picker.addItems([self._label(i) for i in range(count)])
        self.picker.setCurrentIndex(index)
        self.picker.blockSignals(False)
        self.picker.setEnabled(count > 0)
        if self.buttons:
            room = self.field.get("max") is None or count < self.field["max"]
            self.buttons["Add"].setEnabled(room)
            self.buttons["Duplicate"].setEnabled(room and count > 0)
            self.buttons["Delete"].setEnabled(count > 0)
            if self.field.get("max") is not None:
                self.buttons["Add"].setToolTip("Up to %d elements" % self.field["max"])
        self._build(index)

    def _select(self, index):
        self.panel.block_index[self.count_key] = index
        self._build(index)

    def _build(self, index):
        if self.body is not None:
            self.layout().removeWidget(self.body)
            self.body.hide()
            self.body.deleteLater()
        if index < 0:
            self.body = QtWidgets.QLabel("No elements")
            self.body.setEnabled(False)
        else:
            self.body = self.panel.build_fields(self.field["fields"], "%s[%d]." % (self.count_key, index))
        self.layout().addWidget(self.body)

    def _value_changed(self, key):
        # A renamed element updates its picker item
        label_key = self.field.get("label")
        prefix = self.count_key + "["
        if label_key and key.startswith(prefix) and key.endswith("]." + label_key):
            for i in range(self.picker.count()):
                self.picker.setItemText(i, self._label(i))


class TagEditorPanel(QtWidgets.QWidget):
    value_changed = QtCore.Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.node = None
        self.handle = None
        self.values = {}
        self.tag_file = ""
        self.last_tags_root = None
        self.block_index = {}  # selected element per block count key
        self.expanded = {}  # open sections by title
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        self.title = QtWidgets.QLabel()
        self.title.setStyleSheet("font-weight: bold;")
        self.info = QtWidgets.QLabel()
        self.info.setWordWrap(True)
        self.info.setTextInteractionFlags(QtCore.Qt.TextSelectableByMouse)
        # Here and not on the Point: Max blocks Python started from the Point's own panel
        self.select_button = QtWidgets.QPushButton("Select Contents")
        self.select_button.clicked.connect(lambda: rt.tagEditorSelectContents(self.node))
        # Always asks where to save, starting at the imported tag
        self.export_button = QtWidgets.QPushButton("Export Tag...")
        self.export_button.setToolTip("Writes the tag; asks where to save it")
        self.export_button.clicked.connect(self._export)
        self.scroll = QtWidgets.QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.scroll.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        layout.addWidget(self.title)
        layout.addWidget(self.info)
        buttons = QtWidgets.QHBoxLayout()
        buttons.addWidget(self.select_button)
        buttons.addWidget(self.export_button)
        layout.addLayout(buttons)
        layout.addWidget(self.scroll, 1)

    def value(self, key):
        return self.values.get(key, "")

    def tags_root(self):
        """Tags folder of the tag being edited; for a new tag, the last one browsed."""
        return tags_root_of(self.tag_file) or self.last_tags_root

    def remember_tags_root(self, root):
        self.last_tags_root = root

    def set_value(self, key, text):
        """Stores a field on the Point (undoable); unknown keys and equal values are skipped."""
        if self.node is None or key not in self.values or self.values[key] == text:
            return
        if rt.tagEditorSetField(self.node, key, text):
            self.values[key] = text
            self.value_changed.emit(key)
            if "change colors" in key:
                rt.applyObjectChangeColors(self.node)  # the model's materials show them
            elif key.endswith(("object.bounding radius", "object.bounding offset")):
                rt.applyObjectBoundingRadius(self.node)  # the Influence helper

    def ref_visibility(self, part, kinds=None):
        """0 = no nodes, 1 = all hidden, 2 = some visible; kinds None = all of them."""
        if self.node is None:
            return 0
        return int(rt.tagEditorRefVisibility(self.node, part, kinds))

    def show_ref(self, part, visible, kinds=None):
        if self.node is not None:
            rt.tagEditorShowRef(self.node, part, visible, kinds)

    def link_ref(self, part):
        # After the menu closes: refresh rebuilds the button that opened it
        if self.node is not None and rt.tagEditorLinkRef(self.node, part) > 0:
            QtCore.QTimer.singleShot(0, self.refresh)

    def unlink_ref(self, part):
        if self.node is not None and rt.tagEditorUnlinkRef(self.node, part) > 0:
            QtCore.QTimer.singleShot(0, self.refresh)

    def add_bounding_radius(self):
        # Later: refresh rebuilds the "+" that was clicked into the eye
        if self.node is not None and rt.tagEditorAddBoundingRadius(self.node):
            QtCore.QTimer.singleShot(0, self.refresh)

    def select_ref(self, part):
        if self.node is not None:
            rt.tagEditorSelectRef(self.node, part)  # the editor follows the new selection

    def _set_elements(self, count_key, result):
        """Stores the fields after a block change (one undo step) and shows the new element."""
        values, index = result
        if self.node is None or not rt.tagEditorSetFields(self.node, list(values), list(values.values())):
            return
        # Nested blocks start again at their first element
        for key in [k for k in self.block_index if k.startswith(count_key + "[")]:
            del self.block_index[key]
        self.block_index[count_key] = max(index, 0)
        self.refresh()

    def add_element(self, field, count_key, index):
        self._set_elements(count_key, elements.add(self.values, field, count_key))

    def duplicate_element(self, field, count_key, index):
        if index >= 0:
            self._set_elements(count_key, elements.duplicate(self.values, count_key, index))

    def delete_element(self, field, count_key, index):
        if index >= 0:
            self._set_elements(count_key, elements.delete(self.values, count_key, index))

    def _export(self):
        # Clicking the button takes the focus, so a field being typed in is already stored
        if self.node is not None and rt.tagEditorExport(self.node) is not None:
            self.refresh()  # shows the new tag path

    def _show_message(self, title, info):
        self.node = None
        self.handle = None
        self.title.setText(title)
        self.info.setText(info)
        self.select_button.setVisible(False)
        self.export_button.setVisible(False)
        self.scroll.setWidget(QtWidgets.QWidget())

    def refresh(self):
        """Shows the selected Point; called on selection change, undo and redo."""
        node = rt.tagEditorSelected()
        if node is None:
            self._show_message("No object tag selected",
                               "Select the Point of an imported object tag (e.g. warthog.vehicle).")
            return
        handle, name, group, tag_file, keys, values, contents = list(rt.tagEditorFields(node))
        same_node = handle == self.handle
        scroll_pos = self.scroll.verticalScrollBar().value()
        try:
            layout = group_layout(group)
        except RuntimeError as error:
            self._show_message(name, "Could not read the %s definitions:\n%s" % (group, error))
            return

        if not same_node:
            self.block_index = {}
        self.node, self.handle = node, handle
        self.values = dict(zip(list(keys), list(values)))
        self.tag_file = tag_file
        # Also after undo / redo and block changes
        rt.applyObjectChangeColors(node)
        rt.applyObjectBoundingRadius(node)
        self.title.setText(name)
        self.info.setText(tag_file or "New tag, not exported yet")
        self.select_button.setVisible(True)
        # New tags (and deleted imports) have nothing to select
        self.select_button.setEnabled(contents > 0)
        self.select_button.setToolTip(
            "Selects the model, collision and physics of the tag" if contents > 0
            else "Nothing to select: import the tag or link objects to it")
        self.export_button.setVisible(True)

        content = QtWidgets.QWidget()
        column = QtWidgets.QVBoxLayout(content)
        column.setContentsMargins(0, 0, 0, 0)
        sections = layout["sections"]
        for section in sections:
            title = section["title"]
            # Object (the first section) starts open
            expanded = self.expanded.get(title, section is sections[0])
            column.addWidget(Section(
                title,
                lambda fields=section["fields"]: self.build_fields(fields, ""),
                expanded,
                lambda on, title=title: self.expanded.__setitem__(title, on)))
        column.addStretch(1)
        self.scroll.setWidget(content)
        if same_node:
            QtCore.QTimer.singleShot(0, lambda: self.scroll.verticalScrollBar().setValue(scroll_pos))

    def build_fields(self, fields, prefix):
        """Form with layout fields in order; keys are prefix + field key."""
        widget = QtWidgets.QWidget()
        form = QtWidgets.QFormLayout(widget)
        form.setContentsMargins(6, 2, 0, 2)
        form.setRowWrapPolicy(QtWidgets.QFormLayout.WrapLongRows)
        form.setFieldGrowthPolicy(QtWidgets.QFormLayout.AllNonFixedFieldsGrow)
        for field in fields:
            key = prefix + field["key"]
            if field["kind"] == "block":
                form.addRow(Block(self, field, key))
            elif field["kind"] == "flags":
                # Name on its own row, checkboxes below it
                form.addRow(field_label(field))
                box = field_editor(self, field, key)
                box.setContentsMargins(12, 0, 0, 0)
                form.addRow(box)
            else:
                form.addRow(field_label(field), field_editor(self, field, key))
        return widget
