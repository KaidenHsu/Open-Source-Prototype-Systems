#include <cstdint>
#include <iostream>
#include <iomanip>
#include "Vtiny_system_todo.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static void eval_cycle(Vtiny_system_todo* top, VerilatedVcdC* tfp) {
    top->clk = 0;
    top->eval();
    if (tfp) tfp->dump(main_time);
    main_time++;
    top->clk = 1;
    top->eval();
    if (tfp) tfp->dump(main_time);
    main_time++;
    top->clk = 0;
    top->eval();
}

static void clear_reqs(Vtiny_system_todo* top) {
    top->c0_req_valid = 0;
    top->c0_req_write = 0;
    top->c0_req_addr  = 0;
    top->c0_req_wdata = 0;
    top->c1_req_valid = 0;
    top->c1_req_write = 0;
    top->c1_req_addr  = 0;
    top->c1_req_wdata = 0;
}

static uint32_t core_read(Vtiny_system_todo* top, VerilatedVcdC* tfp, int core, uint8_t addr) {
    clear_reqs(top);
    if (core == 0) {
        top->c0_req_valid = 1;
        top->c0_req_write = 0;
        top->c0_req_addr  = addr;
    } else {
        top->c1_req_valid = 1;
        top->c1_req_write = 0;
        top->c1_req_addr  = addr;
    }
    top->eval();
    uint32_t value = (core == 0) ? top->c0_resp_rdata : top->c1_resp_rdata;
    eval_cycle(top, tfp);
    clear_reqs(top);
    top->eval();
    return value;
}

static uint32_t core_write(Vtiny_system_todo* top, VerilatedVcdC* tfp, int core, uint8_t addr, uint32_t data) {
    clear_reqs(top);
    if (core == 0) {
        top->c0_req_valid = 1;
        top->c0_req_write = 1;
        top->c0_req_addr  = addr;
        top->c0_req_wdata = data;
    } else {
        top->c1_req_valid = 1;
        top->c1_req_write = 1;
        top->c1_req_addr  = addr;
        top->c1_req_wdata = data;
    }
    top->eval();
    uint32_t value = (core == 0) ? top->c0_resp_rdata : top->c1_resp_rdata;
    eval_cycle(top, tfp);
    clear_reqs(top);
    top->eval();
    return value;
}

static void print_state(Vtiny_system_todo* top, int step, const char* action, uint32_t observed) {
    std::cout << std::dec << std::setw(2) << step << "  " << std::left << std::setw(18) << action
              << " observed=" << std::setw(3) << observed
              << " mem[0x24]=" << std::setw(3) << top->debug_mem_24
              << " | C0(valid=" << int(top->debug_c0_valid)
              << ", tag=0x" << std::hex << std::setw(2) << std::setfill('0') << int(top->debug_c0_tag)
              << std::dec << std::setfill(' ') << ", data=" << top->debug_c0_data << ")"
              << " | C1(valid=" << int(top->debug_c1_valid)
              << ", tag=0x" << std::hex << std::setw(2) << std::setfill('0') << int(top->debug_c1_tag)
              << std::dec << std::setfill(' ') << ", data=" << top->debug_c1_data << ")"
              << " | inv0=" << int(top->debug_c0_inv_valid) << "@0x" << std::hex << int(top->debug_c0_inv_addr)
              << " inv1=" << int(top->debug_c1_inv_valid) << "@0x" << int(top->debug_c1_inv_addr)
              << " snoop0=" << int(top->debug_snoop_to_c0_valid) << "@0x" << int(top->debug_snoop_to_c0_addr)
              << " snoop1=" << int(top->debug_snoop_to_c1_valid) << "@0x" << int(top->debug_snoop_to_c1_addr)
              << std::dec << "\n";
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    auto* top = new Vtiny_system_todo;
    auto* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("build/wave.vcd");

    clear_reqs(top);
    top->rst = 1;
    eval_cycle(top, tfp);
    eval_cycle(top, tfp);
    top->rst = 0;
    top->eval();

    const uint8_t A = 0x24;
    bool pass = true;
    int step = 0;

    std::cout << "Week 10 snooping invalidation integration lab\n";
    std::cout << "Address under test: 0x24, initial memory value: 10\n";
    std::cout << "step action             observed mem/cache/invalidation trace\n";

    uint32_t r0a = core_read(top, tfp, 0, A);
    print_state(top, step++, "C0 read", r0a);
    if (r0a != 10) { std::cout << "[FAIL] C0 first read expected 10\n"; pass = false; }

    uint32_t r1a = core_read(top, tfp, 1, A);
    print_state(top, step++, "C1 read", r1a);
    if (r1a != 10) { std::cout << "[FAIL] C1 first read expected 10\n"; pass = false; }

    uint32_t w0 = core_write(top, tfp, 0, A, 42);
    print_state(top, step++, "C0 write 42", w0);
    if (top->debug_mem_24 != 42) { std::cout << "[FAIL] memory should update to 42 after C0 write\n"; pass = false; }

    uint32_t r1b = core_read(top, tfp, 1, A);
    print_state(top, step++, "C1 reread", r1b);
    if (r1b != 42) { std::cout << "[FAIL] C1 reread expected 42. Likely C0 invalidation did not reach C1 with the full address.\n"; pass = false; }

    uint32_t w1 = core_write(top, tfp, 1, A, 99);
    print_state(top, step++, "C1 write 99", w1);
    if (top->debug_mem_24 != 99) { std::cout << "[FAIL] memory should update to 99 after C1 write\n"; pass = false; }

    uint32_t r0b = core_read(top, tfp, 0, A);
    print_state(top, step++, "C0 reread", r0b);
    if (r0b != 99) { std::cout << "[FAIL] C0 reread expected 99. Likely C1 invalidation did not reach C0.\n"; pass = false; }

    if (pass) {
        std::cout << "[PASS] Snooping invalidation interface is correctly integrated.\n";
    } else {
        std::cout << "TESTS FAILED: fix only rtl/tiny_system_todo.sv, then rerun scripts/run_verilator.sh\n";
    }

    tfp->close();
    delete tfp;
    delete top;
    return pass ? 0 : 1;
}
