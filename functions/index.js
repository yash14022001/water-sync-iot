const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

const db_firestore = admin.firestore();
const fcm = admin.messaging();

exports.helloWorld = functions.database.ref('/users/{uid}/hardware/data_values/{macID}/{timestamp}')
  .onCreate((snapshot, context) => {
    
    const payload = {
        notification:{
            title : 'Message from Cloud',
            body : 'This is your body',
            badge : '1',
            sound : 'default'
        }
    };
    
    var uid = snapshot.ref.parent.parent.parent.parent.getKey();

    console.log(`uid is fetched as ${uid} `);

    var tokensArr = [];
    let allTokens = db_firestore.collection(`users/${uid}/tokens`).get().then(snapshot => {
        snapshot.forEach(doc => {
          //console.log(doc.id, '=>', doc.data());
          console.log(`adding token to allToken array :${doc.data()['token']}`)
          //tokensArr.push(doc.data()['token']);
          return admin.messaging().sendToDevice(doc.data()['token'], payload)
        });
        return tokensArr;
      })
      .catch(err => {
        console.log('Error getting documents', err);
        return err;
      });

      console.log(`array ::: `,JSON.stringify(tokensArr));

      //console.log(`allTokens have following value`)

      return admin.messaging().sendToDevice(tokensArr,payload);
    /*return admin_db.database().ref(`users/${uid}/tokens`).once('value').then(allToken => {
        if(allToken.val()){
            console.log('token available');
            const token = Object.keys(allToken.val());
            return admin.messaging().sendToDevice(token,payload);
        }else{
            console.log('No token available');
        }
    });*/

});
