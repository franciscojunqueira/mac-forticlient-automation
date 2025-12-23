#!/bin/bash

# Script de instalação completo e auto-suficiente do VPN Monitor
# Detecta automaticamente configurações e instala dependências
# Uso: ./install.sh

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
print_header "VPN Monitor - Instalador Automático v2.0"
echo -e "Sistema de monitoramento e reconexão automática"
echo -e "FortiClient + MFA - 95% de automação\n"

# Detectar diretório do projeto
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
print_info "Diretório do projeto: $PROJECT_DIR"

# ============================================
# ETAPA 1: Verificar pré-requisitos
# ============================================
print_header "ETAPA 1: Verificando Pré-requisitos"

# Verificar macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Este script é apenas para macOS"
    exit 1
fi
print_success "Sistema operacional: macOS $(sw_vers -productVersion)"

# Verificar Homebrew
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew não instalado"
    echo -e "\nDeseja instalar o Homebrew? (S/n): \c"
    read -r response
    if [[ ! $response =~ ^[Nn]$ ]]; then
        print_info "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew instalado"
    else
        print_error "Homebrew é necessário para instalar cliclick"
        exit 1
    fi
else
    print_success "Homebrew: $(brew --version | head -1)"
fi

# Verificar e instalar cliclick
if ! command -v cliclick &> /dev/null; then
    print_warning "cliclick não instalado (necessário para automação de clique)"
    echo -e "\nDeseja instalar cliclick via Homebrew? (S/n): \c"
    read -r response
    if [[ ! $response =~ ^[Nn]$ ]]; then
        print_info "Instalando cliclick..."
        brew install cliclick
        print_success "cliclick instalado"
    else
        print_error "cliclick é obrigatório para o clique automático"
        exit 1
    fi
else
    print_success "cliclick: $(cliclick -v 2>&1 | head -1 || echo 'instalado')"
fi

# Verificar FortiClient
if [ ! -d "/Applications/FortiClient.app" ]; then
    print_warning "FortiClient não encontrado em /Applications/"
    print_info "Certifique-se de instalar o FortiClient antes de usar o monitor"
else
    print_success "FortiClient: instalado"
fi

# ============================================
# ETAPA 2: Detectar configuração da VPN
# ============================================
print_header "ETAPA 2: Detectando Configuração da VPN"

# Detectar UUID da VPN
print_info "Buscando conexão VPN FortiClient..."
VPN_UUID=$(scutil --nc list 2>/dev/null | grep -i "forticlient\|VPN" | head -1 | awk '{print $2}')

if [ -n "$VPN_UUID" ]; then
    VPN_NAME=$(scutil --nc list 2>/dev/null | grep "$VPN_UUID" | sed 's/.*"\(.*\)".*/\1/')
    print_success "UUID detectado: $VPN_UUID"
    print_success "Nome: $VPN_NAME"
else
    print_warning "UUID da VPN não detectado automaticamente"
    print_info "Configure a VPN no FortiClient primeiro ou edite manualmente depois"
    VPN_UUID="CONFIGURE_MANUALLY"
fi

# Detectar interface VPN (quando conectada)
print_info "Detectando interface VPN..."
VPN_INTERFACE=""
for iface in $(ifconfig -l); do
    if [[ $iface == utun* ]]; then
        IP=$(ifconfig "$iface" 2>/dev/null | grep "inet " | awk '{print $2}')
        # Detecta IPs privados comuns (10.*, 172.16-31.*, 192.168.*)
        if [[ $IP == 10.* ]] || [[ $IP == 172.1[6-9].* ]] || [[ $IP == 172.2[0-9].* ]] || [[ $IP == 172.3[0-1].* ]] || [[ $IP == 192.168.* ]]; then
            VPN_INTERFACE=$iface
            print_success "Interface detectada: $VPN_INTERFACE (IP: $IP)"
            break
        fi
    fi
done

if [ -z "$VPN_INTERFACE" ]; then
    print_warning "Interface VPN não detectada (VPN pode estar desconectada)"
    print_info "Usando interface padrão: utun7"
    VPN_INTERFACE="utun7"
fi

# Detectar servidor VPN
print_info "Detectando servidor VPN..."
VPN_SERVER=$(scutil --nc status "$VPN_UUID" 2>/dev/null | grep "ServerAddress" | awk '{print $3}' || echo "")
if [ -n "$VPN_SERVER" ]; then
    print_success "Servidor: $VPN_SERVER"
else
    print_warning "Servidor não detectado"
fi

# ============================================
# ETAPA 3: Instalar scripts
# ============================================
print_header "ETAPA 3: Instalando Scripts"

