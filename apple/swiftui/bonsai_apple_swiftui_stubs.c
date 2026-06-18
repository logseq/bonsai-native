#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/threads.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef void (*bonsai_native_event_callback)(int32_t event_id, const char *text);
typedef bool (*bonsai_native_launch_callback)(
  void *delegate,
  void *application,
  void *launch_options);

extern void bonsai_native_swiftui_run_application(bonsai_native_launch_callback callback);
extern void *bonsai_native_swiftui_create_node(int32_t raw_kind);
extern void bonsai_native_swiftui_release_node(void *node);
extern void bonsai_native_swiftui_set_text(void *node, const char *text);
extern void bonsai_native_swiftui_set_text_attributes(
  void *node,
  int32_t style,
  int32_t weight,
  int32_t color);
extern void bonsai_native_swiftui_set_placeholder(void *node, const char *text);
extern void bonsai_native_swiftui_set_spacing(void *node, double spacing);
extern void bonsai_native_swiftui_set_children(void *node, void **children, int32_t count);
extern void bonsai_native_swiftui_set_on_click(void *node, int32_t event_id);
extern void bonsai_native_swiftui_set_on_change(void *node, int32_t event_id);
extern void bonsai_native_swiftui_set_list_row_subtitle(void *node, const char *subtitle);
extern void bonsai_native_swiftui_set_list_row_trailing_text(
  void *node,
  const char *trailing_text);
extern void bonsai_native_swiftui_set_list_row_title_strikethrough(
  void *node,
  bool title_strikethrough);
extern void bonsai_native_swiftui_set_list_row_leading(
  void *node,
  const char *system_image,
  const char *selected_system_image,
  bool selected);
extern void bonsai_native_swiftui_set_list_row_leading_accessibility(
  void *node,
  const char *label);
