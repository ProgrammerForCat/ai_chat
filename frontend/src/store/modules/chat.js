import api from '../../services/api'

const state = {
  conversations: [],
  currentConversation: null,
  specialists: [],
  loading: false,
  error: null
}

const getters = {
  conversations: state => state.conversations,
  currentConversation: state => state.currentConversation,
  specialists: state => state.specialists,
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
  SET_CONVERSATIONS(state, conversations) {
    state.conversations = conversations
  },
  SET_CURRENT_CONVERSATION(state, conversation) {
    state.currentConversation = conversation
  },
  SET_SPECIALISTS(state, specialists) {
    state.specialists = specialists
  },
  ADD_CONVERSATION(state, conversation) {
    state.conversations.unshift(conversation)
  },
  ADD_MESSAGES(state, messages) {
    if (state.currentConversation) {
      state.currentConversation.messages.push(...messages)
    }
  }
}

const actions = {
  async fetchSpecialists({ commit }) {
    try {
      const response = await api.get('/api/v1/specialists')
      commit('SET_SPECIALISTS', response.data.specialists)
    } catch (error) {
      commit('SET_ERROR', 'Failed to fetch specialists')
    }
  },
  
  async fetchConversations({ commit }) {
    commit('SET_LOADING', true)
    try {
      const response = await api.get('/api/v1/conversations')
      commit('SET_CONVERSATIONS', response.data.conversations)
    } catch (error) {
      commit('SET_ERROR', 'Failed to fetch conversations')
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async createConversation({ commit }, { specialistType, title }) {
    try {
      const response = await api.post('/api/v1/conversations', {
        conversation: {
          specialist_type: specialistType,
          title
        }
      })
      const conversation = response.data.conversation
      commit('ADD_CONVERSATION', conversation)
      commit('SET_CURRENT_CONVERSATION', conversation)
      return { success: true, conversation }
    } catch (error) {
      const message = error.response?.data?.errors?.join(', ') || 'Failed to create conversation'
      commit('SET_ERROR', message)
      return { success: false, error: message }
    }
  },
  
  async loadConversation({ commit }, conversationId) {
    commit('SET_LOADING', true)
    try {
      const response = await api.get(`/api/v1/conversations/${conversationId}`)
      commit('SET_CURRENT_CONVERSATION', response.data.conversation)
    } catch (error) {
      commit('SET_ERROR', 'Failed to load conversation')
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async sendMessage({ commit }, { conversationId, content }) {
    try {
      const response = await api.post(`/api/v1/conversations/${conversationId}/messages`, {
        message: { content }
      })
      commit('ADD_MESSAGES', response.data.messages)
      return { success: true }
    } catch (error) {
      const message = error.response?.data?.errors?.join(', ') || 'Failed to send message'
      commit('SET_ERROR', message)
      return { success: false, error: message }
    }
  },
  
  clearCurrentConversation({ commit }) {
    commit('SET_CURRENT_CONVERSATION', null)
  }
}

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
}