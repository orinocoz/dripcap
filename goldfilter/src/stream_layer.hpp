#ifndef STREAM_LAYER_HPP
#define STREAM_LAYER_HPP

struct Layer;
typedef std::shared_ptr<Layer> LayerPtr;

struct StreamLayer {
    LayerPtr layer;
};

#endif
