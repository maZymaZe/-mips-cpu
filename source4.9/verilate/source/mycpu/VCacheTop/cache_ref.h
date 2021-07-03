#pragma once

#include "defs.h"
#include "memory.h"
#include "reference.h"

class MyCache;

class CacheRefModel final : public ICacheRefModel {
public:
    CacheRefModel(MyCache *_top, size_t memory_size);

    void reset();
    auto load(addr_t addr, AXISize size) -> word_t;
    void store(addr_t addr, AXISize size, word_t strobe, word_t data);
    void check_internal();
    void check_memory();

private:


    word_t cache[256][16];
    int nxt_wr[256] = {0};
    struct META{
        addr_t tag;
        bool valid;
        bool dirty;
    }meta[256];


    MyCache *top;
    VModelScope *scope;

    /**
     * TODO (Lab3) declare reference model's memory and internal states :)
     *
     * NOTE: you can use BlockMemory, or replace it with anything you like.
     */

    // int state;
    BlockMemory mem;
    int fetch(addr_t addr);
    int inCache(addr_t addr);
};
