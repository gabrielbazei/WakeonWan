# Este de um worker para receber macs com base em um id específico 
# e executar o comando WakeOnLan em cima de um mac para ligar o computador
import subprocess,requests,time
#Troque aqui o ID do raspberry
id = '1'
url="https://wakeonwan-bazei.azurewebsites.net/"
url = url + "/id/" + str(id)
tempo = 2 # Tempo de espera inicial

# Função para verificar se o MAC Address é válido
# O MAC Address deve ter o formato XX:XX:XX:XX:XX:XX, onde X é um dígito hexadecimal
def sanitizador(mac):
    valido = 0
    mac = mac.strip().replace('"', '') # Remove aspas e espaços desnecessários
    if len(mac) == 17: # Tamanho correto para MAC Address
        temp = mac.upper() # Converte para maiúsculas
        for i, char in enumerate(temp): # Verifica cada caractere
            if i in [2, 5, 8, 11, 14]: # Verifica se é um :
                if char != ":":
                    print(f"Esperado ':' na posição {i}, mas encontrou '{char}'")
                    valido += 1
            else:
                if char not in "0123456789ABCDEF": # Verifica se é um caractere válido
                    print(f"Char inválido na posição {i}: '{char}'")
                    valido += 1
    else:
        # Se o tamanho não for 17, imprime mensagem de erro
        print("Tamanho inválido") 
        print(len(mac))
        valido += 1
    
    # Se o MAC Address for válido, retorna True, caso contrário, retorna False
    return valido == 0

# Função para executar o comando WakeOnLan
# Recebe o MAC Address como parâmetro e executa o comando WakeOnLan
def wol(mac):
    if sanitizador(mac): # Verifica se o MAC Address é válido
        print('WakeOnLan:',mac)
        subprocess.run(["WakeOnLan",mac]) # Executa o comando WakeOnLan com o MAC Address
while True:
    try:
        response = requests.get(url) # Faz uma requisição GET para o servidor
        tempo = 2 # Reseta o tempo de espera
        print("connected, codigo:", response.status_code)
        if response.status_code == 201:
            wol(response.text)
    except:
        print("Erro ao tentar acessar o servidor")
        if tempo < 10: # Aumenta o tempo de espera em caso de erro
            tempo += 1
    time.sleep(tempo)