# Criar diretórios necessários
print_info "Criando diretórios..."
mkdir -p ~/bin
mkdir -p ~/tmp
mkdir -p ~/GitHub/mac-Forticlient-automation/scripts
print_success "Diretórios criados"

# Copiar script principal
if [ -f "$PROJECT_DIR/scripts/vpn-monitor-orizon.sh" ]; then
    print_info "Copiando script principal..."
    cp "$PROJECT_DIR/scripts/vpn-monitor-orizon.sh" ~/bin/
    chmod +x ~/bin/vpn-monitor-orizon.sh

    # Atualizar UUID no script
    if [ "$VPN_UUID" != "CONFIGURE_MANUALLY" ]; then
        sed -i '' "s/FORTICLIENT_UUID=.*/FORTICLIENT_UUID=\"$VPN_UUID\"/" ~/bin/vpn-monitor-orizon.sh
        print_success "UUID configurado automaticamente no script"
    fi

    # Atualizar interface no script
    sed -i '' "s/VPN_INTERFACE=.*/VPN_INTERFACE=\"$VPN_INTERFACE\"/" ~/bin/vpn-monitor-orizon.sh
    print_success "Interface configurada: $VPN_INTERFACE"

    print_success "Script principal: ~/bin/vpn-monitor-orizon.sh"
else
    print_error "Script principal não encontrado: $PROJECT_DIR/scripts/vpn-monitor-orizon.sh"
    print_info "Você precisará criar ou copiar o script manualmente"
fi

# Copiar script de clique automático
if [ -f "$PROJECT_DIR/scripts/auto-click-connect.sh" ]; then
    print_info "Copiando script de clique automático..."
    if [ "$PROJECT_DIR/scripts/auto-click-connect.sh" != "$HOME/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh" ]; then
        cp "$PROJECT_DIR/scripts/auto-click-connect.sh" ~/GitHub/mac-Forticlient-automation/scripts/
    fi
    chmod +x ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh
    print_success "Script de clique: ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh"
else
    print_warning "Script de clique não encontrado: $PROJECT_DIR/scripts/auto-click-connect.sh"
fi

# Copiar scripts auxiliares
print_info "Copiando scripts auxiliares..."
SCRIPTS_COPIED=0
for script in restart-monitor.sh force-disconnect-vpn.sh test-disconnect-with-countdown.sh; do
    if [ -f "$PROJECT_DIR/scripts/$script" ]; then
        cp "$PROJECT_DIR/scripts/$script" ~/GitHub/mac-Forticlient-automation/scripts/
        chmod +x ~/GitHub/mac-Forticlient-automation/scripts/$script
        SCRIPTS_COPIED=$((SCRIPTS_COPIED + 1))
    fi
done
if [ $SCRIPTS_COPIED -gt 0 ]; then
    print_success "$SCRIPTS_COPIED scripts auxiliares copiados"
else
    print_warning "Nenhum script auxiliar encontrado"
fi

# ============================================
# ETAPA 4: Configurar permissões
# ============================================
print_header "ETAPA 4: Verificando Permissões"

print_warning "AÇÃO NECESSÁRIA:"
echo -e "\nPara o clique automático funcionar, você precisa conceder"
echo -e "permissões de Acessibilidade para seu terminal:\n"
echo -e "1. Abra: ${BLUE}Configurações → Privacidade e Segurança → Acessibilidade${NC}"
echo -e "2. Adicione seu terminal (Terminal.app ou Warp)"
echo -e "3. Marque a caixa de seleção\n"

