[English](README.en.md) | **Português (Brasil)**

# VPN Monitor & Auto-Reconnect - FortiClient

Sistema completo de monitoramento e reconexão automática para FortiClient Zero Trust Fabric Agent com autenticação MFA. Alcança ~95% de automação, deixando apenas a aprovação MFA manual (obrigatória por segurança).

## 📋 Visão Geral

Este é um **sistema de automação baseado em bash** que monitora conexões VPN e reconecta automaticamente quando desconectado, incluindo interação automática de UI para clicar no botão "Connect".

**Problema resolvido:** Reconectar VPN manualmente é tedioso e interrompe o fluxo de trabalho. Este sistema automatiza todo o processo, exceto a aprovação MFA (que é obrigatória por segurança).

**Para quem é:** Desenvolvedores e profissionais remotos que precisam manter conexão VPN ativa o tempo todo, especialmente em configurações multi-monitor.

## ✨ Recursos

- ✅ Monitoramento contínuo da conexão VPN (verifica a cada 5 segundos)
- ✅ Detecção dupla confiável (scutil + ifconfig)
- ✅ Alertas múltiplos quando VPN desconecta:
  - Alerta de voz em português brasileiro (voz Luciana)
  - Sons do sistema
  - Notificações do macOS
- ✅ Reconexão 95% automática:
  - Detecta desconexão automaticamente
  - Salva contexto do usuário (app em foco + posição do mouse)
  - Abre FortiClient automaticamente
  - Clica automaticamente no botão "Connect"
  - Restaura mouse para posição original (suporta multi-monitor com coordenadas negativas)
  - Restaura foco para aplicação original
  - Fecha janela do FortiClient após conexão bem-sucedida
  - Restaura foco final para sua aplicação
- ✅ Suporte multi-monitor completo via CoreGraphics
- ✅ Dois modos de detecção de botão:
  - Auto-detecção via visão computacional (Python + Pillow)
  - Coordenadas fixas calibradas (modo privacidade - sem screenshots)
- ✅ Lock file para prevenir múltiplas instâncias
- ✅ Logs detalhados para debugging
- ✅ Scripts de teste e gerenciamento inclusos
- ✅ Suporte para início automático no login do macOS

## 🏗️ Arquitetura

### Componentes Principais

1. **vpn-monitor-orizon.sh** - Daemon de monitoramento principal
   - Loop de verificação a cada 5 segundos
   - Verificação dupla (scutil + ifconfig)
   - Orquestração do fluxo de reconexão
   - Gerenciamento de lock file (`~/tmp/.vpn-monitor.lock`)

2. **auto-click-connect.sh** - Componente de automação de UI
   - Detecção dinâmica da posição da janela FortiClient
   - Dois modos de detecção de botão (auto/manual)
   - Restauração de contexto do usuário (mouse + foco)
   - Suporte multi-monitor com coordenadas negativas

3. **config.sh** - Configuração centralizada
   - Toggle PRIVACY_MODE
   - Offsets de botão para modo manual
   - Configurações de VPN (UUID, interface, intervalo)

### Fluxo de Reconexão

```
VPN desconecta
   ↓
Detecta em ~5s (verificação dupla)
   ↓
Salva contexto (app em foco + posição do mouse)
   ↓
Alertas (voz PT-BR + som + notificação)
   ↓
Abre FortiClient automaticamente
   ↓
Clica no botão "Connect" automaticamente
   ↓
Restaura mouse (0.2s após clique)
   ↓
Aguarda modal MFA (2s)
   ↓
Restaura foco para aplicação original
   ↓
→ Você aprova no celular (ÚNICA AÇÃO MANUAL) ←
   ↓
VPN reconecta
   ↓
Fecha FortiClient automaticamente
   ↓
Restaura foco final
   ↓
Alerta de confirmação
```

**Reduz de 7 ações manuais para apenas 1!** 🎉

## 🔧 Pré-requisitos

