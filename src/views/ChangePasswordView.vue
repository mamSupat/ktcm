<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { send } from '../api';
const router=useRouter(), old=ref(''), next=ref(''), again=ref(''), msg=ref('');
async function save() {
  try {
    if (next.value.length<6||next.value!==again.value)
      throw Error('รหัสผ่านใหม่อย่างน้อย 6 ตัวและต้องตรงกัน');
    await send('/auth/password', { old_password: old.value, new_password: next.value }, 'PUT');
    const u=JSON.parse(localStorage.getItem('user'));
    u.must_change_password=false;
    localStorage.setItem('user', JSON.stringify(u));
    router.push('/'+u.role);
  }
  catch (e) {
    msg.value=e.message;
  }
}
</script>
<template>
<main class="page" style="max-width:430px;margin:8vh auto">
 <h2>
  เปลี่ยนรหัสผ่านครั้งแรก
 </h2>
 <p>
  กรุณาตั้งรหัสผ่านใหม่ก่อนเข้าใช้งานระบบ
 </p>
 <p class="msg">
  {{msg}}
 </p>
 <form @submit.prevent="save">
  <label>
   รหัสผ่านเดิม
   <input required="" type="password" v-model="old"/>
  </label>
  <label>
   รหัสผ่านใหม่
   <input minlength="6" required="" type="password" v-model="next"/>
  </label>
  <label>
   ยืนยันรหัสผ่าน
   <input required="" type="password" v-model="again"/>
  </label>
  <button>
   บันทึกรหัสผ่าน
  </button>
 </form>
</main>
</template>
