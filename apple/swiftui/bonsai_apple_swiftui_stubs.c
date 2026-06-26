#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/threads.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>

typedef void (*bonsai_native_event_callback)(int32_t event_id, const char *text);
typedef void (*bonsai_native_http_callback)(
  void *context,
  bool success,
  const char *response);
typedef bool (*bonsai_native_launch_callback)(
  void *delegate,
  void *application,
  void *launch_options);

extern void bonsai_native_swiftui_run_application(bonsai_native_launch_callback callback);
extern void bonsai_native_swiftui_set_clipboard_text(const char *text);
extern void bonsai_native_swiftui_set_clipboard_image_file(const char *path);
extern void bonsai_native_swiftui_toggle_audio_file_playback(const char *path);
extern void bonsai_native_swiftui_start_audio_recording(void);
extern char *bonsai_native_swiftui_stop_audio_recording_and_transcribe(void);
extern void *bonsai_native_swiftui_create_node(int32_t raw_kind);
extern void bonsai_native_swiftui_release_node(void *node);
extern void bonsai_native_swiftui_set_text(void *node, const char *text);
extern void bonsai_native_swiftui_set_system_image(void *node, const char *system_image);
extern void bonsai_native_swiftui_set_button_subtitle(void *node, const char *subtitle);
extern void bonsai_native_swiftui_set_button_style(void *node, int32_t style);
extern void bonsai_native_swiftui_set_title_visible(void *node, bool is_visible);
extern void bonsai_native_swiftui_set_keyboard_dismiss_controls(void *node, bool is_enabled);
extern void bonsai_native_swiftui_set_scroll_dismisses_keyboard(void *node, bool is_enabled);
extern void bonsai_native_swiftui_set_image_source(void *node, int32_t source);
extern void bonsai_native_swiftui_set_image_color(void *node, int32_t color);
extern void bonsai_native_swiftui_set_image_style(
  void *node,
  double max_height,
  double corner_radius);
extern void bonsai_native_swiftui_set_text_attributes(
  void *node,
  int32_t style,
  int32_t weight,
  int32_t color);
extern void bonsai_native_swiftui_set_enabled(void *node, bool is_enabled);
extern void bonsai_native_swiftui_set_placeholder(void *node, const char *text);
extern void bonsai_native_swiftui_set_text_field_style(void *node, int32_t style);
extern void bonsai_native_swiftui_set_text_field_axis(void *node, int32_t axis);
extern void bonsai_native_swiftui_set_text_field_secure(void *node, bool is_secure);
extern void bonsai_native_swiftui_set_toggle(void *node, bool is_on, int32_t event_id);
extern void bonsai_native_swiftui_set_progress(void *node, double value);
extern void bonsai_native_swiftui_set_spacing(void *node, double spacing);
extern void bonsai_native_swiftui_set_children(void *node, void **children, int32_t count);
extern void bonsai_native_swiftui_set_list_behavior(
  void *node,
  int32_t refresh_event_id,
  int32_t delete_event_id,
  int32_t move_event_id,
  bool edit_mode);
extern void bonsai_native_swiftui_set_on_click(void *node, int32_t event_id);
extern void bonsai_native_swiftui_set_navigation_link_callbacks(
  void *node,
  int32_t activate_event_id,
  int32_t deactivate_event_id);
extern void bonsai_native_swiftui_set_navigation_link_value(void *node, const char *value);
extern void bonsai_native_swiftui_set_tap_action(void *node, int32_t event_id);
extern void bonsai_native_swiftui_set_on_change(void *node, int32_t event_id);
extern void bonsai_native_swiftui_set_list_row_subtitle(void *node, const char *subtitle);
extern void bonsai_native_swiftui_set_list_row_trailing_text(
  void *node,
  const char *trailing_text);
extern void bonsai_native_swiftui_set_list_row_content_style(
  void *node,
  int32_t content_style);
extern void bonsai_native_swiftui_set_list_row_accessory(
  void *node,
  int32_t accessory);
extern void bonsai_native_swiftui_set_list_row_title_strikethrough(
  void *node,
  bool title_strikethrough);
extern void bonsai_native_swiftui_set_list_row_leading_system_image(
  void *node,
  const char *system_image);
