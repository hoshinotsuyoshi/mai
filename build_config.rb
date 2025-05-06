MRuby::Build.new do |conf|
  toolchain :clang

  conf.gembox 'default'
  # conf.gem :core => 'mruby-print'

  # conf.gem './mrbgems/mruby-json'
  conf.gem './mrbgems/mruby-json'
  # conf.gem './mrbgems/mruby-http'
  # conf.gem './mrbgems/mruby-mbedtls'

  conf.cc.defines << 'MRB_USE_MBEDTLS'

  conf.cc.flags << '-O2'
  # conf.linker.flags << '-static'

  conf.bins << 'mrbc'
end
