#!/bin/bash

# Environment passed:
# BENCH_EXEC_PATH: the benchmark executable
# RTS_OPTIONS: additional RTS options
# QUICK_MODE: whether we are in quick mode

#------------------------------------------------------------------------------
# RTS Options
#------------------------------------------------------------------------------

# RTS options based on the benchmark executable
bench_exe_rts_opts () {
  case "$1" in
    Prelude.Concurrent*) echo -n "-K256K -M384M" ;;
    *) echo -n "" ;;
  esac
}

# General RTS options for different classes of benchmarks
bench_rts_opts_default () {
  case "$1" in
    */o-1-sp*) echo -n "-K36K -M16M" ;;
    */o-n-h*) echo -n "-K36K -M32M" ;;
    */o-n-st*) echo -n "-K1M -M16M" ;;
    */o-n-sp*) echo -n "-K1M -M32M" ;;
    *) echo -n "" ;;
  esac
}

# Overrides for specific benchmarks
bench_rts_opts_specific () {
  case "$1" in
    Prelude.Parallel/o-n-heap/mapping/mapM) echo -n "-M256M" ;;
    #Prelude.Parallel/o-n-heap/monad-outer-product/toList) echo -n "-K-M256M" ;;
    Prelude.Parallel/o-n-heap/monad-outer-product/*) echo -n "-M256M" ;;
    Prelude.Parallel/o-n-space/monad-outer-product/*) echo -n "-K4M -M256M" ;;
    Prelude.Serial/o-n-space/grouping/*) echo -n "" ;;
    Prelude.Serial/o-n-space/*) echo -n "-K4M" ;;
    Prelude.WSerial/o-n-space/*) echo -n "-K4M" ;;

    Prelude.Async/o-n-space/monad-outer-product/*) echo -n "-K4M" ;;
    Prelude.Ahead/o-n-space/monad-outer-product/*) echo -n "-K4M" ;;

    Prelude.WAsync/o-n-heap/monad-outer-product/toNull3) echo -n "-M64M" ;;
    Prelude.WAsync/o-n-space/monad-outer-product/*) echo -n "-K4M" ;;

    # XXX need to investigate these, taking too much stack
    Data.Parser.ParserD/o-1-space/some) echo -n "-K1M" ;;
    Data.Parser/o-1-space/some) echo -n "-K1M" ;;
    Data.Parser.ParserD/o-1-space/manyTill) echo -n "-K4M" ;;
    Data.Parser/o-1-space/manyTill) echo -n "-K4M" ;;

    Data.SmallArray/o-1-sp*) echo -n "-K128K" ;;
    *) echo -n "" ;;
  esac
}

#------------------------------------------------------------------------------
# Speed options
#------------------------------------------------------------------------------

if test "$QUICK_MODE" -eq 0
then
QUICK_OPTIONS="--min-samples 3"
fi
SUPER_QUICK_OPTIONS="--min-samples 1 --include-first-iter"

bench_exe_quick_opts () {
  case "$1" in
    Prelude.Concurrent) echo -n "$SUPER_QUICK_OPTIONS" ;;
    Prelude.Rate) echo -n "$SUPER_QUICK_OPTIONS" ;;
    Prelude.Adaptive) echo -n "$SUPER_QUICK_OPTIONS" ;;
    fileio) echo -n "$SUPER_QUICK_OPTIONS" ;;
    *) echo -n "" ;;
  esac
}

# Use quick options for benchmarks that take too long
bench_quick_opts () {
  case "$1" in
    Prelude.Parallel/o-n-heap/mapping/mapM)
        echo -n "$SUPER_QUICK_OPTIONS" ;;
    Prelude.Parallel/o-n-heap/monad-outer-product/*)
        echo -n "$SUPER_QUICK_OPTIONS" ;;
    Prelude.Parallel/o-n-space/monad-outer-product/*)
        echo -n "$SUPER_QUICK_OPTIONS" ;;
    Prelude.Parallel/o-n-heap/generation/*) echo -n "$QUICK_OPTIONS" ;;
    Prelude.Parallel/o-n-heap/mapping/*) echo -n "$QUICK_OPTIONS" ;;
    Prelude.Parallel/o-n-heap/concat-foldable/*) echo -n "$QUICK_OPTIONS" ;;

    Prelude.Async/o-1-space/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;
    Prelude.Async/o-n-space/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;

    Prelude.Ahead/o-1-space/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;
    Prelude.Ahead/o-n-space/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;

    Prelude.WAsync/o-n-heap/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;
    Prelude.WAsync/o-n-space/monad-outer-product/*) echo -n "$QUICK_OPTIONS" ;;
    *) echo -n "" ;;
  esac
}

last=""
for i in "$@"
do
    BENCH_NAME="$last"
    last="$i"
done

RTS_OPTIONS=\
"+RTS -T \
$(bench_exe_rts_opts $(basename $BENCH_EXEC_PATH)) \
$(bench_rts_opts_default $BENCH_NAME) \
$(bench_rts_opts_specific $BENCH_NAME) \
$RTS_OPTIONS \
-RTS"

QUICK_BENCH_OPTIONS="\
$(bench_exe_quick_opts $(basename $BENCH_EXEC_PATH)) \
$(bench_quick_opts $BENCH_NAME)"

if test -n "$STREAM_SIZE"
then
  STREAM_LEN=$(env LC_ALL=en_US.UTF-8 printf "\--stream-size %'.f\n" $STREAM_SIZE)
fi

echo "$BENCH_NAME: \
$STREAM_LEN \
$QUICK_BENCH_OPTIONS \
$RTS_OPTIONS"

$BENCH_EXEC_PATH $RTS_OPTIONS "$@" $QUICK_BENCH_OPTIONS
