document.addEventListener('DOMContentLoaded', function() {
    const macInput = document.getElementById('macInput');
    const macNameInput = document.getElementById('macName');
    const saveBtn = document.getElementById('savebtn');
    const idInput = document.getElementById('id');
    const wakeForm = document.getElementById('wakeForm');
    const addMacBtn = document.getElementById('addMacBtn');
    const macList = document.getElementById('macList');
    const macListUl = document.getElementById('macListUl');

    console.log("Script loaded");

    const savedId = localStorage.getItem('id');
    if (savedId) {
        idInput.value = savedId;
        wakeForm.classList.remove('hidden');
    }

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

    macInput.addEventListener('focus', function() {
        macInput.classList.remove('disabled');
    });

    macNameInput.addEventListener('focus', function() {
        macNameInput.classList.remove('disabled');
    });

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

    function saveMac(mac, name) {
        const macs = getMacs();
        macs.push({ mac, name });
        localStorage.setItem('macs', JSON.stringify(macs));
    }

    function getMacs() {
        const macs = localStorage.getItem('macs');
        if (macs) {
            return JSON.parse(macs);
        }
        return [];
    }

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

    window.wakeMac = function(mac) {
        enviarSinal(idInput.value,mac);
    };

    window.removeMac = function(index) {
        if (confirm('Are you sure you want to remove this MAC address?')) {
            const macs = getMacs();
            macs.splice(index, 1);
            localStorage.setItem('macs', JSON.stringify(macs));
            displayMacs();
        }
    };

    function enviarSinal(id,mac) {
        console.log("Sending magic packet...");
        var url = 'http://192.168.0.13:5000/id';
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