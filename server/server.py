# Este é um servidor Flask simples que armazena pares de id e mac
# em memória. Ele possui dois endpoints: um para obter o mac associado a um id
# e outro para adicionar um novo par id/mac.
# O endpoint GET /id/<string:id> retorna o mac associado ao id fornecido.
# Se o id não existir, retorna um código de status 204.
# O endpoint POST /id adiciona um novo par id/mac. O corpo da requisição deve ser um JSON
from flask import Flask, request, jsonify
from flask_cors import CORS
app = Flask(__name__)
CORS(app)
ids = []
macs = []
@app.route('/id/<string:id>', methods=['GET'])
def get_item(id):
    if id in ids:
        temp = jsonify(macs[ids.index(id)])
        del macs[ids.index(id)]
        del ids[ids.index(id)]
        return temp,201
    else:
        return '', 204
@app.route('/id', methods=['POST'])
def post_item():
    data = request.json
    id = data.get('id')
    mac = data.get('mac')
    ids.append(id)
    macs.insert(ids.index(id), mac)
    return '', 201
if __name__ == '__main__':
    app.run(host='192.168.0.3', port=5000, debug=False)
