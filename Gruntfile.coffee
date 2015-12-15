"use strict"

module.exports = (grunt) ->

  # 时间统计
  require('time-grunt')(grunt)

  grunt.initConfig

    pkg: grunt.file.readJSON('package.json') # 配置
    cwd: process.cwd() # 当前目录

    # 清空目录
    clean:
      dev: ['build/dev/**']
      build: ['build/www/**', '!build/www', 'build/*.zip']

    # zip压缩
    compress:
      options:
        archive: ->
          pkg = grunt.config.get('pkg')
          cwd = grunt.config.get('cwd')
          cwd + '/build/' + pkg.name + '_' + Date.now() + '.zip'
      dist:
        files: [{
          expand: true
          cwd: 'build/www'
          src: ['**/*']
          dest: 'build/gzip' # 该属性仅用于gzip模式
        }]

    # 静态服务器
    connect:
      server:
        options:
          port: 8888
          base: './build/dev'

    # 复制内容
    copy:
      dev:
        files: [{
          expand: true
          cwd: './asset'
          src: ['**/*.!(less)']
          dest: 'build/dev'
        },{
          expand: true
          cwd: './html'
          src: ['**/*', '!index.html']
          dest: 'build/dev/html'
        },{
          expand: true
          cwd: './html'
          src: ['index.html']
          dest: 'build/dev'
        }]
      build:
        expand: true
        cwd: 'build/dev'
        src: ['**/*']
        dest: 'build/www'

    # css压缩
    cssmin:
      options:
        compatibility: ['ie7', 'ie8'] # 支持IEhack
        keepSpecialComments: '0' # 忽略全部注释
        advanced: false # 高级优化
      dist:
        src: 'build/dev/css/importer.css'
        dest: 'build/dev/css/importer.min.css'

    # less解析
    less:
      options:
        strictMath: true
        strictUnits: true
      dev:
        expand: true
        cwd: 'asset/css/'
        src: ['importer.less']
        dest: 'build/dev/css/'
        ext: '.css'

    # 文件填充
    'sails-linker':
      devJs:
        options:
          startTag: '<!-- scripts start -->'
          endTag: '<!-- scripts end -->'
          fileTmpl: '<script src="%s"></script>'
          appRoot: 'build/dev'
        files:
          'build/dev/**/*.html': ['build/dev/js/main.js']
      buildJs:
        options:
          startTag: '<!-- scripts start -->'
          endTag: '<!-- scripts end -->'
          fileTmpl: '<script src="%s"></script>'
          appRoot: 'build/dev'
          relative: true
        files:
          'build/dev/**/*.html': ['build/dev/js/main.min.js']
      devCss:
        options:
          startTag: '<!-- styles start -->'
          endTag: '<!-- styles end -->'
          fileTmpl: '<link rel="stylesheet" href="%s">'
          appRoot: 'build/dev'
        files:
          'build/dev/**/*.html': ['build/dev/css/**/*.css']
      buildCss:
        options:
          startTag: '<!-- styles start -->'
          endTag: '<!-- styles end -->'
          fileTmpl: '<link rel="stylesheet" href="%s">'
          appRoot: 'build/dev'
          relative: true
        files:
          'build/dev/**/*.html': ['build/dev/css/**/*.min.css']

    # 同步目录
    sync:
      dev:
        files: [{
          cwd: './asset'
          src: ['**/*.!(less)']
          dest: 'build/dev'
        },{
          cwd: './html'
          src: ['**/*', '!index.html']
          dest: 'build/dev/html'
        },{
          cwd: './html'
          src: ['index.html']
          dest: 'build/dev'
        }]

    # 文件压缩
    uglify:
      dist:
        src: ['build/dev/js/main.js']
        dest: 'build/dev/js/main.min.js'

    # 文件变化监听
    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: 'webpack:dev'
      less:
        files: ['asset/css/**/*.less']
        tasks: 'less:dev'
      asset:
        files: ['asset/**/*', 'html/**/*']
        tasks: ['sync:dev', 'sails-linker:devJs', 'sails-linker:devCss']

    # js加载器
    webpack:
      dev:
        entry: './src/main.coffee' # 输入
        output:
          path: 'build/dev/js' # 内部地址
          publicPath: '/js/' # 外部地址
          filename: "[name].js" # 输出
          chunkFilename: "[name].js" # 模块
        module:
          loaders: [
            {test: /\.coffee$/, loader: 'coffee-loader'} # coffee加载器
            {test: /\.html$/, loader: 'html-loader'} # html加载器
          ]
        resolve:
          # 别名
          alias:
            src: '<%= cwd %>/src'
            common: 'src/common'
            lib: 'src/lib'
            page: 'src/page'
            ui: 'src/ui'
          # 后缀补全
          extensions: ['', '.coffee', '.js']

  # 加载包
  require('load-grunt-tasks')(grunt)

  # 命令
  grunt.registerTask 'compile', ['clean:dev', 'webpack:dev', 'less:dev', 'copy:dev']
  grunt.registerTask 'default', ['compile', 'sails-linker:devJs', 'sails-linker:devCss', 'connect', 'watch']
  grunt.registerTask 'build', ['compile', 'uglify', 'cssmin', 'sails-linker:buildJs', 'sails-linker:buildCss', 'clean:build', 'copy:build', 'compress']
