"""Create Physics Tag: lists the templates of lua/generators/templates by category (Lua
generators.physics list) and creates the chosen one's physics with createFromTemplate
(builders/tag/physics/new_from_template.ms), sized to the selected geometry.
For an existing vehicle Point (the tag editor's "+" on its physics), it creates the physics,
links it to that vehicle and fills the vehicle's fields."""
import html
import traceback

from pymxs import runtime as rt

from .qt import QtCore, QtGui, QtWidgets, shiboken, GetQMaxMainWindow
from .fields import ComboBox
from .layout import run_lua_json

TITLE = "Create Physics Tag"
TARGET_NOTE = ("Creates its physics and sets this vehicle's type, speeds, turns and flags from the\n"
               "template (a Stock entry uses that vehicle's exact values); fitted wheels set wheel\n"
               "circumference. Its other fields stay.")
TYPE_TIP = "The .vehicle 'type' this physics needs: the game drives its powered mass points by it."
DEFAULT_WORDS = "tire, wheel"
FIT_TIP = ("Each wheel's mass point goes on the center of a model's wheel, 1.3 times its radius\n"
           "(as the warthog's), with that node as its model node. The wheels are the visible\n"
           "objects (or the selected ones, if any) with one of the wheel names.")
WORDS_TIP = ("Words in the names of the wheels (nodes or meshes), separated by commas.\n"
             "Steering wheels are left out.")

_dialog = None
# What was picked last, kept while Max is open: "category" -> row, label -> entry, template -> option
_last = {}


