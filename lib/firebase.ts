// lib/firebase.ts
import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// Your web app's Firebase configuration

// For Firebase JS SDK v7.20.0 and later, measurementId is optional

const firebaseConfig = {

  apiKey: "AIzaSyAfY18qUi7pRthM6aYv7Q9JeE3_ANLneY8",
  authDomain: "annur-motor-system.firebaseapp.com",
  projectId: "annur-motor-system",
  storageBucket: "annur-motor-system.firebasestorage.app",
  messagingSenderId: "770182713014",
  appId: "1:770182713014:web:6bb406a043a00b09c02017",
  measurementId: "G-5NWF0GTNJY"

};


// Initialize Firebase
let app;
if (!getApps().length) {
  app = initializeApp(firebaseConfig);
} else {
  app = getApps()[0];
}

const db = getFirestore(app);
const auth = getAuth(app);

export { db, auth };