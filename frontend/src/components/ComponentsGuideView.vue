<script setup lang="ts">
import { ref, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'

const toast = useToast()
const confirm = useConfirm()

const searchQuery = ref('')
const selectedCategory = ref('all')

const categories = [
  { label: 'All', value: 'all', icon: 'pi pi-th-large' },
  { label: 'Forms', value: 'forms', icon: 'pi pi-file-edit' },
  { label: 'Buttons', value: 'buttons', icon: 'pi pi-send' },
  { label: 'Tables & Data', value: 'data', icon: 'pi pi-table' },
  { label: 'Panels & Layout', value: 'panels', icon: 'pi pi-box' },
  { label: 'Feedback & Overlays', value: 'feedback', icon: 'pi pi-bell' },
]

const textVal = ref('')
const numberVal = ref(42)
const passwordVal = ref('')
const selectedCity = ref(null)
const cities = ref([
  { name: 'Madrid', code: 'MAD' },
  { name: 'Barcelona', code: 'BCN' },
  { name: 'Valencia', code: 'VLC' },
  { name: 'Sevilla', code: 'SVQ' }
])
const switchVal = ref(true)
const checkboxVal = ref(true)
const radioVal = ref('A')
const sliderVal = ref(60)
const ratingVal = ref(4)

const isDialogVisible = ref(false)
const progressVal = ref(75)

const tableData = ref([
  { id: 1, name: 'Seat 101', section: 'North Zone', status: 'Available', price: '$50' },
  { id: 2, name: 'Seat 102', section: 'North Zone', status: 'Occupied', price: '$50' },
  { id: 3, name: 'Seat 201', section: 'VIP Lounge', status: 'Reserved', price: '$120' },
  { id: 4, name: 'Seat 202', section: 'VIP Lounge', status: 'Available', price: '$120' }
])

const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'Available': return 'success'
    case 'Occupied': return 'danger'
    case 'Reserved': return 'warn'
    default: return 'info'
  }
}

const showToastSuccess = () => {
  toast.add({ severity: 'success', summary: 'Action Successful', detail: 'The Toast component is working correctly.', life: 3000 })
}

const showConfirm = () => {
  confirm.require({
    message: 'Are you sure you want to run this test?',
    header: 'Test Confirmation',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Yes, continue',
    rejectLabel: 'Cancel',
    accept: () => {
      toast.add({ severity: 'info', summary: 'Confirmed', detail: 'You accepted the action.', life: 3000 })
    }
  })
}

const activeCodeTab = ref<Record<string, boolean>>({})
const toggleCode = (section: string) => {
  activeCodeTab.value[section] = !activeCodeTab.value[section]
}

const isCategoryVisible = (cat: string) => {
  if (selectedCategory.value !== 'all' && selectedCategory.value !== cat) return false
  if (!searchQuery.value) return true
  const query = searchQuery.value.toLowerCase()
  return cat.toLowerCase().includes(query) || query.includes(cat)
}
</script>

<template>
  <div class="guide-container">
    <header class="guide-header">
      <h1>PrimeVue 4 Component Guide</h1>
      <p class="subtitle">
        Interactive catalog of the PrimeVue components available to speed up project development.
      </p>

      <div class="controls-bar">
        <IconField iconPosition="left" class="search-field">
          <InputIcon class="pi pi-search" />
          <InputText v-model="searchQuery" placeholder="Search component..." class="w-full" />
        </IconField>

        <div class="category-pills">
          <Button
            v-for="cat in categories"
            :key="cat.value"
            :label="cat.label"
            :icon="cat.icon"
            :variant="selectedCategory === cat.value ? undefined : 'outlined'"
            :severity="selectedCategory === cat.value ? 'primary' : 'secondary'"
            size="small"
            @click="selectedCategory = cat.value"
          />
        </div>
      </div>
    </header>

    <section v-if="isCategoryVisible('forms')" class="component-section">
      <div class="section-title">
        <i class="pi pi-file-edit text-primary"></i>
        <h2>1. Form Inputs</h2>
        <Button
          :label="activeCodeTab['forms'] ? 'Hide Code' : 'View Vue Code'"
          icon="pi pi-code"
          variant="text"
          severity="secondary"
          size="small"
          class="ml-auto"
          @click="toggleCode('forms')"
        />
      </div>

      <Card>
        <template #content>
          <div class="form-grid">
            <div class="field">
              <label>InputText</label>
              <InputText v-model="textVal" placeholder="Type something..." />
              <small>Value: {{ textVal }}</small>
            </div>

            <div class="field">
              <label>InputNumber</label>
              <InputNumber v-model="numberVal" showButtons :min="0" :max="100" />
            </div>

            <div class="field">
              <label>Password</label>
              <Password v-model="passwordVal" toggleMask placeholder="Password" />
            </div>

            <div class="field">
              <label>Select (Dropdown)</label>
              <Select v-model="selectedCity" :options="cities" optionLabel="name" placeholder="Select a city" />
            </div>

            <div class="field flex-row">
              <ToggleSwitch v-model="switchVal" id="sw" />
              <label for="sw">ToggleSwitch (On)</label>
            </div>

            <div class="field flex-row">
              <Checkbox v-model="checkboxVal" :binary="true" id="chk" />
              <label for="chk">Checkbox (Checked)</label>
            </div>

            <div class="field">
              <label>Slider ({{ sliderVal }})</label>
              <Slider v-model="sliderVal" class="mt-2" />
            </div>

            <div class="field">
              <label>Rating</label>
              <Rating v-model="ratingVal" />
            </div>
          </div>

          <div v-if="activeCodeTab['forms']" class="code-block">
            <pre><code>&lt;script setup&gt;
