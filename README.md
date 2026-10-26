
## Overview

studiomdl-sven-crossplatfrom compiles [Studio Model Data][SMD] from [QC files][QC] to a [model file][MDL].

This is a cross-platform compatible version of [studiomdl][studiomdl_wiki] for Half-Life (GoldSrc).
It uses some stuff from [sven-studiomdl](https://the303.org/backups/sven_studiomdl_2019.rar), reimplemented cleaner because i don't want to add mess to this already messed up compiler (no offense, original author, i meant valve's mess)

## Prerequestites

- `gcc` or `clang`

## Installing & Building

Clone this project.

```sh
git clone https://github.com/fnky/studiomdl.git
cd studiomdl
```

```sh
make
make install # optional
```

You can set architecture (default `-m32`), compiler (default `gcc`) and install path (default `/usr/local/bin`) as well as user flags for custom C flags.


```sh
make CC=clang ARCH=-m64 INSTALL_PATH=/usr/bin USER_FLAGS="-O3 -march=native"
```

The source tables (`MAXSTUDIOSEQUENCES`, `MAXSTUDIOANIMATIONS`, `MAXSTUDIOVERTS`,
`MAXSTUDIOTRIANGLES`) can be raised without editing the source, e.g.
`make USER_FLAGS=-DMAXSTUDIOSEQUENCES=1024`, at the cost of a bigger static binary.

> **Note:** 64-bit build currently doesn't work, due to structs not using compatible data types.

## Usage

```sh
studiomdl [options] <QC file>
```

#### Options

<dl>
  <dt><code>-t</code></dt>
  <dd>texture</dd>

  <dt><code>-r</code></dt>
  <dd>tag reversed</dd>

  <dt><code>-n</code></dt>
  <dd>tag bad normals</dd>

  <dt><code>-f</code></dt>
  <dd>flip all triangles</dd>

  <dt><code>-a</code></dt>
  <dd>normal blend angle</dd>

  <dt><code>-h</code></dt>
  <dd>dump hboxes</dd>

  <dt><code>-i</code></dt>
  <dd>ignore warnings</dd>

  <dt><code>-k</code></dt>
  <dd>keep unused bones (`-b` is accepted as an alias of it)</dd>

  <dt><code>-g size</code></dt>
  <dd>max sequencegroup size</dd>
</dl>

> Note: Your QC and SMD files has to use `LF` (Unix) line-endings in order to work.

### Sven Co-op extensions


<dl>
  <dt><code>$keepbone "&lt;bone&gt;"</code> / <code>$protected "&lt;bone&gt;"</code></dt>
  <dd>keep a bone that no vertex references. Both spellings are the same command, and the
  name is matched against the original SMD name, i.e. before <code>$renamebone</code> is
  applied</dd>

  <dt><code>$keepallbones</code> / <code>-k</code></dt>
  <dd>keep every bone the source files declare (up to 128 bones in the compiled model)</dd>

  <dt><code>$texrendermode "&lt;texture&gt;" &lt;mode&gt;</code></dt>
  <dd>one of <code>additive</code>, <code>masked</code>, <code>fullbright</code>,
  <code>nomips</code>, <code>flatshade</code>, <code>alpha</code> or <code>chrome</code></dd>
</dl>

Textures up to 1024×1024 are accepted. Anything above 640×480 still compiles but it prints
  ```
  NOTE: Texture too large for vanilla GoldSrc.
  ```
  so the same model can target Sven Co-op
  and vanilla GoldSrc from one source.

`-p`, `-2` (force power-of-two textures) were dropped.

`$cliptotextures` is still *implemented* here (StudioMDL SC dropped it and only warns), so
existing QCs keep working.

## Contribute

See the [guidelines for contributing][].

## License

[Half Life 1 SDK LICENSE](LICENSE)

[SMD]: https://developer.valvesoftware.com/wiki/Studio_Model_Data
[QC]: https://developer.valvesoftware.com/wiki/QC
[MDL]: https://developer.valvesoftware.com/wiki/Model
[studiomdl_wiki]: https://developer.valvesoftware.com/wiki/Studiomdl
[guidelines for contributing]: https://github.com/fnky/studiomdl/blob/master/CONTRIBUTING.md
[studiomdl_banner]: https://raw.githubusercontent.com/fnky/studiomdl/master/img/banner.png
