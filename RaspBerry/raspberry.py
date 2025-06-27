# Este de um worker para receber macs com base em um id especifico 
# e executar o comando WakeOnLan em cima de um mac para ligar o computador
import subprocess,requests,time,platform,uuid,os,sys

# Funcao para obter o MAC Address da maquina
# Dependendo do sistema operacional, utiliza metodos diferentes para obter o MAC Address
def pega_mac():
    system = platform.system()
    if system == "Windows":
        mac = uuid.getnode()
        mac_address = ':'.join(['{:02x}'.format((mac >> ele) & 0xff) for ele in range(40, -1, -8)])
        return mac_address
    elif system == "Linux":
        try:
            result = subprocess.check_output("ip link", shell=True).decode()
            for line in result.split("\n"):
                if "link/ether" in line:
                    parts = line.strip().split()
                    return parts[1]
        except Exception as e:
            print(f"Erro ao obter MAC: {e}")
            return None
    return None
# Funcao para verificar se o MAC Address e valido
# O MAC Address deve ter o formato XX:XX:XX:XX:XX:XX, onde X e um digito hexadecimal
def sanitizador(mac):
    valido = 0
    if len(mac) == 17: # Tamanho correto para MAC Address
        temp = mac.upper() # Converte para maiusculas
        for i, char in enumerate(temp): # Verifica cada caractere
            if i in [2, 5, 8, 11, 14]: # Verifica se e um :
                if char != ":":
                    print(f"Esperado ':' na posicao {i}, mas encontrou '{char}'")
                    valido += 1
            else:
                if char not in "0123456789ABCDEF": # Verifica se e um caractere valido
                    print(f"Char invalido na posicao {i}: '{char}'")
                    valido += 1
    else:
        # Se o tamanho nao for 17, imprime mensagem de erro
        print("Tamanho invalido") 
        print(len(mac))
        valido += 1
    # Se o MAC Address for valido, retorna True, caso contrario, retorna False
    return valido == 0
# Funcao para executar o comando WakeOnLan
# Recebe o MAC Address como parametro e executa o comando WakeOnLan
def wol(mac):
    mac = mac.strip().replace('"', '') # Remove aspas e espacos desnecessarios
    mac = mac.replace('-', ':')  # Substitui '-' por ':'
    if sanitizador(mac): # Verifica se o MAC Address e valido
        subprocess.run(["wakeonlan",mac]) # Executa o comando WakeOnLan com o MAC Address
#MAIN
id= pega_mac() # Obtem o MAC Address da maquina
if id is None: # Se nao conseguiu obter o MAC Address, imprime mensagem de erro
    print("Erro ao obter MAC Address")
id = id.upper() # Converte o MAC Address para maiusculas
print("ID da maquina", id)
url="https://wakeonwan-bazei.azurewebsites.net/"
url = url + "/id/" + str(id)
tempo = 2 # Tempo de espera inicial
while True:
    try:
        response = requests.get(url) # Faz uma requisicao GET para o servidor
        tempo = 2 # Reseta o tempo de espera
        if response.status_code == 201:
            wol(response.text)
    except:
        print("Erro ao tentar acessar o servidor")
        if tempo < 10: # Aumenta o tempo de espera em caso de erro
            tempo += 1
    time.sleep(tempo)