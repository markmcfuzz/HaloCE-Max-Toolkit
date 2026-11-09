"""Animation Preview section of the Shaders tab: GlyphFX preview switch and A-D Out sliders on
the materials of an object tag Point or a mesh (builders\\tag\\shared\\shader_animation.ms).
Saved in the scene, not in the tag."""
from pymxs import runtime as rt

from .qt import QtCore, QtWidgets, shiboken

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

    loop = QtWidgets.QCheckBox("Loop to Timeline")
    loop.setChecked(bool(rt.shaderAnimationLoopOn()))
    loop.setToolTip("Every shader of the scene loops with the timeline, without a jump: cosine,"
                    " diagonal wave and slide run a bit faster or slower than in game. Follows"
                    " timeline changes. Random functions are unchanged")
    loop.toggled.connect(lambda on: loop_to_timeline(loop, on))
    form.addRow(loop)

    fit = QtWidgets.QPushButton("Fit Timeline to Shader Animation")
    fit.setToolTip("Sets the timeline to the longest shader animation of the scene, at game speed"
                   " (or a few of its cycles, so the rest change speed 5% at most), and turns"
                   " Loop to Timeline on")
    fit.clicked.connect(lambda checked=False: fit_timeline(loop))
    form.addRow(fit)

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


def loop_to_timeline(check, on):
    """Turns Loop to Timeline on or off on every GlyphFX material of the scene."""
    if int(rt.setShaderAnimationLoop(on)) == 0 and on:
        check.blockSignals(True)
        check.setChecked(False)
        check.blockSignals(False)
        QtWidgets.QMessageBox.information(check.window(), "Loop to Timeline",
                                          "No shader in the scene supports it yet: it needs a"
                                          " GlyphFX effect with Animation Loop Length.")


def fit_timeline(loop):
    """Fits the timeline to the scene's shader animations and says how long it is."""
    parent = loop.window()  # the dock: the section may be rebuilt
    frames, count, error = list(rt.fitTimelineToShaderAnimation())
    frames, count = int(frames), int(count)
    if frames == 0:
        QtWidgets.QMessageBox.information(parent, "Fit Timeline to Shader Animation",
                                          "No shader animation with a cycle in the scene (Animation"
                                          " Preview on). Random functions have none.")
        return
    if shiboken.isValid(loop):
        loop.blockSignals(True)
        loop.setChecked(True)
        loop.blockSignals(False)
    QtWidgets.QMessageBox.information(
        parent, "Fit Timeline to Shader Animation",
        "%d frames (%.2f s), %d shader(s). Largest speed change from the game: %.1f%%."
        % (frames, frames / float(rt.frameRate), count, float(error) * 100))