- **Sistema Operacional:** macOS 14+ (Sonoma ou superior)
- **Software:**
  - FortiClient Zero Trust Fabric Agent instalado
  - Conexão VPN configurada no FortiClient
  - [cliclick](https://github.com/BlueM/cliclick) instalado (`brew install cliclick`)
  - Bash 5.x (padrão no macOS moderno)
- **Opcional (para modo auto-detecção):**
  - Python 3
  - Pillow (`pip3 install Pillow`)
- **Permissões macOS:**
  - **Acessibilidade** (obrigatório) - Para cliclick funcionar
  - **Screen Recording** (apenas se PRIVACY_MODE=false) - Para detecção automática de botão

### Configurar Permissões

1. Abra: **Configurações → Privacidade e Segurança → Acessibilidade**
2. Clique no **+** e adicione seu terminal (Terminal.app, iTerm2, Warp, etc.)
3. Se usar PRIVACY_MODE=false: **Configurações → Privacidade e Segurança → Screen Recording** e adicione seu terminal

## 🚀 Instalação

### Instalação Automática (Recomendado)

```bash
cd ~/GitHub/mac-Forticlient-automation
./install.sh
```

O instalador irá:
- Detectar automaticamente UUID da VPN
- Instalar dependências (cliclick via Homebrew)
- Copiar scripts para locais corretos
- Configurar permissões
- Opcionalmente adicionar aos Itens de Login

### Instalação Manual

```bash
# 1. Criar diretórios necessários
mkdir -p ~/bin ~/tmp ~/GitHub/mac-Forticlient-automation/scripts

# 2. Copiar script principal
cp scripts/vpn-monitor-orizon.sh ~/bin/
chmod +x ~/bin/vpn-monitor-orizon.sh

# 3. Copiar script de clique automático
cp scripts/auto-click-connect.sh ~/GitHub/mac-Forticlient-automation/scripts/
chmod +x ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh

# 4. Copiar configuração
cp config.sh ~/GitHub/mac-Forticlient-automation/

# 5. Instalar cliclick
brew install cliclick

# 6. Configurar UUID da VPN
scutil --nc list  # Copie o UUID da sua VPN
nano ~/bin/vpn-monitor-orizon.sh  # Edite linha 14: FORTICLIENT_UUID="seu-uuid"
```

## ⚙️ Configuração

### Configuração Básica

Edite `~/GitHub/mac-Forticlient-automation/config.sh`:

```bash
# Modo de detecção de botão
export PRIVACY_MODE=false  # false=auto-detecção, true=coordenadas fixas

# Coordenadas fixas (apenas se PRIVACY_MODE=true)
export BUTTON_OFFSET_X=552
export BUTTON_OFFSET_Y=525

# UUID da VPN (deixe vazio para auto-detectar)
export FORTICLIENT_UUID=""

# Interface VPN (geralmente utun7 para FortiClient)
export VPN_INTERFACE="utun7"

# Intervalo de verificação em segundos
export CHECK_INTERVAL=5

# Habilitar reconexão automática
export AUTO_RECONNECT=true
```

### Descobrir UUID da VPN

```bash
scutil --nc list
```

Procure por uma entrada contendo "FortiClient" ou "VPN" e copie o UUID (formato: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX).

### Customizar Alertas de Voz

Edite `~/bin/vpn-monitor-orizon.sh`:

```bash
# Linha 73 - Alerta de desconexão
say -v Luciana "Atenção! A V P N foi desconectada..."

# Linha 89 - Alerta de reconexão
say -v Luciana "V P N reconectada com sucesso"

# Outras vozes disponíveis: Joana, Felipe
# Listar todas: say -v "?"
```

## 💻 Uso

### Iniciar Monitor

```bash
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

### Verificar Status

```bash
# Verificar se está rodando
pgrep -lf vpn-monitor-orizon

# Ver logs em tempo real
tail -f ~/tmp/vpn-monitor.log

# Ver últimas 50 linhas
tail -n 50 ~/tmp/vpn-monitor.log
```

### Parar Monitor

```bash
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
```

### Reiniciar Monitor

```bash
# Método fácil (recomendado)
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh

# Método manual
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

## 🧪 Testes

### Teste Simples

```bash
# Desconectar VPN manualmente
scutil --nc stop "VPN"

# Aguarde ~5 segundos e observe:
# 1. Alerta de voz em português
# 2. FortiClient abre automaticamente
# 3. Clique automático no botão Connect
# 4. Mouse e foco voltam para onde estavam
# 5. Aprove no celular quando notificado
# 6. FortiClient fecha automaticamente
# 7. Foco volta para sua aplicação
```

### Teste Automatizado com Countdown

```bash
~/GitHub/mac-Forticlient-automation/scripts/test-disconnect-with-countdown.sh
```

Este script irá:
- Contar 5 segundos
- Desconectar VPN
- Você observa todo o processo automático
- Foco e mouse devem voltar para o terminal

### Desconexão Forçada (Para Testes)

```bash
~/GitHub/mac-Forticlient-automation/scripts/force-disconnect-vpn.sh
```

## 🐛 Troubleshooting

### Monitor não inicia

**Sintoma:** Script não inicia ou sai imediatamente.

**Soluções:**
```bash
# Verificar permissões
ls -la ~/bin/vpn-monitor-orizon.sh
# Deve mostrar: -rwxr-xr-x

# Corrigir permissões
chmod +x ~/bin/vpn-monitor-orizon.sh

# Verificar se já está rodando
pgrep -lf vpn-monitor-orizon

# Remover lock file antigo
rm -f ~/tmp/.vpn-monitor.lock
```

### Não recebe alertas de voz

**Sintoma:** Sem alerta de voz quando VPN desconecta.

**Soluções:**
```bash
# Testar comando say
say -v Luciana "teste em português"

# Verificar vozes instaladas
say -v "?"

# Instalar voz Luciana
# Vá em: Configurações → Acessibilidade → Conteúdo Falado → Vozes do Sistema
# Baixe: Português (Brasil) - Luciana
```

### Clique automático não funciona

**Sintoma:** FortiClient abre mas botão Connect não é clicado.

**Soluções:**
```bash
# Verificar se cliclick está instalado
which cliclick
# Se não: brew install cliclick

# Testar cliclick
cliclick p  # Deve mostrar posição do mouse

# Verificar permissões de Acessibilidade
# Vá em: Configurações → Privacidade e Segurança → Acessibilidade
# Adicione seu terminal

# Alternar modo de detecção
# Edite config.sh: PRIVACY_MODE=true (ou false)
```

### Mouse não volta para posição original em multi-monitor

**Sintoma:** Mouse não retorna à posição original, especialmente em coordenadas negativas.

**Soluções:**
```bash
# Testar CoreGraphics
osascript -l JavaScript << 'EOF'
ObjC.import('CoreGraphics');
var point = {x: 500, y: -100};
$.CGWarpMouseCursorPosition(point);
console.log("Mouse movido para coordenadas negativas");
EOF

# Se funcionar, problema pode ser timing
# Edite auto-click-connect.sh linha ~179: ajuste sleep
```

### FortiClient não abre

**Sintoma:** FortiClient não é aberto automaticamente.

**Soluções:**
```bash
# Testar manualmente
open -a "FortiClient"

# Verificar instalação
ls -la /Applications/FortiClient.app

# Verificar nome correto do app
ls -la /Applications/ | grep -i forti
```

### Múltiplas instâncias rodando

**Sintoma:** Logs duplicados ou comportamento errático.

**Soluções:**
```bash
# Usar script de restart (recomendado)
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh

# Ou matar todas e reiniciar
pkill -9 -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

### VPN não é detectada como conectada

**Sintoma:** Monitor acha que VPN está sempre desconectada.

**Soluções:**
```bash
# Verificar UUID
scutil --nc list

# Verificar status
scutil --nc status "SEU-UUID-AQUI"

# Verificar interface
ifconfig | grep utun

# Ajustar padrão de IP
# Edite vpn-monitor-orizon.sh linha ~52
# Exemplo: if ifconfig "$VPN_INTERFACE" 2>/dev/null | grep -q "inet 172\.16\.";
```

## 🗺️ Roadmap

- [ ] Interface gráfica opcional (menu bar app)
- [ ] Suporte para outros clientes VPN
- [ ] Métricas e estatísticas de conexão
- [ ] Notificações customizáveis via Notification Center
- [ ] Integração com Slack/Teams para notificações
- [ ] Modo silent (sem alertas de voz)

## 🤝 Contribuindo

Contribuições são bem-vindas! Aqui está como você pode ajudar:

### Reportar Bugs

Abra uma issue incluindo:
- Versão do macOS
- Versão do FortiClient
- Logs relevantes (`~/tmp/vpn-monitor.log`)
- Passos para reproduzir

### Sugerir Melhorias

Abra uma issue descrevendo:
- O problema que você está tentando resolver
- Sua solução proposta
- Alternativas consideradas

### Enviar Pull Requests

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

### Padrões de Código

- Use bash idiomático e POSIX quando possível
- Adicione comentários para lógica complexa
- Mantenha formato de log: `[YYYY-MM-DD HH:MM:SS] mensagem`
- Teste em múltiplos cenários (single/multi-monitor)
- Atualize documentação se necessário

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

Copyright (c) 2025 Francisco Junqueira

## 📚 Documentação Adicional

- [Documentação Técnica Completa](docs/FINAL-IMPLEMENTATION.md)
- [Suporte Multi-Monitor](docs/MULTI-MONITOR-SUPPORT.md)
- [Calibração de Cliques](docs/CLICK-CALIBRATION.md)
- [Modo Privacidade](docs/PRIVACY-MODE.md)
- [Análise Técnica](docs/vpn-monitor-analysis.md)
- [Changelog](CHANGELOG.md)
- [WARP Guide](WARP.md)

## 📞 Contato

**Maintainer:** Francisco Junqueira

**Repository:** [mac-Forticlient-automation](https://github.com/franciscojunqueira/mac-Forticlient-automation)

---

**Desenvolvido para automatizar monitoramento VPN com FortiClient + MFA**

✨ A solução mais automatizada possível respeitando limites de segurança ✨

🎯 **95% de automação** - Você só aprova no celular! 🎯
