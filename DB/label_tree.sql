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

 Date: 15/04/2026 14:28:59
*/


-- ----------------------------
-- Table structure for label_tree
-- ----------------------------
DROP TABLE IF EXISTS "public"."label_tree";
CREATE TABLE "public"."label_tree" (
  "id" int4 NOT NULL DEFAULT nextval('label_tree_id_seq'::regclass),
  "file_metadata_id" int4 NOT NULL,
  "top_label" varchar(128) COLLATE "pg_catalog"."default" NOT NULL,
  "mid_label" varchar(128) COLLATE "pg_catalog"."default" NOT NULL,
  "sub_label" varchar(128) COLLATE "pg_catalog"."default",
  "is_primary" bool DEFAULT false
)
;

-- ----------------------------
-- Primary Key structure for table label_tree
-- ----------------------------
ALTER TABLE "public"."label_tree" ADD CONSTRAINT "label_tree_pkey" PRIMARY KEY ("id");
