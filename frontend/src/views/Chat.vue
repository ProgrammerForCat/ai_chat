<template>
  <div class="chat-container">
    <!-- Sidebar -->
    <div class="sidebar">
      <div class="sidebar-header">
        <button @click="showSpecialistSelector" class="new-chat-btn">
          + 新しい相談
        </button>
        <button @click="handleLogout" class="logout-btn">
          ログアウト
        </button>
      </div>
      
      <div class="conversations-list">
        <div
          v-for="conversation in conversations"
          :key="conversation.id"
          @click="selectConversation(conversation.id)"
          :class="['conversation-item', { active: currentConversation?.id === conversation.id }]"
        >
          <div class="conversation-title">{{ conversation.title }}</div>
          <div class="conversation-meta">
            {{ getSpecialistName(conversation.specialist_type) }} • 
            {{ formatDate(conversation.created_at) }}
          </div>
        </div>
      </div>
    </div>
    
    <!-- Main Chat Area -->
    <div class="main-content">
      <!-- Specialist Selector -->
      <div v-if="showSelector" class="specialist-selector">
        <h2>どの専門家に相談しますか？</h2>
        <div class="specialists-grid">
          <div
            v-for="specialist in specialists"
            :key="specialist.id"
            @click="startNewConversation(specialist.id)"
            class="specialist-card"
          >
            <div class="specialist-icon">{{ specialist.icon }}</div>
            <div class="specialist-name">{{ specialist.name }}</div>
            <div class="specialist-description">{{ specialist.description }}</div>
          </div>
        </div>
      </div>
      
      <!-- Chat Area -->
      <div v-else-if="currentConversation" class="chat-area">
        <div class="chat-header">
          <h3>{{ getSpecialistName(currentConversation.specialist_type) }}</h3>
        </div>
        
        <div class="messages-container" ref="messagesContainer">
          <div
            v-for="message in currentConversation.messages"
            :key="message.id"
            :class="['message', message.role]"
          >
            <div class="message-content">
              <div v-if="message.role === 'assistant'" v-html="renderMarkdown(message.content)"></div>
              <div v-else>{{ message.content }}</div>
            </div>
            <div class="message-time">
              {{ formatDateTime(message.created_at) }}
            </div>
          </div>
          
          <!-- 送信中のメッセージ -->
          <div v-if="pendingMessage" class="message user">
            <div class="message-content">
              {{ pendingMessage }}
            </div>
            <div class="message-time">
              {{ formatDateTime(new Date().toISOString()) }}
            </div>
          </div>
          
          <!-- ローディングスピナー -->
          <div v-if="loading && pendingMessage" class="message assistant">
            <div class="message-content loading-content">
              <div class="loading-spinner">
                <div class="spinner"></div>
                <span>返答を生成中...</span>
              </div>
            </div>
          </div>
        </div>
        
        <div class="message-input-area">
          <div class="message-input-container">
            <input
              v-model="newMessage"
              @keyup.enter="handleSendMessage"
              :placeholder="loading ? '返答を待っています...' : 'メッセージを入力...'"
              :disabled="loading"
            />
            <button @click="handleSendMessage" :disabled="loading || !newMessage.trim()">
              <span v-if="loading">送信中...</span>
              <span v-else>送信</span>
            </button>
          </div>
        </div>
      </div>
      
      <!-- Empty State -->
      <div v-else class="empty-state">
        <h2>AI専門相談チャットへようこそ</h2>
        <p>左側のメニューから「新しい相談」をクリックして始めましょう</p>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import { marked } from 'marked'

