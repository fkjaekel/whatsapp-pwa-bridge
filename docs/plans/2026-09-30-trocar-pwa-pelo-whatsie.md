# Trocar o PWA do WhatsApp Web pelo whatsie

Criado em 2026-09-30 · máquina `spdata-arq-felipe` (Cinnamon/X11) · execução em `sonnet / medium`

## Objetivo

O WhatsApp passa a ter ícone na bandeja do Cinnamon, com contador de não lidas. Fechar a janela
esconde o app em vez de encerrá-lo, ele sobe sozinho no login e os links `whatsapp://` do Chrome
abrem nele. O PWA do Chrome sai, junto com as peças deste repo, que só existiam para atender o PWA.

Goal: `xdg-mime query default x-scheme-handler/whatsapp` devolve `com.ktechpit.whatsie.desktop`, o
whatsie roda na bandeja com o PWA desinstalado e `systemctl --user is-active whatsapp-bridge.service`
continua `active`.

## Por que o whatsie

- O Chrome no Linux não dá ícone de bandeja a PWA, então manter o PWA não resolve.
- O whatsie está na versão 6.1.1 no Flathub (`com.ktechpit.whatsie`, publicada em 22/09/2026) e é
  mantido. O ZapZap 7.4.5 (`com.rtosta.zapzap`) seria a alternativa equivalente.
- O `.desktop` dele declara `MimeType=x-scheme-handler/whatsapp;` com `Exec=whatsie %u`, e a CLI
  aceita `whatsapp://` e wa.me como argumento. Isso substitui o handler deste repo.
- O sandbox tem `--talk-name=org.kde.StatusNotifierWatcher`, que o `xapp-sn-watcher` do Cinnamon
  atende. Os applets `systray@cinnamon.org` e `xapp-status@cinnamon.org` já estão no painel.

## Estado atual (medido em 2026-09-30)

| Peça | Onde |
|---|---|
| PWA WhatsApp Web | app-id `hnpfjngllnobngcgfapefoaidbinmjnm`, WM_CLASS `crx_hnpfjngllnobngcgfapefoaidbinmjnm` |
| launcher do PWA (gerido pelo Chrome) | `~/.local/share/applications/chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop` |
| autostart do PWA (gerido pelo Chrome) | `~/.config/autostart/chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop` |
| menu do PWA (gerido pelo Chrome) | `~/.config/menus/applications-merged/user-chrome-apps.menu` |
| handler `whatsapp://` (symlink para este checkout) | `~/.local/bin/whatsapp-uri-handler` |
| native host (symlink para este checkout) | `~/.local/bin/whatsapp-bridge-host`, que escuta em `/run/user/1000/whatsapp-bridge.sock` |
| registro do handler | `~/.local/share/applications/whatsapp-uri-handler.desktop` e a linha em `[Default Applications]` de `~/.config/mimeapps.list` |
| manifest do native host | `~/.config/google-chrome/NativeMessagingHosts/com.fjaekel.whatsapp_bridge.json` |
| extensão descompactada | id `mkcgbebnofigbmjehjonacgdbookjfne`, carregada de `extension/` deste checkout |
| helper de posicionamento (não versionado) | `~/.local/bin/place-pwas-on-laptop`, com alvo no Outlook e no WhatsApp |

## Não mexer: nome parecido, peça diferente

O serviço `whatsapp-bridge.service` (systemd user) roda `~/.local/bin/whatsapp-bridge` (ELF,
whatsmeow), com store em `~/.local/share/whatsapp-bridge-store`. É outro aparelho vinculado, do
whatsapp-mcp e do health-track, e não tem relação com este repo. Não pare, não desabilite, não apague
e não desvincule aparelhos pela lista do celular, porque desvincular o errado derruba essa ponte.

## Decisões

- A instalação é de sistema, pelo remote `flathub` que já existe. O polkit
  (`/usr/share/polkit-1/rules.d/org.freedesktop.Flatpak.rules`) libera o grupo `sudo` sem senha em
  sessão local ativa.
