<template>
  <div class="page">
    <!-- 顶部检索区 -->
    <el-card class="card" shadow="never">
      <div class="card-title">
        <div class="title">本地文档检索</div>
        <div class="sub">支持多维条件筛选；全部留空则默认全量检索</div>
      </div>

      <el-form :model="form" label-width="92px" class="form" @submit.prevent>
        <div class="form-grid">
          <el-form-item label="原文档ID">
            <el-input v-model="form.origin_doc_id" placeholder="源文件的检索ID" clearable />
          </el-form-item>

          <el-form-item label="文档ID">
            <el-input v-model="form.doc_id" placeholder="结构化文档的检索ID" clearable />
          </el-form-item>

          <el-form-item label="文件名">
            <el-input v-model="form.filename" placeholder="支持模糊匹配" clearable />
          </el-form-item>

          <el-form-item label="文档类型">
            <el-select v-model="form.doc_type" placeholder="请选择" clearable filterable>
              <el-option v-for="x in docTypeOptions" :key="x" :label="x" :value="x" />
            </el-select>
          </el-form-item>

          <el-form-item label="来源">
            <el-input v-model="form.source" placeholder="ACL / arxiv / 本地上传" clearable />
          </el-form-item>

          <el-form-item label="关键词">
            <el-input v-model="form.keyword" placeholder="支持模糊匹配，如 NLP / Transformer" clearable />
          </el-form-item>

          <el-form-item label="出版年份">
            <div class="year-range">
              <el-input v-model="form.year_from" placeholder="起始" clearable />
              <span class="sep">~</span>
              <el-input v-model="form.year_to" placeholder="截止" clearable />
            </div>
          </el-form-item>
        </div>

        <div class="form-actions">
          <el-button type="primary" :loading="loading" @click="onSearch">查询</el-button>
          <el-button :disabled="loading" @click="onReset">重置</el-button>
          <div class="meta">
            <el-tag type="info" effect="plain">共 {{ total }} 条</el-tag>
          </div>
        </div>
      </el-form>
    </el-card>

    <!-- 列表区 -->
    <el-card class="card" shadow="never">
      <div class="list-head">
        <div class="list-title">文件列表</div>
        <div class="list-hint">点击“检视”查看结构化信息与章节；支持下载原文与导出解析文</div>
      </div>

      <el-table
        :data="list"
        v-loading="loading"
        class="table"
        height="520"
        border
      >
        <el-table-column prop="doc_id" label="文档ID" width="90" />
        <el-table-column prop="origin_doc_id" label="原文档ID" width="100" />
        <el-table-column prop="filename" label="文件名" min-width="220" show-overflow-tooltip />

        <el-table-column prop="authors" label="作者" min-width="140" show-overflow-tooltip />
        <el-table-column prop="source" label="来源" width="120" />
        <el-table-column prop="publish_time" label="出版时间" width="120" />

        <el-table-column prop="doc_type" label="文档类型" width="120" />

        <el-table-column label="关键词" min-width="180">
          <template #default="{ row }">
            <div class="kw">
              <el-tag
                v-for="(k, idx) in (row.keywords || []).slice(0, 3)"
                :key="idx"
                effect="plain"
                size="small"
                class="kw-tag"
              >
                {{ k }}
              </el-tag>
              <span v-if="(row.keywords || []).length > 3" class="kw-more">
                +{{ row.keywords.length - 3 }}
              </span>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="openInspect(row)">检视</el-button>
            <el-button type="danger" link @click="confirmDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          layout="total, prev, pager, next, sizes"
          :page-sizes="[10, 20, 50]"
          @current-change="fetchList"
          @size-change="onPageSizeChange"
        />
      </div>
    </el-card>

    <!-- 检视 Drawer -->
    <el-drawer
      v-model="inspectOpen"
      size="56%"
      :with-header="false"
      destroy-on-close
    >
      <div class="drawer">
        <div class="drawer-head">
          <div>
            <div class="drawer-title">文档基础信息</div>
            <div class="drawer-sub" v-if="detail">
              DocID：{{ detail.doc_id }} ｜ 文件：{{ detail.filename }}
            </div>
          </div>

          <div class="drawer-actions">
            <el-button
              type="primary"
              plain
              :disabled="!detail"
              @click="downloadOriginal"
            >
              下载原文
            </el-button>
            <el-button
              type="primary"
              :disabled="!detail"
              @click="exportParsed"
            >
              导出解析文
            </el-button>
          </div>
        </div>

        <el-divider />

        <!-- 基础信息表 -->
        <el-descriptions v-if="detail" :column="2" border>
          <el-descriptions-item label="文档ID">{{ detail.doc_id }}</el-descriptions-item>
          <el-descriptions-item label="原文档ID">{{ detail.origin_doc_id }}</el-descriptions-item>

          <el-descriptions-item label="文件名" :span="2">
            {{ detail.filename }}
          </el-descriptions-item>

          <el-descriptions-item label="文档类型">{{ detail.doc_type }}</el-descriptions-item>
          <el-descriptions-item label="语言">{{ detail.language }}</el-descriptions-item>

          <el-descriptions-item label="来源">{{ detail.source }}</el-descriptions-item>
          <el-descriptions-item label="出版时间">{{ detail.publish_time }}</el-descriptions-item>

          <el-descriptions-item label="作者" :span="2">
            {{ detail.authors }}
          </el-descriptions-item>

          <el-descriptions-item label="状态">{{ detail.status }}</el-descriptions-item>
          <el-descriptions-item label="关键词">
            <div class="kw">
              <el-tag
                v-for="(k, idx) in detail.keywords || []"
                :key="idx"
                effect="plain"
                size="small"
                class="kw-tag"
              >
                {{ k }}
              </el-tag>
            </div>
          </el-descriptions-item>
        </el-descriptions>

        <el-empty v-else description="暂无文档信息" />

        <el-divider />

        <!-- 章节列表 -->
        <div class="sec-title">章节结构</div>
        <el-table
          v-if="detail"
          :data="detail.sections || []"
          border
          class="sec-table"
        >
          <el-table-column prop="name" label="章节名" min-width="180" show-overflow-tooltip />
          <el-table-column prop="pages" label="页码" width="110" />
          <el-table-column prop="summary" label="内容摘要" min-width="240" show-overflow-tooltip />

          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button type="primary" link @click="viewSectionText(row)">
                查看全文
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div v-if="detail" class="sec-hint">
          入库前可人工修改章节摘要或校验章节结构，提升质量。
        </div>
      </div>
    </el-drawer>

    <!-- 全文弹窗 -->
    <el-dialog
      v-model="textDialogOpen"
      width="720px"
      destroy-on-close
      :title="textDialogTitle"
    >
      <div class="text-wrap" v-loading="textLoading">
        <pre class="text-pre">{{ sectionText }}</pre>
      </div>

      <template #footer>
        <el-button @click="textDialogOpen = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'

