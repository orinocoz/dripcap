function makeFilter(node) {
  'use strict';
  return (function(node) {
    let res;
    return res = (() => {
      switch (node.type) {
        case 'Identifier':
        return function(pkt) {
          let name = node.name.toLowerCase();
          let find = function(layers, name) {
            for (let ns in layers) {
              let layer = layers[ns];
              if (layer.name.toLowerCase() === name) {
                return layer;
              }
              if (layer.aliases != null) {
                for (let i = 0; i < layer.aliases.length; i++) {
                  let alias = layer.aliases[i];
                  if (alias.toLowerCase() === name) {
                    return layer;
                  }
                }
              }
              if (layer.layers != null) {
                let child = find(layer.layers, name);
                if (child != null) {
                  return child;
                }
              }
            }
            return null;
          };

          let layer = find(pkt.layers, name);
          if (layer != null) {
            return layer;
          }
          if (pkt[node.name] != null) {
            return pkt[node.name];
          }
          switch (node.name) {
            case 'Number':
            return Number;
            break;
            case 'Date':
            return Date;
            break;
            case 'Math':
            return Math;
            break;
            case '$':
            return pkt;
            break;
          }
          return undefined;
        };
        case 'MemberExpression':
        {
          let fo = makeFilter(node.object);
          let fp =
          (() => {
            switch (node.property.type) {
              case 'Identifier':
              return () => node.property.name;
              default:
              return makeFilter(node.property);
            }
          })();
          return function(pkt) {
            try {
              let obj = fo(pkt);
              let prop = fp(pkt);
              if ((obj.attrs != null) && obj.attrs.hasOwnProperty(prop)) {
                return obj.attrs[prop];
              }
              if (obj[prop] != null) {
                return obj[prop];
              }
            } catch (error) {
              return undefined;
            }
          };
        }
        case 'Literal':
        if (node.regex != null) {
          let reg = new RegExp(node.regex.pattern, node.regex.flags);
          return () => reg;
        } else {
          return () => node.value;
        }
        case 'UnaryExpression':
        {
          let f = makeFilter(node.argument);
          switch (node.operator) {
            case '+':
            return pkt => +f(pkt);
            case '-':
            return pkt => -f(pkt);
            case '!':
            return pkt => !f(pkt);
            case '~':
            return pkt => ~f(pkt);
            default:
            throw new SyntaxError();
          }
        }
        case 'CallExpression':
        {
          let cf = makeFilter(node.callee);
          let af = node.arguments.map(a => makeFilter(a));
          return function(pkt) {
            let args = af.map(f => f(pkt));
            let obj = cf(pkt);
            if (obj != null) {
              return obj.apply(this, args);
            } else {
              return undefined;
            }
          };
        }
        case 'SequenceExpression':
        {
          let ef = node.expressions.map(e => makeFilter(e));
          return function(pkt) {
            res = undefined;
            for (let i = 0; i < ef.length; i++) {
              f = ef[i];
              res = f(pkt);
            }
            return res;
          };
        }
        case 'BinaryExpression':
        {
          let lf = makeFilter(node.left);
          let rf = makeFilter(node.right);
          switch (node.operator) {
            case '>':
            return pkt => lf(pkt) > rf(pkt);
            case '<':
            return pkt => lf(pkt) < rf(pkt);
            case '<=':
            return pkt => lf(pkt) <= rf(pkt);
            case '>=':
            return pkt => lf(pkt) >= rf(pkt);
            case '==':
            return function(pkt) {
              let lhs = lf(pkt);
              let rhs = rf(pkt);
              if ((lhs != null) && (lhs.equals != null)) {
                return lhs.equals(rhs);
              }
              if ((rhs != null) && (rhs.equals != null)) {
                return rhs.equals(lhs);
              }
              return lhs === rhs;
            };
            case '!=':
            return pkt => lf(pkt) !== rf(pkt);
            case '+':
            return pkt => lf(pkt) + rf(pkt);
            case '-':
            return pkt => lf(pkt) - rf(pkt);
            case '*':
            return pkt => lf(pkt) * rf(pkt);
            case '/':
            return pkt => lf(pkt) / rf(pkt);
            case '%':
            return pkt => lf(pkt) % rf(pkt);
            case '&':
            return pkt => lf(pkt) & rf(pkt);
            case '|':
            return pkt => lf(pkt) | rf(pkt);
            case '^':
            return pkt => lf(pkt) ^ rf(pkt);
            case '>>':
            return pkt => lf(pkt) >> rf(pkt);
            case '<<':
            return pkt => lf(pkt) << rf(pkt);
            default:
            throw new SyntaxError();
          }
        }
        case 'ConditionalExpression':
        {
          let tf = makeFilter(node.test);
          let cf = makeFilter(node.consequent);
          let af = makeFilter(node.alternate);
          return function(pkt) {
            if (tf(pkt)) {
              return cf(pkt);
            } else {
              return af(pkt);
            }
          };
        }
        case 'LogicalExpression':
        switch (node.operator) {
          case '||':
          {
            let lf = makeFilter(node.left);
            let rf = makeFilter(node.right);
            return pkt => lf(pkt) || rf(pkt);
          }
          case '&&':
          {
            let lf = makeFilter(node.left);
            let rf = makeFilter(node.right);
            return pkt => lf(pkt) && rf(pkt);
          }
          default:
          throw new SyntaxError();
        }
        default:
        throw new SyntaxError();
      }
    })();
  })(node);
};

module.exports = makeFilter(ast);
