//Este script é responsável por gerenciar a interação do usuário com a interface web, 
// incluindo o armazenamento local de endereços MAC e nomes, bem como o envio de pacotes mágicos para acordar dispositivos na rede.
// Ele utiliza o Local Storage do navegador para armazenar os dados e a API Fetch para enviar requisições HTTP.
// O script é executado quando o DOM é completamente carregado, garantindo que todos os elementos estejam disponíveis para manipulação.



document.addEventListener('DOMContentLoaded', function() {
    //referência aos elementos do DOM
    const macInput = document.getElementById('macInput');
    const macNameInput = document.getElementById('macName');
    const saveBtn = document.getElementById('savebtn');
    const idInput = document.getElementById('id');
    const wakeForm = document.getElementById('wakeForm');
    const addMacBtn = document.getElementById('addMacBtn');
    const macList = document.getElementById('macList');
    const macListUl = document.getElementById('macListUl');
    console.log("Script loaded");
    // Verifica se já existe um ID salvo no Local Storage e, se sim, preenche o campo de ID e exibe o formulário de wake
    const savedId = localStorage.getItem('id');
    if (savedId) {
        idInput.value = savedId;
        wakeForm.classList.remove('hidden');
    }
    // Adiciona um evento de clique ao botão de salvar ID
    // que salva o ID no Local Storage e exibe o formulário de wake
    // se o ID não estiver vazio
    // Caso contrário, oculta o formulário de wake

    saveBtn.addEventListener('click', function(event) {
        event.preventDefault();
        const id = idInput.value.trim();
        if (id !== '') {
            localStorage.setItem('id', id);
            wakeForm.classList.remove('hidden');
        } else {
            wakeForm.classList.add('hidden');
        }
    });
    // Adiciona um evento de foco ao campo de ID
    macInput.addEventListener('focus', function() {
        macInput.classList.remove('disabled');
    });
    // Adiciona um evento de foco ao campo de nome do MAC
    macNameInput.addEventListener('focus', function() {
        macNameInput.classList.remove('disabled');
    });
    // Adiciona um evento de clique ao botão de adicionar MAC
    addMacBtn.addEventListener('click', function(event) {
        event.preventDefault();
        const mac = macInput.value.trim();
        const name = macNameInput.value.trim();
        if (mac && name) {
            saveMac(mac, name);
            displayMacs();
            macInput.value = '';
            macNameInput.value = '';
        }
    });
    // Adiciona um evento de clique ao botão de adicionar MAC
    function saveMac(mac, name) {
        const macs = getMacs();
        macs.push({ mac, name });
        localStorage.setItem('macs', JSON.stringify(macs));
    }
    // Retorna uma lista de endereços MAC armazenados no Local Storage
    function getMacs() {
        const macs = localStorage.getItem('macs');
        if (macs) {
            return JSON.parse(macs);
        }
        return [];
    }
    // Exibe a lista de endereços MAC armazenados no Local Storage
    // Cada item da lista inclui um botão para acordar o dispositivo e um botão para remover o endereço MAC
    function displayMacs() {
        const macs = getMacs();
        macListUl.innerHTML = '';
        macs.forEach((macObj, index) => {
            const li = document.createElement('li');
            li.innerHTML = `
                ${macObj.name} (${macObj.mac})
                <div class="button-group">
                    <button onclick="wakeMac('${macObj.mac}')">Wake</button>
                    <button onclick="removeMac(${index})">Remove</button>
                </div>
            `;
            macListUl.appendChild(li);
        });
        macList.classList.remove('hidden');
    }
    // Adiciona um evento de clique ao botão de acordar dispositivo
    window.wakeMac = function(mac) {
        enviarSinal(idInput.value,mac);
    };
    // Adiciona um evento de clique ao botão de remover endereço MAC
    window.removeMac = function(index) {
        if (confirm('Are you sure you want to remove this MAC address?')) {
            const macs = getMacs();
            macs.splice(index, 1);
            localStorage.setItem('macs', JSON.stringify(macs));
            displayMacs();
        }
    };
    // Envia um pacote mágico para acordar o dispositivo com o endereço MAC especificado
    // O pacote mágico é enviado para um endpoint específico, que deve ser configurado para lidar com o pedido
    // O ID e o endereço MAC são passados como parâmetros no corpo da requisição
    // O resultado da requisição é exibido no console, indicando se o pacote mágico foi enviado com sucesso ou não
    // O endpoint utilizado neste caso é um serviço de wake-on-LAN hospedado na Azure, mas pode ser substituído por qualquer outro serviço compatível
    function enviarSinal(id,mac) {
        console.log("Sending magic packet...");
        var url = 'https://wakeonwan-bazei.azurewebsites.net/id';
        fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id: id, mac: mac })
        }).then(response => {
            if (response.ok) {
                console.log("Magic packet sent!");
            } else {
                console.log("Failed to send magic packet!");
            }
        }).catch(error => {
            console.error('Error:', error);
        });
    }
    displayMacs();
});