extern void bonsai_native_swiftui_set_list_row_leading_event(void *node, int32_t event_id);
extern void bonsai_native_swiftui_clear_list_row_actions(void *node);
extern void bonsai_native_swiftui_append_list_row_action(
  void *node,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_set_searchable(void *node, int32_t event_id, const char *text);
extern void bonsai_native_swiftui_set_sheet(
  void *node,
  void *content,
  bool is_presented,
  int32_t dismiss_event_id);
extern void bonsai_native_swiftui_set_padding(
  void *node,
  double top,
  double leading,
  double bottom,
  double trailing);
extern void bonsai_native_swiftui_set_frame(void *node, double width, double height);
extern void bonsai_native_swiftui_clear_tabs(
  void *node,
  const char *selected,
  int32_t event_id);
extern void bonsai_native_swiftui_append_tab(
  void *node,
  const char *id,
  const char *title,
  const char *system_image,
  int32_t role);
extern void *bonsai_native_swiftui_make_controller(
  void *root,
  bonsai_native_event_callback callback);
extern void bonsai_native_swiftui_update_controller(void *controller, void *root);
extern void bonsai_native_swiftui_release_controller(void *controller);
extern void *bonsai_native_swiftui_make_window(
  void *root,
  bonsai_native_event_callback callback);
extern void bonsai_native_swiftui_release_window(void *window);

static value *event_callback = NULL;
static value *launch_callback = NULL;

static value value_of_pointer(void *pointer);

static void swiftui_event_callback(int32_t event_id, const char *text)
{
  if (event_callback == NULL) {
    return;
  }

  CAMLparam0();
  CAMLlocal2(text_value, result);
  text_value = text == NULL ? Val_none : caml_alloc_some(caml_copy_string(text));
  result = caml_callback2_exn(*event_callback, Val_int(event_id), text_value);
  (void)result;
  CAMLreturn0;
}

static bool swiftui_launch_callback(void *delegate, void *application, void *launch_options)
{
  if (launch_callback == NULL) {
    return true;
  }

  CAMLparam0();
  CAMLlocal4(delegate_value, application_value, launch_options_value, result);
  delegate_value = value_of_pointer(delegate);
  application_value = value_of_pointer(application);
  launch_options_value = value_of_pointer(launch_options);
  result =
    caml_callback3_exn(*launch_callback, delegate_value, application_value, launch_options_value);
  if (Is_exception_result(result)) {
    CAMLreturnT(bool, false);
  }
  CAMLreturnT(bool, Bool_val(result));
}

static void *pointer_val(value raw_value)
{
  return (void *)Nativeint_val(raw_value);
}

static value value_of_pointer(void *pointer)
{
  return caml_copy_nativeint((intnat)pointer);
}

CAMLprim value bonsai_apple_swiftui_register_event_callback(value callback)
{
  CAMLparam1(callback);
  if (event_callback == NULL) {
    event_callback = caml_stat_alloc(sizeof(value));
    *event_callback = callback;
    caml_register_generational_global_root(event_callback);
  } else {
    caml_modify_generational_global_root(event_callback, callback);
  }
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_run_application(value callback)
{
  CAMLparam1(callback);
  if (launch_callback == NULL) {
    launch_callback = caml_stat_alloc(sizeof(value));
    *launch_callback = callback;
    caml_register_generational_global_root(launch_callback);
  } else {
    caml_modify_generational_global_root(launch_callback, callback);
  }
  bonsai_native_swiftui_run_application(swiftui_launch_callback);
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_create_node(value raw_kind)
{
  CAMLparam1(raw_kind);
  CAMLreturn(value_of_pointer(bonsai_native_swiftui_create_node(Int_val(raw_kind))));
}

CAMLprim value bonsai_apple_swiftui_release_node(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_release_node(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_text(value node, value text)
{
  CAMLparam2(node, text);
  bonsai_native_swiftui_set_text(pointer_val(node), String_val(text));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_text_attributes(
  value node,
  value style,
  value weight,
  value color)
{
  CAMLparam4(node, style, weight, color);
  bonsai_native_swiftui_set_text_attributes(
    pointer_val(node),
    Int_val(style),
    Int_val(weight),
    Int_val(color));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_placeholder(value node, value placeholder)
{
  CAMLparam2(node, placeholder);
  bonsai_native_swiftui_set_placeholder(
    pointer_val(node),
    Is_none(placeholder) ? NULL : String_val(Some_val(placeholder)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_spacing(value node, value spacing)
{
  CAMLparam2(node, spacing);
  bonsai_native_swiftui_set_spacing(
    pointer_val(node),
    Is_none(spacing) ? -1.0 : Double_val(Some_val(spacing)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_children(value node, value children)
{
  CAMLparam2(node, children);
  mlsize_t count = Wosize_val(children);
  void **child_pointers = NULL;
  if (count > 0) {
    child_pointers = caml_stat_alloc(sizeof(void *) * count);
    for (mlsize_t i = 0; i < count; i++) {
      child_pointers[i] = pointer_val(Field(children, i));
    }
  }

  bonsai_native_swiftui_set_children(pointer_val(node), child_pointers, (int32_t)count);
  if (child_pointers != NULL) {
    caml_stat_free(child_pointers);
  }
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_on_click(value node, value event_id)
{
  CAMLparam2(node, event_id);
  bonsai_native_swiftui_set_on_click(pointer_val(node), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_on_change(value node, value event_id)
{
  CAMLparam2(node, event_id);
  bonsai_native_swiftui_set_on_change(pointer_val(node), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_subtitle(value node, value subtitle)
{
  CAMLparam2(node, subtitle);
  bonsai_native_swiftui_set_list_row_subtitle(
    pointer_val(node),
    Is_none(subtitle) ? NULL : String_val(Some_val(subtitle)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_trailing_text(value node, value trailing_text)
{
  CAMLparam2(node, trailing_text);
  bonsai_native_swiftui_set_list_row_trailing_text(
    pointer_val(node),
    Is_none(trailing_text) ? NULL : String_val(Some_val(trailing_text)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_title_strikethrough(
  value node,
  value title_strikethrough)
{
  CAMLparam2(node, title_strikethrough);
  bonsai_native_swiftui_set_list_row_title_strikethrough(
    pointer_val(node),
    Bool_val(title_strikethrough));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_leading(
  value node,
  value system_image,
  value selected_system_image,
  value selected)
{
  CAMLparam4(node, system_image, selected_system_image, selected);
  bonsai_native_swiftui_set_list_row_leading(
    pointer_val(node),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Is_none(selected_system_image) ? NULL : String_val(Some_val(selected_system_image)),
    Bool_val(selected));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_leading_accessibility(
  value node,
  value label)
{
  CAMLparam2(node, label);
  bonsai_native_swiftui_set_list_row_leading_accessibility(pointer_val(node), String_val(label));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_leading_event(value node, value event_id)
{
  CAMLparam2(node, event_id);
  bonsai_native_swiftui_set_list_row_leading_event(pointer_val(node), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_list_row_actions(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_list_row_actions(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_list_row_action(
  value node,
  value title,
  value system_image,
  value style,
  value event_id)
{
  CAMLparam5(node, title, system_image, style, event_id);
  bonsai_native_swiftui_append_list_row_action(
    pointer_val(node),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_searchable(value node, value event_id, value text)
{
  CAMLparam3(node, event_id, text);
  bonsai_native_swiftui_set_searchable(pointer_val(node), Int_val(event_id), String_val(text));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_searchable(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_set_searchable(pointer_val(node), -1, "");
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_sheet(
  value node,
  value content,
  value is_presented,
  value dismiss_event_id)
{
  CAMLparam4(node, content, is_presented, dismiss_event_id);
  bonsai_native_swiftui_set_sheet(
    pointer_val(node),
    Is_none(content) ? NULL : pointer_val(Some_val(content)),
    Bool_val(is_presented),
    Int_val(dismiss_event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_padding(
  value node,
  value top,
  value leading,
  value bottom,
  value trailing)
{
  CAMLparam5(node, top, leading, bottom, trailing);
  bonsai_native_swiftui_set_padding(
    pointer_val(node),
    Double_val(top),
    Double_val(leading),
    Double_val(bottom),
    Double_val(trailing));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_frame(value node, value width, value height)
{
  CAMLparam3(node, width, height);
  bonsai_native_swiftui_set_frame(pointer_val(node), Double_val(width), Double_val(height));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_tabs(value node, value selected, value event_id)
{
  CAMLparam3(node, selected, event_id);
  bonsai_native_swiftui_clear_tabs(pointer_val(node), String_val(selected), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_tab(
  value node,
  value id,
  value title,
  value system_image,
  value role)
{
  CAMLparam5(node, id, title, system_image, role);
  bonsai_native_swiftui_append_tab(
    pointer_val(node),
    String_val(id),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(role));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_make_controller(value root)
{
  CAMLparam1(root);
  CAMLreturn(value_of_pointer(
    bonsai_native_swiftui_make_controller(pointer_val(root), swiftui_event_callback)));
}

CAMLprim value bonsai_apple_swiftui_update_controller(value controller, value root)
{
  CAMLparam2(controller, root);
  bonsai_native_swiftui_update_controller(pointer_val(controller), pointer_val(root));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_release_controller(value controller)
{
  CAMLparam1(controller);
  bonsai_native_swiftui_release_controller(pointer_val(controller));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_make_window(value root)
{
  CAMLparam1(root);
  CAMLreturn(value_of_pointer(
    bonsai_native_swiftui_make_window(pointer_val(root), swiftui_event_callback)));
}

CAMLprim value bonsai_apple_swiftui_release_window(value window)
{
  CAMLparam1(window);
  bonsai_native_swiftui_release_window(pointer_val(window));
  CAMLreturn(Val_unit);
}
