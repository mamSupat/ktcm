import { createRouter, createWebHistory } from 'vue-router';
import LoginView from '../views/LoginView.vue';
import AdminView from '../views/AdminView.vue';
import EmployeeView from '../views/EmployeeView.vue';
import CommitteeView from '../views/CommitteeView.vue';
import ChangePasswordView from '../views/ChangePasswordView.vue';
const router=createRouter({
  history: createWebHistory(), routes: [
    { path: '/', component: LoginView }, { path: '/change-password', component: ChangePasswordView },
    { path: '/admin', component: AdminView, meta: { role: 'admin' } },
    { path: '/employee', component: EmployeeView, meta: { role: 'employee' } },
    { path: '/committee', component: CommitteeView, meta: { role: 'committee' } }
  ]
});
router.beforeEach(to => {
  const u=JSON.parse(localStorage.getItem('user')||'null'); if (to.path!=='/'&&!u)
    return '/'; if (to.path==='/'&&u)
    return u.must_change_password? '/change-password':'/'+u.role; if (u?.must_change_password&&to.path!='/change-password')
    return '/change-password'; if (to.path==='/change-password'&&!u?.must_change_password)
    return '/'+u.role; if (to.meta.role&&u?.role!==to.meta.role)
    return '/'+u.role;
});
export default router;
