program = require('commander')

module.exports = (argv) ->
  program
    .version('0.0.1')
    .option('-t, --tmpl [type]', 'Template type [basic]', 'basic')
    .parse(argv)

  console.log ("#{program.tmpl} #{program.args}")