extern void bonsai_native_swiftui_set_list_row_preview_image_path(
  void *node,
  const char *image_path);
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
extern void bonsai_native_swiftui_clear_list_row_menu_actions(void *node);
extern void bonsai_native_swiftui_append_list_row_menu_action(
  void *node,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_clear_context_menu_actions(void *node);
extern void bonsai_native_swiftui_append_context_menu_action(
  void *node,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_set_searchable(
  void *node,
  int32_t event_id,
  const char *text,
  const char *prompt);
extern void bonsai_native_swiftui_set_sheet(
  void *node,
  void *content,
  bool is_presented,
  int32_t dismiss_event_id);
extern void bonsai_native_swiftui_set_sheet_detents(
  void *node,
  int32_t *kinds,
  double *values,
  int32_t count);
extern void bonsai_native_swiftui_set_safe_area_inset_bottom(void *node, void *content);
extern void bonsai_native_swiftui_set_popover(
  void *node,
  void *content,
  bool is_presented,
  int32_t dismiss_event_id);
extern void bonsai_native_swiftui_set_alert(
  void *node,
  bool is_presented,
  int32_t dismiss_event_id,
  const char *title,
  const char *message);
extern void bonsai_native_swiftui_set_alert_text_field(
  void *node,
  const char *text,
  const char *placeholder,
  int32_t event_id);
extern void bonsai_native_swiftui_clear_alert_actions(void *node);
extern void bonsai_native_swiftui_append_alert_action(
  void *node,
  const char *id,
  const char *title,
  int32_t role,
  bool is_enabled,
  int32_t event_id);
extern void bonsai_native_swiftui_set_confirmation_dialog(
  void *node,
  bool is_presented,
  int32_t dismiss_event_id,
  const char *title,
  const char *message);
extern void bonsai_native_swiftui_clear_confirmation_dialog_actions(void *node);
extern void bonsai_native_swiftui_append_confirmation_dialog_action(
  void *node,
  const char *id,
  const char *title,
  int32_t role,
  bool is_enabled,
  int32_t event_id);
extern void bonsai_native_swiftui_set_navigation_title(void *node, const char *title);
extern void bonsai_native_swiftui_clear_toolbar(void *node);
extern void bonsai_native_swiftui_append_toolbar_item(
  void *node,
  const char *id,
  const char *title,
  const char *system_image,
  bool is_title_visible,
  bool is_enabled,
  const char *share_url,
  int32_t event_id);
extern void bonsai_native_swiftui_append_toolbar_menu_action(
  void *node,
  const char *item_id,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id,
  bool starts_section,
  const char *export_filename,
  const char *export_content_type,
  const char *export_content);
extern void bonsai_native_swiftui_set_padding(
  void *node,
  double top,
  double leading,
  double bottom,
  double trailing);
extern void bonsai_native_swiftui_set_regular_material_panel(
  void *node,
  double corner_radius);
extern void bonsai_native_swiftui_set_secondary_fill_panel(
  void *node,
  double corner_radius,
  double opacity);
extern void bonsai_native_swiftui_set_liquid_glass_panel(
  void *node,
  double corner_radius,
  bool is_transparent,
  int32_t tint_color,
  double tint_opacity);
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
extern void bonsai_native_swiftui_clear_sidebar_shell(
  void *node,
  const char *title,
  int compact_top_bar_visible,
  const char *bottom_search_placeholder,
  const char *bottom_search_text,
  int32_t bottom_search_event_id);
extern void bonsai_native_swiftui_set_sidebar_header_action(
  void *node,
  const char *header_action_id,
  const char *header_action_title,
  const char *header_action_system_image,
  const char *header_action_avatar_image,
  const char *header_action_avatar_initial,
  int32_t header_action_event_id);
extern void bonsai_native_swiftui_append_sidebar_action(
  void *node,
  const char *id,
  const char *title,
  const char *subtitle,
  const char *system_image,
  int32_t event_id);
extern void bonsai_native_swiftui_append_sidebar_action_menu_action(
  void *node,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_set_sidebar_history_title(
  void *node,
  const char *title);
extern void bonsai_native_swiftui_append_sidebar_history_action(
  void *node,
  const char *id,
  const char *title,
  const char *subtitle,
  const char *system_image,
  int32_t event_id);
extern void bonsai_native_swiftui_append_sidebar_history_action_menu_action(
  void *node,
  const char *title,
  const char *system_image,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_set_sidebar_bottom_action(
  void *node,
  const char *id,
  const char *title,
  const char *system_image,
  int32_t event_id,
  int32_t chrome);
extern void bonsai_native_swiftui_set_section(void *node, const char *title);
extern void bonsai_native_swiftui_clear_picker(
  void *node,
  const char *title,
  const char *selected,
  int32_t style,
  int32_t event_id);
extern void bonsai_native_swiftui_append_picker_option(
  void *node,
  const char *id,
  const char *title);
extern void bonsai_native_swiftui_set_file_exporter(
  void *node,
  const char *filename,
  const char *content_type,
  const char *content);
extern void bonsai_native_swiftui_set_share_link(void *node, const char *url);
extern void bonsai_native_swiftui_set_file_importer(
  void *node,
  const char **allowed_types,
  int32_t count,
  int32_t event_id);
extern void bonsai_native_swiftui_set_slider(
  void *node,
  const char *title,
  double value,
  double min,
  double max,
  int32_t event_id);
extern void bonsai_native_swiftui_set_stepper(
  void *node,
  const char *title,
  int32_t value,
  int32_t min,
  int32_t max,
  int32_t step,
  int32_t event_id);
extern void bonsai_native_swiftui_set_date_picker(
  void *node,
  const char *title,
  const char *selected,
  int32_t event_id);
extern void bonsai_native_swiftui_set_color_picker(
  void *node,
  const char *title,
  const char *selected,
  int32_t event_id);
extern void bonsai_native_swiftui_clear_menu(
  void *node,
  const char *title,
  const char *system_image);
extern void bonsai_native_swiftui_append_menu_action(
  void *node,
  const char *id,
  const char *title,
  const char *system_image,
  int32_t style,
  bool is_enabled,
  int32_t event_id);
extern void bonsai_native_swiftui_set_disclosure_group(
  void *node,
  const char *title,
  bool is_expanded,
  int32_t event_id);
extern void bonsai_native_swiftui_set_navigation_path_stack(
  void *node,
  const char **path,
  int32_t path_count,
  int32_t event_id,
  const char **destinations,
  int32_t destination_count);
extern void bonsai_native_swiftui_set_image_payload_mode(void *node, bool wants_payload);
extern void *bonsai_native_swiftui_make_controller(
  void *root,
  bonsai_native_event_callback callback);
extern void bonsai_native_swiftui_update_controller(void *controller, void *root);
extern void bonsai_native_swiftui_release_controller(void *controller);
extern void *bonsai_native_swiftui_make_window(
  void *root,
  bonsai_native_event_callback callback);
extern void bonsai_native_swiftui_release_window(void *window);
extern void bonsai_native_swiftui_http_send_json(
  const char *method,
  const char *url,
  const char *authorization,
  const char *body,
  double timeout_seconds,
  void *context,
  bonsai_native_http_callback callback);

static value *event_callback = NULL;
static value *launch_callback = NULL;

struct bonsai_main_callback {
  value callback;
};

struct bonsai_http_context {
  value *callback;
};

static value value_of_pointer(void *pointer);

static void run_ocaml_callback_on_main(void *context)
{
  struct bonsai_main_callback *main_callback = context;
  caml_acquire_runtime_system();
  caml_callback(main_callback->callback, Val_unit);
  caml_remove_generational_global_root(&main_callback->callback);
  caml_release_runtime_system();
  free(main_callback);
}

CAMLprim value bonsai_apple_swiftui_run_on_main(value callback)
{
  CAMLparam1(callback);
  struct bonsai_main_callback *main_callback = malloc(sizeof(struct bonsai_main_callback));
  if (main_callback == NULL) {
    caml_failwith("Unable to allocate main-thread callback");
  }
  main_callback->callback = callback;
  caml_register_generational_global_root(&main_callback->callback);
  dispatch_async_f(dispatch_get_main_queue(), main_callback, run_ocaml_callback_on_main);
  CAMLreturn(Val_unit);
}

static void swiftui_event_callback(int32_t event_id, const char *text)
{
  if (event_callback == NULL) {
    return;
  }

  caml_acquire_runtime_system();
  CAMLparam0();
  CAMLlocal2(text_value, result);
  text_value = text == NULL ? Val_none : caml_alloc_some(caml_copy_string(text));
  result = caml_callback2_exn(*event_callback, Val_int(event_id), text_value);
  (void)result;
  CAMLdrop;
  caml_release_runtime_system();
}

static bool swiftui_launch_callback(void *delegate, void *application, void *launch_options)
{
  if (launch_callback == NULL) {
    return true;
  }

  bool should_finish_launching = false;
  caml_acquire_runtime_system();
  CAMLparam0();
  CAMLlocal4(delegate_value, application_value, launch_options_value, result);
  delegate_value = value_of_pointer(delegate);
  application_value = value_of_pointer(application);
  launch_options_value = value_of_pointer(launch_options);
  result =
    caml_callback3_exn(*launch_callback, delegate_value, application_value, launch_options_value);
  if (!Is_exception_result(result)) {
    should_finish_launching = Bool_val(result);
  }
  CAMLdrop;
  caml_release_runtime_system();
  return should_finish_launching;
}

static void swiftui_http_callback(void *raw_context, bool success, const char *response)
{
  if (raw_context == NULL) {
    return;
  }

  struct bonsai_http_context *context = raw_context;
  caml_acquire_runtime_system();
  CAMLparam0();
  CAMLlocal2(response_value, result);
  response_value = caml_copy_string(response == NULL ? "" : response);
  result = caml_callback2_exn(*context->callback, Val_bool(success), response_value);
  (void)result;
  caml_remove_generational_global_root(context->callback);
  caml_stat_free(context->callback);
  caml_stat_free(context);
  CAMLdrop;
  caml_release_runtime_system();
}

static void *pointer_val(value raw_value)
{
  return (void *)Nativeint_val(raw_value);
}

static const char *option_string_val(value raw_value)
{
  return Is_block(raw_value) ? String_val(Field(raw_value, 0)) : NULL;
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
  caml_release_runtime_system();
  bonsai_native_swiftui_run_application(swiftui_launch_callback);
  caml_acquire_runtime_system();
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_http_send_json(
  value method,
  value url,
  value authorization,
  value body,
  value timeout_seconds,
  value callback)
{
  CAMLparam5(method, url, authorization, body, timeout_seconds);
  CAMLxparam1(callback);
  struct bonsai_http_context *context = caml_stat_alloc(sizeof(struct bonsai_http_context));
  context->callback = caml_stat_alloc(sizeof(value));
  *context->callback = callback;
  caml_register_generational_global_root(context->callback);
  bonsai_native_swiftui_http_send_json(
    String_val(method),
    String_val(url),
    Is_none(authorization) ? NULL : String_val(Some_val(authorization)),
    String_val(body),
    Double_val(timeout_seconds),
    context,
    swiftui_http_callback);
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_http_send_json_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_http_send_json(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_clipboard_text(value text)
{
  CAMLparam1(text);
  bonsai_native_swiftui_set_clipboard_text(String_val(text));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_clipboard_image_file(value path)
{
  CAMLparam1(path);
  bonsai_native_swiftui_set_clipboard_image_file(String_val(path));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_toggle_audio_file_playback(value path)
{
  CAMLparam1(path);
  bonsai_native_swiftui_toggle_audio_file_playback(String_val(path));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_start_audio_recording(value unit)
{
  CAMLparam1(unit);
  bonsai_native_swiftui_start_audio_recording();
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_stop_audio_recording_and_transcribe(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(ocaml_result);
  char *result = bonsai_native_swiftui_stop_audio_recording_and_transcribe();
  ocaml_result = caml_copy_string(result == NULL ? "" : result);
  free(result);
  CAMLreturn(ocaml_result);
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

CAMLprim value bonsai_apple_swiftui_set_system_image(value node, value system_image)
{
  CAMLparam2(node, system_image);
  bonsai_native_swiftui_set_system_image(pointer_val(node), option_string_val(system_image));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_button_subtitle(value node, value subtitle)
{
  CAMLparam2(node, subtitle);
  bonsai_native_swiftui_set_button_subtitle(pointer_val(node), option_string_val(subtitle));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_button_style(value node, value style)
{
  CAMLparam2(node, style);
  bonsai_native_swiftui_set_button_style(pointer_val(node), Int_val(style));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_title_visible(value node, value is_visible)
{
  CAMLparam2(node, is_visible);
  bonsai_native_swiftui_set_title_visible(pointer_val(node), Bool_val(is_visible));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_keyboard_dismiss_controls(value node, value is_enabled)
{
  CAMLparam2(node, is_enabled);
  bonsai_native_swiftui_set_keyboard_dismiss_controls(
    pointer_val(node),
    Bool_val(is_enabled));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_scroll_dismisses_keyboard(value node, value is_enabled)
{
  CAMLparam2(node, is_enabled);
  bonsai_native_swiftui_set_scroll_dismisses_keyboard(
    pointer_val(node),
    Bool_val(is_enabled));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_image_source(value node, value source)
{
  CAMLparam2(node, source);
  bonsai_native_swiftui_set_image_source(pointer_val(node), Int_val(source));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_image_color(value node, value color)
{
  CAMLparam2(node, color);
  bonsai_native_swiftui_set_image_color(pointer_val(node), Int_val(color));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_image_style(
  value node,
  value max_height,
  value corner_radius)
{
  CAMLparam3(node, max_height, corner_radius);
  bonsai_native_swiftui_set_image_style(
    pointer_val(node),
    Double_val(max_height),
    Double_val(corner_radius));
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

CAMLprim value bonsai_apple_swiftui_set_enabled(value node, value is_enabled)
{
  CAMLparam2(node, is_enabled);
  bonsai_native_swiftui_set_enabled(pointer_val(node), Bool_val(is_enabled));
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

CAMLprim value bonsai_apple_swiftui_set_text_field_style(value node, value style)
{
  CAMLparam2(node, style);
  bonsai_native_swiftui_set_text_field_style(pointer_val(node), Int_val(style));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_text_field_axis(value node, value axis)
{
  CAMLparam2(node, axis);
  bonsai_native_swiftui_set_text_field_axis(pointer_val(node), Int_val(axis));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_text_field_secure(value node, value is_secure)
{
  CAMLparam2(node, is_secure);
  bonsai_native_swiftui_set_text_field_secure(pointer_val(node), Bool_val(is_secure));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_toggle(
  value node,
  value is_on,
  value event_id)
{
  CAMLparam3(node, is_on, event_id);
  bonsai_native_swiftui_set_toggle(pointer_val(node), Bool_val(is_on), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_progress(value node, value progress)
{
  CAMLparam2(node, progress);
  bonsai_native_swiftui_set_progress(pointer_val(node), Double_val(progress));
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

CAMLprim value bonsai_apple_swiftui_set_list_behavior(
  value node,
  value refresh_event_id,
  value delete_event_id,
  value move_event_id,
  value edit_mode)
{
  CAMLparam5(node, refresh_event_id, delete_event_id, move_event_id, edit_mode);
  bonsai_native_swiftui_set_list_behavior(
    pointer_val(node),
    Int_val(refresh_event_id),
    Int_val(delete_event_id),
    Int_val(move_event_id),
    Bool_val(edit_mode));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_on_click(value node, value event_id)
{
  CAMLparam2(node, event_id);
  bonsai_native_swiftui_set_on_click(pointer_val(node), Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_navigation_link_callbacks(
  value node,
  value activate_event_id,
  value deactivate_event_id)
{
  CAMLparam3(node, activate_event_id, deactivate_event_id);
  bonsai_native_swiftui_set_navigation_link_callbacks(
    pointer_val(node),
    Int_val(activate_event_id),
    Int_val(deactivate_event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_navigation_link_value(value node, value link_value)
{
  CAMLparam2(node, link_value);
  bonsai_native_swiftui_set_navigation_link_value(
    pointer_val(node),
    option_string_val(link_value));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_tap_action(value node, value event_id)
{
  CAMLparam2(node, event_id);
  bonsai_native_swiftui_set_tap_action(pointer_val(node), Int_val(event_id));
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

CAMLprim value bonsai_apple_swiftui_set_list_row_content_style(value node, value content_style)
{
  CAMLparam2(node, content_style);
  bonsai_native_swiftui_set_list_row_content_style(pointer_val(node), Int_val(content_style));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_accessory(value node, value accessory)
{
  CAMLparam2(node, accessory);
  bonsai_native_swiftui_set_list_row_accessory(pointer_val(node), Int_val(accessory));
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

CAMLprim value bonsai_apple_swiftui_set_list_row_leading_system_image(
  value node,
  value system_image)
{
  CAMLparam2(node, system_image);
  bonsai_native_swiftui_set_list_row_leading_system_image(
    pointer_val(node),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_list_row_preview_image_path(
  value node,
  value image_path)
{
  CAMLparam2(node, image_path);
  bonsai_native_swiftui_set_list_row_preview_image_path(
    pointer_val(node),
    Is_none(image_path) ? NULL : String_val(Some_val(image_path)));
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

CAMLprim value bonsai_apple_swiftui_clear_list_row_menu_actions(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_list_row_menu_actions(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_list_row_menu_action(
  value node,
  value title,
  value system_image,
  value style,
  value event_id)
{
  CAMLparam5(node, title, system_image, style, event_id);
  bonsai_native_swiftui_append_list_row_menu_action(
    pointer_val(node),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_context_menu_actions(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_context_menu_actions(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_context_menu_action(
  value node,
  value title,
  value system_image,
  value style,
  value event_id)
{
  CAMLparam5(node, title, system_image, style, event_id);
  bonsai_native_swiftui_append_context_menu_action(
    pointer_val(node),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_searchable(value node, value event_id, value text, value prompt)
{
  CAMLparam4(node, event_id, text, prompt);
  bonsai_native_swiftui_set_searchable(
    pointer_val(node),
    Int_val(event_id),
    String_val(text),
    Is_none(prompt) ? NULL : String_val(Some_val(prompt)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_searchable(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_set_searchable(pointer_val(node), -1, "", NULL);
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

CAMLprim value bonsai_apple_swiftui_set_sheet_detents(
  value node,
  value kinds,
  value values)
{
  CAMLparam3(node, kinds, values);
  mlsize_t count = Wosize_val(kinds);
  int32_t *kind_values = NULL;
  double *detent_values = NULL;
  if (count > 0) {
    kind_values = calloc(count, sizeof(int32_t));
    detent_values = calloc(count, sizeof(double));
    if (kind_values == NULL || detent_values == NULL) {
      free(kind_values);
      free(detent_values);
      caml_failwith("failed to allocate sheet detents");
    }
    for (mlsize_t index = 0; index < count; index++) {
      kind_values[index] = Int_val(Field(kinds, index));
      detent_values[index] = Double_val(Field(values, index));
    }
  }
  bonsai_native_swiftui_set_sheet_detents(
    pointer_val(node),
    kind_values,
    detent_values,
    (int32_t)count);
  free(kind_values);
  free(detent_values);
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_safe_area_inset_bottom(value node, value content)
{
  CAMLparam2(node, content);
  bonsai_native_swiftui_set_safe_area_inset_bottom(
    pointer_val(node),
    Is_none(content) ? NULL : pointer_val(Some_val(content)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_popover(
  value node,
  value content,
  value is_presented,
  value dismiss_event_id)
{
  CAMLparam4(node, content, is_presented, dismiss_event_id);
  bonsai_native_swiftui_set_popover(
    pointer_val(node),
    Is_none(content) ? NULL : pointer_val(Some_val(content)),
    Bool_val(is_presented),
    Int_val(dismiss_event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_alert(
  value node,
  value is_presented,
  value dismiss_event_id,
  value title,
  value message)
{
  CAMLparam5(node, is_presented, dismiss_event_id, title, message);
  bonsai_native_swiftui_set_alert(
    pointer_val(node),
    Bool_val(is_presented),
    Int_val(dismiss_event_id),
    option_string_val(title),
    option_string_val(message));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_alert_text_field(
  value node,
  value text,
  value placeholder,
  value event_id)
{
  CAMLparam4(node, text, placeholder, event_id);
  bonsai_native_swiftui_set_alert_text_field(
    pointer_val(node),
    option_string_val(text),
    option_string_val(placeholder),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_alert_actions(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_alert_actions(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_alert_action(
  value node,
  value id,
  value title,
  value role,
  value is_enabled,
  value event_id)
{
  CAMLparam5(node, id, title, role, is_enabled);
  CAMLxparam1(event_id);
  bonsai_native_swiftui_append_alert_action(
    pointer_val(node),
    String_val(id),
    String_val(title),
    Int_val(role),
    Bool_val(is_enabled),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_alert_action_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_alert_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_confirmation_dialog(
  value node,
  value is_presented,
  value dismiss_event_id,
  value title,
  value message)
{
  CAMLparam5(node, is_presented, dismiss_event_id, title, message);
  bonsai_native_swiftui_set_confirmation_dialog(
    pointer_val(node),
    Bool_val(is_presented),
    Int_val(dismiss_event_id),
    option_string_val(title),
    option_string_val(message));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_confirmation_dialog_actions(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_confirmation_dialog_actions(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_confirmation_dialog_action(
  value node,
  value id,
  value title,
  value role,
  value is_enabled,
  value event_id)
{
  CAMLparam5(node, id, title, role, is_enabled);
  CAMLxparam1(event_id);
  bonsai_native_swiftui_append_confirmation_dialog_action(
    pointer_val(node),
    String_val(id),
    String_val(title),
    Int_val(role),
    Bool_val(is_enabled),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_confirmation_dialog_action_bytecode(
  value *argv,
  int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_confirmation_dialog_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_navigation_title(value node, value title)
{
  CAMLparam2(node, title);
  bonsai_native_swiftui_set_navigation_title(
    pointer_val(node),
    Is_none(title) ? NULL : String_val(Some_val(title)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_toolbar(value node)
{
  CAMLparam1(node);
  bonsai_native_swiftui_clear_toolbar(pointer_val(node));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_toolbar_item(
  value node,
  value id,
  value title,
  value system_image,
  value is_title_visible,
  value is_enabled,
  value share_url,
  value event_id)
{
  CAMLparam5(node, id, title, system_image, is_title_visible);
  CAMLxparam3(is_enabled, share_url, event_id);
  bonsai_native_swiftui_append_toolbar_item(
    pointer_val(node),
    String_val(id),
    String_val(title),
    option_string_val(system_image),
    Bool_val(is_title_visible),
    Bool_val(is_enabled),
    option_string_val(share_url),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_toolbar_item_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_toolbar_item(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5],
    argv[6],
    argv[7]);
}

CAMLprim value bonsai_apple_swiftui_append_toolbar_menu_action(
  value node,
  value item_id,
  value title,
  value system_image,
  value style,
  value event_id,
  value starts_section,
  value export_filename,
  value export_content_type,
  value export_content)
{
  CAMLparam5(node, item_id, title, system_image, style);
  CAMLxparam5(event_id, starts_section, export_filename, export_content_type, export_content);
  bonsai_native_swiftui_append_toolbar_menu_action(
    pointer_val(node),
    String_val(item_id),
    String_val(title),
    option_string_val(system_image),
    Int_val(style),
    Int_val(event_id),
    Bool_val(starts_section),
    option_string_val(export_filename),
    option_string_val(export_content_type),
    option_string_val(export_content));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_toolbar_menu_action_bytecode(
  value *argv,
  int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_toolbar_menu_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5],
    argv[6],
    argv[7],
    argv[8],
    argv[9]);
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

CAMLprim value bonsai_apple_swiftui_set_regular_material_panel(
  value node,
  value corner_radius)
{
  CAMLparam2(node, corner_radius);
  bonsai_native_swiftui_set_regular_material_panel(
    pointer_val(node),
    Double_val(corner_radius));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_secondary_fill_panel(
  value node,
  value corner_radius,
  value opacity)
{
  CAMLparam3(node, corner_radius, opacity);
  bonsai_native_swiftui_set_secondary_fill_panel(
    pointer_val(node),
    Double_val(corner_radius),
    Double_val(opacity));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_liquid_glass_panel(
  value node,
  value corner_radius,
  value is_transparent,
  value tint_color,
  value tint_opacity)
{
  CAMLparam5(node, corner_radius, is_transparent, tint_color, tint_opacity);
  bonsai_native_swiftui_set_liquid_glass_panel(
    pointer_val(node),
    Double_val(corner_radius),
    Bool_val(is_transparent),
    Int_val(tint_color),
    Double_val(tint_opacity));
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

CAMLprim value bonsai_apple_swiftui_clear_sidebar_shell(
  value node,
  value title,
  value compact_top_bar_visible,
  value bottom_search_placeholder,
  value bottom_search_text,
  value bottom_search_event_id)
{
  CAMLparam5(node, title, compact_top_bar_visible, bottom_search_placeholder, bottom_search_text);
  CAMLxparam1(bottom_search_event_id);
  bonsai_native_swiftui_clear_sidebar_shell(
    pointer_val(node),
    Is_none(title) ? NULL : String_val(Some_val(title)),
    Bool_val(compact_top_bar_visible),
    Is_none(bottom_search_placeholder) ? NULL : String_val(Some_val(bottom_search_placeholder)),
    String_val(bottom_search_text),
    Int_val(bottom_search_event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_sidebar_shell_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_clear_sidebar_shell(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_sidebar_header_action(
  value node,
  value id,
  value title,
  value system_image,
  value avatar_image,
  value avatar_initial,
  value event_id)
{
  CAMLparam5(node, id, title, system_image, avatar_image);
  CAMLxparam2(avatar_initial, event_id);
  bonsai_native_swiftui_set_sidebar_header_action(
    pointer_val(node),
    Is_none(id) ? NULL : String_val(Some_val(id)),
    Is_none(title) ? NULL : String_val(Some_val(title)),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Is_none(avatar_image) ? NULL : String_val(Some_val(avatar_image)),
    Is_none(avatar_initial) ? NULL : String_val(Some_val(avatar_initial)),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_sidebar_header_action_byte(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_set_sidebar_header_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5],
    argv[6]);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_action(
  value node,
  value id,
  value title,
  value subtitle,
  value system_image,
  value event_id)
{
  CAMLparam5(node, id, title, subtitle, system_image);
  CAMLxparam1(event_id);
  bonsai_native_swiftui_append_sidebar_action(
    pointer_val(node),
    String_val(id),
    String_val(title),
    Is_none(subtitle) ? NULL : String_val(Some_val(subtitle)),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_action_byte(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_sidebar_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_action_menu_action(
  value node,
  value title,
  value system_image,
  value style,
  value event_id)
{
  CAMLparam5(node, title, system_image, style, event_id);
  bonsai_native_swiftui_append_sidebar_action_menu_action(
    pointer_val(node),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_sidebar_history_title(value node, value title)
{
  CAMLparam2(node, title);
  bonsai_native_swiftui_set_sidebar_history_title(
    pointer_val(node),
    Is_none(title) ? NULL : String_val(Some_val(title)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_history_action(
  value node,
  value id,
  value title,
  value subtitle,
  value system_image,
  value event_id)
{
  CAMLparam5(node, id, title, subtitle, system_image);
  CAMLxparam1(event_id);
  bonsai_native_swiftui_append_sidebar_history_action(
    pointer_val(node),
    String_val(id),
    String_val(title),
    Is_none(subtitle) ? NULL : String_val(Some_val(subtitle)),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_history_action_byte(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_sidebar_history_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_append_sidebar_history_action_menu_action(
  value node,
  value title,
  value system_image,
  value style,
  value event_id)
{
  CAMLparam5(node, title, system_image, style, event_id);
  bonsai_native_swiftui_append_sidebar_history_action_menu_action(
    pointer_val(node),
    String_val(title),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_sidebar_bottom_action(
  value node,
  value id,
  value title,
  value system_image,
  value event_id,
  value chrome)
{
  CAMLparam5(node, id, title, system_image, event_id);
  CAMLxparam1(chrome);
  bonsai_native_swiftui_set_sidebar_bottom_action(
    pointer_val(node),
    Is_none(id) ? NULL : String_val(Some_val(id)),
    Is_none(title) ? NULL : String_val(Some_val(title)),
    Is_none(system_image) ? NULL : String_val(Some_val(system_image)),
    Int_val(event_id),
    Int_val(chrome));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_sidebar_bottom_action_byte(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_set_sidebar_bottom_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_section(value node, value title)
{
  CAMLparam2(node, title);
  bonsai_native_swiftui_set_section(
    pointer_val(node),
    Is_none(title) ? NULL : String_val(Some_val(title)));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_picker(
  value node,
  value title,
  value selected,
  value style,
  value event_id)
{
  CAMLparam5(node, title, selected, style, event_id);
  bonsai_native_swiftui_clear_picker(
    pointer_val(node),
    String_val(title),
    String_val(selected),
    Int_val(style),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_picker_option(value node, value id, value title)
{
  CAMLparam3(node, id, title);
  bonsai_native_swiftui_append_picker_option(pointer_val(node), String_val(id), String_val(title));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_file_exporter(
  value node,
  value filename,
  value content_type,
  value content)
{
  CAMLparam4(node, filename, content_type, content);
  bonsai_native_swiftui_set_file_exporter(
    pointer_val(node),
    String_val(filename),
    String_val(content_type),
    String_val(content));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_share_link(value node, value url)
{
  CAMLparam2(node, url);
  bonsai_native_swiftui_set_share_link(pointer_val(node), String_val(url));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_file_importer(
  value node,
  value allowed_types,
  value event_id)
{
  CAMLparam3(node, allowed_types, event_id);
  mlsize_t count = Wosize_val(allowed_types);
  const char **types = calloc(count, sizeof(char *));
  if (types == NULL) {
    caml_failwith("failed to allocate file importer type array");
  }
  for (mlsize_t index = 0; index < count; index++) {
    types[index] = String_val(Field(allowed_types, index));
  }
  bonsai_native_swiftui_set_file_importer(
    pointer_val(node),
    types,
    (int32_t)count,
    Int_val(event_id));
  free(types);
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_slider(
  value node,
  value title,
  value slider_value,
  value min,
  value max,
  value event_id)
{
  CAMLparam5(node, title, slider_value, min, max);
  CAMLxparam1(event_id);
  bonsai_native_swiftui_set_slider(
    pointer_val(node),
    String_val(title),
    Double_val(slider_value),
    Double_val(min),
    Double_val(max),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_slider_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_set_slider(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5]);
}

CAMLprim value bonsai_apple_swiftui_set_stepper(
  value node,
  value title,
  value stepper_value,
  value min,
  value max,
  value step,
  value event_id)
{
  CAMLparam5(node, title, stepper_value, min, max);
  CAMLxparam2(step, event_id);
  bonsai_native_swiftui_set_stepper(
    pointer_val(node),
    String_val(title),
    Int_val(stepper_value),
    Int_val(min),
    Int_val(max),
    Int_val(step),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_stepper_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_set_stepper(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5],
    argv[6]);
}

CAMLprim value bonsai_apple_swiftui_set_date_picker(
  value node,
  value title,
  value selected,
  value event_id)
{
  CAMLparam4(node, title, selected, event_id);
  bonsai_native_swiftui_set_date_picker(
    pointer_val(node),
    String_val(title),
    String_val(selected),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_color_picker(
  value node,
  value title,
  value selected,
  value event_id)
{
  CAMLparam4(node, title, selected, event_id);
  bonsai_native_swiftui_set_color_picker(
    pointer_val(node),
    String_val(title),
    String_val(selected),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_clear_menu(
  value node,
  value title,
  value system_image)
{
  CAMLparam3(node, title, system_image);
  bonsai_native_swiftui_clear_menu(
    pointer_val(node),
    String_val(title),
    option_string_val(system_image));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_menu_action(
  value node,
  value id,
  value title,
  value system_image,
  value style,
  value is_enabled,
  value event_id)
{
  CAMLparam5(node, id, title, system_image, style);
  CAMLxparam2(is_enabled, event_id);
  bonsai_native_swiftui_append_menu_action(
    pointer_val(node),
    String_val(id),
    String_val(title),
    option_string_val(system_image),
    Int_val(style),
    Bool_val(is_enabled),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_append_menu_action_bytecode(value *argv, int argn)
{
  (void)argn;
  return bonsai_apple_swiftui_append_menu_action(
    argv[0],
    argv[1],
    argv[2],
    argv[3],
    argv[4],
    argv[5],
    argv[6]);
}

CAMLprim value bonsai_apple_swiftui_set_disclosure_group(
  value node,
  value title,
  value is_expanded,
  value event_id)
{
  CAMLparam4(node, title, is_expanded, event_id);
  bonsai_native_swiftui_set_disclosure_group(
    pointer_val(node),
    String_val(title),
    Bool_val(is_expanded),
    Int_val(event_id));
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_navigation_path_stack(
  value node,
  value path,
  value event_id,
  value destinations)
{
  CAMLparam4(node, path, event_id, destinations);
  mlsize_t path_count = Wosize_val(path);
  mlsize_t destination_count = Wosize_val(destinations);
  const char **path_values = NULL;
  const char **destination_values = NULL;
  if (path_count > 0) {
    path_values = calloc(path_count, sizeof(char *));
    if (path_values == NULL) {
      caml_failwith("failed to allocate navigation path array");
    }
  }
  if (destination_count > 0) {
    destination_values = calloc(destination_count, sizeof(char *));
    if (destination_values == NULL) {
      free(path_values);
      caml_failwith("failed to allocate navigation destination array");
    }
  }
  for (mlsize_t index = 0; index < path_count; index++) {
    path_values[index] = String_val(Field(path, index));
  }
  for (mlsize_t index = 0; index < destination_count; index++) {
    destination_values[index] = String_val(Field(destinations, index));
  }
  bonsai_native_swiftui_set_navigation_path_stack(
    pointer_val(node),
    path_values,
    (int32_t)path_count,
    Int_val(event_id),
    destination_values,
    (int32_t)destination_count);
  free(path_values);
  free(destination_values);
  CAMLreturn(Val_unit);
}

CAMLprim value bonsai_apple_swiftui_set_image_payload_mode(value node, value wants_payload)
{
  CAMLparam2(node, wants_payload);
  bonsai_native_swiftui_set_image_payload_mode(pointer_val(node), Bool_val(wants_payload));
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
