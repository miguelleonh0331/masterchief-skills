---
name: optimus
description: Controla RTK por proyecto, Ultracave y Ponytail full cuando el usuario pide encender, apagar o consultar Optimus. Reconoce también "enciente skill optimus". No activar por tareas de programación genéricas.
---

# Optimus

Skill personal. Activación por proyecto mediante instrucciones al agente; no intercepta terminales ni instala hooks. Leer este archivo para consultar estado o apagar NO activa ningún modo.

## Control

Usar `/opt/codex-web/.venv-zynertools/bin/python "/opt/codex-web/skills/optimus/scripts/optimus.py" <on|off|status|gain> --project "<directorio del proyecto>"`. El script encuentra la raíz por el `.git` más cercano (incluye worktrees); fuera de Git usa el directorio indicado. Estado persistido fuera del repositorio, independiente de variables de una terminal.

- **Enciende/activa/enciente skill optimus**, `$optimus on`: ejecutar `on`. Tras éxito, leer `../ultracave/SKILL.md` y `../ponytail/SKILL.md` relativos a esta skill. Aplicar Ultracave y Ponytail **full** durante la sesión para este proyecto. La activación explícita de Optimus autoriza cargar ambos modos. Confirmar RTK **guiado por instrucciones**, no automático mediante hooks.
- **Apaga/desactiva skill optimus**, `$optimus off`: ejecutar `off`; cancelar inmediatamente los modos persistentes Ultracave/Caveman y Ponytail activados por Optimus. No desinstalar nada. Si falla la escritura, dejar de aplicar los modos en esta sesión y reportar el fallo del estado persistente.
- **Estado optimus**, `$optimus status`: ejecutar `status`, informar estado del proyecto y que la cobertura RTK es guiada por el agente. No cargar ni activar las otras skills.
- **Ahorro optimus**, `$optimus gain`: ejecutar `gain`. No activar modos. Las métricas RTK son estimaciones de salida, no de factura total.
- `$optimus` sin acción: consultar estado y mostrar las acciones disponibles; no asumir encendido.

Antes de cada lote de comandos y al retomar tras compactación, consultar `status` para el directorio donde se ejecutarán. Si está apagado, suspender los tres modos. En un proyecto distinto, no heredar el encendido ni escribir su estado. Un estado encendido permite retomar RTK allí; para restaurar estilos en una sesión nueva, cargar Optimus y sus skills hermanas. Un nuevo agente no descubre automáticamente este estado: debe invocarse Optimus o recibir estas instrucciones.

Si una dependencia falta, reportarla sin instalarla silenciosamente. Si RTK falla, usar comandos normales e informar la degradación. Las instrucciones del usuario y del proyecto prevalecen sobre los estilos.

## RTK cuando está encendido

- Ejecutar explícitamente comandos RTK compatibles para salidas que leerá el agente: por ejemplo `rtk git status`, `rtk git diff`, `rtk git log -n 10`, `rtk grep "patrón" ruta`, y runners de pruebas compatibles. Conservar argumentos, directorio, códigos de salida y alcance. Comprobar `--help` si el mapeo no es conocido; no anteponer `rtk` indiscriminadamente a PowerShell, pipelines o comandos arbitrarios.
- Consultar resúmenes para explorar. Antes de editar o revisar, leer completas las partes relevantes del código y del diff. No interpretar ausencia en una salida truncada como ausencia real.
- Usar comandos originales para JSON, salida consumida por scripts, conteos exactos, inventarios exhaustivos y comandos sin filtro compatible. No comprimir código, instrucciones del proyecto ni contratos cuya lectura completa sea necesaria.
- Depuración: `rtk recall <hash> --full` recupera salida conservada; `--from`, `--lines` o `--grep` permiten consultar partes. La recuperación no está garantizada para cada ejecución. Si falta, repetir sin RTK solo cuando sea seguro. Nunca repetir operaciones con efectos secundarios para recuperar salida. `rtk proxy <comando> ...` devuelve salida sin filtro y registra uso; estando apagado, usar directamente el comando original.
- No usar `--skip-env`, omitir validaciones ni reducir pruebas por ahorro. RTK cambia presentación, no autorizaciones ni criterio de éxito.
- El helper `gain` ejecuta `rtk gain --project` desde la raíz. Esto filtra estadísticas por directorio; ejecuciones desde subdirectorios pueden contabilizarse aparte. No afirmar ahorro exacto de todo el árbol sin comprobarlo.

## Estilos y límites

Ultracave comprime respuestas, no detalles técnicos necesarios; documentos, código y preguntas conservan claridad. Ponytail full busca el cambio mínimo que resuelve toda la tarea. Cuando apagar Optimus, dejar de aplicar ambos aunque sus instrucciones indiquen persistencia. Una invocación posterior explícita de una skill independiente sigue la nueva instrucción del usuario.

## Instalación y reversión

Requiere Python 3, RTK y las skills hermanas `ultracave` y `ponytail`. Windows: el helper también busca RTK en el enlace estándar de WinGet si el PATH del proceso aún no se actualizó.

Esta skill no cambia código, dependencias, `AGENTS.md`, perfiles de terminal ni configuración de agentes. No ejecutar `rtk init -g`. Para hooks automáticos, tratarlo como una tarea adicional: verificar versión, esquema, confianza y configuración local de cada agente; revisar primero `rtk init --dry-run` y probar encendido/apagado con aislamiento. No afirmar que Codex y Claude usan la misma configuración.

Para revertir: apagar Optimus, eliminar esta carpeta de skill y opcionalmente sus registros de estado (ruta indicada por `status`; por defecto `LOCALAPPDATA/Optimus/projects` en Windows o `~/.local/state/optimus/projects`). Conservar RTK y las otras skills salvo petición expresa de desinstalación.

Fuentes: [RTK](https://github.com/rtk-ai/rtk), [hooks Codex](https://learn.chatgpt.com/docs/hooks). Los mecanismos automáticos no se han configurado con esta skill.
