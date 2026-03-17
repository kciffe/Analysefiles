<!-- 侧边栏 -->
<template>
    <el-aside :width="elAsideWidth" >
        <el-menu router :default-active="route.path" background-color="#545c64" text-color="#fff"
            :collapse="isCollapsed" :collapse-transition="false">
            <h3 v-show="!isCollapsed">技术分析系统</h3>
            <h3 v-show="isCollapsed">系统</h3>
            <!-- key 是 Vue 用来 区分每一项的唯一标识 -->
            <el-menu-item v-for="item in noChildren" :index="item.path" :key="item.path">
                <!-- “这个地方渲染什么组件，不写死，由 is 决定。” -->
                <!-- <component class="icons" :is="item.icon"></component> -->
                 <el-icon class="icons">
                        <component :is="item.icon" />
                    </el-icon>
                <span>{{ item.label }}</span>
            </el-menu-item>
            <el-sub-menu v-for="item in hasChildren" :index="item.path" :key="item.path">
                <template #title>
                    <!-- <component class="icons" :is="item.icon"></component> -->
                    <el-icon class="icons">
                        <component :is="item.icon" />
                    </el-icon>
                    <span>{{ item.label }}</span>
                </template>
                <el-menu-item v-for="(subItem) in item.children" :index="subItem.path" :key="subItem.path">
                    <component class="icons" :is="subItem.icon"></component>
                    <span>{{ subItem.label }}</span>
                </el-menu-item>

            </el-sub-menu>

        </el-menu>
    </el-aside>
</template>


<script lang="ts" setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAllDataStore } from '@/store'
import {
    Histogram,
    Comment,
    Share,
    Setting,
    LocationFilled,
    CircleClose,
} from '@element-plus/icons-vue'
const store = useAllDataStore()
const isCollapsed = computed(() => store.state.iscollapsed)
const elAsideWidth = computed(() => store.state.iscollapsed ? '64px' : '200px')
const route = useRoute()
const list = ref([
    {
        path: '/home',
        name: 'home',
        label: '首页总览',
        icon: Histogram,
        url: 'Home'
    },
    {
        path: '/RequirementList',
        name: 'RequirementList',
        label: '需求列表',
        icon: Comment,
        url: 'RequirementList'
    },
    {
        path: '/Share',
        name: 'Share',
        label: '已发布列表',
        icon: Share,
        url: 'Share'
    },
    {
        path: 'DataBase',
        label: '本地数据库管理',
        icon: LocationFilled,
        children: [
            {
                path: '/UploadParse',
                name: 'UploadParse',
                label: '上传本地文档',
                icon: Setting,
                url: 'UploadParse'
            },
            {
                path: '/UploadParseByMD',
                name: 'UploadParseByMD',
                label: '上传文档(MD)',
                icon: Setting,
                url: 'UploadParseByMD'
            },
            {
                path: '/SearchPaper',
                name: 'SearchPaper',
                label: '数据库文档检索',
                icon: Setting,
                url: 'SearchPaper'
            },
                        {
                path: '/CategoryLevelsManage',
                name: 'CategoryLevelsManage',
                label: '文档标签管理',
                icon: Setting,
                url: 'CategoryLevelsManage'
            },
        ]
    },
        {
        path: '/test',
        name: 'test',
        label: '测试',
        icon: CircleClose,
        url: 'test'
    },
])
const noChildren = computed(() => list.value.filter(item => !item.children))
const hasChildren = computed(() => list.value.filter(item => item.children))

</script>

<style lang="less" scoped>
.icons {
    width: 18px;
    height: 18px;
    margin-right: 20px;
}

.el-menu {
    border-right: none;

    h3 {
        line-height: 48px;
        color: #fff;
        text-align: center;
    }
}

.el-aside {
    height: 100%;
    background-color: #545c64;
}
</style>