/*
 Navicat Premium Dump SQL

 Source Server         : deep_research
 Source Server Type    : PostgreSQL
 Source Server Version : 180001 (180001)
 Source Host           : localhost:5432
 Source Catalog        : deep_research
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 180001 (180001)
 File Encoding         : 65001

 Date: 15/04/2026 14:42:20
*/


-- ----------------------------
-- Table structure for file_metadata
-- ----------------------------
DROP TABLE IF EXISTS "public"."file_metadata";
CREATE TABLE "public"."file_metadata" (
  "id" int4 NOT NULL,
  "file_id" int4 NOT NULL,
  "source" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "title" varchar(256) COLLATE "pg_catalog"."default" NOT NULL,
  "authors" varchar(255) COLLATE "pg_catalog"."default",
  "institutions" varchar(255) COLLATE "pg_catalog"."default",
  "publish_year" timestamp(6),
  "keywords" jsonb DEFAULT '[]'::jsonb,
  "abstract" text COLLATE "pg_catalog"."default",
  "language" varchar(32) COLLATE "pg_catalog"."default",
  "created_time" timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "update_time" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Records of file_metadata
-- ----------------------------
INSERT INTO "public"."file_metadata" VALUES (5, 5, 'arxiv', 'A Survey on RAG Meeting LLMs: Towards Retrieval-Augmented Large Language Models', 'Wenqi Fan, Shijie Wang, Yujuan Ding, Hengyun Li, Liangbo Ning, Dawei Yin, Tat-Seng Chua, Qing Li', 'The Hong Kong Polytechnic University; Baidu Inc.; National University of Singapore', '2024-01-01 00:00:00', 'arXiv预印本', '["RAG", "LLM", "Retrieval-Augmented Generation", "Survey"]', 'This survey reviews retrieval-augmented large language models from the perspectives of architecture, training strategies, and applications.', 'en', '2026-03-15 20:09:42.280356', '2026-03-15 20:09:42.280356');
INSERT INTO "public"."file_metadata" VALUES (4, 4, 'arxiv', 'DeepResearcher: Scaling Deep Research via Reinforcement Learning in Real-world Environments', 'Yuxiang Zheng, Dayuan Fu, Xiangkun Hu, Xiaojie Cai, Lyumanshan Ye, Pengrui Lu, Pengfei Liu', 'Shanghai Jiao Tong University; Shanghai Innovation Institute; Generative AI Research Lab (GAIR)', '2024-01-01 00:00:00', 'arXiv预印本', '["Deep Research", "Reinforcement Learning", "Web Search", "LLM Agent", "NLP"]', 'DeepResearcher presents a reinforcement learning framework for training deep research agents in real-world web environments.', 'en', '2026-03-15 20:09:42.280356', '2026-03-15 20:09:42.280356');
INSERT INTO "public"."file_metadata" VALUES (3, 3, 'arxiv', 'DeepResearch Arena: The First Exam of LLMs’ Research Abilities via Seminar-Grounded Tasks', 'Haiyuan Wan, Chen Yang, Junchi Yu, Meiqi Tu, Jiaxuan Lu, Di Yu, Jianbao Cao, Ben Gao, Jiaqing Xie, Aoran Wang, Wenlong Zhang, Philip Torr, Dongzhan Zhou', 'Shanghai Artificial Intelligence Laboratory; Tsinghua University; The Hong Kong University of Science and Technology, Guangzhou; University of Oxford; The University of Hong Kong; Wuhan University', '2024-01-01 00:00:00', 'arXiv预印本', '["Deep Research Benchmark", "LLM Evaluation", "Seminar-Grounded Tasks", "Arena", "NLP"]', 'DeepResearch Arena introduces a benchmark grounded in academic seminars to evaluate the research capabilities of deep research agents.', 'en', '2026-03-15 20:09:42.280356', '2026-03-15 20:09:42.280356');
INSERT INTO "public"."file_metadata" VALUES (2, 2, 'arxiv', 'Deep Research Agents: A Systematic Examination and Roadmap', 'Yuxuan Huang, Yihang Chen, Haozheng Zhang, Kang Li, Huichi Zhou, Meng Fang, Linyi Yang, Xiaoguang Li, Lifeng Shang, Songcen Xu, Jianye Hao, Kun Shao, Jun Wang', 'University of Liverpool; Huawei Noah’s Ark Lab; University of Oxford; University College London', '2024-01-01 00:00:00', 'arXiv预印本', '["Deep Research Agent", "LLM Agent", "Tool Use", "Adaptive Planning", "Survey", "NLP"]', 'This paper provides a systematic review of deep research agents, including their architectures, retrieval mechanisms, tool use, workflows, and benchmarks.', 'en', '2026-03-15 20:09:42.280356', '2026-03-15 20:09:42.280356');
INSERT INTO "public"."file_metadata" VALUES (1, 1, 'arxiv', 'ReAct: Synergizing Reasoning and Acting in Language Models', 'Shunyu Yao, Jeffrey Zhao, Dian Yu, Nan Du, Izhak Shafran, Karthik Narasimhan, Yuan Cao', 'Princeton University; Google Research', '2024-01-01 00:00:00', 'ICLR 2023', '["LLM Agent", "Reasoning", "Action Planning", "ReAct", "Prompting", "NLP"]', 'ReAct proposes a paradigm that interleaves reasoning traces and task-specific actions in large language models, enabling interactive problem solving.', 'en', '2026-03-15 20:09:42.280356', '2026-03-15 20:09:42.280356');

-- ----------------------------
-- Primary Key structure for table file_metadata
-- ----------------------------
ALTER TABLE "public"."file_metadata" ADD CONSTRAINT "file_metadata_pk" PRIMARY KEY ("id");
