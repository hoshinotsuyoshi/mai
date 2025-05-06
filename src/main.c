#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/dump.h>
#include <mruby/string.h>

extern const uint8_t src_main_rb_mrb[];
extern const uint32_t src_main_rb_mrb_len;

int main(void) {
  mrb_state *mrb = mrb_open();
  if (!mrb) return 1;

  mrb_load_irep_buf(mrb, src_main_rb_mrb, src_main_rb_mrb_len);

  if (mrb->exc) {
    mrb_print_error(mrb);
    mrb_close(mrb);
    return 1;
  }

  mrb_close(mrb);
  return 0;
}

