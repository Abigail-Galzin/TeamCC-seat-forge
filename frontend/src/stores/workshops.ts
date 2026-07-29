import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { Workshop, WorkshopFormData } from '@/types/workshop'

const mockWorkshops: Workshop[] = [
  {
    id: 1,
    title: 'Introducción a Vue 3',
    description: 'Fundamentos de Composition API, reactividad y componentes reutilizables.',
    topic: 'Frontend',
    active: true,
  },
  {
    id: 2,
    title: 'Rails API desde cero',
    description: 'Construcción de endpoints RESTful con Rails 8 y buenas prácticas.',
    topic: 'Backend',
    active: true,
  },
  {
    id: 3,
    title: 'Testing con Vitest',
    description: 'Pruebas unitarias y de integración para aplicaciones Vue.',
    topic: 'Quality',
    active: false,
  },
  {
    id: 4,
    title: 'Diseño de sistemas con PrimeVue',
    description: 'Patrones de UI, temas y accesibilidad con PrimeVue 4.',
    topic: 'UI/UX',
    active: true,
  },
]

export const useWorkshopsStore = defineStore('workshops', () => {
  const workshops = ref<Workshop[]>([...mockWorkshops])
  let nextId = workshops.value.length + 1

  function getAll(): Workshop[] {
    return workshops.value
  }

  function getById(id: number): Workshop | undefined {
    return workshops.value.find((w) => w.id === id)
  }

  function create(data: WorkshopFormData): Workshop {
    const workshop: Workshop = { id: nextId++, ...data }
    workshops.value = [...workshops.value, workshop]
    return workshop
  }

  function update(id: number, data: WorkshopFormData): Workshop | null {
    const index = workshops.value.findIndex((w) => w.id === id)
    if (index === -1) return null

    const updated: Workshop = { id, ...data }
    workshops.value = workshops.value.map((w) => (w.id === id ? updated : w))
    return updated
  }

  return { workshops, getAll, getById, create, update }
})
