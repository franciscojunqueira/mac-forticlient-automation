#!/bin/bash

# ============================================
# CONFIGURAÇÕES DO VPN MONITOR
# ============================================

# --------------------------------------------
# MODO DE PRIVACIDADE
# --------------------------------------------
# Define como o botão Connect será localizado:
#
# PRIVACY_MODE=false (RECOMENDADO - Padrão)
#   ✓ Detecção automática via visão computacional
#   ✓ Mais preciso - funciona com qualquer tamanho de janela
#   ✓ Adapta-se automaticamente a mudanças na UI
#   ⚠ Captura screenshot da janela FortiClient
#   ⚠ Requer permissão "Screen Recording" no macOS
#   ⚠ Requer Python 3 + Pillow instalado
#
# PRIVACY_MODE=true (PRIVACIDADE MÁXIMA)
#   ✓ SEM screenshots - SEM permissão "Screen Recording"
#   ✓ Mais privado e seguro
#   ✓ Não requer Python ou bibliotecas externas
#   ⚠ Usa coordenadas fixas calibradas
#   ⚠ Pode precisar recalibração se janela mudar de tamanho
#
export PRIVACY_MODE=true

# --------------------------------------------
# COORDENADAS FIXAS (usado quando PRIVACY_MODE=true)
# --------------------------------------------
# Offset do botão Connect a partir do canto superior esquerdo da janela
# Valores padrão calibrados para janela FortiClient 894x714
# 
# Se o clique não acertar o botão, ajuste estes valores:
# - Aumente BUTTON_OFFSET_X para mover para direita
# - Diminua BUTTON_OFFSET_X para mover para esquerda
# - Aumente BUTTON_OFFSET_Y para mover para baixo
# - Diminua BUTTON_OFFSET_Y para mover para cima
#
export BUTTON_OFFSET_X=552
export BUTTON_OFFSET_Y=525

# --------------------------------------------
# VPN CONFIGURAÇÃO
# --------------------------------------------
# UUID da conexão VPN (obtenha com: scutil --nc list)
# Deixe em branco para auto-detectar o primeiro FortiClient
export FORTICLIENT_UUID=""

# Interface de rede VPN (normalmente ppp0)
export VPN_INTERFACE="ppp0"

# Intervalo de verificação em segundos
export CHECK_INTERVAL=5

# Habilitar reconexão automática
export AUTO_RECONNECT=true

# --------------------------------------------
# PERMISSÕES DO MACOS
# --------------------------------------------
# IMPORTANTE: Dependendo do modo escolhido, você precisará de diferentes permissões:
#
# Com PRIVACY_MODE=false:
#   1. Acessibilidade (obrigatório) - para cliclick funcionar
#   2. Screen Recording (obrigatório) - para capturar screenshot
#
# Com PRIVACY_MODE=true:
#   1. Acessibilidade (obrigatório) - para cliclick funcionar
#   2. Screen Recording (NÃO necessário) ✓
#
# Como configurar:
# 1. Vá em: Configurações → Privacidade e Segurança → Acessibilidade
# 2. Adicione seu terminal (Terminal.app, iTerm2, Warp, etc.)
# 3. Se PRIVACY_MODE=false, vá também em: Screen Recording
# 4. Adicione seu terminal
