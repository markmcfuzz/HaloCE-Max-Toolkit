"""Editors for one tag field. Values are text as in lua\\importers\\shared\\tag_fields.lua:
numbers as typed, several numbers space-separated, angles in radians, refs as "group:path"."""
import math

from .qt import QtCore, QtGui, QtWidgets


# Spinners and lists change with the mouse wheel only when focused, so scrolling the panel is safe
class SpinBox(QtWidgets.QSpinBox):
    def __init__(self, low, high):
        super().__init__()
        self.setFocusPolicy(QtCore.Qt.StrongFocus)
        self.setKeyboardTracking(False)
        self.setRange(low, high)

    def wheelEvent(self, event):
        if self.hasFocus():
            super().wheelEvent(event)
        else:
            event.ignore()


class ComboBox(QtWidgets.QComboBox):
    def __init__(self):
        super().__init__()
        self.setFocusPolicy(QtCore.Qt.StrongFocus)

    def wheelEvent(self, event):
        if self.hasFocus():
            super().wheelEvent(event)
        else:
            event.ignore()


def to_float(text):
    try:
        return float(text)
    except ValueError:
        return None


def to_int(text):
    try:
        return int(text)
    except ValueError:
        return 0


def parts_of(text, count):
    parts = text.split()
    return (parts + ["0"] * count)[:count]


def degrees_text(radians_text):
    radians = to_float(radians_text)
    return "%.6g" % math.degrees(radians) if radians is not None else "0"


def radians_text(degrees):
    return "%.9g" % math.radians(degrees)


def ref_path(value):
    """"ligh:vehicles\\warthog\\headlights" -> "vehicles\\warthog\\headlights"."""
    return value.split(":", 1)[1] if ":" in value else value


def to_signed32(value):
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value >= 0x80000000 else value


def number_edit(panel, key, part, count, angle):
    """Line edit for a float (part None) or one part of several; angles shown in degrees."""
    edit = QtWidgets.QLineEdit()

    def stored():
        value = panel.value(key)
        return value if part is None else parts_of(value, count)[part]

    def show():
        edit.setText(degrees_text(stored()) if angle else stored())

    def commit():
        if not edit.isModified():
            return  # only left the field: re-storing would round angles again
        number = to_float(edit.text().strip())
        if number is not None:
            text = radians_text(number) if angle else edit.text().strip()
            if part is None:
                panel.set_value(key, text)
            else:
                parts = parts_of(panel.value(key), count)
                parts[part] = text
                panel.set_value(key, " ".join(parts))
        show()  # an invalid number shows the stored value again

    show()
    edit.show_value = show  # lets a color picker update the text
    edit.editingFinished.connect(commit)
    return edit


class ColorEditor(QtWidgets.QWidget):
    """0-1 floats (r g b, or a r g b) and a swatch that opens the color picker."""

    def __init__(self, panel, key, parts):
        super().__init__()
        self.panel = panel
        self.key = key
        self.parts = parts
        self.has_alpha = parts == 4
        layout = QtWidgets.QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.edits = [number_edit(panel, key, i, parts, False) for i in range(parts)]
        for edit in self.edits:
            layout.addWidget(edit)
        self.swatch = QtWidgets.QPushButton()
        self.swatch.setFixedSize(36, 20)
        self.swatch.setToolTip("Pick a color")
        self.swatch.clicked.connect(self.pick)
        layout.addWidget(self.swatch)
        panel.value_changed.connect(self._value_changed)
        self._update_swatch()

    def _color(self):
        parts = parts_of(self.panel.value(self.key), self.parts)
        values = [min(max(to_float(p) or 0.0, 0.0), 1.0) for p in parts]
        if self.has_alpha:
            a, r, g, b = values
        else:
            (r, g, b), a = values, 1.0
        return QtGui.QColor.fromRgbF(r, g, b, a)

    def _update_swatch(self):
        self.swatch.setStyleSheet("background-color: %s; border: 1px solid #555;" % self._color().name())

    def _value_changed(self, key):
        if key == self.key:
            self._update_swatch()

    def pick(self):
        dialog = QtWidgets.QColorDialog
        if self.has_alpha:
            color = dialog.getColor(self._color(), self, "Color", dialog.ShowAlphaChannel)
        else:
            color = dialog.getColor(self._color(), self, "Color")
        if not color.isValid():
            return  # cancelled
        rgb = [color.redF(), color.greenF(), color.blueF()]
        values = ([color.alphaF()] if self.has_alpha else []) + rgb
        self.panel.set_value(self.key, " ".join("%.6g" % v for v in values))
        for edit in self.edits:
            edit.show_value()