echo -e "Deseja abrir as Configurações agora? (S/n): \c"
read -r response
if [[ ! $response =~ ^[Nn]$ ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    print_info "Aguardando configuração... (pressione ENTER quando concluir)"
    read -r
fi

# ============================================
# ETAPA 5: Configurar início automático
# ============================================
print_header "ETAPA 5: Início Automático"

echo -e "Deseja iniciar o monitor automaticamente no login? (S/n): \c"
read -r response
if [[ ! $response =~ ^[Nn]$ ]]; then
    # Verificar se app existe
    if [ -d "$PROJECT_DIR/app/VPNMonitor.app" ]; then
        print_info "Instalando aplicativo wrapper..."
        mkdir -p ~/Applications
        cp -r "$PROJECT_DIR/app/VPNMonitor.app" ~/Applications/
        
        # Adicionar aos Itens de Login
        print_info "Adicionando aos Itens de Login..."
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$HOME/Applications/VPNMonitor.app\", hidden:false}" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Configurado para iniciar no login"
            print_info "Gerenciar em: Configurações → Geral → Itens de Início"
        else
            print_warning "Não foi possível adicionar automaticamente"
            print_info "Adicione manualmente: Configurações → Geral → Itens de Início"
            print_info "Arquivo: ~/Applications/VPNMonitor.app"
        fi
    else
        print_warning "App wrapper não encontrado"
        print_info "Você pode iniciar manualmente com:"
        echo -e "   ${BLUE}~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &${NC}"
    fi
else
    print_info "Início automático não configurado"
fi

# ============================================
# ETAPA 6: Testar configuração
# ============================================
print_header "ETAPA 6: Teste de Configuração"

if [ -f ~/bin/vpn-monitor-orizon.sh ]; then
    echo -e "Deseja iniciar o monitor agora para testar? (S/n): \c"
    read -r response
    if [[ ! $response =~ ^[Nn]$ ]]; then
        print_info "Iniciando monitor..."
        ~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
        MONITOR_PID=$!
        sleep 2
        
        if ps -p $MONITOR_PID > /dev/null; then
            print_success "Monitor iniciado (PID: $MONITOR_PID)"
            print_info "Logs em: ~/tmp/vpn-monitor.log"
            
            echo -e "\nDeseja ver os logs em tempo real? (S/n): \c"
            read -r response
            if [[ ! $response =~ ^[Nn]$ ]]; then
                echo -e "\n${BLUE}Pressione Ctrl+C para sair dos logs${NC}\n"
                sleep 1
                tail -f ~/tmp/vpn-monitor.log
            fi
        else
            print_error "Monitor não iniciou corretamente"
            print_info "Verifique os logs: tail ~/tmp/vpn-monitor.log"
        fi
    else
        print_info "Monitor não iniciado"
    fi
else
    print_warning "Script principal não foi instalado"
    print_info "Não é possível testar sem o script vpn-monitor-orizon.sh"
fi

# ============================================
# RESUMO FINAL
# ============================================
print_header "INSTALAÇÃO CONCLUÍDA"

if [ -f ~/bin/vpn-monitor-orizon.sh ]; then
    echo -e "${GREEN}✅ Sistema instalado com sucesso!${NC}\n"
else
    echo -e "${YELLOW}⚠️  Instalação parcial${NC}\n"
    print_warning "Os scripts principais não foram encontrados no projeto"
    print_info "Você precisará criar ou copiar os scripts manualmente"
    print_info "Consulte o README.md para mais informações\n"
fi

if [ -f ~/bin/vpn-monitor-orizon.sh ] || [ -f ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh ]; then
    print_info "Componentes instalados:"
    [ -f ~/bin/vpn-monitor-orizon.sh ] && echo -e "  • Script principal: ${BLUE}~/bin/vpn-monitor-orizon.sh${NC}"
    [ -f ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh ] && echo -e "  • Script de clique: ${BLUE}~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh${NC}"
    echo -e "  • Logs: ${BLUE}~/tmp/vpn-monitor.log${NC}"
fi

if [ "$VPN_UUID" != "CONFIGURE_MANUALLY" ]; then
    echo -e "\n${GREEN}✅ Configuração detectada:${NC}"
    echo -e "  • UUID: ${BLUE}$VPN_UUID${NC}"
    echo -e "  • Interface: ${BLUE}$VPN_INTERFACE${NC}"
    [ -n "$VPN_SERVER" ] && echo -e "  • Servidor: ${BLUE}$VPN_SERVER${NC}"
fi

echo -e "\n${BLUE}📋 Comandos úteis:${NC}"
echo -e "  • Ver logs: ${BLUE}tail -f ~/tmp/vpn-monitor.log${NC}"
echo -e "  • Status: ${BLUE}pgrep -lf vpn-monitor-orizon${NC}"
echo -e "  • Parar: ${BLUE}pkill -f vpn-monitor-orizon${NC}"
echo -e "  • Reiniciar: ${BLUE}~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh${NC}"
echo -e "  • Testar: ${BLUE}~/GitHub/mac-Forticlient-automation/scripts/test-disconnect-with-countdown.sh${NC}"

echo -e "\n${BLUE}🧪 Como testar:${NC}"
echo -e "  1. Desconecte a VPN manualmente"
echo -e "  2. Aguarde ~5 segundos"
echo -e "  3. Observe:"
echo -e "     - Alerta de voz em português"
echo -e "     - FortiClient abre automaticamente"
echo -e "     - Clique automático no botão Connect"
echo -e "     - Mouse e foco voltam para onde estavam"
echo -e "  4. Aprove no celular"
echo -e "  5. FortiClient fecha automaticamente"
echo -e "  6. Tudo volta ao normal!"

echo -e "\n${YELLOW}⚠️  Lembre-se:${NC}"
echo -e "  • Conceder permissões de Acessibilidade ao seu terminal"
echo -e "  • Testar antes de confiar em produção"
echo -e "  • Ver documentação completa: ${BLUE}README.md${NC}"

echo -e "\n${GREEN}✨ Aproveite seus 95% de automação! ✨${NC}\n"
