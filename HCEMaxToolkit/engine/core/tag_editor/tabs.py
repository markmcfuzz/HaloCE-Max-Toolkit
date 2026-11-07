"""Close buttons (X) on the tabs of the toolkit's docks. Max rebuilds its dock tab bars when
docks move, so the tabs are checked twice per second and the X put back when missing."""
from .qt import QtCore, QtGui, QtWidgets, shiboken, GetQMaxMainWindow

TITLES = ("Halo Tag Editor", "Shaders", "Animation Player", "Model Animations")
BUTTON_NAME = "HCETabCloseButton"

_timer = None


def close_icon(color):
    size = 16
    pixmap = QtGui.QPixmap(size, size)
    pixmap.fill(QtCore.Qt.transparent)
    painter = QtGui.QPainter(pixmap)
    painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtGui.QPen(color, 1.6))
    painter.drawLine(QtCore.QPointF(4.5, 4.5), QtCore.QPointF(11.5, 11.5))
    painter.drawLine(QtCore.QPointF(11.5, 4.5), QtCore.QPointF(4.5, 11.5))
    painter.end()
    return QtGui.QIcon(pixmap)


def _dock(main, title):
    for dock in main.findChildren(QtWidgets.QDockWidget):
        if shiboken.isValid(dock) and dock.windowTitle() == title:
            return dock
    return None


def _close(title):
    # The dock is looked up on click: a reopened one is a new widget
    main = GetQMaxMainWindow()
    dock = _dock(main, title)
    if dock is not None:
        dock.close()


def _close_button(bar, title):
    button = QtWidgets.QToolButton(bar)
    button.setObjectName(BUTTON_NAME)
    button.setAutoRaise(True)
    button.setIcon(close_icon(bar.palette().color(QtGui.QPalette.ButtonText)))
    button.setIconSize(QtCore.QSize(12, 12))
    button.setFixedSize(16, 16)
    button.setToolTip("Close")
    button.setProperty("tab_title", title)
    button.clicked.connect(lambda: _close(title))
    return button


def refresh():
    """Puts the X on our tabs and takes it off tabs Max reused for other docks."""
    main = GetQMaxMainWindow()
    side = QtWidgets.QTabBar.RightSide
    for bar in main.findChildren(QtWidgets.QTabBar):
        if not shiboken.isValid(bar):
            continue
        for i in range(bar.count()):
            title = bar.tabText(i)
            button = bar.tabButton(i, side)
            ours = button is not None and button.objectName() == BUTTON_NAME
            if title in TITLES and _dock(main, title) is not None:
                if not (ours and button.property("tab_title") == title):
                    bar.setTabButton(i, side, _close_button(bar, title))
                    if ours:
                        button.deleteLater()
            elif ours:
                bar.setTabButton(i, side, None)
                button.deleteLater()


def watch():
    """Starts the checks (once per Max session); called when a dock opens."""
    global _timer
    if _timer is None or not shiboken.isValid(_timer):
        _timer = QtCore.QTimer(GetQMaxMainWindow())
        _timer.timeout.connect(refresh)
        _timer.start(500)
    QtCore.QTimer.singleShot(0, refresh)
