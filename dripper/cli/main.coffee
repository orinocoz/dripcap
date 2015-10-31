fs = require 'fs'
path = require 'path'

argv = process.argv
if argv.length >= 3
  command = argv[2]
  try
    f = require "#{__dirname}/commands/#{command}"
  catch e
    console.warn "command not found: #{command}"
    process.exit 1
  argv.splice(2, 1)
  f(argv)
else
  console.log 'commands:'
  for c in fs.readdirSync "#{__dirname}/commands"
    console.log '\t' + path.basename c, '.coffee'
