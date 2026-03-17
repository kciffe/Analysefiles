
// 统一路径
export const API = {
  UploadParse: {
    // PARSE: 'http://127.0.0.1:4523/m2/7688138-7430664-default/405628960?apifoxApiId=405628960',         
    PARSE: '/docs/upload/parse',
    INGEST: '/uploadparse/ingest',
  },
  Home: {
    TableList: '/406379757',
  },
  CategoryLevels: {
    // GET: 'http://127.0.0.1:4523/m2/7688138-7430664-default/408437682',//调试用
    GET: '/query/labels',
    UPDATE: 'http://127.0.0.1:4523/m2/7688138-7430664-default/408519059',
  },
  RequirementList: {
    LIST: 'http://127.0.0.1:4523/m2/7688138-7430664-default/410494771',  // GET  获取需求列表 调试用
    CREATE: '/requirements/parse',
    REMOVE: (_id: string) => 'http://127.0.0.1:4523/m2/7688138-7430664-default/410511662',
    RUN: (_id: string) => 'http://127.0.0.1:4523/m2/7688138-7430664-default/410499925',
    REPORT: (id: string) => `/requirements/${id}/result`,
  },
} as const

