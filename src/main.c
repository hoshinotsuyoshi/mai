#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/dump.h>
#include <mruby/string.h>
#include <mruby/array.h>  // for ARGV
#include <stdlib.h>
#include <string.h>

extern const uint8_t src_main_rb_mrb[];
extern const uint32_t src_main_rb_mrb_len;

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
