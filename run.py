#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
MeeX Nokia N9 QML Launcher
Runs the MeeX QML interface full-screen using Nokia N9's built-in PySide Qt runtime.
"""
import sys
from PySide.QtGui import QApplication
from PySide.QtDeclarative import QDeclarativeView
from PySide.QtCore import QUrl

def main():
    app = QApplication(sys.argv)
    view = QDeclarativeView()
    view.setSource(QUrl.fromLocalFile("main.qml"))
    view.showFullScreen()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
