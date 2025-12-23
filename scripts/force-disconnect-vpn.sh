#!/bin/bash

# Script para forçar desconexão da VPN (para testes)
# Útil para verificar se o monitor detecta e reconecta automaticamente

echo "🔌 Desconectando VPN para teste..."

# Desconectar usando scutil
scutil --nc stop "VPN" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ VPN desconectada"
    echo ""
    echo "📊 Aguarde ~5 segundos e observe:"
    echo "  1. Alerta de voz em português"
    echo "  2. FortiClient abre automaticamente"
    echo "  3. Clique automático no botão Connect"
    echo "  4. Mouse e foco voltam para onde estavam"
    echo "  5. Notificação para aprovar no celular"
    echo "  6. Após aprovar: FortiClient fecha"
    echo "  7. Alerta de sucesso"
else
    echo "❌ Erro ao desconectar VPN"
    echo "ℹ️  Tente: scutil --nc stop \"VPN\""
fi
