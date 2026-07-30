import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
    },
    {
      path: '/components',
      name: 'components-guide',
      component: () => import('../components/ComponentsGuideView.vue'),
    },
  ],
})

export default router
