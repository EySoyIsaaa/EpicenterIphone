#include "EpicenterDSPCore.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

namespace {
constexpr double pi = 3.14159265358979323846;

void require(bool condition, const char* message) {
    if (!condition) { std::fprintf(stderr, "%s\n", message); std::exit(1); }
}

void checkRate(int sampleRate) {
    epicenter::EpicenterDSPCore core;
    core.prepare(sampleRate, 2, 8192);
    core.setEnabled(true);
    core.setParameters(100, 45, 50, 100, 100);
    const int frameCount = sampleRate * 4;
    std::vector<float> left(static_cast<std::size_t>(frameCount));
    std::vector<float> right(left.size());
    for (int i = 0; i < frameCount; ++i) {
        const auto tone = static_cast<float>(0.1 * std::sin(2 * pi * 80 * i / sampleRate));
        left[static_cast<std::size_t>(i)] = tone;
        right[static_cast<std::size_t>(i)] = tone;
    }
    float* channels[2] = { left.data(), right.data() };
    core.process(channels, 2, left.size());
    double real = 0, imaginary = 0;
    float peak = 0;
    for (int i = 0; i < frameCount; ++i) {
        const float value = left[static_cast<std::size_t>(i)];
        require(std::isfinite(value) && std::isfinite(right[static_cast<std::size_t>(i)]), "Non-finite DSP output");
        peak = std::max(peak, std::abs(value));
        if (i >= sampleRate * 2) {
            const double phase = 2 * pi * 40 * i / sampleRate;
            real += value * std::cos(phase);
            imaginary -= value * std::sin(phase);
        }
    }
    const double subAmplitude = std::sqrt(real * real + imaginary * imaginary) / sampleRate;
    require(subAmplitude > 0.0001 && peak < 2, "Missing subharmonic or unstable output");
    std::printf("%d %.9f %.9f\n", sampleRate, subAmplitude, static_cast<double>(peak));

    core.reset();
    std::fill(left.begin(), left.end(), 0);
    std::fill(right.begin(), right.end(), 0);
    core.process(channels, 2, left.size());
    require(std::all_of(left.begin(), left.end(), [](float v) { return v == 0; }), "Silence generates noise");

    core.setEnabled(false);
    std::fill(left.begin(), left.end(), 0.2f);
    core.process(channels, 2, left.size());
    require(std::all_of(left.begin(), left.end(), [](float v) { return v == 0.2f; }), "Disabled DSP changes the signal");
}
}

int main() {
    for (const int sampleRate : {44100, 48000, 96000, 192000}) { checkRate(sampleRate); }
}
