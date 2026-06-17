#include <jni.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

static int ocaml_runtime_started = 0;

static void ensure_ocaml_runtime(void) {
  if (!ocaml_runtime_started) {
    char *argv[] = { "bonsai_android", NULL };
    caml_startup(argv);
    ocaml_runtime_started = 1;
  }
}

JNIEXPORT jstring JNICALL
Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_renderNative(JNIEnv *env, jobject self) {
  (void)self;
  CAMLparam0();
  CAMLlocal1(result);
  ensure_ocaml_runtime();
  const value *callback = caml_named_value("bonsai_android_render");
  if (callback == NULL) {
    CAMLreturnT(
      jstring,
      (*env)->NewStringUTF(
        env,
        "{\"type\":\"text\",\"text\":\"OCaml render callback missing\",\"modifiers\":[]}"));
  }
  result = caml_callback(*callback, Val_unit);
  CAMLreturnT(jstring, (*env)->NewStringUTF(env, String_val(result)));
}

JNIEXPORT void JNICALL
Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_dispatchClickNative(JNIEnv *env, jobject self, jint event_id) {
  (void)env;
  (void)self;
  CAMLparam0();
  ensure_ocaml_runtime();
  const value *callback = caml_named_value("bonsai_android_dispatch_click");
  if (callback != NULL) caml_callback(*callback, Val_int(event_id));
  CAMLreturn0;
}

JNIEXPORT void JNICALL
Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_dispatchChangeNative(
    JNIEnv *env,
    jobject self,
    jint event_id,
    jstring text) {
  (void)self;
  CAMLparam0();
  CAMLlocal2(ocaml_text, result);
  ensure_ocaml_runtime();
  const value *callback = caml_named_value("bonsai_android_dispatch_change");
  if (callback == NULL) CAMLreturn0;

  const char *utf8 = (*env)->GetStringUTFChars(env, text, NULL);
  ocaml_text = caml_copy_string(utf8);
  (*env)->ReleaseStringUTFChars(env, text, utf8);

  value args[2] = { Val_int(event_id), ocaml_text };
  result = caml_callbackN(*callback, 2, args);
  (void)result;
  CAMLreturn0;
}
