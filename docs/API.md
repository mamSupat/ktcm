# REST API Reference

Base URL: `http://localhost:3000/api`  
ทุก Endpoint ยกเว้น `POST /auth/login` ต้องส่ง Header `Authorization: Bearer <JWT>`  
รูปแบบ Error: `{ "status":"error", "message":"..." }` และ HTTP 400/401/403/404 ตามกรณี

| Method | Endpoint | Role | Query / Path / Body |
|---|---|---|---|
| POST | `/auth/login` | Public | Body: username, password |
| GET | `/auth/me` | All | - |
| PUT | `/auth/password` | All | Body: old_password, new_password |
| PUT | `/profile` | All | Body: fullname, email, phone |
| GET/POST | `/users` | Admin | POST body: username,password,fullname,role |
| PUT/DELETE | `/users/:id` | Admin | Path id; PUT body: fullname,role,active,password? |
| GET/POST | `/rounds` | All/Admin | POST body: name,start_date,end_date,status |
| PUT/DELETE | `/rounds/:id` | Admin | Path id; PUT body: name,start_date,end_date,status |
| GET/POST | `/topics` | All/Admin | POST body: round_id,name |
| PUT/DELETE | `/topics/:id` | Admin | Path id; PUT body: round_id,name |
| GET/POST | `/indicators` | All/Admin | POST body: topic_id,name,description,weight,eval_type,max_score,evidence_hint,level1..level4 |
| PUT/DELETE | `/indicators/:id` | Admin | Path id; PUT body same as POST |
| GET/POST | `/duties` | All/Admin | POST body: user_id,round_id,title,description,committees:[{id}],chair_id |
| PUT | `/duties/:id` | Admin | Path id; Body: title,description |
| GET | `/duties/:id/self` | Employee | Path duty id |
| PUT | `/duties/:id/self` | Employee | Body: scores:[{indicator_id,score,details:[...]}] |
| POST | `/duties/:id/submit` | Employee | Path duty id |
| POST | `/evidence` | Employee | Body: duty_id,indicator_id,name,data (data URL) or url |
| GET | `/evidence/duty/:id` | Authorized | Path duty id |
| GET | `/evidence/:id/download` | Authorized | Path evidence id |
| GET | `/committee/tasks` | Committee | Assigned tasks |
| GET | `/committee/tasks/:id` | Committee | Path assignment id |
| PUT | `/committee/tasks/:id/draft` | Committee | Body: comment,scores:[{indicator_id,score,comment}] |
| PUT | `/committee/tasks/:id/submit` | Committee | Body: signature (image data URL) |
| GET | `/dashboard` | Admin | Summary counts |
| GET | `/report` | Admin/Committee/Employee | Employee/committee see own assigned data |
| GET | `/report/:dutyId` | Authorized | Individual report |
| GET | `/backup` | Admin | Export all tables as JSON |
| POST | `/restore` | Admin | Body: JSON backup object |

ตัวอย่าง Response สำเร็จ:
```json
{"status":"success","message":"บันทึกสำเร็จ"}
```
ตัวอย่าง Error:
```json
{"status":"error","message":"ไม่มีสิทธิ์ใช้งาน"}
```
