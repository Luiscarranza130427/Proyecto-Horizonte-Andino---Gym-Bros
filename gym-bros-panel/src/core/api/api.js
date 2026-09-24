import axios from 'axios'

import { API_BASE_URL } from '@/core/config/env'
import { configurarInterceptores } from '@/core/api/interceptors'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

configurarInterceptores(api)

export { registrarManejadorNoAutorizado, registrarProveedorDeToken } from '@/core/api/interceptors'
export default api
