# Guia de Reconexão Semi-Automática da VPN Orizon

## ✅ O que foi implementado

O script de monitoramento agora possui **reconexão semi-automática** que funciona assim:

### Fluxo Completo

```
1. VPN desconecta
   ↓
2. 🔔 Alerta: "Atenção! VPN Orizon desconectada"
   ↓
3. 🔄 Script executa: scutil --nc start (inicia processo de conexão)
   ↓
4. 📱 Alerta: "Verifique seu celular para aprovar a conexão VPN"
   ↓
5. [VOCÊ APROVA NO CELULAR] ← Única ação manual necessária
   ↓
6. ✅ VPN reconecta automaticamente
   ↓
7. 🎉 Alerta: "VPN reconectada com sucesso"
```

## 🎯 Vantagens

### Antes (sem reconexão)
- VPN desconecta
- Você recebe alerta
- Precisa abrir FortiClient
- Clicar em "Conectar"
- Aprovar no celular

**Total: 4 ações manuais**

### Agora (com reconexão)
- VPN desconecta
- Script inicia reconexão automaticamente
- Você apenas aprova no celular

**Total: 1 ação manual** ✨

## 📋 Alertas que você receberá

### Quando desconectar:
- 🗣️ Voz: "Atenção! VPN Orizon desconectada"
- 🔔 Som: Sosumi
- 📱 Notificação: "Conexão VPN foi perdida"

### Durante reconexão:
- 🗣️ Voz: "Verifique seu celular para aprovar a conexão VPN"
- 🔔 Som: Glass
- 📱 Notificação: "Aprove no celular para reconectar"

### Quando reconectar:
- 🗣️ Voz: "VPN reconectada com sucesso"
- 🔔 Som: Hero
- 📱 Notificação: "Conexão restabelecida"

## ⚙️ Configuração

### Habilitar/Desabilitar reconexão automática

Edite o arquivo `~/bin/vpn-monitor-orizon.sh`:

```bash
# Linha 17
AUTO_RECONNECT=true   # Reconexão automática ATIVADA (padrão)
AUTO_RECONNECT=false  # Reconexão automática DESATIVADA (apenas alerta)
```

## 🚀 Como Usar

### Se estiver usando LaunchAgent (automático no login)

Já está rodando! Não precisa fazer nada.

### Se estiver usando Login Item (VPNMonitor.app)

Já está rodando! Não precisa fazer nada.

### Reiniciar o monitor com as novas funcionalidades

Se o monitor já estava rodando, reinicie:

#### Opção 1: Se rodando via LaunchAgent
```bash
launchctl unload ~/Library/LaunchAgents/com.user.vpn-monitor-orizon.plist
launchctl load ~/Library/LaunchAgents/com.user.vpn-monitor-orizon.plist
```

#### Opção 2: Se rodando via Login Item
```bash
# Encontre o processo
pgrep -f vpn-monitor-orizon

# Mate o processo (substitua PID pelo número retornado acima)
kill PID

# Reabra o app
open ~/Applications/VPNMonitor.app
```

#### Opção 3: Manual
```bash
# Mate qualquer instância rodando
pkill -f vpn-monitor-orizon

# Execute novamente
~/bin/vpn-monitor-orizon.sh &
```

## 🧪 Como Testar

### Teste 1: Verificar se script foi atualizado
```bash
grep "AUTO_RECONNECT" ~/bin/vpn-monitor-orizon.sh
```
Deve mostrar: `AUTO_RECONNECT=true`

### Teste 2: Desconectar manualmente e observar
1. Desconecte a VPN pelo FortiClient
2. Aguarde ~5 segundos
3. Você deve receber:
   - Alerta de desconexão
   - Alerta para aprovar no celular
4. Aprove no celular
5. VPN reconecta automaticamente

## ⚠️ Limitações

### O que NÃO pode ser automatizado:
- ❌ Aprovação MFA no celular (requer interação humana por segurança)
- ❌ Inserção de senha/usuário (protegido pelo FortiClient)
- ❌ Bypass de autenticação (impossível e inseguro)

### O que FOI automatizado:
- ✅ Detecção de desconexão
- ✅ Início do processo de reconexão
- ✅ Alertas informativos
- ✅ Confirmação de reconexão bem-sucedida

## 🔍 Troubleshooting

### Script não tenta reconectar
```bash
# Verifique se AUTO_RECONNECT está true
grep AUTO_RECONNECT ~/bin/vpn-monitor-orizon.sh

# Deve mostrar: AUTO_RECONNECT=true
```

### Reconexão não funciona
```bash
# Teste manualmente se o comando funciona
scutil --nc start "2617CE22-5F83-46EA-9EA3-4B9DADEC75A6"

# Depois aprove no celular
# Verifique se conectou:
scutil --nc status "2617CE22-5F83-46EA-9EA3-4B9DADEC75A6"
```

### UUID da VPN mudou
Se reconfigurou a VPN, o UUID pode ter mudado:

```bash
# Liste conexões VPN
scutil --nc list

# Atualize o UUID no script (linha 7)
# Substitua o valor de FORTICLIENT_UUID
```

## 📊 Logs

### Ver o que está acontecendo

Se usando LaunchAgent:
```bash
tail -f ~/tmp/vpn-monitor.log
```

Logs mostrarão:
- `VPN conectada` - Status conectado
- `⚠️ VPN DESCONECTADA!` - Desconexão detectada
- `🔄 Tentando reconectar...` - Iniciou reconexão
- `✅ VPN conectada` - Reconexão bem-sucedida

## 🎓 Resumo

A reconexão **semi-automática** é o melhor equilíbrio entre:
- ✅ Conveniência (automatiza o que é possível)
- ✅ Segurança (mantém MFA obrigatório)
- ✅ Praticidade (reduz de 4 para 1 ação manual)

**Você só precisa aprovar no celular. O resto é automático!** 🚀
