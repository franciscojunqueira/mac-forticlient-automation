# VPN Monitor & Auto-Reconnect - FortiClient

Complete monitoring and automatic reconnection system for FortiClient Zero Trust Fabric Agent with MFA authentication. Achieves ~95% automation, leaving only manual MFA approval (mandatory for security).

## 🎯 Funcionalidades

- ✅ **Monitoramento contínuo** da conexão VPN (verifica a cada 5 segundos)
- ✅ **Alertas múltiplos** quando a VPN desconecta:
  - 🗣️ Alerta de voz em português brasileiro (voz Luciana)
  - 🔔 Sons do sistema
  - 📱 Notificações do macOS
- ✅ **Reconexão 95% AUTOMÁTICA**:
  - Detecta desconexão automaticamente
  - Salva contexto do usuário (app em foco + posição do mouse)
  - Abre o FortiClient automaticamente
  - **Clica automaticamente no botão "Connect"** 
  - **Restaura mouse para posição original** (suporta multi-monitor com coordenadas negativas!)
  - **Restaura foco para aplicação original** (você continua trabalhando sem interrupção)
  - Você só precisa aprovar no celular quando notificado!
  - **Fecha janela do FortiClient** após conexão bem-sucedida
  - **Restaura foco final** para sua aplicação original
- ✅ **Suporte multi-monitor** com coordenadas negativas (via CoreGraphics)
- ✅ **Confirmação de reconexão** com alerta de sucesso
- ✅ **Inicia automaticamente** no login do macOS

## 🎬 Como Funciona (Do Ponto de Vista do Usuário)

### Cenário Real:
Você está trabalhando no seu editor de código quando a VPN cai...

**Antes (manual - 6+ ações):**
1. Perceber que VPN caiu
2. Abrir FortiClient
3. Clicar em "Connect"
4. Aprovar no celular
5. Fechar FortiClient
6. Voltar para seu trabalho
7. Reposicionar janelas

**Agora (95% automático - 1 ação):**
1. 📱 **Você apenas aprova no celular** quando notificado
2. ✨ **Sistema faz todo o resto automaticamente**

Você nem perde o foco do trabalho! O mouse e a janela ativa voltam automaticamente para onde estavam.

## 🚀 Instalação Rápida

### Pré-requisitos
```bash
# Instalar cliclick (para automação de mouse)
brew install cliclick

# Criar diretórios necessários
mkdir -p ~/bin ~/tmp
```

### Instalação Automática
```bash
cd ~/GitHub/mac-Forticlient-automation
./install.sh
```

### Instalação Manual
```bash
# 1. Copiar script principal
cp scripts/vpn-monitor-orizon.sh ~/bin/
chmod +x ~/bin/vpn-monitor-orizon.sh

# 2. Copiar script de clique automático
mkdir -p ~/GitHub/mac-Forticlient-automation/scripts/
cp scripts/auto-click-connect.sh ~/GitHub/mac-Forticlient-automation/scripts/
chmod +x ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh

# 3. Iniciar monitor
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &

# 4. (Opcional) Adicionar aos Itens de Login
# Ir em: Configurações → Geral → Itens de Início
# Adicionar: ~/bin/vpn-monitor-orizon.sh
```

## 📋 Requisitos

- macOS (testado em macOS 14+)
- FortiClient Zero Trust Fabric Agent instalado
- Conexão VPN configurada
- **cliclick** instalado (`brew install cliclick`)
- **Permissões de Acessibilidade** para Terminal/Warp:
  - Configurações → Privacidade e Segurança → Acessibilidade
  - Adicionar: Terminal ou Warp (sua aplicação de terminal)

## 📁 Estrutura do Projeto

```
mac-Forticlient-automation/
├── README.md                           # Este arquivo
├── CHANGELOG.md                        # Histórico de versões
├── install.sh                          # Script de instalação automática
├── scripts/
│   ├── vpn-monitor-orizon.sh          # Script principal de monitoramento
│   ├── auto-click-connect.sh          # Script de clique automático (multi-monitor)
│   ├── restart-monitor.sh             # Reinicia o monitor facilmente
│   ├── force-disconnect-vpn.sh        # Para testes (desconecta VPN)
│   └── test-disconnect-with-countdown.sh  # Teste completo com countdown
├── app/
│   └── VPNMonitor.app/                 # Wrapper macOS app (opcional)
└── docs/
    ├── FINAL-IMPLEMENTATION.md         # Documentação técnica completa
    ├── MULTI-MONITOR-SUPPORT.md        # Detalhes do suporte multi-monitor
    ├── CLICK-CALIBRATION.md            # Calibração das coordenadas do botão
    └── vpn-monitor-analysis.md         # Análise técnica dos métodos
```

## ⚙️ Configuração

### Customizar Alertas

Edite `~/bin/vpn-monitor-orizon.sh`:

