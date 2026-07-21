// Static Firebase JS module graph for iOS/WebKit compatibility.
//
// Keep URLs aligned with kVexdaFirebaseJsSdkVersion in
// lib/core/firebase/vexda_firebase_web_config.dart (11.9.1).
import * as core from 'https://www.gstatic.com/firebasejs/11.9.1/firebase-app.js';
import * as auth from 'https://www.gstatic.com/firebasejs/11.9.1/firebase-auth.js';
import * as firestore from 'https://www.gstatic.com/firebasejs/11.9.1/firebase-firestore.js';
import * as storage from 'https://www.gstatic.com/firebasejs/11.9.1/firebase-storage.js';
import * as functions from 'https://www.gstatic.com/firebasejs/11.9.1/firebase-functions.js';

window.firebase_core = core;
window.firebase_auth = auth;
window.firebase_firestore = firestore;
window.firebase_storage = storage;
window.firebase_functions = functions;