import { ref } from 'vue'

const textVal = ref('')
const numberVal = ref(42)
const passwordVal = ref('')
const selectedCity = ref(null)
const cities = [{ name: 'Madrid' }, { name: 'Barcelona' }]
const switchVal = ref(true)
const ratingVal = ref(4)
&lt;/script&gt;

&lt;template&gt;
  &lt;InputText v-model="textVal" placeholder="Text..." /&gt;
  &lt;InputNumber v-model="numberVal" showButtons /&gt;
  &lt;Password v-model="passwordVal" toggleMask /&gt;
  &lt;Select v-model="selectedCity" :options="cities" optionLabel="name" /&gt;
  &lt;ToggleSwitch v-model="switchVal" /&gt;
  &lt;Rating v-model="ratingVal" /&gt;
&lt;/template&gt;</code></pre>
          </div>
        </template>
      </Card>
    </section>

    <section v-if="isCategoryVisible('buttons')" class="component-section">
      <div class="section-title">
        <i class="pi pi-send text-primary"></i>
        <h2>2. Buttons & Variants</h2>
        <Button
          :label="activeCodeTab['buttons'] ? 'Hide Code' : 'View Vue Code'"
          icon="pi pi-code"
          variant="text"
          severity="secondary"
          size="small"
          class="ml-auto"
          @click="toggleCode('buttons')"
        />
      </div>

      <Card>
        <template #content>
          <div class="buttons-demo">
            <h4>Severities</h4>
            <div class="button-row">
              <Button label="Primary" />
              <Button label="Secondary" severity="secondary" />
              <Button label="Success" severity="success" icon="pi pi-check" />
              <Button label="Info" severity="info" icon="pi pi-info-circle" />
              <Button label="Warn" severity="warn" icon="pi pi-exclamation-triangle" />
              <Button label="Help" severity="help" icon="pi pi-question-circle" />
              <Button label="Danger" severity="danger" icon="pi pi-times" />
            </div>

            <h4 class="mt-4">Variant Styles (Variants & Options)</h4>
            <div class="button-row">
              <Button label="Outlined" variant="outlined" />
              <Button label="Text" variant="text" />
              <Button label="Rounded" rounded />
              <Button icon="pi pi-heart" rounded severity="danger" aria-label="Favorite" />
              <Button label="Badge" icon="pi pi-bell" badge="3" severity="info" />
              <Button label="Loading" loading />
            </div>
          </div>

          <div v-if="activeCodeTab['buttons']" class="code-block mt-3">
            <pre><code>&lt;Button label="Primary" /&gt;
&lt;Button label="Success" severity="success" icon="pi pi-check" /&gt;
&lt;Button label="Danger" severity="danger" icon="pi pi-times" /&gt;

