import { createRouter, createWebHashHistory, type RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'main',
    component: () => import('@/view/Main.vue'),
    redirect: '/home',
    children: [
      {
        path: '/home',
        name: 'home',
        component: () => import('@/view/Home.vue'),
        meta: { title: '首页总览' },
      },
      {
        path: '/RequirementList',
        name: 'RequirementList',
        component: () => import('@/view/RequirementList.vue'),
        meta: { title: '需求列表' },
      },
      {
        path: '/Share',
        name: 'Share',
        component: () => import('@/view/test.vue'),
        meta: { title: '已发布列表' },
      },
      {
        path: '/UploadParse',
        name: 'UploadParse',
        component: () => import('@/view/UploadParse.vue'),
        meta: { title: '上传本地文档' },
      },
      {
        path: '/UploadParseByMD',
        name: 'UploadParseByMD',
        component: () => import('@/view/UploadParseByMD.vue'),
        meta: { title: '上传文档(MD)' },
      },
      {
        path: '/SearchPaper',
        name: 'SearchPaper',
        component: () => import('@/view/SearchPaper.vue'),
        meta: { title: '数据库文档检索' },
      },
      {
        path: '/test',
        name: 'test',
        component: () => import('@/view/test.vue'),
        meta: { title: '测试' },
      },
      {
        path: '/CategoryLevelsManage',
        name: 'CategoryLevelsManage',
        component: () => import('@/view/CategoryLevelsManage.vue'),
        meta: { title: '文档标签管理' },
      },
      {
        path: '/RequirementCreate',
        name: 'RequirementCreate',
        component: () => import('@/view/RequirementCreate.vue'),
        meta: { title: '需求创建' },
      },
      {
        path: '/requirements/:id/report',
        name: 'RequirementReport',
        component: () => import('@/view/RequirementReport.vue'),
        meta: { title: '报告展示' },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

export default router
