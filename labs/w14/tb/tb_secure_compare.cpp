#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

#include "verilated.h"
#include "verilated_vcd_c.h"

#if defined(DESIGN_BUGGY)
    #include "Vsecure_compare_buggy.h"
    using Dut = Vsecure_compare_buggy;
    static const char *DESIGN_NAME = "buggy";
#elif defined(DESIGN_FIXED)
    #include "Vsecure_compare_fixed.h"
    using Dut = Vsecure_compare_fixed;
    static const char *DESIGN_NAME = "fixed";
#else
    #error "Define DESIGN_BUGGY or DESIGN_FIXED"
#endif

static const uint64_t SECRET = 0x1122334455667788ULL;
static vluint64_t main_time = 0;

double sc_time_stamp() { return static_cast<double>(main_time); }

struct TestCase {
    std::string name;
    uint64_t candidate;
};

// clock tick
static void tick(Dut *dut, VerilatedVcdC *tfp) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(main_time);
    main_time++;

    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(main_time);
    main_time++;
}

// run one test case
static int run_one(Dut *dut, VerilatedVcdC *tfp, uint64_t candidate,
                   int &match, int &debug_count) {
    dut->start = 0;
    dut->candidate = candidate;
    tick(dut, tfp);

    dut->start = 1;
    tick(dut, tfp);
    dut->start = 0;

    int cycles = 0;
    const int max_cycles = 100;
    while (!dut->done && cycles < max_cycles) {
        tick(dut, tfp);
        cycles++;
    }

    match = dut->match;
    debug_count = dut->debug_count;

    // Leave one idle cycle between tests.
    tick(dut, tfp);
    return cycles;
}

static std::string get_arg(int argc, char **argv, const std::string &prefix,
                           const std::string &fallback) {
    for (int i = 1; i < argc; i++) {
        std::string arg(argv[i]);
        if (arg.rfind(prefix, 0) == 0) return arg.substr(prefix.size());
    }
    return fallback;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    bool trace = false;
    for (int i = 1; i < argc; i++) {
        if (std::string(argv[i]) == "+trace") trace = true;
    }

    std::string csv_path = get_arg(argc, argv, "+csv=", "build/latency.csv");
    std::string vcd_path = get_arg(argc, argv, "+vcd=", std::string("build/trace_") + DESIGN_NAME + ".vcd");

    Dut *dut = new Dut;
    VerilatedVcdC *tfp = nullptr;

    if (trace) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        dut->trace(tfp, 99);
        tfp->open(vcd_path.c_str());
    }

    // reset and start
    dut->clk = 0;
    dut->rst = 1;
    dut->start = 0;
    dut->candidate = 0;
    for (int i = 0; i < 5; i++) tick(dut, tfp);
    dut->rst = 0;
    tick(dut, tfp);

    // test cases
    std::vector<TestCase> tests = {
        {"exact_match", SECRET},
        {"mismatch_byte0", SECRET ^ 0x00000000000000ffULL},
        {"mismatch_byte1", SECRET ^ 0x000000000000ff00ULL},
        {"mismatch_byte3", SECRET ^ 0x00000000ff000000ULL},
        {"mismatch_byte7", SECRET ^ 0xff00000000000000ULL},
    };

    // add randomized tests
    std::mt19937_64 rng(14);
    for (int i = 0; i < 5; i++) {
        uint64_t x = rng();
        if (x == SECRET) x ^= 1ULL;
        tests.push_back({"random_" + std::to_string(i), x});
    }

    // csv and header
    std::ofstream csv(csv_path);
    csv << "design,case,candidate_hex,match,latency_cycles,debug_count\n";

    // run all test cases in tests
    bool pass_functional = true;
    for (const auto &tc : tests) {
        int match = 0;
        int debug_count = 0;
        int latency = run_one(dut, tfp, tc.candidate, match, debug_count);
        bool expected_match = (tc.candidate == SECRET);
        if (static_cast<bool>(match) != expected_match) {
            pass_functional = false;
            std::cerr << "Functional mismatch in " << tc.name << "\n";
        }
        csv << DESIGN_NAME << "," << tc.name << ",0x" << std::hex << std::setw(16)
            << std::setfill('0') << tc.candidate << std::dec << "," << match << ","
            << latency << "," << debug_count << "\n";
    }

    // clean up
    csv.close();
    if (tfp) {
        tfp->close();
        delete tfp;
    }
    dut->final();
    delete dut;

    // print info to terminal and return
    std::cout << "Wrote " << csv_path << "\n";
    std::cout << "Functional status: " << (pass_functional ? "PASS" : "FAIL") << "\n";
    return pass_functional ? 0 : 1;
}