&lt;Button label="Outlined" variant="outlined" /&gt;
&lt;Button label="Text" variant="text" /&gt;
&lt;Button label="Rounded" rounded /&gt;
&lt;Button icon="pi pi-heart" rounded severity="danger" /&gt;
&lt;Button label="Notifications" icon="pi pi-bell" badge="5" severity="info" /&gt;</code></pre>
          </div>
        </template>
      </Card>
    </section>

    <section v-if="isCategoryVisible('data')" class="component-section">
      <div class="section-title">
        <i class="pi pi-table text-primary"></i>
        <h2>3. Tables & Data Display</h2>
        <Button
          :label="activeCodeTab['data'] ? 'Hide Code' : 'View Vue Code'"
          icon="pi pi-code"
          variant="text"
          severity="secondary"
          size="small"
          class="ml-auto"
          @click="toggleCode('data')"
        />
      </div>

      <Card>
        <template #content>
          <DataTable :value="tableData" stripedRows paginator :rows="3" responsiveLayout="scroll">
            <Column field="id" header="ID" sortable></Column>
            <Column field="name" header="Name / Seat" sortable></Column>
            <Column field="section" header="Section"></Column>
            <Column field="status" header="Status">
              <template #body="slotProps">
                <Tag :value="slotProps.data.status" :severity="getStatusSeverity(slotProps.data.status)" />
              </template>
            </Column>
            <Column field="price" header="Price"></Column>
          </DataTable>

          <div class="tags-chips-demo mt-4">
            <h4>Tags, Badges & Chips</h4>
            <div class="button-row">
              <Tag value="Available" severity="success" />
              <Tag value="Reserved" severity="warn" />
              <Badge value="12" severity="info" />
              <Chip label="VIP Seat" icon="pi pi-star-fill" />
            </div>
          </div>

          <div v-if="activeCodeTab['data']" class="code-block mt-3">
            <pre><code>&lt;script setup&gt;
import { ref } from 'vue'

const items = ref([
  { id: 1, name: 'Seat 101', section: 'North Zone', status: 'Available' },
  { id: 2, name: 'Seat 102', section: 'North Zone', status: 'Occupied' }
])
&lt;/script&gt;

&lt;template&gt;
  &lt;DataTable :value="items" stripedRows paginator :rows="5"&gt;
    &lt;Column field="id" header="ID" sortable /&gt;
    &lt;Column field="name" header="Name" /&gt;
    &lt;Column field="status" header="Status"&gt;
      &lt;template #body="slotProps"&gt;
        &lt;Tag :value="slotProps.data.status" severity="success" /&gt;
      &lt;/template&gt;
    &lt;/Column&gt;
  &lt;/DataTable&gt;
&lt;/template&gt;</code></pre>
          </div>
        </template>
      </Card>
    </section>

    <section v-if="isCategoryVisible('panels')" class="component-section">
      <div class="section-title">
        <i class="pi pi-box text-primary"></i>
        <h2>4. Panels & Containers</h2>
        <Button
          :label="activeCodeTab['panels'] ? 'Hide Code' : 'View Vue Code'"
          icon="pi pi-code"
          variant="text"
          severity="secondary"
          size="small"
          class="ml-auto"
          @click="toggleCode('panels')"
        />
      </div>

      <div class="panels-grid">
        <Panel header="Collapsible Panel" toggleable>
          <p class="m-0">
            This is a PrimeVue Panel component with support for collapsing and expanding.
          </p>
        </Panel>

        <Accordion value="0">
          <AccordionPanel value="0">
            <AccordionHeader>FAQ #1</AccordionHeader>
            <AccordionContent>
              <p class="m-0">
                PrimeVue v4 components are fully adapted to Vue 3's Composition API.
              </p>
            </AccordionContent>
          </AccordionPanel>
          <AccordionPanel value="1">
            <AccordionHeader>FAQ #2</AccordionHeader>
            <AccordionContent>
              <p class="m-0">
                You can change the theme at runtime or customize Design Tokens.
              </p>
            </AccordionContent>
          </AccordionPanel>
        </Accordion>
      </div>

      <Card v-if="activeCodeTab['panels']" class="mt-3">
        <template #content>
          <div class="code-block">
            <pre><code>&lt;Panel header="My Panel" toggleable&gt;
  &lt;p&gt;Panel content...&lt;/p&gt;
&lt;/Panel&gt;

&lt;Accordion value="0"&gt;
  &lt;AccordionPanel value="0"&gt;
    &lt;AccordionHeader&gt;Title 1&lt;/AccordionHeader&gt;
    &lt;AccordionContent&gt;Content 1&lt;/AccordionContent&gt;
  &lt;/AccordionPanel&gt;
