esprima = require('esprima')

makeFilter = (node) ->
  do (node=node) ->
    res = switch node.type
      when 'Identifier'
        (pkt) ->
          for layer in pkt.layers
            return layer if layer.name.toLowerCase() == node.name.toLowerCase()
            if layer.aliases?
              for a in layer.aliases
                return layer if a.toLowerCase() == node.name.toLowerCase()
          return pkt.attrs[node.name] if pkt.attrs.hasOwnProperty(node.name)
          return pkt[node.name] if pkt[node.name]?
          switch node.name
            when 'Number'
              return Number
            when 'Date'
              return Date
            when 'Math'
              return Math
            when '$'
              return pkt
          undefined
      when 'MemberExpression'
        fo = makeFilter(node.object)
        fp =
          switch node.property.type
            when 'Identifier'
              -> node.property.name
            else
              makeFilter(node.property)
        (pkt) ->
          try
            obj = fo(pkt)
            prop = fp(pkt)
            return obj.attrs[prop] if obj.attrs? && obj.attrs.hasOwnProperty(prop)
            return obj[prop] if obj[prop]?
          catch
            undefined
      when 'Literal'
        if node.regex?
          reg = new RegExp(node.regex.pattern, node.regex.flags)
          -> reg
        else
          -> node.value
      when 'UnaryExpression'
        f = makeFilter(node.argument)
        switch node.operator
          when '+'
            (pkt) -> +f(pkt)
          when '-'
            (pkt) -> -f(pkt)
          when '!'
            (pkt) -> !f(pkt)
          when '~'
            (pkt) -> ~f(pkt)
          else
            throw new SyntaxError()
      when 'CallExpression'
        cf = makeFilter(node.callee)
        af = node.arguments.map (a) -> makeFilter(a)
        (pkt) ->
          args = af.map (f) -> f(pkt)
          obj = cf(pkt)
          if obj?
            obj.apply(@, args)
          else
            undefined
      when 'SequenceExpression'
        ef = node.expressions.map (e) -> makeFilter(e)
        (pkt) ->
          res = undefined
          for f in ef
            res = f(pkt)
          res
      when 'BinaryExpression'
        lf = makeFilter(node.left)
        rf = makeFilter(node.right)
        switch node.operator
          when '>'
            (pkt) -> lf(pkt) > rf(pkt)
          when '<'
            (pkt) -> lf(pkt) < rf(pkt)
          when '<='
            (pkt) -> lf(pkt) <= rf(pkt)
          when '>='
            (pkt) -> lf(pkt) >= rf(pkt)
          when '=='
            (pkt) ->
              lhs = lf(pkt)
              rhs = rf(pkt)
              return lhs.equals(rhs) if lhs?.equals?
              return rhs.equals(lhs) if rhs?.equals?
              lhs == rhs
          when '!='
            (pkt) -> lf(pkt) != rf(pkt)
          when '+'
            (pkt) -> lf(pkt) + rf(pkt)
          when '-'
            (pkt) -> lf(pkt) - rf(pkt)
          when '*'
            (pkt) -> lf(pkt) * rf(pkt)
          when '/'
            (pkt) -> lf(pkt) / rf(pkt)
          when '%'
            (pkt) -> lf(pkt) % rf(pkt)
          when '&'
            (pkt) -> lf(pkt) & rf(pkt)
          when '|'
            (pkt) -> lf(pkt) | rf(pkt)
          when '^'
            (pkt) -> lf(pkt) ^ rf(pkt)
          when '>>'
            (pkt) -> lf(pkt) >> rf(pkt)
          when '<<'
            (pkt) -> lf(pkt) << rf(pkt)
          else
            throw new SyntaxError()
      when 'ConditionalExpression'
        tf = makeFilter(node.test)
        cf = makeFilter(node.consequent)
        af = makeFilter(node.alternate)
        (pkt) ->
          if tf(pkt)
            cf(pkt)
          else
            af(pkt)
      when 'LogicalExpression'
        switch node.operator
          when '||'
            lf = makeFilter(node.left)
            rf = makeFilter(node.right)
            (pkt) -> lf(pkt) || rf(pkt)
          when '&&'
            lf = makeFilter(node.left)
            rf = makeFilter(node.right)
            (pkt) -> lf(pkt) && rf(pkt)
          else
            throw new SyntaxError()
      else
        throw new SyntaxError()

parseFilter = (expression) ->
  ast = esprima.parse expression
  switch ast.body.length
    when 0
      return -> true
    when 1
      root = ast.body[0]
      throw new SyntaxError() if root.type != "ExpressionStatement"
      f = makeFilter(root.expression)
      return (pkt) -> !!f(pkt)
    else
      throw new SyntaxError()

module.exports = parseFilter
