#ifndef ICS_INLINE_TESTS

#include "common.h"
#include "testbench.h"
#include "cell.h"
#include "stupid.h"

extern StupidBuffer *top;
extern VModelScope *scope;
extern DBus *dbus;
extern CacheRefModel *ref;

#endif

/**
 * NOTE: if you want to add some debug prints, don't forget to revert them
 *       before submitting your work to eLearning.
 *       generally, you are NOT ALLOWED to modify any unless stated.
 */

/**
 * basic tests
 */

WITH {
    dbus->async_load(0xc, MSIZE4);
    top->tick();
    // ASSERT(top->dresp == 0);
} AS("void");

WITH {
    // NOTE: it depends on your design.
    //       maybe your cache likes to set addr_ok to false.
    //       in that case, change following lines to match your design.
    ASSERT(dbus->addr_ok() == true);
    ASSERT(dbus->data_ok() == false);
    ASSERT(dbus->rdata() == 0);
} AS("reset");

WITH {
    for (int i = 0; i < 4096; i++) {
        dbus->async_loadw(4 * i);
        dbus->clear();
        top->eval();

        for (int j = 0; j < 256; j++) {
            ASSERT(!dbus->valid());
            top->tick();
        }
    }
} AS("fake load");

WITH {
    for (int i = 0; i < 4096; i++) {
        dbus->async_storew(4 * i, 0xdeadbeef);
        dbus->clear();
        top->eval();

        for (int j = 0; j < 256; j++) {
            ASSERT(!dbus->valid());
            top->tick();
        }
    }
} AS("fake store");

// both dbus->store and dbus->load wait for your model to complete
WITH {
    dbus->store(0, MSIZE4, 0b1111, 0x2048ffff);
    ASSERT(dbus->load(0, MSIZE4) == 0x2048ffff);
} AS("naive");

// this test is explicitly marked with "SKIP".
WITH SKIP {
    bool one = 1, three = 3;
    ASSERT(one + one == three);  // trust me, it must fail
    // but you should not fail here since it's skipped.
} AS("akarin~");

// if your cache does not support partial writes, you can simply skip
// this test by marking it with SKIP.
WITH /*SKIP*/ {
    // S iterates over 0b0000 to 0b1111.
    std::vector<word_t> a;  // to store the correct value
    a.resize(16);

    for (int S = 0; S < 16; S++) {
        auto value = randi();  // equivalent to randi<word_t>, returns a 32 bit random unsigned integer.
        dbus->store(0x100 + 4 * S, MSIZE4, S, value);
        a[S] = value & STROBE_TO_MASK[S];  // STROBE_TO_MASK is defined in common.h
    }

    for (int i = 0; i < 16; i++) {
        auto got = dbus->load(0x100 + 4 * i, MSIZE4);
        ASSERT(got == a[i]);
    }
} AS("strobe");

