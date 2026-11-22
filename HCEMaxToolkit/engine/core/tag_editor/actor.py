"""Actor: a tab that lists what an imported actor variant's unit can do (unit states and AI
impulses, per actor mode) with the animation each one plays, as the game picks it
(lua/bridge/actor_ui.lua). Enter or double-click plays it on the unit's bones with the
Animation Player's functions (builders/tag/model_animations/animation_player.ms)."""
import traceback

from pymxs import runtime as rt

from .qt import QtCore, QtGui, QtWidgets
from .fields import ComboBox
from .layout import run_lua_json
from . import player

DOCK_NAME = "HCEActorDock"
DEFAULT_MODE = "stand"  # the stance units start in

# What the game does when the animation is missing
MISSING = {"rest": "no animation: rest pose", "skip": "no animation: does not happen"}
MISSING_TIP = {"rest": "Without its animation the unit enters this state in its rest pose.",
               "skip": "Without its animation the game never starts it."}

GROUP_TIPS = {
    "Unit states": "What the unit's body is doing (standing, moving, landing, melee...).\n"
                   "The game picks one every tick.",
    "AI impulses": "One-shot animations the AI asks for (signals, dodges, dives, surprise).\n"
                   "They only happen when the animation exists.",
}
MODE_TIP = "Actor mode: it picks the stance of the animation graph\n(asleep, alert, stand, crouch, flee, flaming)"


