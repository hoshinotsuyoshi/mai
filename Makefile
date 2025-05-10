MRUBY_DIR := ./mruby
MRUBY_BUILD_DIR := $(MRUBY_DIR)/build/host
MRBC := $(MRUBY_BUILD_DIR)/bin/mrbc
CFLAGS := -I$(MRUBY_BUILD_DIR)/include
CC := clang
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  LDFLAGS := -L$(MRUBY_BUILD_DIR)/lib -lmruby -lm
else
  LDFLAGS := -L$(MRUBY_BUILD_DIR)/lib -lmruby -static -lm
endif

.PHONY: all clean smoke test

all: mi

mi: $(MRUBY_BUILD_DIR)/bin/mrbc src/main.rb.mrb
	xxd -i src/main.rb.mrb > src/mrb_code.c
	$(CC) src/main.c src/mrb_code.c $(CFLAGS) $(LDFLAGS) -o mi

src/main.rb.mrb: src/main.rb
	$(MRBC) -o src/main.rb.mrb src/main.rb

$(MRUBY_BUILD_DIR)/bin/mrbc:
	cd $(MRUBY_DIR) && MRUBY_CONFIG=../build_config.rb rake

clean:
	cd $(MRUBY_DIR) && rake clean
	rm -f src/*.mrb src/mrb_code.c mi

smoke: mi
	./examples/tasks/summarize_pr/main.sh

test: $(MRUBY_BUILD_DIR)/bin/mruby
	$(MRUBY_BUILD_DIR)/bin/mruby test/mi_test.rb