// this is a more detailed example of DBus.
// add DEBUG to see all memory operations.
WITH /*TRACE*/ /*DEBUG*/ {
    {
        dbus->store(0xc, MSIZE4, 0b1111, 0x12345678);
        ASSERT(dbus->load(0xc, MSIZE4) == 0x12345678);
    }

    {
        uint8_t a[4];
        uint16_t b[2];
        uint32_t c;

        dbus->storew(0x108, 0xdeadbeef);
        dbus->storeh(0x100, 0x0817);
        dbus->storeh(0x102, 0x1926);
        dbus->storeb(0x104, 0xdd);
        dbus->storeb(0x105, 0xcc);
        dbus->storeb(0x106, 0xbb);
        dbus->storeb(0x107, 0xaa);

        a[0] = dbus->loadb(0x108);
        a[1] = dbus->loadb(0x109);
        a[2] = dbus->loadb(0x10a);
        a[3] = dbus->loadb(0x10b);
        b[0] = dbus->loadh(0x104);
        b[1] = dbus->loadh(0x106);
        c = dbus->loadw(0x100);

        ASSERT(a[0] == 0xef && a[1] == 0xbe && a[2] == 0xad && a[3] == 0xde);
        ASSERT(b[0] == 0xccdd && b[1] == 0xaabb);
        ASSERT(c == 0x19260817);

        a[0] = dbus->loadb(0x100);
        a[1] = dbus->loadb(0x101);
        a[2] = dbus->loadb(0x102);
        a[3] = dbus->loadb(0x103);
        b[0] = dbus->loadh(0x108);
        b[1] = dbus->loadh(0x10a);
        c = dbus->loadw(0x104);

        ASSERT(a[0] == 0x17 && a[1] == 0x08 && a[2] == 0x26 && a[3] == 0x19);
        ASSERT(b[0] == 0xbeef && b[1] == 0xdead);
        ASSERT(c == 0xaabbccdd);
    }

    {
        // NOTE: the default memory size is 1 MiB
        //       which is specified in common.h: "MEMORY_SIZE".
        //       Therefore, the maximum address is 0xfffff.

        // asynchronous operations do not wait for cache to complete,
        // so you have to manually tick the cache or use dbus->await.

        dbus->async_storew(0xffffc, 0x2048ffff);

        top->ticks(2048);

        // stop issuing store.
        dbus->clear();
        top->ticks(2048);

        // issue a new load.
        dbus->async_loadw(0xffffc);
        word_t value = dbus->await(2048);  // it waits for async_loadw to complete.
        ASSERT(value == 0x2048ffff);
    }
} AS("ad hoc");

// this is an example of DBusPipeline.
// all operations performed by pipeline are asynchronous, unless
// p.fence() is called.
// add DEBUG to see all memory & pipeline operations.
WITH /*TRACE*/ /*DEBUG*/ {
    auto p = DBusPipeline(top, dbus);

    {
        word_t value;
        p.store(0xc, MSIZE4, 0b1111, 0x12345678);
        p.load(0xc, MSIZE4, &value);
        p.expect(0xc, MSIZE4, 0x12345678);
        p.fence(2048);  // above three operations should complete in 2048 cycles
        ASSERT(value == 0x12345678);
    }

    {
        uint8_t a[4];
        uint16_t b[2];
        uint32_t c;

        p.storew(0x108, 0xdeadbeef);
        p.storeh(0x100, 0x0817);
        p.storeh(0x102, 0x1926);
        p.storeb(0x104, 0xdd);
        p.storeb(0x105, 0xcc);
        p.storeb(0x106, 0xbb);
        p.storeb(0x107, 0xaa);

        p.loadb(0x108, a + 0);
        p.loadb(0x109, a + 1);
        p.loadb(0x10a, a + 2);
        p.loadb(0x10b, a + 3);
        p.loadh(0x104, b + 0);
        p.loadh(0x106, b + 1);
        p.loadw(0x100, &c);

        p.expectb(0x100, 0x17);
        p.expectb(0x101, 0x08);
        p.expectb(0x102, 0x26);
        p.expectb(0x103, 0x19);
        p.expecth(0x108, 0xbeef);
        p.expecth(0x10a, 0xdead);
        p.expectw(0x104, 0xaabbccdd);

        p.fence(65536);

        ASSERT(a[0] == 0xef && a[1] == 0xbe && a[2] == 0xad && a[3] == 0xde);
        ASSERT(b[0] == 0xccdd && b[1] == 0xaabb);
        ASSERT(c == 0x19260817);
    }

    p.fence(0);  // assert that pipeline is empty
    p.fence();  // must not block

    {
        word_t value;
        p.storew(0xffffc, 0x2048ffff);
        p.loadw(0xffffc, &value);

        // manually update the pipeline
        p.ticks(2048);

        ASSERT(value == 0x2048ffff);
    }

    // NOTE: p.fence() will be called implicitly when p is being
    //       destructed here.
} AS("pipelined");

