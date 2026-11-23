const base=(import.meta.env.VITE_API_URL||'http://localhost:3000/api').replace(/\/$/, '');
export async function api(path, options={}) {
  const token=localStorage.getItem('token');
  const res=await fetch(base+path, { ...options, headers: { ...(options.body instanceof FormData? {}:{ 'Content-Type': 'application/json' }), ...(token? { Authorization: 'Bearer '+token }:{}), ...options.headers } });
  const type=res.headers.get('content-type')||'';
  const data=type.includes('application/json')? await res.json():await res.blob();
  if (!res.ok)
    throw new Error(data.message||'เกิดข้อผิดพลาด');
  return data;
}
export const send=(path, body, method='POST') => api(path, { method, body: JSON.stringify(body) });
