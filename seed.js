import mysql from 'mysql2/promise'
import crypto from 'node:crypto'
const db=await mysql.createConnection({host:process.env.DB_HOST||'127.0.0.1',user:process.env.DB_USER||'root',password:process.env.DB_PASSWORD||'1234',database:process.env.DB_NAME||'hr_evaluation'})
const hash=p=>{const s=crypto.randomBytes(16).toString('hex');return s+':'+crypto.scryptSync(p,s,64).toString('hex')}
for(const u of [['admin','admin123','ผู้ดูแลระบบ','admin'],['employee01','emp123','บุคลากรตัวอย่าง','employee'],['committee01','com123','คณะกรรมการตัวอย่าง','committee']])await db.execute('INSERT IGNORE INTO users(username,password_hash,fullname,role,must_change_password) VALUES(?,?,?,?,?)',[u[0],hash(u[1]),u[2],u[3],u[3]==='admin'?0:1])
const [[employee]]=await db.query("SELECT id FROM users WHERE username='employee01'"),[[committee]]=await db.query("SELECT id FROM users WHERE username='committee01'")
const [[found]]=await db.query("SELECT id FROM rounds WHERE name='รอบทดลองระบบ'")
if(!found){
 const [r]=await db.execute("INSERT INTO rounds(name,status) VALUES('รอบทดลองระบบ','open')")
 const [t]=await db.execute("INSERT INTO topics(round_id,name) VALUES(?,?)",[r.insertId,'ผลการปฏิบัติงาน'])
 await db.execute("INSERT INTO indicators(topic_id,name,description,weight,max_score,eval_type,level1,level2,level3,level4) VALUES(?,?,?,?,?,?,?,?,?,?)",[t.insertId,'คุณภาพงาน','ประเมินคุณภาพและความถูกต้องของงาน',1,4,'scale','ต้องปรับปรุงมาก','ต่ำกว่าคาดหวัง','ตามคาดหวัง','สูงกว่าคาดหวัง'])
 await db.execute("INSERT INTO indicators(topic_id,name,description,weight,max_score,eval_type) VALUES(?,?,?,?,?,?)",[t.insertId,'มีหลักฐานประกอบ','มีการแนบหลักฐานการปฏิบัติงาน',1,1,'yesno'])
 const [d]=await db.execute("INSERT INTO duties(user_id,round_id,title,description) VALUES(?,?,?,?)",[employee.id,r.insertId,'แบบประเมินตัวอย่าง','ตัวอย่างสำหรับทดลองระบบทุกบทบาท'])
 await db.execute("INSERT INTO committee_assignments(duty_id,committee_id,committee_role) VALUES(?,?,'chair')",[d.insertId,committee.id])
}
console.log('สร้างบัญชีและข้อมูลตัวอย่างเรียบร้อย');await db.end()