WITH {
    auto p = DBusPipeline(top, dbus);
    auto factory = MemoryCellFactory(&p);

    // take a, b, c from verilated memory.
    auto a = factory.take<word_t>(0);
    auto b = factory.take<uint16_t>(4);
    auto c = factory.take<uint16_t>(2);

    a.set(0x19260817);
    b = 0xbeef;
    ASSERT(a.get() == 0x19260817);
    ASSERT(b.get() == 0x0000beef);

    a = b;
    ASSERT(b.get() == 0x0000beef);

    c = 0xdead;
    ASSERT(a.get() == 0xdeadbeef);
    ASSERT(c.get() == 0x0000dead);
    ASSERT((a + c) == 0xdeae9d9c);

    b = c;
    ASSERT(b.get() == 0x0000dead);
} AS("memory cell");

WITH {
    constexpr int n = 64;

    auto p = DBusPipeline(top, dbus);
    auto factory = MemoryCellFactory(&p);

    // take an array of length n from verilated memory.
    auto a = factory.take<uint32_t, n>(0);

    for (int i = 0; i < n; i++) {
        a[i] = uint32_t(0x19260817u * (i + 1));
    }
    for (int i = 0; i < n; i++) {
        ASSERT(a[i] == uint32_t(0x19260817u * (i + 1)));
    }
} AS("memory cell array");

/**
 * model comparing
 *
 * you can use synchronous load/store functions in dbus.
 * we have hacked these functions to check the results with your
 * reference model during invocation.
 */

constexpr size_t CMP_SCAN_SIZE = 32 * 1024;  // 32 KiB

WITH CMP_TO(ref) {
    for (size_t i = 0; i < CMP_SCAN_SIZE / 4; i++) {
        dbus->storew(4 * i, randi<uint32_t>());
        dbus->loadw(4 * i);
    }
} AS("cmp: word");

WITH CMP_TO(ref) {
    for (size_t i = 0; i < CMP_SCAN_SIZE / 2; i++) {
        dbus->storeh(2 * i, randi<uint16_t>());
        dbus->loadh(2 * i);
    }
} AS("cmp: halfword");

WITH CMP_TO(ref) {
    for (size_t i = 0; i < CMP_SCAN_SIZE; i++) {
        dbus->storeb(i, randi<uint8_t>());
        dbus->loadb(i);
    }
} AS("cmp: byte");

WITH CMP_TO(ref) {
    constexpr int T = 65536;
    for (int i = 0; i < T; i++) {
        addr_t addr = randi<addr_t>(0, MEMORY_SIZE / 8) * 4;  // random address within 512 KiB region
        dbus->storew(addr, randi());
        dbus->loadw(addr);
    }
} AS("cmp: random");

/**
 * pressure tests and benchmarks
 */

WITH {
    auto p = DBusPipeline(top, dbus);

    for (addr_t i = 0; i < MEMORY_SIZE / 4; i++) {
        p.storew(4 * i, 0xcccccccc);
    }
    for (addr_t i = 0; i < MEMORY_SIZE / 4; i++) {
        p.expectw(4 * i, 0xcccccccc);
    }
} AS("memset");

WITH {
    auto p = DBusPipeline(top, dbus);

    addr_t MID = MEMORY_SIZE / 2;
    for (addr_t i = MID; i < MEMORY_SIZE; i += 4) {
        p.storew(i, randi());
    }

    word_t buffer[32];
    for (addr_t i = 0; i < MID; i += sizeof(buffer)) {
        for (addr_t j = 0; j < 32; j++) {
            p.loadw(MID + i + 4 * j, buffer + j);
        }

        p.fence();

        for (addr_t j = 0; j < 32; j++) {
            p.storew(i + 4 * j, buffer[j]);
        }
    }

    for (addr_t i = 0; i < MID; i += 4) {
        word_t expected;
        p.loadw(MID + i, &expected);
        p.fence();
        p.expectw(i, expected);
    }
} AS("memcpy");

WITH {
    auto p = DBusPipeline(top, dbus);
    for (addr_t i = 0; i < MEMORY_SIZE; i += 4) {
        auto value = randi();
        p.storew(i, value);
        p.expectw(i, value);
    }
} AS("load/store repeat");

