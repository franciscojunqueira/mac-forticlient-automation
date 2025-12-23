# Análise de Métodos para Monitoramento VPN Orizon (FortiClient)

## Resumo Executivo
**Método Recomendado:** Combinação de `scutil --nc status` + verificação de interface `utun7`

## Análise do Ambiente Atual

### ✅ Informações Detectadas
- **VPN:** FortiClient conectado à Orizon
- **UUID:** `2617CE22-5F83-46EA-9EA3-4B9DADEC75A6`
- **Interface:** `utun7` (IP: 172.22.64.3)
- **Servidor VPN:** vpn-a.orizon.com.br (179.191.93.220)
- **Logs disponíveis:** `/Library/Application Support/Fortinet/FortiClient/Logs/`

## Comparação de Métodos

### 🥇 Método 1: scutil + Interface (RECOMENDADO)
**Confiabilidade:** ⭐⭐⭐⭐⭐

```bash
scutil --nc status "2617CE22-5F83-46EA-9EA3-4B9DADEC75A6" | grep -q "^Connected$"
ifconfig utun7 | grep -q "inet 172\.22\."
```

**Vantagens:**
- ✅ API nativa do macOS para VPNs
- ✅ Detecta status real da conexão VPN
- ✅ Não depende de processos ou logs
- ✅ Resposta instantânea
- ✅ Dupla verificação (scutil + interface) elimina falsos positivos

**Desvantagens:**
- ⚠️ UUID pode mudar se reconfigurar VPN (raro)

**Melhor para:** Monitoramento contínuo e confiável

---

### 🥈 Método 2: Monitoramento de Rotas
**Confiabilidade:** ⭐⭐⭐⭐

```bash
netstat -rn | grep -q "172\.22\.64\.3.*utun7"
```

**Vantagens:**
- ✅ Detecta presença de rotas VPN
- ✅ Independente de UUID

**Desvantagens:**
- ⚠️ Pode ter delay até rotas serem removidas
- ⚠️ Mais lento que scutil

**Melhor para:** Backup do método principal

---

### 🥉 Método 3: Monitoramento de Logs
**Confiabilidade:** ⭐⭐⭐

```bash
tail -f "/Library/Application Support/Fortinet/FortiClient/Logs/vpn-provider.log"
```

**Vantagens:**
- ✅ Informação detalhada sobre desconexões
- ✅ Histórico disponível

**Desvantagens:**
- ❌ Requer acesso root aos logs
- ❌ Mais pesado (I/O contínuo)
- ❌ Pode ter delay na escrita dos logs
- ⚠️ Formato de log pode mudar entre versões

**Melhor para:** Debug/diagnóstico, não monitoramento em tempo real

---

### ❌ Método 4: Verificação de Processos
**Confiabilidade:** ⭐⭐

```bash
pgrep -f "FortiClient" && netstat -rn | grep -q "172\."
```

**Vantagens:**
- ✅ Simples

**Desvantagens:**
- ❌ FortiClient permanece rodando mesmo desconectado
- ❌ Muitos falsos positivos
- ❌ Não detecta estado real da VPN

**Melhor para:** Nenhum caso específico (não recomendado)

## Implementação Escolhida

O script criado (`~/bin/vpn-monitor-orizon.sh`) usa:
1. **Verificação primária:** `scutil --nc status` com UUID detectado
2. **Verificação secundária:** Interface `utun7` com IP 172.22.*
3. **Alertas múltiplos:** 
   - Voz: `say "Atenção! VPN Orizon desconectada"`
   - Som: Sistema (Sosumi.aiff)
   - Notificação visual: Centro de notificações do macOS

## Como Usar

### Opção A: Execução Manual
```bash
~/bin/vpn-monitor-orizon.sh
```
- Mantém terminal aberto
- Vê logs em tempo real
- Para com Ctrl+C

### Opção B: Background Simples
```bash
~/bin/vpn-monitor-orizon.sh &
```
- Roda em background
- Alertas funcionam normalmente

### Opção C: LaunchAgent (Automático)
```bash
# Carregar o serviço
launchctl load ~/Library/LaunchAgents/com.user.vpn-monitor-orizon.plist

# Verificar status
launchctl list | grep vpn-monitor

# Ver logs
tail -f ~/tmp/vpn-monitor.log

# Parar serviço
launchctl unload ~/Library/LaunchAgents/com.user.vpn-monitor-orizon.plist
```
- Inicia automaticamente no login
- Sempre rodando em background
- Logs em `~/tmp/vpn-monitor.log`

## Conclusão

**Recomendação Final:** Usar o script criado com **Opção B ou C**

O método escolhido oferece:
- ⚡ Detecção rápida (5 segundos)
- 🎯 Alta precisão (dupla verificação)
- 🔊 Alertas múltiplos (voz + som + notificação)
- 🪶 Leve (baixo uso de recursos)
- 🛡️ Confiável (API nativa do macOS)

### Ajustes Possíveis
- **Intervalo de verificação:** Mudar `sleep 5` no script (linha 61)
- **Mensagem de voz:** Editar linha 49
- **Som:** Trocar `/System/Library/Sounds/Sosumi.aiff` por outro (linha 52)
