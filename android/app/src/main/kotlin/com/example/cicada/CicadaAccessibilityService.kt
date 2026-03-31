package com.example.cicada

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.ClipData
import android.content.ClipboardManager
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class CicadaAccessibilityService : AccessibilityService() {
    companion object {
        var instance: CicadaAccessibilityService? = null
    }

    override fun onServiceConnected() {
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    /** Parse UI tree, return clickable/text nodes with bounds. */
    fun captureScreenHierarchy(): String {
        val root = rootInActiveWindow ?: return "Empty Screen"
        val sb = StringBuilder()
        parseNode(root, sb)
        return sb.toString()
    }

    private fun parseNode(node: AccessibilityNodeInfo?, sb: StringBuilder, depth: Int = 0) {
        node ?: return
        if (depth > 30) return
        if (node.isClickable || !node.text.isNullOrEmpty()) {
            val rect = Rect()
            node.getBoundsInScreen(rect)
            sb.append("{text:'${node.text}', pkg:'${node.packageName}', bounds:[${rect.left},${rect.top},${rect.right},${rect.bottom}]}\n")
        }
        for (i in 0 until node.childCount) parseNode(node.getChild(i), sb, depth + 1)
    }

    /** Simulate tap at screen coordinates. */
    fun click(x: Int, y: Int) {
        val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 50))
            .build()
        dispatchGesture(gesture, null, null)
    }

    /** Find a node by text content, return its center coordinates or null. */
    fun findNodeByText(text: String): Pair<Int, Int>? {
        val root = rootInActiveWindow ?: return null
        return searchNodeByText(root, text)
    }

    private fun searchNodeByText(node: AccessibilityNodeInfo?, text: String, depth: Int = 0): Pair<Int, Int>? {
        node ?: return null
        if (depth > 30) return null
        val nodeText = node.text?.toString() ?: ""
        if (nodeText.contains(text, ignoreCase = true)) {
            val rect = Rect()
            node.getBoundsInScreen(rect)
            return Pair(rect.centerX(), rect.centerY())
        }
        for (i in 0 until node.childCount) {
            val result = searchNodeByText(node.getChild(i), text, depth + 1)
            if (result != null) return result
        }
        return null
    }

    /** Input text into the currently focused field. */
    fun inputText(text: String): Boolean {
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }

        // Try focused input node first
        val focusedNode = findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
        if (focusedNode != null) {
            if (focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)) return true
        }

        // Try finding any editable node
        val root = rootInActiveWindow
        if (root != null) {
            val editableNode = findEditableNode(root)
            if (editableNode != null) {
                if (editableNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)) return true
                // Fallback: clipboard paste
                val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("input", text))
                if (editableNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)) return true
            }
        }
        return false
    }

    private fun findEditableNode(node: AccessibilityNodeInfo, depth: Int = 0): AccessibilityNodeInfo? {
        if (depth > 20) return null
        if (node.isEditable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findEditableNode(child, depth + 1)
            if (result != null) return result
        }
        return null
    }

    /** Check if the foreground app is Termux. */
    fun isForegroundTermux(): Boolean {
        val root = rootInActiveWindow ?: return false
        return root.packageName?.toString() == "com.termux"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
