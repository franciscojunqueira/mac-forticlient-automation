#!/bin/bash

# Script de diagnóstico para FortiClient
# Verifica janela, posição do botão e capacidade de clique

echo "🔍 Diagnóstico FortiClient - Detecção de Botão Connect"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar se FortiClient está instalado
if [ ! -d "/Applications/FortiClient.app" ]; then
    echo "❌ FortiClient não encontrado em /Applications/"
    exit 1
fi
echo "✅ FortiClient instalado"
echo ""

# Abrir FortiClient
echo "🚀 Abrindo FortiClient..."
open -a "FortiClient"
sleep 3

# Verificar se janela está aberta
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
                return "NOT_FOUND"
            end if
        on error
            return "ERROR"
        end try
    end tell
end tell
EOF
)

if [ "$WINDOW_INFO" = "ERROR" ] || [ "$WINDOW_INFO" = "NOT_FOUND" ]; then
    echo "❌ Janela FortiClient não encontrada"
    echo ""
    echo "ℹ️  Janelas disponíveis:"
    osascript 2>/dev/null <<'EOF'
tell application "System Events"
    tell process "FortiClient"
        try
            repeat with w in (every window)
                log name of w
            end repeat
        end try
    end tell
end tell
EOF
    exit 1
fi

read -r WIN_X WIN_Y WIN_WIDTH WIN_HEIGHT <<< "$WINDOW_INFO"

echo "✅ Janela detectada!"
echo "   Posição: ($WIN_X, $WIN_Y)"
echo "   Tamanho: ${WIN_WIDTH}x${WIN_HEIGHT}"
echo ""

# Carregar config para ver modo
CONFIG_FILE="$HOME/GitHub/mac-Forticlient-automation/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "📋 Configuração atual:"
    echo "   PRIVACY_MODE: $PRIVACY_MODE"
    if [ "$PRIVACY_MODE" = "true" ]; then
        echo "   BUTTON_OFFSET_X: $BUTTON_OFFSET_X"
        echo "   BUTTON_OFFSET_Y: $BUTTON_OFFSET_Y"
        
        # Calcular posição do botão
        BUTTON_X=$((WIN_X + BUTTON_OFFSET_X))
        BUTTON_Y=$((WIN_Y + BUTTON_OFFSET_Y))
        
        echo ""
        echo "🎯 Posição calculada do botão (modo fixo):"
        echo "   X: $BUTTON_X"
        echo "   Y: $BUTTON_Y"
    else
        echo ""
        echo "🔍 Modo auto-detecção ativado"
        echo "   Tentando detectar botão via visão computacional..."
        
        DETECTOR_SCRIPT="$HOME/GitHub/mac-Forticlient-automation/scripts/find-connect-button.py"
        if [ -f "$DETECTOR_SCRIPT" ] && command -v python3 &>/dev/null; then
            if $DETECTOR_SCRIPT &>/dev/null; then
                if [ -f "/tmp/forticlient-button-coords.json" ]; then
                    BUTTON_X=$(python3 -c "import json; print(json.load(open('/tmp/forticlient-button-coords.json'))['absolute_x'])")
                    BUTTON_Y=$(python3 -c "import json; print(json.load(open('/tmp/forticlient-button-coords.json'))['absolute_y'])")
                    echo "   ✅ Botão detectado via visão computacional"
                    echo ""
                    echo "🎯 Posição detectada do botão:"
                    echo "   X: $BUTTON_X"
                    echo "   Y: $BUTTON_Y"
                else
                    echo "   ❌ Falha ao detectar botão"
                fi
            else
                echo "   ❌ Erro ao executar detector"
            fi
        else
            echo "   ⚠️  Python 3 ou find-connect-button.py não encontrado"
        fi
    fi
else
    echo "⚠️  Arquivo config.sh não encontrado"
    echo "   Usando coordenadas padrão..."
    BUTTON_X=$((WIN_X + 552))
    BUTTON_Y=$((WIN_Y + 525))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🖱️  Teste de Clique"
echo ""
echo "⚠️  AVISO: O script irá mover o mouse e clicar na posição calculada!"
echo "   Se a VPN estiver desconectada, isso pode iniciar a conexão."
echo ""
echo "Deseja continuar com o teste de clique? (S/n): "
read -r response

if [[ ! $response =~ ^[Nn]$ ]]; then
    if [ -z "$BUTTON_X" ] || [ -z "$BUTTON_Y" ]; then
        echo "❌ Posição do botão não foi determinada"
        exit 1
    fi
    
    echo ""
    echo "📍 Salvando posição atual do mouse..."
    ORIG_POS=$(cliclick p 2>/dev/null)
    echo "   Posição original: $ORIG_POS"
    
    echo ""
    echo "🖱️  Movendo mouse para ($BUTTON_X, $BUTTON_Y)..."
    cliclick m:$BUTTON_X,$BUTTON_Y
    sleep 1
    
    echo "📸 Mouse está sobre o botão correto?"
    echo "   Verifique visualmente antes de continuar."
    echo ""
    echo "Pressione ENTER para clicar, ou Ctrl+C para cancelar..."
    read -r
    
    echo "👆 Clicando..."
    cliclick c:$BUTTON_X,$BUTTON_Y
    
    echo ""
    echo "✅ Clique executado!"
    echo ""
    echo "🔄 Restaurando posição do mouse..."
    cliclick m:$ORIG_POS
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Diagnóstico concluído"
    echo ""
    echo "Observações:"
    echo "  • Se o botão foi clicado corretamente: configuração OK!"
    echo "  • Se o clique foi em local errado:"
    echo "    - Modo PRIVACY_MODE=true: ajuste BUTTON_OFFSET_X/Y no config.sh"
    echo "    - Modo PRIVACY_MODE=false: verifique permissão Screen Recording"
else
    echo ""
    echo "🔄 Teste cancelado"
    echo "   Restaurando mouse para posição original..."
    # Não movemos o mouse se não fizemos o teste
fi

echo ""
echo "📝 Para mais informações, consulte:"
echo "   docs/CLICK-CALIBRATION.md"
echo "   docs/PRIVACY-MODE.md"
