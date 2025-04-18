import subprocess,requests,time
#Troque aqui o ID do raspberry
id = '1'
url="wow-server-hkb5bqbtaedpgfej.brazilsouth-01.azurewebsites.net"
url = url + "/id/" + str(id)
tempo = 2 # Tempo de espera inicial
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
        print("Tamanho inválido") 
        print(len(mac))
        valido += 1

    return valido == 0


def wol(mac):
    if sanitizador(mac): # Verifica se o MAC Address é válido
        print('WakeOnLan:',mac)
        #subprocess.run(["WakeOnLan",mac]) # Executa o comando WakeOnLan com o MAC Address
while True:
    try:
        response = requests.get(url) # Faz uma requisição GET para o servidor
        tempo = 2 # Reseta o tempo de espera
        if response.status_code == 201:
            wol(response.text)
    except:
        print("Erro ao tentar acessar o servidor")
        if tempo < 10: # Aumenta o tempo de espera em caso de erro
            tempo += 1
    time.sleep(tempo)


