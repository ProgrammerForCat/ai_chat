<template>
  <div id="app">
    <n-message-provider>
      <router-view />
    </n-message-provider>
  </div>
</template>

<script>
import { NMessageProvider } from 'naive-ui'

export default {
  name: 'App',
  components: {
    NMessageProvider
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background-color: #f7fafc;
}

#app {
  min-height: 100vh;
}
</style>