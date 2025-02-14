import subprocess,requests,time
#Troque aqui o ID do raspberry
id = '1'
url="http://192.168.0.13:5000"
url = url + "/id/" + str(id)
#"10:FF:E0:0F:AD:11"
def wol(mac):
    print('WakeOnLan:',mac)
    #subprocess.run(["WakeOnLan",mac])
while True:
    try:
        response = requests.get(url)
        if response.status_code == 201:
            wol(response.text)
    except:
        print("Erro ao tentar acessar o servidor")
    time.sleep(2)


