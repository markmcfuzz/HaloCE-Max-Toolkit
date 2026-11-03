"""Editors for one tag field. Values are text as in lua\\importers\\shared\\tag_fields.lua:
numbers as typed, several numbers space-separated, angles in radians, refs as "group:path"."""
import html
import json
import math
import os
import re

from .qt import QtCore, QtGui, QtWidgets, shiboken

# Tooltip texts by help key ("object.bounding radius"), see lua\bridge\tag_ui.lua
HELP_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "field_help.json")
_help = None


def help_text(field):
    global _help
    if _help is None:
        try:
            with open(HELP_PATH, encoding="utf-8") as f:
                _help = json.load(f)
        except (OSError, ValueError) as error:
            print("Tag editor: could not read %s: %s" % (HELP_PATH, error))
            _help = {}
    return _help.get(field.get("help", ""), "")


# Mark before names that have help; change its color here
HELP_MARK = '<span style="color:#4FC3F7; font-weight:bold;">?</span>&nbsp;&nbsp;'


def set_help(label, field, text):
    """"? name" with the help as tooltip, when the field has one."""
    help = help_text(field)
    if not help:
        label.setText(text)
        return
    label.setTextFormat(QtCore.Qt.RichText)
    label.setText(HELP_MARK + html.escape(text))
    label.setToolTip("<qt>%s</qt>" % html.escape(help))  # rich text wraps long lines
    label.setCursor(QtCore.Qt.WhatsThisCursor)


def field_label(field):
    label = QtWidgets.QLabel()
    set_help(label, field, field["name"])
    return label


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


class NumberLineEdit(QtWidgets.QLineEdit):
    # Narrow by default (it still stretches): x y z rows fit next to the field name
    def sizeHint(self):
        hint = super().sizeHint()
        return QtCore.QSize(min(hint.width(), 40), hint.height())

    def minimumSizeHint(self):
        hint = super().minimumSizeHint()
        return QtCore.QSize(min(hint.width(), 30), hint.height())


def number_edit(panel, key, part, count, angle):
    """Line edit for a float (part None) or one part of several; angles shown in degrees."""
    edit = NumberLineEdit()

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

    def __init__(self, panel, key, parts, labels):
        super().__init__()
        self.panel = panel
        self.key = key
        self.parts = parts
        self.has_alpha = parts == 4
        layout = QtWidgets.QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.edits = [number_edit(panel, key, i, parts, False) for i in range(parts)]
        for widget in with_part_labels(self.edits, labels):
            layout.addWidget(widget)
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


def with_part_labels(widgets, labels):
    """Gray "x", "y", "z" (or "from", "to"...) before each box."""
    items = []
    for i, widget in enumerate(widgets):
        if labels and i < len(labels):
            label = QtWidgets.QLabel(labels[i])
            label.setEnabled(False)  # gray
            items.append(label)
        items.append(widget)
    return items


def row_of(widgets):
    row = QtWidgets.QWidget()
    layout = QtWidgets.QHBoxLayout(row)
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(4)
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
    """One checkbox per bit; bits without a name or "unused" (padding) are hidden and keep
    their value."""
    box = QtWidgets.QWidget()
    layout = QtWidgets.QVBoxLayout(box)
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(1)
    value = to_int(panel.value(key))
    for bit, name in enumerate(options):
        if not name or re.fullmatch(r"unused\d*", name):
            continue
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


# Object references with eye and link buttons (tagRefNodes in tag_editor.ms)
EYE_PARTS = {"object.model": "model", "object.animation graph": "animation",
             "object.collision model": "collision", "object.physics": "physics",
             "object.bounding radius": "boundingRadius"}
PART_NAMES = {"boundingRadius": "bounding radius helper"}


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


# What the eye's right-click menu offers (tagRefNodeKind in tag_editor.ms) and what is checked,
# as the import leaves it (lower LODs hidden). Kept while Max is open
EYE_KINDS = {"model": ["Geometry", "LODs", "Nodes", "Markers"], "collision": ["Geometry", "Pathfinding Spheres"]}
_eye_shown = {"model": {"Geometry", "Nodes", "Markers"}, "collision": {"Geometry", "Pathfinding Spheres"}}


