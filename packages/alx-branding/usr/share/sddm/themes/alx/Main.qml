import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1366
    height: 768
    color: config.backgroundColor || "#0B0D10"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string errorMessage: ""
    property string currentTime: Qt.formatTime(new Date(), "HH:mm")
    property string currentDate: Qt.formatDate(new Date(), "ddd, yyyy-MM-dd")

    // Static PNG ASCII "ALX" wallpaper (no blur, no shader effects, no GPU animations)
    Image {
        anchors.fill: parent
        source: config.background || "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: false
        asynchronous: false
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            root.currentTime = Qt.formatTime(now, "HH:mm")
            root.currentDate = Qt.formatDate(now, "ddd, yyyy-MM-dd")
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.errorMessage = "Authentication failed. Try again."
            passwordInput.text = ""
            passwordInput.focus = true
        }
        function onLoginSucceeded() {
            root.errorMessage = ""
        }
    }

    // Centered 320px login card
    Rectangle {
        id: card
        width: 320
        height: cardColumn.implicitHeight + 48
        anchors.centerIn: parent
        color: config.cardColor || "#13171D"
        border.color: config.borderColor || "#1F2630"
        border.width: 1
        radius: 4

        Column {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 12

            // JetBrains Mono clock
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.currentTime
                color: config.textColor || "#E6EDF3"
                font.family: config.fontFamily || "JetBrains Mono"
                font.pixelSize: 34
                font.bold: true
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.currentDate + "  //  ALX LITE"
                color: config.mutedColor || "#8B949E"
                font.family: config.fontFamily || "JetBrains Mono"
                font.pixelSize: 11
            }

            Rectangle {
                width: parent.width
                height: 1
                color: config.borderColor || "#1F2630"
            }

            // Username field
            Text {
                text: "USERNAME"
                color: config.mutedColor || "#8B949E"
                font.family: config.fontFamily || "JetBrains Mono"
                font.pixelSize: 10
            }

            Rectangle {
                width: parent.width
                height: 36
                color: config.backgroundColor || "#0B0D10"
                border.color: userInput.activeFocus ? (config.accentColor || "#3DDC97") : (config.borderColor || "#1F2630")
                border.width: 1
                radius: 2

                TextInput {
                    id: userInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: userModel.lastUser || ""
                    color: config.textColor || "#E6EDF3"
                    font.family: config.fontFamily || "JetBrains Mono"
                    font.pixelSize: 13
                    selectByMouse: true
                    KeyNavigation.tab: passwordInput
                    onAccepted: passwordInput.focus = true
                }
            }

            // Password field
            Text {
                text: "PASSWORD"
                color: config.mutedColor || "#8B949E"
                font.family: config.fontFamily || "JetBrains Mono"
                font.pixelSize: 10
            }

            Rectangle {
                width: parent.width
                height: 36
                color: config.backgroundColor || "#0B0D10"
                border.color: passwordInput.activeFocus ? (config.accentColor || "#3DDC97") : (config.borderColor || "#1F2630")
                border.width: 1
                radius: 2

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: config.textColor || "#E6EDF3"
                    font.family: config.fontFamily || "JetBrains Mono"
                    font.pixelSize: 13
                    selectByMouse: true
                    focus: true
                    KeyNavigation.backtab: userInput
                    onAccepted: sddm.login(userInput.text, passwordInput.text, root.sessionIndex)
                }
            }

            // Error line
            Text {
                visible: root.errorMessage.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: root.errorMessage
                color: config.dangerColor || "#F85149"
                font.family: config.fontFamily || "JetBrains Mono"
                font.pixelSize: 11
            }

            // Login button (#3DDC97 accent)
            Rectangle {
                width: parent.width
                height: 36
                color: loginMouse.pressed ? "#2BB67B" : (config.accentColor || "#3DDC97")
                radius: 2

                Text {
                    anchors.centerIn: parent
                    text: "LOG IN"
                    color: "#0B0D10"
                    font.family: config.fontFamily || "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: loginMouse
                    anchors.fill: parent
                    onClicked: sddm.login(userInput.text, passwordInput.text, root.sessionIndex)
                }
            }

            // Session selector + power actions
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width - 136
                    height: 28
                    color: config.backgroundColor || "#0B0D10"
                    border.color: config.borderColor || "#1F2630"
                    border.width: 1
                    radius: 2

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: "Session: " + (sessionModel.data(sessionModel.index(root.sessionIndex, 0), Qt.DisplayRole) || "Awesome")
                        color: config.mutedColor || "#8B949E"
                        font.family: config.fontFamily || "JetBrains Mono"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (sessionModel.rowCount() > 0) {
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 60
                    height: 28
                    color: config.backgroundColor || "#0B0D10"
                    border.color: config.borderColor || "#1F2630"
                    border.width: 1
                    radius: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Reboot"
                        color: config.mutedColor || "#8B949E"
                        font.family: config.fontFamily || "JetBrains Mono"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sddm.reboot()
                    }
                }

                Rectangle {
                    width: 60
                    height: 28
                    color: config.backgroundColor || "#0B0D10"
                    border.color: config.borderColor || "#1F2630"
                    border.width: 1
                    radius: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Power"
                        color: config.dangerColor || "#F85149"
                        font.family: config.fontFamily || "JetBrains Mono"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (userInput.text === "") {
            userInput.focus = true
        } else {
            passwordInput.focus = true
        }
    }
}
