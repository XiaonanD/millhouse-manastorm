$(function () {

    var socket = io();

    // - Whenever the server emits 'data', update the flow graph
    // - TODO integrate with D3.js
    socket.on('data', function (data) {
        console.log('message received %s', data);
        $('#data').append(data + '<br/>');
    });
});