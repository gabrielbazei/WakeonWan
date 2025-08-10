# Este código é um exemplo de um servidor Flask que armazena IDs e MACs em listas.
# Ele possui dois endpoints: um para obter um MAC associado a um ID e outro para adicionar um novo ID e MAC.
from flask import Flask, request, jsonify, make_response
import os
app = Flask(__name__)
#O servidor inicializa duas listas vazias: uma para armazenar IDs e outra para armazenar MACs.
ids = []
macs = []
# O servidor possui um endpoint GET que aceita um ID como parâmetro de URL e retorna o MAC associado a esse ID.
# Se o ID não estiver presente, retorna um código de status 204 (sem conteúdo).
@app.route('/id/<string:id>', methods=['GET'])
def get_item(id):
    print(ids)
    # Verifica se o ID está na lista de IDs
    if id in ids:
        # temporariamente armazena o MAC associado ao ID
        temp = jsonify(macs[ids.index(id)])
        # Remove o ID e o MAC das listas utilizando o índice do ID
        del macs[ids.index(id)]
        # Remove o ID da lista de IDs utilizando o método index
        # Isso garante que o ID e o MAC sejam removidos juntos
        del ids[ids.index(id)]
        # retorna 201 para indicar que o recurso foi criado
        response = make_response(temp, 201)
        return response
    else:
        # caso contrário retorna 204 indicando que não há conteúdo
        response = make_response('', 204)
        return response
# O servidor possui um endpoint POST que aceita um JSON contendo um ID e um MAC.
# Ele adiciona o ID e o MAC às listas correspondentes e retorna um código de status 201 (criado).
@app.route('/id', methods=['POST'])
def post_item():
    # Verifica se o conteúdo do tipo JSON foi enviado
    data = request.json
    #pega o ID e o MAC do JSON recebido
    id = data.get('id')
    mac = data.get('mac')
    #adiciona o ID e o MAC às listas correspondentes
    ids.append(id)
    # Vale ressaltar que o MAC é adicionado na mesma posição do ID
    # Isso garante que o ID e o MAC estejam sempre sincronizados
    macs.insert(ids.index(id), mac)
    # Retorna 201 como resposta, indicando que o recurso foi criado com sucesso
    response = make_response('', 201)
    return response
# O servidor é executado na porta especificada na variável de ambiente, especifica da azure PORT ou na porta 5000 por padrão.
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)