```bash
# Linha 38 - Habilitar/desabilitar reconexão automática
AUTO_RECONNECT=true   # ou false

# Linha 116 - Voz do alerta (português brasileiro)
say -v Luciana "..."  # Outras opções: Joana, Felipe

# Linha 70 - Voz de confirmação
say "VPN reconectada com sucesso"  # Usa voz padrão do sistema
```

### UUID da VPN

Se você reconfigurar sua VPN, atualize o UUID:

```bash
# Descobrir UUID atual
scutil --nc list

# Atualizar no script (linha 25)
FORTICLIENT_UUID="seu-uuid-aqui"
```

## 🧪 Como Testar

### Teste Simples (Desconexão Manual)
```bash
# Desconectar VPN manualmente
scutil --nc stop "VPN"

# Aguardar ~5 segundos e observar:
# 1. Alerta de voz em português
# 2. FortiClient abre
# 3. Clique automático no botão Connect
# 4. Mouse e foco voltam para onde estavam
# 5. Aprovar no celular
# 6. FortiClient fecha automaticamente
# 7. Foco volta para sua aplicação
```

### Teste Completo com Countdown
```bash
# Execute este script e MANTENHA O FOCO no terminal
~/GitHub/mac-Forticlient-automation/scripts/test-disconnect-with-countdown.sh

# O script vai:
# - Contar 5 segundos
# - Desconectar VPN
# - Você deve observar todo o processo automático
# - Foco e mouse devem voltar para o terminal
```

## 📊 Gerenciamento

### Ver se está rodando
```bash
pgrep -lf vpn-monitor-orizon
# ou
ps aux | grep vpn-monitor-orizon.sh | grep -v grep
```

### Ver logs em tempo real
```bash
tail -f ~/tmp/vpn-monitor.log
```

### Parar o monitor
```bash
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
```

### Reiniciar o monitor (método fácil)
```bash
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh
```

### Reiniciar o monitor (método manual)
```bash
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

## 🎓 Como Funciona Tecnicamente

### Métodos de Detecção

O script usa **dupla verificação** para máxima confiabilidade:

1. **scutil --nc status** - API nativa do macOS para VPNs
2. **ifconfig** - Verifica se interface VPN tem IP (padrão configurável: 10.*, 172.16.*, etc)

Ambos devem confirmar para considerar conectado.

### Fluxo de Reconexão (Detalhado)

```
VPN desconecta
   ↓
Detecta em ~5s (dupla verificação)
   ↓
SALVA CONTEXTO DO USUÁRIO:
  - Aplicação em foco (nome + bundle ID)
  - Posição do mouse (X,Y incluindo coordenadas negativas)
   ↓
Alertas (voz em PT-BR + som + notificação)
   ↓
Abre FortiClient automaticamente
   ↓
Aguarda janela abrir (2s)
   ↓
✨ CLICA no botão "Connect" automaticamente
  - Detecta posição da janela dinamicamente
  - Calcula coordenadas do botão (62% largura, 72% altura)
  - Funciona em qualquer monitor/posição
   ↓
RESTAURAÇÃO IMEDIATA (Etapa 1):
  - Mouse volta para posição original (0.2s após clique)
  - Usa CoreGraphics para coordenadas negativas
   ↓
Aguarda janela modal MFA aparecer (2s)
   ↓
RESTAURAÇÃO DE FOCO (Etapa 2):
  - Foco volta para aplicação original
  - Usa bundle ID (mais confiável que nome)
   ↓
Você APENAS aprova no celular (1 toque) 📱
   ↓
VPN reconecta
   ↓
RESTAURAÇÃO FINAL:
  - Fecha janela FortiClient (Command+W)
  - Restaura foco para aplicação original
   ↓
Alerta de confirmação em português
```

**Reduz de 7 ações manuais para apenas 1!** 🎉

### Coordenadas Multi-Monitor

O sistema suporta **coordenadas negativas** (monitors posicionados acima/esquerda do principal):

- **Detecção**: `cliclick p` para obter posição atual
- **Restauração**: `osascript` + `CoreGraphics` (JavaScript ObjC Bridge)
  - `cliclick` não funciona bem com coordenadas negativas
  - Solução: `CGWarpMouseCursorPosition` via JavaScript OSA

Exemplo:
```javascript
ObjC.import('CoreGraphics');
var point = {x: 1200, y: -300};  // Monitor acima
$.CGWarpMouseCursorPosition(point);
```

## ⚠️ Limitações Técnicas

### Por que não é 100% automático?

O FortiClient com MFA tem as seguintes proteções de segurança:

- 🔒 **Aprovação MFA obrigatória** no celular (não pode e NÃO DEVE ser bypassada)
- 🔒 **Credenciais protegidas** (senha/certificado não acessíveis via script)
- 🔒 **Autenticação 2FA** (segurança corporativa)

### O que NÃO pode ser automatizado:
- ❌ Aprovar MFA automaticamente (violaria segurança obrigatória)
- ❌ Bypass de autenticação
- ❌ Armazenar credenciais

### O que FOI automatizado (95% do possível!):
- ✅ Detecção de desconexão
- ✅ Salvamento de contexto do usuário
- ✅ Abertura do FortiClient
- ✅ **Clique automático no botão "Connect"** ✨
- ✅ **Restauração de mouse (multi-monitor + coordenadas negativas)** ✨
- ✅ **Restauração de foco da aplicação** ✨
- ✅ **Fechamento automático do FortiClient** ✨
- ✅ **Restauração final de foco** ✨
- ✅ Alertas fortes e múltiplos em português
- ✅ Confirmação de reconexão
- ✅ Monitoramento contínuo

## 🔧 Troubleshooting

### Monitor não inicia
```bash
# Verificar permissões do script
ls -la ~/bin/vpn-monitor-orizon.sh

