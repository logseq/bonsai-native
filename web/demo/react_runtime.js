import React from "react";
import { createRoot } from "react-dom/client";

function classNames(...names) {
  return names.filter(Boolean).join(" ");
}

function modifierStyle(modifiers) {
  const style = {};

  for (const modifier of modifiers || []) {
    if (modifier.type === "padding") {
      style.paddingTop = modifier.top;
      style.paddingInlineStart = modifier.start;
      style.paddingBottom = modifier.bottom;
      style.paddingInlineEnd = modifier.end;
    } else if (modifier.type === "frame") {
      if (modifier.width !== null) {
        style.width = modifier.width;
      }
      if (modifier.height !== null) {
        style.height = modifier.height;
      }
    }
  }

  return style;
}

function renderNode(node, callbacks) {
  const style = modifierStyle(node.modifiers);

  switch (node.type) {
    case "text":
      return React.createElement("p", { className: "demo-text", style }, node.text);
    case "button":
      return React.createElement(
        "button",
        {
          className: "demo-button",
          disabled: !node.enabled,
          onClick: () => callbacks.click(node.eventId),
          style,
        },
        node.text,
      );
    case "textField":
      return React.createElement("input", {
        className: "demo-input",
        onChange: (event) => callbacks.change(node.eventId, event.target.value),
        placeholder: node.placeholder || "",
        style,
        value: node.text,
      });
    case "vstack":
    case "hstack":
      return React.createElement(
        "div",
        {
          className: classNames("demo-stack", node.type === "hstack" && "demo-stack-row"),
          style: { ...style, gap: node.spacing ?? 0 },
        },
        node.children.map((child, index) =>
          React.createElement(React.Fragment, { key: index }, renderNode(child, callbacks)),
        ),
      );
    case "list":
      return React.createElement(
        "div",
        { className: "demo-list", style },
        node.rows.map((row) =>
          React.createElement("div", { className: "demo-row", key: row.key }, renderNode(row.node, callbacks)),
        ),
      );
    case "scrollView":
      return React.createElement("div", { className: "demo-scroll", style }, renderNode(node.child, callbacks));
    case "navigationStack":
      return React.createElement(
        "div",
        { className: "demo-navigation", style },
        node.children.map((child, index) =>
          React.createElement(React.Fragment, { key: index }, renderNode(child, callbacks)),
        ),
      );
    case "image":
      return React.createElement("div", { className: "demo-image", style }, node.name);
    case "customView":
      return React.createElement("div", { className: "demo-custom", style }, node.kind);
    default:
      return React.createElement("pre", { className: "demo-unknown", style }, JSON.stringify(node, null, 2));
  }
}

function DemoApp({ renderJson, dispatchClick, dispatchChange, rerender }) {
  const tree = JSON.parse(renderJson());
  const callbacks = {
    click(eventId) {
      dispatchClick(eventId);
      rerender();
    },
    change(eventId, value) {
      dispatchChange(eventId)(value);
      rerender();
    },
  };

  return React.createElement(
    "main",
    { className: "demo-shell" },
    React.createElement("section", { className: "demo-panel" }, [
      React.createElement("h1", { key: "title" }, "Counter"),
      React.createElement("div", { className: "demo-surface", key: "surface" }, renderNode(tree, callbacks)),
    ]),
  );
}

export function createRenderer(rootId, renderJson, dispatchClick, dispatchChange) {
  const target = document.getElementById(rootId);
  const root = createRoot(target);

  const renderer = {
    render() {
      root.render(
        React.createElement(DemoApp, {
          dispatchChange,
          dispatchClick,
          renderJson,
          rerender: () => renderer.render(),
        }),
      );
    },
  };

  return renderer;
}
