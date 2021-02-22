//user.js
const dbHelper = require('./db.js');

class User {
    constructor() {
    }

   static async save(userAddress,userValue) {
        let _user = {address:userAddress,value:userValue};
        dbHelper.open().then(db=>{
            let userCollection = db.collection('users');
            userCollection.updateOne(_user,{'$set':_user},{'upsert':true},(err,result)=>{
                if(err) throw new Error(err);
                //console.log('保存用户成功：'+JSON.stringify(_user));
                dbHelper.close();
            })
        })
    }

    static async find(userAddress) {
        return new Promise((resolve,reject)=>{
            dbHelper.open().then(db=>{
                let userCollection = db.collection('users');
                userCollection.findOne({address: userAddress},(err,result)=>{
                    if(err) throw new Error(err);
                   // console.log('找到用户：'+JSON.stringify(result));
                    dbHelper.close();
                    resolve(result);
                })
            })
        })
    }

    static async findAll() {
        return new Promise((resolve,reject)=>{
            dbHelper.open().then(db=>{
                let userCollection = db.collection('users');
                userCollection.find({}).toArray((err,result)=>{
                    if(err) throw new Error(err);
                    //console.log(`查询用户列表成功：`+JSON.stringify(result));
                    dbHelper.close();
                    resolve(result);
                })
            })
        })
    }

    static async update(id,user) {
        dbHelper.open().then(db=>{
            let userCollection = db.collection('users');
            userCollection.updateOne({'_id':ObjectId(id)},{$set:user},(err,result)=>{
                if(err) throw new Error(err);
                dbHelper.close();
                //console.log(`更新用户成功：`+user);
            })
        })
    }

    static async remove(id) {
        dbHelper.open().then(db=>{
            let userCollection = db.collection('users');
            userCollection.deleteOne({'_id':ObjectId(id)},(err,result)=>{
                if(err) throw new Error(err);
                dbHelper.close();
                //console.log(`删除用户成功：`+user);
            })
        })
    }

    static async saveBlockNum(blkNum) {
        let blk = {address:"0x0001",blocknumber:blkNum};
        dbHelper.open().then(db=>{
            let userCollection = db.collection('blocknumber');
            userCollection.updateOne(blk,{'$set':blk},{'upsert':true},(err,result)=>{
                if(err) throw new Error(err);
                //console.log('保存用户成功：'+JSON.stringify(_user));
                dbHelper.close();
            })
        })
    }

    static async getBlockNum() {
        return new Promise((resolve,reject)=>{
            dbHelper.open().then(db=>{
                let userCollection = db.collection('blocknumber');
                userCollection.findOne({address:'0x0001'},(err,result)=>{
                    if(err) throw new Error(err);
                    // console.log('找到用户：'+JSON.stringify(result));
                    dbHelper.close();
                    resolve(result);
                })
            })
        })
    }
}



module.exports = User;