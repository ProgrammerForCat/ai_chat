import { createStore } from 'vuex'
import auth from './modules/auth'
import chat from './modules/chat'

export default createStore({
  modules: {
    auth,
    chat
  }
})