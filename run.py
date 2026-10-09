import os
import sys
from PySide.QtGui import QApplication
from PySide.QtDeclarative import QDeclarativeView
from PySide.QtCore import QUrl

def main():
    app = QApplication(sys.argv)
    view = QDeclarativeView()
    
    # Tam ekran ve koordinat kaymasini onlemek icin gorunumu ekrana kitle
    view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    qml_path = "/opt/MeeX/main.qml"
    if not os.path.exists(qml_path):
        qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "main.qml")
    if not os.path.exists(qml_path):
        qml_path = "/home/user/main.qml"

    view.setSource(QUrl.fromLocalFile(qml_path))

    for err in view.errors():
        print("QML Hatasi:", err.toString())

    view.showFullScreen()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
