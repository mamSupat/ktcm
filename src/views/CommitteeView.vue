<script setup>
import { ref, onMounted } from 'vue';
import { api, send } from '../api';
const tasks=ref([]), selected=ref(null), data=ref(null), scores=ref({}), comments=ref({}), summary=ref(''), signature=ref(''), msg=ref('');
async function openEvidence(id) {
  try {
    const blob=await api('/evidence/'+id+'/download'), url=URL.createObjectURL(blob);
    Object.assign(document.createElement('a'), { href: url, target: '_blank' }).click();
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function load() {
  try {
    tasks.value=await api('/committee/tasks');
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function openTask(t) {
  try {
    selected.value=t;
    data.value=await api('/committee/tasks/'+t.id);
    summary.value=data.value.assessment?.comment||'';
    scores.value={};
    comments.value={};
    for (const i of data.value.indicators) {
      const s=data.value.scores.find(x => x.indicator_id===i.id);
      scores.value[i.id]=s?.score??'';
      comments.value[i.id]=s?.comment||'';
    }
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function draft() {
  try {
    if (data.value.indicators.some(i => scores.value[i.id]===''||scores.value[i.id]===undefined))
      throw Error('กรุณาให้คะแนนทุกตัวชี้วัด');
    await send('/committee/tasks/'+selected.value.id+'/draft', { comment: summary.value, scores: data.value.indicators.map(i => ({ indicator_id: i.id, score: Number(scores.value[i.id]), comment: comments.value[i.id] })) }, 'PUT');
    msg.value='บันทึกร่างแล้ว';
    await load();
    await openTask(selected.value);
  }
  catch (e) {
    msg.value=e.message;
  }
}
function totalScore() { return data.value?.indicators.reduce((n, i) => n+(Number(scores.value[i.id]||0)*Number(i.weight||1)), 0)||0; }
async function signFile(e) {
  const f=e.target.files[0]; if (!f)
    return; const r=new FileReader(); r.onload=() => signature.value=r.result; r.readAsDataURL(f);
}
async function submit() {
  try {
    if (!signature.value)
      throw Error('กรุณาแนบลายเซ็นก่อนยืนยัน');
    await send('/committee/tasks/'+selected.value.id+'/submit', { signature: signature.value }, 'PUT');
    msg.value='ยืนยันผลประเมินแล้ว';
    data.value=null;
    selected.value=null;
    await load();
  }
  catch (e) {
    msg.value=e.message;
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
    หน้ากรรมการผู้ประเมิน
   </h1>
   <small>
    รายการที่ได้รับมอบหมาย
   </small>
  </div>
  <button @click="logout">
   ออกจากระบบ
  </button>
 </header>
 <p class="msg">
  {{msg}}
 </p>
 <div v-if="!selected">
  <section :key="t.id" class="panel" v-for="t in tasks">
   <h3>
    {{t.title}} — {{t.fullname}}
   </h3>
   <p>
    {{t.description}}
   </p>
   <p>
    บทบาท: {{t.committee_role==='chair'?'ประธาน':'กรรมการร่วม'}} | สถานะ: {{t.status}}
   </p>
   <button :disabled="t.duty_status!=='submitted'||t.status==='submitted'" @click="openTask(t)">
    เปิดตรวจและประเมิน
   </button>
  </section>
  <p v-if="!tasks.length">
   ยังไม่มีรายการที่ได้รับมอบหมาย
  </p>
 </div>
 <div class="panel" v-else="">
  <button @click="selected=null;data=null">
   ← กลับรายการ
  </button>
  <h2>
   {{data.task.title}} — {{data.task.fullname}}
  </h2>
  <p>
   {{data.task.description}}
  </p>
  <h3>
   หลักฐานประกอบ
  </h3>
  <p :key="f.id" v-for="f in data.evidence">
   <a :href="f.url" target="_blank" v-if="f.url">
    {{f.filename}}
   </a>
   <button @click="openEvidence(f.id)" type="button" v-else="">
    {{f.filename}}
   </button>
  </p>
  <h3>
   คะแนนประเมินตนเอง
  </h3>
  <table>
   <tr>
    <th>
     ตัวชี้วัด
    </th>
    <th>
     คะแนนตนเอง
    </th>
   </tr>
   <tr v-for="i in data.indicators">
    <td>
     {{i.name}}
    </td>
    <td>
     {{data.self.find(s=&gt;s.indicator_id===i.id)?.score??'-'}}
    </td>
   </tr>
  </table>
  <h3>
   ประเมินรายตัวชี้วัด
  </h3>
  <div :key="i.id" class="subpanel" v-for="i in data.indicators">
   <b>
    {{i.topic_name}} — {{i.name}}
   </b>
   <p>
    {{i.description}}
   </p>
   <p v-for="d in data.details.filter(x=&gt;x.indicator_id===i.id)">
    รายละเอียดที่ผู้รับการประเมินระบุ: {{d.detail}}
   </p>
   <p v-if="i.eval_type==='scale'">
    1 {{i.level1}}
    <br/>
    2 {{i.level2}}
    <br/>
    3 {{i.level3}}
    <br/>
    4 {{i.level4}}
   </p>
   <label>
    คะแนน
    <select v-model="scores[i.id]">
     <option value="">
      เลือกคะแนน
     </option>
     <option :value="n" v-for="n in (i.eval_type==='yesno'?[0,1]:[1,2,3,4])">
      {{i.eval_type==='yesno'?(n?'มี':'ไม่มี'):'ระดับ '+n}}
     </option>
    </select>
   </label>
   <label>
    ความคิดเห็นรายตัวชี้วัด
    <textarea v-model="comments[i.id]"></textarea>
   </label>
  </div>
  <p>
   <b>
    คะแนนรวมถ่วงน้ำหนัก (ร่าง): {{totalScore()}}
   </b>
  </p>
  <label>
   ความคิดเห็นสรุปภาพรวม
   <textarea v-model="summary"></textarea>
  </label>
  <button @click="draft">
   บันทึกร่าง / แก้ไขร่าง
  </button>
  <hr/>
  <h3>
   ลงนามและยืนยันผล
  </h3>
  <label>
   แนบภาพลายเซ็น
   <input @change="signFile" accept="image/*" type="file"/>
  </label>
  <img :src="signature" style="max-width:220px;max-height:100px" v-if="signature"/>
  <button @click="submit">
   ยืนยันและส่งผลประเมิน
  </button>
 </div>
</main>
</template>