def details_html(details, palette):
    """The template's summary and its rows (Lua: templateDetails) in two columns."""
    text = palette.color(QtGui.QPalette.WindowText)
    back = palette.color(QtGui.QPalette.Window)
    muted = QtGui.QColor((text.red() * 2 + back.red()) // 3, (text.green() * 2 + back.green()) // 3,
                         (text.blue() * 2 + back.blue()) // 3).name()
    cells = "".join('<tr><td style="color:%s; padding:2px 16px 2px 0;">%s</td><td style="padding:2px 0;">%s</td></tr>'
                    % (muted, html.escape(name), html.escape(value)) for name, value in details["rows"])
    return '<p style="margin-bottom:8px;"><b>%s</b></p><table cellspacing="0">%s</table>' % (
        html.escape(details["summary"]), cells)


class NewPhysicsDialog(QtWidgets.QDialog):
    """target: handle of an existing vehicle Point (the tag editor's "+"), whose name the physics
    takes, or None (Create Physics Tag)."""

    def __init__(self, categories, parent=None, target=None, target_name=""):
        super().__init__(parent)
        self.target = target
        self.title = "Physics for " + target_name if target is not None else TITLE
        self.setWindowTitle(self.title)
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        self.categories = categories
        self.auto_name = ""

        self.category_list = QtWidgets.QListWidget()
        for category in categories:
            self.category_list.addItem(category["label"])
        self.category_list.setFixedWidth(self.category_list.sizeHintForColumn(0) + 24)

        self.choice_label = QtWidgets.QLabel()
        self.entry = ComboBox()
        self.option_label = QtWidgets.QLabel()
        self.option = ComboBox()
        self.description = QtWidgets.QLabel()
        self.description.setTextFormat(QtCore.Qt.RichText)
        self.description.setWordWrap(True)
        self.description.setAlignment(QtCore.Qt.AlignTop | QtCore.Qt.AlignLeft)

        # Wheels of the selection (categories with fit_wheels)
        self.wheels = None  # {"text", "names", "axles", "matches"} found last
        self.fit_check = QtWidgets.QCheckBox("Put the wheels on the model's wheels")
        self.fit_check.setToolTip(FIT_TIP)
        self.fit_check.setChecked(_last.get("fit", True))
        self.wheel_words = QtWidgets.QLineEdit(_last.get("words", DEFAULT_WORDS))
        self.wheel_words.setToolTip(WORDS_TIP)
        self.wheel_status = QtWidgets.QLabel()
        self.wheel_status.setWordWrap(True)
        words_row = QtWidgets.QHBoxLayout()
        words_row.addWidget(QtWidgets.QLabel("Wheel names"))
        words_row.addWidget(self.wheel_words, 1)
        self.fit_box = QtWidgets.QWidget()
        fit_layout = QtWidgets.QVBoxLayout(self.fit_box)
        fit_layout.setContentsMargins(0, 4, 0, 0)
        fit_layout.addWidget(self.fit_check)
        fit_layout.addLayout(words_row)
        fit_layout.addWidget(self.wheel_status)

        choices = QtWidgets.QGridLayout()
        choices.addWidget(self.choice_label, 0, 0)
        choices.addWidget(self.entry, 0, 1)
        choices.addWidget(self.option_label, 1, 0)
        choices.addWidget(self.option, 1, 1)
        choices.setColumnStretch(1, 1)
        right = QtWidgets.QVBoxLayout()
        right.addLayout(choices)
        right.addWidget(self.description, 1)
        right.addWidget(self.fit_box)
        top = QtWidgets.QHBoxLayout()
        top.addWidget(self.category_list)
        top.addLayout(right, 1)

        self.size_label = QtWidgets.QLabel()
        self.type_label = QtWidgets.QLabel()
        self.type_label.setToolTip(TYPE_TIP)
        self.name = QtWidgets.QLineEdit()
        name_row = QtWidgets.QHBoxLayout()
        name_row.addWidget(QtWidgets.QLabel("Name"))
        name_row.addWidget(self.name, 1)
        targeted = target is not None
        # The "+" also fills its vehicle
        self.target_note = QtWidgets.QLabel(TARGET_NOTE)
        self.target_note.setVisible(targeted)
        self.create_button = QtWidgets.QPushButton("Create")
        self.create_button.setDefault(True)
        button_row = QtWidgets.QHBoxLayout()
        button_row.addStretch(1)
        button_row.addWidget(self.create_button)
        # The new physics takes the vehicle's name
        if targeted:
            self.name.setText(target_name.rsplit(".", 1)[0])
        self.name.setEnabled(not targeted)

        layout = QtWidgets.QVBoxLayout(self)
        layout.addLayout(top, 1)
        layout.addWidget(self.size_label)
        layout.addWidget(self.type_label)
        layout.addLayout(name_row)
        layout.addWidget(self.target_note)
        layout.addLayout(button_row)
        self.resize(540, 470)

        self.category_list.currentRowChanged.connect(self._fill_entries)
        self.entry.currentIndexChanged.connect(self._fill_options)
        self.option.currentIndexChanged.connect(self._option_changed)
        self.fit_check.toggled.connect(self._fit_toggled)
        self.wheel_words.editingFinished.connect(self._words_changed)
        self.create_button.clicked.connect(lambda: QtCore.QTimer.singleShot(0, self._create))

        row = _last.get("category", 0)
        self.category_list.setCurrentRow(row if 0 <= row < len(categories) else 0)

    # Selection

    def _category(self):
        return self.categories[max(self.category_list.currentRow(), 0)]

    def _entry(self):
        entries = self._category()["entries"]
        return entries[max(self.entry.currentIndex(), 0)]

    def _fill_entries(self, row):
        if row < 0:
            return
        _last["category"] = row
        category = self.categories[row]
        self.choice_label.setText(category["choice"])
        self.entry.blockSignals(True)
        self.entry.clear()
        for entry in category["entries"]:
            self.entry.addItem(entry["label"])
        index = _last.get(category["label"], 0)
        self.entry.setCurrentIndex(index if 0 <= index < self.entry.count() else 0)
        self.entry.blockSignals(False)
        self.fit_box.setVisible(category.get("fit_wheels", False))
        self.wheels = None
        self._fill_options(self.entry.currentIndex())
        self._refresh_wheels(pick=True)

    def _fill_options(self, index):
        if index < 0:
            return
        _last[self._category()["label"]] = index
        entry = self._entry()
        options = entry.get("options")
        self.option.blockSignals(True)
        self.option.clear()
        if options:
            self.option_label.setText(options["label"])
            for item in options["items"]:
                self.option.addItem(item["label"], item["name"])
            picked = self.option.findData(_last.get(entry["template"], options["default"]))
            self.option.setCurrentIndex(max(picked, 0))
        self.option.blockSignals(False)
        for widget in (self.option_label, self.option):
            widget.setVisible(bool(options))
        self.type_label.setText("Vehicle type: " + entry["vehicle_type"])
        # The name follows the template until it is typed
        if self.name.text().strip() in ("", self.auto_name):
            self.auto_name = "new_" + entry["name"]
            self.name.setText(self.auto_name)
        self._show_description()
        if self.isVisible():
            self._show_size()

    def _option_changed(self, index):
        options = self._entry().get("options")
        if options and index >= 0:
            _last[self._entry()["template"]] = self.option.itemData(index)
        self._show_description()

    def _option_item(self):
        options = self._entry().get("options")
        if not options or self.option.currentIndex() < 0:
            return None
        return options["items"][self.option.currentIndex()]

    def _show_description(self):
        details = (self._option_item() or self._entry())["details"]
        self.description.setText(details_html(details, self.palette()))
        self._fit_description()
        self._show_wheel_status()

    def _fit_description(self):
        """Never cuts the list: the dialog grows when it needs more room (bigger fonts or DPI)."""
        if self.isVisible():
            self.description.setMinimumHeight(self.description.heightForWidth(self.description.width()))

    # Wheels of the visible objects (or the selection): found by name in Max (newPhysicsWheels), grouped in axles
    # and matched to the templates by Lua (generators.physics fit)

    def _fitting(self):
        return self._category().get("fit_wheels", False) and self.fit_check.isChecked()

    def _refresh_wheels(self, pick=False):
        """Finds the wheels again; pick: when they changed, shows the template that fits them."""
        if not self._fitting():
            self.wheels = None
            self._show_wheel_status()
            return
        previous = self.wheels["text"] if self.wheels else None
        found = {"text": "", "names": [], "axles": [], "matches": []}
        try:
            text, names = list(rt.newPhysicsWheels(self.wheel_words.text()))
            found["text"], found["names"] = str(text), [str(name) for name in names]
            if found["text"]:
                fit = run_lua_json("generators.physics", "fit", found["text"])
                found["axles"], found["matches"] = list(fit["axles"] or []), list(fit["matches"] or [])
        except Exception:
            print(traceback.format_exc())
        self.wheels = found
        if pick and found["text"] and found["text"] != previous:
            self._pick_match()
        self._show_wheel_status()

    def _current_fits(self):
        if not self.wheels:
            return False
        entry = self._entry()
        item = self._option_item()
        option = entry["option"] or (item["name"] if item else "")
        return any(m["template"] == entry["template"] and m["option"] == option for m in self.wheels["matches"])

    def _pick_match(self):
        """Shows the first entry (and option) that fits the wheels, unless the current one does."""
        if self._current_fits():
            return
        for match in self.wheels["matches"]:
            for index, entry in enumerate(self._category()["entries"]):
                if entry["template"] != match["template"]:
                    continue
                if entry["option"] and entry["option"] != match["option"]:
                    continue
                self.entry.setCurrentIndex(index)
                if not entry["option"] and match["option"]:
                    self.option.setCurrentIndex(max(self.option.findData(match["option"]), 0))
                return

    def _show_wheel_status(self):
        if not hasattr(self, "wheel_status"):
            return
        self.wheel_words.setEnabled(self.fit_check.isChecked())
        wheels = self.wheels
        if not self._fitting():
            text = "Wheels go by the template's proportions."
        elif not wheels or not wheels["names"]:
            text = ("No wheels in the %s (names with: %s): they go by the template's proportions."
                    % (self._source_text(), self.wheel_words.text()))
        else:
            text = "Found %d wheels in the %s, axles front to back: %s." % (
                len(wheels["names"]), self._source_text(), ", ".join(str(int(n)) for n in wheels["axles"]))
            if self._current_fits():
                text += " The mass points go on them."
            else:
                text += (" This template doesn't fit them: they go by its proportions.\nWheels: %s"
                         % ", ".join(wheels["names"]))
        self.wheel_status.setText(text)
        self.wheel_status.setToolTip("\n".join(wheels["names"]) if wheels and wheels["names"] else "")

    def _fit_toggled(self, checked):
        _last["fit"] = checked
        self._refresh_wheels(pick=True)

    def _words_changed(self):
        _last["words"] = self.wheel_words.text()
        self.wheels = None
        self._refresh_wheels(pick=True)

    # Size of the selection (or of the visible objects when nothing is selected), shown whenever
    # the dialog comes back to the front

    def _source_text(self):
        return "selection" if getattr(self, "selected", False) else "visible objects"

    def _show_size(self):
        if self._entry().get("stock"):
            self.size_label.setText("Size: as the original tag (Fit to Model adapts it later)")
            return
        try:
            count, low, high, selected = list(rt.newPhysicsSourceBox())
        except Exception:
            self.size_label.setText("Size: unknown (see the log)")
            print(traceback.format_exc())
            return
        self.selected = bool(selected)
        if int(count) > 0:
            size = (high.x - low.x, high.y - low.y, high.z - low.z)
            kind = "selected" if self.selected else "visible"
            self.size_label.setText("Size: %d %s objects (%.2f x %.2f x %.2f wu)" % ((int(count), kind) + size))
        else:
            self.size_label.setText("Size: template default (nothing visible or selected)")

    def showEvent(self, event):
        super().showEvent(event)
        self._show_size()
        self._show_wheel_status()
        # Once laid out, when the list knows its width
        QtCore.QTimer.singleShot(0, self._fit_description)

    def changeEvent(self, event):
        super().changeEvent(event)
        if event.type() == QtCore.QEvent.ActivationChange and self.isActiveWindow():
            self._show_size()
            self._refresh_wheels(pick=True)

    # Create

    def _create(self):
        entry = self._entry()
        item = self._option_item()
        option = entry["option"] or (item["name"] if item else "")
        name = self.name.text().strip() or "new_" + entry["name"]
        # The wheels as they are now; only when this template fits them
        self._refresh_wheels()
        wheels = self.wheels["text"] if self._fitting() and self._current_fits() else ""
        target = None
        if self.target is not None:
            target = rt.maxOps.getNodeByHandle(self.target)
            if target is None:
                QtWidgets.QMessageBox.warning(self, self.title, "The vehicle is no longer in the scene.")
                return
        try:
            # Kept on the physics for Fit to Model: "" when its wheels don't go on the model's
            words = self.wheel_words.text() if self._fitting() or entry.get("stock_wheels") else ""
            point = rt.createFromTemplate(entry["template"], option, name, wheels, words, target)
        except Exception:
            print(traceback.format_exc())
            point = None
        if point is None:
            QtWidgets.QMessageBox.warning(self, self.title, "Could not create the tag! See the log for details.")
            return
        self.close()
        # Once the dialog is gone, or the new spheres only show after the next click
        QtCore.QTimer.singleShot(0, rt.redrawViews)


def show(target=None):
    """Create Physics Tag (tool_new_physics.ms), or the tag editor's "+" on a vehicle's physics
    (target: the vehicle Point)."""
    global _dialog
    if _dialog is not None and shiboken.isValid(_dialog):
        _dialog.close()
    main = GetQMaxMainWindow()
    try:
        categories = run_lua_json("generators.physics", "list")["categories"]
    except Exception as error:
        QtWidgets.QMessageBox.warning(main, TITLE, "Could not read the physics templates:\n%s" % error)
        return
    handle, target_name = None, ""
    if target is not None:
        handle, target_name = int(target.inode.handle), str(target.name)
    _dialog = NewPhysicsDialog(categories, main, handle, target_name)
    _dialog.show()
    _dialog.raise_()
