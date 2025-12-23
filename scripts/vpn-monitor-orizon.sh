#!/bin/bash

# VPN Monitor - Órizon
# Monitora conexão VPN FortiClient e reconecta automaticamente
# Com clique automático no botão Connect + restauração de contexto
# Versão: 2.0 com 95% de automação

# ============================================
# CONFIGURAÇÕES
# ============================================

# UUID da conexão VPN (obter com: scutil --nc list)
FORTICLIENT_UUID="2617CE22-5F83-46EA-9EA3-4B9DADEC75A6"

# Interface VPN (geralmente utun7 para FortiClient)
VPN_INTERFACE="utun7"

# Intervalo de verificação em segundos
CHECK_INTERVAL=5

# Arquivo de lock para evitar múltiplas instâncias
LOCK_FILE="$HOME/tmp/.vpn-monitor.lock"

# Arquivo de log
LOG_FILE="$HOME/tmp/vpn-monitor.log"

# Habilitar reconexão automática
AUTO_RECONNECT=true

# ============================================
# FUNÇÕES
# ============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Verificar se VPN está conectada usando scutil
check_vpn_status() {
    local status=$(scutil --nc status "$FORTICLIENT_UUID" 2>/dev/null)
    if echo "$status" | grep -q "Connected"; then
        return 0
    else
        return 1
    fi
}

# Verificar interface de rede (backup check)
check_vpn_interface() {
    if ifconfig "$VPN_INTERFACE" 2>/dev/null | grep -q "inet 172\.22\."; then
        return 0
    else
        return 1
    fi
}

# Dupla verificação
is_vpn_connected() {
    if check_vpn_status && check_vpn_interface; then
        return 0
    else
        return 1
    fi
}

# Alertas quando VPN desconecta
alert_disconnection() {
    log "⚠️  VPN DESCONECTADA - Iniciando alertas..."
    
    # Alerta de voz em português (V P N espaçado para pronunça correta)
    say -v Luciana "Atenção! A V P N da Órizon foi desconectada. Iniciando reconexão automática." &
    
    # Som de alerta
    afplay /System/Library/Sounds/Glass.aiff &
    
    # Notificação do sistema
    osascript -e 'display notification "VPN desconectada! Reconectando automaticamente..." with title "VPN Monitor Órizon" sound name "Glass"' &
    
    log "📢 Alertas enviados"
}

# Confirmar reconexão
alert_reconnection() {
    log "✅ VPN RECONECTADA!"
    
    # Alerta de confirmação em português (V P N espaçado)
    say -v Luciana "V P N da Órizon reconectada com sucesso" &
    
    # Som de sucesso
    afplay /System/Library/Sounds/Hero.aiff &
    
    # Notificação
    osascript -e 'display notification "VPN reconectada com sucesso!" with title "VPN Monitor Órizon" sound name "Hero"' &
}

# Abrir FortiClient
open_forticlient() {
    log "🚀 Abrindo FortiClient..."
    open -a "FortiClient"
    sleep 2
    log "✅ FortiClient aberto"
}