class StayOpenMenu(QtWidgets.QMenu):
    """Checkable items toggle without closing the menu, so the viewport shows each change."""

    def _toggle(self, action):
        if action is not None and action.isCheckable() and action.isEnabled():
            action.trigger()
            return True
        return False

    def mouseReleaseEvent(self, event):
        if not self._toggle(self.actionAt(event.pos())):
            super().mouseReleaseEvent(event)

    def keyPressEvent(self, event):
        keys = (QtCore.Qt.Key_Return, QtCore.Qt.Key_Enter, QtCore.Qt.Key_Space)
        if not (event.key() in keys and self._toggle(self.activeAction())):
            super().keyPressEvent(event)


def eye_button(panel, part):
    """Shows or hides the nodes of a reference (undoable in Max); right-click picks which kinds."""
    button = QtWidgets.QToolButton()
    button.setCheckable(True)
    button.setAutoRaise(True)
    color = button.palette().color(QtGui.QPalette.ButtonText)
    kinds = EYE_KINDS.get(part)
    name = PART_NAMES.get(part, part)

    def shown():
        return [k for k in kinds if k in _eye_shown[part]] if kinds else None

    def update():
        has_nodes = panel.ref_visibility(part) > 0
        visible = has_nodes and panel.ref_visibility(part, shown()) == 2
        button.blockSignals(True)
        button.setChecked(visible)
        button.blockSignals(False)
        button.setIcon(eye_icon(visible, color))
        button.setEnabled(has_nodes)
        if not has_nodes:
            button.setToolTip("Nothing to show or hide: import or link the %s first" % name)
        elif kinds:
            button.setToolTip("Show / hide the %s: %s\nRight-click to choose what"
                              % (name, ", ".join(shown())))
        else:
            button.setToolTip("Show / hide the %s" % name)

    def toggled(visible):
        button.setIcon(eye_icon(visible, color))
        panel.show_ref(part, visible, shown())

    def set_kind(kind, on):
        # Unchecked kinds stay hidden; checked ones follow the eye
        (_eye_shown[part].add if on else _eye_shown[part].discard)(kind)
        panel.show_ref(part, on and button.isChecked(), [kind])

    def choose(pos):
        menu = StayOpenMenu(button)
        checked = _eye_shown[part]
        actions = {}

        def changed(kind, on):
            set_kind(kind, on)
            for k, action in actions.items():
                action.setEnabled(not (k in checked and len(checked) == 1))  # one always stays
            update()

        for kind in kinds:
            actions[kind] = action = menu.addAction(kind)
            action.setCheckable(True)
            action.setChecked(kind in checked)
            action.setEnabled(not (kind in checked and len(checked) == 1))
            action.toggled.connect(lambda on, kind=kind: changed(kind, on))
        (menu.exec if hasattr(menu, "exec") else menu.exec_)(button.mapToGlobal(pos))
        if shiboken.isValid(button):
            update()

    button.toggled.connect(toggled)
    if kinds:
        button.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        button.customContextMenuRequested.connect(choose)
    update()
    return button


def plus_icon(color):
    size = 32
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtGui.QPen(color, 3))
    painter.drawLine(16, 6, 16, 26)
    painter.drawLine(6, 16, 26, 16)
    painter.end()
    return QtGui.QIcon(pixmap)


def add_helper_button(panel):
    """Where the bounding radius eye goes when the Point has no helper (a tag made from scratch)."""
    button = QtWidgets.QToolButton()
    button.setAutoRaise(True)
    button.setIcon(plus_icon(button.palette().color(QtGui.QPalette.ButtonText)))
    button.setToolTip("Add the bounding radius helper, sized from these fields")
    button.clicked.connect(panel.add_bounding_radius)
    return button


def play_icon(color):
    size = 32
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtCore.Qt.NoPen)
    painter.setBrush(color)
    painter.drawPolygon(QtGui.QPolygonF([QtCore.QPointF(9, 5), QtCore.QPointF(27, 16), QtCore.QPointF(9, 27)]))
    painter.end()
    return QtGui.QIcon(pixmap)


