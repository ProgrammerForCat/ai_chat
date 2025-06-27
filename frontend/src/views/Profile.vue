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
          <n-button
            type="warning"
            @click="showPasswordModal = true"
          >
            パスワードを変更
          </n-button>
        </n-space>
      </template>
    </n-card>

    <n-modal
      v-model:show="showPasswordModal"
      preset="dialog"
      title="パスワードの変更"
      positive-text="変更"
      negative-text="キャンセル"
      @positive-click="handlePasswordUpdate"
      @negative-click="showPasswordModal = false"
    >
      <n-form
        ref="passwordFormRef"
        :model="passwordFormData"
        :rules="passwordRules"
        label-placement="left"
        label-width="120px"
      >
        <n-form-item label="現在のパスワード" path="current_password">
          <n-input
            v-model:value="passwordFormData.current_password"
            type="password"
            show-password-on="click"
            placeholder="現在のパスワード"
          />
        </n-form-item>
        <n-form-item label="新しいパスワード" path="new_password">
          <n-input
            v-model:value="passwordFormData.new_password"
            type="password"
            show-password-on="click"
            placeholder="新しいパスワード"
          />
        </n-form-item>
        <n-form-item label="新しいパスワード(確認)" path="new_password_confirmation">
          <n-input
            v-model:value="passwordFormData.new_password_confirmation"
            type="password"
            show-password-on="click"
            placeholder="新しいパスワードを再入力"
          />
        </n-form-item>
      </n-form>
    </n-modal>
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
    const passwordFormRef = ref()
    const loading = ref(false)
    const showPasswordModal = ref(false)
    
    const formData = reactive({
      email: '',
      username: '',
      gemini_api_key: ''
    })
    
    const passwordFormData = reactive({
      current_password: '',
      new_password: '',
      new_password_confirmation: ''
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

    const passwordRules = {
      current_password: [
        {
          required: true,
          message: '現在のパスワードを入力してください',
          trigger: ['input', 'blur']
        }
      ],
      new_password: [
        {
          required: true,
          message: '新しいパスワードを入力してください',
          trigger: ['input', 'blur']
        },
        {
          min: 6,
          message: 'パスワードは6文字以上である必要があります',
          trigger: ['input', 'blur']
        }
      ],
      new_password_confirmation: [
        {
          required: true,
          message: '新しいパスワードを再入力してください',
          trigger: ['input', 'blur']
        },
        {
          validator: (rule, value) => value === passwordFormData.new_password,
          message: '新しいパスワードと確認用パスワードが一致しません',
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

    const handlePasswordUpdate = async () => {
      try {
        await passwordFormRef.value?.validate()
        loading.value = true

        const updateData = {
          current_password: passwordFormData.current_password,
          new_password: passwordFormData.new_password,
          new_password_confirmation: passwordFormData.new_password_confirmation
        }

        await api.put('/api/v1/users/password', updateData)

        message.success('パスワードを更新しました')
        showPasswordModal.value = false
        // Clear password fields after successful update
        passwordFormData.current_password = ''
        passwordFormData.new_password = ''
        passwordFormData.new_password_confirmation = ''
      } catch (error) {
        console.error('パスワード更新エラー:', error)
        if (error.response?.data?.errors) {
          message.error(error.response.data.errors.join(', '))
        } else {
          message.error('パスワードの更新に失敗しました')
        }
      } finally {
        loading.value = false
      }
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
      goBack,
      passwordFormRef,
      passwordFormData,
      passwordRules,
      handlePasswordUpdate,
      showPasswordModal
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