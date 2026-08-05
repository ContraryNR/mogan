// DocumentMetadata.qml — 文档元数据弹窗（文档 → 元数据）。
// DialogShell + 内联 TextInput + DialogButtons 拼装。
// 字段由 C++ 经 metadataFields 注入（QVariantList<QVariantMap>），Repeater 按
// type 渲染：text → label + TextInput（单行，selectByMouse）。
//
// context property（C++ 注入）：metadataFields、dialogButtons、dpScale、isDark、
// closeBridge。OK：closeBridge.submit({key: value, ...})；
// Reset：closeBridge.choose(2)（C++ 返回 (tuple "reset")，Scheme 侧循环重调）。
// 无 Cancel 按钮——关窗即丢弃改动（一次性提交语义）。

import QtQuick
import "atoms"

DialogShell {
    id: root
    implicitWidth: 420
    // 动态高度：内边距 + 字段行（行高 + 行间距）+ 按钮区。与 C++ logicH 同源。
    implicitHeight: implicitMargins * 2 + fields.length * (rowH + 12 * Theme.scaleFactor) + 64 * Theme.scaleFactor
    implicitMargins: 24 * Theme.scaleFactor

    property var fields: typeof metadataFields !== "undefined" ? metadataFields : []
    property var buttonLabels: typeof dialogButtons !== "undefined" ? dialogButtons : ["OK", "Reset"]
    property real rowH: Theme.rowH

    // 字段运行时值：Repeater 的 modelData 只读，故另起对象存当前值，
    // OK 时整包提交。onTextChanged 里改对象再回赋，触发 binding 刷新。
    property var values: {
        var v = {};
        for (var i = 0; i < fields.length; i++)
            v[fields[i].key] = fields[i].value;
        return v;
    }

    content: Column {
        clip: true
        spacing: 12 * Theme.scaleFactor

        Repeater {
            model: root.fields
            delegate: Item {
                width: parent.width
                height: rowH

                // 左：字段标签。
                Text {
                    id: fieldLabel
                    text: modelData.label
                    color: Theme.fg
                    font.pixelSize: Theme.fontBody
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 右：文本输入框（单行，selectByMouse，失焦/回车写本地 values）。
                Rectangle {
                    id: fieldBg
                    width: 240 * Theme.scaleFactor
                    height: rowH * 0.7
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fieldBg
                    border.width: Theme.borderW
                    border.color: fieldInput.activeFocus ? Theme.selectBorder : Theme.borderClr
                    radius: Theme.radius

                    TextInput {
                        id: fieldInput
                        anchors.fill: parent
                        anchors.margins: Theme.comboPad
                        text: root.values[modelData.key] !== undefined ? root.values[modelData.key] : ""
                        color: Theme.fg
                        font.pixelSize: Theme.fontBody
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        onTextChanged: {
                            var cur = root.values;
                            cur[modelData.key] = text;
                            root.values = cur;
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: 8 * Theme.scaleFactor
        }

        DialogButtons {
            anchors.horizontalCenter: parent.horizontalCenter
            buttonLabels: root.buttonLabels
            onClicked: function (index) {
                if (index === 0)
                    closeBridge.submit(root.values);
                else if (index === 1)
                    closeBridge.choose(2);
            }
        }
    }
}
