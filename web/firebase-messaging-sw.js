importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI",
  appId: "1:951845646390:web:c16b39f0a39a1c9e20e897",
  messagingSenderId: "951845646390",
  projectId: "studio-2145172646-5b4a0",
  authDomain: "studio-2145172646-5b4a0.firebaseapp.com",
  storageBucket: "studio-2145172646-5b4a0.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "icons/Icon-192.png",
    badge: "favicon.png"
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
