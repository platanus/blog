---
layout: post
title: "(in)decisiones en Platanus"
author: agustinf
tags:
  - process
---

En nuestro trabajo es frecuente toparnos con encrucijadas y nos ocurre frecuentemente el problema que se conoce como “analysis paralysis”. Nos enfrentamos a escoger entre dos herramientas similares, cada una con ciertas ventajas por sobre la otra. Por buscar tomar la mejor decisión, dedicamos nuestro tiempo a evaluar las opciones. Cuando hay una opción claramente mejor que la otra es muy fácil, pero cuando las alternativas son muy similares en cuanto a costo y beneficio, tomar una decisión se nos hace más dificil. La paradoja está en que es justamente en esas decisiones difíciles donde, dada la similitud entre las alternativas, menos importa qué opción tomemos. Más tarde, una vez que el tiempo se nos fue entre la manos, casi en su totalidad dedicado a evaluar una decisión, podemos ver claramente en retrospectiva: lo mejor habría sido lanzar una moneda al aire y seguir adelante con cualquiera de las opciones.

En Platanus invertimos una buena parte de nuestro tiempo intentando tomar decisiones de antemano y definir estándares para nuestro trabajo, precisamente para que las encrucijadas no interrumpan después nuestro trabajo. No es una tarea fácil, toma mucho tiempo y es fácil que una larga discusión quede finalmente en nada. Algo que sí hemos llegado a acordar, es que precisamente el tener acuerdos, convenciones, estándares y maneras explícitas de hacer las cosas nos ayuda a ser más eficientes y felices. No queremos hundirnos en estas discusiones bizantinas cada vez que queremos hacer algo.

Con ese objetivo en mente, nos hemos propuesto construir una guía de desarrollo, en otras palabras, dejar por escrito nuestro estilo y nuestras decisiones. La idea es que más tarde, cuando por ejemplo tengamos la duda de si usar Bourbon o Bootstrap, podamos remitirnos a “la Guia”, como una especie de libro de mandamientos, y ahorrarnos un largo proceso de evaluación y ponderación de argumentos.

Si bien estamos convencidos de que construir esta guía tiene valor, el proceso que seguimos para definir nuestros “estándares” aún tiene sus defectos. Quizás el principal defecto es que ponernos de acuerdo como equipo nos toma muchísimo tiempo, algunos toman posturas extremas y muchas veces caemos en discusiones eternas, que cuesta cerrar. Además de la poca eficiencia lograda hay dos problemas que se desprenden de este proceso defectuoso:

1. **Perdemos flexibilidad.** Cuando el camino hasta lograr una decisión es muy doloroso, una vez que tenemos la decisión tomada, es poco probable que queramos volver a recorrer el camino y repensar la decisión. Claramente hay un balance en esto, pues algo de bueno hay en que no repensemos todo todos los días.

2. **No tomamos todas las decisiones que debiéramos estar tomando.** Nuevamente, al tratarse de un camino tortuoso, es fácil optar por el silencio, que es cláramente la peor opción en términos de resultados. Postergamos las decisiones porque no queremos pasar por el sufrimiento de discutirlas.

Ahora bien, para resolver el problema, lo mejor sería entender por qué se genera. Tengo que aclarar que en ningún caso creo que la dificultad para lograr acuerdos sea un defecto del equipo o de sus miembros, sino más bien del proceso. Creo que el aspecto tortuoso de las discusiones en Platanus se da porque:

1. **La comunicación siempre es dificil:** incluso una sola mente humana tiene dificultades para ponerse de acuerdo consigo mismo. El hecho que no todos tengamos las mismas vivencias, recuerdos y conceptos en la mente hace que sea extraordinariamente dificil llegar a consenso.
2. **Tomar decisiones entre varios requiere habilidades de moderación:** No todos somos moderadores innatos, y con moderador me refiero a alguien que puede tomar en cuenta las opiniones pero es también capaz de zanjar. Al mismo tiempo, los que sí tienen habilidades de moderación, no necesariamente tienen conocimiento en todos los temas, por lo que se hace imposible que puedan tomar ese rol.

Estos problemas son tan reales y permanentes en los seres humanos, que pienso que hay que aplicar una filosofía judo, es decir, esquivarlos sin enfrentarlos directamente. Podríamos perder muchísimo tiempo intentando mejorar nuestras habilidades de comunicación y moderación sin resultados relevantes. Hay mejores alternativas.

En el mundo Open Source hay mucho de lo que podemos aprender. Teniendo claro el valor de “alguna decisión” por sobre “la mejor decisión”, muchos de los “estándares” que conocemos son en realidad guías opinionadas, donde el autor reconoce no estar necesariamente tomando la mejor decisión, pero sí una que le gusta. El autor no organizó un comité con muchos expertos para determinar la verdad, sino que describió directamente lo que opinaba él a partir de su experiencia. Las decisiones en una guía opinionada, aunque muy determinantes, no son permanentes y son fácilmente reversibles. Es lo que nos enseña Rails, con su “convention over configuration”. Rails es un framework con una opinión muy fuerte, pueden existir muchos argumentos en contra de las formas en que Rails hace lo que hace, pero el hecho que la comunidad Rails decida por nosotros algunas cosas ya nos entrega mucho valor y nos libera de muchas (in)decisiones.

Por eso propongo:

1. Que entendamos nuestra guía como una **colección de opiniones**. Solo basta con cuidar que esta colección sea consistente: ninguna opinión debiera contradecirse con otra, pero definitivamente no necesitamos que todas las opiniones estén en “lo correcto” desde el principio.
2. Las opiniones de la guía debieran tener un **autor** y las discusiones grupales de Trello las debiéramos centrar en **votar y discutir quién debe ser el autor** de un determinado tema.

Creo que si concentramos la labor del grupo sólo en definir a los autores de cada tema y cuidar que no hayan contradicciones, podemos dejar el tiempo de los miembros para que se preocupen más de su rol de autores y puedan así invertir su tiempo en definir y escribir su opinión en lugar de gastárselo en la elaboración de argumentos que muchas veces se topan con argumentos igualmente válidos del otro lado y nos llevan inequívocamente a la “parálisis del análisis” y la indecisión.