WITH {
    auto p = DBusPipeline(top, dbus);

    for (int i = MEMORY_SIZE - 1; i >= 0; i--) {
        p.storeb(i, 0xcc);
    }
    for (size_t i = 0; i < MEMORY_SIZE; i += 4) {
        p.expectw(i, 0xcccccccc);
    }
} AS("backward memset");

WITH {
    auto p = DBusPipeline(top, dbus);

    for (int i = MEMORY_SIZE - 2; i >= 0; i -= 2) {
        p.storeh(i, 0xdead);
        p.expectb(i, 0xad);
        p.expectb(i + 1, 0xde);
    }
    for (size_t i = 0; i < MEMORY_SIZE; i += 4) {
        p.expectw(i, 0xdeaddead);
    }
} AS("backward load/store");

WITH {
    constexpr int T = 1000000;
    constexpr int SIZE = 1024;

    std::vector<word_t> ref;
    ref.resize(SIZE);

    int i = 0;
    auto p = DBusPipeline(top, dbus);
    for (int _ = 0; _ < T; _++) {
        int op = randi(0, 1);

        if (op == 0) {
            // store
            auto value = randi();
            ref[i] = value;
            p.storew(4 * i, value);
        } else {
            p.expectw(4 * i, ref[i]);
        }

        i = (i + randi(0, 64)) % SIZE;
    }
} AS("random step");

WITH {
    std::vector<uint8_t> ref;
    ref.resize(MEMORY_SIZE);

    constexpr int T = 1000000;

    auto p = DBusPipeline(top, dbus);
    for (int _ = 0; _ < T; _++) {
        int size = 1 << randi(0, 2);
        int op = randi(0, 1);
        addr_t addr = randi(0ul, MEMORY_SIZE / size - 1) * size;

        log_debug(
            "random: %s @addr=0x%x, size=%d\n",
            op ? "load" : "store", addr, size
        );

        if (op == 0) {
            // store
            switch (size) {
                case 1: {
                    auto value = randi<uint8_t>();
                    ref[addr] = value;
                    p.storeb(addr, value);
                } break;

                case 2: {
                    auto value = randi<uint16_t>();
                    ref[addr + 0] = (value >> 0) & 0xff;
                    ref[addr + 1] = (value >> 8) & 0xff;
                    p.storeh(addr, value);
                } break;

                case 4: {
                    auto value = randi<uint32_t>();
                    for (int i = 0; i < 4; i++) {
                        ref[addr + i] = (value >> (8 * i)) & 0xff;
                    }
                    p.storew(addr, value);
                } break;
            }
        } else {
            // load
            switch (size) {
                case 1: {
                    p.expectb(addr, ref[addr]);
                } break;

                case 2: {
                    p.expecth(addr, ref[addr] | (ref[addr + 1] << 8));
                } break;

                case 3: {
                    word_t value = 0;
                    for (int i = 0; i < 4; i++) {
                        value |= ref[addr + i] << (8 * i);
                    }
                    p.expectw(addr, value);
                } break;
            }
        }
    }
} AS("random load/store");

WITH {
    std::vector<uint8_t> ref;
    ref.resize(MEMORY_SIZE);

    constexpr int T = 100000;

    auto p = DBusPipeline(top, dbus);
    for (int _ = 0; _ < T; _++) {
        int n = randi(1, 128);
        int s = randi(0ul, MEMORY_SIZE - n);
        int t = randi(0, 1);

        log_debug(
            "block: %s @start=0x%x, n=%d\n",
            t ? "load" : "store", s, n
        );

        if (t == 0) {
            // store
            for (int i = 0; i < n; i++) {
                auto value = randi<uint8_t>();
                ref[s + i] = value;
                p.storeb(s + i, value);
            }
        } else {
            // load
            for (int i = 0; i < n; i++) {
                p.expectb(s + i, ref[s + i]);
            }
        }
    }
} AS("random block load/store");

/**
 * real algorithm workloads.
 *
 * you can run real algorithms/programs on your verilated cache
 * with the help of MemoryCell.
 *
 * NOTE: be careful with the default 1MiB memory size.
 */

