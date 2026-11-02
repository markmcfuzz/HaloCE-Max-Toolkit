"""Qt modules of this 3ds Max: PySide6 (2025 and newer) or PySide2 (2023-2024)."""
try:
    from PySide6 import QtCore, QtGui, QtWidgets
    import shiboken6 as shiboken
except ImportError:
    from PySide2 import QtCore, QtGui, QtWidgets
    import shiboken2 as shiboken

from qtmax import GetQMaxMainWindow

__all__ = ["QtCore", "QtGui", "QtWidgets", "shiboken", "GetQMaxMainWindow"]
