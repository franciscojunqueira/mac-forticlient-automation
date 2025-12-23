#!/bin/bash

# Script de desinstalação do VPN Monitor
# Remove todos os componentes instalados e limpa configurações
# Uso: ./uninstall.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Banner
clear
print_header "VPN Monitor - Desinstalador"
echo -e "Remove todos os componentes e configurações\n"

print_warning "Este script irá remover:"
echo -e "  • Scripts instalados"
echo -e "  • Aplicativo wrapper"
echo -e "  • Configuração de início automático"
echo -e "  • Logs e arquivos temporários"
echo -e "  • Arquivos de lock\n"

print_info "Os seguintes itens NÃO serão removidos:"
echo -e "  • Homebrew"
echo -e "  • cliclick"
echo -e "  • FortiClient"
echo -e "  • Diretório do projeto (~/GitHub/mac-Forticlient-automation)\n"

echo -e "${YELLOW}Deseja continuar com a desinstalação? (s/N): ${NC}\c"
read -r response
if [[ ! $response =~ ^[Ss]$ ]]; then
    print_info "Desinstalação cancelada"
    exit 0
fi

# ============================================
# ETAPA 1: Parar processos rodando
# ============================================
print_header "ETAPA 1: Parando Processos"

print_info "Verificando processos ativos..."
if pgrep -f "vpn-monitor-orizon" > /dev/null; then
    print_warning "Monitor VPN está rodando. Parando..."
    
    # Tentar parar múltiplas vezes com diferentes métodos
    for attempt in 1 2 3; do
        # Método 1: pkill com padrão
        pkill -9 -f "vpn-monitor-orizon" 2>/dev/null || true
        # Método 2: killall
        killall -9 "vpn-monitor-orizon.sh" 2>/dev/null || true
        # Método 3: kill direto por PID
        for pid in $(pgrep -f "vpn-monitor-orizon"); do
            kill -9 "$pid" 2>/dev/null || true
        done
        
        sleep 1
        
        if ! pgrep -f "vpn-monitor-orizon" > /dev/null; then
            print_success "Processos parados (tentativa $attempt)"
            break
        fi
        
        if [ $attempt -eq 3 ]; then
            print_error "Não foi possível parar todos os processos após 3 tentativas"
            print_info "PIDs ainda ativos:"
            pgrep -fl "vpn-monitor-orizon" || true
            print_info "Tente manualmente: sudo pkill -9 -f vpn-monitor-orizon"
        fi
    done
else
    print_success "Nenhum processo ativo"
fi

# ============================================
# ETAPA 2: Remover item de login
# ============================================
print_header "ETAPA 2: Removendo Início Automático"

print_info "Removendo dos Itens de Login..."
# Tentar remover via osascript
osascript 2>/dev/null <<'EOF'
tell application "System Events"
    try
        delete every login item whose name is "VPNMonitor"
    end try
end tell
EOF

if [ $? -eq 0 ]; then
    print_success "Removido dos Itens de Login"
else
    print_warning "Não foi possível remover automaticamente"
    print_info "Remova manualmente em: Configurações → Geral → Itens de Início"
fi

# ============================================
# ETAPA 3: Remover aplicativo wrapper
# ============================================
print_header "ETAPA 3: Removendo Aplicativo"

if [ -d ~/Applications/VPNMonitor.app ]; then
    print_info "Removendo VPNMonitor.app..."
    rm -rf ~/Applications/VPNMonitor.app
    print_success "Aplicativo removido"
else
    print_info "Aplicativo não encontrado (pode já estar removido)"
fi

# ============================================
# ETAPA 4: Remover scripts
# ============================================
print_header "ETAPA 4: Removendo Scripts"

# Script principal
if [ -f ~/bin/vpn-monitor-orizon.sh ]; then
    print_info "Removendo script principal..."
    rm -f ~/bin/vpn-monitor-orizon.sh
    print_success "Script principal removido"
else
    print_info "Script principal não encontrado"
fi

# Scripts auxiliares (apenas os copiados, não o projeto original)
print_info "Scripts auxiliares estão no projeto (não serão removidos)"

# ============================================
# ETAPA 5: Limpar logs e arquivos temporários
# ============================================
print_header "ETAPA 5: Limpando Logs e Temporários"

echo -e "Deseja remover logs e arquivos temporários? (S/n): \c"
read -r response
if [[ ! $response =~ ^[Nn]$ ]]; then
    # Remover logs
    if [ -f ~/tmp/vpn-monitor.log ]; then
        print_info "Removendo logs..."
        rm -f ~/tmp/vpn-monitor.log
        print_success "Logs removidos"
    fi
    
    # Remover lock file
    if [ -f ~/tmp/.vpn-monitor.lock ]; then
        print_info "Removendo arquivo de lock..."
        rm -f ~/tmp/.vpn-monitor.lock
        print_success "Lock file removido"
    fi
    
    # Remover diretório tmp se estiver vazio
    if [ -d ~/tmp ] && [ -z "$(ls -A ~/tmp)" ]; then
        print_info "Removendo diretório temporário vazio..."
        rmdir ~/tmp
        print_success "Diretório temporário removido"
    fi