- O autostart é escrito à mão em `~/.config/autostart/`. A opção "Start Whatsie automatically when I
  log in" do app, dentro do Flatpak, grava em `~/.var/app/com.ktechpit.whatsie/config/autostart/`
  com `Exec=/app/bin/whatsie`. O Cinnamon nunca lê esse arquivo, então a opção falha em silêncio
  (`src/platform/linux/autostart_xdg.cpp`) e fica desligada.
- O whatsie sobe escondido (`--minimized`) e não abre janela durante a troca de layout do login, então
  não entra no `place-pwas-on-laptop`. O Outlook continua no helper.
- As peças deste repo saem do host, não do repo. Os binários instalados são symlinks para o checkout.

## Como executar

Uma sessão interativa, sem plan loop: 5 dos 12 passos são cliques seus (celular e Chrome), e cada
passo leva minutos. A partir do checkout:

    claude --model sonnet --effort medium "executa docs/plans/2026-09-30-trocar-pwa-pelo-whatsie.md"

No Desktop, abra uma sessão nesta pasta com Sonnet e esforço médio no seletor. O par é o de execução
guiada contra um plano. Nenhum passo pede mais, porque não sobra decisão de desenho nem domínio
sutil.

## Rollback

- `flatpak uninstall com.ktechpit.whatsie` e `rm ~/.config/autostart/com.ktechpit.whatsie.desktop`.
- Reinstale o PWA pelo ícone de instalar na barra de endereço, em `web.whatsapp.com`.
- Rode `./install.sh` deste checkout. Ele recria os symlinks, o `.desktop`, o manifest do host e o
  default do `xdg-mime`. Depois recarregue `extension/` em `chrome://extensions`.
- `cp ~/.local/bin/place-pwas-on-laptop.bak-20260930 ~/.local/bin/place-pwas-on-laptop`.
- Se o repo já estiver arquivado, rode antes
  `GH_TOKEN=$(env -u GITHUB_TOKEN -u GH_TOKEN gh auth token --user fkjaekel) gh repo unarchive fkjaekel/whatsapp-pwa-bridge --yes`.

## Steps

### Step 1: Baseline antes de mexer
Status: pending
Dependencies: none
Files: nenhum (só leitura)
Context: registre na sessão:
- `df -h /`: precisa de pelo menos 2 GB livres, porque o runtime `org.kde.Platform//6.11` baixa 410 MB e ocupa 1,1 GB instalado
- `flatpak remotes`: deve aparecer `flathub system`
- `systemctl --user is-active whatsapp-bridge.service`: deve dar `active`
- `xdg-mime query default x-scheme-handler/whatsapp`: deve dar `whatsapp-uri-handler.desktop`
Success: os quatro valores conferem. Qualquer divergência para a execução e vira pergunta.

### Step 2: Instalar o whatsie pelo Flathub
Status: pending
Dependencies: 1
Files: `/var/lib/flatpak/` (instalação de sistema)
Context: `flatpak install -y --noninteractive flathub com.ktechpit.whatsie`. Se o polkit pedir senha, não insista. Instale como usuário com `flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo` seguido de `flatpak install --user -y flathub com.ktechpit.whatsie`, e nos passos seguintes troque `/var/lib/flatpak/exports` por `~/.local/share/flatpak/exports`.
Success: `flatpak info com.ktechpit.whatsie` mostra versão 6.1.1 ou maior, e `grep MimeType /var/lib/flatpak/exports/share/applications/com.ktechpit.whatsie.desktop` devolve `x-scheme-handler/whatsapp;`.

