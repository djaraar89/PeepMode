---
trigger: always_on
---

# PeepMode — Seguridad permanente

Este workspace corresponde al repositorio de PeepMode ubicado en:

`C:/GitHub/PeepMode`

La base funcional del proyecto es:

`https://github.com/Kelzorz/PeepMode`

La configuración puede contener actualmente:

* `origin` → `https://github.com/Kelzorz/PeepMode.git`
* `upstream` → `https://github.com/ktilkath/PeepMode.git`

Esto no debe considerarse automáticamente un error.

No modificar, eliminar, renombrar ni agregar remotos sin autorización explícita.

## Protección Git

Nunca modificar archivos directamente en las ramas:

* `master`
* `main`

Antes de modificar cualquier archivo, comprobar:

* ruta del repositorio;
* rama activa;
* commit `HEAD`;
* estado de Git;
* objetivo del cambio;
* archivos que se modificarán.

Si la rama activa es `master` o `main`, detenerse sin modificar archivos.

No ejecutar sin autorización explícita:

* `git reset --hard`
* `git clean`
* `git restore`
* `git checkout --`
* `git rebase`
* `git push`
* `git push --force`
* eliminación de ramas;
* descarte de cambios;
* reescritura del historial;
* modificación de remotos.

No hacer commits salvo que el prompt actual lo autorice expresamente.

## Método de trabajo

Trabajar con un solo cambio atómico a la vez.

Para cada cambio:

1. Inspeccionar el estado inicial.
2. Confirmar rama, `HEAD` y estado de Git.
3. Explicar el objetivo.
4. Enumerar los archivos que se modificarán.
5. Aplicar únicamente el cambio autorizado.
6. Revisar el diff.
7. Ejecutar las validaciones disponibles.
8. Registrar el resultado.
9. Informar los archivos afectados y riesgos pendientes.

No declarar éxito sin evidencia verificable.

## Protección de mapas de StarCraft II

Trabajar solamente en un mapa a la vez.

El primer mapa piloto será:

`Blackrock`

No modificar simultáneamente todos los mapas de la rotación.

No realizar reemplazos masivos en carpetas `.SC2Map`.

No asumir que dos mapas poseen una estructura idéntica.

Antes de abrir o guardar un mapa con el Editor de StarCraft II:

1. confirmar que la rama activa no sea `master` ni `main`;
2. comprobar `git status`;
3. registrar el estado anterior.

Después de guardar con el Editor:

1. comprobar nuevamente `git status`;
2. inventariar todos los archivos modificados;
3. distinguir cambios esperados e inesperados;
4. revisar el diff antes de hacer commit.

## Registros acumulativos

El proyecto deberá mantener:

* `docs/WORKLOG.md`
* `CHANGELOG.md`
* `docs/DECISIONS.md`

Estos registros son **append-only**.

Las entradas nuevas solo pueden agregarse al final.

Está prohibido:

* borrar entradas anteriores;
* reemplazar un registro completo;
* regenerarlo desde cero;
* resumir o condensar su historial;
* modificar silenciosamente entradas antiguas;
* reorganizar entradas;
* eliminar intentos fallidos;
* conservar solamente la entrada más reciente.

Si una entrada anterior contiene un error, agregar una nueva corrección al final. No modificar la entrada original.

Después de actualizar un registro, revisar su diff.

El diff debe mostrar exclusivamente líneas nuevas agregadas al final. Si muestra contenido histórico eliminado, modificado o reordenado, detenerse y no hacer commit.

## Finalización

Después de cada tarea, informar:

* rama activa;
* commit base;
* objetivo;
* archivos modificados;
* validaciones realizadas;
* resultado;
* registros actualizados;
* riesgos pendientes;
* mensaje de commit sugerido.

Finalizar con uno de estos estados:

* `CAMBIO VALIDADO Y REGISTRADO`
* `CAMBIO PARCIALMENTE VALIDADO Y REGISTRADO`
* `INTENTO FALLIDO Y REGISTRADO`
* `DETENIDO ANTES DE MODIFICAR`
* `DETENIDO POR ALTERACIÓN DEL HISTORIAL`
