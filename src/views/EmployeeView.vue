<script setup>
import { ref, onMounted } from 'vue';
import { api, send } from '../api';
const user=ref(JSON.parse(localStorage.getItem('user')||'{}')), duties=ref([]), forms=ref({}), profile=ref({ fullname: '', email: '', phone: '' }), pw=ref({ old_password: '', new_password: '' }), msg=ref('');
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
    duties.value=await api('/duties');
    for (const d of duties.value) {
      const x=await api('/duties/'+d.id+'/self'), scores={}, details={};
      for (const i of x.indicators) {
        const s=x.scores.find(v => v.indicator_id===i.id);
        scores[i.id]=s?.score??'';
        details[i.id]=x.details.filter(v => v.self_score_id===s?.id).map(v => v.detail).join('\n');
      }
      forms.value[d.id]={ ...x, scores, details };
    }
    profile.value={ fullname: user.value.fullname, email: user.value.email||'', phone: user.value.phone||'' };
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function save(d) {
  try {
    const f=forms.value[d.id];
    if (f.indicators.some(i => f.scores[i.id]===''||f.scores[i.id]===undefined))
      throw Error('กรุณากรอกคะแนนให้ครบทุกตัวชี้วัด');
    await send('/duties/'+d.id+'/self', { scores: f.indicators.map(i => ({ indicator_id: i.id, score: Number(f.scores[i.id]), details: (f.details[i.id]||'').split('\n') })) }, 'PUT');
    msg.value='บันทึกการประเมินตนเองแล้ว';
    await load();
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function submit(d) {
  if (!confirm('ส่งแบบประเมินแล้วจะไม่สามารถแก้ไขได้ ยืนยันหรือไม่?'))
    return; try {
      await send('/duties/'+d.id+'/submit', {});
      msg.value='ส่งแบบประเมินแล้ว';
      await load();
    }
  catch (e) {
    msg.value=e.message;
  }
}
async function evidence(d, i, event) {
  const file=event.target.files[0]; if (!file)
    return; const reader=new FileReader(); reader.onload=async () => {
      try {
        await send('/evidence', { duty_id: d.id, indicator_id: i.id, name: file.name, data: reader.result });
        msg.value='แนบหลักฐานแล้ว';
        await load();
      }
      catch (e) {
        msg.value=e.message;
      }
    }; reader.readAsDataURL(file);
}
async function addUrl(d, i) {
  const url=prompt('วาง URL หลักฐาน'); if (url)
    try {
      await send('/evidence', { duty_id: d.id, indicator_id: i.id, name: url, url });
      await load();
    }
    catch (e) {
      msg.value=e.message;
    }
}
async function updateProfile() {
  try {
    await send('/profile', profile.value, 'PUT');
    user.value={ ...user.value, ...profile.value };
    localStorage.setItem('user', JSON.stringify(user.value));
    msg.value='บันทึกข้อมูลส่วนตัวแล้ว';
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function password() {
  try {
    await send('/auth/password', pw.value, 'PUT');
    msg.value='เปลี่ยนรหัสผ่านแล้ว';
    pw.value={ old_password: '', new_password: '' };
  }
  catch (e) {
    msg.value=e.message;
  }
}
async function report(d) {
  try {
    const x=await api('/report/'+d.id);
    const w=window.open('', '_blank');
    w.document.write('<h2>รายงานการประเมิน '+x.duty.title+'</h2><p>'+x.duty.fullname+'</p><table border=1><tr><th>ตัวชี้วัด</th><th>คะแนนตนเอง</th></tr>'+x.indicators.map(i => '<tr><td>'+i.name+'</td><td>'+(x.self.find(s => s.indicator_id===i.id)?.score??'-')+'</td></tr>').join('')+'</table><p>ความคิดเห็นกรรมการ</p>'+x.committee.map(c => '<p>'+c.fullname+': '+(c.comment||'')+'</p>').join(''));
    w.document.close();
    w.print();
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
    หน้าผู้รับการประเมิน
   </h1>
   <small>
    {{user.fullname}}
   </small>
  </div>
  <button @click="logout">
   ออกจากระบบ
  </button>
 </header>
 <p class="msg">
  {{msg}}
 </p>
 <section class="panel">
  <h3>
   ข้อมูลส่วนตัว
  </h3>
  <form @submit.prevent="updateProfile">
   <input placeholder="ชื่อ-สกุล" required="" v-model="profile.fullname"/>
   <input placeholder="อีเมล" v-model="profile.email"/>
   <input placeholder="โทรศัพท์" v-model="profile.phone"/>
   <button>
    บันทึกข้อมูล
   </button>
  </form>
  <h3>
   เปลี่ยนรหัสผ่าน
  </h3>
  <form @submit.prevent="password">
   <input placeholder="รหัสผ่านเดิม" required="" type="password" v-model="pw.old_password"/>
   <input minlength="6" placeholder="รหัสผ่านใหม่อย่างน้อย 6 ตัว" required="" type="password" v-model="pw.new_password"/>
   <button>
    เปลี่ยนรหัสผ่าน
   </button>
  </form>
 </section>
 <h2>
  แบบประเมินของฉัน
 </h2>
 <div :key="d.id" class="panel" v-for="d in duties">
  <h3>
   {{d.title}} — {{d.round_name}}
  </h3>
  <p>
   {{d.description}}
  </p>
  <p>
   สถานะ:
   <b>
    {{d.status}}
   </b>
   | ความคืบหน้า: {{forms[d.id]?.indicators.length?Math.round(forms[d.id].indicators.filter(i=&gt;forms[d.id].scores[i.id]!==''&amp;&amp;forms[d.id].scores[i.id]!==undefined).length/forms[d.id].indicators.length*100):0}}%
  </p>
  <div :key="i.id" class="subpanel" v-for="i in forms[d.id]?.indicators">
   <h4>
    {{i.topic_name}} — {{i.name}} (น้ำหนัก {{i.weight}})
   </h4>
   <p>
    {{i.description}}
   </p>
   <p v-if="i.eval_type==='scale'">
    ระดับ 1: {{i.level1}}
    <br/>
    ระดับ 2: {{i.level2}}
    <br/>
    ระดับ 3: {{i.level3}}
    <br/>
    ระดับ 4: {{i.level4}}
   </p>
   <label>
    ประเมินตนเอง
    <select :disabled="d.status!=='pending'" v-model="forms[d.id].scores[i.id]">
     <option value="">
      เลือกคะแนน
     </option>
     <option :value="n" v-for="n in (i.eval_type==='yesno'?[0,1]:[1,2,3,4])">
      {{i.eval_type==='yesno'?(n?'มี':'ไม่มี'):'ระดับ '+n}}
     </option>
    </select>
   </label>
   <label>
    รายละเอียดประกอบ (แยกแต่ละรายการด้วยการขึ้นบรรทัดใหม่)
    <textarea :disabled="d.status!=='pending'" placeholder="รายละเอียดประกอบการประเมิน" v-model="forms[d.id].details[i.id]"></textarea>
   </label>
   <label>
    แนบไฟล์ PDF/JPG/PNG
    <input :disabled="d.status!=='pending'" @change="e=&gt;evidence(d,i,e)" accept=".pdf,.jpg,.jpeg,.png" type="file"/>
   </label>
   <button :disabled="d.status!=='pending'" @click="addUrl(d,i)" type="button">
    แนบ URL
   </button>
   <p :key="f.id" v-for="f in forms[d.id]?.evidence.filter(x=&gt;x.indicator_id===i.id)">
    <a :href="f.url" target="_blank" v-if="f.url">
     {{f.filename}}
    </a>
    <button @click="openEvidence(f.id)" type="button" v-else="">
     {{f.filename}}
    </button>
   </p>
  </div>
  <button @click="save(d)" v-if="d.status==='pending'">
   บันทึกแบบประเมิน
  </button>
  <button @click="submit(d)" v-if="d.status==='pending'">
   ส่งแบบประเมิน
  </button>
  <button @click="report(d)">
   Export / พิมพ์ PDF
  </button>
  <h4>
   ผลและความคิดเห็นกรรมการ
  </h4>
  <button @click="report(d)">
   ดูรายงานผล
  </button>
 </div>
 <p v-if="!duties.length">
  ยังไม่มีแบบประเมิน
 </p>
</main>
</template>
