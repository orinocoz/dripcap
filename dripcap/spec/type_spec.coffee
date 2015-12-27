{
  Enum
  Flags
  MACAddress
  IPv4Address
  IPv6Address
  IPv4Host
  IPv6Host
} = require('../type')

describe "Enum", ->
  table =
    0x1: 'Foo'
    0x2: 'Bar'
    0x4: 'Baz'

  it "toString() returns a string representation", ->
    en = new Enum(table, 0x1)
    expect(en.toString()).toEqual("Foo (1)")
    en = new Enum(table, 0x2)
    expect(en.toString()).toEqual("Bar (2)")
    en = new Enum(table, 0x4)
    expect(en.toString()).toEqual("Baz (4)")
    en = new Enum(table, 0x8)
    expect(en.toString()).toEqual("unknown (8)")

  it "name returns string value", ->
    en = new Enum(table, 0x1)
    expect(en.name).toEqual("Foo")
    en = new Enum(table, 0x2)
    expect(en.name).toEqual("Bar")
    en = new Enum(table, 0x4)
    expect(en.name).toEqual("Baz")
    en = new Enum(table, 0x8)
    expect(en.name).toEqual("unknown")

  it "known returns if the value is registerd", ->
    en = new Enum(table, 0x1)
    expect(en.known).toBe(true)
    en = new Enum(table, 0x2)
    expect(en.known).toBe(true)
    en = new Enum(table, 0x4)
    expect(en.known).toBe(true)
    en = new Enum(table, 0x8)
    expect(en.known).toBe(false)

describe "Flags", ->
  table =
    'Foo': 0x1
    'Bar': 0x2
    'Baz': 0x4

  it "toString() returns a string representation", ->
    fl = new Flags(table, table['Foo'])
    expect(fl.toString()).toEqual("Foo (1)")
    fl = new Flags(table, table['Foo'] | table['Bar'])
    expect(fl.toString()).toEqual("Foo, Bar (3)")
    fl = new Flags(table, table['Foo'] | table['Bar'] | table['Baz'])
    expect(fl.toString()).toEqual("Foo, Bar, Baz (7)")
    fl = new Flags(table, table['Foo'] | 10)
    expect(fl.toString()).toEqual("Foo, Bar (11)")
    fl = new Flags(table, 0x0)
    expect(fl.toString()).toEqual("none (0)")
    fl = new Flags(table, 0x8)
    expect(fl.toString()).toEqual("none (8)")

  it "get returns a boolean value", ->
    fl = new Flags(table, table['Foo'])
    expect(fl.get 'Foo').toBe(true)
    fl = new Flags(table, table['Foo'] | table['Bar'])
    expect(fl.get 'Bar').toBe(true)
    fl = new Flags(table, table['Foo'] | table['Bar'] | table['Baz'])
    expect(fl.get 'Baz').toBe(true)
    fl = new Flags(table, table['Foo'] | 10)
    expect(fl.get 'Foo').toBe(true)
    fl = new Flags(table, 0x0)
    expect(fl.get 'Foo').toBe(false)
    fl = new Flags(table, 0x8)
    expect(fl.get 'Foo').toBe(false)

  it "is returns if its value represents the specified flag exactly", ->
    fl = new Flags(table, table['Foo'])
    expect(fl.is 'Foo').toBe(true)
    fl = new Flags(table, table['Foo'] | table['Bar'])
    expect(fl.is 'Bar').toBe(false)
    fl = new Flags(table, table['Foo'] | table['Bar'] | table['Baz'])
    expect(fl.is 'Baz').toBe(false)
    fl = new Flags(table, table['Foo'] | 10)
    expect(fl.is 'Foo').toBe(false)
    fl = new Flags(table, 0x0)
    expect(fl.is 'Foo').toBe(false)
    fl = new Flags(table, 0x8)
    expect(fl.is 'Foo').toBe(false)

describe "MACAddress", ->
  it "can be constructed from Buffer", ->
    expect ->
      new MACAddress(new Buffer([0x01, 0x23, 0x45, 0x67, 0x89, 0xab]))
    .not.toThrow()

  it "can be constructed from String", ->
    expect ->
      new MACAddress("01:23:45:67:89:ab")
    .not.toThrow()

  it "toString() returns a string representation", ->
    addr = new MACAddress(new Buffer([0x01, 0x23, 0x45, 0x67, 0x89, 0xab]))
    expect(addr.toString()).toEqual("01:23:45:67:89:ab")

  it "equals() returns if the given representation is equal to this", ->
    addr = new MACAddress(new Buffer([0x01, 0x23, 0x45, 0x67, 0x89, 0xab]))
    expect(addr.equals("01:23:45:67:89:ab")).toEqual(true)
    expect(addr.equals("01-23-45-67-89-ab")).toEqual(true)
    expect(addr.equals("01:23:45:67:89:AB")).toEqual(true)

describe "IPv4Address", ->
  it "can be constructed from Buffer", ->
    expect ->
      new IPv4Address(new Buffer([192,168,1,50]))
    .not.toThrow()

  it "can be constructed from String", ->
    expect ->
      new IPv4Address("192.168.1.50")
    .not.toThrow()

  addr = new IPv4Address(new Buffer([192,168,1,50]))
  it "toString() returns a string representation", ->
    expect(addr.toString()).toEqual("192.168.1.50")

  it "equals() returns if the given representation is equal to this", ->
    addr = new IPv4Address(new Buffer([192,168,1,50]))
    expect(addr.equals("192.168.1.50")).toEqual(true)

describe "IPv4Host", ->
  addr = new IPv4Address(new Buffer([192,168,1,50]))
  host = new IPv4Host(addr, 8080)
  it "toString() returns a string representation", ->
    expect(host.toString()).toEqual("192.168.1.50:8080")

describe "IPv6Address", ->
  addr = new IPv6Address(new Buffer([
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef
  ]))
  it "toString() returns a string representation", ->
    expect(addr.toString()).toEqual("123:4567:89ab:cdef:123:4567:89ab:cdef")

describe "IPv6Host", ->
  addr = new IPv6Address(new Buffer([
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef
  ]))
  host = new IPv6Host(addr, 8080)
  it "toString() returns a string representation", ->
    expect(host.toString())
      .toEqual("[123:4567:89ab:cdef:123:4567:89ab:cdef]:8080")