# Deve mostrar: -rwxr-xr-x
# Se não, executar:
chmod +x ~/bin/vpn-monitor-orizon.sh
```

### Não recebe alertas de voz
```bash
# Testar comando say manualmente
say -v Luciana "teste em português"

# Se não funcionar, verificar vozes instaladas
say -v "?"

# Instalar voz Luciana (se necessário)
# Configurações → Acessibilidade → Conteúdo Falado → Vozes do Sistema
```

### Clique automático não funciona
```bash
# Verificar se cliclick está instalado
which cliclick

# Se não estiver:
brew install cliclick

# Testar cliclick manualmente
cliclick p  # Mostra posição atual do mouse

# Verificar permissões de Acessibilidade
# Ir em: Configurações → Privacidade e Segurança → Acessibilidade
# Adicionar: Terminal ou Warp
```

### FortiClient não abre
```bash
# Testar manualmente
open -a "FortiClient"

# Se falhar, verificar se está instalado
ls -la /Applications/FortiClient.app
```

### Mouse não volta para posição original (multi-monitor)
```bash
# Verificar se CoreGraphics/JavaScript está funcionando
osascript -l JavaScript << 'EOF'
ObjC.import('CoreGraphics');
var point = {x: 500, y: -100};
$.CGWarpMouseCursorPosition(point);
console.log("Mouse movido para coordenadas negativas");
EOF

# Se funcionar, o problema pode ser timing
# Ajustar delays no script auto-click-connect.sh
```

### Múltiplas instâncias rodando
```bash
# Usar script de restart
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh

# Ou manualmente:
pkill -9 -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

## 📚 Documentação Adicional

- **[Documentação Técnica Completa](docs/FINAL-IMPLEMENTATION.md)** - Implementação detalhada
- **[Suporte Multi-Monitor](docs/MULTI-MONITOR-SUPPORT.md)** - Coordenadas dinâmicas e negativas
- **[Calibração de Cliques](docs/CLICK-CALIBRATION.md)** - Como foram calibrados os botões
- **[Análise Técnica](docs/vpn-monitor-analysis.md)** - Comparação de métodos de monitoramento

## ⚙️ Configuração Personalizada

Configure o script conforme sua VPN:

### Descobrir UUID da sua VPN
```bash
scutil --nc list
```

### Editar configurações no script
Edite `~/bin/vpn-monitor-orizon.sh`:

```bash
# Linha 13-14: UUID da sua VPN
FORTICLIENT_UUID="YOUR-VPN-UUID-HERE"

# Linha 16: Interface (geralmente utun7 para FortiClient)
VPN_INTERFACE="utun7"

# Linha 51-52: Padrão de IP da sua VPN
# Exemplos: 10.*, 192.168.*, 172.16.*, 172.22.*
if ifconfig "$VPN_INTERFACE" 2>/dev/null | grep -q "inet 10\.";
```

## 🎯 Casos de Uso

### Trabalho Remoto
Ideal para quem trabalha remotamente e precisa manter VPN ativa o tempo todo. O sistema garante reconexão rápida sem perder seu contexto de trabalho.

### Múltiplos Monitores
Funciona perfeitamente em setups com 2, 3 ou mais monitores, incluindo monitores posicionados acima ou à esquerda do principal (coordenadas negativas).

### Desenvolvimento
Desenvolvedores que precisam acessar recursos internos via VPN podem continuar codificando sem interrupções - o sistema restaura foco para o IDE automaticamente.

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se livre para:
- Reportar bugs
- Sugerir melhorias
- Enviar pull requests
- Adaptar para seu ambiente corporativo

## 📄 Licença

MIT License - Veja LICENSE para mais detalhes.

Adapte conforme necessário respeitando políticas de segurança da sua empresa.

---

**Desenvolvido para automatizar monitoramento VPN com FortiClient + MFA**

✨ A solução mais automatizada possível respeitando limites de segurança ✨

🎯 **95% de automação** - Você só aprova no celular! 🎯