# Executar clique automático
auto_click_connect() {
    log "🖱️  Executando clique automático no botão Connect..."
    
    # Caminho do script de clique
    local CLICK_SCRIPT="$HOME/GitHub/VPN-automate/scripts/auto-click-connect.sh"
    
    if [ -f "$CLICK_SCRIPT" ]; then
        # Salva contexto antes de executar (para restauração final)
        SAVED_APP=$(osascript 2>/dev/null <<'EOF'
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
        
        # Executa o script de clique
        "$CLICK_SCRIPT" >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            log "✅ Clique automático executado com sucesso"
            
            # Alerta para aprovar no celular  
            say -v Luciana "Aprove a conexão da V P N no seu celular" &
            osascript -e 'display notification "Aprove a conexão VPN no seu celular" with title "VPN Monitor Órizon - MFA"' &
            
            return 0
        else
            log "❌ Erro ao executar clique automático"
            return 1
        fi
    else
        log "⚠️  Script de clique não encontrado: $CLICK_SCRIPT"
        log "ℹ️  Clique manualmente no botão Connect"
        return 1
    fi
}

# Fechar FortiClient após conexão bem-sucedida
close_forticlient() {
    log "🔄 Fechando FortiClient..."
    sleep 2
    
    # Fecha a janela com Command+W
    osascript <<'EOF' 2>/dev/null
tell application "System Events"
    tell process "FortiClient"
        if exists window "FortiClient -- Zero Trust Fabric Agent" then
            keystroke "w" using {command down}
        end if
    end tell
end tell
EOF
    
    log "✅ FortiClient fechado"
}

# Restauração final de foco
restore_final_focus() {
    if [ -n "$SAVED_APP" ]; then
        local APP_NAME=$(echo "$SAVED_APP" | cut -d'|' -f1)
        local APP_BUNDLE=$(echo "$SAVED_APP" | cut -d'|' -f2)
        
        if [ "$APP_NAME" != "FortiClient" ]; then
            log "🔄 Restauração final de foco: $APP_NAME"
            
            sleep 1
            
            # Tenta por Bundle ID primeiro
            if [ -n "$APP_BUNDLE" ]; then
                osascript 2>/dev/null <<EOF
try
    tell application id "$APP_BUNDLE" to activate
end try
EOF
                if [ $? -eq 0 ]; then
                    log "↩️  Foco restaurado (via bundle ID)"
                    return 0
                fi
            fi
            
            # Fallback: tenta por nome
            osascript 2>/dev/null <<EOF
tell application "$APP_NAME" to activate
EOF
            log "↩️  Foco restaurado (via nome)"
        fi
    fi
}

# Reconexão automática completa
attempt_reconnection() {
    log "🔄 Iniciando processo de reconexão automática..."
    
    # 1. Alertas
    alert_disconnection
    
    # 2. Abrir FortiClient
    open_forticlient
    
    # 3. Clique automático
    if auto_click_connect; then
        # 4. Aguardar conexão (até 30 segundos)
        log "⏳ Aguardando conexão (aprovação MFA)..."
        local attempts=0
        local max_attempts=30
        
        while [ $attempts -lt $max_attempts ]; do
            sleep 1
            attempts=$((attempts + 1))
            
            if is_vpn_connected; then
                log "✅ VPN reconectada após $attempts segundos"
                
                # 5. Fechar FortiClient
                close_forticlient
                
                # 6. Restauração final de foco
                restore_final_focus
                
                # 7. Alerta de sucesso
                alert_reconnection
                
                return 0
            fi
        done
        
        log "⚠️  Timeout aguardando reconexão ($max_attempts segundos)"
        log "ℹ️  Verifique se você aprovou no celular"
        return 1
    else
        log "⚠️  Clique automático falhou. Clique manualmente no botão Connect."
        return 1
    fi
}

# ============================================
# SETUP E VERIFICAÇÕES
# ============================================

# Criar diretórios necessários
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOCK_FILE")"

# Verificar se já está rodando
if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "❌ Monitor já está rodando (PID: $OLD_PID)"
        echo "   Para parar: pkill -f vpn-monitor-orizon"
        echo "   Para reiniciar: ~/GitHub/VPN-automate/scripts/restart-monitor.sh"
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi

# Criar lock file
echo $$ > "$LOCK_FILE"

# Limpar lock file ao sair
trap "rm -f '$LOCK_FILE'; log '🛑 Monitor parado'" EXIT INT TERM

# ============================================
# INÍCIO DO MONITOR
# ============================================

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚀 VPN Monitor Órizon - Versão 2.0 (95% automação)"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "UUID: $FORTICLIENT_UUID"
log "Interface: $VPN_INTERFACE"
log "Intervalo: ${CHECK_INTERVAL}s"
log "Auto-reconnect: $AUTO_RECONNECT"
log "PID: $$"
log "Log: $LOG_FILE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar se VPN está conectada inicialmente
if is_vpn_connected; then
    log "✅ VPN já está conectada - Iniciando monitoramento..."
else
    log "⚠️  VPN desconectada no início - Aguardando conexão manual ou desconexão para reconectar..."
fi

# Flag para controlar reconexão
RECONNECT_ATTEMPTED=false
LAST_STATE="unknown"

# ============================================
# LOOP PRINCIPAL DE MONITORAMENTO
# ============================================

while true; do
    if is_vpn_connected; then
        # VPN está conectada
        if [ "$LAST_STATE" != "connected" ]; then
            log "✅ VPN conectada"
            LAST_STATE="connected"
            RECONNECT_ATTEMPTED=false
        fi
    else
        # VPN está desconectada
        if [ "$LAST_STATE" != "disconnected" ]; then
            log "⚠️  VPN desconectada detectada!"
            LAST_STATE="disconnected"
        fi
        
        # Tentar reconectar (apenas uma vez por desconexão)
        if [ "$AUTO_RECONNECT" = true ] && [ "$RECONNECT_ATTEMPTED" = false ]; then
            RECONNECT_ATTEMPTED=true
            attempt_reconnection
        fi
    fi
    
    # Aguardar próxima verificação
    sleep "$CHECK_INTERVAL"
done
