# english

[![Crates.io](https://img.shields.io/crates/v/english)](https://crates.io/crates/english)
[![Docs.rs](https://docs.rs/english/badge.svg)](https://docs.rs/english)
![License](https://img.shields.io/crates/l/english)
[![Discord](https://img.shields.io/discord/123456789012345678.svg?logo=discord&logoColor=white&color=5865F2)](https://discord.gg/tDBPkdgApN)


**english** is a blazing fast and light weight English inflection library written in Rust. Total bundled data size is less than 1 MB. It provides extremely accurate verb conjugation and noun/adjective declension based on highly processed Wiktionary data, making it ideal for real-time procedural text generation.

## ⚡ Speed and Accuracy

Evaluation of the English inflector (`extractor/main.rs/check_*`) and performance benchmarking (`examples/speedmark.rs`) shows:

| Part of Speech | Correct / Total | Accuracy  | Throughput (calls/sec) | Time per Call |
|----------------|----------------|-----------|-----------------------|---------------|
| **Nouns**      | 238106 / 238549 | 99.81%   | 5,228,300             | 191 ns        |
| **Verbs**      | 158056 / 161643 | 97.78%   | 8,473,248             | 118 ns        |
| **Adjectives** | 119200 / 119356 | 99.86%   | 11,999,052             | 83 ns        |

*Note: Benchmarking was done under a worst-case scenario; typical real-world usage is 50~ nanoseconds faster.*

## 📦 Installation

```
cargo add english
```

Then in your code:

```rust
use english::*;
fn main() {
    // --- Mixed Sentence Example ---
    let subject_number = Number::Plural;
    let run = Verb::present_participle("run"); // running
    let child = Noun::from("child").with_specifier(run); //running child
    let subject = English::noun(child, &subject_number); //running children
    let verb = English::verb(
        "steal",
        &Person::Third,
        &subject_number,
        &Tense::Past,
        &Form::Finite,
    ); //stole
    let object = Noun::count_with_number("potato", 7); //7 potatoes

    let sentence = format!("The {} {} {}.", subject, verb, object);
    assert_eq!(sentence, "The running children stole 7 potatoes.");

    // --- Nouns ---
    // Note that noun(), count(), etc can work on both strings and Noun struct
    let jeans = Noun::from("pair").with_complement("of jeans");
    assert_eq!(Noun::count_with_number(jeans, 3), "3 pairs of jeans");
    // Regular plurals
    assert_eq!(English::noun("cat", &Number::Plural), "cats");
    // Add a number 2-9 to the end of the word to try different forms.
    // Can use plural()
    assert_eq!(Noun::plural("die2"), "dice");
    // Use count function for better ergonomics if needed
    assert_eq!(Noun::count("man", 2), "men");
    // Use count_with_number function to preserve the number
    assert_eq!(Noun::count_with_number("nickel", 3), "3 nickels");
    // Invariant nouns
    assert_eq!(English::noun("sheep", &Number::Plural), "sheep");

    // --- Verbs ---
    // All verb functions can use either strings or Verb struct
    let pick_up = Verb::from("pick").with_particle("up");
    // Helper functions: past() , third_person(), present_participle(), infinitive() etc.
    assert_eq!(Verb::past(&pick_up,), "picked up");
    assert_eq!(Verb::present_participle("walk"), "walking");
    assert_eq!(Verb::past_participle("go"), "gone");
    // Add a number 2-9 to the end of the word to try different forms.
    assert_eq!(Verb::past("lie"), "lay");
    assert_eq!(Verb::past("lie2"), "lied");
    // "to be" has the most verb forms in english and requires using verb()
    assert_eq!(
        English::verb(
            "be",
            &Person::First,
            &Number::Singular,
            &Tense::Present,
            &Form::Finite
        ),
        "am"
    );

    // --- Adjectives ---
    // Add a number 2-9 to the end of the word to try different forms. (Bad has the most forms at 3)
    assert_eq!(English::adj("bad", &Degree::Comparative), "more bad");
    assert_eq!(English::adj("bad", &Degree::Superlative), "most bad");
    assert_eq!(Adj::comparative("bad2"), "badder");
    assert_eq!(Adj::superlative("bad2"), "baddest");
    assert_eq!(Adj::comparative("bad3"), "worse");
    assert_eq!(Adj::superlative("bad3"), "worst");
    assert_eq!(Adj::positive("bad3"), "bad");

    // --- Pronouns ---
    assert_eq!(
        English::pronoun(
            &Person::First,
            &Number::Singular,
            &Gender::Neuter,
            &Case::PersonalPossesive
        ),
        "my"
    );
    assert_eq!(
        English::pronoun(
            &Person::First,
            &Number::Singular,
            &Gender::Neuter,
            &Case::Possessive
        ),
        "mine"
    );

    // --- Possessives ---
    assert_eq!(English::add_possessive("dog"), "dog's");
    assert_eq!(English::add_possessive("dogs"), "dogs'");
}
```

---

## 🔧 Crate Overview

This project is organized as a Cargo workspace with all crates under the `crates/` directory:

```
english/
├── Cargo.toml              # Workspace root (virtual manifest)
├── crates/
│   ├── english/            # Main public API crate
│   │   ├── Cargo.toml
│   │   ├── build.rs        # Generates PHF maps from data files at compile time
│   │   ├── src/
│   │   ├── data/           # Pre-generated TSV data files (committed to repo)
│   │   │   ├── adj_data.tsv
│   │   │   ├── noun_data.tsv
│   │   │   └── verb_data.tsv
│   │   └── examples/
│   ├── english-core/       # Core inflection engine (pure algorithmic, no data)
│   │   ├── Cargo.toml
│   │   └── src/
│   └── extractor/          # Dev-only Wiktionary processing tool
│       ├── Cargo.toml
│       └── src/
├── .cargo/
│   └── config.toml         # Cargo aliases (e.g., `cargo xtask`)
├── publish.sh              # Publish script for crates.io
├── build_data.sh           # Full data regeneration script
└── README.md
```

### `english` (`crates/english/`)

> The public API for verb conjugation and noun/adjective declension.

* Combines optimized PHF (Perfect Hash Function) data with inflection logic from `english-core`
* Pure Rust, no external runtime dependencies
* `build.rs` generates PHF lookup maps from TSV data files at compile time
* `O(1)` lookup for irregular forms via `phf::Map`
* Data files ship with the crate — consumers just `cargo add english`

### `english-core` (`crates/english-core/`)

> The core engine for English inflection — pure algorithmic logic.

* Implements the core rules for conjugation/declension
* Used to classify forms as regular or irregular for the extractor
* Has no data dependency — logic-only
* Can be used standalone for an even smaller footprint (at the cost of some accuracy)

### `extractor` (`crates/extractor/`)

> A dev-only tool to process and refine Wiktionary data.

* Parses large English Wiktionary JSONL dumps
* Extracts all verb, noun, and adjective forms
* Uses `english-core` to filter out regular forms, preserving only irregulars
* Generates TSV data files consumed by `english`'s `build.rs`

---

## 🏗️ Building from Source

### Prerequisites

* [Rust](https://www.rust-lang.org/tools/install) (edition 2024, MSRV 1.85+)

### Quick Start (just build and test)

The pre-generated data files are committed to the repo, so you can build immediately:

```bash
# Clone the repo
git clone https://github.com/gold-silver-copper/english.git
cd english

# Build the entire workspace
cargo build --workspace

# Run all tests (including doctests)
cargo test --workspace

# Run the benchmark example
cargo run --example speedmark -p english --release

# Build documentation
cargo doc --workspace --no-deps --open
```

### Full Data Regeneration (optional)

If you want to regenerate the inflection data from a fresh Wiktionary dump, use the provided `build_data.sh` script or follow the manual steps below.

#### Using the build script

```bash
# Download Wiktionary data, run extractor, regenerate TSV files, build and test
./build_data.sh
```

#### Manual steps

1. **Download the raw Wiktextract JSONL dump** (~20 GB) from [Kaikki.org](https://kaikki.org/dictionary/rawdata.html):
   ```bash
   wget -O rawwiki.jsonl.bz2 "https://kaikki.org/dictionary/raw-wiktextract-data.jsonl.bz2"
   bunzip2 rawwiki.jsonl.bz2
   ```
   Or download it directly from the website if the URL has changed.

2. **Run the extractor** to process the dump and generate new data files:
   ```bash
   cargo xtask rawwiki.jsonl
   # This is an alias for: cargo run --package extractor --release -- rawwiki.jsonl
   ```

3. **Rebuild the workspace** — `build.rs` will pick up the updated TSV files:
   ```bash
   cargo build --workspace
   ```

4. **Run tests** to verify everything still works:
   ```bash
   cargo test --workspace
   ```

### Project Links

- [Wiktextract (GitHub)](https://github.com/tatuylonen/wiktextract) — the tool that produces the JSONL dumps
- [Kaikki.org raw data](https://kaikki.org/dictionary/rawdata.html) — pre-built JSONL dumps
- Current version built with data from 8/17/2025

---

## Benchmarks
Performance benchmarks were run on an M2 Macbook.

Writing benchmarks and tests for such a project is rather difficult and requires opinionated decisions. Many words may have alternative inflections, and the data in Wiktionary is not perfect. Many words might be both countable and uncountable, the tagging of words may be inconsistent. This library includes a few uncountable words in its dataset, but not all. Uncountable words require special handling anyway. Take all benchmarks with a grain of salt, write your own tests for your own use cases. Any suggestions to improve the benchmarking are highly appreciated.

## Disclaimer
Wiktionary data is often unstable and subject to unexpected changes. This means that the provided inflections may change across data updates. You can look at the diffs of the TSV data files in `crates/english/data/` for a source of truth.

## Inspirations and Thanks
- Ole in the bevy discord suggested I use `phf` instead of sorted arrays, this resulted in up to 40% speedups
- https://github.com/atteo/evo-inflector
- https://github.com/plurals/pluralize


## 📄 License

- Code: Dual licensed under MIT and Apache © 2024 [gold-silver-copper](https://github.com/gold-silver-copper)
  - [MIT](https://opensource.org/licenses/MIT)
  - [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)

- Data: Wiktionary content is dual-licensed under
  - [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
  - [GNU FDL](https://www.gnu.org/licenses/fdl-1.3.html)
