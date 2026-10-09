import QtQuick 1.1
import com.nokia.meego 1.0

PageStackWindow {
    id: appWindow
    width: 480
    height: 854
    initialPage: mainPage
    showToolBar: false
    showStatusBar: false

    property string serverUrl: "http://192.168.8.137:5000/api"
    property bool isLoading: false

    // Sailfish OS (Silica) Renk Paleti
    property color silicaBlack: "#080C12"
    property color silicaCard: "#121A24"
    property color silicaCardBorder: "#1E2A38"
    property color silicaHighlight: "#00D2C4"    // İkonik Sailfish Turkuazı
    property color silicaTextPrimary: "#FFFFFF"
    property color silicaTextSecondary: "#8A9BA8"
    property color silicaHeart: "#FF3366"        // Beğeni Pembesi
    property color silicaRetweet: "#00E676"      // Retweet Yeşili
    property color silicaPillBg: "#172230"
    property color silicaPillBorder: "#27374D"

    // ==============================================================
    // 1. ANA SAYFA (Zaman Tüneli & Pulley Menu)
    // ==============================================================
    Page {
        id: mainPage
        orientationLock: PageOrientation.LockPortrait

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        // Üst Başlık
        Item {
            id: topHeader
            width: parent.width
            height: 76
            anchors.top: parent.top

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: silicaHighlight
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: "MeeX"
                    font.bold: true
                    font.pixelSize: 32
                    color: silicaTextPrimary
                }

                Label {
                    text: "• Akış"
                    font.pixelSize: 22
                    color: silicaHighlight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Üst Sağ Butonlar (Arama ve Yeni Gönderi)
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Hızlı Arama Butonu (Görünür Pill Tasarımı)
                Rectangle {
                    width: 76
                    height: 42
                    radius: 21
                    color: "#162434"
                    border.color: "#38BDF8"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Item {
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: 11; height: 11; radius: 5; color: "transparent"; border.color: "#38BDF8"; border.width: 2; x: 1; y: 1 }
                            Rectangle { width: 2; height: 6; radius: 1; color: "#38BDF8"; rotation: -45; transformOrigin: Item.Top; x: 10; y: 10 }
                        }

                        Text {
                            text: "Ara"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#38BDF8"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: openSearch()
                    }
                }

                // Hızlı Yeni Tweet Butonu
                Rectangle {
                    width: 44
                    height: 42
                    radius: 21
                    color: "#182433"
                    border.color: silicaHighlight
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.bold: true
                        font.pixelSize: 28
                        color: silicaHighlight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(composePage)
                    }
                }
            }
        }

        // Pulley Menu Göstergesi
        Item {
            id: pulleyIndicator
            width: parent.width
            height: 55
            anchors.bottom: tweetList.top
            visible: tweetList.contentY < -20

            Text {
                anchors.centerIn: parent
                text: tweetList.contentY < -90 ? "↓ Bırak ve Yenile" : "↓ Çekerek Yenile"
                font.pixelSize: 20
                font.bold: tweetList.contentY < -90
                color: tweetList.contentY < -90 ? silicaHighlight : silicaTextSecondary
            }
        }

        // Tweet Akış Listesi
        ListView {
            id: tweetList
            anchors.top: topHeader.bottom
            anchors.bottom: bottomNavBar.top
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            model: ListModel { id: tweetModel }

            onMovementEnded: {
                if (contentY < -80) {
                    fetchTimeline();
                }
            }

            delegate: tweetDelegateComponent
        }

        // Sailfish Bildirim Kapsülü (Toast)
        Rectangle {
            id: toastBox
            anchors.top: topHeader.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            height: 44
            width: Math.max(160, toastRow.width + 36)
            radius: 22
            color: "#182230"
            border.color: toastBox.toastColor
            border.width: 2
            z: 99
            visible: opacity > 0
            opacity: 0

            property color toastColor: silicaHighlight

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            Row {
                id: toastRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: toastIcon
                    font.pixelSize: 20
                    color: toastBox.toastColor
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: toastText
                    font.bold: true
                    font.pixelSize: 18
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Timer {
                id: toastTimer
                interval: 2000
                onTriggered: toastBox.opacity = 0
            }
        }

                                // ==============================================================
        // SAILFISH OS (SILICA UI) GEZİNME ÇUBUĞU
        // Minimalist, İnce Çizgili Vektör İkonlar & Ambiance Vurgusu
        // ==============================================================
        Rectangle {
            id: bottomNavBar
            anchors.bottom: parent.bottom
            width: parent.width
            height: 72
            color: "#080D14"
            border.color: "#182432"
            border.width: 1

            property int currentTab: 0

            Row {
                anchors.fill: parent

                // 1. Akış (Sailfish Minimalist Ev / Home İkonu)
                Item {
                    width: parent.width / 5
                    height: parent.height

                    // Sailfish Aktif Sekme Gösterge Çizgisi
                    Rectangle {
                        width: 24; height: 2; radius: 1
                        color: silicaHighlight
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        visible: bottomNavBar.currentTab === 0
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: bottomNavBar.currentTab === 0 ? 1.0 : 0.55

                        Item {
                            width: 24; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Çatı (İnce Vektör)
                            Rectangle {
                                width: 14; height: 14
                                rotation: 45
                                color: bottomNavBar.currentTab === 0 ? silicaHighlight : "#FFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 1
                            }
                            // Gövde
                            Rectangle {
                                width: 16; height: 11
                                color: bottomNavBar.currentTab === 0 ? silicaHighlight : "#FFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 8
                            }
                            // Kapı Boşluğu (Sailfish Negatif Alan)
                            Rectangle {
                                width: 6; height: 7
                                color: "#080D14"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 12
                            }
                        }

                        Text {
                            text: "Akış"
                            font.bold: bottomNavBar.currentTab === 0
                            font.pixelSize: 12
                            color: bottomNavBar.currentTab === 0 ? silicaHighlight : "#8A9BA8"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bottomNavBar.currentTab = 0;
                            fetchTimeline();
                        }
                    }
                }

                // 2. Arama (Sailfish İnce Halka Büyüteç İkonu)
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Rectangle {
                        width: 24; height: 2; radius: 1
                        color: silicaHighlight
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        visible: bottomNavBar.currentTab === 1
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: bottomNavBar.currentTab === 1 ? 1.0 : 0.55

                        Item {
                            width: 24; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Büyüteç Halkası
                            Rectangle {
                                width: 14; height: 14
                                radius: 7
                                color: "transparent"
                                border.color: bottomNavBar.currentTab === 1 ? silicaHighlight : "#FFFFFF"
                                border.width: 2
                                x: 2; y: 1
                            }
                            // Sap
                            Rectangle {
                                width: 2; height: 7
                                radius: 1
                                color: bottomNavBar.currentTab === 1 ? silicaHighlight : "#FFFFFF"
                                rotation: -45
                                transformOrigin: Item.Top
                                x: 13; y: 12
                            }
                        }

                        Text {
                            text: "Arama"
                            font.bold: bottomNavBar.currentTab === 1
                            font.pixelSize: 12
                            color: bottomNavBar.currentTab === 1 ? silicaHighlight : "#8A9BA8"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bottomNavBar.currentTab = 1;
                            openSearch();
                        }
                    }
                }

                // 3. Gönder (Sailfish Ambient Eylem Butonu)
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: "#10252D"
                            border.color: silicaHighlight
                            border.width: 1
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.bold: true
                                font.pixelSize: 26
                                color: silicaHighlight
                            }
                        }

                        Text {
                            text: "Gönder"
                            font.pixelSize: 12
                            color: silicaHighlight
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(composePage)
                    }
                }

                // 4. Profil (Sailfish Minimalist Kişi Silüeti)
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Rectangle {
                        width: 24; height: 2; radius: 1
                        color: silicaHighlight
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        visible: bottomNavBar.currentTab === 3
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: bottomNavBar.currentTab === 3 ? 1.0 : 0.55

                        Item {
                            width: 24; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Baş
                            Rectangle {
                                width: 8; height: 8
                                radius: 4
                                color: bottomNavBar.currentTab === 3 ? silicaHighlight : "#FFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 1
                            }
                            // Gövde / Omuzlar
                            Rectangle {
                                width: 18; height: 7
                                radius: 3
                                color: bottomNavBar.currentTab === 3 ? silicaHighlight : "#FFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 11
                            }
                        }

                        Text {
                            text: "Profil"
                            font.bold: bottomNavBar.currentTab === 3
                            font.pixelSize: 12
                            color: bottomNavBar.currentTab === 3 ? silicaHighlight : "#8A9BA8"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bottomNavBar.currentTab = 3;
                            openProfile("");
                        }
                    }
                }

                // 5. Ayarlar (Sailfish Minimalist Ekolayzır / Slayt Çubukları)
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Rectangle {
                        width: 24; height: 2; radius: 1
                        color: silicaHighlight
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        visible: bottomNavBar.currentTab === 4
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: bottomNavBar.currentTab === 4 ? 1.0 : 0.55

                        Item {
                            width: 24; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter

                            // 1. Çubuk & Düğme (Üstte)
                            Rectangle { width: 1; height: 16; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#8A9BA8"; x: 4; y: 3 }
                            Rectangle { width: 5; height: 4; radius: 1; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#FFFFFF"; x: 2; y: 5 }

                            // 2. Çubuk & Düğme (Altta)
                            Rectangle { width: 1; height: 16; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#8A9BA8"; x: 11; y: 3 }
                            Rectangle { width: 5; height: 4; radius: 1; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#FFFFFF"; x: 9; y: 13 }

                            // 3. Çubuk & Düğme (Ortada)
                            Rectangle { width: 1; height: 16; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#8A9BA8"; x: 18; y: 3 }
                            Rectangle { width: 5; height: 4; radius: 1; color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#FFFFFF"; x: 16; y: 9 }
                        }

                        Text {
                            text: "Ayarlar"
                            font.bold: bottomNavBar.currentTab === 4
                            font.pixelSize: 12
                            color: bottomNavBar.currentTab === 4 ? silicaHighlight : "#8A9BA8"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bottomNavBar.currentTab = 4;
                            pageStack.push(settingsPage);
                        }
                    }
                }
            }
        }

        // Yükleniyor Göstergesi
        BusyIndicator {
            id: busy
            anchors.centerIn: parent
            visible: appWindow.isLoading
            running: appWindow.isLoading
            z: 99
        }

        Timer {
            id: loadingSafetyTimer
            interval: 6000
            onTriggered: {
                if (appWindow.isLoading) {
                    appWindow.isLoading = false;
                }
            }
        }

        // Boş Akış Bildirimi
        Item {
            id: emptyState
            anchors.centerIn: parent
            width: parent.width - 40
            height: 200
            visible: tweetModel.count === 0 && !appWindow.isLoading

            Column {
                anchors.centerIn: parent
                spacing: 14
                width: parent.width

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "★"
                    font.pixelSize: 42
                    color: silicaHighlight
                }

                Label {
                    id: statusMsg
                    width: parent.width
                    text: "Akış bekleniyor...\nAlttaki 'Akış' butonuna dokunun."
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 20
                    color: silicaTextSecondary
                }

                Rectangle {
                    width: 180
                    height: 48
                    radius: 24
                    color: "#182433"
                    border.color: silicaHighlight
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Şimdi Yenile"
                        font.pixelSize: 18
                        font.bold: true
                        color: silicaHighlight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: fetchTimeline()
                    }
                }
            }
        }

        Component.onCompleted: {
            initCache();
            fetchTimeline();
        }
    }

    // ==============================================================
    // ORTAK TWEET KARTI BİLEŞENİ
    // ==============================================================
    Component {
        id: tweetDelegateComponent

        Item {
            id: tweetDelegate
            width: 480
            height: cardBg.height + 16

            property int localLikes: model.likes
            property int localRetweets: model.retweets
            property bool isLiked: model.favorited ? true : false
            property bool isRetweeted: model.retweeted ? true : false
            property bool isBookmarked: model.bookmarked ? true : false

            Rectangle {
                id: cardBg
                width: 456
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 4
                radius: 16
                color: silicaCard
                border.color: silicaCardBorder
                border.width: 1
                height: cardContent.height + 28

                Column {
                    id: cardContent
                    width: parent.width - 28
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    spacing: 12

                    // 1. Üst Bilgi: Avatar + İsim + Handle
                    Row {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 56
                            height: 56
                            radius: 28
                            color: "#223142"
                            border.color: "#2C3E50"
                            border.width: 1
                            clip: true

                            Image {
                                id: avatarImg
                                anchors.fill: parent
                                source: (model.avatar && model.avatar !== "") ? model.avatar : ""
                                fillMode: Image.PreserveAspectCrop
                            }

                            Text {
                                anchors.centerIn: parent
                                text: model.user ? model.user.charAt(0) : "X"
                                color: silicaHighlight
                                font.bold: true
                                font.pixelSize: 24
                                visible: avatarImg.status !== Image.Ready
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: openProfile(model.screen_name)
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Label {
                                text: model.user
                                font.bold: true
                                font.pixelSize: 22
                                color: silicaTextPrimary

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: openProfile(model.screen_name)
                                }
                            }

                            Row {
                                spacing: 8
                                Label {
                                    text: model.screen_name
                                    font.pixelSize: 18
                                    color: silicaTextSecondary
                                }
                                Label {
                                    text: "• " + model.created_at
                                    font.pixelSize: 15
                                    color: "#5C6E7E"
                                }
                            }
                        }
                    }

                    // 2. Tweet Metni (Tıklanınca Detay ve Yanıtları Açar)
                    Label {
                        width: parent.width
                        text: model.text
                        wrapMode: Text.Wrap
                        font.pixelSize: 21
                        color: "#E2E8F0"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: openTweetDetailWithData(model.id, model.user, model.screen_name, model.text, model.avatar, model.media, model.created_at)
                        }
                    }

                    // 3. Tweet İçi Görsel
                    Rectangle {
                        width: parent.width
                        height: (model.media && model.media !== "") ? 200 : 0
                        radius: 12
                        color: "#0B1118"
                        border.color: "#1E2A38"
                        border.width: 1
                        clip: true
                        visible: (model.media && model.media !== "")

                        Image {
                            anchors.fill: parent
                            source: (model.media && model.media !== "") ? model.media : ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: openTweetDetailWithData(model.id, model.user, model.screen_name, model.text, model.avatar, model.media, model.created_at)
                        }
                    }

                    // 4. Yeniden Tasarlanan Eylem Kapsülleri (Beğen, Retweet, Yanıt)
                    Row {
                        width: parent.width
                        spacing: 12

                        // BEĞEN BUTONU
                        Rectangle {
                            height: 42
                            width: Math.max(96, likeRow.width + 24)
                            radius: 21
                            color: tweetDelegate.isLiked ? "#3A1524" : silicaPillBg
                            border.color: tweetDelegate.isLiked ? silicaHeart : silicaPillBorder
                            border.width: 1
                            opacity: likeArea.pressed ? 0.6 : 1.0

                            Row {
                                id: likeRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "♥"
                                    font.pixelSize: 22
                                    color: tweetDelegate.isLiked ? silicaHeart : "#94A3B8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: tweetDelegate.localLikes > 0 ? tweetDelegate.localLikes.toString() : "Beğen"
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: tweetDelegate.isLiked ? silicaHeart : "#94A3B8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: likeArea
                                anchors.fill: parent
                                onClicked: {
                                    if (!tweetDelegate.isLiked) {
                                        tweetDelegate.isLiked = true;
                                        tweetDelegate.localLikes += 1;
                                        likeTweet(model.id);
                                        showToast("Beğenildi", "♥", silicaHeart);
                                    } else {
                                        tweetDelegate.isLiked = false;
                                        tweetDelegate.localLikes = Math.max(0, tweetDelegate.localLikes - 1);
                                        unlikeTweet(model.id);
                                        showToast("Beğeni Geri Çekildi", "♡", silicaTextSecondary);
                                    }
                                }
                            }
                        }

                        // RETWEET BUTONU
                        Rectangle {
                            height: 42
                            width: Math.max(96, rtRow.width + 24)
                            radius: 21
                            color: tweetDelegate.isRetweeted ? "#123020" : silicaPillBg
                            border.color: tweetDelegate.isRetweeted ? silicaRetweet : silicaPillBorder
                            border.width: 1
                            opacity: rtArea.pressed ? 0.6 : 1.0

                            Row {
                                id: rtRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "⇄"
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: tweetDelegate.isRetweeted ? silicaRetweet : "#94A3B8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: tweetDelegate.localRetweets > 0 ? tweetDelegate.localRetweets.toString() : "RT"
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: tweetDelegate.isRetweeted ? silicaRetweet : "#94A3B8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: rtArea
                                anchors.fill: parent
                                onClicked: {
                                    if (!tweetDelegate.isRetweeted) {
                                        tweetDelegate.isRetweeted = true;
                                        tweetDelegate.localRetweets += 1;
                                        retweetTweet(model.id);
                                        showToast("Retweet Edildi", "⇄", silicaRetweet);
                                    } else {
                                        tweetDelegate.isRetweeted = false;
                                        tweetDelegate.localRetweets = Math.max(0, tweetDelegate.localRetweets - 1);
                                        unretweetTweet(model.id);
                                        showToast("Retweet Kaldırıldı", "⇄", silicaTextSecondary);
                                    }
                                }
                            }
                        }

                        // YANITLA BUTONU
                        Rectangle {
                            height: 42
                            width: Math.max(96, replyRow.width + 24)
                            radius: 21
                            color: silicaPillBg
                            border.color: silicaPillBorder
                            border.width: 1
                            opacity: replyArea.pressed ? 0.6 : 1.0

                            Row {
                                id: replyRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "↩"
                                    font.pixelSize: 22
                                    font.bold: true
                                    color: silicaHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Yanıt"
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: silicaHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: replyArea
                                anchors.fill: parent
                                onClicked: {
                                    tweetInput.text = model.screen_name + " ";
                                    pageStack.push(composePage);
                                }
                            }
                        }

                        // YER İMİ (BOOKMARK) BUTONU
                        Rectangle {
                            height: 42
                            width: 44
                            radius: 21
                            color: tweetDelegate.isBookmarked ? "#38290B" : silicaPillBg
                            border.color: tweetDelegate.isBookmarked ? "#F59E0B" : silicaPillBorder
                            border.width: 1
                            opacity: bmArea.pressed ? 0.6 : 1.0

                            Text {
                                anchors.centerIn: parent
                                text: "★"
                                font.pixelSize: 20
                                color: tweetDelegate.isBookmarked ? "#F59E0B" : "#94A3B8"
                            }

                            MouseArea {
                                id: bmArea
                                anchors.fill: parent
                                onClicked: {
                                    if (!tweetDelegate.isBookmarked) {
                                        tweetDelegate.isBookmarked = true;
                                        bookmarkTweet(model.id);
                                        showToast("Yer İmlerine Eklendi", "★", "#F59E0B");
                                    } else {
                                        tweetDelegate.isBookmarked = false;
                                        unbookmarkTweet(model.id);
                                        showToast("Yer İmlerinden Kaldırıldı", "☆", silicaTextSecondary);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==============================================================
    // 2. KULLANICI PROFİL SAYFASI (Sekmeli: Hakkında / Tweetler)
    // ==============================================================
    Page {
        id: profilePage
        orientationLock: PageOrientation.LockPortrait

        property string currentProfileUser: ""
        property int activeTab: 0

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        Item {
            id: profileTopBar
            width: parent.width
            height: 76
            anchors.top: parent.top

            Item {
                width: 80
                height: 50
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "← Geri"
                    font.pixelSize: 22
                    color: silicaTextSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop()
                }
            }

            Label {
                text: "Profil"
                font.bold: true
                font.pixelSize: 24
                color: silicaTextPrimary
                anchors.centerIn: parent
            }
        }

        // Sekme Çubuğu
        Rectangle {
            id: profileTabBar
            anchors.top: profileTopBar.bottom
            width: parent.width
            height: 50
            color: "#0F1620"
            border.color: "#1A2533"
            border.width: 1

            Row {
                anchors.fill: parent

                Rectangle {
                    width: profilePage.currentProfileUser === "" ? parent.width / 3 : parent.width / 2
                    height: parent.height
                    color: profilePage.activeTab === 0 ? "#172330" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Hakkında"
                        font.bold: true
                        font.pixelSize: 17
                        color: profilePage.activeTab === 0 ? silicaHighlight : silicaTextSecondary
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 3
                        color: silicaHighlight
                        visible: profilePage.activeTab === 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: profilePage.activeTab = 0
                    }
                }

                Rectangle {
                    width: profilePage.currentProfileUser === "" ? parent.width / 3 : parent.width / 2
                    height: parent.height
                    color: profilePage.activeTab === 1 ? "#172330" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Tweetler (" + profileTweetModel.count + ")"
                        font.bold: true
                        font.pixelSize: 17
                        color: profilePage.activeTab === 1 ? silicaHighlight : silicaTextSecondary
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 3
                        color: silicaHighlight
                        visible: profilePage.activeTab === 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: profilePage.activeTab = 1
                    }
                }

                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    visible: profilePage.currentProfileUser === ""
                    color: profilePage.activeTab === 2 ? "#172330" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "İmler (" + bookmarkTweetModel.count + ")"
                        font.bold: true
                        font.pixelSize: 17
                        color: profilePage.activeTab === 2 ? "#F59E0B" : silicaTextSecondary
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 3
                        color: "#F59E0B"
                        visible: profilePage.activeTab === 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            profilePage.activeTab = 2;
                            fetchBookmarks();
                        }
                    }
                }
            }
        }
        // Görünüm 1: Hakkında Sekmesi
        Flickable {
            id: aboutView
            anchors.top: profileTabBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            contentHeight: aboutColumn.height + 40
            clip: true
            visible: profilePage.activeTab === 0

            Column {
                id: aboutColumn
                width: parent.width
                spacing: 16

                Rectangle {
                    width: parent.width
                    height: 140
                    color: "#1A2533"

                    Image {
                        id: bannerImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Item {
                    width: parent.width
                    height: 90

                    Rectangle {
                        id: profAvatarBox
                        width: 84
                        height: 84
                        radius: 42
                        color: "#223142"
                        border.color: silicaHighlight
                        border.width: 2
                        clip: true
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.bottom: parent.bottom

                        Image {
                            id: profAvatarImg
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    Column {
                        anchors.left: profAvatarBox.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: profAvatarBox.verticalCenter
                        spacing: 4

                        Label {
                            id: profName
                            text: "Yükleniyor..."
                            font.bold: true
                            font.pixelSize: 24
                            color: silicaTextPrimary
                        }

                        Label {
                            id: profHandle
                            text: "@..."
                            font.pixelSize: 18
                            color: silicaHighlight
                        }
                    }
                }

                Column {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Label {
                        id: profBio
                        width: parent.width
                        text: ""
                        wrapMode: Text.Wrap
                        font.pixelSize: 19
                        color: "#E2E8F0"
                    }

                    Row {
                        spacing: 16
                        Label {
                            id: profLocation
                            text: ""
                            font.pixelSize: 16
                            color: silicaTextSecondary
                            visible: text !== ""
                        }
                        Label {
                            id: profJoined
                            text: ""
                            font.pixelSize: 16
                            color: "#5C6E7E"
                            visible: text !== ""
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 120; height: 50; radius: 10
                        color: silicaCard; border.color: silicaCardBorder; border.width: 1
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Label { id: statTweets; text: "0"; font.bold: true; font.pixelSize: 18; color: silicaHighlight; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: "Gönderi"; font.pixelSize: 13; color: silicaTextSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }

                    Rectangle {
                        width: 120; height: 50; radius: 10
                        color: silicaCard; border.color: silicaCardBorder; border.width: 1
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Label { id: statFollowing; text: "0"; font.bold: true; font.pixelSize: 18; color: silicaTextPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: "Takip"; font.pixelSize: 13; color: silicaTextSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }

                    Rectangle {
                        width: 120; height: 50; radius: 10
                        color: silicaCard; border.color: silicaCardBorder; border.width: 1
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Label { id: statFollowers; text: "0"; font.bold: true; font.pixelSize: 18; color: silicaTextPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: "Takipçi"; font.pixelSize: 13; color: silicaTextSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - 40
                    height: 50
                    radius: 12
                    color: "#182433"
                    border.color: silicaHighlight
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Gönderileri Listele (" + profileTweetModel.count + ") →"
                        font.bold: true
                        font.pixelSize: 18
                        color: silicaHighlight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: profilePage.activeTab = 1
                    }
                }
            }
        }

        // Görünüm 2: Tweetler Sekmesi
        ListView {
            id: profileTweetList
            anchors.top: profileTabBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            visible: profilePage.activeTab === 1
            model: ListModel { id: profileTweetModel }
            delegate: tweetDelegateComponent

            Label {
                anchors.centerIn: parent
                text: "Kullanıcıya ait tweet bulunamadı."
                font.pixelSize: 18
                color: silicaTextSecondary
                visible: profileTweetModel.count === 0
            }
        }


        // Görünüm 3: Yer İmleri Sekmesi (Bookmarks)
        ListView {
            id: bookmarkTweetList
            anchors.top: profileTabBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            visible: profilePage.activeTab === 2
            model: ListModel { id: bookmarkTweetModel }
            delegate: tweetDelegateComponent

            Label {
                anchors.centerIn: parent
                text: "Henüz kaydedilmiş yer imi bulunmuyor."
                font.pixelSize: 18
                color: silicaTextSecondary
                visible: bookmarkTweetModel.count === 0
            }
        }
    }

    // ==============================================================
    // 3. KEŞFET & ARAMA SAYFASI (Search & Trends)
    // ==============================================================
    Page {
        id: searchPage
        orientationLock: PageOrientation.LockPortrait

        property int activeTab: 0 // 0: Gündemdekiler, 1: Arama
        property bool isSearching: false
        property string searchStatusText: "Aramak için kelime girip 'Ara' butonuna basın."
        property string trendsStatusText: "Gündem başlıkları yükleniyor..."

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        Item {
            id: searchTopBar
            width: parent.width
            height: 76
            anchors.top: parent.top

            Item {
                width: 80; height: 50
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "← Geri"; font.pixelSize: 22; color: silicaTextSecondary }
                MouseArea { anchors.fill: parent; onClicked: pageStack.pop() }
            }

            Label {
                text: "Arama & Keşfet"
                font.bold: true
                font.pixelSize: 24
                color: silicaTextPrimary
                anchors.centerIn: parent
            }
        }

        // Arama & Keşfet Sekme Çubuğu (Gündemler / Arama) - Sailfish OS Vektör İkonlu
        Rectangle {
            id: searchTabBar
            anchors.top: searchTopBar.bottom
            width: parent.width
            height: 48
            color: "#0F1620"
            border.color: "#1A2533"
            border.width: 1

            Row {
                anchors.fill: parent

                // 1. Sekme: Gündemler
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    color: searchPage.activeTab === 0 ? "#172330" : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        // Trend Yükseliş Çubukları (Vektör İkon)
                        Item {
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: 3; height: 7; radius: 1; color: searchPage.activeTab === 0 ? silicaHighlight : silicaTextSecondary; x: 1; y: 9 }
                            Rectangle { width: 3; height: 11; radius: 1; color: searchPage.activeTab === 0 ? silicaHighlight : silicaTextSecondary; x: 6; y: 5 }
                            Rectangle { width: 3; height: 15; radius: 1; color: searchPage.activeTab === 0 ? silicaHighlight : silicaTextSecondary; x: 11; y: 1 }
                        }

                        Text {
                            text: "Gündemdekiler"
                            font.bold: true
                            font.pixelSize: 16
                            color: searchPage.activeTab === 0 ? silicaHighlight : silicaTextSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 3
                        color: silicaHighlight
                        visible: searchPage.activeTab === 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchPage.activeTab = 0;
                            fetchTrends();
                        }
                    }
                }

                // 2. Sekme: Arama
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    color: searchPage.activeTab === 1 ? "#172330" : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        // Vektörel Büyüteç İkonu (Unicode Değil, %100 Vektör)
                        Item {
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 11; height: 11
                                radius: 5
                                color: "transparent"
                                border.color: searchPage.activeTab === 1 ? "#38BDF8" : silicaTextSecondary
                                border.width: 2
                                x: 1; y: 1
                            }
                            Rectangle {
                                width: 2; height: 6
                                radius: 1
                                color: searchPage.activeTab === 1 ? "#38BDF8" : silicaTextSecondary
                                rotation: -45
                                transformOrigin: Item.Top
                                x: 10; y: 10
                            }
                        }

                        Text {
                            text: "Tweet Ara"
                            font.bold: true
                            font.pixelSize: 16
                            color: searchPage.activeTab === 1 ? "#38BDF8" : silicaTextSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 3
                        color: "#38BDF8"
                        visible: searchPage.activeTab === 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchPage.activeTab = 1;
                        }
                    }
                }
            }
        }

        // ============================================
        // GÖRÜNÜM 1: GÜNDEMLER SEKMESİ (Trends)
        // ============================================
        ListView {
            id: trendsList
            anchors.top: searchTabBar.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            visible: searchPage.activeTab === 0
            model: ListModel { id: trendsModel }

            header: Item {
                width: parent.width
                height: 40
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle { width: 4; height: 16; radius: 2; color: silicaHighlight }
                    Text { text: "Bugün Neler Oluyor?"; font.bold: true; font.pixelSize: 18; color: silicaTextPrimary }
                }
            }

            delegate: Item {
                width: 480
                height: 68

                Rectangle {
                    width: 452
                    height: 58
                    radius: 12
                    anchors.centerIn: parent
                    color: silicaCard
                    border.color: silicaCardBorder
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Text {
                            text: (index + 1).toString()
                            font.bold: true
                            font.pixelSize: 17
                            color: silicaHighlight
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 50

                            Text {
                                text: model.name
                                font.bold: true
                                font.pixelSize: 18
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: model.count ? model.count + " Tweet" : "Popüler Konu"
                                font.pixelSize: 13
                                color: silicaTextSecondary
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchField.text = model.name;
                            searchPage.activeTab = 1;
                            performSearch(model.name);
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: searchPage.trendsStatusText
                font.pixelSize: 18
                color: silicaTextSecondary
                visible: trendsModel.count === 0 && !appWindow.isLoading
            }
        }

        // ============================================
        // GÖRÜNÜM 2: ARAMA SEKMESİ (Search)
        // ============================================
        Item {
            id: searchViewContainer
            anchors.top: searchTabBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: searchPage.activeTab === 1

            // Arama Çubuğu
            Rectangle {
                id: searchInputBox
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 14
                height: 54
                radius: 27
                color: silicaCard
                border.color: "#38BDF8"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    TextField {
                        id: searchField
                        width: parent.width - 90
                        height: parent.height
                        placeholderText: "Kelime, konu veya @hesap..."
                        font.pixelSize: 20

                        onAccepted: {
                            searchField.focus = false;
                            performSearch(searchField.text);
                        }
                    }

                    Rectangle {
                        width: 74
                        height: parent.height
                        radius: 20
                        color: "#38BDF8"
                        opacity: searchBtnArea.pressed ? 0.6 : 1.0

                        Text {
                            anchors.centerIn: parent
                            text: "Ara"
                            font.bold: true
                            font.pixelSize: 18
                            color: silicaBlack
                        }

                        MouseArea {
                            id: searchBtnArea
                            anchors.fill: parent
                            onClicked: {
                                searchField.focus = false;
                                performSearch(searchField.text);
                            }
                        }
                    }
                }
            }

            // Arama Sonuçları Listesi
            ListView {
                id: searchResultsList
                anchors.top: searchInputBox.bottom
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                clip: true
                model: ListModel { id: searchResultsModel }
                delegate: tweetDelegateComponent

                Label {
                    anchors.centerIn: parent
                    text: searchPage.searchStatusText
                    font.pixelSize: 18
                    color: silicaTextSecondary
                    visible: searchResultsModel.count === 0
                }
            }
        }
    }

    // ==============================================================
    // 4. TWEET DETAY VE YANIT ZİNCİRİ SAYFASI (Thread View)
    // ==============================================================
    Page {
        id: tweetDetailPage
        orientationLock: PageOrientation.LockPortrait

        property string targetTweetId: ""

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        Item {
            id: detailTopBar
            width: parent.width; height: 76
            anchors.top: parent.top

            Item {
                width: 80; height: 50
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "← Geri"; font.pixelSize: 22; color: silicaTextSecondary }
                MouseArea { anchors.fill: parent; onClicked: pageStack.pop() }
            }

            Label {
                text: "Gönderi Detayı"
                font.bold: true
                font.pixelSize: 24
                color: silicaTextPrimary
                anchors.centerIn: parent
            }
        }

        Flickable {
            id: detailFlickable
            anchors.top: detailTopBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            contentHeight: detailColumn.height + 60
            clip: true

            Column {
                id: detailColumn
                width: parent.width
                spacing: 14

                // Ana Tweet Kartı
                Rectangle {
                    width: parent.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 16
                    color: silicaCard
                    border.color: silicaHighlight
                    border.width: 1
                    height: mainDetailCol.height + 28

                    Column {
                        id: mainDetailCol
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        spacing: 12

                        Row {
                            spacing: 12
                            Rectangle {
                                width: 60; height: 60; radius: 30
                                color: "#223142"; clip: true
                                Image { id: detailAvatar; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Label { id: detailUser; font.bold: true; font.pixelSize: 24; color: silicaTextPrimary }
                                Label { id: detailScreenName; font.pixelSize: 18; color: silicaTextSecondary }
                            }
                        }

                        Text {
                            id: detailText
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: 22
                            color: "#FFFFFF"
                        }

                        Rectangle {
                            id: detailMediaBox
                            width: parent.width
                            height: detailMediaBox.visible ? 220 : 0
                            radius: 12
                            color: "#0B1118"
                            clip: true
                            visible: false
                            Image { id: detailMediaImg; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
                        }

                        Label {
                            id: detailDate
                            font.pixelSize: 16
                            color: "#5C6E7E"
                        }
                    }
                }

                // Yanıtlar Başlığı
                Rectangle {
                    width: parent.width
                    height: 40
                    color: "#0F1620"
                    visible: repliesModel.count > 0
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle { width: 4; height: 16; radius: 2; color: silicaHighlight }
                        Text { text: "Yanıtlar (" + repliesModel.count + ")"; font.bold: true; font.pixelSize: 18; color: silicaTextPrimary }
                    }
                }

                // Yanıtlar Listesi (Repeater)
                Repeater {
                    model: ListModel { id: repliesModel }
                    delegate: tweetDelegateComponent
                }

                Item { width: parent.width; height: 20 }
            }
        }
    }

    // ==============================================================
    // 5. YENİ GÖNDERİ SAYFASI
    // ==============================================================
    Page {
        id: composePage
        orientationLock: PageOrientation.LockPortrait

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        Item {
            id: composeTopBar
            width: parent.width; height: 76
            anchors.top: parent.top

            Item {
                width: 90; height: 50
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "← İptal"; font.pixelSize: 22; color: silicaTextSecondary }
                MouseArea { anchors.fill: parent; onClicked: pageStack.pop() }
            }

            Rectangle {
                width: 110; height: 46; radius: 23
                color: silicaHighlight
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Paylaş"
                    font.bold: true; font.pixelSize: 20
                    color: silicaBlack
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: sendTweet(tweetInput.text, imagePathInput.text)
                }
            }
        }

        Rectangle {
            anchors.top: composeTopBar.bottom
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 16
            height: 260
            radius: 14
            color: silicaCard
            border.color: silicaCardBorder
            border.width: 1

            TextArea {
                id: tweetInput
                anchors.fill: parent
                anchors.margins: 14
                placeholderText: "Neler düşünüyorsun?"
                font.pixelSize: 23
            }
        }


        // Görsel / Fotoğraf Yolu Alanı
        Rectangle {
            anchors.top: composeTopBar.bottom
            anchors.topMargin: 278
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 16
            height: 48
            radius: 12
            color: "#121A24"
            border.color: silicaCardBorder
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Text {
                    text: "📷"
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: imagePathInput
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    selectByMouse: true
                    text: ""

                    Text {
                        anchors.fill: parent
                        text: "Fotoğraf dosya yolu (örn: /home/user/...)"
                        color: "#5C6E7E"
                        font.pixelSize: 15
                        visible: !imagePathInput.text && !imagePathInput.activeFocus
                    }
                }

                Text {
                    text: "✕"
                    font.pixelSize: 18
                    color: silicaTextSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    visible: imagePathInput.text.length > 0
                    MouseArea {
                        anchors.fill: parent
                        onClicked: imagePathInput.text = ""
                    }
                }
            }
        }

        Rectangle {
            anchors.top: composeTopBar.bottom
            anchors.topMargin: 338
            anchors.right: parent.right
            anchors.rightMargin: 20
            width: 90; height: 36; radius: 18
            color: "#182230"

            Text {
                anchors.centerIn: parent
                text: (280 - tweetInput.text.length).toString()
                font.bold: true; font.pixelSize: 18
                color: tweetInput.text.length > 280 ? "#FF4444" : silicaHighlight
            }
        }
    }

    // ==============================================================
    // 6. AYARLAR SAYFASI
    // ==============================================================
    Page {
        id: settingsPage
        orientationLock: PageOrientation.LockPortrait

        Rectangle {
            anchors.fill: parent
            color: silicaBlack
        }

        Item {
            id: settingsTopBar
            width: parent.width; height: 76
            anchors.top: parent.top

            Item {
                width: 80; height: 50
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "← Geri"; font.pixelSize: 22; color: silicaTextSecondary }
                MouseArea { anchors.fill: parent; onClicked: pageStack.pop() }
            }

            Label {
                text: "Sunucu Ayarları"
                font.bold: true; font.pixelSize: 24
                color: silicaTextPrimary
                anchors.centerIn: parent
            }
        }

        Column {
            anchors.top: settingsTopBar.bottom
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 20
            spacing: 18

            Label {
                text: "MeeX Köprü Sunucu URL'i:"
                font.pixelSize: 19
                color: silicaHighlight
            }

            Rectangle {
                width: parent.width; height: 58; radius: 12
                color: silicaCard; border.color: silicaCardBorder; border.width: 1

                TextField {
                    id: serverInput
                    anchors.fill: parent; anchors.margins: 8
                    text: appWindow.serverUrl
                    font.pixelSize: 21
                }
            }

            Rectangle {
                width: parent.width; height: 56; radius: 14
                color: silicaHighlight

                Text {
                    anchors.centerIn: parent
                    text: "Kaydet ve Akışı Güncelle"
                    font.bold: true; font.pixelSize: 20
                    color: silicaBlack
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        appWindow.serverUrl = serverInput.text;
                        pageStack.pop();
                        fetchTimeline();
                    }
                }
            }
        }
    }

    // ==============================================================
    // AĞ FONKSİYONLARI (AJAX / REST)
    // ==============================================================
    function showToast(text, icon, color) {
        toastText.text = text;
        toastIcon.text = icon;
        toastBox.toastColor = color ? color : silicaHighlight;
        toastBox.opacity = 1.0;
        toastTimer.restart();
    }

    function fetchTimeline() {
        if (appWindow.isLoading) return;
        appWindow.isLoading = true;
        if (loadingSafetyTimer) loadingSafetyTimer.restart();

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                appWindow.isLoading = false;
                if (loadingSafetyTimer) loadingSafetyTimer.stop();
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        tweetModel.clear();
                        if (res.data && res.data.length > 0) {
                            for (var i = 0; i < res.data.length; i++) {
                                tweetModel.append(res.data[i]);
                            }
                            statusMsg.text = "";
                            saveCache("timeline", xhr.responseText);
                        } else {
                            statusMsg.text = "Akışta henüz tweet bulunmuyor.";
                        }
                    } catch (e) {
                        statusMsg.text = "Veri ayrıştırma hatası: " + e;
                    }
                } else {
                    if (tweetModel.count > 0) {
                        showToast("Çevrimdışı: Önbellek Gösteriliyor", "☁", silicaTextSecondary);
                    } else {
                        statusMsg.text = "Sunucu Hatası (" + xhr.status + ") " + serverUrl;
                    }
                }
            }
        };

        xhr.open("GET", serverUrl + "/timeline");
        xhr.send();
    }
    function openProfile(userName) {
        profilePage.currentProfileUser = userName;
        profilePage.activeTab = 0;
        pageStack.push(profilePage);

        var url = serverUrl + "/profile";
        var tweetsUrl = serverUrl + "/user_tweets";
        if (userName && userName.length > 0) {
            url += "?user=" + encodeURIComponent(userName);
            tweetsUrl += "?user=" + encodeURIComponent(userName);
        }

        var xhrProf = new XMLHttpRequest();
        xhrProf.onreadystatechange = function() {
            if (xhrProf.readyState === XMLHttpRequest.DONE && xhrProf.status === 200) {
                try {
                    var res = JSON.parse(xhrProf.responseText);
                    var d = res.data;
                    profName.text = d.name;
                    profHandle.text = d.screen_name;
                    profBio.text = d.description;
                    profLocation.text = d.location;
                    profJoined.text = d.created_at ? "Katıldı: " + d.created_at : "";
                    statTweets.text = d.statuses_count.toString();
                    statFollowing.text = d.following_count.toString();
                    statFollowers.text = d.followers_count.toString();
                    if (d.avatar) profAvatarImg.source = d.avatar;
                    if (d.banner) bannerImg.source = d.banner;
                } catch (e) {
                    console.log("Profil parse hatası: " + e);
                }
            }
        };
        xhrProf.open("GET", url);
        xhrProf.send();

        var xhrTweets = new XMLHttpRequest();
        xhrTweets.onreadystatechange = function() {
            if (xhrTweets.readyState === XMLHttpRequest.DONE && xhrTweets.status === 200) {
                try {
                    var resT = JSON.parse(xhrTweets.responseText);
                    profileTweetModel.clear();
                    if (resT.data && resT.data.length > 0) {
                        for (var i = 0; i < resT.data.length; i++) {
                            profileTweetModel.append(resT.data[i]);
                        }
                    }
                } catch (e) {
                    console.log("Kullanıcı tweet parse hatası: " + e);
                }
            }
        };
        xhrTweets.open("GET", tweetsUrl);
        xhrTweets.send();
    }

    function openSearch() {
        searchPage.activeTab = 1;
        pageStack.push(searchPage);
        fetchTrends();
    }

    function fetchTrends() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var res = JSON.parse(xhr.responseText);
                    trendsModel.clear();
                    if (res.data && res.data.length > 0) {
                        for (var i = 0; i < res.data.length; i++) {
                            trendsModel.append({
                                "name": String(res.data[i].name || ""),
                                "count": String(res.data[i].count || "")
                            });
                        }
                    }
                } catch (e) {
                    console.log("Gündem parse hatası: " + e);
                }
            }
        };
        xhr.open("GET", serverUrl + "/trends");
        xhr.send();
    }

    function performSearch(query) {
        if (!query || query.trim().length === 0) return;
        searchPage.activeTab = 1;
        searchPage.searchStatusText = "Aranıyor...";
        searchResultsModel.clear();
        appWindow.isLoading = true;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                appWindow.isLoading = false;
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        searchResultsModel.clear();
                        if (res.data && res.data.length > 0) {
                            for (var i = 0; i < res.data.length; i++) {
                                var item = res.data[i];
                                searchResultsModel.append({
                                    "id": String(item.id || ""),
                                    "user": String(item.user || ""),
                                    "screen_name": String(item.screen_name || ""),
                                    "avatar": String(item.avatar || ""),
                                    "text": String(item.text || ""),
                                    "media": String(item.media || ""),
                                    "likes": parseInt(item.likes || 0),
                                    "retweets": parseInt(item.retweets || 0),
                                    "favorited": Boolean(item.favorited),
                                    "retweeted": Boolean(item.retweeted),
                                    "bookmarked": Boolean(item.bookmarked),
                                    "created_at": String(item.created_at || "")
                                });
                            }
                            searchPage.searchStatusText = "";
                        } else {
                            searchPage.searchStatusText = "Aramanızla eşleşen tweet bulunamadı.";
                        }
                    } catch (e) {
                        searchPage.searchStatusText = "Sonuç ayrıştırma hatası: " + e;
                    }
                } else {
                    searchPage.searchStatusText = "Arama yapılamadı (Hata: " + xhr.status + ")";
                }
            }
        };
        xhr.open("GET", serverUrl + "/search?q=" + encodeURIComponent(query.trim()));
        xhr.send();
    }

    function openTweetDetailWithData(tweetId, user, screenName, text, avatar, media, createdAt) {
        tweetDetailPage.targetTweetId = String(tweetId || "");
        detailUser.text = String(user || "");
        detailScreenName.text = String(screenName || "");
        detailText.text = String(text || "");
        detailDate.text = String(createdAt || "");
        if (avatar && avatar !== "") detailAvatar.source = avatar;
        if (media && media !== "") {
            detailMediaImg.source = media;
            detailMediaBox.visible = true;
        } else {
            detailMediaBox.visible = false;
        }
        repliesModel.clear();
        pageStack.push(tweetDetailPage);

        // Arka planda yanıtları ve güncel verileri çek
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var res = JSON.parse(xhr.responseText);
                    repliesModel.clear();
                    var rList = res.data.replies || [];
                    for (var i = 0; i < rList.length; i++) {
                        var item = rList[i];
                        repliesModel.append({
                            "id": String(item.id || ""),
                            "user": String(item.user || ""),
                            "screen_name": String(item.screen_name || ""),
                            "avatar": String(item.avatar || ""),
                            "text": String(item.text || ""),
                            "media": String(item.media || ""),
                            "likes": parseInt(item.likes || 0),
                            "retweets": parseInt(item.retweets || 0),
                            "favorited": Boolean(item.favorited),
                            "retweeted": Boolean(item.retweeted),
                            "bookmarked": Boolean(item.bookmarked),
                            "created_at": String(item.created_at || "")
                        });
                    }
                } catch (e) {
                    console.log("Yanıt parse hatası: " + e);
                }
            }
        };
        xhr.open("GET", serverUrl + "/tweet_detail?id=" + encodeURIComponent(tweetId));
        xhr.send();
    }

    function openTweetDetail(tweetId) {
        openTweetDetailWithData(tweetId, "", "", "Yükleniyor...", "", "", "");
    }

    function getDatabase() {
        return openDatabaseSync("MeeXDB", "1.0", "MeeX Local Cache", 100000);
    }

    function initCache() {
        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS cache (key TEXT UNIQUE, value TEXT)');
            });
            var cached = loadCache("timeline");
            if (cached && cached.length > 0) {
                var res = JSON.parse(cached);
                if (res.data && res.data.length > 0 && tweetModel.count === 0) {
                    for (var i = 0; i < res.data.length; i++) {
                        tweetModel.append(res.data[i]);
                    }
                    if (statusMsg) statusMsg.text = "";
                }
            }
        } catch(e) {
            console.log("initCache hatası: " + e);
        }
    }

    function saveCache(key, val) {
        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO cache VALUES (?, ?)', [key, val]);
            });
        } catch(e) {
            console.log("saveCache hatası: " + e);
        }
    }

    function loadCache(key) {
        try {
            var db = getDatabase();
            var res = "";
            db.transaction(function(tx) {
                var rs = tx.executeSql('SELECT value FROM cache WHERE key = ?', [key]);
                if (rs.rows.length > 0) {
                    res = rs.rows.item(0).value;
                }
            });
            return res;
        } catch(e) {
            console.log("loadCache hatası: " + e);
            return "";
        }
    }

    function sendTweet(text, imgPath) {
        if ((!text || text.trim().length === 0) && (!imgPath || imgPath.trim().length === 0)) return;
        appWindow.isLoading = true;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                appWindow.isLoading = false;
                if (xhr.status === 200) {
                    tweetInput.text = "";
                    if (imagePathInput) imagePathInput.text = "";
                    pageStack.pop();
                    fetchTimeline();
                    showToast("Tweet Paylaşıldı", "✓", silicaHighlight);
                } else {
                    showToast("Gönderilemedi", "✕", "#FF4444");
                }
            }
        };
        xhr.open("POST", serverUrl + "/tweet");
        xhr.setRequestHeader("Content-Type", "application/json");
        var payload = { "text": text };
        if (imgPath && imgPath.trim().length > 0) {
            payload["image_path"] = imgPath.trim();
        }
        xhr.send(JSON.stringify(payload));
    }

    function bookmarkTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/bookmark");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }

    function unbookmarkTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/unbookmark");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }

    function fetchBookmarks() {
        appWindow.isLoading = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                appWindow.isLoading = false;
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        bookmarkTweetModel.clear();
                        if (res.data && res.data.length > 0) {
                            for (var i = 0; i < res.data.length; i++) {
                                bookmarkTweetModel.append(res.data[i]);
                            }
                        }
                    } catch (e) {
                        console.log("Yer imleri parse hatası: " + e);
                    }
                }
            }
        };
        xhr.open("GET", serverUrl + "/bookmarks");
        xhr.send();
    }

    function likeTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/like");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }

    function unlikeTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/unlike");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }

    function retweetTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/retweet");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }

    function unretweetTweet(tweetId) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", serverUrl + "/unretweet");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ "id": tweetId }));
    }
}
