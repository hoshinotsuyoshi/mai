#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/dump.h>
#include <mruby/string.h>
#include <mruby/array.h>  // for ARGV
#include <stdlib.h>
#include <string.h>

extern const uint8_t src_main_rb_mrb[];
extern const uint32_t src_main_rb_mrb_len;

// define ENV-like constants
void define_env_const(mrb_state *mrb, const char *key, const char *fallback) {
  const char *val = getenv(key);
  if (!val) val = fallback;
  if (val) {
    mrb_define_global_const(mrb, key, mrb_str_new_cstr(mrb, val));
  }
}

char *build_default_path(const char *home, const char *suffix) {
  size_t len = strlen(home) + strlen(suffix) + 1;
  char *path = malloc(len);
  if (!path) return NULL;
  snprintf(path, len, "%s%s", home, suffix);
  return path;
}

// Kernel#exit method
static mrb_value mrb_kernel_exit(mrb_state *mrb, mrb_value self) {
  mrb_int status = 0;
  mrb_get_args(mrb, "|i", &status); // when args exist get them, otherwise 0
  exit(status); // call C's exit
  return mrb_nil_value(); // never launched, but needed
}

int main(int argc, char **argv) {
  mrb_state *mrb = mrb_open();
  if (!mrb) return 1;

  // Define Kernel#exit
  struct RClass *krn = mrb->kernel_module;
  mrb_define_method(mrb, krn, "exit", mrb_kernel_exit, MRB_ARGS_OPT(1));

  // define ARGV (excluding argv[0])
  mrb_value args = mrb_ary_new_capa(mrb, argc > 1 ? argc - 1 : 0);
  for (int i = 1; i < argc; i++) {
    mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb, argv[i]));
  }
  mrb_define_global_const(mrb, "ARGV", args);

  // define HOME and XDG paths
  const char *home = getenv("HOME");
  if (home) {
    mrb_define_global_const(mrb, "HOME", mrb_str_new_cstr(mrb, home));

    char *def_config = build_default_path(home, "/.config");
    char *def_cache  = build_default_path(home, "/.cache");
    char *def_data   = build_default_path(home, "/.local/share");
    char *def_state  = build_default_path(home, "/.local/state");

    define_env_const(mrb, "XDG_CONFIG_HOME", def_config);
    define_env_const(mrb, "XDG_CACHE_HOME",  def_cache);
    define_env_const(mrb, "XDG_DATA_HOME",   def_data);
    define_env_const(mrb, "XDG_STATE_HOME",  def_state);

    free(def_config);
    free(def_cache);
    free(def_data);
    free(def_state);
  }

  // GEMINI_API_KEY
  const char *google_api_key = getenv("GEMINI_API_KEY");
  if (google_api_key) {
    mrb_define_global_const(mrb, "GEMINI_API_KEY", mrb_str_new_cstr(mrb, google_api_key));
  }

  // execute embedded .mrb
  mrb_load_irep_buf(mrb, src_main_rb_mrb, src_main_rb_mrb_len);

  if (mrb->exc) {
    mrb_print_error(mrb);
    mrb_close(mrb);
    return 1;
  }

  mrb_close(mrb);
  return 0;
}
