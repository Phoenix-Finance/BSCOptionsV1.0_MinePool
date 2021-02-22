const MongoClient = require("mongodb").MongoClient;
const url = `mongodb://localhost:27017`;
module.exports = {
    db:null,
    open() {
        return new Promise(function(resolve,reject) {
            MongoClient.connect(url,(err,client)=>{
                if(err) {
                    throw new Error(err);
                }
                this.db = client.db('db');
                resolve(this.db);
            })
        })
    },
    close() {
        if(this.db) {
            this.db.close();
        }
    }
}