<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const isDarkMode = ref(false)

const toggleDarkMode = () => {
  isDarkMode.value = !isDarkMode.value
  document.documentElement.classList.toggle('my-app-dark')
}

const items = ref([
  {
    label: 'Home',
    icon: 'pi pi-home',
    command: () => router.push({ name: 'dashboard' })
  },
  {
    label: 'Workshops',
    icon: 'pi pi-calendar',
    command: () => router.push({ name: 'attendee-catalog' })
  },
  {
    label: 'Sessions',
    icon: 'pi pi-list',
    command: () => router.push({ name: 'sessions-browse' })
  },
  {
    label: 'Admin Workshops',
    icon: 'pi pi-briefcase',
    command: () => router.push({ name: 'admin-workshops' })
  },
  {
    label: 'My registrations',
    icon: 'pi pi-user',
    command: () => router.push({ name: 'attendee-history' })
  },
  {
    label: 'Component Catalog',
    icon: 'pi pi-th-large',
    command: () => router.push({ name: 'components-guide' })
  }
])
</script>

<template>
  <Toast />
  <ConfirmDialog />

  <div class="app-layout">
    <header class="app-header">
      <Menubar :model="items" class="custom-menubar">
        <template #start>
          <div class="brand" @click="router.push({ name: 'dashboard' })">
            <i class="pi pi-box brand-icon"></i>
            <span class="brand-name">SeatForge</span>
          </div>
        </template>
        <template #end>
          <div class="nav-end">
            <Button
              :icon="isDarkMode ? 'pi pi-sun' : 'pi pi-moon'"
              :label="isDarkMode ? 'Light Mode' : 'Dark Mode'"
              severity="secondary"
              variant="text"
              size="small"
              @click="toggleDarkMode"
            />
          </div>
        </template>
      </Menubar>
    </header>

    <main class="app-content">
      <RouterView />
    </main>

    <footer class="app-footer">
      <p>SeatForge &copy; 2026 - Built with Vue 3 & PrimeVue 4</p>
    </footer>
  </div>
</template>

<style>
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  background-color: #f8fafc;
  color: #1e293b;
}

.my-app-dark body {
  background-color: #090d16;
  color: #f1f5f9;
}

.app-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
}

.custom-menubar {
  border-radius: 0 !important;
  border-left: none !important;
  border-right: none !important;
  border-top: none !important;
  padding: 0.75rem 2rem !important;
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(8px);
}

.my-app-dark .custom-menubar {
  background: rgba(15, 23, 42, 0.95) !important;
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-right: 2rem;
  cursor: pointer;
}

.brand-icon {
  font-size: 1.5rem;
  color: #10b981;
}

.brand-name {
  font-weight: 800;
  font-size: 1.25rem;
  color: #0f172a;
}

.my-app-dark .brand-name {
  color: #f8fafc;
}

.nav-end {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.app-content {
  flex: 1;
}

.app-footer {
  text-align: center;
  padding: 1.5rem;
  color: #94a3b8;
  font-size: 0.875rem;
  border-top: 1px solid #e2e8f0;
  background: #ffffff;
}

.my-app-dark .app-footer {
  background: #0f172a;
  border-top-color: #1e293b;
  color: #64748b;
}

.doc-link {
  text-decoration: none;
}
</style>
