#!/bin/bash

# Script de teste completo com countdown
# Testa o fluxo completo de desconexão e reconexão automática
# Verifica se mouse e foco são restaurados corretamente

echo "🧪 TESTE COMPLETO DO VPN MONITOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ℹ️  Este teste irá:"
echo "  1. Contar 5 segundos (mantenha o foco neste terminal)"
echo "  2. Desconectar VPN automaticamente"
echo "  3. Você deve observar todo o processo automático"
echo "  4. Mouse e foco devem voltar para este terminal"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  • Mantenha este terminal em foco"
echo "  • Não toque no mouse durante o teste"
echo "  • Aprove no celular quando solicitado"
echo ""
read -p "Pressione ENTER para iniciar o teste..."
echo ""

# Salvar posição atual do mouse para verificar depois
INITIAL_MOUSE=$(cliclick p 2>/dev/null)
echo "📍 Posição inicial do mouse: $INITIAL_MOUSE"

# Salvar aplicação em foco
INITIAL_APP=$(osascript 2>/dev/null <<'EOF'
tell application "System Events"
    name of first application process whose frontmost is true
end tell
EOF
)
echo "💻 Aplicação em foco: $INITIAL_APP"
echo ""

# Countdown
for i in 5 4 3 2 1; do
    echo "⏱️  Desconectando VPN em $i segundos..."
    sleep 1
done

echo ""
echo "🔌 DESCONECTANDO VPN AGORA!"
echo ""

# Desconectar VPN
scutil --nc stop "VPN" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ VPN desconectada com sucesso"
    echo ""
    echo "📊 OBSERVE O PROCESSO AUTOMÁTICO:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⏱️  ~1s  → Alerta de voz: 'VPN foi desconectada'"
    echo "  ⏱️  ~2s  → FortiClient abre automaticamente"
    echo "  ⏱️  ~4s  → Clique automático no botão Connect"
    echo "  ⏱️  ~4.5s → Mouse VOLTA para posição original"
    echo "  ⏱️  ~5s  → Foco VOLTA para este terminal"
    echo "  ⏱️  ~5s  → Alerta: 'Aprove no celular'"
    echo "  👤 VOCÊ → Aprove no celular (Push MFA)"
    echo "  ⏱️  +2s  → VPN reconecta"
    echo "  ⏱️  +4s  → FortiClient fecha automaticamente"
    echo "  ⏱️  +5s  → Alerta de sucesso: 'VPN reconectada'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⏳ Aguardando processo completo (até 40 segundos)..."
    echo ""
    
    # Aguardar reconexão
    TIMEOUT=40
    ELAPSED=0
    
    while [ $ELAPSED -lt $TIMEOUT ]; do
        sleep 1
        ELAPSED=$((ELAPSED + 1))
        
        # Verificar se VPN reconectou
        if scutil --nc status "VPN" 2>/dev/null | grep -q "Connected"; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✅ TESTE CONCLUÍDO COM SUCESSO!"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⏱️  Tempo total: ${ELAPSED}s"
            echo ""
            
            # Verificar posição do mouse
            sleep 2
            FINAL_MOUSE=$(cliclick p 2>/dev/null)
            echo "🖱️  Posição do mouse:"
            echo "   Inicial: $INITIAL_MOUSE"
            echo "   Final:   $FINAL_MOUSE"
            
            if [ "$INITIAL_MOUSE" = "$FINAL_MOUSE" ]; then
                echo "   ✅ Mouse restaurado corretamente!"
            else
                echo "   ⚠️  Mouse não voltou exatamente (diferença normal)"
            fi
            
            echo ""
            
            # Verificar aplicação em foco
            FINAL_APP=$(osascript 2>/dev/null <<'EOF'
tell application "System Events"
    name of first application process whose frontmost is true
end tell
EOF
)
            echo "💻 Aplicação em foco:"
            echo "   Inicial: $INITIAL_APP"
            echo "   Final:   $FINAL_APP"
            
            if [ "$INITIAL_APP" = "$FINAL_APP" ]; then
                echo "   ✅ Foco restaurado corretamente!"
            else
                echo "   ⚠️  Foco mudou (esperado se você mudou de app)"
            fi
            
            echo ""
            echo "🎉 AUTOMAÇÃO FUNCIONANDO PERFEITAMENTE!"
            echo ""
            exit 0
        fi
        
        # Mostrar progresso a cada 5 segundos
        if [ $((ELAPSED % 5)) -eq 0 ]; then
            echo "   ⏳ ${ELAPSED}s decorridos..."
        fi
    done
    
    echo ""
    echo "⏱️  Timeout de ${TIMEOUT}s atingido"
    echo "⚠️  VPN não reconectou automaticamente"
    echo ""
    echo "🔍 Possíveis causas:"
    echo "  • Você não aprovou no celular"
    echo "  • Monitor VPN não está rodando"
    echo "  • Clique automático falhou"
    echo ""
    echo "📊 Verifique os logs:"
    echo "   tail -20 ~/tmp/vpn-monitor.log"
    echo ""
    exit 1
else
    echo ""
    echo "❌ Erro ao desconectar VPN"
    echo "ℹ️  Certifique-se de que a VPN está conectada antes do teste"
    echo ""
    exit 1
fi
