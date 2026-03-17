export interface UiNode {
  id: string; //用 path.join(' / ') 作为稳定 id
  name: string;
  level: number;
  path: string[];
  children?: UiNode[];
}

export interface CategoryLevelDict {
  [name: string]: string[]; // childrenNameList
}

