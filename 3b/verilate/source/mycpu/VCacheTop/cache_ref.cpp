#include "cache_ref.h"
#include <stdio.h>
#include <string.h>
#include "mycache.h"
CacheRefModel::CacheRefModel(MyCache* _top, size_t memory_size)
    : top(_top), scope(top->VCacheTop), mem(memory_size) {
    /**
     * TODO (Lab3) setup reference model :)
     */

    mem.set_name("ref");
}

void CacheRefModel::reset() {
    /**
     * TODO (Lab3) reset reference model :)
     */

    log_debug("ref: reset()\n");
    memset(cache, 0, sizeof(cache));
    memset(nxt_wr, 0, sizeof(nxt_wr));
    memset(meta, 0, sizeof(meta));
    mem.reset();
}
int CacheRefModel::inCache(addr_t addr) {
    addr_t tag = addr >> 8;
    for (int i = 0; i < 16; i++) {
        if (meta[i].tag == tag && meta[i].valid == true &&
            (i >> 2) == ((addr & 0xff) >> 6))
            return i + 1;
    }
    return 0;
}
int CacheRefModel::fetch(addr_t addr) {
    word_t index = ((addr & 0xff) >> 6);
    nxt_wr[index] = (nxt_wr[index] + 1) &3;
    int lid = (nxt_wr[index]) | (index << 2);
     //printf("\n!%x %d!\n",addr,lid);

    if (meta[lid].valid && meta[lid].dirty) {
        addr_t start = (meta[lid].tag << 8) | (index <<6);
        for (int i = 0; i < 16; i++) {
            mem.store(start + 4 * i, cache[lid][i], 0xffffffff);
            //printf("\n!%x %x!\n", start + 4 * i,cache[lid][i]);
            //scanf("%*d");
        }
    }
    addr_t start = addr / 64 * 64;
    for (int i = 0; i < 16; i++) {
        cache[lid][i] = mem.load(start + 4 * i);
    }
    meta[lid].tag = addr >> 8;
    meta[lid].valid = 1;
    meta[lid].dirty = 0;
    return lid;
}
auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t {
    /**
     * TODO (Lab3) implement load operation for reference model :)
     */

    log_debug("ref: load(0x%x, %d)\n", addr, 1 << size);
    //printf("\nref: load(0x%x, %d)\n", addr, 1 << size);
    int nw = inCache(addr);
    if (nw == 0)
        nw = fetch(addr);
    else
        nw--;
    //printf("\n! %d %x %x!\n", nw, addr % 64 / 4, cache[nw][addr % 64 / 4]);
    return cache[nw][addr % 64 / 4];
}

void CacheRefModel::store(addr_t addr,
                          AXISize size,
                          word_t strobe,
                          word_t data) {
    /**
     * TODO (Lab3) implement store operation for reference model :)
     */

    log_debug("ref: store(0x%x, %d, %x, \"%08x\")\n", addr, 1 << size, strobe,
              data);
    //printf("\nref: store(0x%x, %d, %x, \"%08x\")\n", addr, 1 << size, strobe,data);
    int nw = inCache(addr);
    
    if (nw == 0)
        nw = fetch(addr);
    else
        nw--;
   
    auto mask = STROBE_TO_MASK[strobe];
    auto& value = cache[nw][addr % 64 / 4];

    
    meta[nw].dirty = true;
    value = (data & mask) | (value & ~mask);

    //printf("!%x %x %x!%d %d %x!\n", addr, data, mask, nw, addr % 64 / 4, value);
    //mem.store(addr, data, mask);
}

void CacheRefModel::check_internal() {
    /**
     * TODO (Lab3) compare reference model's internal states to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     */
    
    log_debug("ref: check_internal()\n");
    //check_memory();
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            if (meta[i].valid)
                asserts(cache[i][j] == scope->mem[i * 16 + j],
                        "reference model's internal state is different from "
                        "RTL model."
                        " at mem[%x][%x], expected = %08x, got = %08x",
                        i, j, cache[i][j], scope->mem[i * 16 + j]);
        }
    }

    /**
     * the following comes from StupidBuffer's reference model.
     */
    // for (int i = 0; i < 16; i++) {
    //     asserts(
    //         buffer[i] == scope->mem[i],
    //         "reference model's internal state is different from RTL model."
    //         " at mem[%x], expected = %08x, got = %08x",
    //         i, buffer[i], scope->mem[i]
    //     );
    // }
}

void CacheRefModel::check_memory() {
    /**
     * TODO (Lab3) compare reference model's memory to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     *       you can use mem.dump() and MyCache::dump() to get the full contents
     *       of both memories.
     */

    log_debug("ref: check_memory()\n");
    auto d1=mem.dump(0, mem.size());
    auto d2=top->dump();
   /* int l=d1.size();
    for(int i=0;i<l;i++){
        if(d1[i]!=d2[i]){
            printf("\n!%d %x %x!\n",i,d1[i],d2[i]);
        }
    }*/
    /**
     * the following comes from StupidBuffer's reference model.
     */
    asserts(d1 == d2,"reference model's memory content is different from RTL model");
}
