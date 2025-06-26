import api from '../../services/api'

const state = {
  user: null,
  token: localStorage.getItem('token') || null,
  loading: false,
  error: null
}

const getters = {
  isAuthenticated: state => !!state.token,
  user: state => state.user,
  loading: state => state.loading,
  error: state => state.error
}

const mutations = {
  SET_LOADING(state, loading) {
    state.loading = loading
  },
  SET_ERROR(state, error) {
    state.error = error
  },
  SET_USER(state, user) {
    state.user = user
  },
  SET_TOKEN(state, token) {
    state.token = token
    if (token) {
      localStorage.setItem('token', token)
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    } else {
      localStorage.removeItem('token')
      delete api.defaults.headers.common['Authorization']
    }
  },
  CLEAR_AUTH(state) {
    state.user = null
    state.token = null
    state.error = null
    localStorage.removeItem('token')
    delete api.defaults.headers.common['Authorization']
  }
}

const actions = {
  async register({ commit }, userData) {
    commit('SET_LOADING', true)
    commit('SET_ERROR', null)
    
    try {
      const response = await api.post('/api/v1/auth/register', { user: userData })
      const { user, token } = response.data
      
      commit('SET_USER', user)
      commit('SET_TOKEN', token)
      commit('SET_LOADING', false)
      
      return { success: true }
    } catch (error) {
      const message = error.response?.data?.errors?.join(', ') || 'Registration failed'
      commit('SET_ERROR', message)
      commit('SET_LOADING', false)
      return { success: false, error: message }
    }
  },
  
  async login({ commit }, credentials) {
    commit('SET_LOADING', true)
    commit('SET_ERROR', null)
    
    try {
      const response = await api.post('/api/v1/auth/login', credentials)
      const { user, token } = response.data
      
      commit('SET_USER', user)
      commit('SET_TOKEN', token)
      commit('SET_LOADING', false)
      
      return { success: true }
    } catch (error) {
      const message = error.response?.data?.error || 'Login failed'
      commit('SET_ERROR', message)
      commit('SET_LOADING', false)
      return { success: false, error: message }
    }
  },
  
  async logout({ commit }) {
    try {
      await api.delete('/api/v1/auth/logout')
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      commit('CLEAR_AUTH')
    }
  },
  
  initializeAuth({ commit, state }) {
    if (state.token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${state.token}`
    }
  }
}

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
}