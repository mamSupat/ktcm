<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { send } from '../api';
const router=useRouter(), username=ref('admin'), password=ref('admin123'), error=ref(''), busy=ref(false);
async function login() {
  busy.value=true; error.value=''; try {
    const d=await send('/auth/login', { username: username.value, password: password.value });
    localStorage.setItem('token', d.token);
    localStorage.setItem('user', JSON.stringify(d.user));
    router.push(d.user.must_change_password? '/change-password':'/'+d.user.role);
  }
    catch (e) {
      error.value=e.message;
    }
    finally {
      busy.value=false;
    }
}
</script>
<template>
<main class="page" style="max-width:430px;margin:8vh auto">
 <h1>
  ระบบประเมินบุคลากร
 </h1>
 <p>
  เข้าสู่ระบบ
 </p>
 <p class="msg error" v-if="error">
  {{error}}
 </p>
 <form @submit.prevent="login">
  <label>
   ชื่อผู้ใช้
   <input required="" v-model.trim="username"/>
  </label>
  <label>
   รหัสผ่าน
   <input required="" type="password" v-model="password"/>
  </label>
  <button :disabled="busy">
   เข้าสู่ระบบ
  </button>
 </form>
 <hr/>
 <small>
  บัญชีฝึก: admin/admin123 · employee01/emp123 · committee01/com123
 </small>
</main>
</template>
