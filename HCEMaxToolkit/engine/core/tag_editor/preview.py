"""Animation Preview section of the Shaders tab: GlyphFX preview switch and A-D Out sliders on
the materials of an object tag Point or a mesh (builders\\tag\\shared\\shader_animation.ms).
Saved in the scene, not in the tag."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets

TITLE = "Animation Preview"
OUTS = ["A", "B", "C", "D"]


def preview_box(node):
    """Built when the section opens; reads the materials again."""
    widget = QtWidgets.QWidget()
    form = QtWidgets.QFormLayout(widget)
    form.setContentsMargins(6, 2, 0, 2)
    state = rt.tagEditorPreviewState(node)
    if state is None:
        form.addRow(QtWidgets.QLabel("No GlyphFX materials with Animation Preview"))
        return widget
    state = list(state)

    def set_param(name, value):
        if rt.isValidNode(node):
            rt.tagEditorSetPreview(node, name, value)

    check = QtWidgets.QCheckBox("Animation Preview")
    check.setChecked(bool(state[0]))
    check.setToolTip("Plays the shaders' animations with the timeline")
    check.toggled.connect(lambda on: set_param("AnimationPreview", on))
    form.addRow(check)

    for i, out in enumerate(OUTS):
        slider = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        slider.setRange(0, 100)
        slider.setValue(int(round(float(state[i + 1]) * 100)))
        slider.setToolTip("Stands in for the object's %s Out function (e.g. recent shield damage);"
                          " 0 = idle" % out)
        value = QtWidgets.QLabel("%.2f" % (slider.value() / 100.0))
        value.setMinimumWidth(30)

        def moved(v, name="ObjectFunction" + out, value=value):
            value.setText("%.2f" % (v / 100.0))
            set_param(name, v / 100.0)

        slider.valueChanged.connect(moved)
        row = QtWidgets.QHBoxLayout()
        row.addWidget(slider, 1)
        row.addWidget(value)
        form.addRow("%s Out" % out, row)
    return widget
