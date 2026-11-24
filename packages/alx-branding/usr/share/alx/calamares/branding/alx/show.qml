import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0f172a"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text {
                    text: "Algothix OS (ALX) Lite"
                    color: "#38bdf8"
                    font.pixelSize: 28
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Fast, terminal-first Debian coding OS tuned for 2-4 GB RAM laptops."
                    color: "#e2e8f0"
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0f172a"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text {
                    text: "Developer Ready Out of the Box"
                    color: "#38bdf8"
                    font.pixelSize: 26
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Neovim, tmux, zsh, Git, rootless Podman, and on-demand toolchains via alx-setup."
                    color: "#e2e8f0"
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0f172a"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text {
                    text: "Work Together with ALX Link"
                    color: "#38bdf8"
                    font.pixelSize: 26
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Pair two ALX laptops with alx-link pair for SSH, Syncthing, clipboard, and remote builds."
                    color: "#e2e8f0"
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
