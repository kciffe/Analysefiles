import axios, {  type AxiosResponse} from 'axios'
import { ElMessage } from 'element-plus';
/** 后端统一返回壳：{ code, data, msg } */
export type ApiEnvelope<T> = {
  code: number
  data: T
  msg?: string
}

// 建议用 env 管 baseURL（最干净）
export const http = axios.create({
  timeout: 30_000 * 2 * 5,
})
const NetworkError = "网络错误，请稍后重试"
// 添加请求拦截器
http.interceptors.request.use(
    function (config) {
      // 在发送请求之前做些什么

      return config
    },
    function (error) {
      // 对请求错误做些什么
      return Promise.reject(error)
    }
);

// 添加响应拦截器
http.interceptors.response.use(
    (res:AxiosResponse<ApiEnvelope<any>>)=>{
        const {code, data, msg} = res.data
        if(code===200){
            return data
        }else{
            ElMessage.error(msg||NetworkError);
            return Promise.reject(new Error(msg));
        }
    },
    (error) => {
    ElMessage.error(NetworkError)
    return Promise.reject(error)
  },
);
