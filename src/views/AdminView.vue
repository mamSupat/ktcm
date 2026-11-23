<script setup>
import { ref, onMounted } from 'vue';
import { api, send } from '../api';
const users=ref([]), rounds=ref([]), topics=ref([]), indicators=ref([]), duties=ref([]), report=ref([]), dash=ref({}), detail=ref(null), msg=ref('');
const staff=ref({ username: '', password: '', fullname: '', role: 'employee' }), round=ref({ name: '', start_date: '', end_date: '' }), topic=ref({ round_id: '', name: '' });
const indicator=ref({ topic_id: '', name: '', description: '', weight: 1, eval_type: 'scale', max_score: 4, evidence_hint: '', level1: '', level2: '', level3: '', level4: '' });
const duty=ref({ user_id: '', round_id: '', title: '', description: '', committees: [], chair_id: '' });
async function load() {
  try {
    [users.value, rounds.value, topics.value, indicators.value, duties.value, report.value, dash.value]=await Promise.all(['/users', '/rounds', '/topics', '/indicators', '/duties', '/report', '/dashboard'].map(api));
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function add(url, obj, reset) {
  try {
    await send(url, obj);
    msg.value='บันทึกสำเร็จ';
    reset();
    await load();
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function remove(url, id) {
  if (confirm('ยืนยันการลบ/ปิดใช้งาน?'))
    try {
      await send(url+'/'+id, {}, 'DELETE');
      await load();
    }
    catch (e) {
      msg.value=e.message;
    }
}
async function resetPassword(u) {
  const p=prompt('กำหนดรหัสผ่านชั่วคราว (อย่างน้อย 6 ตัว)'); if (p&&p.length>=6)
    try {
      await send('/users/'+u.id, { fullname: u.fullname, role: u.role, active: !!u.active, password: p }, 'PUT');
      msg.value='Reset Password แล้ว';
    }
    catch (e) {
      msg.value=e.message;
    }
}
async function showReport(id) {
  try {
    detail.value=await api('/report/'+id);
  }
  catch (e) {
    msg.value=e.message;
  }
}
function printReport() { window.print(); }
async function exportReport() {
  try {
    const data=await api('/report'), blob=new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }), url=URL.createObjectURL(blob), el=document.createElement('a');
    el.href=url;
    el.download='hr-report.json';
    el.click();
    URL.revokeObjectURL(url);
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function backup() {
  try {
    const data=await api('/backup'), blob=new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }), url=URL.createObjectURL(blob), a=document.createElement('a');
    a.href=url;
    a.download='hr-backup.json';
    a.click();
    URL.revokeObjectURL(url);
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function restore(e) {
  const f=e.target.files[0]; if (!f)
    return; if (!confirm('ข้อมูลปัจจุบันจะถูกแทนที่ ต้องการกู้คืนหรือไม่?'))
    return; try {
      await send('/restore', JSON.parse(await f.text()));
      msg.value='กู้คืนข้อมูลสำเร็จ';
      load();
    }
  catch (x) {
    msg.value=x.message;
  }
}
function logout() { localStorage.clear(); location.href='/'; }
onMounted(load);
</script>
<template>
<main class="page">
 <header>
  <div>
   <h1>
    ผู้ดูแลระบบ
   </h1>
   <small>
    จัดการระบบประเมินบุคลากร
   </small>
  </div>
  <button @click="logout">
   ออกจากระบบ
  </button>
 </header>
 <p class="msg">
  {{msg}}
 </p>
 <section class="grid">
  <div class="panel">
   <b>
    ผู้ใช้
   </b>
   <h2>
    {{dash.users||0}}
   </h2>
  </div>
  <div class="panel">
   <b>
    รอบประเมิน
   </b>
   <h2>
    {{dash.rounds||0}}
   </h2>
  </div>
  <div class="panel">
   <b>
    งานทั้งหมด
   </b>
   <h2>
    {{dash.duties||0}}
   </h2>
  </div>
  <div class="panel">
   <b>
    ประเมินเสร็จ
   </b>
   <h2>
    {{dash.evaluated||0}}
   </h2>
  </div>
 </section>
 <section class="grid">
  <div class="panel">
   <h3>
    เพิ่มผู้ใช้
   </h3>
   <form @submit.prevent="add('/users',staff,()=&gt;staff={username:'',password:'',fullname:'',role:'employee'})">
    <input placeholder="Username" required="" v-model.trim="staff.username"/>
    <input minlength="6" placeholder="รหัสผ่านชั่วคราว" required="" v-model="staff.password"/>
    <input placeholder="ชื่อ-สกุล" required="" v-model.trim="staff.fullname"/>
    <select v-model="staff.role">
     <option value="employee">
      ผู้รับการประเมิน
     </option>
     <option value="committee">
      กรรมการ
     </option>
     <option value="admin">
      ผู้ดูแล
     </option>
    </select>
    <button>
     เพิ่มผู้ใช้
    </button>
   </form>
  </div>
  <div class="panel">
   <h3>
    สร้างรอบประเมิน
   </h3>
   <form @submit.prevent="add('/rounds',round,()=&gt;round={name:'',start_date:'',end_date:''})">
    <input placeholder="ชื่อรอบ" required="" v-model="round.name"/>
    <label>
     วันเริ่ม
     <input type="date" v-model="round.start_date"/>
    </label>
    <label>
     วันสิ้นสุด
     <input type="date" v-model="round.end_date"/>
    </label>
    <button>
     บันทึกรอบ
    </button>
   </form>
  </div>
  <div class="panel">
   <h3>
    เพิ่มหัวข้อ
   </h3>
   <form @submit.prevent="add('/topics',topic,()=&gt;topic={round_id:'',name:''})">
    <select required="" v-model="topic.round_id">
     <option value="">
      เลือกรอบ
     </option>
     <option :value="r.id" v-for="r in rounds">
      {{r.name}}
     </option>
    </select>
    <input placeholder="ชื่อหัวข้อ" required="" v-model="topic.name"/>
    <button>
     เพิ่มหัวข้อ
    </button>
   </form>
  </div>
  <div class="panel">
   <h3>
    เพิ่มตัวชี้วัด
   </h3>
   <form @submit.prevent="add('/indicators',indicator,()=&gt;indicator={topic_id:'',name:'',description:'',weight:1,eval_type:'scale',max_score:4,evidence_hint:'',level1:'',level2:'',level3:'',level4:''})">
    <select required="" v-model="indicator.topic_id">
     <option value="">
      เลือกหัวข้อ
     </option>
     <option :value="t.id" v-for="t in topics">
      {{t.name}}
     </option>
    </select>
    <input placeholder="ชื่อตัวชี้วัด" required="" v-model="indicator.name"/>
    <textarea placeholder="รายละเอียด" v-model="indicator.description"></textarea>
    <label>
     น้ำหนักคะแนน
     <input min="0.1" step="0.1" type="number" v-model.number="indicator.weight"/>
    </label>
    <select v-model="indicator.eval_type">
     <option value="scale">
      ระดับ 1-4
     </option>
     <option value="yesno">
      มี/ไม่มี
     </option>
    </select>
    <input min="1" placeholder="คะแนนเต็ม (ระดับ 1-4 ใช้ 4)" type="number" v-model.number="indicator.max_score"/>
    <input placeholder="หลักฐานที่ต้องแนบ" v-model="indicator.evidence_hint"/>
    <input placeholder="คำอธิบายระดับ 1" v-model="indicator.level1"/>
    <input placeholder="คำอธิบายระดับ 2" v-model="indicator.level2"/>
    <input placeholder="คำอธิบายระดับ 3" v-model="indicator.level3"/>
    <input placeholder="คำอธิบายระดับ 4" v-model="indicator.level4"/>
    <button>
     เพิ่มตัวชี้วัด
    </button>
   </form>
  </div>
  <div class="panel">
   <h3>
    มอบหมายผู้รับการประเมินและกรรมการ
   </h3>
   <form @submit.prevent="add('/duties',duty,()=&gt;duty={user_id:'',round_id:'',title:'',description:'',committees:[],chair_id:''})">
    <select required="" v-model="duty.user_id">
     <option value="">
      เลือกบุคลากร
     </option>
     <option :value="u.id" v-for="u in users.filter(x=&gt;x.role==='employee'&amp;&amp;x.active)">
      {{u.fullname}}
     </option>
    </select>
    <select required="" v-model="duty.round_id">
     <option value="">
      เลือกรอบ
     </option>
     <option :value="r.id" v-for="r in rounds">
      {{r.name}}
     </option>
    </select>
    <input placeholder="ชื่องาน/แบบประเมิน" required="" v-model="duty.title"/>
    <textarea placeholder="รายละเอียด" v-model="duty.description"></textarea>
    <b>
     เลือกประธานกรรมการ
    </b>
    <select v-model="duty.chair_id">
     <option value="">
      ยังไม่กำหนด
     </option>
     <option :value="c.id" v-for="c in users.filter(x=&gt;x.role==='committee'&amp;&amp;x.active)">
      {{c.fullname}}
     </option>
    </select>
    <b>
     เลือกกรรมการ (ติ๊กเลือกผู้เข้าร่วม)
    </b>
    <label v-for="c in users.filter(x=&gt;x.role==='committee'&amp;&amp;x.active)">
     <input :value="c.id" type="checkbox" v-model="duty.committees"/>
     {{c.fullname}} ({{Number(duty.chair_id)===Number(c.id)?'ประธาน':'กรรมการร่วม'}})
    </label>
    <button>
     มอบหมายงาน
    </button>
   </form>
  </div>
 </section>
 <section class="panel">
  <h2>
   ผู้ใช้งาน
  </h2>
  <table>
   <tr>
    <th>
     ชื่อ
    </th>
    <th>
     บัญชี
    </th>
    <th>
     บทบาท
    </th>
    <th>
     สถานะ
    </th>
    <th>
     จัดการ
    </th>
   </tr>
   <tr v-for="u in users">
    <td>
     {{u.fullname}}
    </td>
    <td>
     {{u.username}}
    </td>
    <td>
     {{u.role}}
    </td>
    <td>
     {{u.active?'ใช้งาน':'ปิด'}}
    </td>
    <td>
     <button @click="resetPassword(u)">
      Reset Password
     </button>
     <button @click="remove('/users',u.id)">
      ปิดบัญชี
     </button>
    </td>
   </tr>
  </table>
 </section>
 <section class="panel">
  <h2>
   รอบ / หัวข้อ / ตัวชี้วัด
  </h2>
  <p v-for="r in rounds">
   {{r.name}} ({{r.start_date||'-'}} ถึง {{r.end_date||'-'}}) — {{r.status}}
   <button @click="send('/rounds/'+r.id,{name:r.name,start_date:r.start_date,end_date:r.end_date,status:r.status==='open'?'closed':'open'},'PUT').then(load)">
    {{r.status==='open'?'ปิดรอบ':'เปิดรอบ'}}
   </button>
   <button @click="remove('/rounds',r.id)">
    ลบ
   </button>
  </p>
  <p v-for="t in topics">
   {{t.round_name}} / {{t.name}}
   <button @click="remove('/topics',t.id)">
    ลบ
   </button>
  </p>
  <p v-for="i in indicators">
   {{i.topic_name}} / {{i.name}} — {{i.eval_type}}
   <button @click="remove('/indicators',i.id)">
    ลบ
   </button>
  </p>
 </section>
 <section class="panel">
  <h2>
   ติดตามงาน
  </h2>
  <table>
   <tr>
    <th>
     บุคลากร
    </th>
    <th>
     งาน
    </th>
    <th>
     สถานะ
    </th>
    <th>
     ความคืบหน้า
    </th>
    <th>
     รายงาน
    </th>
   </tr>
   <tr v-for="d in duties">
    <td>
     {{d.fullname}}
    </td>
    <td>
     {{d.title}}
    </td>
    <td>
     {{d.status}}
    </td>
    <td>
     {{d.indicator_count?Math.round(d.self_count/d.indicator_count*100):0}}%
    </td>
    <td>
     <button @click="showReport(d.id)">
      ดูรายละเอียด
     </button>
    </td>
   </tr>
  </table>
 </section>
 <section class="panel" v-if="detail">
  <button @click="detail=null">
   ปิดรายละเอียด
  </button>
  <h2>
   ผลรายบุคคล: {{detail.duty.fullname}} — {{detail.duty.title}}
  </h2>
  <table>
   <tr>
    <th>
     ตัวชี้วัด
    </th>
    <th>
     คะแนนตนเอง
    </th>
    <th>
     คะแนนกรรมการ
    </th>
   </tr>
   <tr v-for="i in detail.indicators">
    <td>
     {{i.name}}
    </td>
    <td>
     {{detail.self.find(x=&gt;x.indicator_id===i.id)?.score??'-'}}
    </td>
    <td>
     {{detail.committee.filter(x=&gt;x.indicator_id===i.id).map(x=&gt;x.score).join(', ')||'-'}}
    </td>
   </tr>
  </table>
  <h3>
   สรุปกรรมการ
  </h3>
  <p v-for="c in detail.committee">
   {{c.fullname}} ({{c.committee_role}}): {{c.comment||'-'}} — {{c.status}}
  </p>
 </section>
 <section class="panel">
  <h2>
   รายงานผล
  </h2>
  <button @click="exportReport">
   ดาวน์โหลดรายงาน JSON
  </button>
  <button @click="printReport">
   พิมพ์รายงาน / Save PDF
  </button>
  <table>
   <tr>
    <th>
     ผู้รับการประเมิน
    </th>
    <th>
     งาน
    </th>
    <th>
     กรรมการ
    </th>
    <th>
     คะแนน
    </th>
    <th>
     สถานะกรรมการ
    </th>
   </tr>
   <tr v-for="r in report">
    <td>
     {{r.fullname}}
    </td>
    <td>
     {{r.title}}
    </td>
    <td>
     {{r.committee_name}} ({{r.committee_role}})
    </td>
    <td>
     {{r.total_score}}
    </td>
    <td>
     {{r.committee_status}}
    </td>
   </tr>
  </table>
 </section>
 <section class="panel">
  <h2>
   Backup / Restore
  </h2>
  <button @click="backup">
   ดาวน์โหลด Backup JSON
  </button>
  <label>
   เลือกไฟล์ Backup เพื่อกู้คืน
   <input @change="restore" accept=".json,application/json" type="file"/>
  </label>
  <small>
   การ Restore จะแทนที่ข้อมูลทั้งหมดในฐานข้อมูล
  </small>
 </section>
</main>
</template>