### Step 3: Vincular o whatsie e configurar bandeja e notificações
Status: pending
Dependencies: 2
Manual: true
Files: `~/.var/app/com.ktechpit.whatsie/` (perfil e configurações do app)
Context: a sessão abre o app com `setsid flatpak run com.ktechpit.whatsie >/dev/null 2>&1 &`, e você escaneia o QR no celular (WhatsApp → Aparelhos conectados → Conectar um aparelho). O whatsie entra ao lado do PWA e da ponte whatsmeow; o limite do WhatsApp é de 4 aparelhos. Nas configurações (os rótulos abaixo são os do código, em inglês; a interface pode aparecer em português):
- "When closing the window": "Minimize to tray"
- "Hide the tray icon": desmarcado
- notificações: ligadas
- "Start Whatsie automatically when I log in": desmarcado (ver Decisões)
Se aparecer "No system tray was detected", pare: o sandbox não enxergou a bandeja do Cinnamon.
Success: as conversas carregam; o ícone aparece na bandeja; depois de fechar a janela, `flatpak ps` ainda lista `com.ktechpit.whatsie`; uma mensagem recebida gera notificação e contador no ícone.

### Step 4: Autostart minimizado
Status: pending
Dependencies: 3
Files: `~/.config/autostart/com.ktechpit.whatsie.desktop` (novo)
Context: escreva o arquivo com este conteúdo:

    [Desktop Entry]
    Type=Application
    Name=Whatsie
    Icon=com.ktechpit.whatsie
    Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=whatsie com.ktechpit.whatsie --minimized
    X-GNOME-Autostart-enabled=true

A opção `--minimized` é "Start hidden in the system tray" (`src/app/cli_options.cpp`).
Success: `desktop-file-validate` não acusa erro. Com o app encerrado (`flatpak kill com.ktechpit.whatsie`), rodar o `Exec` faz o whatsie subir só na bandeja, sem janela.

### Step 5: Apontar `whatsapp://` para o whatsie
Status: pending
Dependencies: 3
Files: `~/.config/mimeapps.list`
Context: rode `xdg-mime default com.ktechpit.whatsie.desktop x-scheme-handler/whatsapp`. Sem isso o whatsie fica só como candidato, porque a linha `x-scheme-handler/whatsapp=whatsapp-uri-handler.desktop`, gravada em `[Default Applications]` pelo `install.sh` deste repo, ganha de qualquer app instalado depois.
Success: `xdg-mime query default x-scheme-handler/whatsapp` devolve `com.ktechpit.whatsie.desktop`. `xdg-open 'whatsapp://send?text=teste-handler'` abre no whatsie já aberto, sem segunda janela, e nada é enviado sem clique seu. O botão de abrir o app numa página wa.me no Chrome leva ao aviso do `xdg-open` e abre no whatsie.

### Step 6: Desconectar e desinstalar o PWA
Status: pending
Dependencies: 5
Manual: true
Files: os três arquivos do PWA geridos pelo Chrome (tabela acima)
Context: primeiro, dentro do PWA: menu ⋮ da lista de conversas → Desconectar. Isso remove só esse aparelho; não desvincule pela lista do celular (ver "Não mexer"). Depois, desinstale pelo menu ⋮ da janela do app → Desinstalar, ou em `chrome://apps` → botão direito → Remover do Chrome. O Chrome MCP não controla páginas `chrome://`, por isso esses cliques são seus.
Success: somem o launcher e o autostart do PWA, e a entrada dele em `user-chrome-apps.menu`. Se o autostart ficar para trás, a sessão apaga à mão; o `.menu` é reescrito pelo Chrome e não deve ser editado. `systemctl --user is-active whatsapp-bridge.service` continua `active`, e `~/.local/share/whatsapp-bridge-store/bridge.log` não registra logout depois deste passo.

### Step 7: Remover a extensão da ponte
Status: pending
Dependencies: 6
Manual: true
Files: perfil do Chrome
Context: em `chrome://extensions`, remova a extensão descompactada de id `mkcgbebnofigbmjehjonacgdbookjfne`. O native host, que é o processo `python3` dono de `/run/user/1000/whatsapp-bridge.sock`, encerra junto.
Success: `ss -xlp | grep whatsapp-bridge.sock` não devolve nada.

