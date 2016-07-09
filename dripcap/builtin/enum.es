import {Buffer} from 'dripcap';

export default class Enum
{
    constructor(table, value)
    {
        if (typeof table !== 'object') {
            throw new TypeError('expected Object');
        }
        this.table = table;
        this.value = value;
    }

    get name()
    {
        let name = this.table[this.value];
        return name ? name : 'unknown';
    }

    get known()
    {
        return (this.table[this.value] != null);
    }

    toString()
    {
        return `${this.name} (${this.value})`;
    }

    toJSON()
    {
        return this.toString();
    }

    toMsgpack()
    {
        let table = {};
        if (this.known) {
            table[this.value] = this.table[this.value];
        }
        return [ 'dripcap/enum', table, this.value ];
    }

    equals(val)
    {
        return val.toString() === this.toString();
    }
}
