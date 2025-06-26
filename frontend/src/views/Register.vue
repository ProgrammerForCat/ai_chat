<template>
  <div class="register-container">
    <div class="register-card">
      <h1>新規登録</h1>
      <p>アカウントを作成してAI専門家と相談を始めましょう</p>
      
      <form @submit.prevent="handleRegister" class="register-form">
        <div class="form-group">
          <label for="email">メールアドレス</label>
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            placeholder="your@email.com"
          />
        </div>
        
        <div class="form-group">
          <label for="password">パスワード</label>
          <input
            id="password"
            v-model="form.password"
            type="password"
            required
            placeholder="6文字以上のパスワード"
            minlength="6"
          />
        </div>
        
        <div class="form-group">
          <label for="password_confirmation">パスワード確認</label>
          <input
            id="password_confirmation"
            v-model="form.password_confirmation"
            type="password"
            required
            placeholder="パスワードを再入力"
          />
        </div>
        
        <div class="error-message" v-if="error">
          {{ error }}
        </div>
        
        <button type="submit" :disabled="loading" class="register-button">
          {{ loading ? '登録中...' : '新規登録' }}
        </button>
      </form>
      
      <p class="login-link">
        すでにアカウントをお持ちの方は
        <router-link to="/login">ログイン</router-link>
      </p>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'Register',
  data() {
    return {
      form: {
        email: '',
        password: '',
        password_confirmation: ''
      }
    }
  },
  computed: {
    ...mapGetters('auth', ['loading', 'error'])
  },
  methods: {
    ...mapActions('auth', ['register']),
    
    async handleRegister() {
      if (this.form.password !== this.form.password_confirmation) {
        alert('パスワードが一致しません')
        return
      }
      
      const result = await this.register(this.form)
      if (result.success) {
        this.$router.push('/')
      }
    }
  }
}
</script>

<style scoped>
.register-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.register-card {
  background: white;
  padding: 40px;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

h1 {
  text-align: center;
  color: #2d3748;
  margin-bottom: 8px;
  font-size: 24px;
  font-weight: 600;
}

p {
  text-align: center;
  color: #718096;
  margin-bottom: 32px;
}

.register-form {
  width: 100%;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 8px;
  color: #2d3748;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.2s;
}

input:focus {
  outline: none;
  border-color: #667eea;
}

.error-message {
  color: #e53e3e;
  background: #fed7d7;
  padding: 12px;
  border-radius: 8px;
  margin-bottom: 20px;
  font-size: 14px;
}

.register-button {
  width: 100%;
  padding: 12px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.register-button:hover:not(:disabled) {
  background: #5a67d8;
}

.register-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.login-link {
  text-align: center;
  margin-top: 24px;
  color: #718096;
}

.login-link a {
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
}

.login-link a:hover {
  text-decoration: underline;
}
</style>