MRuby::Build.new do |conf|
  toolchain :clang

  conf.gembox 'default'
  conf.gem github: 'mattn/mruby-json'
  conf.gem github: 'iij/mruby-env'
  conf.gem github: 'iij/mruby-mtest'
  conf.gem github: 'iij/mruby-tempfile'

  conf.cc.defines << 'MRB_USE_MBEDTLS'

  conf.cc.flags << '-O2'
  # conf.linker.flags << '-static'

  conf.bins << 'mrbc'
end
