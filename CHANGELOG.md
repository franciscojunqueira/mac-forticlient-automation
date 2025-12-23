# Changelog

Todas as mudanças importantes neste projeto serão documentadas neste arquivo.

## [2.0.0] - 2025-12-23

### 🎉 Versão Completa - 95% de Automação

#### ✨ Adicionado
- **Restauração completa de contexto do usuário**:
  - Salva aplicação em foco (nome + bundle ID)
  - Salva posição do mouse (incluindo coordenadas negativas)
  - Restaura mouse imediatamente após clique (0.2s)
  - Restaura foco após janela modal MFA aparecer (2s)
  - Restaura foco final após VPN reconectar
- **Suporte multi-monitor completo**:
  - Coordenadas negativas via CoreGraphics
  - JavaScript ObjC Bridge (`CGWarpMouseCursorPosition`)
  - Funciona com monitores acima/esquerda do principal
- **Fechamento automático do FortiClient**:
  - Fecha janela após reconexão bem-sucedida (Command+W)
  - Restaura foco para aplicação original
- **Alertas em português brasileiro**:
  - Voz Luciana (PT-BR) para todos os alertas
  - "V P N" espaçado para pronúncia correta
  - Alertas genéricos configuráveis
- **Scripts de teste**:
  - `test-disconnect-with-countdown.sh` - Teste completo com countdown
  - `force-disconnect-vpn.sh` - Desconexão forçada para testes
  - `restart-monitor.sh` - Reinício fácil do monitor

#### 🔧 Melhorado
- Clique automático agora usa coordenadas relativas (62% largura, 72% altura)
- Detecção dinâmica da posição da janela do FortiClient
- Timing otimizado para restauração de contexto
- Logs detalhados para debugging
- Dupla tentativa de restauração de foco com fallback

#### 🐛 Corrigido
- Mouse não voltava para coordenadas negativas (multi-monitor)
- Foco era roubado pela janela modal MFA
- FortiClient roubava foco após reconexão
- Contexto era salvo tarde demais (após FortiClient abrir)

## [1.0.3] - 2025-12-23

### ✨ Adicionado
- Clique automático no botão "Connect" do FortiClient
- Calibração precisa das coordenadas do botão
- Suporte para múltiplos monitores (detecção dinâmica de posição)
- Scripts de teste e debugging

### 🔧 Melhorado
- Reduz intervenção manual de 5 passos para 1 (apenas aprovar MFA)
- Documentação completa em `docs/`

## [1.0.2] - 2025-12-22

### 🔧 Melhorado
- Otimização do monitoramento contínuo
- Melhor tratamento de múltiplas instâncias

## [1.0.1] - 2025-12-21

### ✨ Adicionado
- Detecção dupla (scutil + ifconfig) para maior confiabilidade
- Lock file para evitar múltiplas instâncias

## [1.0.0] - 2025-12-20

### 🎉 Lançamento Inicial

#### ✨ Funcionalidades
- Monitoramento contínuo da conexão VPN (a cada 5s)
- Alertas múltiplos quando VPN desconecta:
  - Alerta de voz (`say`)
  - Sons do sistema
  - Notificações do macOS
- Abertura automática do FortiClient
- Confirmação de reconexão
- Suporte para início automático no login

---

## Legenda
- ✨ Adicionado: Novas funcionalidades
- 🔧 Melhorado: Melhorias em funcionalidades existentes
- 🐛 Corrigido: Correções de bugs
- 🎉 Marcos importantes do projeto
