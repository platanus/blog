---
title: Usando git con archivos pesados
author: Agustin
layout: post
tags:
  - programacion
  - tips
---

Haciendo un juego en IOS me topé con que nuestro ilustrador nos mandaba un montón de archivos Photoshop (PSD) *pesadísimos*, y de a poco empezó a quedar un desastre de carpetas y archivos con distintas versiones, imágenes exportadas en distintas calidades, etc. Poner archivos grandes en Git es una mala idea, porque el tamaño del repositorio crece muy rápido (se guarda cada versión entera, tanto en local como en el repositorio remoto). Entonces encontré [git-annex][1], que ayuda a manejar archivos en git, pero sin poner su contenido en git. Es decir, el repositorio sigue siendo liviano, pero tiene la metadata de los archivos grandes. El contenido del archivo se aloja en otra parte, como por ejemplo [S3][2].

En Mac OSX se puede instalar usando [brew][3]

```bash
brew update
brew install haskell-platform git ossp-uuid md5sha1sum coreutils pcre libgsasl gnutls libidn libgsasl
pkg-config libxml2
brew link libxml2
cabal update
PATH=$HOME/bin:$PATH
cabal install c2hs git-annex --bindir=$HOME/bin
```

[1]: http://git-annex.branchable.com/
[2]: http://aws.amazon.com/s3
[3]: http://mxcl.github.com/homebrew/