&lt;/Accordion&gt;</code></pre>
          </div>
        </template>
      </Card>
    </section>

    <section v-if="isCategoryVisible('feedback')" class="component-section">
      <div class="section-title">
        <i class="pi pi-bell text-primary"></i>
        <h2>5. Messages, Dialogs & Notifications</h2>
        <Button
          :label="activeCodeTab['feedback'] ? 'Hide Code' : 'View Vue Code'"
          icon="pi pi-code"
          variant="text"
          severity="secondary"
          size="small"
          class="ml-auto"
          @click="toggleCode('feedback')"
        />
      </div>

      <Card>
        <template #content>
          <div class="feedback-demo">
            <h4>Alert Messages</h4>
            <div class="messages-list mb-4">
              <Message severity="success">Operation completed successfully.</Message>
              <Message severity="info">Important information about your account.</Message>
              <Message severity="warn">Warning: Review the entered parameters.</Message>
            </div>

            <h4>Progress Bar</h4>
            <ProgressBar :value="progressVal" class="mb-4" />

            <h4>Overlay Services (Toast, Confirm, Dialog)</h4>
            <div class="button-row">
              <Button label="Trigger Toast" icon="pi pi-bell" severity="success" @click="showToastSuccess" />
              <Button label="Trigger ConfirmDialog" icon="pi pi-exclamation-circle" severity="warn" @click="showConfirm" />
              <Button label="Open Dialog Modal" icon="pi pi-window-maximize" severity="info" @click="isDialogVisible = true" />
            </div>

            <Dialog v-model:visible="isDialogVisible" modal header="Test Dialog" :style="{ width: '30rem' }">
              <p class="m-0">
                This is an interactive popup modal using PrimeVue's <code>&lt;Dialog /&gt;</code> component.
              </p>
              <template #footer>
                <Button label="Close" icon="pi pi-check" @click="isDialogVisible = false" />
              </template>
            </Dialog>
          </div>

          <div v-if="activeCodeTab['feedback']" class="code-block mt-3">
            <pre><code>&lt;script setup&gt;
import { ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'

const toast = useToast()
const confirm = useConfirm()
const isDialogVisible = ref(false)

const triggerToast = () => {
  toast.add({ severity: 'success', summary: 'Success', detail: 'Message sent', life: 3000 })
}
&lt;/script&gt;

&lt;template&gt;
  &lt;Toast /&gt;
  &lt;ConfirmDialog /&gt;

  &lt;Button label="Toast" @click="triggerToast" /&gt;
  &lt;Button label="Modal" @click="isDialogVisible = true" /&gt;

  &lt;Dialog v-model:visible="isDialogVisible" modal header="Title"&gt;
    &lt;p&gt;Modal content...&lt;/p&gt;
  &lt;/Dialog&gt;
&lt;/template&gt;</code></pre>
          </div>
        </template>
      </Card>
    </section>
  </div>
</template>

<style scoped>
.guide-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2.5rem 1.5rem;
}

.guide-header {
  margin-bottom: 3rem;
  text-align: center;
}

.guide-header h1 {
  font-size: 2.5rem;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #64748b;
  font-size: 1.1rem;
  margin-bottom: 2rem;
}

.controls-bar {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  align-items: center;
  margin-top: 1.5rem;
}

.search-field {
  width: 100%;
  max-width: 500px;
}

.category-pills {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  justify-content: center;
}

.component-section {
  margin-bottom: 3rem;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.section-title h2 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}

.section-title i {
  font-size: 1.5rem;
  color: #10b981;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1.5rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field.flex-row {
  flex-direction: row;
  align-items: center;
}

.buttons-demo h4, .tags-chips-demo h4, .feedback-demo h4 {
  font-size: 1rem;
  color: #475569;
  margin-bottom: 0.75rem;
}

.button-row {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
  align-items: center;
}

.panels-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 1.5rem;
}

.messages-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.code-block {
  background: #0f172a;
  color: #e2e8f0;
  padding: 1.25rem;
  border-radius: 8px;
  overflow-x: auto;
  font-family: 'Fira Code', monospace, sans-serif;
  font-size: 0.88rem;
  line-height: 1.5;
}

.code-block pre {
  margin: 0;
}

.ml-auto {
  margin-left: auto;
}

.mt-2 { margin-top: 0.5rem; }
.mt-3 { margin-top: 0.75rem; }
.mt-4 { margin-top: 1rem; }
.mb-3 { margin-bottom: 0.75rem; }
.mb-4 { margin-bottom: 1rem; }
.w-full { width: 100%; }
</style>
