# masterchief-skills

Skills para los agentes de Claude Code de codex-web-v4: `optimus`,
`ultracave` y `ponytail`.

## Por que un repositorio

Las skills son ficheros sueltos: no vienen de ningun paquete ni se instalan
con un gestor. Tenerlas aqui las deja versionadas, permite actualizarlas en
todos los servidores con un `git pull`, y mantiene las instrucciones junto a
los ficheros en vez de en un mensaje que se pierde.

## Como las encuentra Claude

Claude Code busca las skills en `<directorio de trabajo>/.claude/skills`. En
codex-web-v4 el directorio de trabajo de cada especialista es su propio
workspace, bajo `/var/lib/codex-web-v4/agents/<id>/workspace`, que nace
vacio. Por eso instalar no basta: hay que enlazar.

El instalador deja **una sola copia** en una carpeta compartida y pone un
**enlace** en cada workspace:

```text
/opt/codex-web-v4/skills/                     una copia
   optimus/  ultracave/  ponytail/

/var/lib/codex-web-v4/agents/<id>/workspace/.claude/skills -> /opt/codex-web-v4/skills
```

Enlaces y no copias: al corregir una skill se corrige para todos a la vez.
Con copias acabarias con versiones distintas sin enterarte.

## Instalacion

```bash
git clone https://github.com/<usuario>/masterchief-skills.git /opt/masterchief-skills
cd /opt/masterchief-skills
sudo ./install.sh --rtk /ruta/al/binario/rtk
```

Opciones:

| Opcion | Para que | Por defecto |
|---|---|---|
| `--dest` | donde viven las skills | `/opt/codex-web-v4/skills` |
| `--agents-dir` | donde estan los workspaces | `/var/lib/codex-web-v4/agents` |
| `--user` | usuario del servicio | `codex-web` |
| `--rtk` | binario de RTK a instalar en `/usr/local/bin` | no instala |
| `--python` | interprete para el helper de optimus | el `python3` del PATH |

## RTK

`optimus` usa [RTK](https://github.com/rtk-ai/rtk) para filtrar salidas antes
de que lleguen al modelo. Es un **binario independiente**, no un paquete de
pip, y por su tamaño no se versiona aqui. Pasalo con `--rtk`; sin el, la
skill se instala igual pero pierde su razon de ser.

El instalador lo deja en `/usr/local/bin/rtk` para que este disponible en
todo el sistema, no solo dentro de un entorno virtual.

## Rutas dentro de optimus

`optimus/SKILL.md` lleva escritas las rutas del servidor donde nacio. El
instalador las reescribe a las de la maquina donde se ejecuta. Si editas ese
fichero a mano, respeta ese detalle o el helper no se encontrara a si mismo.

## Limitacion conocida

Los especialistas creados **despues** de instalar nacen sin el enlace,
porque codex-web-v4 crea el workspace vacio. Vuelve a ejecutar el
instalador, o enlaza a mano:

```bash
ln -sfn /opt/codex-web-v4/skills /var/lib/codex-web-v4/agents/<id>/workspace/.claude/skills
```

## Que NO va aqui

Este repositorio es para skills genericas. Las que describen la arquitectura
interna de un sistema concreto —las `zynervox_*`— no deben publicarse en un
repositorio abierto.

No guardes aqui llaves, contraseñas ni inventarios de servidores.
