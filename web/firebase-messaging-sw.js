importScripts(
  'https://www.gstatic.com/firebasejs/12.15.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/12.15.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyB7jdOMwZfw0jzySnBVYltaCMJ7pf2nLUw',
  authDomain: 'raq-darjar.firebaseapp.com',
  projectId: 'raq-darjar',
  storageBucket: 'raq-darjar.firebasestorage.app',
  messagingSenderId: '1080325854470',
  appId: '1:1080325854470:web:4100773edeb607de1b3a87',
});

firebase.messaging();
