from flask import Flask, request, jsonify
from flask_cors import CORS
app = Flask(__name__)
CORS(app)
ids = []
macs = []
@app.route('/id/<string:id>', methods=['GET'])
def get_item(id):
    print('ids:',ids, 'macs:',macs)
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
    print('ids:',ids, 'macs:',macs)
    return '', 201
if __name__ == '__main__':
    app.run(host='192.168.0.13', port=5000, debug=True)
