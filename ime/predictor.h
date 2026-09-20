#pragma once
#include <algorithm>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace rhg {
struct Word { const char16_t *text; unsigned frequency; unsigned first; unsigned count; };
struct Pair { unsigned target; unsigned score; };
#include "model.inc"

inline bool letter(char16_t hi, char16_t lo) {
    return hi == 0xd803 && lo >= 0xdd00 && lo <= 0xdd27;
}
struct Context {
    std::u16string prefix, previous;
    bool valid = false;
};
inline Context context(std::u16string_view before, std::u16string_view after) {
    Context c;
    if (after.size() >= 2 && letter(after[0], after[1])) return c;
    size_t start = before.size();
    while (start >= 2 && letter(before[start-2], before[start-1])) start -= 2;
    c.prefix = before.substr(start);
    if (c.prefix.empty() && !before.empty() && before.back() != u' ' && before.back() != u'\t') return c;
    size_t end = start;
    while (end && (before[end-1] == u' ' || before[end-1] == u'\t')) --end;
    if (end < start) {
        size_t previousStart = end;
        while (previousStart >= 2 && letter(before[previousStart-2], before[previousStart-1])) previousStart -= 2;
        c.previous = before.substr(previousStart, end-previousStart);
    }
    c.valid = true;
    return c;
}
inline int find(std::u16string_view word) {
    auto it = std::lower_bound(std::begin(words), std::end(words), word,
        [](const Word &entry, std::u16string_view value) { return std::u16string_view(entry.text) < value; });
    return it != std::end(words) && std::u16string_view(it->text) == word ? int(it - std::begin(words)) : -1;
}
inline std::vector<unsigned> suggest(std::u16string_view prefix, std::u16string_view previous, size_t limit = 5) {
    struct Candidate { unsigned id, score; };
    std::vector<Candidate> best;
    int prev = find(previous);
    for (unsigned id = 0; id < sizeof(words)/sizeof(words[0]); ++id) {
        const auto &entry = words[id];
        std::u16string_view text(entry.text);
        if (text == prefix || text.substr(0, prefix.size()) != prefix) continue;
        unsigned score = entry.frequency;
        if (prev >= 0) {
            const auto &parent = words[prev];
            for (unsigned j = parent.first; j < parent.first + parent.count; ++j)
                if (pairs[j].target == id) { score += 256 + 256 * pairs[j].score; break; }
        }
        Candidate candidate{id, score};
        auto pos = std::lower_bound(best.begin(), best.end(), candidate, [](Candidate a, Candidate b) {
            return a.score > b.score || (a.score == b.score && a.id < b.id);
        });
        best.insert(pos, candidate);
        if (best.size() > limit) best.pop_back();
    }
    std::vector<unsigned> result;
    for (auto c : best) result.push_back(c.id);
    return result;
}
}
