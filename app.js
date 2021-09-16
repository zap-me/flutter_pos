//functions to be used

function nonce() {
    return Math.floor(new Date().getTime() / 1000);
}


function sign(data) {
    var hash = CryptoJS.HmacSHA256(data, localStorage.getItem("flutter.secret"));
    return CryptoJS.enc.Base64.stringify(hash);
}

window.initConnection = async function(wsUrl) {
  const socket = io(wsUrl);
  var secretString = localStorage.getItem("flutter.secret");
  var tokenString = localStorage.getItem("flutter.api_key");
  socket.on('connect', () => {
      console.log('socket connected, id', socket.id);
      // create auth data
      var nonce_ = nonce();
      var sig = sign(nonce_.toString());
      var auth = {signature: sig, api_key: tokenString, nonce: nonce_};
      // emit auth message
      socket.emit('auth', auth);
  });

  socket.on('tx', (arg) => {
      var tx = JSON.parse(arg);
      console.log(`tx is ${tx}`);
    }
  );
}


