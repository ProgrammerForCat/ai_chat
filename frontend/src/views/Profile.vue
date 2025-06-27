<template>
  <div class="profile">
    <n-card title="プロフィール設定" class="profile-card">
      <n-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-placement="left"
        label-width="120px"
      >
        <n-form-item label="メールアドレス" path="email">
          <n-input
            v-model:value="formData.email"
            placeholder="メールアドレス"
            disabled
          />
        </n-form-item>
        
        <n-form-item label="ユーザー名" path="username">
          <n-input
            v-model:value="formData.username"
            placeholder="ユーザー名を入力"
          />
        </n-form-item>
        
        <n-form-item label="Gemini APIキー" path="gemini_api_key">
          <n-input
            v-model:value="formData.gemini_api_key"
            type="password"
            show-password-on="click"
            placeholder="Gemini APIキーを入力"
          />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button
            type="primary"
            :loading="loading"
            @click="handleUpdate"
          >
            保存
          </n-button>
          <n-button @click="handleReset">
            リセット
          </n-button>
          <n-button @click="goBack">
            戻る
          </n-button>
        </n-space>
      </template>
    </n-card>
  </div>
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import { useStore } from 'vuex'
import { useRouter } from 'vue-router'
import { useMessage } from 'naive-ui'
import api from '../services/api'

export default {
  name: 'Profile',
  setup() {
    const store = useStore()
    const router = useRouter()
    const message = useMessage()
    const formRef = ref()
    const loading = ref(false)
    
    const formData = reactive({
      email: '',
      username: '',
      gemini_api_key: ''
    })
    
    const originalData = reactive({
      email: '',
      username: '',
      gemini_api_key: ''
    })
    
    const rules = {
      username: [
        {
          required: false,
          message: 'ユーザー名を入力してください',
          trigger: ['input', 'blur']
        }
      ],
      gemini_api_key: [
        {
          required: false,
          message: 'Gemini APIキーを入力してください',
          trigger: ['input', 'blur']
        }
      ]
    }
    
    const loadProfile = async () => {
      try {
        const response = await api.get('/api/v1/users/profile')
        const userData = response.data.user
        
        formData.email = userData.email
        formData.username = userData.username || ''
        formData.gemini_api_key = userData.gemini_api_key || ''
        
        // Keep original data for reset
        originalData.email = userData.email
        originalData.username = userData.username || ''
        originalData.gemini_api_key = userData.gemini_api_key || ''
      } catch (error) {
        console.error('プロフィール取得エラー:', error)
        message.error('プロフィール情報の取得に失敗しました')
      }
    }
    
    const handleUpdate = async () => {
      try {
        await formRef.value?.validate()
        loading.value = true
        
        const updateData = {
          username: formData.username,
          gemini_api_key: formData.gemini_api_key
        }
        
        await api.put('/api/v1/users/profile', updateData)
        
        // Update original data
        originalData.username = formData.username
        originalData.gemini_api_key = formData.gemini_api_key
        
        message.success('プロフィールを更新しました')
      } catch (error) {
        console.error('プロフィール更新エラー:', error)
        if (error.response?.data?.error) {
          message.error(error.response.data.error)
        } else {
          message.error('プロフィールの更新に失敗しました')
        }
      } finally {
        loading.value = false
      }
    }
    
    const handleReset = () => {
      formData.username = originalData.username
      formData.gemini_api_key = originalData.gemini_api_key
    }
    
    const goBack = () => {
      router.push('/')
    }
    
    onMounted(() => {
      loadProfile()
    })
    
    return {
      formRef,
      formData,
      rules,
      loading,
      handleUpdate,
      handleReset,
      goBack
    }
  }
}
</script>

<style scoped>
.profile {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.profile-card {
  width: 100%;
  max-width: 500px;
}
</style>