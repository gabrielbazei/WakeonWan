# Este de um worker para receber macs com base em um id especifico 
# e executar o comando WakeOnLan em cima de um mac para ligar o computador
import subprocess,requests,time,platform,uuid,os,sys

# Funcao para obter o MAC Address da maquina
# Dependendo do sistema operacional, utiliza metodos diferentes para obter o MAC Address
def pega_mac():
    # Verifica o sistema operacional
    system = platform.system()
    # Se for Windows, utiliza o uuid para obter o MAC Address
    if system == "Windows":
        # uuid.getnode() retorna o MAC Address da maquina
        mac = uuid.getnode()
        # Converte o MAC Address para o formato XX:XX:XX:XX:XX:XX
        mac_address = ':'.join(['{:02x}'.format((mac >> ele) & 0xff) for ele in range(40, -1, -8)])
        # Retorna o MAC Address no formato correto
        return mac_address
    # Se for linux, utiliza o comando ip link para obter o MAC Address
    elif system == "Linux":
        try:
            # Executa o comando ip link e captura a saida
            result = subprocess.check_output("ip link", shell=True).decode()
            # Procura pela linha que contem o MAC Address
            # A linha deve conter "link/ether" seguido do MAC Address
            for line in result.split("\n"):
                if "link/ether" in line:
                    # o uso de strip e split é usado para limpar a linha e obter o MAC Address de forma limpa
                    parts = line.strip().split()
                    # retorna parts [1] que é o MAC Address
                    return parts[1]
        #se tudo falhar, imprime mensagem de erro
        except Exception as e:
            print(f"Erro ao obter MAC: {e}")
            return None
    # se não for Windows ou Linux, retorna None
    return None
# Funcao para verificar se o MAC Address e valido
# O MAC Address deve ter o formato XX:XX:XX:XX:XX:XX, onde X e um digito hexadecimal
def sanitizador(mac):
    # inicializa a variavel valido como 0
    valido = 0
    if len(mac) == 17: # Tamanho correto para MAC Address
        temp = mac.upper() # Converte para maiusculas
        for i, char in enumerate(temp): # Verifica cada caractere
            if i in [2, 5, 8, 11, 14]: # Verifica nas posicoes onde deve haver ':', caso contrario, imprime mensagem de erro
                if char != ":":
                    print(f"Esperado ':' na posicao {i}, mas encontrou '{char}'")
                    # a adicao de 1 a valido indica que o MAC Address nao e valido
                    valido += 1
            else:
                # Se o "i" nao for uma posicao de ':', verifica se o caractere e um digito hexadecimal
                # Hexadecimais sao de 0 a 9 e de A a F
                if char not in "0123456789ABCDEF": # Verifica se e um caractere valido
                    print(f"Char invalido na posicao {i}: '{char}'")
                    # caso não seja um caractere valido, adiciona 1 a valido
                    valido += 1
    else:
        # Se o tamanho nao for 17, imprime mensagem de erro
        print("Tamanho invalido") 
        print(len(mac))
        valido += 1
    # Se o MAC Address for valido, retorna True, caso contrario, retorna False
    # o valor a ser validado precisar ser 0, pois se valido for maior que 0, significa que houve algum erro
    return valido == 0
# Funcao para executar o comando WakeOnLan
# Recebe o MAC Address como parametro e executa o comando WakeOnLan
def wol(mac):
    # remove espacos e aspas desnecessarias do MAC Address, isto é devido ao formato que o servidor envia o MAC Address
    mac = mac.strip().replace('"', '') # Remove aspas e espacos desnecessarios
    #aqui é uma função para auxiliar aqueles que usam o MAC Address com '-' ao inves de ':', comunmente usado por windows
    mac = mac.replace('-', ':')  # Substitui '-' por ':'
    # roda o sanitizador
    if sanitizador(mac): # Verifica se o MAC Address e valido
        #Aqui a função subprocess.run é usada para executar o comando WakeOnLan
        subprocess.run(["wakeonlan",mac]) # Executa o comando WakeOnLan com o MAC Address
#MAIN
id= pega_mac() # Obtem o MAC Address da maquina
if id is None: # Se nao conseguiu obter o MAC Address, imprime mensagem de erro
    print("Erro ao obter MAC Address")
id = id.upper() # Converte o MAC Address para maiusculas
print("ID da maquina", id) #Agora o usuario sabe qual o ID utilizar no website ou no aplicativo
url="https://wakeonwan-bazei.azurewebsites.net/" # URL do servidor Flask
url = url + "/id/" + str(id) # Adiciona o ID ao final da URL
tempo = 2 # Tempo de espera inicial, o tempo aumenta em caso de erro
# Loop infinito para verificar o servidor Flask
while True:
    try:
        response = requests.get(url) # Faz uma requisicao GET para o servidor
        tempo = 2 # Reseta o tempo de espera
        #print("response", response.status_code) # Imprime o codigo de status da resposta, utilizado para debug
        if response.status_code == 201:
            #chama a funcao wol com o MAC Address retornado pelo servidor
            wol(response.text)
    except:
        # Se ocorrer um erro ao tentar acessar o servidor, imprime mensagem de erro
        print("Erro ao tentar acessar o servidor")
        if tempo < 10: # Aumenta o tempo de espera em caso de erro
            tempo += 1
    time.sleep(tempo)