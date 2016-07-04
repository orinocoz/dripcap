import {Layer,
        Buffer,
        Msgpack} from 'dripcap';
import MACAddress from './mac.es';

export default class IPv4Dissector
{
    constructor(options)
    {
    }

    analyze(packet, parentLayer)
    {
        function assertLength(len)
        {
            if (parentLayer.payload.length < len) {
                throw new Error('too short frame');
            }
        }

        let layer = new Layer();
        layer.name = 'IPv4';
        layer.namespace = '::Ethernet::IPv4';

        layer.payload = parentLayer.payload.slice(14);

        layer.fields.push({
            name : 'Payload',
            value : layer.payload,
            range : layer.payload
        });

        layer.summary = "ipv4";

        parentLayer.layers[layer.namespace] = layer;
        return true;
    }
}
