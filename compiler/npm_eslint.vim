if exists("current_compiler")
  finish
endif
let current_compiler = "npm_eslint"

CompilerSet makeprg=npm\ run\ eslint\ --\ --no-color\ -f\ unix\ $*
CompilerSet errorformat=%A%f:%l:%c:%m,%-G%.%#
