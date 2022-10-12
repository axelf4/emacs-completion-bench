# Emacs fuzzy completion style benchmark

This is a benchmark intended for measuring the relative performance
of a set of fuzzy completions styles for Emacs.

The styles included in this benchmark are

* The builtin `basic` style.
  
  Not fuzzy in the slightest. Implemented in C. Only included as a baseline.
* The builtin `flex` style.
  
  "Greedy" fuzzy algorithm in Emacs Lisp.
* [`hotfuzz`][hotfuzz] with its dynamic module loaded.

  Unlike with other dynamic modules
  that are consulted *for each* individual each candidate to compute its score,
  the Hotfuzz Lisp code only calls out to the native code once,
  passing along the entire completions list.
  This reduces overhead and enables multithreaded filtering and scoring.
* [`fussy`][fussy]

  Fussy is generic over different scoring backends,
  the following of which are benchmarked:
  
  - [flx], an Emacs Lisp library for fuzzy matching
  - [fzf-native] which is a dynamic module implementing the [fzf] algorithm
  - [fuz], a dynamic module implementing skim's algorithm (or clangd's!)
  - [hotfuzz] which calls into the Emacs Lisp implementation of
    the Hotfuzz scoring algorithm
  
  The [flx-rs], [LiquidMetal] and [sublime_fuzzy] backends had to be excluded
  due to them erroring out on the benchmark input.
  
  To make timings comparable to other the styles,
  the following options were set
  
  - `fussy-use-cache` to `nil`,
    since the benchmark tries completing with the same input many times
  - `fussy-filter-fn` to `#'fussy-filter-default` since it is faster than the current default
  - `fussy-compare-same-score-fn` to `nil`, and
  - `fussy-score-threshold-to-filter-alist` to `nil` 
    both since other styles do not implement this
* [`orderless`][orderless]
  
  Not fuzzy, but somewhat interesting to include
  just for reference given its popularity.
  
The benchmark consists of completing against a list of candidate completions
of length 95653, with the median length of each string being 37.
The search strings are of length between one and ten.

Case-insensitive matching is used,
i.e. `completion-ignore-case` is set to `t`.

To reproduce,
compile the Hotfuzz dynamic module as instructed in its README
and place the resulting dynamic library in this directory.
The other dynamic module packages ship precompiled binaries.
Then run
```sh
./runbench
```
in a shell from within this directory.

## Results

Running the benchmark on a Lenovo ThinkPad T450 in Emacs 28.1
the resulting times were

| Style                |      Time (s) | #GC |        GC time (s) |    Rel |
|----------------------|--------------:|----:|-------------------:|-------:|
| `basic`              |   0.264177651 |   0 |                0.0 |   0.39 |
| `hotfuzz`            |   0.675077483 |   0 |                0.0 |      1 |
| `flex`               |  10.659162948 |   9 | 1.1566389280000005 |  15.78 |
| `fussy`/`flx`        |  20.459863556 |  51 |       11.053008226 |  30.31 |
| `fussy`/`fzf-native` | 114.452248804 | 392 |       90.741769522 | 169.54 |
| `fussy`/`fuz`        |   4.799709416 |   9 | 2.1221384660000098 |   7.11 |
| `fussy`/`hotfuzz`    |  41.835871034 |   8 | 1.8608007069999957 |  61.97 |
| `orderless`          |   1.652139614 |   3 | 0.6919645190000097 |   2.45 |

where the "Rel" column indicates the relative slowdown factor
compared to the fastest sorting fuzzy style.

## Conclusion

Something seems to have gone wrong with `fzf-native`.

Hotfuzz is pretty fast.

[hotfuzz]:https://github.com/axelf4/hotfuzz
[fussy]: https://github.com/jojojames/fussy
[flx]: https://github.com/lewang/flx
[flx-rs]: https://github.com/jcs-elpa/flx-rs
[fzf-native]: https://github.com/dangduc/fzf-native
[fzf]: https://github.com/junegunn/fzf
[fuz]: https://github.com/rustify-emacs/fuz.el
[LiquidMetal]: https://github.com/rmm5t/liquidmetal
[sublime_fuzzy]: https://github.com/Schlechtwetterfront/fuzzy-rs
[orderless]: https://github.com/oantolin/orderless