class PlayerButton(QtWidgets.QToolButton):
    """Opens the Animation Player (player.py) for the animation graph field at key."""

    def __init__(self, panel, key):
        super().__init__()
        self.panel = panel
        self.key = key
        self.setAutoRaise(True)
        self.setIcon(play_icon(self.palette().color(QtGui.QPalette.ButtonText)))
        self.clicked.connect(lambda: panel.open_player(key))
        panel.value_changed.connect(self._value_changed)
        self._update()

    def _problem(self):
        if not ref_path(self.panel.value(self.key)).strip():
            return "set the animation graph first"
        path = self.panel.animation_tag_path(self.key)
        if not path:
            return "the object tag is not inside a tags folder"
        if not os.path.isfile(path):
            return "tag not found:\n" + path
        if self.panel.ref_visibility("model") == 0:
            return "import or link the model first"
        return ""

    def _update(self):
        problem = self._problem()
        self.setEnabled(not problem)
        self.setToolTip("Animation Player" + (": " + problem if problem else ""))

    def _value_changed(self, key):
        if key == self.key:
            self._update()


def ref_edit(panel, key, allowed, accepts):
    """Path without extension, typed or picked with "..."; the group stays in the value and
    export checks it."""
    edit = QtWidgets.QLineEdit(ref_path(panel.value(key)))
    edit.setToolTip("Allowed: " + ", ".join(allowed) if allowed else "Allowed: any tag")

    # Tag type list, only when more than one type is allowed (e.g. the shader types)
    fourccs = [fourcc for _, fourcc in accepts]
    combo = ComboBox() if len(accepts) > 1 else None

    def show_group():
        if combo is not None:
            value = panel.value(key)
            group = value.split(":", 1)[0] if ":" in value else ""
            combo.blockSignals(True)
            combo.setCurrentIndex(fourccs.index(group) if group in fourccs else -1)
            combo.blockSignals(False)

    def pick_group(i):
        if i >= 0:
            panel.set_value(key, fourccs[i] + ":" + ref_path(panel.value(key)))

    if combo is not None:
        combo.addItems([name for name, _ in accepts])
        combo.setSizeAdjustPolicy(QtWidgets.QComboBox.AdjustToMinimumContentsLengthWithIcon)
        combo.setMinimumContentsLength(10)
        combo.setToolTip("Tag type")
        show_group()
        combo.currentIndexChanged.connect(pick_group)

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
        show_group()

    button = QtWidgets.QToolButton()
    button.setText("...")
    button.setToolTip("Browse for a tag")
    button.clicked.connect(browse)
    edit.editingFinished.connect(commit)
    part = eye_part(key)
    if part == "animation":
        buttons = [PlayerButton(panel, key)]
    else:
        buttons = [eye_button(panel, part), link_button(panel, part)] if part else []
    return row_of(buttons + ([combo] if combo is not None else []) + [edit, button])


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
        edit = number_edit(panel, key, None, 1, kind == "angle")
        part = eye_part(key)  # bounding radius: eye for its helper, "+" while there is none
        if not part:
            return edit
        button = eye_button(panel, part) if panel.ref_visibility(part) > 0 else add_helper_button(panel)
        return row_of([button, edit])
    labels = field.get("partLabels")
    if kind in ("floats", "angles"):
        count = field["parts"]
        edits = [number_edit(panel, key, i, count, kind == "angles") for i in range(count)]
        return row_of(with_part_labels(edits, labels))
    if kind == "color":
        return ColorEditor(panel, key, field["parts"], labels)
    if kind == "int":
        return int_spin(panel, key, None, 1, field["min"], field["max"])
    if kind == "ints":
        count = field["parts"]
        spins = [int_spin(panel, key, i, count, -32768, 32767) for i in range(count)]
        return row_of(with_part_labels(spins, labels))
    if kind == "enum":
        return enum_combo(panel, key, field["options"])
    if kind == "flags":
        return flags_box(panel, key, field["options"])
    if kind == "ref":
        return ref_edit(panel, key, field.get("allowed", []), field.get("accepts", []))
    return text_edit(panel, key, field.get("maxLength", 255))
