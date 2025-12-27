
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";


const firebaseConfig = {
  apiKey: "AIzaSyBVPw2K7-KXv4vyEnW_-g5aatBjDV9A-Hs",
  authDomain: "dineflow-hackathon.firebaseapp.com",
  projectId: "dineflow-hackathon",
  storageBucket: "dineflow-hackathon.firebasestorage.app",
  messagingSenderId: "220862448660",
  appId: "1:220862448660:web:6c5095bfdf0a2394895301",
  measurementId: "G-ERK1VS75HB",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { db };