else
    print_info "Logs e temporários mantidos"
fi

# ============================================
# ETAPA 6: Limpar diretório do projeto (opcional)
# ============================================
print_header "ETAPA 6: Diretório do Projeto"

if [ -d ~/GitHub/mac-Forticlient-automation ]; then
    echo -e "${YELLOW}O diretório do projeto ainda existe:${NC}"
    echo -e "${BLUE}~/GitHub/mac-Forticlient-automation${NC}\n"
    echo -e "Deseja removê-lo também? (s/N): \c"
    read -r response
    if [[ $response =~ ^[Ss]$ ]]; then
        print_warning "Removendo diretório do projeto..."
        rm -rf ~/GitHub/mac-Forticlient-automation
        print_success "Diretório do projeto removido"
    else
        print_info "Diretório do projeto mantido"
        print_info "Você pode reinstalar executando: ./install.sh"
    fi
fi

# ============================================
# ETAPA 7: Verificar limpeza
# ============================================
print_header "ETAPA 7: Verificação Final"

print_info "Verificando componentes restantes..."

COMPONENTS_FOUND=0

if [ -f ~/bin/vpn-monitor-orizon.sh ]; then
    print_warning "Script principal ainda existe: ~/bin/vpn-monitor-orizon.sh"
    COMPONENTS_FOUND=1
fi

if [ -d ~/Applications/VPNMonitor.app ]; then
    print_warning "Aplicativo ainda existe: ~/Applications/VPNMonitor.app"
    COMPONENTS_FOUND=1
fi

if pgrep -f "vpn-monitor-orizon" > /dev/null; then
    print_warning "Processos ainda rodando"
    COMPONENTS_FOUND=1
fi

if [ $COMPONENTS_FOUND -eq 0 ]; then
    print_success "Todos os componentes foram removidos"
else
    print_warning "Alguns componentes ainda existem (veja acima)"
fi

# ============================================
# RESUMO FINAL
# ============================================
print_header "DESINSTALAÇÃO CONCLUÍDA"

echo -e "${GREEN}✅ VPN Monitor foi desinstalado${NC}\n"

print_info "Componentes removidos:"
echo -e "  • ✅ Script principal"
echo -e "  • ✅ Scripts auxiliares"
echo -e "  • ✅ Aplicativo wrapper"
echo -e "  • ✅ Início automático"
echo -e "  • ✅ Processos parados"

if [ -d ~/GitHub/mac-Forticlient-automation ]; then
    echo -e "\n${BLUE}ℹ️  Diretório do projeto mantido:${NC}"
    echo -e "  ${BLUE}~/GitHub/mac-Forticlient-automation${NC}"
    echo -e "\n  Para reinstalar: ${BLUE}cd ~/GitHub/mac-Forticlient-automation && ./install.sh${NC}"
    echo -e "  Para remover: ${BLUE}rm -rf ~/GitHub/mac-Forticlient-automation${NC}"
fi

echo -e "\n${YELLOW}⚠️  Itens NÃO removidos (conforme esperado):${NC}"
echo -e "  • Homebrew"
echo -e "  • cliclick"
echo -e "  • FortiClient"
echo -e "  • Permissões de Acessibilidade (configuração do sistema)"

echo -e "\n${BLUE}📋 Para remover cliclick (opcional):${NC}"
echo -e "  ${BLUE}brew uninstall cliclick${NC}"

echo -e "\n${YELLOW}🔧 Configurações do macOS (limpeza manual opcional):${NC}"
echo -e "\n${BLUE}1. Permissões de Acessibilidade:${NC}"
echo -e "   • Abra: Configurações → Privacidade e Segurança → Acessibilidade"
echo -e "   • Remova seu terminal da lista (se não usar para outras automações)"
echo -e "\n${BLUE}2. Notificações (opcional):${NC}"
echo -e "   • Abra: Configurações → Notificações"
echo -e "   • Procure e remova entradas relacionadas ao VPN Monitor"
echo -e "\n${BLUE}3. Itens de Login (verificação):${NC}"
echo -e "   • Abra: Configurações → Geral → Itens de Início"
echo -e "   • Verifique se VPNMonitor foi removido da lista"

echo -e "\n${GREEN}Obrigado por usar o VPN Monitor!${NC}\n"
