package com.logseq.bonsaiandroid

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    var treeJson by remember { mutableStateOf(BonsaiAndroidNative.render(this)) }
                    BonsaiNode(
                        node = JSONObject(treeJson),
                        refresh = { treeJson = BonsaiAndroidNative.render(this) },
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BonsaiNode(node: JSONObject, refresh: () -> Unit) {
    val modifiers = node.optJSONArray("modifiers")
    BonsaiModifierWrappers(modifiers = modifiers, index = 0, refresh = refresh) {
        BonsaiNodeContent(node = node, modifier = modifiers.toLayoutModifier(), refresh = refresh)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BonsaiModifierWrappers(
    modifiers: JSONArray?,
    index: Int,
    refresh: () -> Unit,
    content: @Composable () -> Unit,
) {
    if (modifiers == null || index >= modifiers.length()) {
        content()
        return
    }

    val item = modifiers.getJSONObject(index)
    when (item.getString("type")) {
        "searchable" -> {
            val eventId = item.getInt("eventId")
            var value by remember(eventId, item.optString("text")) {
                mutableStateOf(item.optString("text"))
            }
            Column {
                OutlinedTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = value,
                    singleLine = true,
                    placeholder = { Text("Search") },
                    onValueChange = {
                        value = it
                        BonsaiAndroidNative.dispatchChange(eventId, it)
                        refresh()
                    },
                )
                Spacer(modifier = Modifier.height(8.dp))
                BonsaiModifierWrappers(modifiers, index + 1, refresh, content)
            }
        }
        "toolbar" -> {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    val items = item.getJSONArray("items")
                    for (itemIndex in 0 until items.length()) {
                        val toolbarItem = items.getJSONObject(itemIndex)
                        TextButton(
                            onClick = {
                                BonsaiAndroidNative.dispatchClick(toolbarItem.getInt("eventId"))
                                refresh()
                            },
                        ) {
                            Text(toolbarItem.getString("title"))
                        }
                    }
                }
                BonsaiModifierWrappers(modifiers, index + 1, refresh, content)
            }
        }
        "sheet" -> {
            BonsaiModifierWrappers(modifiers, index + 1, refresh, content)
            if (item.optBoolean("isPresented", false)) {
                ModalBottomSheet(
                    onDismissRequest = {
                        if (!item.isNull("dismissEventId")) {
                            BonsaiAndroidNative.dispatchClick(item.getInt("dismissEventId"))
                        }
                        refresh()
                    },
                ) {
                    BonsaiNode(item.getJSONObject("content"), refresh)
                }
            }
        }
        else -> BonsaiModifierWrappers(modifiers, index + 1, refresh, content)
    }
}

@Composable
private fun BonsaiNodeContent(node: JSONObject, modifier: Modifier, refresh: () -> Unit) {
    when (node.getString("type")) {
        "text" -> Text(text = node.getString("text"), modifier = modifier)
        "button" -> {
            val eventId = node.getInt("eventId")
            Button(
                modifier = modifier,
                onClick = {
                    BonsaiAndroidNative.dispatchClick(eventId)
                    refresh()
                },
            ) {
                Text(node.getString("text"))
            }
        }
        "textField" -> {
            val eventId = node.getInt("eventId")
            var value by remember(node.optString("text")) { mutableStateOf(node.optString("text")) }
            OutlinedTextField(
                modifier = modifier,
                value = value,
                placeholder = node.optString("placeholder").takeIf { it.isNotBlank() }?.let { { Text(it) } },
                onValueChange = {
                    value = it
                    BonsaiAndroidNative.dispatchChange(eventId, it)
                    refresh()
                },
            )
        }
        "vstack" -> {
            Column(
                modifier = modifier,
                verticalArrangement = Arrangement.spacedBy(node.optDouble("spacing", 0.0).dp),
            ) {
                val children = node.getJSONArray("children")
                for (index in 0 until children.length()) {
                    BonsaiNode(children.getJSONObject(index), refresh)
                }
            }
        }
        "hstack" -> {
            Row(
                modifier = modifier,
                horizontalArrangement = Arrangement.spacedBy(node.optDouble("spacing", 0.0).dp),
            ) {
                val children = node.getJSONArray("children")
                for (index in 0 until children.length()) {
                    BonsaiNode(children.getJSONObject(index), refresh)
                }
            }
        }
        "scrollView" -> {
            Column(modifier = modifier.verticalScroll(rememberScrollState())) {
                BonsaiNode(node.getJSONObject("child"), refresh)
            }
        }
        "list" -> {
            LazyColumn(modifier = modifier) {
                items(node.getJSONArray("rows").objects(), key = { it.getString("key") }) {
                    BonsaiNode(it.getJSONObject("node"), refresh)
                }
            }
        }
        "navigationStack" -> {
            Column(modifier = modifier) {
                val children = node.getJSONArray("children")
                for (index in 0 until children.length()) {
                    BonsaiNode(children.getJSONObject(index), refresh)
                }
            }
        }
        "image" -> Text(text = node.getString("name"), modifier = modifier)
        "customView" -> Text(text = node.getString("kind"), modifier = modifier)
    }
}

private fun JSONArray?.toLayoutModifier(): Modifier {
    var modifier: Modifier = Modifier
    if (this == null) return modifier
    forEachObject { item ->
        when (item.getString("type")) {
            "padding" -> {
                modifier = modifier.padding(
                    start = item.optDouble("start", 0.0).dp,
                    top = item.optDouble("top", 0.0).dp,
                    end = item.optDouble("end", 0.0).dp,
                    bottom = item.optDouble("bottom", 0.0).dp,
                )
            }
            "frame" -> {
                if (!item.isNull("width")) modifier = modifier.width(item.getDouble("width").dp)
                if (!item.isNull("height")) modifier = modifier.height(item.getDouble("height").dp)
            }
        }
    }
    return modifier
}

private fun JSONArray.forEachObject(f: (JSONObject) -> Unit) {
    for (index in 0 until length()) f(getJSONObject(index))
}

private fun JSONArray.objects(): List<JSONObject> =
    buildList {
        forEachObject { add(it) }
    }
