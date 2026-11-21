"""Read-only numbers of a physics tag: what tool calculates when it loads the tag, and what the
game will do with these values (docs/physics.md). Updated on every edit."""
import math

from .qt import QtCore, QtWidgets
from .fields import to_float, to_int, parts_of

GRAVITY = 0.0035651792  # world units per tick squared
TICKS = 30
METERS = 3.048  # per world unit
# Mass points whose bottom is this close to the lowest one touch the ground at rest
CONTACT = 0.02


def _vector(text):
    return [to_float(p) or 0.0 for p in parts_of(text, 3)]


def mass_points(values):
    """Each mass point with the mass, density and position tool gives it."""
    get = lambda key: values.get(key, "")
    total_mass = to_float(get("mass")) or 0.0
    density = to_float(get("density")) or 0.0
    points = []
    for i in range(max(0, to_int(get("mass points")))):
        prefix = "mass points[%d]." % i
        points.append({
            "name": get(prefix + "name"),
            "relative mass": to_float(get(prefix + "relative mass")) or 0.0,
            "relative density": to_float(get(prefix + "relative density")) or 0.0,
            "position": _vector(get(prefix + "position")),
            "radius": to_float(get(prefix + "radius")) or 0.0,
        })
    sum_mass = sum(p["relative mass"] for p in points)
    sum_volume = sum(p["relative mass"] / p["relative density"] for p in points if p["relative density"] != 0)
    for p in points:
        p["mass"] = total_mass * p["relative mass"] / sum_mass if sum_mass else 0.0
        p["density"] = density * p["relative density"] * sum_volume / sum_mass if sum_mass else 0.0
    return points


def calculate(values):
    get = lambda key: values.get(key, "")
    total_mass = to_float(get("mass")) or 0.0
    moment_scale = to_float(get("moment scale")) or 0.0
    new_physics = (to_float(get("radius")) or 0.0) <= 0
    points = mass_points(values)

    center = [0.0, 0.0, 0.0]
    if total_mass:
        for p in points:
            for a in range(3):
                center[a] += p["mass"] * p["position"][a] / total_mass
    moments = [0.0, 0.0, 0.0]
    for p in points:
        k = moment_scale * p["mass"]
        x, y, z = (p["position"][a] - center[a] for a in range(3))
        sphere = 0.4 * k * p["radius"] ** 2 if new_physics else 0.0
        moments[0] += k * (y * y + z * z) + sphere
        moments[1] += k * (z * z + x * x) + sphere
        moments[2] += k * (x * x + y * y) + sphere

    # Ground contact at rest: the lowest mass points
    bottoms = [p["position"][2] - p["radius"] for p in points]
    contacts = sum(1 for b in bottoms if b <= min(bottoms) + CONTACT) if points else 0
    ground_depth = to_float(get("ground depth")) or 0.0
    damp = to_float(get("ground damp fraction")) or 0.0
    no_bounce = 2 * math.sqrt(GRAVITY / (ground_depth * contacts)) if ground_depth > 0 and contacts else 0.0

    air = to_float(get("air friction")) or 0.0
    fall = GRAVITY * (to_float(get("gravity scale")) or 0.0) / air if air > 0 else None
    water_density = to_float(get("water density")) or 0.0
    water_depth = to_float(get("water depth")) or 0.0
    floating = [p for p in points if water_depth > 0 and 0 < p["density"] < water_density]

    return {
        "points": points, "center": center, "moments": moments, "new physics": new_physics,
        "contacts": contacts, "sink": ground_depth / contacts if contacts else 0.0,
        "no bounce": no_bounce, "damp": damp, "fall": fall, "floating": floating,
        "powered": max(0, to_int(get("powered mass points"))),
    }


def _number(v):
    return "%.4g" % v


def tag_text(values):
    c = calculate(values)
    lines = [
        "<b>Calculated by tool</b> (when it loads the tag; the tag's own values don't matter)",
        "center of mass: %s" % "  ".join(_number(v) for v in c["center"]),
        "xx / yy / zz moment: %s" % "  /  ".join(_number(v) for v in c["moments"]),
    ]
    for p in c["points"]:
        lines.append("&nbsp;&nbsp;%s: mass %s, density %s" % (p["name"] or "?", _number(p["mass"]), _number(p["density"])))

    lines.append("<br><b>In game</b> (approximate)")
    if c["contacts"]:
        bounce = c["damp"] / c["no bounce"] if c["no bounce"] else 0
        feel = "bounces" if bounce < 0.5 else "a little bounce" if bounce < 0.9 else "no bounce"
        lines.append("at rest on %d mass points, each sinks %s" % (c["contacts"], _number(c["sink"])))
        lines.append("ground damp fraction for no bounce: %s (now %s: %s)" % (_number(c["no bounce"]), _number(c["damp"]), feel))
        if c["contacts"] < 3:
            lines.append("fewer than 3 mass points on the ground: it never comes to rest")
    if c["fall"] is not None:
        lines.append("top falling speed: %s wu/s (%s m/s)" % (_number(c["fall"] * TICKS), _number(c["fall"] * TICKS * METERS)))
    else:
        lines.append("air friction 0: no top falling speed")
    lines.append("mass points that float: %d of %d" % (len(c["floating"]), len(c["points"])))
    lines.append("powered mass points: %d (human jeep, human tank and alien fighter need 2, human boat 3)" % c["powered"])
    if not c["new physics"]:
        lines.append("radius > 0: old physics (no sweep against the level)")
    return "<br>".join(lines)


def mass_point_text(values, index):
    points = calculate(values)["points"]
    if not 0 <= index < len(points):
        return ""
    p = points[index]
    water = to_float(values.get("water density", "")) or 0.0
    floats = "floats" if 0 < p["density"] < water else "sinks"
    return ("<b>Calculated by tool</b><br>mass %s (%s%% of the total)<br>density %s: %s in water"
            % (_number(p["mass"]), _number(100 * p["mass"] / (to_float(values.get("mass", "")) or 1)),
               _number(p["density"]), floats))


class CalcLabel(QtWidgets.QLabel):
    """Shows text_of(panel.values) and follows every edit (a method slot: Qt disconnects it when
    the label is deleted)."""

    def __init__(self, panel, text_of):
        super().__init__()
        self.panel = panel
        self.text_of = text_of
        self.setWordWrap(True)
        self.setTextFormat(QtCore.Qt.RichText)
        self.setTextInteractionFlags(QtCore.Qt.TextSelectableByMouse)
        self.setContentsMargins(6, 2, 0, 6)
        panel.value_changed.connect(self.update_text)
        self.update_text()

    def update_text(self, key=None):
        self.setText(self.text_of(self.panel.values))