/**
 * 你需要改的地方：接口路径（按你后端实际实现改）
 * - search: 多条件检索
 * - detail: 获取文档详情（含 sections）
 * - delete: 删除文档
 * - sectionText: 获取章节全文
 * - downloadOriginal: 下载原文（blob）
 * - exportParsed: 导出解析文（blob）
 */
const API = {
  search: '/localdocs/search', // GET params: ...filters,page,page_size
  detail: (docId: string | number) => `/localdocs/${docId}`,
  remove: (docId: string | number) => `/localdocs/${docId}`,
  sectionText: (docId: string | number, sectionId: string | number) =>
    `/localdocs/${docId}/sections/${sectionId}/text`,
  downloadOriginal: (docId: string | number) => `/localdocs/${docId}/download`,
  exportParsed: (docId: string | number) => `/localdocs/${docId}/export`,
}

type SectionItem = {
  id: string | number
  name: string
  pages: string
  summary: string
}

type DocSummary = {
  doc_id: string | number
  origin_doc_id?: string | number
  filename: string
  authors?: string
  source?: string
  publish_time?: string
  doc_type?: string
  keywords?: string[]
}

type DocDetail = DocSummary & {
  language?: string
  status?: string
  sections?: SectionItem[]
}

const docTypeOptions = ref<string[]>([
  'ACL',
  'CVPR',
  '专利',
  '技术报告',
  '其他',
])

// 表单（不填=全量）
const form = reactive({
  origin_doc_id: '',
  doc_id: '',
  filename: '',
  doc_type: '',
  source: '',
  keyword: '',
  year_from: '',
  year_to: '',
})

