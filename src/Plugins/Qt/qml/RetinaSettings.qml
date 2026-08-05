// RetinaSettings.qml — 高分屏设置弹窗（视图 → 高分屏设置）。
// DialogShell + Toggle + EnumCombo + DialogButtons 拼装。
// 字段由 C++ 经 retinaFields 注入（QVariantList<QVariantMap>），Repeater 按
// type 分发：toggle → Toggle（value "on"/"off" ↔ bool）、enum → EnumCombo。
//
// context property（C++ 注入）：retinaFields、dialogButtons、dpScale、isDark、
// closeBridge。OK：closeBridge.submit({key: value, ...})；
// Reset：closeBridge.choose(2)（C++ 返回 (tuple "reset")，Scheme 侧循环重调）；
// Cancel：closeBridge.cancel()。

import QtQuick
import "atoms"

DialogShell {
    id: root
    implicitWidth: 420
    // 动态高度：内边距 + 字段行（行高 + 行间距）+ 按钮区。与 C++ logicH 同源。
    implicitHeight: implicitMargins * 2 + fields.length * (rowH + 12 * Theme.scaleFactor) + 64 * Theme.scaleFactor
    implicitMargins: 24 * Theme.scaleFactor

    property var fields: typeof retinaFields !== "undefined" ? retinaFields : []
    property var buttonLabels: typeof dialogButtons !== "undefined" ? dialogButtons : ["OK", "Reset", "Cancel"]
    property real rowH: Theme.rowH

    // 字段运行时值：Repeater 的 modelData 只读，故另起对象存当前值，
    // OK 时整包提交。onChanged/onToggled 里改对象再回赋，触发 binding 刷新。
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
                height: modelData.type === "toggle" ? toggleRow.height : comboRow.height

                // toggle 字段（布尔偏好，value 为 "on"/"off"）
                Toggle {
                    id: toggleRow
                    visible: modelData.type === "toggle"
                    width: parent.width
                    label: modelData.label
                    value: root.values[modelData.key] === "on"
                    onToggled: function (v) {
                        var cur = root.values;
                        cur[modelData.key] = v ? "on" : "off";
                        root.values = cur;
                    }
                }

                // enum 字段（缩放比例，value 为 "1"/"1.2"/... ）
                EnumCombo {
                    id: comboRow
                    visible: modelData.type === "enum"
                    width: parent.width
                    label: modelData.label
                    options: modelData.options !== undefined ? modelData.options : []
                    value: root.values[modelData.key] !== undefined ? root.values[modelData.key] : ""
                    onChanged: function (v) {
                        var cur = root.values;
                        cur[modelData.key] = v;
                        root.values = cur;
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
                else
                    closeBridge.cancel();
            }
        }
    }
}