def row_of(widgets):
    row = QtWidgets.QWidget()
    layout = QtWidgets.QHBoxLayout(row)
    layout.setContentsMargins(0, 0, 0, 0)
    for w in widgets:
        layout.addWidget(w)
    return row


def int_spin(panel, key, part, count, low, high):
    value = panel.value(key)
    spin = SpinBox(low, high)
    spin.setValue(to_int(value if part is None else parts_of(value, count)[part]))

    def commit(v):
        if part is None:
            panel.set_value(key, str(v))
        else:
            parts = parts_of(panel.value(key), count)
            parts[part] = str(v)
            panel.set_value(key, " ".join(parts))

    spin.valueChanged.connect(commit)
    return spin


def enum_combo(panel, key, options):
    combo = ComboBox()
    combo.addItems(options)
    value = to_int(panel.value(key))
    combo.setCurrentIndex(value if 0 <= value < len(options) else -1)

    def commit(i):
        if i >= 0:
            panel.set_value(key, str(i))

    combo.currentIndexChanged.connect(commit)
    return combo


def flags_box(panel, key, options):
    """One checkbox per bit; bits without a name keep their value."""
    box = QtWidgets.QWidget()
    layout = QtWidgets.QVBoxLayout(box)
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(1)
    value = to_int(panel.value(key))
    for bit, name in enumerate(options):
        check = QtWidgets.QCheckBox(name)
        check.setChecked(bool((value >> bit) & 1))

        def commit(checked, bit=bit):
            v = to_int(panel.value(key))
            v = v | (1 << bit) if checked else v & ~(1 << bit)
            panel.set_value(key, str(to_signed32(v)))

        check.toggled.connect(commit)
        layout.addWidget(check)
    return box


def tags_root_of(path):
    """"D:/halo/tags/vehicles/x.vehicle" -> "D:/halo/tags/" (None outside a tags folder)."""
    at = path.replace("\\", "/").lower().find("/tags/")
    return path.replace("\\", "/")[:at + 6] if at >= 0 else None


# Object references whose imported nodes the eye shows / hides (tagRefLayers in tag_editor.ms)
EYE_PARTS = {"object.model": "model", "object.animation graph": "animation",
             "object.collision model": "collision", "object.physics": "physics"}


def eye_part(key):
    if "[" not in key:
        for suffix, part in EYE_PARTS.items():
            if key.endswith(suffix):
                return part
    return None


def eye_icon(visible, color):
    """Drawn here so no image files are needed: an open eye, or a crossed out one."""
    size = 32
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtGui.QPen(color, 2.5))
    outline = QtGui.QPainterPath()
    outline.moveTo(3, 16)
    outline.quadTo(16, 1, 29, 16)
    outline.quadTo(16, 31, 3, 16)
    painter.drawPath(outline)
    if visible:
        painter.setBrush(color)
        painter.drawEllipse(QtCore.QPointF(16, 16), 5, 5)
    else:
        painter.drawLine(5, 28, 27, 4)
    painter.end()
    return QtGui.QIcon(pixmap)


def link_icon(color):
    """Two chain links."""
    size = 32
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtGui.QPen(color, 2.5))
    painter.translate(16, 16)
    painter.rotate(-45)
    painter.drawRoundedRect(QtCore.QRectF(-14, -5, 17, 10), 5, 5)
    painter.drawRoundedRect(QtCore.QRectF(-3, -5, 17, 10), 5, 5)
    painter.end()
    return QtGui.QIcon(pixmap)


def link_button(panel, part):
    """Menu to link scene objects to a reference, unlink them or select them."""
    button = QtWidgets.QToolButton()
    button.setAutoRaise(True)
    button.setPopupMode(QtWidgets.QToolButton.InstantPopup)
    button.setStyleSheet("QToolButton::menu-indicator { image: none; }")
    button.setIcon(link_icon(button.palette().color(QtGui.QPalette.ButtonText)))
    if part == "animation":
        button.setEnabled(False)
        button.setToolTip("Animations can't be linked yet")
        return button
    button.setToolTip("Link scene objects as the %s" % part)
    linked = panel.ref_visibility(part) > 0
    menu = QtWidgets.QMenu(button)
    menu.addAction("Link Objects...", lambda: panel.link_ref(part))
    menu.addAction("Unlink Objects...", lambda: panel.unlink_ref(part)).setEnabled(linked)
    menu.addAction("Select Linked", lambda: panel.select_ref(part)).setEnabled(linked)
    button.setMenu(menu)
    return button


