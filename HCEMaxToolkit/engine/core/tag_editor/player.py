"""Animation Player: a tab next to the tag editor that lists the animations of an object's
animation graph and puts the picked one as keys on its model's bones. The work is done by
builders/tag/model_animations/animation_player.ms (animPlayerOpen, animPlayerApply, animPlayerStop).
The same panel is Import > Tag > Model Animations (show_scene): node None, the scene bones."""
import traceback

from pymxs import runtime as rt

from .qt import QtCore, QtGui, QtWidgets, shiboken, GetQMaxMainWindow
from .fields import ComboBox
from . import tabs

DOCK_NAME = "HCEAnimationPlayerDock"
IMPORT_DOCK_NAME = "HCEModelAnimationsDock"
EDITOR_DOCK_NAME = "HCETagEditorDock"  # see __init__.py

# Max's real-time playback speeds (timeConfiguration.playbackSpeed 1 to 5)
SPEEDS = ["¼×", "½×", "1×", "2×", "4×"]

# Open panels by dock name
_panels = {}


def media_icon(kind, color):
    """Drawn here so no image files are needed: play, pause, stop or loop."""
    size = 32
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtCore.Qt.NoPen)
    painter.setBrush(color)
    if kind == "play":
        painter.drawPolygon(QtGui.QPolygonF([QtCore.QPointF(9, 5), QtCore.QPointF(27, 16), QtCore.QPointF(9, 27)]))
    elif kind == "pause":
        painter.drawRect(QtCore.QRectF(8, 6, 6, 20))
        painter.drawRect(QtCore.QRectF(18, 6, 6, 20))
    elif kind == "stop":
        painter.drawRect(QtCore.QRectF(8, 8, 16, 16))
    else:
        # Loop: a circle with an arrow head
        painter.setBrush(QtCore.Qt.NoBrush)
        painter.setPen(QtGui.QPen(color, 3))
        painter.drawArc(QtCore.QRectF(6, 6, 20, 20), 30 * 16, 300 * 16)
        painter.setPen(QtCore.Qt.NoPen)
        painter.setBrush(color)
        painter.drawPolygon(QtGui.QPolygonF([QtCore.QPointF(20, 2), QtCore.QPointF(29, 9), QtCore.QPointF(19, 13)]))
    painter.end()
    return QtGui.QIcon(pixmap)


def tool_button(icon, tip):
    button = QtWidgets.QToolButton()
    button.setAutoRaise(True)
    button.setIcon(icon)
    button.setIconSize(QtCore.QSize(18, 18))
    button.setToolTip(tip)
    return button