### Step 8: Apagar do host as peças deste repo
Status: pending
Dependencies: 7
Files: `~/.local/bin/whatsapp-uri-handler`, `~/.local/bin/whatsapp-bridge-host`, `~/.local/share/applications/whatsapp-uri-handler.desktop`, `~/.config/google-chrome/NativeMessagingHosts/com.fjaekel.whatsapp_bridge.json` e `/run/user/1000/whatsapp-bridge.sock`, se tiver sobrado
Context: antes de apagar, confirme com `readlink` que os dois binários são symlinks para este checkout. O `~/.local/bin/whatsapp-bridge`, sem sufixo e em ELF, não é deste repo. Depois rode `update-desktop-database ~/.local/share/applications`.
Success: `grep -c whatsapp-uri-handler ~/.local/share/applications/mimeinfo.cache ~/.config/mimeapps.list` dá 0 nos dois arquivos; `xdg-mime query default x-scheme-handler/whatsapp` segue em `com.ktechpit.whatsie.desktop`; `systemctl --user is-active whatsapp-bridge.service` dá `active`.

### Step 9: Tirar o WhatsApp do helper de posicionamento
Status: pending
Dependencies: 6
Files: `~/.local/bin/place-pwas-on-laptop` (não versionado; copie antes para `place-pwas-on-laptop.bak-20260930` na mesma pasta)
Context: no JS, remova `"crx_hnpfjngllnobngcgfapefoaidbinmjnm"` do array `ids` e troque "(Outlook, WhatsApp)" por "(Outlook)" no comentário do topo. O `.desktop` de autostart do helper não muda.
Success: `bash -n` passa; `grep -c hnpfjng` dá 0; `PWA_PLACE_ACTIVE=4 ~/.local/bin/place-pwas-on-laptop` termina, e `journalctl -t place-pwas-on-laptop --since -2min` mostra `iniciado` e `concluido`, sem `ERR`.

### Step 10: Validar no próximo login
Status: pending
Dependencies: 4, 8, 9
Manual: true
Files: nenhum
Context: saia e entre de novo na sessão, ou reinicie a máquina.
Success: o whatsie está na bandeja, sem janela; o Outlook abre no eDP-1; nenhum PWA do WhatsApp subiu; `whatsapp-bridge.service` está `active`; um link wa.me no Chrome abre no whatsie.

### Step 11: Registrar e aposentar o repo
Status: pending
Dependencies: 10
Files: `README.md` deste repo; este plano; `~/.claude/projects/-home-fjaekel/memory/cinnamon-pwa-window-placement.md` e a linha dela no `MEMORY.md`
Context: o README ganha no topo a linha "Aposentado em <data>: substituído pelo whatsie (Flathub `com.ktechpit.whatsie`), que registra `x-scheme-handler/whatsapp` sozinho. Para reinstalar, `./install.sh`, que exige o PWA." No mesmo commit, `git mv` este plano para `docs/plans/archive/`. Como o commit só tem doc, o push vai direto na `main`. Na memória, registre que o helper agora move só o Outlook e que o WhatsApp virou o whatsie Flatpak na bandeja; se o diretório de memória estiver versionado no `claude-settings`, faça commit e push lá também.
Success: `git log --oneline -1 origin/main` mostra o commit, e a memória está atualizada.

### Step 12: Arquivar o repo no GitHub
Status: pending
Dependencies: 11
Manual: true
Files: nenhum local
Context: a decisão é sua. A recomendação é arquivar, porque o repo só serve ao PWA. Rode só depois do push do passo 11, porque repo arquivado vira somente leitura: `GH_TOKEN=$(env -u GITHUB_TOKEN -u GH_TOKEN gh auth token --user fkjaekel) gh repo archive fkjaekel/whatsapp-pwa-bridge --yes`. Para desfazer, use o mesmo prefixo com `gh repo unarchive fkjaekel/whatsapp-pwa-bridge --yes`.
Success: `gh repo view fkjaekel/whatsapp-pwa-bridge --json isArchived` devolve `true`.
