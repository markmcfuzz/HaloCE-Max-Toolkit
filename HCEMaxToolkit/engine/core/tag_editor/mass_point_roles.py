"""Role of a mass point (front tire, wing...): a list that sets its powered mass point, friction,
relative density and metallic flag at once, with the values of the stock vehicles."""
import json
import os

from .qt import QtCore
from .fields import ComboBox, to_float, to_int

ROLES_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mass_point_roles.json")
CUSTOM = "Custom"
_roles = None


def all_roles():
    global _roles
    if _roles is None:
        with open(ROLES_PATH, encoding="utf-8") as f:
            _roles = json.load(f)["roles"]
    return _roles


def powered_names(values):
    """Names of the tag's powered mass points, by index."""
    count = to_int(values.get("powered mass points", "0"))
    return [values.get("powered mass points[%d].name" % i, "") for i in range(count)]


def available(values):
    """The roles this tag can use: it has their powered mass point."""
    names = powered_names(values)
    return [r for r in all_roles() if all(n in names for n in (r.get("powered"), r.get("needs")) if n)]


def role_fields(values, prefix, role):
    """Field key -> text the role sets on the mass point at prefix."""
    names = powered_names(values)
    powered = names.index(role["powered"]) if role.get("powered") else -1
    # Bit 0 is metallic; any other bit stays
    flags = (to_int(values.get(prefix + "flags", "0")) & ~1) | role["metallic"]
    return {
        prefix + "powered mass point": str(powered),
        prefix + "flags": str(flags),
        prefix + "relative density": "%g" % role["relative_density"],
        prefix + "friction type": str(role["friction_type"]),
        prefix + "friction parallel scale": "%g" % role["parallel"],
        prefix + "friction perpendicular scale": "%g" % role["perpendicular"],
    }


def matches(values, prefix, role):
    for key, text in role_fields(values, prefix, role).items():
        if abs(to_float(values.get(key, "0")) - float(text)) > 1e-4:
            return False
    return True


class RoleCombo(ComboBox):
    """Shows the role the mass point's fields match, or Custom; picking one sets them."""

    def __init__(self, panel, prefix):
        super().__init__()
        self.panel = panel
        self.prefix = prefix
        self.roles = []
        self.setToolTip("What this mass point is on the vehicle: sets its powered mass point, friction,\n"
                        "relative density and metallic flag with the values of the stock vehicles.")
        self.fill()
        self.activated.connect(self._picked)
        panel.value_changed.connect(self._value_changed)

    def fill(self):
        values = self.panel.values
        self.blockSignals(True)
        self.clear()
        self.roles = available(values)
        current = next((i for i, r in enumerate(self.roles) if matches(values, self.prefix, r)), -1)
        # Custom only while no role fits: it can't be picked to change anything
        if current < 0:
            self.roles = [None] + self.roles
            current = 0
        for i, role in enumerate(self.roles):
            self.addItem(role["label"] if role else CUSTOM)
            if role:
                self.setItemData(i, role["tip"], QtCore.Qt.ToolTipRole)
        self.setCurrentIndex(current)
        self.blockSignals(False)

    def _picked(self, index):
        role = self.roles[index] if 0 <= index < len(self.roles) else None
        if role is None:
            return
        fields = role_fields(self.panel.values, self.prefix, role)
        # Later: storing them rebuilds the panel, and this list with it
        QtCore.QTimer.singleShot(0, lambda panel=self.panel: panel.set_fields(fields))

    def _value_changed(self, key):
        if key.startswith(self.prefix) or key.startswith("powered mass points"):
            self.fill()