class AnimationPlayerPanel(QtWidgets.QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.node = None
        self.tag_path = ""
        self.point_name = ""
        self.playing = False
        color = self.palette().color(QtGui.QPalette.ButtonText)
        self.icons = {kind: media_icon(kind, color) for kind in ("play", "pause", "stop", "loop")}
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        self.title = QtWidgets.QLabel()
        self.title.setStyleSheet("font-weight: bold;")
        self.info = QtWidgets.QLabel()
        self.info.setWordWrap(True)
        self.search = QtWidgets.QLineEdit()
        self.search.setPlaceholderText("search animations...")
        self.search.setClearButtonEnabled(True)
        self.search.textChanged.connect(self._filter)
        self.list = QtWidgets.QListWidget()
        # A click only selects (Ctrl / Shift: several, to extract); Enter or double-click plays
        self.list.setSelectionMode(QtWidgets.QAbstractItemView.ExtendedSelection)
        self.list.itemActivated.connect(self._apply)
        self.list.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.list.customContextMenuRequested.connect(self._menu)
        self.count = QtWidgets.QLabel()
        self.count.setAlignment(QtCore.Qt.AlignRight)
        self.count.setEnabled(False)
        # Controls on Max's own timeline, so its time slider and play button stay in step
        self.play_button = tool_button(self.icons["play"], "Play")
        self.play_button.clicked.connect(self._play_pause)
        self.stop_button = tool_button(self.icons["stop"],
                                       "Stop: removes the animation keys and puts the bones back in\n"
                                       "the pose they had before the player first played on them")
        self.stop_button.clicked.connect(self._stop)
        self.loop_button = tool_button(self.icons["loop"], "Loop")
        self.loop_button.setCheckable(True)
        self.loop_button.setChecked(True)
        self.loop_button.toggled.connect(self._playback_changed)
        self.speed = ComboBox()
        self.speed.addItems(SPEEDS)
        self.speed.setCurrentIndex(2)
        self.speed.setToolTip("Playback speed")
        self.speed.currentIndexChanged.connect(self._playback_changed)
        self.frame_label = QtWidgets.QLabel("0 / 0")
        self.frame_label.setToolTip("Frame / last frame")
        self.frame_label.setAlignment(QtCore.Qt.AlignRight | QtCore.Qt.AlignVCenter)
        # Room for 4 digits each, so the row doesn't jump while playing
        self.frame_label.setMinimumWidth(self.frame_label.fontMetrics().horizontalAdvance("0000 / 0000") + 4)
        self.slider = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        self.slider.valueChanged.connect(self._slider_moved)
        self.status = QtWidgets.QLabel()
        self.status.setEnabled(False)
        layout.addWidget(self.title)
        layout.addWidget(self.info)
        layout.addWidget(self.search)
        layout.addWidget(self.list, 1)
        layout.addWidget(self.count)
        row = QtWidgets.QHBoxLayout()
        for widget in (self.play_button, self.stop_button, self.loop_button, self.speed):
            row.addWidget(widget)
        row.addStretch(1)
        row.addWidget(self.frame_label)
        layout.addLayout(row)
        layout.addWidget(self.slider)
        layout.addWidget(self.status)
        # Follows Max's time a few times per second (also when it plays or is scrubbed there)
        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self._poll)
        self.timer.start(50)
        # Space plays / pauses anywhere in the panel but the search box
        for widget in [self] + self.findChildren(QtWidgets.QWidget):
            if widget is not self.search and widget.parent() is not self.search:
                widget.installEventFilter(self)

    def eventFilter(self, watched, event):
        if event.type() in (QtCore.QEvent.ShortcutOverride, QtCore.QEvent.KeyPress) \
                and event.key() == QtCore.Qt.Key_Space and event.modifiers() == QtCore.Qt.NoModifier:
            # Accepting the override keeps Max's own Space hotkey from taking it
            if event.type() == QtCore.QEvent.ShortcutOverride:
                event.accept()
            elif not event.isAutoRepeat():
                self._play_pause()
            return True
        return super().eventFilter(watched, event)

    def _node_ok(self):
        if self.node is None:  # the scene bones
            return True
        try:
            return bool(rt.isValidNode(self.node))
        except Exception:
            return False

    def load(self, node, tag_path):
        """Lists the animations of tag_path for the object tag Point node, or for the scene
        bones when node is None (decoded once)."""
        self.node = node
        self.tag_path = tag_path
        self.point_name = "the scene" if node is None else str(node.name)
        self.list.clear()
        self.status.setText("")
        self.title.setText(tag_path.replace("/", "\\").rsplit("\\", 1)[-1] if tag_path else "Animation Player")
        self.info.setText("Loading animations...")
        QtWidgets.QApplication.processEvents()
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.WaitCursor)
        try:
            result = rt.animPlayerOpen(node, tag_path)
            if not isinstance(result, str):
                tag_name, names, exts, frames, found, total = list(result)
        except Exception as error:
            # Shown here and in the Listener, instead of a panel stuck on "Loading"
            traceback.print_exc()
            result = "Could not load the animations: %s" % error
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()
        if isinstance(result, str):
            self.info.setText(result)
            self._filter()
            return
        self.title.setText(str(tag_name))
        # "17 of 19" only when the model lacks some animated bones
        where = "in the scene" if node is None else "of %s" % self.point_name
        bones = "%d bones %s" % (total, where) if found == total \
            else "%d of %d bones %s" % (found, total, where)
        if found == 0:
            model = "the scene" if node is None else "%s's model" % self.point_name
            bones = "None of the %d animated bones are in %s" % (total, model)
        self.info.setText("%s\n%d animations of %s" % (bones, len(names), tag_name))
        for i, (name, ext, frame_count) in enumerate(zip(names, exts, frames)):
            item = QtWidgets.QListWidgetItem("%s  (%s · %d frames)" % (name, ext, frame_count))
            item.setData(QtCore.Qt.UserRole, i + 1)  # 1-based, as in MAXScript
            if frame_count == 0:
                item.setFlags(item.flags() & ~QtCore.Qt.ItemIsEnabled)
                item.setToolTip("Could not be read (see the Max log)")
            self.list.addItem(item)
        self._filter()

    def _filter(self):
        words = self.search.text().lower().split()
        shown = 0
        for row in range(self.list.count()):
            item = self.list.item(row)
            hidden = not all(w in item.text().lower() for w in words)
            item.setHidden(hidden)
            shown += 0 if hidden else 1
        # Only while searching: the total is in the info above
        total = self.list.count()
        self.count.setVisible(shown != total)
        self.count.setText("%d of %d found" % (shown, total))

    def _picked(self):
        return [item for item in self.list.selectedItems()
                if not item.isHidden() and item.flags() & QtCore.Qt.ItemIsEnabled]

    def _menu(self, pos):
        items = self._picked()
        if not items:
            return
        what = "animation" if len(items) == 1 else "%d animations" % len(items)
        menu = QtWidgets.QMenu(self)
        to_data = menu.addAction("Extract %s to data folder" % what)
        to_data.setToolTip(str(rt.animPlayerDataFolder(self.tag_path) or ""))
        menu.setToolTipsVisible(True)
        menu.addAction("Extract %s to..." % what)
        chosen = menu.exec_(self.list.viewport().mapToGlobal(pos))
        if chosen is not None:
            self._extract(items, chosen is to_data)

    def _extract(self, items, to_data):
        indices = ",".join(str(item.data(QtCore.Qt.UserRole)) for item in items)
        what = "1 animation" if len(items) == 1 else "%d animations" % len(items)
        if to_data:  # "to..." opens a folder dialog first
            QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.WaitCursor)
        try:
            folder = rt.animPlayerExtract(self.tag_path, indices, to_data)
            if folder is None:
                self.status.setText("Could not extract (see the Max log)")
            elif folder:
                # Long paths are cut in the middle; the full one is in the tooltip
                text = "Extracted %s to %s" % (what, folder)
                metrics = self.status.fontMetrics()
                self.status.setText(metrics.elidedText(text, QtCore.Qt.ElideMiddle, self.width() - 12))
                self.status.setToolTip(str(folder))
        except Exception as error:
            traceback.print_exc()
            self.status.setText("Could not extract: %s" % error)
        finally:
            if to_data:
                QtWidgets.QApplication.restoreOverrideCursor()

    def _apply(self, item):
        if not self._node_ok():
            self.status.setText("%s is gone from the scene" % self.point_name)
            return
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.WaitCursor)
        try:
            self.status.setToolTip("")
            ms = rt.animPlayerApply(self.node, item.data(QtCore.Qt.UserRole))
            self.status.setText("Could not apply it (see the Max log)" if ms < 0 else "Applied in %d ms" % ms)
            if ms >= 0:
                rt.animPlayerPlay(self.loop_button.isChecked(), self.speed.currentIndex() + 1)
        except Exception as error:
            traceback.print_exc()
            self.status.setText("Could not apply it: %s" % error)
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()

    def _poll(self):
        if not self.isVisible():
            return
        try:
            frame, first, last, playing = list(rt.animPlayerTimeState())
        except Exception:
            return
        if not self.slider.isSliderDown():
            self.slider.blockSignals(True)
            self.slider.setRange(first, last)
            self.slider.setValue(frame)
            self.slider.blockSignals(False)
        self.frame_label.setText("%d / %d" % (frame - first, last - first))
        playing = bool(playing)
        if playing != self.playing:
            self.playing = playing
            self.play_button.setIcon(self.icons["pause" if playing else "play"])
            self.play_button.setToolTip("Pause" if playing else "Play")

    def _play_pause(self):
        try:
            if self.playing:
                rt.animPlayerPause()
            else:
                rt.animPlayerPlay(self.loop_button.isChecked(), self.speed.currentIndex() + 1)
        except Exception as error:
            traceback.print_exc()
            self.status.setText("Could not play: %s" % error)
        self._poll()

    def _playback_changed(self, *args):
        rt.animPlayerSetPlayback(self.loop_button.isChecked(), self.speed.currentIndex() + 1)

    def _slider_moved(self, frame):
        rt.animPlayerSetFrame(frame)
        self._poll()

    def _stop(self):
        if not self._node_ok():
            self.status.setText("%s is gone from the scene" % self.point_name)
            return
        try:
            restored = rt.animPlayerStop(self.node)
            self.status.setText("Back to the pose before playing" if restored else "Nothing to restore")
        except Exception as error:
            traceback.print_exc()
            self.status.setText("Could not stop: %s" % error)
        self.list.clearSelection()


