#ifndef CHANNEL_HPP
#define CHANNEL_HPP

#include <thread>
#include <queue>
#include <set>

class ChannelBase
{
  public:
    ChannelBase();
    virtual ~ChannelBase();
    ChannelBase(ChannelBase const &) = delete;
    ChannelBase &operator=(ChannelBase const &) = delete;

  public:
    template <class... Args>
    static size_t select(std::initializer_list<ChannelBase *> args)
    {
        std::vector<ChannelBase *> channels(args);
        if (channels.empty()) {
            return 1;
        }

        std::condition_variable cond;
        for (size_t i = 0; i < channels.size(); ++i) {
            ChannelBase *chan = channels.at(i);
            std::unique_lock<std::mutex> lock(chan->mutex);
            if (chan->closed) {
                return i;
            }
        }
        for (size_t i = 0; i < channels.size(); ++i) {
            ChannelBase *chan = channels.at(i);
            std::unique_lock<std::mutex> lock(chan->mutex);
            chan->selectConds.insert(&cond);
        }

        std::mutex m;
        size_t index = channels.size();
        while (index >= channels.size()) {
            std::unique_lock<std::mutex> lock(m);
            cond.wait(lock, [&channels, &index] {
                for (size_t i = 0; i < channels.size(); ++i) {
                    ChannelBase *chan = channels.at(i);
                    std::unique_lock<std::mutex> lock(chan->mutex);
                    if (chan->closed || chan->ready()) {
                        index = i;
                        return true;
                    }
                }
                return false;
            });
        }

        for (size_t i = 0; i < channels.size(); ++i) {
            ChannelBase *chan = channels.at(i);
            std::unique_lock<std::mutex> lock(chan->mutex);
            chan->selectConds.erase(&cond);
        }
        return index;
    }

  protected:
    virtual bool ready() const = 0;

  protected:
    std::mutex mutex;
    std::set<std::condition_variable *> selectConds;
    bool closed;
};

ChannelBase::ChannelBase()
    : closed(false)
{
}

ChannelBase::~ChannelBase()
{
}

template <class T>
class Channel final : public ChannelBase
{
  public:
    Channel();
    ~Channel();
    void send(const T &val);
    T recv();
    void close();

  private:
    bool ready() const override;

  private:
    std::condition_variable cond;
    std::queue<T> queue;
};

template <class T>
Channel<T>::Channel()
{
}

template <class T>
Channel<T>::~Channel()
{
    close();
}

template <class T>
void Channel<T>::send(const T &val)
{
    {
        std::unique_lock<std::mutex> lock(mutex);
        queue.push(val);
    }
    cond.notify_all();
}

template <class T>
T Channel<T>::recv()
{
    std::unique_lock<std::mutex> lock(mutex);
    cond.wait(lock, [this] {
        return !queue.empty() || closed;
    });
    if (queue.empty()) {
        return T();
    } else {
        T val = queue.front();
        queue.pop();
        return val;
    }
}

template <class T>
void Channel<T>::close()
{
    {
        std::unique_lock<std::mutex> lock(mutex);
        if (closed)
            return;
        closed = true;
    }
    cond.notify_all();
    for (std::condition_variable *c : selectConds) {
        c->notify_all();
    }
}

template <class T>
bool Channel<T>::ready() const
{
    return !queue.empty();
}

#endif
