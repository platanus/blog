---
title: Cómo lograr que Eclipse reconozca el Android conectado al USB
author: Agustin
layout: post
categories:
    - android
    - eclipse
---

El SDK de Android trae el programita `adb` entre sus utilidades. Es el servidor de debug.  Con `adb kill-server` lo matas y con `adb devices` lo prendes y buscas dispositivos.

Pasé un buen rato intentándolo con mi teléfono y mi Mac, hasta que descubrí que Easy Tether, una extensión que instalé hace mucho tiempo, estaba provocando un problema, así que con `sudo kextunload` `/System/Library/Extensions/EasyTetherUSBEthernet.kext` se acabó el problema.