export default {
  name: 'Chat',
  data() {
    return {
      showSelector: false,
      newMessage: '',
      pendingMessage: null
    }
  },
  computed: {
    ...mapGetters('auth', ['user']),
    ...mapGetters('chat', [
      'conversations',
      'currentConversation',
      'specialists',
      'loading',
      'error'
    ])
  },
  async created() {
    try {
      await this.initializeAuth()
      await this.loadData()
    } catch (error) {
      console.error('Initialization error:', error)
      this.$router.push('/login')
    }
  },
  methods: {
    ...mapActions('auth', ['logout', 'initializeAuth']),
    ...mapActions('chat', [
      'fetchSpecialists',
      'fetchConversations',
      'createConversation',
      'loadConversation',
      'sendMessage',
      'clearCurrentConversation'
    ]),
    
    async loadData() {
      await Promise.all([
        this.fetchSpecialists(),
        this.fetchConversations()
      ])
    },
    
    showSpecialistSelector() {
      this.showSelector = true
      this.clearCurrentConversation()
    },
    
    async startNewConversation(specialistType) {
      const result = await this.createConversation({
        specialistType,
        title: null
      })
      
      if (result.success) {
        this.showSelector = false
        await this.fetchConversations()
      }
    },
    
    async selectConversation(conversationId) {
      this.showSelector = false
      await this.loadConversation(conversationId)
      this.$nextTick(() => {
        setTimeout(() => {
          this.scrollToBottom()
        }, 500)
      })
    },
    
    async handleSendMessage() {
      if (!this.newMessage.trim() || !this.currentConversation || this.loading) return
      
      const messageContent = this.newMessage.trim()
      this.newMessage = ''
      this.pendingMessage = messageContent
      
      this.$nextTick(() => {
        this.scrollToBottom()
      })
      
      try {
        const result = await this.sendMessage({
          conversationId: this.currentConversation.id,
          content: messageContent
        })
        
        this.pendingMessage = null
        
        if (result.success) {
          await this.fetchConversations()
          setTimeout(() => {
            this.scrollToBottom()
          }, 500)
        } else {
          console.error('Send message failed:', result.error)
          this.newMessage = messageContent
        }
      } catch (error) {
        console.error('Send message error:', error)
        this.newMessage = messageContent
        this.pendingMessage = null
      }
    },
    
    async handleLogout() {
      await this.logout()
      this.$router.push('/login')
    },
    
    getSpecialistName(type) {
      const specialist = this.specialists.find(s => s.id === type)
      return specialist ? specialist.name : type
    },
    
    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString('ja-JP')
    },
    
    formatTime(dateString) {
      return new Date(dateString).toLocaleTimeString('ja-JP', {
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    
    formatDateTime(dateString) {
      return new Date(dateString).toLocaleString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    
    scrollToBottom() {
      const container = this.$refs.messagesContainer
      if (container) {
        container.scrollTop = container.scrollHeight
      }
    },
    
    renderMarkdown(content) {
      if (!content) return ''
      return marked(content, {
        breaks: true,
        gfm: true
      })
    }
  }
}
</script>

<style scoped>
.chat-container {
  display: flex;
  height: 100vh;
}

.sidebar {
  width: 300px;
  background: #2d3748;
  color: white;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 20px;
  border-bottom: 1px solid #4a5568;
}

.new-chat-btn, .logout-btn {
  width: 100%;
  padding: 12px;
  margin-bottom: 10px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
}

.logout-btn {
  background: #e53e3e;
}

.new-chat-btn:hover {
  background: #3182ce;
}

.logout-btn:hover {
  background: #c53030;
}

.conversations-list {
  flex: 1;
  overflow-y: auto;
  padding: 0 20px;
}

.conversation-item {
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.conversation-item:hover {
  background: #4a5568;
}

.conversation-item.active {
  background: #4299e1;
}

.conversation-title {
  font-weight: 500;
  margin-bottom: 4px;
}

.conversation-meta {
  font-size: 12px;
  color: #a0aec0;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: white;
}

.specialist-selector {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.specialist-selector h2 {
  margin-bottom: 32px;
  color: #2d3748;
}

.specialists-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  max-width: 800px;
}

.specialist-card {
  padding: 24px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.specialist-card:hover {
  border-color: #4299e1;
  box-shadow: 0 4px 12px rgba(66, 153, 225, 0.1);
}

.specialist-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.specialist-name {
  font-size: 18px;
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 8px;
}

.specialist-description {
  color: #718096;
  font-size: 14px;
}

.chat-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

.chat-header {
  padding: 20px;
  border-bottom: 1px solid #e2e8f0;
  background: #f7fafc;
}

.chat-header h3 {
  color: #2d3748;
  margin: 0;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px 40px;
  min-height: 0;
}

.message {
  margin-bottom: 16px;
  display: flex;
  flex-direction: column;
}

.message.user {
  align-items: flex-end;
}

.message.assistant {
  align-items: flex-start;
  margin-left: 20px;
}

.message-content {
  max-width: 85%;
  padding: 16px 20px 16px 28px;
  border-radius: 12px;
  word-wrap: break-word;
}

.message.user .message-content {
  background: #4299e1;
  color: white;
}

.message.assistant .message-content {
  background: #f7fafc;
  color: #2d3748;
  border: 1px solid #e2e8f0;
}

.message-content h1,
.message-content h2,
.message-content h3 {
  margin: 12px 0 8px 0;
  color: #2d3748;
}

.message-content h1 {
  font-size: 1.2em;
  border-bottom: 2px solid #e2e8f0;
  padding-bottom: 4px;
}

.message-content h2 {
  font-size: 1.1em;
}

.message-content h3 {
  font-size: 1.05em;
}

.message-content code {
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.85em;
  color: #e53e3e;
}

.message-content pre {
  background: #2d3748;
  color: #f7fafc;
  padding: 12px;
  border-radius: 6px;
  overflow-x: auto;
  margin: 8px 0;
}

.message-content pre code {
  background: none;
  padding: 0;
  color: inherit;
  font-size: 0.9em;
}

.message-content strong {
  font-weight: 600;
}

.message-content em {
  font-style: italic;
}

.message-content a {
  color: #4299e1;
  text-decoration: none;
}

.message-content a:hover {
  text-decoration: underline;
}

.message-content ul,
.message-content ol {
  margin: 8px 0;
  padding-left: 20px;
}

.message-content li {
  margin: 2px 0;
}

.message-content blockquote {
  border-left: 4px solid #e2e8f0;
  padding-left: 12px;
  margin: 8px 0;
  color: #718096;
}

.loading-content {
  display: flex;
  align-items: center;
  padding: 12px 16px;
}

.loading-spinner {
  display: flex;
  align-items: center;
  gap: 8px;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid #e2e8f0;
  border-top: 2px solid #4299e1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-spinner span {
  color: #718096;
  font-size: 14px;
}

.message-time {
  font-size: 12px;
  color: #718096;
  margin-top: 4px;
}

.message-input-area {
  padding: 20px;
  border-top: 1px solid #e2e8f0;
  background: #f7fafc;
}

.message-input-container {
  display: flex;
  gap: 12px;
}

.message-input-container input {
  flex: 1;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 24px;
  font-size: 16px;
}

.message-input-container input:focus {
  outline: none;
  border-color: #4299e1;
}

.message-input-container button {
  padding: 12px 24px;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 24px;
  cursor: pointer;
  font-weight: 500;
}

.message-input-container button:hover:not(:disabled) {
  background: #3182ce;
}

.message-input-container button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #718096;
}

.empty-state h2 {
  margin-bottom: 16px;
}
</style>