class PlayerDock(QtWidgets.QDockWidget):
    def closeEvent(self, event):
        # Closing is a Stop for every Point it played on: no animation keys are left behind
        try:
            rt.animPlayerStopAll()
        except Exception:
            traceback.print_exc()
        super().closeEvent(event)


class ImportDock(QtWidgets.QDockWidget):
    def closeEvent(self, event):
        # Import > Tag > Model Animations: the keys stay on the scene bones
        try:
            rt.animPlayerKeepScene()
        except Exception:
            traceback.print_exc()
        super().closeEvent(event)


def _dock(main, name):
    for dock in main.findChildren(QtWidgets.QDockWidget, name):
        if shiboken.isValid(dock):
            return dock
    return None


def _open(name, title, dock_class, find_beside):
    """The panel of dock name, made as a tab beside find_beside(main) (right side when it's
    floating or None) the first time; brought to the front."""
    main = GetQMaxMainWindow()
    panel = _panels.get(name)
    if panel is None or not shiboken.isValid(panel):
        # Looked up with this main: docks found through another (freed) main are deleted wrappers
        beside = find_beside(main)
        dock = dock_class(title, main)
        dock.setObjectName(name)
        dock.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        dock.setMinimumWidth(320)
        panel = AnimationPlayerPanel(dock)
        dock.setWidget(panel)
        _panels[name] = panel
        if beside is not None and not beside.isFloating():
            main.addDockWidget(main.dockWidgetArea(beside), dock)
            main.tabifyDockWidget(beside, dock)
        else:
            main.addDockWidget(QtCore.Qt.RightDockWidgetArea, dock)
    dock = panel.parent()
    dock.show()
    dock.raise_()
    tabs.watch()
    return panel


def show(node, tag_path):
    """Opens the tab beside the tag editor (or brings it to the front) and loads the tag."""
    panel = _open(DOCK_NAME, "Animation Player", PlayerDock, lambda main: _dock(main, EDITOR_DOCK_NAME))
    # After the tab shows: loading the first time takes about a second
    QtCore.QTimer.singleShot(0, lambda: panel.load(node, tag_path))


def show_scene(tag_path, find_command_panel):
    """Import > Tag > Model Animations: the tag's animations for the scene bones, in a tab
    beside the Command Panel (find_command_panel(main))."""
    panel = _open(IMPORT_DOCK_NAME, "Model Animations", ImportDock, find_command_panel)
    QtCore.QTimer.singleShot(0, lambda: panel.load(None, tag_path))
