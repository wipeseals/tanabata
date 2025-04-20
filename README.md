# tanabata

`tanabata.gleam` は、Gleam 言語の勉強を目的に実装された Brainfuck インタプリタ。

## Structure

- `src/tanabata.gleam`: Brainfuck インタプリタのメインロジックを含むファイル。
- `test/tanabata_test.gleam`: インタプリタのテストケースを含むファイル。
- `misc/`: サンプルの Brainfuck プログラムを含むディレクトリ。

## Getting Started

1. Gleam をインストールします。
2. 以下のコマンドを使用してプロジェクトをビルドおよび実行します。

```sh
# ビルド
gleam build

# 実行
gleam run
```

nix flakes を使用している場合は、以下のコマンドを使用してプロジェクトをビルドおよび実行します。

```sh
direnv allow
```

## Samples

`misc/` ディレクトリには、以下のようなサンプルプログラムが含まれています。
この内容は [Brainfuck のサンプルコード集 - HIRO LAB BLOG](https://hirlab.net/nblog/category/programming/art_1604/) より引用しています。

### `01_hello.bf`: "Hello, World!" を出力

```bash
gleam run

  Compiling tanabata
   Compiled in 0.76s
    Running tanabata.main
src:
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.

stdin:
stdout: Hello World!

vmstat: cmd: , cycle: 986, pc: 106, ptr: 6, ptr_value: 10, stdin: , stdout: Hello World!
, mem: 0, 0, 72, 100, 87, 33, 10
```

### `02_ascii.bf`: ASCII コードを出力

```bash
 gleam run

  Compiling tanabata
   Compiled in 0.75s
    Running tanabata.main
src:
    .+[.+]

stdin:
stdout:


␦123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
vmstat: cmd: , cycle: 1023, pc: 6, ptr: 0, ptr_value: 0, stdin: , stdout:


␦123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ, mem: 0
```

### `03_fizzbuzz.bf`: FizzBuzz

```bash
gleam run

  Compiling tanabata
   Compiled in 0.73s
    Running tanabata.main
src:
++++++[->++++>>+>+>-<<<<<]>[<++++>>+++>++++>>+++>+++++>+++++>>>>>>++>>++<
<<<<<<<<<<<<<-]<++++>+++>-->+++>->>--->++>>>+++++[->++>++<<]<<<<<<<<<<[->
-[>>>>>>>]>[<+++>.>.>>>>..>>>+<]<<<<<-[>>>>]>[<+++++>.>.>..>>>+<]>>>>+<-[
<<<]<[[-<<+>>]>>>+>+<<<<<<[->>+>+>-<<<<]<]>>[[-]<]>[>>>[>.<<.<<<]<[.<<<<]
>]>.<<<<<<<<<<<]

stdin:
stdout: 1
2
Fizz
4
Buzz
...
91
92
Fizz
94
Buzz
Fizz
97
98
Fizz
Buzz

vmstat: cmd: , cycle: 12529, pc: 308, ptr: 0, ptr_value: 0, stdin: , stdout: ...
```

### `04_primenumber.bf`: 素数を出力

```bash
gleam run

  Compiling tanabata
   Compiled in 0.75s
    Running tanabata.main
src:
>++++[<++++++++>-]>++++++++[<++++++>-]<++.<.>+.<.>++.<.>++.<.>------..<.>
.++.<.>--.++++++.<.>------.>+++[<+++>-]<-.<.>-------.+.<.> -.+++++++.<.>
------.--.<.>++.++++.<.>---.---.<.> +++.-.<.>+.+++.<.>--.--.<.> ++.++++.<.>
---.-----.<.>+++++.+.<.>.------.<.> ++++++.----.<.> ++++.++.<.> -.-----.<.>
+++++.+.<.>.--.

stdin:
stdout: 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
vmstat: cmd: , cycle: 439, pc: 304, ptr: 1, ptr_value: 55, stdin: , stdout: 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97, mem: 32, 55, 0
```

## License

このプロジェクトは MIT ライセンスの下で配布されています。詳細は [LICENSE](/LICENSE) ファイルを参照してください。
