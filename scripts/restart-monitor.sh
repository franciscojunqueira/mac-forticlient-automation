#!/bin/bash

# Script para reiniciar o monitor VPN de forma limpa

echo "🔄 Reiniciando VPN Monitor..."

# Matar todas as instâncias
echo "🛑 Parando instâncias antigas..."
pkill -9 -f vpn-monitor-orizon 2>/dev/null
sleep 1

# Remover lockfile
rm -f ~/tmp/.vpn-monitor.lock

# Verificar se ainda há processos
if pgrep -f vpn-monitor > /dev/null; then
    echo "⚠️  Ainda há processos rodando. Tentando matar novamente..."
    pkill -9 -f vpn-monitor-orizon
    sleep 2
fi

# Confirmar limpeza
if pgrep -f vpn-monitor > /dev/null; then
    echo "❌ Não foi possível parar todos os processos. Reinicie o Mac."
    exit 1
fi

echo "✅ Todos os processos parados"
echo ""

# Iniciar novo monitor
echo "🚀 Iniciando monitor..."
mkdir -p ~/tmp
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
NEW_PID=$!

sleep 2

# Verificar se iniciou
if ps -p $NEW_PID > /dev/null 2>&1; then
    echo "✅ Monitor iniciado com sucesso (PID: $NEW_PID)"
    echo ""
    echo "📊 Ver logs em tempo real:"
    echo "   tail -f ~/tmp/vpn-monitor.log"
    echo ""
    echo "🛑 Para parar:"
    echo "   pkill -f vpn-monitor-orizon"
else
    echo "❌ Falha ao iniciar monitor"
    exit 1
fi