class ActorPanel(player.AnimationPlayerPanel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.data = None
        self.names = []  # animation names as the player lists them
        self.turn = {}  # behavior name -> permutation played last
        self.search.setPlaceholderText("search behaviors...")
        self.in_place_check.setVisible(False)
        self.extract_all_button.setVisible(False)
        self.list.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)
        self.mode = ComboBox()
        self.mode.setToolTip(MODE_TIP)
        self.mode.currentIndexChanged.connect(self._fill)
        self.group = ComboBox()
        self.group.setToolTip("Kind of behavior listed")
        self.group.currentIndexChanged.connect(self._fill)
        self.note = QtWidgets.QLabel()
        self.note.setWordWrap(True)
        self.note.setVisible(False)
        self.layout().insertWidget(2, self.mode)
        self.layout().insertWidget(3, self.group)
        self.layout().insertWidget(4, self.note)
        for widget in (self.mode, self.group, self.note):
            widget.installEventFilter(self)  # Space plays / pauses here too

    def load(self, node, variant_path):
        """Lists the behaviors of the actor variant for its unit's object tag Point."""
        self.node = node
        self.tag_path = variant_path
        self.point_name = str(node.name)
        self.data = None
        self.list.clear()
        self.status.setText("")
        self.title.setText(variant_path.replace("/", "\\").rsplit("\\", 1)[-1])
        self.info.setText("Loading behaviors...")
        QtWidgets.QApplication.processEvents()
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.WaitCursor)
        try:
            data = run_lua_json("bridge.actor_ui", "behaviors", variant_path)
            result = rt.animPlayerOpen(node, data["graphPath"])
            if isinstance(result, str):
                raise RuntimeError(result)
            self.names = [str(name) for name in list(result)[1]]
        except Exception as error:
            traceback.print_exc()
            self.info.setText("Could not load the behaviors: %s" % error)
            return
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()
        self.data = data
        weapon = "%s (%s)" % (data["weapon"], data["weaponLabel"]) if data["weapon"] else "unarmed"
        self.info.setText("Unit: %s\nWeapon: %s\nActor: %s\nAnimations: %s"
                          % (data["unit"], weapon, data["actor"] or "none", data["graph"]))
        self.mode.blockSignals(True)
        self.mode.clear()
        for i, mode in enumerate(data["modes"]):
            self.mode.addItem(mode["name"])
            self.mode.setItemData(i, self._mode_tip(mode), QtCore.Qt.ToolTipRole)
        seats = [mode["seat"] for mode in data["modes"]]
        self.mode.setCurrentIndex(seats.index(DEFAULT_MODE) if DEFAULT_MODE in seats else 0)
        self.mode.blockSignals(False)
        self._fill()

    def _mode_tip(self, mode):
        return "%s\nStance in the animation graph: '%s'" % (mode.get("about") or "", mode["seat"])

    def _behavior_tip(self, behavior, mode):
        lines = [behavior.get("about") or ""]
        if behavior.get("never"):
            return lines[0]
        animations = behavior["animations"] or []
        if not animations:
            lines.append(MISSING_TIP[behavior["missing"]])
        if mode.get("ikMarkers"):
            lines.append("Weapon IK: %s" % ("on" if behavior.get("ik") else "off"))
        if len(animations) > 1:
            lines.append("\nPermutations (each play takes the next one):")
            lines += [a["name"] for a in animations]
        return "\n".join(lines)

    def _fill(self, *args):
        self.list.clear()
        if self.data is None or self.mode.currentIndex() < 0:
            return
        mode = self.data["modes"][self.mode.currentIndex()]
        self.mode.setToolTip("%s\n\n%s" % (self._mode_tip(mode), MODE_TIP))
        self.note.setText(mode.get("note") or "")
        self.note.setVisible(bool(mode.get("note")))
        gray = self.palette().color(QtGui.QPalette.Disabled, QtGui.QPalette.Text)
        behaviors = mode["behaviors"] or []
        # The kinds of this mode, keeping the one picked
        groups = []
        for behavior in behaviors:
            if behavior["group"] not in groups:
                groups.append(behavior["group"])
        picked = self.group.currentText()
        self.group.blockSignals(True)
        self.group.clear()
        self.group.addItems(groups)
        self.group.setCurrentIndex(groups.index(picked) if picked in groups else 0)
        for i, group in enumerate(groups):
            self.group.setItemData(i, GROUP_TIPS.get(group, ""), QtCore.Qt.ToolTipRole)
        self.group.setToolTip(GROUP_TIPS.get(self.group.currentText(), "Kind of behavior listed"))
        self.group.blockSignals(False)
        self.group.setVisible(bool(groups))
        for behavior in behaviors:
            if behavior["group"] != self.group.currentText():
                continue
            animations = behavior["animations"] or []
            if animations:
                text = "%s  ->  %s  (%d frames)" % (behavior["name"], animations[0]["name"],
                                                    animations[0]["frames"])
                if len(animations) > 1:
                    text += "  +%d" % (len(animations) - 1)
            else:
                text = "%s  -  %s" % (behavior["name"], MISSING[behavior["missing"]])
            item = QtWidgets.QListWidgetItem(text)
            item.setData(QtCore.Qt.UserRole, behavior)
            item.setToolTip(self._behavior_tip(behavior, mode))
            if not animations:
                item.setForeground(gray)
            self.list.addItem(item)
        self._filter()

    def _menu(self, pos):
        pass  # nothing to extract here

    def _animation_index(self, animation):
        """1-based index in the player's list: the tag's own, checked by name."""
        i = animation["index"]
        if 0 <= i < len(self.names) and self.names[i] == animation["name"]:
            return i + 1
        return self.names.index(animation["name"]) + 1 if animation["name"] in self.names else 0

    def _apply(self, item):
        behavior = item.data(QtCore.Qt.UserRole)
        if not isinstance(behavior, dict):
            return
        if not self._node_ok():
            self.status.setText("%s is gone from the scene" % self.point_name)
            return
        animations = behavior["animations"] or []
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.WaitCursor)
        try:
            if not animations:
                if behavior["missing"] == "rest":
                    # What the game shows: the model's rest pose
                    rt.animPlayerStop(self.node)
                    self.status.setText("'%s' has no animation: rest pose" % behavior["name"])
                else:
                    self.status.setText("'%s' has no animation: the game never starts it" % behavior["name"])
                return
            turn = (self.turn.get(behavior["name"], -1) + 1) % len(animations)
            self.turn[behavior["name"]] = turn
            animation = animations[turn]
            # The player keeps one tag loaded: ours again when another panel changed it
            if isinstance(rt.animPlayerOpen(self.node, self.data["graphPath"]), str):
                self.status.setText("Could not read the animations (see the Max log)")
                return
            ms = rt.animPlayerApply(self.node, self._animation_index(animation))
            if ms < 0:
                self.status.setText("Could not apply '%s' (see the Max log)" % animation["name"])
                return
            status = "%s: %s" % (behavior["name"], animation["name"])
            # The hands the game holds on the weapon (weapon_ik.ms); not in every state
            mode = self.data["modes"][self.mode.currentIndex()]
            markers = mode.get("ikMarkers") or []
            if behavior.get("ik") and markers:
                done = rt.actorWeaponIk(self.node, "|".join(markers), "|".join(mode.get("ikAttach") or []))
                status += "  (weapon IK: %s)" % (", ".join(markers) if done else "markers not found")
            self.status.setText(status)
            rt.animPlayerPlay(self.loop_button.isChecked(), self.speed.currentIndex() + 1)
        except Exception as error:
            traceback.print_exc()
            self.status.setText("Could not apply it: %s" % error)
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()


def show(node, variant_path, find_beside):
    """Opens the tab beside find_beside(main) (or brings it to the front) and loads the variant."""
    panel = player.open_dock(DOCK_NAME, "Actor", player.PlayerDock, find_beside, ActorPanel)
    QtCore.QTimer.singleShot(0, lambda: panel.load(node, variant_path))
