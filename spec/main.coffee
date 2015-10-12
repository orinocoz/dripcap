global.console = require('remote').getGlobal('console')

console.log 'test started'
dripcap.action.emit 'Core: Close Window'