def eye_button(panel, part):
    """Shows or hides the nodes this reference imported (undoable in Max)."""
    button = QtWidgets.QToolButton()
    button.setCheckable(True)
    button.setAutoRaise(True)
    color = button.palette().color(QtGui.QPalette.ButtonText)
    state = panel.ref_visibility(part)  # 0 = no nodes, 1 = all hidden, 2 = visible

    def show_state(visible):
        button.setIcon(eye_icon(visible, color))

    button.setChecked(state == 2)
    show_state(state == 2)
    button.setEnabled(state > 0)
    button.setToolTip("Show / hide the %s" % part if state > 0
                      else "Nothing to show or hide: import or link the %s first" % part)

    def toggled(visible):
        show_state(visible)
        panel.show_ref(part, visible)

    button.toggled.connect(toggled)
    return button


def ref_edit(panel, key, allowed, accepts):
    """Path without extension, typed or picked with "..."; the group stays in the value and
    export checks it."""
    edit = QtWidgets.QLineEdit(ref_path(panel.value(key)))
    edit.setToolTip("Allowed: " + ", ".join(allowed) if allowed else "Allowed: any tag")

    def commit():
        if not edit.isModified():
            return
        value = panel.value(key)
        group = value.split(":", 1)[0] if ":" in value else ""
        panel.set_value(key, group + ":" + edit.text().strip())
        edit.setText(ref_path(panel.value(key)))

    def browse():
        root = panel.tags_root()
        current = ref_path(panel.value(key)).replace("\\", "/")
        start = root or ""
        if root and current:
            start = root + current.rsplit("/", 1)[0] if "/" in current else root
        names = [name for name, _ in accepts]
        filters = "Allowed tags (%s);;All Files (*.*)" % " ".join("*." + n for n in names)
        path, _ = QtWidgets.QFileDialog.getOpenFileName(edit, "Select Tag", start, filters)
        if not path:
            return  # cancelled
        tag_root = tags_root_of(path)
        base, ext = path.rsplit(".", 1) if "." in path.rsplit("/", 1)[-1] else (path, "")
        fourcc = dict(accepts).get(ext.lower())
        if tag_root is None or fourcc is None:
            QtWidgets.QMessageBox.warning(
                edit, "Select Tag",
                "Pick a %s tag inside a tags folder." % " / ".join(names) if tag_root is None
                else "'.%s' is not allowed here. Allowed: %s" % (ext, ", ".join(allowed)))
            return
        panel.remember_tags_root(tag_root)
        panel.set_value(key, fourcc + ":" + base[len(tag_root):].replace("/", "\\"))
        edit.setText(ref_path(panel.value(key)))

    button = QtWidgets.QToolButton()
    button.setText("...")
    button.setToolTip("Browse for a tag")
    button.clicked.connect(browse)
    edit.editingFinished.connect(commit)
    part = eye_part(key)
    buttons = [eye_button(panel, part), link_button(panel, part)] if part else []
    return row_of(buttons + [edit, button])


def text_edit(panel, key, max_length):
    edit = QtWidgets.QLineEdit(panel.value(key))
    edit.setMaxLength(max_length)

    def commit():
        if not edit.isModified():
            return
        panel.set_value(key, edit.text().strip())
        edit.setText(panel.value(key))

    edit.editingFinished.connect(commit)
    return edit


def field_editor(panel, field, key):
    """Widget for a layout field (lua\\bridge\\tag_ui.lua) stored under key."""
    kind = field["kind"]
    if kind in ("float", "angle"):
        return number_edit(panel, key, None, 1, kind == "angle")
    if kind in ("floats", "angles"):
        count = field["parts"]
        return row_of([number_edit(panel, key, i, count, kind == "angles") for i in range(count)])
    if kind == "color":
        return ColorEditor(panel, key, field["parts"])
    if kind == "int":
        return int_spin(panel, key, None, 1, field["min"], field["max"])
    if kind == "ints":
        count = field["parts"]
        return row_of([int_spin(panel, key, i, count, -32768, 32767) for i in range(count)])
    if kind == "enum":
        return enum_combo(panel, key, field["options"])
    if kind == "flags":
        return flags_box(panel, key, field["options"])
    if kind == "ref":
        return ref_edit(panel, key, field.get("allowed", []), field.get("accepts", []))
    return text_edit(panel, key, field.get("maxLength", 255))