const loading = ref(false)
const list = ref<DocSummary[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(10)

async function fetchList() {
  loading.value = true
  try {
    const params = buildQueryParams()
    const resp = await axios.get(API.search, { params })

    // 你后端建议返回：{ items: DocSummary[], total: number }
    const data = resp.data
    list.value = Array.isArray(data?.items) ? data.items : Array.isArray(data) ? data : []
    total.value = typeof data?.total === 'number' ? data.total : list.value.length
  } catch (e: any) {
    ElMessage.error(e?.message || '检索失败')
  } finally {
    loading.value = false
  }
}

function buildQueryParams() {
  const params: Record<string, any> = {
    page: page.value,
    page_size: pageSize.value,
  }
  // 只把非空字段带上（否则后端不好区分）
  Object.entries(form).forEach(([k, v]) => {
    const vv = String(v ?? '').trim()
    if (vv) params[k] = vv
  })
  return params
}

function onSearch() {
  page.value = 1
  fetchList()
}

function onReset() {
  form.origin_doc_id = ''
  form.doc_id = ''
  form.filename = ''
  form.doc_type = ''
  form.source = ''
  form.keyword = ''
  form.year_from = ''
  form.year_to = ''
  page.value = 1
  fetchList()
}

function onPageSizeChange() {
  page.value = 1
  fetchList()
}

/** 删除 */
async function confirmDelete(row: DocSummary) {
  try {
    await ElMessageBox.confirm(
      `是否删除该文档？\n文档ID：${row.doc_id}\n文件名：${row.filename}`,
      '删除确认',
      { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消', closeOnClickModal: false }
    )
    await axios.delete(API.remove(row.doc_id))
    ElMessage.success('删除成功')
    fetchList()
  } catch {
    // cancel
  }
}

/** 检视 Drawer */
const inspectOpen = ref(false)
const detail = ref<DocDetail | null>(null)

async function openInspect(row: DocSummary) {
  inspectOpen.value = true
  detail.value = null

  try {
    const resp = await axios.get(API.detail(row.doc_id))
    detail.value = resp.data as DocDetail
  } catch (e: any) {
    ElMessage.error(e?.message || '获取详情失败')
  }
}

/** 查看章节全文 */
const textDialogOpen = ref(false)
const textLoading = ref(false)
const sectionText = ref('')
const textDialogTitle = computed(() => currentSectionTitle.value || '章节全文')
const currentSectionTitle = ref('')

async function viewSectionText(sec: SectionItem) {
  if (!detail.value) return
  textDialogOpen.value = true
  sectionText.value = ''
  currentSectionTitle.value = sec.name
  textLoading.value = true

  try {
    const resp = await axios.get(API.sectionText(detail.value.doc_id, sec.id))
    // 后端建议返回：{ text: "..." }，也可直接返回 string
    const data = resp.data
    sectionText.value = typeof data === 'string' ? data : (data?.text ?? '')
    if (!sectionText.value) sectionText.value = '(无内容)'
  } catch (e: any) {
    ElMessage.error(e?.message || '获取全文失败')
    sectionText.value = '(获取失败)'
  } finally {
    textLoading.value = false
  }
}

/** 下载/导出 */
async function downloadOriginal() {
  if (!detail.value) return
  await downloadBlob(API.downloadOriginal(detail.value.doc_id), `${detail.value.filename || 'original'}`)
}

async function exportParsed() {
  if (!detail.value) return
  const base = detail.value.filename ? detail.value.filename.replace(/\.[^.]+$/, '') : 'parsed'
  await downloadBlob(API.exportParsed(detail.value.doc_id), `${base}_parsed.json`)
}

async function downloadBlob(url: string, filename: string) {
  try {
    const resp = await axios.get(url, { responseType: 'blob' })
    const blob = resp.data as Blob
    triggerDownload(blob, filename)
    ElMessage.success('已开始下载')
  } catch (e: any) {
    ElMessage.error(e?.message || '下载失败')
  }
}

function triggerDownload(blob: Blob, filename: string) {
  const a = document.createElement('a')
  const href = URL.createObjectURL(blob)
  a.href = href
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(href)
}

// 初次进入：默认全量
fetchList()
</script>

<style scoped>
.page {
  width: 100%;
  min-height: 100%;
  padding: 18px 20px;
  box-sizing: border-box;
  background: #f6f7fb;
}

/* 卡片统一 */
.card {
  border-radius: 14px;
  border: 1px solid #e8eef8;
  margin-bottom: 14px;
}

.card-title {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 14px;
}

.title {
  font-size: 18px;
  font-weight: 900;
  color: #111827;
}

.sub {
  font-size: 12px;
  color: #6b7280;
}

/* 表单 */
.form-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(240px, 1fr));
  gap: 6px 18px;
  align-items: start;
}

.year-range {
  display: flex;
  align-items: center;
  gap: 10px;
}

.sep {
  color: #9ca3af;
}

.form-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}

.meta {
  margin-left: auto;
}

/* 列表头 */
.list-head {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 10px;
}

.list-title {
  font-size: 16px;
  font-weight: 900;
  color: #111827;
}

.list-hint {
  font-size: 12px;
  color: #6b7280;
}

.table {
  border-radius: 12px;
  overflow: hidden;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
}

/* 关键词展示 */
.kw {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
}

.kw-tag {
  border-radius: 999px;
}

.kw-more {
  font-size: 12px;
  color: #6b7280;
}

/* Drawer */
.drawer {
  padding: 18px 18px 26px;
}

.drawer-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.drawer-title {
  font-size: 16px;
  font-weight: 900;
  color: #111827;
}

.drawer-sub {
  margin-top: 6px;
  font-size: 12px;
  color: #6b7280;
}

.drawer-actions {
  display: inline-flex;
  gap: 10px;
  align-items: center;
}

.sec-title {
  font-size: 14px;
  font-weight: 900;
  color: #111827;
  margin-bottom: 10px;
}

.sec-table {
  border-radius: 12px;
  overflow: hidden;
}

.sec-hint {
  margin-top: 10px;
  font-size: 12px;
  color: #6b7280;
}

/* 全文 */
.text-wrap {
  max-height: 520px;
  overflow: auto;
  background: #0b1020;
  border-radius: 10px;
  padding: 12px 12px;
}

.text-pre {
  margin: 0;
  color: #e5e7eb;
  font-size: 12px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

/* Element Plus 细节美化 */
:deep(.el-input__wrapper),
:deep(.el-select__wrapper) {
  border-radius: 10px;
}

:deep(.el-button) {
  border-radius: 10px;
}
</style>