// the first two tests use DBusPipeline for better performance.
WITH STAT {
    constexpr int n = 150000;

    auto p = DBusPipeline(top, dbus);
    auto factory = MemoryCellFactory(&p);

    auto a = factory.take<uint32_t, n>(0);
    uint32_t b[n];

    for (int i = 0; i < n; i++) {
        a[i] = b[i] = randi();
    }

    std::sort(a, a + n);
    std::sort(b, b + n);

    for (int i = 0; i < n; i++) {
        ASSERT(a[i] == b[i]);
    }
} AS("std::sort");

WITH STAT {
    constexpr int n = 150000;

    auto p = DBusPipeline(top, dbus);
    auto factory = MemoryCellFactory(&p);

    auto a = factory.take<uint32_t, n>(0);
    uint32_t b[n];

    for (int i = 0; i < n; i++) {
        a[i] = b[i] = randi();
    }

    std::stable_sort(a, a + n);
    std::sort(b, b + n);

    for (int i = 0; i < n; i++) {
        ASSERT(a[i] == b[i]);
    }
} AS("std::stable_sort");

// you can also use DBus directly.
// at this time, the reference model can be enabled.
WITH STAT CMP_TO(ref) {
    constexpr int n = 150000;

    // here we do not have to create a pipeline.
    // just dbus is OK.
    auto factory = MemoryCellFactory(dbus);

    auto a = factory.take<uint32_t, n>(0);
    uint32_t b[n];

    for (int i = 0; i < n; i++) {
        a[i] = b[i] = randi();
    }

    std::make_heap(a, a + n);
    for (int i = n; i > 0; i--) {
        std::pop_heap(a, a + i);
    }
    std::sort(b, b + n);

    for (int i = 0; i < n; i++) {
        ASSERT(a[i] == b[i]);
    }
} AS("heap sort");

// you can also manually implement any algorithm on top of memory cells.
WITH STAT CMP_TO(ref) {
    constexpr int n = 50000;

    // set up cell factory.
    auto factory = MemoryCellFactory(dbus);
    auto allocate = [&factory]() {
        return factory.allocate<int>();
    };
    using Cell = decltype(allocate());

    // get a buffer of nodes.
    struct Node {
        Cell key, size, left, right;
    };

    auto construct = [&allocate] {
        return Node{allocate(), allocate(), allocate(), allocate()};
    };

    std::vector<Node> m;
    m.reserve(n + 1);
    for (int i = 0; i < n + 1; i++) {
        m.emplace_back(construct());
    }

    // the algorithms.
    auto root = factory.allocate_and_init(0);
    auto count = factory.allocate_and_init(0);

    std::function<int(int, int)> insert;
    insert = [&insert, &count, &m](int x, int key) -> int {
        if (x == 0) {
            count = count + 1;
            x = count;
            m[x].key = key;
        } else {
            if (key < m[x].key)
                m[x].left = insert(m[x].left, key);
            else
                m[x].right = insert(m[x].right, key);
        }

        m[x].size = m[x].size + 1;
        return x;
    };

    std::function<int(int, int)> kth;
    kth = [&kth, &m](int x, int k) -> int {
        int vsize = m[m[x].left].size;

        if (k <= vsize)
            return kth(m[x].left, k);
        else if (k > vsize + 1)
            return kth(m[x].right, k - vsize - 1);
        else
            return m[x].key;
    };

    // run it!
    int keys[n + 1];
    for (int i = 1; i <= n; i++) {
        keys[i] = randi();
        root = insert(root, keys[i]);
    }

    std::sort(keys + 1, keys + n + 1);

    for (int i = 1; i <= n; i++) {
        ASSERT(kth(root, i) == keys[i]);
    }
} AS("binary search tree");
WITH STAT {
    constexpr int n = 30;

    auto p = DBusPipeline(top, dbus);
    auto factory = MemoryCellFactory(&p);

    auto a = factory.take<uint32_t, n>(0);
	a[0]=0;
	a[1]=1;
    for (int i = 2; i < n; i++) {
        a[i]=a[i-1]+a[i-2];
    }
    ASSERT(514229 == a[29]);

} AS("Fibonacci");
