#!/bin/bash

# Script para clicar automaticamente no botão Connect do FortiClient
# Versão 2.0: Com restauração completa de contexto e suporte multi-monitor
# - Coordenadas negativas via CoreGraphics
# - Bundle ID para restauração de foco confiável
# - Restauração dupla de foco (imediata + após modal MFA)

echo "🖱️  Clicando automaticamente no botão Connect..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================
# ETAPA 1: SALVAR CONTEXTO DO USUÁRIO
# ============================================

# Salva aplicação em foco (nome + bundle ID para confiabilidade)
APP_INFO=$(osascript 2>/dev/null <<'EOF'
tell application "System Events"
    set frontProc to first application process whose frontmost is true
    set appName to name of frontProc
    try
        set appBundle to bundle identifier of frontProc
    on error
        set appBundle to ""
    end try
    return appName & "|" & appBundle
end tell
EOF
)

if [ -n "$APP_INFO" ]; then
    ORIG_APP=$(echo "$APP_INFO" | cut -d'|' -f1)
    ORIG_BUNDLE=$(echo "$APP_INFO" | cut -d'|' -f2)
    echo "💾 Aplicação em foco: $ORIG_APP"
    [ -n "$ORIG_BUNDLE" ] && echo "💾 Bundle ID: $ORIG_BUNDLE"
fi

# Salva posição atual do mouse (pode ser coordenada negativa)
ORIG_MOUSE_POS=$(cliclick p 2>/dev/null)
if [ -n "$ORIG_MOUSE_POS" ]; then
    echo "💾 Posição do mouse: $ORIG_MOUSE_POS"
    
    # Extrai X e Y para usar com CoreGraphics se necessário
    ORIG_MOUSE_X=$(echo "$ORIG_MOUSE_POS" | cut -d',' -f1)
    ORIG_MOUSE_Y=$(echo "$ORIG_MOUSE_POS" | cut -d',' -f2)
fi

echo ""

# ============================================
# ETAPA 2: ATIVAR FORTICLIENT
# ============================================

# Ativa o FortiClient
osascript <<'EOF' 2>/dev/null
tell application "FortiClient" to activate
delay 0.5
EOF

# Aguarda janela estar visível
sleep 1.5

# ============================================
# ETAPA 3: DETECTAR POSIÇÃO DA JANELA
# ============================================

# Pega posição e tamanho da janela do FortiClient
# IMPORTANTE: Sempre obtém posição atual da janela dinamicamente
# Funciona independente de qual monitor ou posição a janela esteja
WINDOW_INFO=$(osascript 2>/dev/null <<'EOF'
tell application "System Events"
    tell process "FortiClient"
        try
            if exists window "FortiClient -- Zero Trust Fabric Agent" then
                set winPos to position of window "FortiClient -- Zero Trust Fabric Agent"
                set winSize to size of window "FortiClient -- Zero Trust Fabric Agent"
                set x to item 1 of winPos as integer
                set y to item 2 of winPos as integer
                set w to item 1 of winSize as integer
                set h to item 2 of winSize as integer
                return (x as text) & " " & (y as text) & " " & (w as text) & " " & (h as text)
            else
                return "ERROR"
            end if
        on error
            return "ERROR"
        end try
    end tell
end tell
EOF
)

if [ "$WINDOW_INFO" = "ERROR" ]; then
    echo "❌ Janela FortiClient não encontrada"
    exit 1
fi

# Extrai posição e tamanho
read -r WIN_X WIN_Y WIN_WIDTH WIN_HEIGHT <<< "$WINDOW_INFO"

echo "📏 Janela: ${WIN_WIDTH}x${WIN_HEIGHT} em ($WIN_X, $WIN_Y)"

# ============================================
# ETAPA 4: CALCULAR E EXECUTAR CLIQUE
# ============================================

# Calcula posição do botão Connect usando OFFSET FIXO
# Calibrado manualmente: 552 pixels à direita, 525 pixels abaixo
# Mais confiável que porcentagem pois o botão não muda de posição
# Funciona em qualquer posição de janela, qualquer monitor
BUTTON_X=$((WIN_X + 552))
BUTTON_Y=$((WIN_Y + 525))

echo "🎯 Posição do botão: ($BUTTON_X, $BUTTON_Y)"
echo ""

# Move mouse e clica
echo "🖱️  Movendo mouse..."
cliclick m:$BUTTON_X,$BUTTON_Y
sleep 0.2

echo "👆 Clicando..."
cliclick c:$BUTTON_X,$BUTTON_Y

echo "✅ Clique executado!"
echo ""

# ============================================
# ETAPA 5: RESTAURAÇÃO IMEDIATA (Mouse)
# ============================================

# Restaura mouse imediatamente (0.2s após clique)
sleep 0.2

if [ -n "$ORIG_MOUSE_X" ] && [ -n "$ORIG_MOUSE_Y" ]; then
    echo "🔄 Restaurando mouse..."
    
    # Verifica se coordenadas são negativas (multi-monitor)
    if [[ "$ORIG_MOUSE_X" =~ ^-.*$ ]] || [[ "$ORIG_MOUSE_Y" =~ ^-.*$ ]]; then
        # Usa CoreGraphics via JavaScript ObjC Bridge para coordenadas negativas
        echo "   (usando CoreGraphics para coordenadas negativas)"
        osascript -l JavaScript 2>/dev/null <<EOF
ObjC.import('CoreGraphics');
var point = {x: $ORIG_MOUSE_X, y: $ORIG_MOUSE_Y};
$.CGWarpMouseCursorPosition(point);
EOF
    else
        # Usa cliclick para coordenadas positivas (mais rápido)
        cliclick m:$ORIG_MOUSE_POS 2>/dev/null
    fi
    
    echo "↩️  Mouse restaurado: $ORIG_MOUSE_POS"
fi

echo ""

# ============================================
# ETAPA 6: AGUARDAR MODAL MFA
# ============================================

echo "⏳ Aguardando janela modal MFA (2s)..."
sleep 2

# ============================================
# ETAPA 7: RESTAURAÇÃO DE FOCO (Etapa 1)
# ============================================

if [ -n "$ORIG_APP" ] && [ "$ORIG_APP" != "FortiClient" ]; then
    echo "🔄 Restaurando foco para aplicação original..."
    
    # Tenta primeiro por Bundle ID (mais confiável)
    if [ -n "$ORIG_BUNDLE" ]; then
        osascript 2>/dev/null <<EOF
try
    tell application id "$ORIG_BUNDLE" to activate
end try
EOF
        if [ $? -eq 0 ]; then
            echo "↩️  Foco restaurado: $ORIG_APP (via bundle ID)"
        else
            # Fallback: tenta por nome
            osascript 2>/dev/null <<EOF
tell application "$ORIG_APP" to activate
EOF
            echo "↩️  Foco restaurado: $ORIG_APP (via nome)"
        fi
    else
        # Sem bundle ID, usa nome
        osascript 2>/dev/null <<EOF
tell application "$ORIG_APP" to activate
EOF
        echo "↩️  Foco restaurado: $ORIG_APP"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Aprove a conexão no celular"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ℹ️  O monitor VPN irá:"
echo "  • Aguardar você aprovar no celular"
echo "  • Detectar quando VPN reconectar"
echo "  • Fechar FortiClient automaticamente"
echo "  • Restaurar foco novamente para sua aplicação"
echo ""

exit 0
