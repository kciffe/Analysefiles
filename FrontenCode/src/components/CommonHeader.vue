<!-- 顶部信息栏 -->
<template>
    <div class="header">
        <div class="l-content">
            <!-- <el-button size="small">
                <component class="icons" :is="Menu"></component>
            </el-button> -->
            <el-button class="open-icon" size="small" text @click="handleCollapsed">
                <el-icon :size="20">
                    <Menu />
                </el-icon>
            </el-button>

            <el-breadcrumb separator="/" class="bread">
                <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            </el-breadcrumb>
        </div>
        <div class="r-content">
            <el-dropdown>
                <span class="el-dropdown-link">
                    <img :src="getImageUrl('user')" class="user" />
                </span>
                <template #dropdown>
                    <el-dropdown-menu>
                        <el-dropdown-item>个人中心</el-dropdown-item>
                        <el-dropdown-item>退出登录</el-dropdown-item>
                    </el-dropdown-menu>
                </template>
            </el-dropdown>
        </div>
    </div>
</template>


<script setup>
import { useAllDataStore } from '@/store';
const store = useAllDataStore()
const handleCollapsed = () => {
    store.state.iscollapsed = !store.state.iscollapsed
}
const getImageUrl = (user) => {
    return new URL(`../assets/images/${user}.png`, import.meta.url).href
}
</script>

<style lang="less" scoped>
.header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    height: 100%;
    width: 100%;
    background-color: #333;
}

.icons {
    width: 20px;
    height: 20px;
}

.l-content {
    display: flex;
    align-items: center;

    .el-button {
        margin-right: 20px;
    }
}

.open-icon {
    color: #fff;
}

.open-icon:hover {
    color: #409eff;
}

.r-content {
    .user {
        width: 40px;
        height: 40px;
        border-radius: 50%;
    }
}

:deep(.bread span) {
    color: #fff !important;
    cursor: pointer !important;
}
</style>