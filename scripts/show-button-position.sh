#!/bin/bash

echo "🔍 Mostrando posição da janela FortiClient e botão calculado"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Abrir FortiClient se não estiver aberto
if ! pgrep -x "FortiClient" > /dev/null; then
    echo "🚀 Abrindo FortiClient..."
    open -a "FortiClient"
    sleep 3
else
    echo "✅ FortiClient já está aberto"
fi

echo ""

# Detectar janela
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
    exit 1
fi

read -r WIN_X WIN_Y WIN_WIDTH WIN_HEIGHT <<< "$WINDOW_INFO"

echo "📏 Informações da Janela FortiClient:"
echo "   Posição: X=$WIN_X, Y=$WIN_Y"
echo "   Tamanho: ${WIN_WIDTH}x${WIN_HEIGHT}"
echo ""

# Carregar config
CONFIG_FILE="$HOME/GitHub/mac-Forticlient-automation/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo "⚙️  Configuração Atual:"
echo "   PRIVACY_MODE: $PRIVACY_MODE"
echo ""

if [ "$PRIVACY_MODE" = "true" ]; then
    echo "📍 Modo: Coordenadas Fixas"
    echo "   BUTTON_OFFSET_X: $BUTTON_OFFSET_X"
    echo "   BUTTON_OFFSET_Y: $BUTTON_OFFSET_Y"
    echo ""
    BUTTON_X=$((WIN_X + BUTTON_OFFSET_X))
    BUTTON_Y=$((WIN_Y + BUTTON_OFFSET_Y))
else
    echo "📍 Modo: Auto-detecção (visão computacional)"
    echo ""
    echo "   Tentando detectar botão..."
    DETECTOR_SCRIPT="$HOME/GitHub/mac-Forticlient-automation/scripts/find-connect-button.py"
    if [ -f "$DETECTOR_SCRIPT" ] && command -v python3 &>/dev/null; then
        if $DETECTOR_SCRIPT &>/dev/null 2>&1; then
            if [ -f "/tmp/forticlient-button-coords.json" ]; then
                BUTTON_X=$(python3 -c "import json; print(json.load(open('/tmp/forticlient-button-coords.json'))['absolute_x'])" 2>/dev/null)
                BUTTON_Y=$(python3 -c "import json; print(json.load(open('/tmp/forticlient-button-coords.json'))['absolute_y'])" 2>/dev/null)
                echo "   ✅ Botão detectado!"
            else
                echo "   ❌ Falha ao criar arquivo de coordenadas"
                BUTTON_X=$((WIN_X + 552))
                BUTTON_Y=$((WIN_Y + 525))
                echo "   📍 Usando coordenadas padrão"
            fi
        else
            echo "   ❌ Erro ao executar detector"
            BUTTON_X=$((WIN_X + 552))
            BUTTON_Y=$((WIN_Y + 525))
            echo "   📍 Usando coordenadas padrão"
        fi
    else
        echo "   ⚠️  Detector não disponível"
        BUTTON_X=$((WIN_X + 552))
        BUTTON_Y=$((WIN_Y + 525))
        echo "   📍 Usando coordenadas padrão"
    fi
fi

echo ""
echo "🎯 Posição Calculada do Botão Connect:"
echo "   X: $BUTTON_X"
echo "   Y: $BUTTON_Y"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📸 Agora vou mover o mouse até a posição calculada por 3 segundos"
echo "   OBSERVE se o mouse vai para o botão Connect correto!"
echo ""
echo "Pressione ENTER para mover o mouse..."
read -r

# Salvar posição atual
ORIG_POS=$(cliclick p 2>/dev/null)
echo "💾 Posição atual do mouse: $ORIG_POS"
echo ""
echo "🖱️  Movendo mouse para ($BUTTON_X, $BUTTON_Y)..."
cliclick m:$BUTTON_X,$BUTTON_Y

echo ""
echo "⏰ Aguarde 3 segundos (observe onde está o mouse)..."
sleep 3

echo ""
echo "🔄 Restaurando posição do mouse..."
cliclick m:$ORIG_POS

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Teste concluído!"
echo ""
echo "❓ O mouse foi para o botão Connect correto?"
echo ""
echo "Se NÃO:"
echo "  1. Anote onde o mouse foi parar"
echo "  2. Me diga onde está o botão Connect (mais acima/abaixo, esquerda/direita)"
echo "  3. Podemos ajustar os offsets no config.sh"
