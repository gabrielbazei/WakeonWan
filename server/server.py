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
    if id in ids:
        temp = jsonify(macs[ids.index(id)])
        del macs[ids.index(id)]
        del ids[ids.index(id)]
        response = make_response(temp, 201)
        return response
    else:
        response = make_response('', 204)
        return response
# O servidor possui um endpoint POST que aceita um JSON contendo um ID e um MAC.
# Ele adiciona o ID e o MAC às listas correspondentes e retorna um código de status 201 (criado).
@app.route('/id', methods=['POST'])
def post_item():
    data = request.json
    id = data.get('id')
    mac = data.get('mac')
    ids.append(id)
    macs.insert(ids.index(id), mac)
    response = make_response('', 201)
    return response
# O servidor é executado na porta especificada na variável de ambiente, especifica da azure PORT ou na porta 5000 por padrão.
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)