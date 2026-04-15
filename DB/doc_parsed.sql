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

 Date: 15/04/2026 14:42:09
*/


-- ----------------------------
-- Table structure for doc_parsed
-- ----------------------------
DROP TABLE IF EXISTS "public"."doc_parsed";
CREATE TABLE "public"."doc_parsed" (
  "id" int4 NOT NULL,
  "doc_id" int4 NOT NULL,
  "full_text" text COLLATE "pg_catalog"."default" NOT NULL,
  "structure_info" jsonb NOT NULL,
  "parse_time" timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" varchar(32) COLLATE "pg_catalog"."default" NOT NULL,
  "error_info" text COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of doc_parsed
-- ----------------------------
INSERT INTO "public"."doc_parsed" VALUES (1, 1, '# REACT: SYNERGIZING REASONING AND ACTING IN LANGUAGE MODELS

Shunyu Yao*,1, Jeffrey Zhao2, Dian Yu2, Nan Du2, Izhak Shafran2, Karthik Narasimhan1, Yuan Cao2 

$^{1}$ Department of Computer Science, Princeton University 

2Google Research, Brain team 

1{shunyuy,karthikn}@princeton.edu 

2{jeffreyzhao,dianyu,dunanizhak,yuancao}@google.com 

# ABSTRACT

While large language models (LLMs) have demonstrated impressive performance across tasks in language understanding and interactive decision making, their abilities for reasoning (e.g. chain-of-thought prompting) and acting (e.g. action plan generation) have primarily been studied as separate topics. In this paper, we explore the use of LLMs to generate both reasoning traces and task-specific actions in an interleaved manner, allowing for greater synergy between the two: reasoning traces help the model induce, track, and update action plans as well as handle exceptions, while actions allow it to interface with and gather additional information from external sources such as knowledge bases or environments. We apply our approach, named ReAct, to a diverse set of language and decision making tasks and demonstrate its effectiveness over state-of-the-art baselines in addition to improved human interpretability and trustworthiness. Concretely, on question answering (HotpotQA) and fact verification (Fever), ReAct overcomes prevalent issues of hallucination and error propagation in chain-of-thought reasoning by interacting with a simple Wikipedia API, and generating human-like task-solving trajectories that are more interpretable than baselines without reasoning traces. Furthermore, on two interactive decision making benchmarks (ALFWorld and WebShop), ReAct outperforms imitation and reinforcement learning methods by an absolute success rate of $34\%$ and $10\%$ respectively, while being prompted with only one or two in-context examples. 

# 1 INTRODUCTION

A unique feature of human intelligence is the ability to seamlessly combine task-oriented actions with verbal reasoning (or inner speech, Alderson-Day & Fernyhough, 2015), which has been theorized to play an important role in human cognition for enabling self-regulation or strategization (Vygotsky, 1987; Luria, 1965; Fernyhough, 2010) and maintaining a working memory (Baddeley, 1992). Consider the example of cooking up a dish in the kitchen. Between any two specific actions, we may reason in language in order to track progress ("now that everything is cut, I should heat up the pot of water"), to handle exceptions or adjust the plan according to the situation ("I don''t have salt, so let me use soy sauce and pepper instead"), and to realize when external information is needed ("how do I prepare dough? Let me search on the Internet"). We may also act (open a cookbook to read the recipe, open the fridge, check ingredients) to support the reasoning and to answer questions ("What dish can I make right now?"). This tight synergy between "acting" and "reasoning" allows humans to learn new tasks quickly and perform robust decision making or reasoning, even under previously unseen circumstances or facing information uncertainties. 

Recent results have hinted at the possibility of combining verbal reasoning with interactive decision making in autonomous systems. On one hand, properly prompted large language models (LLMs) have demonstrated emergent capabilities to carry out several steps of reasoning traces to derive 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/d767ee13997fbafe7c9dcbe96cc4928a32350144f7ca7b4d9522d7fde7169436.jpg)



Figure 1: (1) Comparison of 4 prompting methods, (a) Standard, (b) Chain-of-thought (CoT, Reason Only), (c) Act-only, and (d) ReAct (Reason+Act), solving a HotpotQA (Yang et al., 2018) question. (2) Comparison of (a) Act-only and (b) ReAct prompting to solve an AlfWorld (Shridhar et al., 2020b) game. In both domains, we omit in-context examples in the prompt, and only show task solving trajectories generated by the model (Act, Thought) and the environment (Obs).


answers from questions in arithmetic, commonsense, and symbolic reasoning tasks (Wei et al., 2022). However, this "chain-of-thought" reasoning is a static black box, in that the model uses its own internal representations to generate thoughts and is not grounded in the external world, which limits its ability to reason reactively or update its knowledge. This can lead to issues like fact hallucination and error propagation over the reasoning process (Figure 1 (1b)). On the other hand, recent work has explored the use of pre-trained language models for planning and acting in interactive environments (Ahn et al., 2022; Nakano et al., 2021; Yao et al., 2020; Huang et al., 2022a), with a focus on predicting actions via language priors. These approaches usually convert multi-modal observations into text, use a language model to generate domain-specific actions or plans, and then use a controller to choose or execute them. However, they do not employ language models to reason abstractly about high-level goals or maintain a working memory to support acting, barring Huang et al. (2022b) who perform a limited form of verbal reasoning to reiterate spatial facts about the current state. Beyond such simple embodied tasks to interact with a few blocks, there have not been studies on how reasoning and acting can be combined in a synergistic manner for general task solving, and if such a combination can bring systematic benefits compared to reasoning or acting alone. 

In this work, we present ReAct, a general paradigm to combine reasoning and acting with language models for solving diverse language reasoning and decision making tasks (Figure 1). ReAct prompts LLMs to generate both verbal reasoning traces and actions pertaining to a task in an interleaved manner, which allows the model to perform dynamic reasoning to create, maintain, and adjust high-level plans for acting (reason to act), while also interact with the external environments (e.g. Wikipedia) to incorporate additional information into reasoning (act to reason). 

We conduct empirical evaluations of ReAct and state-of-the-art baselines on four diverse benchmarks: question answering (HotPotQA, Yang et al., 2018), fact verification (Fever, Thorne et al., 2018), text-based game (ALFWorld, Shridhar et al., 2020b), and webpage navigation (WebShop, Yao et al., 2022). For HotPotQA and Fever, with access to a Wikipedia API that the model can interact with, ReAct outperforms vanilla action generation models while being competitive with chain-of-thought reasoning $(\text{CoT})$ (Wei et al., 2022). The best approach overall is a combination of ReAct and CoT that allows for the use of both internal knowledge and externally obtained information during reasoning. On ALFWorld and WebShop, two or even one-shot ReAct prompting is able to outperform imitation or reinforcement learning methods trained with $10^{3} \sim 10^{5}$ task instances, with an absolute improvement of $34\%$ and $10\%$ in success rates respectively. We also demonstrate the importance of sparse, versatile reasoning in decision making by showing consistent advantages over controlled baselines with actions only. Besides general applicability and performance boost, the combination of reasoning and acting also contributes to model interpretability, trustworthiness, and diagnosability across all domains, as humans can readily distinguish information from model''s internal knowledge versus external environments, as well as inspect reasoning traces to understand the decision basis of model actions. 

To summarize, our key contributions are the following: (1) we introduce ReAct, a novel prompt-based paradigm to synergize reasoning and acting in language models for general task solving; (2) we perform extensive experiments across diverse benchmarks to showcase the advantage of ReAct in a few-shot learning setup over prior approaches that perform either reasoning or action generation in isolation; (3) we present systematic ablations and analysis to understand the importance of acting in reasoning tasks, and reasoning in interactive tasks; (4) we analyze the limitations of ReAct under the prompting setup (i.e. limited support of reasoning and acting behaviors), and perform initial finetuning experiments showing the potential of ReAct to improve with additional training data. Scaling up ReAct to train and operate on more tasks and combining it with complementary paradigms like reinforcement learning could further unlock the potential of large language models. 

# 2 REACT: SYNERGIZING REASONING + ACTING

Consider a general setup of an agent interacting with an environment for task solving. At time step $t$ , an agent receives an observation $o_t \in \mathcal{O}$ from the environment and takes an action $a_t \in \mathcal{A}$ following some policy $\pi(a_t | c_t)$ , where $c_t = (o_1, a_1, \dots, o_{t-1}, a_{t-1}, o_t)$ is the context to the agent. Learning a policy is challenging when the mapping $c_t \mapsto a_t$ is highly implicit and requires extensive computation. For example, the agent shown in Figure 1(1c) is unable to generate the correct final action (Act 4) to finish the QA task as it requires complex reasoning over the trajectory context (Question, Act 1-3, Obs 1-3). Similarly, the agent shown in Figure 1(2a) fails to comprehend from the context that sinkbasin 1 does not contain peppershaker 1, thus keep producing hallucinating actions. 

The idea of ReAct is simple: we augment the agent''s action space to $\hat{A} = \mathcal{A} \cup \mathcal{L}$ , where $\mathcal{L}$ is the space of language. An action $\hat{a}_t \in \mathcal{L}$ in the language space, which we will refer to as a thought or a reasoning trace, does not affect the external environment, thus leading to no observation feedback. Instead, a thought $\hat{a}_t$ aims to compose useful information by reasoning over the current context $c_t$ , and update the context $c_{t+1} = (c_t, \hat{a}_t)$ to support future reasoning or acting. As shown in Figure 1, there could be various types of useful thoughts, e.g. decomposing task goals and create action plans (2b, Act 1; 1d, Thought 1), injecting commonsense knowledge relevant to task solving (2b, Act 1), extracting important parts from observations (1d, Thought2, 4), track progress and transit action plans (2b, Act 8), handle exceptions and adjust action plans (1d, Thought 3), and so on. 

However, as the language space $\mathcal{L}$ is unlimited, learning in this augmented action space is difficult and requires strong language priors. In this paper, we mainly focus on the setup where a frozen large language model, PaLM-540B (Chowdhery et al., 2022) $^1$ , is prompted with few-shot in-context examples to generate both domain-specific actions and free-form language thoughts for task solving (Figure 1 (1d), (2b)). Each in-context example is a human trajectory of actions, thoughts, and environment observations to solve a task instance (see Appendix C). For the tasks where reasoning is of primary importance (Figure 1(1)), we alternate the generation of thoughts and actions so that the task-solving trajectory consists of multiple thought-action-observation steps. In contrast, for decision making tasks that potentially involve a large number of actions (Figure 1(2)), thoughts only need to 

appear sparsely in the most relevant positions of a trajectory, so we let the language model decide the asynchronous occurrence of thoughts and actions for itself. 

Since decision making and reasoning capabilities are integrated into a large language model, ReAct enjoys several unique features: A) Intuitive and easy to design: Designing ReAct prompts is straightforward as human annotators just type down their thoughts in language on top of their actions taken. No ad-hoc format choice, thought design, or example selection is used in this paper. We detail prompt design for each task in Sections 3 and 4. B) General and flexible: Due to the flexible thought space and thought-action occurrence format, ReAct works for diverse tasks with distinct action spaces and reasoning needs, including but not limited to QA, fact verification, text game, and web navigation. C) Performant and robust: ReAct shows strong generalization to new task instances while learning solely from one to six in-context examples, consistently outperforming baselines with only reasoning or acting across different domains. We also show in Section 3 additional benefits when finetuning is enabled, and in Section 4 how ReAct performance is robust to prompt selections. D) Human aligned and controllable: ReAct promises an interpretable sequential decision making and reasoning process where humans can easily inspect reasoning and factual correctness. Moreover, humans can also control or correct the agent behavior on the go by thought editing, as shown in Figure 5 in Section 4. 

# 3 KNOWLEDGE-INTENSIVE REASONING TASKS

We begin with knowledge-intensive reasoning tasks like multi-hop question answering and fact verification. As shown in Figure 1(1d), by interacting with a Wikipedia API, ReAct is able to retrieve information to support reasoning, while also use reasoning to target what to retrieve next, demonstrating a synergy of reasoning and acting. 

# 3.1 SETUP

Domains We consider two datasets challenging knowledge retrieval and reasoning: (1) Hot-PotQA (Yang et al., 2018), a multi-hop question answering benchmark that requires reasoning over two or more Wikipedia passages, and (2) FEVER (Thorne et al., 2018), a fact verification benchmark where each claim is annotated SUPPORTS, REFUTES, or NOT ENOUGH INFO, based on if there exists a Wikipedia passage to verify the claim. In this work, we operate in a question-only setup for both tasks, where models only receive the question/claim as input without access to support paragraphs, and have to rely on their internal knowledge or retrieve knowledge via interacting with an external environment to support reasoning. 

Action Space We design a simple Wikipedia web API with three types of actions to support interactive information retrieval: (1) search[entity], which returns the first 5 sentences from the corresponding entity wiki page if it exists, or else suggests top-5 similar entities from the Wikipedia search engine, (2) lookup[string], which would return the next sentence in the page containing string, simulating Ctrl+F functionality on the browser. (3) finish[answer], which would finish the current task with answer. We note that this action space mostly can only retrieve a small part of a passage based on exact passage name, which is significantly weaker than state-of-the-art lexical or neural retrievers. The purpose is to simulate how humans would interact with Wikipedia, and force models to retrieve via explicit reasoning in language. 

# 3.2 METHODS

ReAct Prompting For HotpotQA and Fever, we randomly select 6 and 3 cases $^2$ from the training set and manually compose ReAct-format trajectories to use as few-shot exemplars in the prompts. Similar to Figure 1(d), each trajectory consists of multiple thought-action-observation steps (i.e. dense thought), where free-form thoughts are used for various purposes. Specifically, we use a combination of thoughts that decompose questions ("I need to search x, find y, then find z"), extract information from Wikipedia observations ("x was started in 1844", "The paragraph does not tell x"), perform commonsense ("x is not y, so z must instead be...") or arithmetic reasoning (" $1844 < 1989$ ) guide 

<table><tr><td>Prompt Methoda</td><td>HotpotQA (EM)</td><td>Fever (Acc)</td></tr><tr><td>Standard</td><td>28.7</td><td>57.1</td></tr><tr><td>CoT (Wei et al., 2022)</td><td>29.4</td><td>56.3</td></tr><tr><td>CoT-SC (Wang et al., 2022a)</td><td>33.4</td><td>60.4</td></tr><tr><td>Act</td><td>25.7</td><td>58.9</td></tr><tr><td>ReAct</td><td>27.4</td><td>60.9</td></tr><tr><td>CoT-SC → ReAct</td><td>34.2</td><td>64.6</td></tr><tr><td>ReAct→CoT-SC</td><td>35.1</td><td>62.0</td></tr><tr><td>Supervised SoTAb</td><td>67.5</td><td>89.5</td></tr></table>


Table 1: PaLM-540B prompting results on HotpotQA and Fever.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/9507f00bb8d85c8aeb20dbe1500c95bc18b6e2407fb39c74afc6f2ab89b73915.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/c07ecb4731cf876b39669f82788cfd1ce69fd83fe8d48a58f9d29c3e9579e84f.jpg)



Figure 2: PaLM-540B prompting results with respect to number of $\mathrm{CO}\mathrm{T} - \mathrm{SC}$ samples used.


${}^{a}$ HotpotQA EM is 27.1,28.9,33.8 for Standard,CoT, CoT-SC in Wang et al. (2022b). 

$^b$ (Zhu et al., 2021; Lewis et al., 2020) 

search reformulation ("maybe I can search/look up x instead"), and synthesize the final answer ("...so the answer is x"). See Appendix C for more details. 

Baselines We systematically ablate ReAct trajectories to build prompts for multiple baselines (with formats as Figure 1(1a-1c)): (a) Standard prompting (Standard), which removes all thoughts, actions, observations in ReAct trajectories. (b) Chain-of-thought prompting (CoT) (Wei et al., 2022), which removes actions and observations and serve as a reasoning-only baseline. We also build a self-consistency baseline (CoT-SC) (Wang et al., 2022a;b) by sampling 21 CoT trajectories with decoding temperature 0.7 during inference and adopting the majority answer, which is found to consistently boost performance over CoT. (c) Acting-only prompt (Act), which removes thoughts in ReAct trajectories, loosely resembling how WebGPT (Nakano et al., 2021) interacts with the Internet to answer questions, though it operates on a different task and action space, and uses imitation and reinforcement learning instead of prompting. 

Combining Internal and External Knowledge As will be detail in Section 3.3, we observe that the problem solving process demonstrated by ReAct is more factual and grounded, whereas CoT is more accurate in formulating reasoning structure but can easily suffer from hallucinated facts or thoughts. We therefore propose to incorporate ReAct and CoT-SC, and let the model decide when to switch to the other method based on the following heuristics: A) ReAct $\rightarrow$ CoT-SC: when ReAct fails to return an answer within given steps, back off to CoT-SC. We set 7 and 5 steps for HotpotQA and FEVER respectively as we find more steps will not improve ReAct performance<sup>3</sup>. B) CoT-SC $\rightarrow$ ReAct: when the majority answer among $n$ CoT-SC samples occurs less than $n/2$ times (i.e. internal knowledge might not support the task confidently), back off to ReAct. 

Finetuning Due to the challenge of manually annotating reasoning traces and actions at scale, we consider a bootstrapping approach similar to Zelikman et al. (2022), using 3,000 trajectories with correct answers generated by ReAct (also for other baselines) to finetune smaller language models (PaLM-8/62B) to decode trajectories (all thoughts, actions, observations) conditioned on input questions/claims. More details are in Appendix B.1. 

# 3.3 RESULTS AND OBSERVATIONS

ReAct outperforms Act consistently Table 1 shows HotpotQA and Fever results using PaLM-540B as the base model with different prompting methods. We note that ReAct is better than Act on both tasks, demonstrating the value of reasoning to guide acting, especially for synthesizing the final answer, as shown in Figure 1 (1c-d). Fine-tuning results 3 also confirm the benefit of reasoning traces for more informed acting. 

<table><tr><td></td><td>Type</td><td>Definition</td><td>ReAct</td><td>CoT</td></tr><tr><td rowspan="2">Success</td><td>True positive</td><td>Correct reasoning trace and facts</td><td>94%</td><td>86%</td></tr><tr><td>False positive</td><td>Hallucinated reasoning trace or facts</td><td>6%</td><td>14%</td></tr><tr><td rowspan="4">Failure</td><td>Reasoning error</td><td>Wrong reasoning trace (including failing to recover from repetitive steps)</td><td>47%</td><td>16%</td></tr><tr><td>Search result error</td><td>Search return empty or does not contain useful information</td><td>23%</td><td>-</td></tr><tr><td>Hallucination</td><td>Hallucinated reasoning trace or facts</td><td>0%</td><td>56%</td></tr><tr><td>Label ambiguity</td><td>Right prediction but did not match the label precisely</td><td>29%</td><td>28%</td></tr></table>


Table 2: Types of success and failure modes of ReAct and CoT on HotpotQA, as well as their percentages in randomly selected examples studied by human.


ReAct vs. CoT On the other hand, ReAct outperforms CoT on Fever (60.9 vs. 56.3) and slightly lags behind CoT on HotpotQA (27.4 vs. 29.4). Fever claims for SUPPORTS/REFUTES might only differ by a slight amount (see Appendix D.1), so acting to retrieve accurate and up-to-date knowledge is vital. To better understand the behavioral difference between ReAct and CoT on HotpotQA, we randomly sampled 50 trajectories with correct and incorrect answers (judged by EM) from ReAct and CoT respectively (thus 200 examples in total), and manually labeled their success and failure modes in Table 2. Some key observations are as follows: 

A) Hallucination is a serious problem for CoT, resulting in much higher false positive rate than ReAct (14% vs. 6%) in success mode, and make up its major failure mode (56%). In contrast, the problem solving trajectory of ReAct is more grounded, fact-driven, and trustworthy, thanks to the access of an external knowledge base. 

B) While interleaving reasoning, action and observation steps improves ReAct''s groundedness and trustworthiness, such a structural constraint also reduces its flexibility in formulating reasoning steps, leading to more reasoning error rate than CoT. we note that there is one frequent error pattern specific to ReAct, in which the model repetitively generates the previous thoughts and actions, and we categorize it as part of "reasoning error" as the model fails to reason about what the proper next action to take and jump out of the loop4. 

C) For ReAct, successfully retrieving informative knowledge via search is critical. Noninformative search, which counts for $23\%$ of the error cases, derails the model reasoning and gives it a hard time to recover and reformulate thoughts. This is perhaps an expected trade-off between factuality and flexibility, which motivates our proposed strategies of combining two methods. 

We provide examples for each success and failure modes in Appendix E.1. We also find some HotpotQA questions may contain outdated answer labels, see Figure 4 for example. 

ReAct + CoT-SC perform best for prompting LLMs Also shown in Table 1, the best prompting method on HotpotQA and Fever are ReAct $\rightarrow$ CoT-SC and CoT-SC $\rightarrow$ ReAct respectively. Furthermore, Figure 2 shows how different methods perform with respect to the number of CoT-SC samples used. While two ReAct $^+$ CoT-SC methods are advantageous at one task each, they both significantly and consistently outperform CoT-SC across different number of samples, reaching CoT-SC performance with 21 samples using merely 3-5 samples. These results indicate the value of properly combining model internal knowledge and external knowledge for reasoning tasks. 

ReAct performs best for fine-tuning Figure 3 shows the scaling effect of prompting/finetuning four methods (Standard, CoT, Act, ReAct) on HotpotQA. With PaLM-8/62B, prompting ReAct performs worst among four methods due to the difficulty to learn both reasoning and acting from in-context examples. However, when finetuned with just 3,000 examples, ReAct becomes the best method among the four, with PaLM-8B finetuned ReAct outperforming all PaLM-62B prompting methods, and PaLM-62B finetuned ReAct outperforming all 540B prompting methods. In contrast, finetuning Standard or CoT is significantly worse than finetuning ReAct or Act for both PaLM-8/62B, as the former essentially teaches models to memorize (potentially hallucinated) knowledge facts, and the latter teaches models how to (reason and) act to access information from Wikipedia, a more generalizable skill for knowledge reasoning. As all prompting methods are still significantly far from domain-specific state-of-the-art approaches (Table 1), we believe finetuning with more human-written data might be a better way to unleash the power of ReAct. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/f76677eaa0246cb5b8551e916c61285c05b67c0705862f415de68540cdb5a0fc.jpg)



Figure 3: Scaling results for prompting and finetuning on HotPotQA with ReAct (ours) and baselines.


# 4 DECISION MAKING TASKS

We also test ReAct on two language-based interactive decision-making tasks, ALFWorld and WebShop, both of which feature complex environments that require agents to act over long horizons with sparse rewards, warranting the need for reasoning to act and explore effectively. 

ALFWorld ALFWorld (Shridhar et al., 2020b) (Figure 1(2)) is a synthetic text-based game designed to align with the embodied ALFRED benchmark (Shridhar et al., 2020a). It includes 6 types of tasks in which an agent needs to achieve a high-level goal (e.g. examine paper under desklamp) by navigating and interacting with a simulated household via text actions (e.g. go to coffeetable 1, take paper 2, use desklamp 1). A task instance can have more than 50 locations and take an expert policy more than 50 steps to solve, thus challenging an agent to plan and track subgoals, as well as explore systematically (e.g. check all desks one by one for desklamp). In particular, one challenge built into ALFWorld is the need to determine likely locations for common household items (e.g. desks lamps will likely be on desks, shelves, or dressers), making this environment a good fit for LLMs to exploit their pretrained commonsense knowledge. To prompt ReAct, we randomly annotate three trajectories from the training set for each task type, where each trajectory includes sparse thoughts that (1) decompose the goal, (2) track subgoal completion, (3) determine the next subgoal, and (4) reason via commonsense where to find an object and what to do with it. We show prompts used for ALFWorld in Appendix C.4. Following Shridhar et al. (2020b), we evaluate on 134 unseen evaluation games in a task-specific setup. For robustness, we construct 6 prompts for each task type through each permutation of 2 annotated trajectories from the 3 we annotate. Act prompts are constructed using the same trajectories, but without thoughts — since task instances are randomly chosen from the training set, it favors neither ReAct nor Act and provides a fair and controlled comparison to test the importance of sparse thoughts. For baselines, we use BUTLER (Shridhar et al., 2020b), an imitation learning agent trained on $10^{5}$ expert trajectories for each task type $^{5}$ . 

WebShop Can ReAct also interact with noisy real-world language environments for practical applications? We investigate WebShop (Yao et al., 2022), a recently proposed online shopping website environment with 1.18M real-world products and 12k human instructions. Unlike ALFWorld, Webshop contains a high variety of structured and unstructured texts (e.g. product titles, descriptions, and options crawled from Amazon), and requires an agent to purchase a product based on a user instruction (e.g. "I am looking for a nightstand with drawers. It should have a nickel finish, and priced lower than $140") through web interactions (e.g. search "nightstand drawers", choose buttons such as "color: modern-nickel-white" or "back to search"). This task is evaluated by average score (percentage of desired attributes covered by the chosen product averaged across all episodes) and success rate (percentage of episodes where the chosen product satisfies all requirements) on 500 test instructions. We formulate Act prompts with actions to search, choose product, choose options, and buy, with ReAct prompts additionally reasoning to determine what to explore, when to buy, and what products options are relevant to the instruction. See Table 6 for an example prompt, and Table 10 for model predictions in the Appendix. We compare to an imitation learning (IL) method 

<table><tr><td>Method</td><td>Pick</td><td>Clean</td><td>Heat</td><td>Cool</td><td>Look</td><td>Pick 2</td><td>All</td></tr><tr><td>Act (best of 6)</td><td>88</td><td>42</td><td>74</td><td>67</td><td>72</td><td>41</td><td>45</td></tr><tr><td>ReAct (avg)</td><td>65</td><td>39</td><td>83</td><td>76</td><td>55</td><td>24</td><td>57</td></tr><tr><td>ReAct (best of 6)</td><td>92</td><td>58</td><td>96</td><td>86</td><td>78</td><td>41</td><td>71</td></tr><tr><td>ReAct-IM (avg)</td><td>55</td><td>59</td><td>60</td><td>55</td><td>23</td><td>24</td><td>48</td></tr><tr><td>ReAct-IM (best of 6)</td><td>62</td><td>68</td><td>87</td><td>57</td><td>39</td><td>33</td><td>53</td></tr><tr><td>BUTLERg (best of 8)</td><td>33</td><td>26</td><td>70</td><td>76</td><td>17</td><td>12</td><td>22</td></tr><tr><td>BUTLER (best of 8)</td><td>46</td><td>39</td><td>74</td><td>100</td><td>22</td><td>24</td><td>37</td></tr></table>


Table 3: AlfWorld task-specific success rates (\%). BUTLER and BUTLER $_g$ results are from Table 4 of Shridhar et al. (2020b). All methods use greedy decoding, except that BUTLER uses beam search.


<table><tr><td>Method</td><td>Score</td><td>SR</td></tr><tr><td>Act</td><td>62.3</td><td>30.1</td></tr><tr><td>ReAct</td><td>66.6</td><td>40.0</td></tr><tr><td>IL</td><td>59.9</td><td>29.1</td></tr><tr><td>IL+RL</td><td>62.4</td><td>28.7</td></tr><tr><td>Human 
Expert</td><td>82.1</td><td>59.6</td></tr></table>


Table 4: Score and success rate (SR) on Webshop. IL/IL+RL taken from Yao et al. (2022).


trained with 1,012 human annotated trajectories, and a imitation + reinforcement learning (IL + RL) method additionally trained with 10,587 training instructions. 

Results ReAct outperforms Act on both ALFWorld (Table 3) and Webshop (Table 4). On ALFWorld, the best ReAct trial achieves an average success rate of $71\%$ , significantly outperforming the best Act $(45\%)$ and BUTLER $(37\%)$ trials. In fact, even the worse ReAct trial $(48\%)$ beats the best trial of both methods. Moreover, the advantage of ReAct over Act is consistent across six controlled trials, with relative performance gain ranging from $33\%$ to $90\%$ and averaging $62\%$ . Qualitatively, we saw that, without any thoughts at all, Act fails to correctly decompose goals into smaller subgoals, or loses track of the current state of the environment. Example trajectories comparing ReAct and Act can be found in Appendix D.2.1 and Appendix D.2.2. 

On Webshop, one-shot Act prompting already performs on par with IL and $\mathrm{IL + RL}$ methods. With additional sparse reasoning, ReAct achieves significantly better performance, with an absolute $10\%$ improvement over the previous best success rate. By checking examples, we find that ReAct is more likely to identify instruction-relevant products and options by reasoning to bridge the gap between noisy observations and actions (e.g. "For ''space-saving ottoman bench for living room'', the item has options ''39x18x18inch'' and ''blue'' and seems good to buy"). However, existing methods are still far from the performance of expert humans (Table 4), who perform significantly more product explorations and query re-formulations that are still challenging for prompting-based methods. 

On the value of internal reasoning vs. external feedback To our knowledge, ReAct is the first demonstration of combined reasoning and action using an LLM applied to an interactive environment within a closed-loop system. Perhaps the closest prior work is Inner Monologue (IM), from Huang et al. (2022b), in which actions from an embodied agent are motivated by an eponymous "inner monologue". However, IM''s "inner monologue" is limited to observations of the environment state and what needs to be completed by the agent for the goal to be satisfied. In contrast, the reasoning traces in ReAct for decision making is flexible and sparse, allowing diverse reasoning types (see Section 2) to be induced for different tasks. 

To demonstrate the differences between ReAct and IM, and to highlight the importance of internal reasoning vs. simple reactions to external feedback, we ran an ablation experiment using a thought pattern composed of IM-like dense external feedback. As can be seen in Table 3, ReAct substantially outperforms IM-style prompting (ReAct-IM) (71 vs. 53 overall success rate), with consistent advantages on five out of six tasks. Qualitatively, we observed that ReAct-IM often made mistakes in identifying when subgoals were finished, or what the next subgoal should be, due to a lack of high-level goal decomposition. Additionally, many ReAct-IM trajectories struggled to determine where an item would likely be within the ALFWorld environment, due to a lack of commonsense reasoning. Both shortcomings can be addressed in the ReAct paradigm. More details about ReAct-IM is in Appendix B.2. An example prompt for ReAct-IM can be found in Appendix C.4, and an example trajectory in Appendix D.2.3. 

# 5 RELATED WORK

Language model for reasoning Perhaps the most well-known work of using LLMs for reasoning is Chain-of-Thought (CoT) (Wei et al., 2022), which reveals the ability of LLMs to formulate their own "thinking procedure" for problem solving. Several follow-up works have since been performed, including least-to-most prompting for solving complicated tasks (Zhou et al., 2022), zero-shot-CoT (Kojima et al., 2022), and reasoning with self-consistency (Wang et al., 2022a). Recently, (Madaan & Yazdanbakhsh, 2022) systematically studied the formulation and structure of CoT, and observed that the presence of symbols, patterns and texts is crucial to the effectiveness of CoT. Other work has also been extended to more sophisticated reasoning architecture beyond simple prompting. For example Selection-Inference (Creswell et al., 2022) divides the reasoning process into two steps of "selection" and "inference". STaR (Zelikman et al., 2022) bootstraps the reasoning process by finetuning the model on correct rationales generated by the model itself. Faithful reasoning (Creswell & Shanahan, 2022) decomposes multi-step reasoning into three steps, each performed by a dedicated LM respectively. Similar approaches like Scratchpad (Nye et al., 2021), which finetunes a LM on intermediate computation steps, also demonstrate improvement on multi-step computation problems. In contrast to these methods, ReAct performs more than just isolated, fixed reasoning, and integrates model actions and their corresponding observations into a coherent stream of inputs for the model to reason more accurately and tackle tasks beyond reasoning (e.g. interactive decision making). 

Language model for decision making The strong capability of LLMs has enabled them to perform tasks beyond language generation, and it is becoming more popular to take advantage of LLMs as a policy model for decision making, especially in interactive environments. WebGPT (Nakano et al., 2021) uses an LM to interact with web browsers, navigate through web pages, and infer answers to complicated questions from ELI5 (Fan et al., 2019). In comparison to ReAct, WebGPT does not explicitly model the thinking and reasoning procedure, instead rely on expensive human feedback for reinforcement learning. In conversation modeling, chatbots like BlenderBot (Shuster et al., 2022b) and Sparrow (Glaese et al., 2022) and task-oriented dialogue systems like SimpleTOD (Hosseini-Asl et al., 2020) also train LMs to make decision about API calls. Unlike ReAct, they do not explicitly consider the reasoning procedure either, and also relies on expensive datasets and human feedback collections for policy learning. In contrast, ReAct learns a policy in a much cheaper way, since the decision making process only requires language description of the reasoning procedure.<sup>6</sup> 

LLMS have also been increasingly employed in interactive and embodied environments for planning and decision making. Perhaps most relevant to ReAct in this respect are SayCan (Ahn et al., 2022) and Inner Monologue (Huang et al., 2022b), which use LLMs for robotic action planning and decision making. In SayCan, LLMs were prompted to directly predict possible actions a robot can take, which is then reranked by an affordance model grounded on the visual environments for final prediction. Inner Monologue made further improvements by adding the eponymous "inner monologue", which is implemented as injected feedback from the environment. To our knowledge, Inner Monologue is the first work that demonstrates such a closed-loop system, which ReAct builds on. However, we argue that Inner Monologue does not truly comprise of inner thoughts — this is elaborated in Section 4. We also note that leveraging language as semantically-rich inputs in the process of interactive decision making has been shown to be successful under other settings (Abramson et al., 2020; Karamcheti et al., 2021; Huang et al., 2022a; Li et al., 2022). It is becoming more evident that with the help of LLMs, language as a fundamental cognitive mechanism will play a critical role in interaction and decision making. What is more, progress in LLMs has also inspired the development of versatile and generalist agents like Reed et al. (2022). 

# 6 CONCLUSION

We have proposed ReAct - a simple yet effective method for synergizing reasoning and acting in large language models. Through a diverse set of experiments on multi-hop question-answering, fact checking, and interactive decision-making tasks, we show that ReAct leads to superior performance with interpretable decision traces. Despite the simplicity of our method, complex tasks with large action spaces require more demonstrations to learn well, which unfortunately can easily go beyond the input length limit of in-context learning. We explore the fine-tuning approach on HotpotQA 

with initial promising results, but learning from more high-quality human annotations will be the desiderata to further improve the performance. Scaling up ReAct with multi-task training and combining it with complementary paradigms like reinforcement learning could result in stronger agents that further unlock the potential of LLMs for more applications. 

# ACKNOWLEDGMENTS

We thank the support and feedback of many people from Google Brain team and Princeton NLP Group. This work was supported in part by the National Science Foundation under Grant No. 2107048. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation. 

# REPRODUCIBILITY STATEMENT

Our main experiments are done on PaLM (Chowdhery et al., 2022), which is not an openly accessible model yet. To increase reproducibility, we have included all used prompts in Appendix C, additional experiments using GPT-3 (Brown et al., 2020) in Appendix A.1, and associated GPT-3 ReAct prompting code at https://anonymous.4open.science/r/ReAct-2268/. 

# ETHICS STATEMENT

ReAct prompts large language models to generate more human interpretable, diagnosable, and controllable task-solving trajectories than previous methods. However, hooking up a large language model with an action space to interact with external environments (e.g. the web, physical environments) has potential dangers, e.g. looking up inappropriate or private information, or taking harmful actions in an environment. Our experiments minimize such risks by limiting the interactions to specific websites (Wikipedia or WebShop) that are free of private information, without any dangerous actions in the action space design (i.e. models cannot really buy products on WebShop the research benchmark, or edit Wikipedia). We believe researchers should be aware of such risks before designing more extensive experiments in the future. 

# REFERENCES



Josh Abramson, Arun Ahuja, Iain Barr, Arthur Brussee, Federico Carnevale, Mary Cassin, Rachita Chhaparia, Stephen Clark, Bogdan Damoc, Andrew Dudzik, Petko Georgiev, Aurelia Guy, Tim Harley, Felix Hill, Alden Hung, Zachary Kenton, Jessica Landon, Timothy Lillicrap, Kory Mathewson, Soña Mokrá, Alistair Muldal, Adam Santoro, Nikolay Savinov, Vikrant Varma, Greg Wayne, Duncan Williams, Nathaniel Wong, Chen Yan, and Rui Zhu. Imitating interactive intelligence, 2020. URL https://arxiv.org/abs/2012.05672. 





Michael Ahn, Anthony Brohan, Noah Brown, Yevgen Chebotar, Omar Cortes, Byron David, Chelsea Finn, Chuyuan Fu, Keerthana Gopalakrishnan, Karol Hausman, Alex Herzog, Daniel Ho, Jasmine Hsu, Julian Ibarz, Brian Ichter, Alex Irpan, Eric Jang, Rosario Jauregui Ruano, Kyle Jeffrey, Sally Jesmonth, Nikhil J Joshi, Ryan Julian, Dmitry Kalashnikov, Yuheng Kuang, Kuang-Huei Lee, Sergey Levine, Yao Lu, Linda Luu, Carolina Parada, Peter Pastor, Jornell Quiambao, Kanishka Rao, Jarek Rettinghouse, Diego Reyes, Pierre Sermanet, Nicolas Sievers, Clayton Tan, Alexander Toshev, Vincent Vanhoucke, Fei Xia, Ted Xiao, Peng Xu, Sichun Xu, Mengyuan Yan, and Andy Zeng. Do as i can, not as i say: Grounding language in robotic affordances, 2022. URL https://arxiv.org/abs/2204.01691. 





Ben Alderson-Day and Charles Fernyhough. Inner speech: development, cognitive functions, phenomenology, and neurobiology. *Psychological bulletin*, 141(5):931, 2015. 





Alan Baddeley. Working memory. Science, 255(5044):556-559, 1992. 





Tom Brown, Benjamin Mann, Nick Ryder, Melanie Subbiah, Jared D Kaplan, Prafulla Dhariwal, Arvind Neelakantan, Pranav Shyam, Girish Sastry, Amanda Askell, et al. Language models are few-shot learners. Advances in neural information processing systems, 33:1877-1901, 2020. 





Aakanksha Chowdhery, Sharan Narang, Jacob Devlin, Maarten Bosma, Gaurav Mishra, Adam Roberts, Paul Barham, Hyung Won Chung, Charles Sutton, Sebastian Gehrmann, et al. Palm: Scaling language modeling with pathways. arXiv preprint arXiv:2204.02311, 2022. 





Antonia Creswell and Murray Shanahan. Faithful reasoning using large language models, 2022. URL https://arxiv.org/abs/2208.14271. 





Antonia Creswell, Murray Shanahan, and Irina Higgins. Selection-inference: Exploiting large language models for interpretable logical reasoning, 2022. URL https://arxiv.org/abs/2205.09712. 





Angela Fan, Yacine Jernite, Ethan Perez, David Grangier, Jason Weston, and Michael Auli. ELI5: Long form question answering. In Proceedings of the 57th Annual Meeting of the Association for Computational Linguistics, pp. 3558-3567, Florence, Italy, July 2019. Association for Computational Linguistics. doi: 10.18653/v1/P19-1346. URL https://aclanthology.org/ P19-1346. 





Charles Fernyhough. Vygotsky, luria, and the social brain. Self and social regulation: Social interaction and the development of social understanding and executive functions, pp. 56-79, 2010. 





Amelia Glaese, Nat McAleese, Maja Trebacz, John Aslanides, Vlad Firoiu, Timo Ewalds, Maribeth Rauh, Laura Weidinger, Martin Chadwick, Phoebe Thacker, Lucy Campbell-Gillingham, Jonathan Uesato, Po-Sen Huang, Ramona Comanescu, Fan Yang, Abigail See, Sumanth Dathathri, Rory Greig, Charlie Chen, Doug Fritz, Jaume Sanchez Elias, Richard Green, Soña Mokrá, Nicholas Fernando, Boxi Wu, Rachel Foley, Susannah Young, Jason Gabriel, William Isaac, John Mellor, Demis Hassabis, Koray Kavukcuoglu, Lisa Anne Hendricks, and Geoffrey Irving. Improving alignment of dialogue agents via targeted human judgements, 2022. URL https://storage.googleapis.com/deepmind-media/DeepMind.com/Authors-Notes/sparrow/sparrow-final.pdf. 





Ehsan Hosseini-Asl, Bryan McCann, Chien-Sheng Wu, Semih Yavuz, and Richard Socher. A simple language model for task-oriented dialogue. Advances in Neural Information Processing Systems, 33:20179–20191, 2020. 





Wenlong Huang, Pieter Abbeel, Deepak Pathak, and Igor Mordatch. Language models as zero-shot planners: Extracting actionable knowledge for embodied agents. arXiv preprint arXiv:2201.07207, 2022a. 





Wenlong Huang, Fei Xia, Ted Xiao, Harris Chan, Jacky Liang, Pete Florence, Andy Zeng, Jonathan Thompson, Igor Mordatch, Yevgen Chebotar, et al. Inner monologue: Embodied reasoning through planning with language models. arXiv preprint arXiv:2207.05608, 2022b. 





Siddharth Karamcheti, Megha Srivastava, Percy Liang, and Dorsa Sadigh. Lila: Language-informed latent actions. In CoRL, pp. 1379-1390, 2021. URL https://proceedings.mlr.press/v164/karamcheti22a.html. 





Takeshi Kojima, Shixiang Shane Gu, Machel Reid, Yutaka Matsuo, and Yusuke Iwasawa. Large language models are zero-shot reasoners. arXiv preprint arXiv:2205.11916, 2022. 





Angeliki Lazaridou, Elena Gribovskaya, Wojciech Stokowiec, and Nikolai Grigorev. Internet-augmented language models through few-shot prompting for open-domain question answering. arXiv preprint arXiv:2203.05115, 2022. 





Patrick Lewis, Ethan Perez, Aleksandra Piktus, Fabio Petroni, Vladimir Karpukhin, Naman Goyal, Heinrich Küttler, Mike Lewis, Wen-tau Yih, Tim Rocktäschel, et al. Retrieval-augmented generation for knowledge-intensive nlp tasks. Advances in Neural Information Processing Systems, 33: 9459-9474, 2020. 





Shuang Li, Xavier Puig, Chris Paxton, Yilun Du, Clinton Wang, Linxi Fan, Tao Chen, De-An Huang, Ekin Akyurek, Anima Anandkumar, Jacob Andreas, Igor Mordatch, Antonio Torralba, and Yuke Zhu. Pre-trained language models for interactive decision-making, 2022. URL https://arxiv.org/abs/2202.01771. 





Aleksandr Romanovich Luria. Ls vygotsky and the problem of localization of functions. Neuropsychologia, 3(4):387-392, 1965. 





Aman Madaan and Amir Yazdanbakhsh. Text and patterns: For effective chain of thought, it takes two to tango, 2022. URL https://arxiv.org/abs/2209.07686. 





Vincent Micheli and François Fleuret. Language models are few-shot butlers. arXiv preprint arXiv:2104.07972, 2021. 





Reiichiro Nakano, Jacob Hilton, Suchir Balaji, Jeff Wu, Long Ouyang, Christina Kim, Christopher Hesse, Shantanu Jain, Vineet Kosaraju, William Saunders, Xu Jiang, Karl Cobbe, Tyna Eloundou, Gretchen Krueger, Kevin Button, Matthew Knight, Benjamin Chess, and John Schulman. Webgpt: Browser-assisted question-answering with human feedback, 2021. URL https://arxiv.org/abs/2112.09332. 





Maxwell Nye, Anders Johan Andreassen, Guy Gur-Ari, Henryk Michalewski, Jacob Austin, David Bieber, David Dohan, Aitor Lewkowycz, Maarten Bosma, David Luan, Charles Sutton, and Augustus Odena. Show your work: Scratchpads for intermediate computation with language models, 2021. URL https://arxiv.org/abs/2112.00114. 





Scott Reed, Konrad Zolna, Emilio Parisotto, Sergio Gomez Colmenarejo, Alexander Novikov, Gabriel Barth-Maron, Mai Gimenez, Yury Sulsky, Jackie Kay, Jost Tobias Springenberg, Tom Eccles, Jake Bruce, Ali Razavi, Ashley Edwards, Nicolas Heess, Yutian Chen, Raia Hadsell, Oriol Vinyals, Mahyar Bordbar, and Nando de Freitas. A generalist agent, 2022. URL https://arxiv.org/abs/2205.06175. 





Mohit Shridhar, Jesse Thomason, Daniel Gordon, Yonatan Bisk, Winson Han, Roozbeh Mottaghi, Luke Zettlemoyer, and Dieter Fox. Alfred: A benchmark for interpreting grounded instructions for everyday tasks. In Proceedings of the IEEE/CVF conference on computer vision and pattern recognition, pp. 10740-10749, 2020a. 





Mohit Shridhar, Xingdi Yuan, Marc-Alexandre Côté, Yonatan Bisk, Adam Trischler, and Matthew Hausknecht. Alfworld: Aligning text and embodied environments for interactive learning. arXiv preprint arXiv:2010.03768, 2020b. 





Kurt Shuster, Mojtaba Komeili, Leonard Adolphs, Stephen Roller, Arthur Szlam, and Jason Weston. Language models that seek for knowledge: Modular search & generation for dialogue and prompt completion. arXiv preprint arXiv:2203.13224, 2022a. 





Kurt Shuster, Jing Xu, Mojtaba Komeili, Da Ju, Eric Michael Smith, Stephen Roller, Megan Ung, Moya Chen, Kushal Arora, Joshua Lane, Morteza Behrooz, William Ngan, Spencer Poff, Naman Goyal, Arthur Szlam, Y-Lan Boureau, Melanie Kambadur, and Jason Weston. Blenderbot 3: a deployed conversational agent that continually learns to responsibly engage, 2022b. URL https://arxiv.org/abs/2208.03188. 





James Thorne, Andreas Vlachos, Christos Christodoulopoulos, and Arpit Mittal. Fever: a large-scale dataset for fact extraction and verification. arXiv preprint arXiv:1803.05355, 2018. 





Lev S Vygotsky. Thinking and speech. The collected works of LS Vygotsky, 1:39-285, 1987. 





Xuezhi Wang, Jason Wei, Dale Schuurmans, Quoc Le, Ed Chi, Sharan Narang, Aakanksha Chowdhery, and Denny Zhou. Self-consistency improves chain of thought reasoning in language models, 2022a. URL https://arxiv.org/abs/2203.11171. 





Xuezhi Wang, Jason Wei, Dale Schuurmans, Quoc Le, Ed Chi, and Denny Zhou. Rationale-augmented ensembles in language models. arXiv preprint arXiv:2207.00747, 2022b. 





Jason Wei, Xuezhi Wang, Dale Schuurmans, Maarten Bosma, Ed Chi, Quoc Le, and Denny Zhou. Chain of thought prompting elicits reasoning in large language models. arXiv preprint arXiv:2201.11903, 2022. 





Zhilin Yang, Peng Qi, Saizheng Zhang, Yoshua Bengio, William W Cohen, Ruslan Salakhutdinov, and Christopher D Manning. Hotpotqa: A dataset for diverse, explainable multi-hop question answering. arXiv preprint arXiv:1809.09600, 2018. 





Shunyu Yao, Rohan Rao, Matthew Hausknecht, and Karthik Narasimhan. Keep CALM and explore: Language models for action generation in text-based games. In Proceedings of the 2020 Conference on Empirical Methods in Natural Language Processing (EMNLP), pp. 8736-8754, Online, November 2020. Association for Computational Linguistics. doi: 10.18653/v1/2020.emnlp-main.704. URL https://aclanthology.org/2020.emnlp-main.704. 





Shunyu Yao, Howard Chen, John Yang, and Karthik Narasimhan. Webshop: Towards scalable real-world web interaction with grounded language agents. arXiv preprint arXiv:2207.01206, 2022. 





Eric Zelikman, Yuhuai Wu, Jesse Mu, and Noah D. Goodman. Star: Bootstrapping reasoning with reasoning, 2022. URL https://arxiv.org/abs/2203.14465. 





Denny Zhou, Nathanael Scharli, Le Hou, Jason Wei, Nathan Scales, Xuezhi Wang, Dale Schuurmans, Olivier Bousquet, Quoc Le, and Ed Chi. Least-to-most prompting enables complex reasoning in large language models, 2022. URL https://arxiv.org/abs/2205.10625. 





Yunchang Zhu, Liang Pang, Yanyan Lan, Huawei Shen, and Xueqi Cheng. Adaptive information seeking for open-domain question answering. arXiv preprint arXiv:2109.06747, 2021. 



# A ADDITIONAL RESULTS

# A.1 GPT-3 EXPERIMENTS

<table><tr><td></td><td>PaLM-540B</td><td>GPT-3</td></tr><tr><td>HotpotQA (exact match)</td><td>29.4</td><td>30.8</td></tr><tr><td>ALFWorld (success rate %)</td><td>70.9</td><td>78.4</td></tr></table>


Table 5: ReAct prompting results using PaLM-540B vs. GPT-3 (text-davinci-002, greedy decoding). On HotpotQA, we randomly sample a subset of 500 validation questions. On ALFWorld, we use all 134 unseen validation task instances, and use the best prompt set according to PaLM-540B.


We run additional GPT-3 (Brown et al., 2020) experiments to confirm ReAct prompting performance is general across different large language models. As shown in Table 5, GPT-3 (text-davinci-002, greedy decoding) consistently outperforms PaLM-540B on HotpotQA and ALFWorld, possibly because it is finetuned with human instruction following. This indicates ReAct prompting is effective across different large language models on different tasks. The code for these experiments are at https://react-lm.github.io/. 

# A.2 REACT OBTAINS UP-TO-DATE KNOWLEDGE ON HOTPOTQA

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/107f7d528301991bdff7bb7c0d21e48e0e5a9cba6a0d67e70949556a2b5af3c1.jpg)



Figure 4: Another example HotpotQA question, where the original label is outdated. Only ReAct is able to obtain the up-to-date answer thanks to real-world web interaction plus reasoning.


During trajectory inspection, we also find that sometimes ReAct does not agree with dataset labels as the labels themselves could be outdated. For example, as shown in Figure 4, the question asks about the size of a hotel, which increased from the HotpotQA construction time. While Standard and CoT give wrong answers due to hallucination, Act fails despite the access of real-world web interaction, due to a lack of reasoning to guide how to interact with the Internet for QA. Only ReAct is able to retrieve up-to-date information from the Internet and provide a reasonable answer. Therefore, better incorporation of reasoning abilities might benefit recent Internet-augmented language models (Nakano et al., 2021; Lazaridou et al., 2022; Shuster et al., 2022a) for up-to-date task solving. 

# A.3 HUMAN-IN-THE-LOOP BEHAVIOR CORRECTION ON ALFWORLD

We also explore human-in-the-loop interaction with ReAct, to allow a human to inspect and edit ReAct''s reasoning traces. Figure 5 shows that by simply removing a hallucinating sentence in Act 17 and adding some hints in Act 23, ReAct can be made to change its behavior drastically to align with these human thought edits and succeed in the task. From a human perspective, solving such a task becomes significantly easier, from typing tens of actions to only editing a couple of thoughts, which enables new forms of human-machine collaboration. We note that such a policy edit on-the-go 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/5107d8d4-0032-48a8-898d-414573145539/c83ed044957b339be617ce38add2b4ffa3bb35bd7d9256fb88e2e547aa50a072.jpg)



Figure 5: A human-in-the-loop behavior correction example with ReAct in AlfWorld. (a) ReAct trajectory fails due to a hallucinating thought (Act 17). (b) By a human simply editing two thoughts (Act 17, 23), the ReAct trajectory produces desirable reasoning traces and actions and succeeds.


is difficult for Act and previous RL methods, as a human cannot change the model parameters, and changing a few actions might not edit the rest of the model behavior. This paradigm is also more than human dialogue to update the goal or subgoal as in Huang et al. (2022b) — while editing ReAct thoughts can do these, it can also modify the model''s internal belief, reasoning styles, or anything the flexible thought space supports, for better task solving. We believe this is an exciting direction for human alignment and leave more systematic study as future work. 

# B EXPERIMENT DETAILS

# B.1 HOTPOTQA FINETUNING DETAILS

For all finetuning we use a batch size of 64. On PaLM-8B, we finetune ReAct and Act methods for 4,000 steps and Standard and CoT methods for 2,000 steps. On PaLM-62B, we finetune ReAct and Act methods for 4,000 steps and Standard and CoT methods for 1,000 steps. We find ReAct and Act methods generally benefit from more training steps (and more training data), while Standard and CoT methods degrade soon after finetuning. 

# B.2 ALFWORLD IM-STYLE DETAILS

For the IM-style ablation, the same expert trajectories used in ReAct are reannotated with dense external feedback thoughts within these trajectories, that limit ReAct-IM to only think about (1) decomposing the current goal and (2) the current subgoal that needs to be completed. In particular, ReAct-IM lacks thoughts that (1) determine when a subgoal is completed (2) determine what the next subgoal should be (3) inducing the LLM to refer to its internal pretraining knowledge to identify where items can be within the environment. 

# C PROMPTS

# C.1 HOTPOTQA


Hotpot QA Prompts


<table><tr><td>Original Question Answer</td><td>What is the elevation range for the area that the eastern sector of the Colorado orogeny extends into? 1,800 to 7,000 ft</td></tr><tr><td>Question Answer</td><td>Musician and satirist Allie Goertz wrote a song about the &quot;The Simpsons&quot; character Milhouse, who Matt Groening named after who? Richard Nixon</td></tr><tr><td>Question Answer</td><td>Which documentary is about Finnish rock groups, Adam Clayton Powell or The Saimaa Gesture? The Saimaa Gesture</td></tr><tr><td>Question Answer</td><td>What profession does Nicholas Ray and Elia Kazan have in common? director, screenwriter, actor</td></tr><tr><td>Question Answer</td><td>Which magazine was started first Arthur&#x27;s Magazine or First for Women? Arthur&#x27;s Magazine</td></tr><tr><td>Question Answer</td><td>Were Pavel Urysohn and Leonid Levin known for the same type of work? Yes</td></tr><tr><td>Yes: 
Question Answer</td><td>What is the elevation range for the area that the eastern sector of the Colorado orogeny extends into? Search[Colorado orogeny] 
The Colorado orogeny was an episode of mountain building (an orogeny) in Colorado and surrounding areas. 
Lookup[eastern sector] 
(Result 1 / 1) The eastern sector extends into the High Plains and is called the Central Plains orogeny. 
Search[High Plains] 
High Plains refers to one of two distinct land regions: 
Search[High Plains (United States)] 
The High Plains are a subregion of the Great Plains. From east to west, the High Plains rise in elevation from around 1,800 to 7,000 ft (550 to 2,130 m). [3] 
Finish[1,800 to 7,000 ft]</td></tr><tr><td>Question Answer</td><td>Musician and satirist Allie Goertz wrote a song about the &quot;The Simpsons&quot; character Milhouse, who Matt Groening named after who? Search[Milhouse] 
Milhouse Mussolini Van Houten is a recurring character in the Fox animated television series The Simpsons voiced by Pamela Hayden and created by Matt Groening. 
Lookup[named after] 
(Result 1 / 1) Milhouse was named after U.S. president Richard Nixon, whose middle name was Milhous. 
Finish[Richard Nixon]</td></tr><tr><td>Question Answer</td><td>Which documentary is about Finnish rock groups, Adam Clayton Powell or The Saimaa Gesture? 
Search[Adam Clayton Powell] 
Could not find [Adam Clayton Powell]. Similar: [&#x27;Adam Clayton Powell III&#x27;, &#x27;Seventh Avenue (Manhattan)&#x27;, &#x27;Adam Clayton Powell Jr. State Office Building&#x27;, &#x27;Isabel Washington Powell&#x27;, &#x27;Adam Powell&#x27;, &#x27;Adam Clayton Powell (film)&#x27;, &#x27;Giancarlo Esposito&#x27;]. 
Search[Adam Clayton Powell (film)] 
Adam Clayton Powell is a 1989 American documentary film directed by Richard Kilberg. The film is about the rise and fall of influential African-American politician Adam Clayton Powell Jr. [3][4] It was later aired as part of the PBS series The American Experience. 
Finish[The Saimaa Gesture]</td></tr><tr><td>Question Answer</td><td>What profession does Nicholas Ray and Elia Kazan have in common? Search[Nicholas Ray] 
Nicholas Ray (born Raymond Nicholas Kienzle Jr., August 7, 1911 - June 16, 1979) was an American film director, screenwriter, and actor best known for the 1955 film Rebel Without a Cause. 
Search[Elia Kazan] 
Elia Kazan was an American film and theatre director, producer, screenwriter and actor.</td></tr></table>

Continued on next page 


Hotpot QA Prompts - Continued from previous page


<table><tr><td>Action 3</td><td>Finish[director, screenwriter, actor]</td></tr><tr><td>Question</td><td>Which magazine was started first Arthur&#x27;s Magazine or First for Women?</td></tr><tr><td>Action 1</td><td>Search[Arthur&#x27;s Magazine]</td></tr><tr><td>Observation 1</td><td>Arthur&#x27;s Magazine (1844-1846) was an American literary periodical published in Philadelphia in the 19th century.</td></tr><tr><td>Action 2</td><td>Search[First for Women]</td></tr><tr><td>Observation 2</td><td>First for Women is a woman&#x27;s magazine published by Bauer Media Group in the USA.[1] The magazine was started in 1989.</td></tr><tr><td>Action 3</td><td>Finish[Arthur&#x27;s Magazine]</td></tr><tr><td>Question</td><td>Were Pavel Urysohn and Leonid Levin known for the same type of work?</td></tr><tr><td>Action 1</td><td>Search[Pavel Urysohn]</td></tr><tr><td>Observation 1</td><td>Pavel Samuilovich Urysohn (February 3, 1898 - August 17, 1924) was a Soviet mathematician who is best known for his contributions in dimension theory.</td></tr><tr><td>Action 2</td><td>Search[Leonid Levin]</td></tr><tr><td>Observation 2</td><td>Leonid Anatolievich Levin is a Soviet-American mathematician and computer scientist.</td></tr><tr><td>Action 3</td><td>Finish[yes]</td></tr><tr><td colspan="2">Goal</td></tr><tr><td>Question</td><td>What is the elevation range for the area that the eastern sector of the Colorado orogeny extends into?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. The eastern sector of Colorado orogeny extends into the High Plains. High Plains rise in elevation from around 1,800 to 7,000 ft, so the answer is 1,800 to 7,000 ft.</td></tr><tr><td>Answer</td><td>1,800 to 7,000 ft</td></tr><tr><td>Question</td><td>Musician and satirist Allie Goertz wrote a song about the &quot;The Simpsons&quot; character Milhouse, who Matt Groening named after who?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. Milhouse was named after U.S. president Richard Nixon, so the answer is Richard Nixon.</td></tr><tr><td>Answer</td><td>Richard Nixon</td></tr><tr><td>Question</td><td>Which documentary is about Finnish rock groups, Adam Clayton Powell or The Saimaa Gesture?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. Adam Clayton Powell (film) is a documentary about an African-American politician, not Finnish rock groups. So the documentary about Finnish rock groups must instead be The Saimaa Gesture.</td></tr><tr><td>Answer</td><td>The Saimaa Gesture</td></tr><tr><td>Question</td><td>What profession does Nicholas Ray and Elia Kazan have in common?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. Professions of Nicholas Ray are director, screenwriter, and actor. Professions of Elia Kazan are director, producer, screenwriter, and actor. So profession Nicholas Ray and Elia Kazan have in common is director, screenwriter, and actor.</td></tr><tr><td>Answer</td><td>director, screenwriter, actor</td></tr><tr><td>Question</td><td>Which magazine was started first Arthur&#x27;s Magazine or First for Women?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. Arthur&#x27;s Magazine was started in 1844. First for Women was started in 1989. 1844 (Arthur&#x27;s Magazine) &lt; 1989 (First for Women), so Arthur&#x27;s Magazine was started first.</td></tr><tr><td>Answer</td><td>Arthur&#x27;s Magazine</td></tr><tr><td>Question</td><td>Were Pavel Urysohn and Leonid Levin known for the same type of work?</td></tr><tr><td>Thought</td><td>Let&#x27;s think step by step. Pavel Urysohn is a mathematician. Leonid Levin is a mathematician and computer scientist. So Pavel Urysohn and Leonid Levin have the same type of work.</td></tr><tr><td>Answer</td><td>Yes</td></tr><tr><td colspan="2">ReAct</td></tr><tr><td>Question</td><td>What is the elevation range for the area that the eastern sector of the Colorado orogeny extends into?</td></tr><tr><td>Thought 1</td><td>I need to search Colorado orogeny, find the area that the eastern sector of the Colorado orogeny extends into, then find the elevation range of the area.</td></tr><tr><td>Action 1</td><td>Search[Colorado orogeny]</td></tr><tr><td>Observation 1</td><td>The Colorado orogeny was an episode of mountain building (an orogeny) in Colorado and surrounding areas.</td></tr><tr><td>Thought 2</td><td>It does not mention the eastern sector. So I need to look up eastern sector.</td></tr><tr><td>Action 2</td><td>Lookup[eastern sector]</td></tr><tr><td>Observation 2</td><td>(Result 1 / 1) The eastern sector extends into the High Plains and is called the Central Plains orogeny.</td></tr><tr><td>Thought 3</td><td>The eastern sector of Colorado orogeny extends into the High Plains. So I need to search High Plains and find its elevation range.</td></tr><tr><td>Action 3</td><td>Search[High Plains]</td></tr><tr><td>Observation 3</td><td>High Plains refers to one of two distinct land regions</td></tr><tr><td>Thought 4</td><td>I need to instead search High Plains (United States).</td></tr><tr><td>Action 4</td><td>Search[High Plains (United States)]</td></tr></table>


Continued on next page 



Hotpot QA Prompts - Continued from previous page


<table><tr><td>Observation 4</td><td>The High Plains are a subregion of the Great Plains. From east to west, the High Plains rise in elevation from around 1,800 to 7,000 ft (550 to 2,130 m).[3]</td></tr><tr><td>Thought 5</td><td>High Plains rise in elevation from around 1,800 to 7,000 ft, so the answer is 1,800 to 7,000 ft.</td></tr><tr><td>Action 5</td><td>Finish[1,800 to 7,000 ft]</td></tr><tr><td>Question</td><td>Musician and satirist Allie Goertz wrote a song about the &quot;The Simpsons&quot; character Milhouse, who Matt Groening named after who?</td></tr><tr><td>Thought 1</td><td>The question simplifies to &quot;The Simpsons&quot; character Milhouse is named after who. I only need to search Milhouse and find who it is named after.</td></tr><tr><td>Action 1</td><td>Search[Milhouse]</td></tr><tr><td>Observation 1</td><td>Milhouse Mussolini Van Houten is a recurring character in the Fox animated television series The Simpsons voiced by Pamela Hayden and created by Matt Groening.</td></tr><tr><td>Thought 2</td><td>The paragraph does not tell who Milhouse is named after, maybe I can look up &quot;named after&quot;.</td></tr><tr><td>Action 2</td><td>Lookup[named after]</td></tr><tr><td>Observation 2</td><td>(Result 1 / 1) Milhouse was named after U.S. president Richard Nixon, whose middle name was Milhous.</td></tr><tr><td>Thought 3</td><td>Milhouse was named after U.S. president Richard Nixon, so the answer is Richard Nixon.</td></tr><tr><td>Action 3</td><td>Finish[Richard Nixon]</td></tr><tr><td>Question</td><td>Which documentary is about Finnish rock groups, Adam Clayton Powell or The Saimaa Gesture?</td></tr><tr><td>Thought 1</td><td>I need to search Adam Clayton Powell and The Saimaa Gesture, and find which documentary is about Finnish rock groups.</td></tr><tr><td>Action 1</td><td>Search[Adam Clayton Powell]</td></tr><tr><td>Observation 1</td><td>Could not find [Adam Clayton Powell]. Similar: [&#x27;Adam Clayton Powell III&#x27;, &#x27;Seventh Avenue (Manhattan)&#x27;, &#x27;Adam Clayton Powell Jr. State Office Building&#x27;, &#x27;Isabel Washington Powell&#x27;, &#x27;Adam Powell&#x27;, &#x27;Adam Clayton Powell (film)&#x27;, &#x27;Giancarlo Esposito&#x27;].</td></tr><tr><td>Thought 2</td><td>To find the documentary, I can search Adam Clayton Powell (film).</td></tr><tr><td>Action 2</td><td>Search[Adam Clayton Powell (film)]</td></tr><tr><td>Observation 2</td><td>Adam Clayton Powell is a 1989 American documentary film directed by Richard Kilberg. The film is about the rise and fall of influential African-American politician Adam Clayton Powell Jr.[3][4] It was later aired as part of the PBS series The American Experience.</td></tr><tr><td>Thought 3</td><td>Adam Clayton Powell (film) is a documentary about an African-American politician, not Finnish rock groups. So the documentary about Finnish rock groups must instead be The Saimaa Gesture.</td></tr><tr><td>Action 3</td><td>Finish[The Saimaa Gesture]</td></tr><tr><td>Question</td><td>What profession does Nicholas Ray and Elia Kazan have in common?</td></tr><tr><td>Thought 1</td><td>I need to search Nicholas Ray and Elia Kazan, find their professions, then find the profession they have in common.</td></tr><tr><td>Action 1</td><td>Search[Nicholas Ray]</td></tr><tr><td>Observation 1</td><td>Nicholas Ray (born Raymond Nicholas Kienzle Jr., August 7, 1911 - June 16, 1979) was an American film director, screenwriter, and actor best known for the 1955 film Rebel Without a Cause.</td></tr><tr><td>Thought 2</td><td>Professions of Nicholas Ray are director, screenwriter, and actor. I need to search Elia Kazan next and find his professions.</td></tr><tr><td>Action 2</td><td>Search[Elia Kazan]</td></tr><tr><td>Observation 2</td><td>Elia Kazan was an American film and theatre director, producer, screenwriter and actor.</td></tr><tr><td>Thought 3</td><td>Professions of Elia Kazan are director, producer, screenwriter, and actor. So profession Nicholas Ray and Elia Kazan have in common is director, screenwriter, and actor.</td></tr><tr><td>Action 3</td><td>Finish[director, screenwriter, actor]</td></tr><tr><td>Question</td><td>Which magazine was started first Arthur&#x27;s Magazine or First for Women?</td></tr><tr><td>Thought 1</td><td>I need to search Arthur&#x27;s Magazine and First for Women, and find which was started first.</td></tr><tr><td>Action 1</td><td>Search[Arthur&#x27;s Magazine]</td></tr><tr><td>Observation 1</td><td>Arthur&#x27;s Magazine (1844-1846) was an American literary periodical published in Philadelphia in the 19th century.</td></tr><tr><td>Thought 2</td><td>Arthur&#x27;s Magazine was started in 1844. I need to search First for Women next.</td></tr><tr><td>Action 2</td><td>Search[First for Women]</td></tr><tr><td>Observation 2</td><td>First for Women is a woman&#x27;s magazine published by Bauer Media Group in the USA.[1] The magazine was started in 1989.</td></tr><tr><td>Thought 3</td><td>First for Women was started in 1989. 1844 (Arthur&#x27;s Magazine) &lt; 1989 (First for Women), so Arthur&#x27;s Magazine was started first.</td></tr><tr><td>Action 3</td><td>Finish[Arthur&#x27;s Magazine]</td></tr><tr><td>Question</td><td>Were Pavel Urysohn and Leonid Levin known for the same type of work?</td></tr><tr><td>Thought 1</td><td>I need to search Pavel Urysohn and Leonid Levin, find their types of work, then find if they are the same.</td></tr><tr><td>Action 1</td><td>Search[Pavel Urysohn]</td></tr></table>


Hotpot QA Prompts - Continued from previous page


<table><tr><td>Observation 1</td><td>Pavel Samuilovich Urysohn (February 3, 1898 - August 17, 1924) was a Soviet mathematician who is best known for his contributions in dimension theory.</td></tr><tr><td>Thought 2</td><td>Pavel Urysohn is a mathematician. I need to search Leonid Levin next and find its type of work.</td></tr><tr><td>Action 2</td><td>Search[Leonid Levin]</td></tr><tr><td>Observation 2</td><td>Leonid Anatolievich Levin is a Soviet-American mathematician and computer scientist.</td></tr><tr><td>Thought 3</td><td>Leonid Levin is a mathematician and computer scientist. So Pavel Urysohn and Leonid Levin have the same type of work.</td></tr><tr><td>Action 3</td><td>Finish[yes]</td></tr></table>

# C.2 FEVER

<table><tr><td colspan="2">FEVER Prompts</td></tr><tr><td>Original</td><td>Determine if there is Observation that SUPPORTS or REFUTES a Claim, or if there is NOT ENOUGH INFORMATION.</td></tr><tr><td>Claim Answer</td><td>Nikolaj Coster-Waldau worked with the Fox Broadcasting Company.SUPPORTS</td></tr><tr><td>Claim Answer</td><td>Stranger Things is set in Bloomington, Indiana REFUTES</td></tr><tr><td>Claim Answer</td><td>Beautiful reached number two on the Billboard Hot 100 in 2003. NOT ENOUGH INFO</td></tr><tr><td>Yes</td><td>Determine if there is Observation that SUPPORTS or REFUTES a Claim, or if there is NOT ENOUGH INFORMATION.</td></tr><tr><td>Claim Action2 Observation 1</td><td>Nikolaj Coster-Waldau worked with the Fox Broadcasting Company.Search[Nikolaj Coster-Waldau]Nikolaj William Coster-Waldau (born 27 July 1970) is a Danish actor and producer. He graduated from the Danish National School of Performing Arts in Copenhagen in 1993,[1] and had his breakthrough role in Denmark with the film Nightwatch (1994). He played Jaime Lannister in the HBO fantasy drama series Game of Thrones, for which he received two Primetime Emmy Award nominations for Outstanding Supporting Actor in a Drama Series.. Coster-Waldau has appeared in numerous films in his native Denmark and Scandinavia, including Headhunters (2011) and A Thousand Times Good Night (2013). In the U.S, his debut film role was in the war film Black Hawk Down (2001), playing Medal of Honor recipient Gary Gordon.[2] He then played a detective in the short-lived Fox television series New Amsterdam (2008), and appeared in the 2009 Fox television film Virtuality, originally intended as a pilot.</td></tr><tr><td>Action 2</td><td>Finish [SUPPORTS]</td></tr><tr><td>Claim Action 1 Observation 1</td><td>Stranger Things is set in Bloomington, Indiana.Search[Stranger Things]Stranger Things is an American science fiction horror drama television series created by the Duffer Brothers. Set in the 1980s, primarily in the fictional town of Hawkins, Indiana, the series centers on a number of mysteries and supernatural events occurring around the town and their impact on an ensemble of child and adult characters.</td></tr><tr><td>Action 2</td><td>Finish [REFUTES]</td></tr><tr><td>Claim Action 1 Observation 1</td><td>Beautiful reached number two on the Billboard Hot 100 in 2003.Search[Beautiful]Could not find [Beautiful]. Similar: [&#x27;Beautiful&#x27;, &#x27;Beautiful, Beautiful&#x27;, &#x27;A Beautiful Mind (film)&#x27;, &#x27;Beautiful (Christina Aguilera song)&#x27;, &#x27;Life Is Beautiful&#x27;].</td></tr><tr><td>Action 2 Observation 2</td><td>Search [Beautiful (Christina Aguilera song)&quot;Beautiful&quot; is a song recorded by American singer Christina Aguilera for her fourth studio album, Stripped (2002).Lookup [Billboard Hot 100]</td></tr><tr><td>Action 3 Observation 3</td><td>(Result 1 / 3) The song peaked at number two on the Billboard Hot 100 in the United States, where it was certified Gold for 500,000 units shipped.</td></tr><tr><td>Action 4</td><td>Finish [NOT ENOUGH INFO]</td></tr><tr><td>No</td><td>Determine if there is Observation that SUPPORTS or REFUTES a Claim, or if there is NOT ENOUGH INFORMATION.</td></tr><tr><td>Claim Thought Answer</td><td>Nikolaj Coster-Waldau worked with the Fox Broadcasting Company.Nikolaj William Coster-Waldau appeared in the 2009 Fox television film Virtuality, so he has worked with the Fox Broadcasting Company.SUPPORTS</td></tr><tr><td>Claim Thought Answer</td><td>Stranger Things is set in Bloomington, Indiana.Stranger Things is in the fictional town of Hawkins, Indiana, not in Bloomington, Indiana REFUTES</td></tr></table>

Continued on next page 


Fever Prompts - Continued from previous page


<table><tr><td>Claim</td><td>Beautiful reached number two on the Billboard Hot 100 in 2003.</td></tr><tr><td>Thought</td><td>The song peaked at number two on the Billboard Hot 100 in the United States, but not sure if it was in 2003.</td></tr><tr><td>Answer</td><td>NOT ENOUGH INFO</td></tr><tr><td>ReAct</td><td>Determine if there is Observation that SUPPORTS or REFUTES a Claim, or if there is NOT ENOUGH INFORMATION.</td></tr><tr><td>Claim</td><td>Nikolaj Coster-Waldau worked with the Fox Broadcasting Company.</td></tr><tr><td>Thought 1</td><td>I need to search Nikolaj Coster-Waldau and find if he has worked with the Fox Broadcasting Company.</td></tr><tr><td>Action 1</td><td>Search[Nikolaj Coster-Waldau]</td></tr><tr><td>Observation 1</td><td>Nikolaj William Coster-Waldau (born 27 July 1970) is a Danish actor and producer. He graduated from the Danish National School of Performing Arts in Copenhagen in 1993, [1] and had his breakthrough role in Denmark with the film Nightwatch (1994). He played Jaime Lannister in the HBO fantasy drama series Game of Thrones, for which he received two Primetime Emmy Award nominations for Outstanding Supporting Actor in a Drama Series.. Coster-Waldau has appeared in numerous films in his native Denmark and Scandinavia, including Headhunters (2011) and A Thousand Times Good Night (2013). In the U.S, his debut film role was in the war film Black Hawk Down (2001), playing Medal of Honor recipient Gary Gordon. [2] He then played a detective in the short-lived Fox television series New Amsterdam (2008), and appeared in the 2009 Fox television film Virtuality, originally intended as a pilot.</td></tr><tr><td>Thought 2</td><td>Because he &quot;appeared in the 2009 Fox television film Virtuality&quot;, he should have worked with the Fox Broadcasting Company.</td></tr><tr><td>Action 2</td><td>Finish[SUPPORTS]</td></tr><tr><td>Claim</td><td>Stranger Things is set in Bloomington, Indiana.</td></tr><tr><td>Thought 1</td><td>I should search for Stranger Things, and see if it is set in Bloomington, Indiana.</td></tr><tr><td>Action 1</td><td>Search[Stranger Things]</td></tr><tr><td>Observation 1</td><td>Stranger Things is an American science fiction horror drama television series created by the Duffer Brothers. Set in the 1980s, primarily in the fictional town of Hawkins, Indiana, the series centers on a number of mysteries and supernatural events occurring around the town and their impact on an ensemble of child and adult characters.</td></tr><tr><td>Thought 2</td><td>The observation says that it is set in a &quot;fictional town of Hawkins, Indiana&quot;, so it is not set in Bloomington.</td></tr><tr><td>Action 2</td><td>Finish[REFUTES]</td></tr><tr><td>Claim</td><td>Beautiful reached number two on the Billboard Hot 100 in 2003.</td></tr><tr><td>Thought 1</td><td>I need to search the song Beautiful and find if it reached number two on the Billboard Hot 100 in 2003.</td></tr><tr><td>Action 1</td><td>Search[Beautiful]</td></tr><tr><td>Observation 1</td><td>Could not find [Beautiful]. Similar: [&#x27;Beautiful&#x27;, &#x27;Beautiful, Beautiful&#x27;, &#x27;A Beautiful Mind (film)&#x27;, &#x27;Beautiful (Christina Aguilera song)&#x27;, &#x27;Life Is Beautiful&#x27;].</td></tr><tr><td>Thought 2</td><td>From suggestions, I should search &quot;Beautiful (Christina Aguilera song)&quot; to find the song.</td></tr><tr><td>Action 2</td><td>Search[Beautiful (Christina Aguilera song)]</td></tr><tr><td>Observation 2</td><td>&quot;Beautiful&quot; is a song recorded by American singer Christina Aguilera for her fourth studio album, Stripped (2002).</td></tr><tr><td>Thought 3</td><td>It does not mention Billboard, so I need to look up &quot;Billboard Hot 100&quot; to find if it reached number two on it in 2003.</td></tr><tr><td>Action 3</td><td>Lookup[Billboard Hot 100]</td></tr><tr><td>Observation 3</td><td>(Result 1 / 3) The song peaked at number two on the Billboard Hot 100 in the United States, where it was certified Gold for 500,000 units shipped.</td></tr><tr><td>Thought 4</td><td>It only says the song peaked at number two on the Billboard Hot 100, but not if it was in 2003. I am not sure if this claim is true or not.</td></tr><tr><td>Action 4</td><td>Finish[NOT ENOUGH INFO]</td></tr></table>

# C.3 WEBSHOP


Table 6: Prompts used for the Webshop experiments in Section 4. We use the prompt on the left for Act, and use the prompt on the right (add reasoning) for ReAct.


<table><tr><td colspan="2">Instruction: i would like a 3 ounce bottle of bright citrus deodorant for sensitive skin, and price lower than 50.00 dollars</td></tr><tr><td>Act</td><td>ReAct</td></tr><tr><td>Action: search [3 ounce bright citrus deodorant sensitive skin] Observation: [ Back to Search ] Page 1 (Total results: 50) [Next]</td><td>Action: search [3 ounce bright citrus deodorant sensitive skin Observation: [ Back to Search ] Page 1 (Total results: 50) [Next]</td></tr><tr><td>[B078GWRC1J] Bright Citrus Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 3-Ounce $10.99</td><td>[B078GWRC1J] Bright Citrus Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 3-Ounce $10.99</td></tr><tr><td>[B078GTKVXY] Ginger Fresh Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 3-Ounce $10.99</td><td>[B078GTKVXY] Ginger Fresh Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 3-Ounce $10.99</td></tr><tr><td>[B08KBVJ4XN] Barrel and Oak - Aluminum-Free Deodorant, Deodorant for Men , Essential Oil-Based Scent, 24-Hour Odor Protection, Cedar &amp; Patchouli Blend, Gentle on Sensitive Skin (Mountain Sage, 2.7 oz, 2-Pack) $15.95</td><td>[B08KBVJ4XN] Barrel and Oak - Aluminum-Free Deodorant, Deodorant for Men , Essential Oil-Based Scent, 24-Hour Odor Protection, Cedar &amp; Patchouli Blend, Gentle on Sensitive Skin (Mountain Sage, 2.7 oz, 2-Pack) $15.95</td></tr><tr><td>Action: click [B078GWRC1J] Observation: [Back to Search] [Prev] scent [assorted scents][bright citrus][calming lavender][ginger [fresh] simply non-scents] size [travel set (4-pack)][3 ounce (pack of 1)][3-ounce (2 -pack)] Bright Citrus Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 3-Ounce Price: $10.99 Rating: N.A. [Description] [Features] [Reviews] [Buy Now]</td><td>Action: think[B078GWRC1J and B078GTKVXY are bright citrus deodorant less then 50 dollars. I can check B078GWRC1J first. Observation: OK. Action: click [B078GWRC1J] Observation: [Back to Search] [Prev] scent [assorted scents][bright citrus][calming lavender][ginger [fresh] simply non-scents] size [travel set (4-pack)][3 ounce (pack of 1)][3-ounce (2 -pack)] Bright Citrus Deodorant by Earth Mama | Natural and Safe for Sensitive Skin, Pregnancy and Breastfeeding, Contains Organic Calendula 2-Ounce Price: $10.99 Rating: N.A. [Description] [Features] [Reviews] [Buy Now] Action: think[For 3 ounce bottle of bright citrus deodorant for sensitive skin, the item has options &#x27;bright citrus&#x27; and &#x27;3 ounce (pack of 1)&#x27; and seems good to buy.] Observation: OK. Action: click[bright citrus] Observation: You have clicked bright citrus. Action: click[3 ounce (pack of 1)] Observation: You have clicked 3 ounce (pack of 1). Action: click[Buy Now]</td></tr></table>

# C.4 ALFWORLD


Table 7: An Act prompt on the ALFWorld clean task. No thoughts are provided.


<table><tr><td>You are in the middle of a room. Looking quickly around you, you see a cabinet 13, a cabinet 12, a cabinet 11, a cabinet 10, a cabinet 9, a cabinet 8, a cabinet 7, a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 1, a diningtable 1, a drawer 1, a fridge 1, a garbagean 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean lettuce in diningtable. &gt; go to fridge 1 The fridge 1 is closed. &gt; open fridge 1 You open the fridge 1. The fridge 1 is open. In it, you see a cup 3, a egg 2, a potato 3, and a potato 2. &gt; go to diningtable 1 On the diningtable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a lettuce 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. &gt; take lettuce 1 from diningtable 1 You pick up the lettuce 1 from the diningtable 1. &gt; go to sinkbasin 1 On the sinkbasin 1, you see a apple 2, a ladle 2, a spoon 1, and a tomato 3. &gt; clean lettuce 1 with sinkbasin 1 You clean the lettuce 1 using the sinkbasin 1. &gt; think: Now I clean a lettuce (1). Next, I need to put it in/on diningtable 1. OK. &gt; go to diningtable 1 On the diningtable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. &gt; put lettuce 1 in/on diningtable 1 You put the lettuce 1 in/on the diningtable 1.</td></tr></table>


Table 8: An ReAct prompt on the ALFWorld clean task.


<table><tr><td>You are in the middle of a room. Looking quickly around you, you see a cabinet 13, a cabinet 12, a cabinet 11, a cabinet 10, a cabinet 9, a cabinet 8, a cabinet 7, a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 1, a diningtable 1, a drawer 1, a fridge 1, a garbagean 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean lettuce in diningtable. &gt; think: To solve the task, I need to find and take a lettuce, then clean it with sinkbasin, then put it in diningtable. OK. &gt; think: First I need to find a lettuce. A lettuce is more likely to appear in fridge (1), diningtable (1), sinkbasin (1), stoveburner (1-3), cabinet (1-13). I can check one by one, starting with fridge 1. OK. &gt; go to fridge 1 The fridge 1 is closed. &gt; open fridge 1 You open the fridge 1. The fridge 1 is open. In it, you see a cup 3, a egg 2, a potato 3, and a potato 2. &gt; go to diningtable 1 On the diningtable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a lettuce 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. &gt; think: Now I find a lettuce (1). Next, I need to take it. OK. &gt; take lettuce 1 from diningtable 1 You pick up the lettuce 1 from the diningtable 1. &gt; think: Now I take a lettuce (1). Next, I need to go to sinkbasin (1) and clean it. OK. &gt; go to sinkbasin 1 On the sinkbasin 1, you see a apple 2, a ladle 2, a spoon 1, and a tomato 3. &gt; clean lettuce 1 with sinkbasin 1 You clean the lettuce 1 using the sinkbasin 1. &gt; think: Now I clean a lettuce (1). Next, I need to put it in/on diningtable 1. OK. &gt; go to diningtable 1 On the diningtable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. &gt; put lettuce 1 in/on diningtable 1 You put the lettuce 1 in/on the diningtable 1.</td></tr></table>


Table 9: An ReAct-IM prompt on the ALFWorld clean task.


```txt
You are in the middle of a room. Looking quickly around you, you see a cabinet 13, a cabinet 12, a cabinet 11, a cabinet 10, a cabinet 9, a cabinet 8, a cabinet 7, a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 1, a diningtable 1, a drawer 1, a garagecan 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean lettuce in dininetable. > think: To solve the task, I need to find and take a lettuce, then clean it with sinkbasin, then put it in dininetable. OK. > think: First I need to find a lettuce. OK. > go to fridge 1 The fridge 1 is closed. > think: First I need to find a lettuce. OK. > open fridge 1 You open the fridge 1. The fridge 1 is open. In it, you see a cup 3, a egg 2, a potato 3, and a potato 2. > think: First I need to find a lettuce. OK. > go to dinintable 1 On the dininable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a lettuce 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. > think: First I need to find a lettuce. OK. > take lettuce 1 from dinintable 1 You pick up the lettuce 1 from the dinintable 1. > think: I need to clean this lettuce (1) using sinkbasin 1. OK. > go to sinkbasin 1 On the sinkbasin 1, you see a apple 2, a ladle 2, a spoon 1, and a tomato 3. > think: I need to clean this lettuce (1) using sinkbasin 1. OK. > clean lettuce 1 with sinkbasin 1 You clean the lettuce 1 using the sinkbasin 1. > think: I need to put this cleaned lettuce (1) in/on dinintable 1. OK. > go to dinintable 1 On the dininable 1, you see a apple 1, a bread 1, a butterknife 2, a cup 2, a fork 2, a knife 2, a knife 1, a ladle 1, a mug 2, a mug 1, a pan 2, a peppershaker 1, a spatula 3, a tomato 2, and a tomato 1. > think: I need to put this cleaned lettuce (1) in/on dinintable 1. OK. > put lettuce 1 in/on dinintable 1 You put the lettuce 1 in/on the dinintable 1. 
```

# D TRAJECTORIES

# D.1 FEVER TRAJECTORIES

We provide some trajectories produced by ReAct, CoT and Acton several randomly selected examples from the FEVER dev set below. Search results are omitted to space. 


Example 2491 (gt: REFUTES)


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Claim:</td><td>Bermuda Triangle is a loosely-defined region in the Pacific Ocean.</td></tr><tr><td>Thought 1:</td><td>I need to search Bermuda Triangle and find if it is in the Pacific Ocean.</td></tr><tr><td>Action 1:</td><td>Search[Bermuda Triangle]</td></tr><tr><td>Observation 1:</td><td>Reportedly haunted locations...</td></tr><tr><td>Thought 2:</td><td>The observation says that it is in the western part of the North Atlantic Ocean, so it is not in the Pacific Ocean.</td></tr><tr><td>Action 2:</td><td>Finish[REFUTES]</td></tr><tr><td>Observation 2:</td><td>Episode finished</td></tr><tr><td colspan="2">Act</td></tr><tr><td>Claim:</td><td>Bermuda Triangle is a loosely-defined region in the Pacific Ocean.</td></tr><tr><td>Action 1:</td><td>: Search[Bermuda Triangle]</td></tr><tr><td>Observation 1:</td><td>: Reportedly haunted locations...</td></tr><tr><td>Action 2:</td><td>Finish[REFUTES]</td></tr><tr><td>Observation 2:</td><td>Episode finished</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Claim:</td><td>Bermuda Triangle is a loosely-defined region in the Pacific Ocean.</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. The Bermuda Triangle is a loosely-defined region in the Atlantic Ocean. The Pacific Ocean is not the Atlantic Ocean.</td></tr><tr><td>Answer:</td><td>REFUTES</td></tr></table>


Example 5908 (gt: SUPPORTS)


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Claim:</td><td>Princess Mononoke is a film.</td></tr><tr><td>Thought 1:</td><td>I need to search Princess Mononoke and find if it is a film.</td></tr><tr><td>Action 1:</td><td>Search[Princess Mononoke]</td></tr><tr><td>Observation 1:</td><td>Princess Mononoke ...</td></tr><tr><td>Thought 2:</td><td>From the observation, it says that Princess Mononoke is a film.</td></tr><tr><td>Action 2:</td><td>Finish [SUPPORTS]</td></tr><tr><td>Observation 2:</td><td>Episode finished</td></tr><tr><td colspan="2">Act</td></tr><tr><td>Claim:</td><td>Princess Mononoke is a film.</td></tr><tr><td>Action 1:</td><td>Search[Princess Mononoke]</td></tr><tr><td>Observation 1:</td><td>Princess Mononoke ...</td></tr><tr><td>Action 2:</td><td>Finish [SUPPORTS]</td></tr><tr><td>Observation 2:</td><td>Episode finished</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Claim:</td><td>Princess Mononoke is a film.</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. Princess Mononoke is a movie, and movies are films.</td></tr><tr><td>Answer:</td><td>SUPPORTS</td></tr></table>


Example 1951 (gt: REFUTES)


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Claim:</td><td>Soyuz was part of the American space program.</td></tr><tr><td>Thought 1:</td><td>I need to search Soyuz and find if it was part of the American space program.</td></tr><tr><td>Action 1:</td><td>Search[Soyuz]</td></tr><tr><td>Observation 1:</td><td>Soyuz is a transliteration...</td></tr><tr><td>Thought 2:</td><td>It does not mention the American space program, so I need to search &quot;American space program&quot; to find if it was part of it.</td></tr><tr><td>Action 2:</td><td>Search[American space program]</td></tr><tr><td>Observation 2:</td><td>The space policy...</td></tr><tr><td>Thought 3:</td><td>It does not mention Soyuz, so I am not sure if this claim is true or not.</td></tr><tr><td>Action 3:</td><td>Finish[NOT ENOUGH INFO]</td></tr><tr><td>Observation 3:</td><td>Episode finished</td></tr><tr><td colspan="2">Act</td></tr><tr><td>Claim:</td><td>Soyuz was part of the American space program.</td></tr><tr><td>Action 1:</td><td>Search[Soyuz]</td></tr><tr><td>Observation 1:</td><td>Soyuz is a transliteration...</td></tr><tr><td>Action 2:</td><td>Finish[NOT ENOUGH INFO]</td></tr><tr><td>Observation 2:</td><td>Episode finished</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Claim:</td><td>Soyuz was part of the American space program.</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. Soyuz is a Russian spacecraft. The American space program is NASA. NASA and Russia have worked together on the International Space Station.</td></tr><tr><td>Answer:</td><td>SUPPORTS</td></tr></table>


Example 3208 (gt: REFUTES)


```txt
ReAct   
Claim: Reign Over Me is an American film made in 2010. Thought 1: I need to search for Reign Over Me and find if it is an American film made in 2010.   
Action 1: Search[Reign Over Me] Observation 1: Reign Over Me ...   
Thought 2: The observation says that it is an American film made in 2007, so it is not made in 2010.   
Action 2: Finish[REFUTES] Observation 2: Episode finished   
Act   
Claim: Reign Over Me is an American film made in 2010. Action 1: Search[Reign Over Me] Action 2: Finish[SUPPORTS] Observation 2: Episode finished   
CoT   
Claim: Reign Over Me is an American film made in 2010. Thought: Let''s think step by step. First, is Reign Over Me an American film? Yes, it is. Second, was it made in 2010? Yes, it was. Answer: SUPPORTS 
```

# D.2 ALFWORLD TRAJECTORIES

We provide an example trajectory of ReAct, Act, and ReAct-IM on the same ALFWorld game, pick Cleanerthen_place_in_recep-Knife-None-CounterTop-10/ trial_T20190909_110445_675754. 

# D.2.1 REACT TRAJECTORY

ReAct is able to correctly find the knife, clean it, and then place it on a countertop. 


ReAct ALFWorld trajectory


```txt
You are in the middle of a room. Looking quickly around you, you see a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 3, a countertop 2, a countertop 1, a drawer 3, a drawer 2, a drawer 1, a fridge 1, a garbagecan 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean knife in countertop. > think: To solve the task, I need to find and take a knife, then clean it with sinkbasin, then put it in countertop. OK. > think: First I need to find a knife. A knife is more likely to appear in cabinet (1-6), drawer (1-3), countertop (1-3), fridge (1), garbagecan (1), shelf (1-3), sinkbasin (1), stoveburner (1-4), toaster (1). I can check one by one, starting with cabinet 1. OK. > go to cabinet 1 On the cabinet 1, you see a bowl 1. > go to cabinet 2 The cabinet 2 is closed. > go to cabinet 3 On the cabinet 3, you see a glassbottle 1. > go to cabinet 4 On the cabinet 4, you see a mug 1. > go to cabinet 5 The cabinet 5 is closed. > go to cabinet 6 The cabinet 6 is closed. > go to drawer 1 The drawer 1 is closed. > go to drawer 2 The drawer 2 is closed. > go to drawer 3 The drawer 3 is closed. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > go to countertop 2 On the countertop 2, you see a cup 1, a dishsponge 1, a glassbottle 3, a knife 1, a plate 2, a potato 3, and a statue 1. > think: Now I find a knife (1). Next, I need to take it. OK. > take knife 1 from countertop 2 You pick up the knife 1 from the countertop 2. > think: Now I take a knife (1). Next, I need to go to sinkbasin (1) and clean it. OK. > go to sinkbasin 1 On the sinkbasin 1, you see a fork 3, a lettuce 3, and a spatula 2. > clean knife 1 with sinkbasin 1 You clean the knife 1 using the sinkbasin 1. > think: Now I clean a knife (1). Next, I need to put it in/on countertop 1. OK. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > put knife 1 in/on countertop 1 You put the knife 1 in/on the countertop 1. 
```

# D.2.2 ACT TRAJECTORY

Act is able to correctly find the knife, but tries to clean it using a sinkbasin before actually going to the sinkbasin. From there on, the model is unable to recover, and is stuck repeating the same sequence of commands. With ReAct, an existing thought would have concretely identified that the knife had been taken, and that the next subgoal was to go to a sinkbasin to clean it. 


Act ALFWorld trajectory


You are in the middle of a room. Looking quickly around you, you see a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 3, a countertop 2, a countertop 1, a drawer 3, a drawer 2, a drawer 1, a fridge 1, a garbagecan 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean knife in countertop. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > go to countertop 2 On the countertop 2, you see a cup 1, a dish sponge 1, a glassbottle 3, a knife 1, a plate 2, a potato 3, and a statue 1. > take knife 1 from countertop 2 You pick up the knife 1 from the countertop 2. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > clean knife 1 with sinkbasin 1 Nothing happens. > go to countertop 3 On the countertop 3, you see a bread 3, a butterknife 2, a cellphone 1, a creditcard 1, a fork 2, a houseplant 1, a knife 2, a spatula 1, a statue 3, a tomato 3, a tomato 2, a tomato 1, and a vase 2. > take knife 2 from countertop 3 Nothing happens. > go to countertop 2 On the countertop 2, you see a cup 1, a dish sponge 1, a glassbottle 3, a plate 2, a potato 3, and a statue 1. > take knife 1 from countertop 2 Nothing happens. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > clean knife 1 with sinkbasin 1 Nothing happens. > go to countertop 3 On the countertop 3, you see a bread 3, a butterknife 2, a cellphone 1, a creditcard 1, a fork 2, a house plant 1, a knife 2, a spatula 1, a statue 3, a tomato 3, a tomato 2, a tomato 1, and a vase 2. > take knife 2 from countertop 3 Nothing happens. > go to countertop 2 On the countertop 2, you see a cup 1, a dish sponge 1, a glassbottle 3, a plate 2, a potato 3, and a statute 1. > take knife 1 from countertop 2 Nothing happens. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > clean knife 1 with sinkbasin 1 Nothing happens. > go to countertop 3 On the countertop 3, you see a bread 3, a butterknife 2, a cellphone 3, a creditcard 1, a fork 2, a house plant 1, a knife 2, a spatula 1, a statue 3, a tomato 3, a tomato 2, a tomato 1, and a vase 2. > take knife 2 from countertop 3 Nothing happens. > go to countertop 2 On the countertop 2, you see a cup 1, a dish sponge 1, a glassbottle $\mathbf{3}$ ,a plate $\mathbf{2}$ ,a potato $\mathbf{3}$ ,and a statue $\mathbf{I}$ . > take knife I from countertop $\mathbf{2}$ Nothing happens. 

# D.2.3 REACT-IM TRAJECTORY

ReAct-IM is able to correctly find the knife, but is unable to clean it as well. The LLM then gets stuck trying to place this knife on a countertop. One possible issue is the incorrect thought think: I need to find a clean knife., which seems to trick the LLM in believing that the knife is already cleaned. In ReAct, this sequence of subgoals would be concretely captured by each thought. 


ReAct-IM ALFWorld trajectory


```txt
You are in the middle of a room. Looking quickly around you, you see a cabinet 6, a cabinet 5, a cabinet 4, a cabinet 3, a cabinet 2, a cabinet 1, a coffeemachine 1, a countertop 3, a countertop 2, a countertop 1, a drawer 3, a drawer 2, a drawer 1, a fridge 1, a garbagecan 1, a microwave 1, a shelf 3, a shelf 2, a shelf 1, a sinkbasin 1, a stoveburner 4, a stoveburner 3, a stoveburner 2, a stoveburner 1, and a toaster 1. Your task is to: put a clean knife in countertop. > think: To solve the task, I need to find and take a clean knife, then put it in countertop. OK. > think: I need to find a clean knife. OK. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > think: I need to find a clean knife. OK. > go to countertop 2 On the countertop 2, you see a cup 1, a dishsponge 1, a glassbottle 3, a knife 1, a plate 2, a potato 3, and a statue 1. > think: I need to find a clean knife. OK. > take knife 1 from countertop 2 You pick up the knife 1 from the countertop 2. > think: I need to put this knife (1) in/on countertop 1. OK. > go to countertop 1 On the countertop 1, you see a lettuce 2, a mug 2, a peppershaker 1, and a spoon 2. > think: I need to put this knife (1) in/on countertop 1. OK. > put knife 1 in/on countertop 1 You put the knife 1 in/on the countertop 1. > think: I need to put this knife (1) in/on countertop 1. OK. > put knife 1 in/on countertop 1 Nothing happens. > think: I need to put this knife (1) in/on countertop 1. OK. > put knife 1 in/on countertop 1 Nothing happens. > think: I need to put this knife (1) in/on countertop 1. OK. > put knife 1 in/on countertop 1 Nothing happens. > think: I need to put this knife (1) in/on countertop 1. OK. > put knife 1 in/on countertops 1 Nothing happens. > think: I need to put this knife (1) in/on countertop 1. OK. 
```

# D.3 WEBSHOP TRAJECTORIES


Table 10: Example trajectories for Webshop predicted by Act and ReAct. Compared to Act, ReAct uses reasoning to find products that satisfy all target attributes.


<table><tr><td colspan="2">Instruction: get me a sixteen pack of apple cinnamon freeze dried banana chips, and price lower than 50.00 dollars</td></tr><tr><td>Act</td><td>ReAct</td></tr><tr><td>Action: search [sixteen pack apple cinnamon freeze dried banana chips]</td><td>Action: search [sixteen pack apple cinnamon freeze dried banana chips]</td></tr><tr><td>Observation: 
[ Back to Search ] 
Page 1 (Total results: 50) 
[Next]</td><td>Observation: 
[ Back to Search ] 
Page 1 (Total results: 50) 
[Next]</td></tr><tr><td>[B0061IVFZE] 
Brothers-ALL-Natural Fruit Crisps, Strawberry Banana, 0.42 - Ounce (Pack of 100) 
$85.0</td><td>[B0061IVFZE] 
Brothers-ALL-Natural Fruit Crisps, Strawberry Banana, 0.42 - Ounce (Pack of 100) 
$85.0</td></tr><tr><td>[B096H2P6G2] 
Moon Fruit Freeze Dried Fruit Snacks. Fruit Snacks for Kids - (Variety Pack) 
$18.99</td><td>[B096H2P6G2] 
Moon Fruit Freeze Dried Fruit Snacks. Fruit Snacks for Kids - (Variety Pack) 
$18.99</td></tr><tr><td>[B092JLLYK6] 
Nature&#x27;s Turn Freeze-Dried Fruit Snacks - Banana Crisps - Perfect For School Lunches or an On-The-Go Snack - No Sugar Added, Non GMO, Gluten Free, Nothing Artificial (0.53oz) 6-Pack $12.99</td><td>[B092JLLYK6] 
Nature&#x27;s Turn Freeze-Dried Fruit Snacks - Banana Crisps - Perfect For School Lunches or an On-The-Go Snack - No Sugar Added, Non GMO, Gluten Free, Nothing Artificial (0.53oz) 6-Pack $12.99</td></tr><tr><td>Action: click [B0061IVFZE] 
Observation: 
[Back to Search] 
[Prev] 
flavor name [asian pear][banana][fuji apple &amp; cinnamon][strawberry banana] Brothers-ALL-Natural Fruit Crisps, Strawberry Banana, 0.42 Ounce (Pack of 100) 
Price: $85.0</td><td>Action: think [B0061IVFZE is strawberry banana, not apple cinnamon. 
B096H2P6G2 is fruit snacks, not freeze dried banana chips. 
B092JLLYK6 is banana crisps, not apple cinnamon. I can check 
B092JLLYK6 first. 
Observation: OK.</td></tr><tr><td>Rating: N.A. 
[Description] 
[Features] 
[Reviews] 
[Buy Now]</td><td>Action: click [B092JLLYK6] 
Observation: 
[Back to Search] 
[Prev] 
flavor name [apple][apple cinnamon][banana][cantaloupe][peach][pear] 
[strawberry][strawberry banana][sampler variety pack][mega variety pack][orchard variety pack] 
size [0.53 ounce (pack of 6)][0.53 ounce (pack of 8)][0.53 ounce (pack of 16)] 
Nature&#x27;s Turn Freeze-Dried Fruit Snacks - Banana Crisps - Perfect For School Lunches or an On-The-Go Snack - No Sugar Added, Non GMO, Gluten Free, Nothing Artificial (0.53oz) 6-Pack Price: $12.99 
Rating: N.A. 
[Description] 
[Features] 
[Reviews] 
[Buy Now]</td></tr><tr><td>Action: click [Buy Now]</td><td>Action: think [For sixteen pack of apple cinnamon freeze dried banana chips, the item has options &#x27;apple cinnamon&#x27; and &#x27;0.53 ounce (pack of 16)&#x27; and seems good to buy.] 
Observation: OK.</td></tr><tr><td>Score: 0.125</td><td>Action: click [apple cinnamon] 
Observation: You have clicked apple cinnamon. 
Action: click [0.53 ounce (pack of 16)] 
Observation: You have clicked 0.53 ounce (pack of 16). 
Action: click [Buy Now]</td></tr></table>

# E MORE ANALYSIS

# E.1 SUCCESS AND FAILURE MODES ANALYSIS

We provide some examples corresponding to the success and error mode analysis given in Sec. 3.3. Search results and non-representative steps are omitted to reduce space. 


Success: True positive


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Question:</td><td>Author David Chanoff has collaborated with a U.S. Navy admiral who served as the ambassador to the United Kingdom under which President?</td></tr><tr><td>Thought 1:</td><td>I need to search David Chanoff and find the U.S. Navy admiral he collaborated with.</td></tr><tr><td>Action 1:</td><td>Search[David Chanoff]</td></tr><tr><td>Observation 1:</td><td>David Chanoff is a noted author...</td></tr><tr><td>Action 2:</td><td>Search[William J. Crowe]</td></tr><tr><td>Observation 2:</td><td>William J. Crowe is...</td></tr><tr><td>Thought 3:</td><td>William J. Crowe served as the ambassador to the United Kingdom under President Bill Clinton. So the answer is Bill Clinton.</td></tr><tr><td>Action 3:</td><td>Finish[Bill Clinton]</td></tr><tr><td>Observation 3:</td><td>Episode finished</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Question:</td><td>What was the name of the team that represented an Arizona university in the conference that covers a broad expanse of the western United States, including Arizona, California, and New Mexico?</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. The name of the team that represented an Arizona university in the conference that covers a broad expanse of the western United States, including Arizona, California, and New Mexico is Arizona State Sun Devils.</td></tr><tr><td>Answer:</td><td>Arizona State Sun Devils</td></tr></table>


Success: False positive


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Question:</td><td>Did the board game San Marco or About Time come out first?</td></tr><tr><td>Thought 1:</td><td>I need to search San Marco and About Time, and find which came out first.</td></tr><tr><td>Action 1:</td><td>Search[San Marco]</td></tr><tr><td>Observation 1:</td><td>San Marco is one of the ... The was built in verince.</td></tr><tr><td>Thought 2:</td><td>San Marco is a sestiere of Venice. I need to search About Time next.</td></tr><tr><td>Action 2:</td><td>Search[About Time]</td></tr><tr><td>Observation 2:</td><td>Could not find [About Time]. Similar: [...]</td></tr><tr><td>Thought 3:</td><td>About Time is a 2013 film. So San Marco came out first.</td></tr><tr><td>Action 3:</td><td>Finish[San Marco]</td></tr><tr><td>Observation 3:</td><td>Episode finished</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Question:</td><td>Was Vanderbilt University or Emory University founded first?</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. Vanderbilt University was founded in 1873. Emory University was founded in 1836. 1873 (Vanderbilt University) &gt; 1836 (Emory University), so Vanderbilt University was founded first.</td></tr><tr><td>Answer:</td><td>Emory University</td></tr></table>


Failure: Reasoning error


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Question:</td><td>What was the middle name of the actress who was cast alongside Harvey Fierstein, Linda Hart, Dick Latessa, Clarke Thorell, Mary Bond Davis, Laura Bell Bundy, Matthew Morrison, Corey Reynolds, and Marissa Jaret Winokur in Hairspray?</td></tr><tr><td>Thought 1:</td><td>I need to search Harvey Fierstein, Linda Hart, Dick Latessa, Clarke Thorell, Mary Bond Davis, Laura Bell Bundy, Matthew Morrison, Corey Reynolds, and Marissa Jaret Winokur, find the actress that was cast alongside them in Hairspray, then find its middle name.</td></tr><tr><td>Action 1:</td><td>Search[Harvey Fierstein]</td></tr><tr><td>Observation 1:</td><td>Harvey Forbes Fierstein ...</td></tr><tr><td>Thought 2:</td><td>Harvey Fierstein is an actor, playwright, and screenwriter. I need to search Linda Hart next...</td></tr><tr><td>Action 2:</td><td>Search[Linda Hart]...</td></tr><tr><td colspan="2">CoT</td></tr><tr><td>Question:</td><td>Who is older Danny Green or James Worthy?</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. Danny Green was born in 1987. James Worthy was born in 1961. 1987 (Danny Green) &gt; 1961 (James Worthy), so Danny Green is older.</td></tr><tr><td>Answer:</td><td>Danny Green</td></tr></table>


Failure: Search error


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Question:</td><td>What does the goddess associated with the goddess frigg consists of what tales?</td></tr><tr><td>Thought 1:</td><td>I need to search goddess frigg and find its associated goddess.</td></tr><tr><td>Action 1:</td><td>Search[goddess frigg]</td></tr><tr><td>Observation 1:</td><td>Could not find goddess frigg. Similar: [&#x27;Frigg&#x27;, &#x27;Frigg and Freyja common origin hypothesis&#x27;, &#x27;Freyja (section Relation to Frigg and other goddesses and figures)&#x27;, &#x27;Eir (redirect from Eir (goddess))&#x27;, &#x27;Baldr&#x27;].</td></tr><tr><td>Thought 2:</td><td>I need to search Frigg instead...</td></tr></table>


Failure: Hallucination


<table><tr><td colspan="2">CoT</td></tr><tr><td>Question:</td><td>What was the first year a scientific journal published by an organization located in the Bronx was published?</td></tr><tr><td>Thought:</td><td>Let&#x27;s think step by step. The first year a scientific journal published by an organization located in the Bronx was published was 1916.</td></tr><tr><td>Answer:</td><td>1916 (Label: 1909)</td></tr></table>


Failure: Label ambiguity


<table><tr><td colspan="2">ReAct</td></tr><tr><td>Question: Thought 1:</td><td>What nationality is the man who developed the dictator game? I need to search dictator game, find the man who developed it, then find his nationality.</td></tr><tr><td>Action 1:</td><td>Search[dictator game]</td></tr><tr><td>Observation 1:</td><td>The dictator game is a popular experimental instrument in social psychology and economics...</td></tr><tr><td>Action 3:</td><td>Search[Amos Tversky]</td></tr><tr><td>Observation 3:</td><td>Amos Nathan Tversky...</td></tr><tr><td>Thought 4:</td><td>Amos Tversky is an Israeli cognitive and mathematical psychologist. So the man who developed the dictator game is Israeli.</td></tr><tr><td>Action 4:</td><td>Finish[Israeli] (label: Israel-American)</td></tr><tr><td colspan="2">ToT</td></tr><tr><td>Question: Thought:</td><td>Kurt Fuller from Stockton, CA appeared in which American Detective Comedy Drama television series created by Steve Franks? Let&#x27;s think step by step. Kurt Fuller from Stockton, CA appeared in Psych. Psych is an American Detective Comedy Drama television series created by Steve Franks.</td></tr><tr><td>Answer:</td><td>Psych (label: Psych is an American detective comedy-drama)</td></tr></table>', '{"title": "REACT: SYNERGIZING REASONING AND ACTING IN LANGUAGE MODELS", "sections": [{"level": 1, "title": "ABSTRACT"}, {"level": 1, "title": "1 INTRODUCTION"}, {"level": 1, "title": "2 REACT: SYNERGIZING REASONING + ACTING"}, {"level": 1, "title": "3 KNOWLEDGE-INTENSIVE REASONING TASKS", "children": [{"level": 2, "title": "3.1 SETUP"}, {"level": 2, "title": "3.2 METHODS"}, {"level": 2, "title": "3.3 RESULTS AND OBSERVATIONS"}]}, {"level": 1, "title": "4 DECISION MAKING TASKS"}, {"level": 1, "title": "5 RELATED WORK"}, {"level": 1, "title": "6 CONCLUSION"}, {"level": 1, "title": "ACKNOWLEDGMENTS"}, {"level": 1, "title": "REPRODUCIBILITY STATEMENT"}, {"level": 1, "title": "ETHICS STATEMENT"}, {"level": 1, "title": "REFERENCES"}, {"level": 1, "title": "A ADDITIONAL RESULTS", "children": [{"level": 2, "title": "A.1 GPT-3 EXPERIMENTS"}, {"level": 2, "title": "A.2 REACT OBTAINS UP-TO-DATE KNOWLEDGE ON HOTPOTQA"}, {"level": 2, "title": "A.3 HUMAN-IN-THE-LOOP BEHAVIOR CORRECTION ON ALFWORLD"}]}, {"level": 1, "title": "B EXPERIMENT DETAILS", "children": [{"level": 2, "title": "B.1 HOTPOTQA FINETUNING DETAILS"}, {"level": 2, "title": "B.2 ALFWORLD IM-STYLE DETAILS"}]}, {"level": 1, "title": "C PROMPTS", "children": [{"level": 2, "title": "C.1 HOTPOTQA"}, {"level": 2, "title": "C.2 FEVER"}, {"level": 2, "title": "C.3 WEBSHOP"}, {"level": 2, "title": "C.4 ALFWORLD"}]}, {"level": 1, "title": "D TRAJECTORIES", "children": [{"level": 2, "title": "D.1 FEVER TRAJECTORIES"}, {"level": 2, "title": "D.2 ALFWORLD TRAJECTORIES", "children": [{"level": 3, "title": "D.2.1 REACT TRAJECTORY"}, {"level": 3, "title": "D.2.2 ACT TRAJECTORY"}, {"level": 3, "title": "D.2.3 REACT-IM TRAJECTORY"}]}, {"level": 2, "title": "D.3 WEBSHOP TRAJECTORIES"}]}, {"level": 1, "title": "E MORE ANALYSIS", "children": [{"level": 2, "title": "E.1 SUCCESS AND FAILURE MODES ANALYSIS"}]}]}', '2026-03-15 20:13:32.896576', 'success', NULL);
INSERT INTO "public"."doc_parsed" VALUES (2, 2, '# DeepResearch Arena: The First Exam of LLMs’ Research Abilities via Seminar-Grounded Tasks

Haiyuan Wan 1,2 *, Chen Yang 3 *, Junchi Yu 4, Meiqi Tu 5, Jiaxuan Lu 1, Di Yu 1,2, Jianbao Cao 1,6, Ben Gao 1, 6, Jiaqing Xie 1, Aoran Wang 1, Wenlong Zhang 1, Philip Torr 4, Dongzhan Zhou 1† 

1Shanghai Artificial Intelligence Laboratory 2Tsinghua University 3The Hong Kong University of Science and Technology, Guangzhou 4University of Oxford 5The University of Hong Kong 6Wuhan University 

# Abstract

Deep research agents have attracted growing attention for their potential to orchestrate multi-stage research workflows, spanning literature synthesis, methodological design, and empirical verification. Despite these strides, evaluating their research capability faithfully is rather challenging due to the difficulty of collecting frontier research questions that genuinely capture researchers’ attention and intellectual curiosity. To address this gap, we introduce DeepResearch Arena, a benchmark grounded in academic seminars that capture rich expert discourse and interaction, better reflecting real-world research environments and reducing the risk of data leakage. To automatically construct DeepResearch Arena, we propose a Multi-Agent Hierarchical Task Generation (MAHTG) system that extracts research-worthy inspirations from seminar transcripts. The MAHTG system further translates researchworthy inspirations into high-quality research tasks, ensuring the traceability of research task formulation while filtering noise. With the MAHTG system, we curate DeepResearch Arena with over 10,000 high-quality research tasks from over 200 academic seminars, spanning 12 disciplines, such as literature, history, and science. Our extensive evaluation shows that DeepResearch Arena presents substantial challenges for current state-of-the-art agents, with clear performance gaps observed across different models. 

# Introduction

Recent developments in large language models (LLMs) have led to the rise of the deep research agent (Huang et al. 2025; Xu and Peng 2025; Wu et al. 2025), a LLM-powered agentic system designed for research task automation by integrating literature search (Baek et al. 2024), experiment design (Schmidgall et al. 2025), and ideation (Li et al. 2024). Prevailing examples, such as GPT DeepResearch (OpenAI 2025), indicate that deep research agents have great potential to significantly promote research creativity and productivity. 

While deep research agents have gained increasing attention (Du et al. 2025), faithfully evaluating their research ability remains a huge challenge. As Einstein once stated, The formulation of the problem is often more essential than its solution, which may be merely a matter of mathematical 

or experimental skill (Einstein and Infeld 1938). This perspective highlights a crucial challenge in formulating highquality and frontier research tasks to faithfully assess the ability of deep research agents. 

Existing benchmarks for deep research agents mainly resort to two approaches to acquire research questions. The first leverages static data corpora such as academic literature and web content, as seen in AcademicBrowse (Zhou et al. 2025a), BrowseComp (Wei et al. 2025), and Researchbench (Liu et al. 2025). The second approach involves manually curated research tasks by domain experts, exemplified by Humanity’s Last Exam (Phan et al. 2025), DeepResearchBench (Du et al. 2025), and ExpertLongBench (Ruan et al. 2025). However, both approaches are hindered by critical limitations. Benchmarks derived from static corpora risk data leakage, as the underlying content may already be included in the model pertaining. Meanwhile, datasets curated by experts face scalability bottlenecks and often lack the diversity and spontaneity found in authentic research settings. More fundamentally, both sources tend to abstract away from the situated, evolving nature of real-world research inquiry, where questions emerge dynamically through discourse, ambiguity, and interdisciplinary exploration. A detailed comparison of these benchmarks across key dimensions, including scalability, automation, data leakage risk, and research realism, is provided in Table 1. 

To bridge this gap, we introduce a novel benchmark, Deep Research Arena, designed to evaluate deep research agents under authentic, cognitively demanding research scenarios. Unlike static corpora that present information without context, or expert-curated benchmarks that rely on handcrafted tasks detached from actual discovery processes, the proposed benchmark is grounded in academic seminars, where real researchers pose open-ended questions, explore uncertain ideas, and build shared understanding through live discussion. This source captures how real research problems naturally emerge, making Deep Research Arena a more faithful proxy of real-world inquiry. Furthermore, seminar videos are rarely included in model pretraining, which significantly reduces the risk of data leakage that commonly affects benchmarks derived from literature or web corpora. 

To capture the nature of such authentic inquiry, Deep Research Arena formulates tasks as open-ended, under-defined 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/17f6f6d18a5571bfd5d6e08b355e0d2f9f1d530581440baef915eb926a513402.jpg)



Figure 1: Overview of seminar domains and task structures in MAHTG. Left: Distribution of academic seminars across diverse domains such as Science & Technology, Health, Finance, and others. The outer arc further decomposes each domain into representative research tasks. For instance, Science & Technology includes tasks such as Hypothesis Generation, Empirical Test, Prototype Specification, and Trend Scan. Right: Illustration of MAHTG’s multi-agent pipeline, where seminar content is transformed into structured research tasks via intermediate inspirations (e.g., Methodology, Transdisciplinarity). Example outputs are shown for both stages.


problems, drawn by the theory of Ill-Structured Problem Solving (Jonassen 1997), which describes real-world problems as “poorly defined, with no single correct formulation and no objective evaluation criteria”. To construct the Deep Research Arena, we develop a Multi-Agent Hierarchical Task Generation (MAHTG) system that automatically extracts research-worthy inspirations and systematically transforms them into high-quality, traceable research tasks through a multi-stage filtering and structuring pipeline. This design ensures both the authenticity and reproducibility of task construction, while reducing noise and preserving the intellectual context of original expert discourse. 

We curate a large-scale, multidisciplinary seminar dataset, constructing over 10,000 structured tasks spanning core research competencies. Building on this, we develop a hybrid evaluation framework that jointly measures factual grounding and higher-order reasoning, with examples shown in Figure 1. Together, these contributions provide a rigorous and theory-aligned foundation for assessing deep research competence in deep research agents. 

Our contributions are threefold: 

• Seminar-grounded data collection. We curate a corpus of over 200 academic seminars across 12 disciplines, encompassing real-world expert discourse across science, engineering, humanities, and the arts. 

• Hierarchical task generation. A multi-stage agent framework extracts research-worthy inspirations from seminar transcripts, categorized into Limitation, Methodology, Transdisciplinarity, and Hypothesis, and transforms them into over 10,000 open-ended tasks aligned with the canonical research stages of Synthesis, Design, 

and Evaluation. 

• Hybrid evaluation framework. We employ two complementary metrics to quantify factual alignment via extracted keypoints and evaluate open-ended reasoning using adaptively generated, rubric-based checklists. 

# Related Works

Deep Research Agents. The emergence of DR agents builds upon recent advances in LLMs equipped with tooluse capabilities (Li et al. 2025; Qu et al. 2025; Tang et al. 2023), which allow models to interface with search engines, code interpreters, and external APIs to extend their reasoning horizon. On this foundation, systems such as GPT Deep Research (OpenAI 2025), Gemini Deep Research (Google 2025), and Grok DeepSearch (xAI 2025) have been developed to support multi-stage research workflows. GPT’s system focuses on outline-driven long-form synthesis with citation grounding, Gemini emphasizes multimodal retrieval and synthesis, while Grok prioritizes real-time web summarization for dynamic topics. These agents reflect a shift from retrieval-based assistants to goal-directed, tool-augmented agents capable of supporting exploratory, open-ended inquiry (Yu, He, and Ying 2023). 

Benchmarks for Deep Research Agents. Existing benchmarks for deep research agents mainly resort to two approaches to acquire research questions: automatically deriving tasks from static corpora or manually curating them through expert design. The first leverages static data corpora such as papers, and web documents to construct benchmarks represented by multi-hop reasoning or simplified sci-

<table><tr><td>Benchmark</td><td>Data Source</td><td>Scalability</td><td>Risk of Data Leakage</td><td>Task Automation</td><td>Research Realism</td></tr><tr><td>ScholarSearch</td><td>Literature</td><td>✓</td><td>✓</td><td>✗</td><td>✗</td></tr><tr><td>BrowseComp</td><td>Web Corpus</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td></tr><tr><td>ResearchBench</td><td>Literature</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td></tr><tr><td>Humanity&#x27;s Last Exam</td><td>Expert</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td></tr><tr><td>DeepResearchBench</td><td>Expert</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td></tr><tr><td>ExpertLongBench</td><td>Expert</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td></tr><tr><td>DeepResearch Arena (Ours)</td><td>Seminar Discourse</td><td>✓</td><td>✗</td><td>✓</td><td>✓</td></tr></table>


Table 1: Comparison of existing deep research benchmarks and our DeepResearch Arena along key dimensions.


entific queries. Examples include MuSiQue (Trivedi et al. 2022), which automatically generates multi-hop questions by linking single-hop QA pairs from existing datasets, and HotpotQA (Yang et al. 2018), where annotators write questions guided by system-selected Wikipedia article pairs, making the process closer to extraction than genuine question generation. Other benchmarks in this category include StrategyQA (Geva et al. 2021), ThoughtSource (Ott et al. 2023), AcademicBrowse (Zhou et al. 2025a), and BrowseComp (Wei et al. 2025). Despite their emphasis on multistep reasoning, these benchmarks rely on manually constructed logic chains with predefined paths. They primarily test factual retrieval and compositional reasoning capabilities, yet fail to capture how research questions naturally emerge, evolve, and iterate in real-world research contexts. ScienceQA (Lu et al. 2022) is a large-scale multimodal multiple-choice science QA benchmark ( 21K questions across STEM and social/language science) that includes lecture and explanation-level CoT annotations to support interpretable multi-step reasoning. 

The second category consists of expert-authored benchmarks, where researchers collaborate with domain specialists to construct high-quality, PhD-level evaluation tasks. Compared to benchmarks built from static corpora, these datasets typically feature more original, conceptually challenging, and discipline-specific questions that better reflect expert-level reasoning. Representative examples include LAB-Bench (Laurent et al. 2024), ARC (Clark et al. 2018), GPQA (Rein et al. 2024), FrontierMath (Glazer et al. 2024), and Humanity’s Last Exam (Phan et al. 2025). GPQA provides graduate-level multiple-choice questions in biology, physics, and chemistry, curated and verified by domain PhDs to ensure they cannot be solved via surface-level heuristics or web search. Humanity’s Last Exam comprises a collection of open-ended, expert-written research questions across disciplines such as history, philosophy, and theoretical science, designed to probe creative, integrative thinking under minimal structural constraints. DeepResearch Bench (Du et al. 2025) moves toward more realistic simulation by requiring long-form research reports across disciplines. However, this entire class of expert-authored benchmarks faces several limitations: their prompts are manually constructed, which restricts scalability and diversity, and the datasets remain relatively small in size. More fundamentally, they also fail to capture how research questions emerge dynamically 

through discourse, ambiguity, and interdisciplinary exploration—core characteristics of authentic research practice. 

# Multi-Agent Hierarchical Task Generation.

Data Collection. To support the construction of research tasks grounded in authentic scholarly practice, we curated a diverse corpus of over 200 academic seminar videos spanning 12 disciplines, contributed by PhD-level researchers and sourced from publicly accessible academic seminar recordings spanning multiple disciplines. Each video is knowledge-dense and typically lasts around or over 1 hour, and the disciplinary distribution of this corpus is illustrated in Figure 2. Seminar recordings preserve the full contextual flow of expert discourse, encompassing how researchers synthesize prior knowledge, design new approaches, and evaluate outcomes. In this way, they offer a rich context for task generation. Compared to static corpora such as Wikipedia or scientific articles, seminar data captures dynamic and authentic interactions among scholars, reflecting the iterative and evolving nature of real-world research. 

As a first step in processing the raw seminar videos, we extract the audio and convert it into textual transcripts with automatic speech recognition. The resulting transcripts retain the full semantic content of the original recordings while remaining absent from existing LLM pretraining corpora, thereby reducing the risk of data contamination and ensuring the integrity of task construction. 

Inspiration Extraction. Based on seminar transcripts, Inspira Agent automatically extracts inspirations (as illustrated in Table 2) from seminar transcripts, transforming unstructured expert discourse into structured units suitable for downstream research task construction. To identify academically valuable content, the agent evaluates candidate segments along four dimensions: Novelty, Explorability, Challenge, and Verifiability. Each selected inspiration must satisfy at least two of these criteria. This multi-dimensional filtering process enables the agent to effectively suppress irrelevant or redundant material, reorganize latent research signals, and produce outputs with clearer logical structure and sharper thematic focus, thereby enhancing their suitability for subsequent task generation. In addition, the agent categorizes each item based on its informational focus into one of four types: Limitation, Methodology, transdisciplinarity, Hypothesis, as illustrated in Table 2, representing testable 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/7f9eba4a38289b64012ede1f52925e20887c8a218a75045fd5eabb8322c04f72.jpg)



Figure 2: Overview of our benchmark construction pipeline, including four stages: (a) Data generation from transcribed seminar videos, (b) extraction of research inspirations, (c) multi-phase task design, and (d) evaluation using both KAE and ACE metrics.


claims that can be empirically verified. 

Task Generation and Filtering. Building on the structured inspirations extracted from seminar transcripts, we deploy TaskWeaver Agent that aggregates and reorganizes content across multiple inspirations to synthesize a focused set of concrete research tasks distributed across three key phases—Synthesize, Design, and Evaluate, as illustrated in Figure 2. These tasks are constructed by identifying the core problem focus or methodological cues within the inspirations and are paired with clearly defined, executable goals. This structured synthesis process enables the scalable construction of diverse, high-quality DeepResearch tasks aligned with the demands of real-world scientific inquiry (Yu et al. 2022). 

To rank the quality of research tasks, we adopt RankEval Agent based on the Elo rating system (Glickman 1995). Each task is initialized with a rating score of 1200. In each round, we randomly sample disjoint pairs of tasks and compare them based on evaluation criteria such as originality, clarity, and scientific relevance. Given a pair of tasks $t _ { a }$ and $t _ { b }$ with current Elo scores $r _ { a }$ and $r _ { b }$ , we first compute the expected winning probabilities using: 

$$
e _ {a} = \frac {1}{1 + 1 0 ^ {\left(r _ {b} - r _ {a}\right) / 4 0 0}}, \tag {1}
$$

where $e _ { b } \ = \ 1 - \ e _ { a }$ . An evaluator determines which task is preferred, along with a confidence score $C \in [ 0 . 5 , 1 . 0 ]$ . Based on this, we assign soft outcomes: 

$$
s _ {a} = C, \quad s _ {b} = 1 - C \tag {2}
$$

We then update the Elo scores using the following update rule: 

$$
r _ {a} ^ {\prime} = r _ {a} + K \cdot \left(s _ {a} - e _ {a}\right), \quad r _ {b} ^ {\prime} = r _ {b} + K \cdot \left(s _ {b} - e _ {b}\right) \tag {3}
$$

where $K$ is a tunable constant controlling the update magnitude, set to $K = 3 2$ in our implementation. This procedure is repeated over $R$ rounds of comparisons (e.g., $R = 2$ ), allowing the scores to stabilize. After all rounds, we select the top $K$ tasks with the highest Elo scores as the final outputs. 

# Evaluation Methodology

To comprehensively assess the capabilities of deep research agents in research-oriented tasks, we propose a hybrid evaluation framework that integrates both objective and subjective dimensions of performance. Traditional benchmarks often focus narrowly on surface-level accuracy or retrieval metrics, failing to capture the nuanced reasoning, creativity, and methodological rigor required for real-world research. In contrast, our framework disentangles these facets by combining (1) Keypoint-Aligned Evaluation (KAE) to measure factual correctness and grounding against reference materials, and (2) Adaptively-generated Checklist Evaluation (ACE) to score open-ended outputs via fine-grained, model-adaptive rubrics. This dual approach enables multiperspective assessment across all stages of the research workflow, from literature synthesis to hypothesis generation and empirical validation, offering a more faithful estimate of models’ deep research competence. 

Keypoint-Aligned Evaluation. To evaluate the factual adequacy of model-generated research reports in a reference-grounded and scalable manner, we propose a structured KAE pipeline. 

Let $R$ denote a model-generated report, and let $U R L ( R )$ represent the set of all cited URLs in $R$ . For each URL $\bar { u \in \ U R L } ( R )$ , we retrieve the underlying webpage content and extract its factual keypoints using a keypoint extraction function Extract(u): 

$$
K _ {u} = \operatorname {E x t r a c t} (u) \tag {4}
$$

<table><tr><td>Term</td><td>Illustration</td><td>Example</td></tr><tr><td colspan="3">I. Core Unit: Inspiration</td></tr><tr><td>Inspiration</td><td>A research-worthy idea distilled from academic dis- course, exhibiting at least two of: novelty, explorability, challenge, verifiability. Serves as the seed for task gen- eration.</td><td>“A greedy maximal independent-set algorithm … achieves a 2-approximation in O (sum of hyperedge sizes) time … shows classical graph methods can solve edge-colored hypergraph clustering without auxiliary graphs.”</td></tr><tr><td colspan="3">II. Types of Inspiration</td></tr><tr><td>Limitation</td><td>An open problem, deficiency, or bottleneck in existing methods.</td><td>“Few models handle transdisciplinary seminar reasoning.”</td></tr><tr><td>Methodology</td><td>A new or adapted approach, pipeline, or tool.</td><td>“Introduce retrieval-augmented reranking framework.”</td></tr><tr><td>Transdisciplinarity</td><td>Ideas involving the fusion of theories or tools across dis- ciplines.</td><td>“Apply ecological network theory to social dynamics”</td></tr><tr><td>Hypothesis</td><td>A testable proposition that guides design or evaluation.</td><td>“Grounded citations improve factual accuracy.”</td></tr><tr><td colspan="3">III. Task Phase Labels</td></tr><tr><td>Synthesize</td><td>Collecting, integrating, and analyzing prior work to form direction.</td><td>“Identify gaps in seminar-based QA literature.”</td></tr><tr><td>Design</td><td>Designing solutions, models, or experiments to address a problem.</td><td>“Propose a multimodal tree-search method.”</td></tr><tr><td>Evaluate</td><td>Assessing results using structured criteria or bench- marks.</td><td>“Compare keypoint coverage across baselines.”</td></tr></table>


Table 2: Core terminology used in our benchmark, grouped into inspiration, its subtypes, and research task phases. This table standardizes interpretation of key concepts throughout the paper.


We then aggregate the keypoints from all cited sources into a unified, de-duplicated list of keypoints, which we term the Unified Evidence Keypoints (UEK): 

$$
\mathrm {U E K} = \operatorname {D e d u p} \left(\bigcup_ {u \in U R L (R)} K _ {u}\right) \tag {5}
$$

Given this set of reference keypoints, we evaluate the report $R$ along three dimensions: 

(1) Keypoint Supported Rate (KSR): the proportion of keypoints from UEK that are explicitly covered or supported in the report: 

$$
\operatorname {K S R} (R) = \frac {\left| S u p p o r t e d (R , \mathrm {U E K}) \right|}{\left| \mathrm {U E K} \right|} \tag {6}
$$

(2) Keypoint Conflict Rate (KCR): the proportion of keypoints from UEK that are contradicted by content in the report: 

$$
\operatorname {K C R} (R) = \frac {\left| \text {c o n f l i c t} (R , \mathrm {U E K}) \right|}{\left| \mathrm {U E K} \right|} \tag {7}
$$

(3) Keypoint Omission Rate (KOR): the proportion of keypoints from UEK that are omitted by content in the report: 

$$
\operatorname {K C R} (R) = \frac {\left| O m i t t e d (R , \mathrm {U E K}) \right|}{\left| \mathrm {U E K} \right|} \tag {8}
$$

Ideally, a high-quality research report should achieve a high KSR (indicating comprehensive factual coverage) and a low KCR and KOR (indicating consistency with evidence). These metrics enable interpretable, referencegrounded evaluation of factual alignment. 

Adaptively-generated Checklist Evaluation. To address the challenges of evaluating open-ended research tasks that lack fixed reference answers, we introduce Adaptivelygenerated Checklist Evaluation (ACE), a two-stage evaluation protocol that leverages the analytical capabilities of large language models (LLMs) while mitigating common sources of bias and inconsistency. 

In the first stage, we use a high-capacity LLM (e.g., GPT-4o) to perform meta-analysis over the task prompt, generating a customized checklist of evaluation criteria tailored to the query. Each checklist item corresponds to a critical evaluation dimension, such as factual correctness, methodological soundness, formatting, or reasoning clarity, and is assigned a normalized weight to reflect its relative importance. This step serves to concretize abstract judgment into discrete, model-understandable subgoals. 

In the second stage, a separate LLM is tasked with scoring the model-generated response against the checklist. For each item, the evaluator model independently assesses whether the response satisfies the criterion and assigns a local score. These individual scores are then aggregated via a weighted average to produce a final task-level rating. By decoupling checklist generation from scoring, ACE reduces evaluation bias, especially those arising from the evaluator’s limited comprehension or heuristic shortcuts. 

ACE addresses key limitations of existing evaluation paradigms. Human evaluation, while often considered the gold standard, suffers from subjectivity, inter-annotator inconsistency, and high cost. LLM-as-a-judge methods, especially when using smaller models, struggle with complex query understanding, detailed analytical reasoning, and accurate interpretation. Furthermore, rubric-based methods ei-

<table><tr><td rowspan="2">Model</td><td colspan="5">KAE</td><td rowspan="2" colspan="2">ACE</td><td rowspan="2" colspan="2">Avg. Token (k)</td><td rowspan="2" colspan="2">Avg. references</td></tr><tr><td colspan="2">KSR</td><td colspan="2">KCR</td><td>KOR</td></tr><tr><td>gpt-4o-search-preview</td><td>50.0</td><td>85.0</td><td>8.9</td><td>5.0</td><td>41.1</td><td>10.0</td><td>2.41</td><td>2.00</td><td>1.21</td><td>2.85</td><td>4.24</td></tr><tr><td>gpt-4o-mini-search-preview</td><td>78.7</td><td>55.6</td><td>8.5</td><td>16.7</td><td>12.8</td><td>27.8</td><td>2.23</td><td>2.05</td><td>1.07</td><td>2.23</td><td>3.83</td></tr><tr><td>gpt-4.1-mini w/search</td><td>62.5</td><td>76.5</td><td>10.9</td><td>5.9</td><td>26.6</td><td>17.6</td><td>2.21</td><td>1.87</td><td>1.10</td><td>2.02</td><td>4.75</td></tr><tr><td>gpt-4.1 w/search</td><td>77.8</td><td>60.6</td><td>2.8</td><td>6.1</td><td>19.4</td><td>33.3</td><td>2.43</td><td>2.22</td><td>1.20</td><td>2.43</td><td>3.51</td></tr><tr><td>o4-mini-deepresearch</td><td>77.2</td><td>75.8</td><td>4.3</td><td>18.2</td><td>18.5</td><td>6.1</td><td>4.03</td><td>3.88</td><td>5.59</td><td>12.5</td><td>29.66</td></tr><tr><td>gemini-2.5-pro w/search</td><td>65.1</td><td>76</td><td>14.3</td><td>12</td><td>20.6</td><td>12</td><td>2.97</td><td>4.03</td><td>4.29</td><td>9.14</td><td>23.86</td></tr><tr><td>gemini-2.5-flash w/search</td><td>78.7</td><td>80</td><td>3.4</td><td>16</td><td>18</td><td>4</td><td>3.81</td><td>3.58</td><td>64.09</td><td>19.78</td><td>29.54</td></tr><tr><td>grok-4 w/search</td><td>83.3</td><td>50</td><td>7.5</td><td>13.8</td><td>9.2</td><td>36.2</td><td>2.97</td><td>2.97</td><td>3.16</td><td>6.60</td><td>20.59</td></tr></table>


Table 3: Evaluation metrics across models. The model release dates are omitted for brevity. Each column reports two values, with the left representing the evaluation results on the English task and the right on the Chinese task.


ther rely on static reference answers, which are unsuitable for open-ended tasks, or require hand-crafted criteria that are difficult to scale and generalize. In contrast, ACE provides a flexible, scalable, and more reliable alternative for nuanced research task evaluation. 

# Experiments

Implementation Details. Our MAHTG system comprises several specialized agents, each responsible for a distinct stage in transforming raw academic seminars into structured research tasks and evaluations. 

Model Selection Rationale. We adopt a heterogeneous model configuration across the MAHTG system, guided by three principles: (1) capability-task alignment, assigning models suited to each agent’s functional role; (2) costeffectiveness and scalability, ensuring efficiency over largescale data; and (3) robustness through model diversity, mitigating systemic bias. Large models like claude-sonnet-4- 20250514 are used for structured reasoning and code-like outputs, while lightweight ones like gpt-4o-mini support tasks requiring relative preference. The Inspira Agent adopts claude-sonnet-4-20250514 for its strong long-context handling and structured generation. The same model powers the TaskWeaver Agent to ensure schema consistency in transforming inspirations into structured tasks. For efficient pairwise evaluation, the RankEval Agent uses gpt-4o-mini, balancing accuracy and cost under the ELO-based framework. To reduce costs, we selected the top 100 highest-scoring samples from the full dataset for evaluation. The choices for LLM align with human-like action and are empirically validated (see appendix). 

We use gemini-2.5-flash as a unified evaluator for both factual and subjective scoring, leveraging its strong instruction-following and long-context reasoning. In KAE, it extracts key factual statements from sources retrieved via the Jina AI API and determines whether each is supported, contradicted, or omitted. In ACE, it generates detailed, task-specific checklists and conducts criterion-based evaluation. This setup ensures consistency across evaluation stages while maintaining precision, scalability, and interpretability. 

Evaluated Models. We evaluate a diverse suite of large language models covering both frontier-level deep research agents and models augmented with real-time retrieval capabilities. Specifically, we include gpt-4o-searchpreview-2025-03-11, gpt-4o-mini-search-preview-2025-03- 11, gpt-4.1-2025-04-14 w/search, gpt-4.1-mini-2025-04- 14 w/search, o4-mini-deepresearch-2025-06-26, gemini-2.5-pro w/search, gemini-2.5-flash w/search, and grok-4- 0709 w/search. When referring to these models in the future, abbreviations will be used, ignoring with search and time versions. 

Overall Performance. The table 3reveals clear differences in both ACE and KCE across models. The best ACE performance is achieved by gpt-o4-mini-deep-research, which combines the highest ACE score of 4.03 with strong KAE metrics, demonstrating accurate, well-structured, and comprehensive outputs. GPT-4.1 excels in factual precision but falls short in subjective quality, with the lowest KCR. It minimizes factual errors, yet its lower ACE scores suggest limited coherence and depth. Gemini-2.5- flash also performs strongly, with relatively high factual coverage and low contradiction and omission, though it uses significantly more tokens than any other model, indicating a trade-off between thoroughness and efficiency. In contrast, gpt-4o-search-previewand gpt-4o-mini-search-preview use far fewer tokens but do not perform so well in both evaluation dimensions, suggesting limited ability to handle complex research tasks. grok-4 demonstrates the strongest factual grounding on English tasks (KSR 83.3), but its performance drops sharply in Chinese, with significantly lower coverage and higher omission. This highlights its limited multilingual generalization despite strong English capabilities. Overall, the results reflect varying model strengths, with some excelling in precision and others in depth or efficiency. 

Performance on Different Tasks. As shown in Figure 3, the ACE-based subjective evaluation reveals substantial differences in how models perform across various research task types. Models like gpt- $o 4$ -mini-deepresearch and gemini-2.5-flash demonstrate consistently strong performance across nearly all tasks, especially excelling in complex and high-level tasks such as hypothesis genera-

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/8ca166ebf992abf9774bdfca2662c03fadb42e9dfb097384418b09025e3967cf.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/563398afc122919c8e6c30e0429aadefd209fa40575a20ec9bfd1965341e49f2.jpg)



(a) Performance by Disciplines


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/71681845a70857e545185c76c4187cf9a8d39260dac419c9408143e976ab416a.jpg)



(b) Performance by Tasks



Figure 3: Comparison of current mainstream models on the DeepResearch Arena benchmark. (a) Performance across 12 research disciplines (e.g., Science & Technology, Art, Finance). (b) Performance across 10 research task types (e.g., Hypothesis Generation, Method Blueprint, Evaluation Metric Design), highlighting task-specific capabilities.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/181b19ee-730d-4ad4-bb7a-81bd7004218a/f66a4017b2098c6e4902eb1ba2287f81344c494c22193f6c362208ea8ef00bca.jpg)



Figure 4: Comparison of DeepResearch agents in terms of Keypoint-Aligned Evaluation (KAE) metrics and efficiency.


tion, evaluation metric design, and methodological planning. Gemini-2.5-pro also shows well-rounded capabilities, performing reliably in tasks that require comparative analysis and methodological reasoning. The gpt-4o family, particularly the mini version, performs poorly across most task types, struggling especially with tasks that require multistep logic and structured outputs. These differences highlight each model’s unique strengths and limitations, underscoring the importance of task-specific evaluation in assessing deep research competence. 

Models also show clear differences in task performance under the KAE as shown in Figure 4. Gemini-2.5-flash and gpt-o4-mini-deepresearch achieve the strongest overall re-

sults, with high keypoint coverage and low conflict and omission rates, leading to the highest efficiency scores. In contrast, gemini-2.5-pro, gpt-4o-search-preview, and gpt-4.1-mini struggle with higher conflict and omission rates, resulting in the lowest efficiency and limited reliability for fact-intensive generation. Overall, the results highlight substantial differences in how models handle task complexity and factual alignment, underscoring the value of KAE for fine-grained evaluation of research capabilities. 

The experiment for effectiveness of our benchmark to prevent data leakage is detailed in the appendix. 

# Conclusion

We present the DeepResearch Arena, a novel benchmark for evaluating the deep research capabilities of large language models in realistic, open-ended settings. Grounded in cognitive theories and authentic seminar discourse, Deep-Research Arena captures the contextual complexity and methodological ambiguity of real-world research. It systematically assesses LLM-based agents across three essential stages, through a curated corpus of multidisciplinary seminars, a hierarchical task generation pipeline, and a hybrid evaluation protocol measuring both factual grounding and higher-order reasoning. By bridging the gap between retrieval-centric agent design and cognitively demanding research tasks, it offers a rigorous, theory-aligned foundation for advancing next-generation research assistants. 

# References



Baek, J.; Jauhar, S. K.; Cucerzan, S.; and Hwang, S. J. 2024. Researchagent: Iterative research idea generation over scientific literature with large language models. arXiv preprint arXiv:2404.07738. 





Carlini, N.; Tramer, F.; Wallace, E.; Jagielski, M.; Herbert-Voss, A.; Lee, K.; Roberts, A.; Brown, T.; Song, D.; Erlingsson, U.; et al. 2021. Extracting training data from large language models. In 30th USENIX security symposium (USENIX Security 21), 2633–2650. 





Castano, J.; Gambarte, M. L.; Park, H. J.; del Pilar ˜ Avila Williams, M.; Perez, D.; Campos, F.; Luna, D.; ´ Ben´ıtez, S.; Berinsky, H.; and Zanetti, S. 2016. A Machine Learning Approach to Clinical Terms Normalization. In Cohen, K. B.; Demner-Fushman, D.; Ananiadou, S.; and Tsujii, J.-i., eds., Proceedings of the 15th Workshop on Biomedical Natural Language Processing, 1–11. Berlin, Germany: Association for Computational Linguistics. 





Clark, P.; Cowhey, I.; Etzioni, O.; Khot, T.; Sabharwal, A.; Schoenick, C.; and Tafjord, O. 2018. Think You Have Solved Question Answering? Try ARC, the AI2 Reasoning Challenge. arXiv preprint arXiv:1803.05457. 





De Boom, C.; Van Canneyt, S.; Bohez, S.; Demeester, T.; and Dhoedt, B. 2015. Learning Semantic Similarity for Very Short Texts. In 2015 IEEE International Conference on Data Mining Workshop (ICDMW), 1229–1234. IEEE. 





Du, M.; Xu, B.; Zhu, C.; Wang, X.; and Mao, Z. 2025. Deep-Research Bench: A Comprehensive Benchmark for Deep Research Agents. arXiv preprint. 





Einstein, A.; and Infeld, L. 1938. The Evolution of Physics. Simon and Schuster. 





Geva, M.; Khashabi, D.; Segal, E.; Khot, T.; Roth, D.; and Berant, J. 2021. Did Aristotle Use a Laptop? A Question Answering Benchmark with Implicit Reasoning Strategies. Transactions of the Association for Computational Linguistics, 9: 346–361. 





Glazer, E.; Erdil, E.; Besiroglu, T.; Chicharro, D.; Chen, E.; Gunning, A.; Olsson, C. F.; Denain, J.-S.; Ho, A.; de Oliveira Santos, E.; Jarviniemi, O.; Barnett, M.; Sandler, ¨ R.; Vrzala, M.; Sevilla, J.; Ren, Q.; Pratt, E.; Levine, L.; Barkley, G.; Stewart, N.; Grechuk, B.; Grechuk, T.; Enugandla, S. V.; and Wildon, M. 2024. FrontierMath: A Benchmark for Evaluating Advanced Mathematical Reasoning in AI. arXiv:2411.04872. 





Glickman, M. E. 1995. A comprehensive guide to chess ratings. American Chess Journal, 3. 





Google. 2025. Deep Research is now available on Gemini 2.5 Pro Experimental. Gemini Blog (online). Gemini Advanced subscribers can use Deep Research powered by Gemini 2.5 Pro Experimental. 





Huang, Y.; Chen, Y.; Zhang, H.; Li, K.; Fang, M.; Yang, L.; Li, X.; Shang, L.; Xu, S.; Hao, J.; Shao, K.; and Wang, J. 2025. Deep Research Agents: A Systematic Examination And Roadmap. arXiv:2506.18096. 





Jindal, S.; and Leema, M. 2024. A Survey of Text Similarity Approaches. Journal of Artificial Intelligence and Capsule Networks, 4(1): 33–45. 





Jonassen, D. H. 1997. Instructional design models for wellstructured and ill-structured problem-solving learning outcomes. Educational Technology Research and Development, 45(1): 65–94. 





Kendall, M. G. 1938. A New Measure of Rank Correlation. Biometrika, 30(1-2): 81–93. 





Laurent, J. M.; Janizek, J. D.; Ruzo, M.; Hinks, M. M.; Hammerling, M. J.; Narayanan, S.; Ponnapati, M.; White, A. D.; and Rodriques, S. G. 2024. LAB-Bench: Measuring Capabilities of Language Models for Biology Research. arXiv:2407.10362. 





Lehman, E.; Jain, S.; Pichotta, K.; Goldberg, Y.; and Wallace, B. C. 2021. Does BERT pretrained on clinical notes reveal sensitive data? arXiv preprint arXiv:2104.07762. 





Li, L.; Xu, W.; Guo, J.; Zhao, R.; Li, X.; Yuan, Y.; Zhang, B.; Jiang, Y.; Xin, Y.; Dang, R.; et al. 2024. Chain of ideas: Revolutionizing research via novel idea development with llm agents. arXiv preprint arXiv:2410.13185. 





Li, W.; Li, D.; Dong, K.; Zhang, C.; Zhang, H.; Liu, W.; Wang, Y.; Tang, R.; and Liu, Y. 2025. Adaptive Tool Use in Large Language Models with Meta-Cognition Trigger. arXiv:2502.12961. 





Liu, Y.; Yang, Z.; Xie, T.; Ni, J.; Gao, B.; Li, Y.; Tang, S.; Ouyang, W.; Cambria, E.; and Zhou, D. 2025. Researchbench: Benchmarking llms in scientific discovery via inspiration-based task decomposition. arXiv preprint arXiv:2503.21248. 





Lu, P.; Mishra, S.; Xia, T.; Qiu, L.; Chang, K.-W.; Zhu, S.- C.; Tafjord, O.; Clark, P.; and Kalyan, A. 2022. Learn to Explain: Multimodal Reasoning via Thought Chains for Science Question Answering. arXiv:2209.09513. 





OpenAI. 2025. Introducing Deep Research. https://cdn.openai.com/API/docs/deep research blog. pdf?utm source=chatgpt.com. Accessed July 30, 2025. 





Ott, S.; Hebenstreit, K.; Lievin, V.; Hother, C. E.; Moradi,´ M.; Mayrhauser, M.; Praas, R.; Winther, O.; and Samwald, M. 2023. ThoughtSource: A central hub for large language model reasoning data. Scientific Data, 10(1). 





Ozt ¨ urk, H.; Ozkirimli, E.; and ¨ Ozg ¨ ur, A. 2016. A compara- ¨ tive study of SMILES-based compound similarity functions for drug-target interaction prediction. BMC bioinformatics, 17(1): 128. 





Pearson, K. 1895. Note on Regression and Inheritance in the Case of Two Parents. Proceedings of the Royal Society of London, 58: 240–242. 





Phan, L.; Gatti, A.; Han, Z.; Li, N.; Hu, J.; Zhang, H.; and et al. 2025. Humanity’s Last Exam. arXiv:2501.14249. 





Qu, C.; Dai, S.; Wei, X.; Cai, H.; Wang, S.; Yin, D.; Xu, J.; and Wen, J.-r. 2025. Tool learning with large language models: a survey. Frontiers of Computer Science, 19(8). 





Rein, D.; Hou, B. L.; Stickland, A. C.; Petty, J.; Pang, R. Y.; Dirani, J.; Michael, J.; and Bowman, S. R. 2024. GPQA: A Graduate-Level Google-Proof Q&A Benchmark. In First Conference on Language Modeling. 





Ruan, J.; Nair, I.; Cao, S.; Liu, A.; Munir, S.; Pollens-Dempsey, M.; Chiang, T.; Kates, L.; David, N.; Chen, S.; 





et al. 2025. ExpertLongBench: Benchmarking Language Models on Expert-Level Long-Form Generation Tasks with Structured Checklists. arXiv preprint arXiv:2506.01241. 





Schmidgall, S.; Su, Y.; Wang, Z.; Sun, X.; Wu, J.; Yu, X.; Liu, J.; Moor, M.; Liu, Z.; and Barsoum, E. 2025. Agent Laboratory: Using LLM Agents as Research Assistants. arXiv:2501.04227. 





Spearman, C. 1904. The proof and measurement of association between two things. The American Journal of Psychology, 15(1): 72–101. 





Tang, Q.; Deng, Z.; Lin, H.; Han, X.; Liang, Q.; Cao, B.; and Sun, L. 2023. ToolAlpaca: Generalized Tool Learning for Language Models with 3000 Simulated Cases. arXiv:2306.05301. 





Trivedi, H.; Balasubramanian, N.; Khot, T.; and Sabharwal, A. 2022. MuSiQue: Multihop Questions via Single-hop Question Composition. arXiv:2108.00573. 





Wang, J.; and Dong, Y. 2020. Measurement of Text Similarity: A Survey. Information, 11(9). 





Wei, J.; Sun, Z.; Papay, S.; McKinney, S.; Han, J.; Fulford, I.; Chung, H. W.; Passos, A. T.; Fedus, W.; and Glaese, A. 2025. Browsecomp: A simple yet challenging benchmark for browsing agents. arXiv preprint arXiv:2504.12516. 





Wu, J.; Zhu, J.; Liu, Y.; Xu, M.; and Jin, Y. 2025. Agentic Reasoning: A Streamlined Framework for Enhancing LLM Reasoning with Agentic Tools. arXiv:2502.04644. 





xAI. 2025. Grok 3. https://x.ai/news/grok-3. Accessed: 2025-07-30. 





Xu, R.; and Peng, J. 2025. A Comprehensive Survey of Deep Research: Systems, Methodologies, and Applications. arXiv:2506.12594. 





Xu, R.; Wang, Z.; Fan, R.-Z.; and Liu, P. 2024. Benchmarking Benchmark Leakage in Large Language Models. arXiv:2404.18824. 





Yang, Z.; Qi, P.; Zhang, S.; Bengio, Y.; Cohen, W. W.; Salakhutdinov, R.; and Manning, C. D. 2018. HotpotQA: A Dataset for Diverse, Explainable Multi-hop Question Answering. In Conference on Empirical Methods in Natural Language Processing (EMNLP). 





Yu, J.; He, R.; and Ying, R. 2023. Thought propagation: An analogical approach to complex reasoning with large language models. arXiv preprint arXiv:2310.03965. 





Yu, J.; Xu, T.; Rong, Y.; Huang, J.; and He, R. 2022. Structure-aware conditional variational auto-encoder for constrained molecule optimization. Pattern Recognition, 126: 108581. 





Zhou, J.; Li, W.; Liao, Y.; Zhang, N.; Qi, T. M. Z.; Wu, Y.; and Yang, T. 2025a. AcademicBrowse: Benchmarking Academic Browse Ability of LLMs. arXiv preprint arXiv:2506.13784. 





Zhou, X.; Weyssow, M.; Widyasari, R.; Zhang, T.; He, J.; Lyu, Y.; Chang, J.; Zhang, B.; Huang, D.; and Lo, D. 2025b. LessLeak-Bench: A First Investigation of Data Leakage in LLMs Across 83 Software Engineering Benchmarks. arXiv:2502.06215. 



# A Data Leakage Detection

To verify that our benchmark minimize the risk of data leakage from the pretraining corpora of LLMs, we conduct a comprehensive leakage simulation experiment (Xu et al. 2024; Zhou et al. 2025b) across all 8 evaluated models. This procedure estimates whether any model can reproduce the withheld portion of a task when prompted with only the first half of the task description. 

# A.1 Experimental Procedure

Given a task instance $T$ , we split it into two parts at a punctuation boundary $i ^ { * }$ closest to the midpoint: 

$$
i ^ {*} = \arg \min  _ {i \in \mathcal {P}} \left| i - \frac {| T |}{2} \right|, \quad \mathcal {P} = \{j \mid T [ j ] \in \text {p u n c t u a t i o n} \} \tag {9}
$$

Let $\mathcal { M } _ { 1 } , \ldots , \mathcal { M } _ { 8 }$ denote the 8 models evaluated in the main paper. Each model $\mathcal { M } _ { k }$ is queried with the prompt $T _ { \mathrm { p r e f i x } }$ , yielding a generated continuation: 

$$
\hat {T} _ {\text {s u f f i x}} ^ {(k)} = \mathcal {M} _ {k} \left(T _ {\text {p r e f i x}}\right) \tag {10}
$$

where $T _ { \mathrm { p r e f i x } } = T [ : i ^ { * } ]$ , $T _ { \mathrm { s u f f i x } } = T [ i ^ { * } : ]$ . This formulation allows us to compare the model-generated continuation $\hat { T } _ { \mathrm { s u f f i } } ^ { ( k ) }$ x with the ground-truth suffix $T _ { \mathrm { s u f f i x } }$ . If the similarity between these two sequences is unexpectedly high, even though the model only received the input prefix, it may suggest that the model has memorized or encountered the full task during pretraining, thereby posing a risk of data leakage. 

# A.2 Similarity Metrics

To assess whether ˆ(k) $\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) }$ potentially replicates the groundtruth suffix $T _ { \mathrm { s u f f i x } }$ , we compute three types of similarity: 

1. String Similarity. We compute string-level similarity between the model-generated suffix and the ground-truth suffix using the normalized Longest Common Subsequence (LCS) metric (Ozt ¨ urk, Ozkirimli, and ¨ Ozg ¨ ur 2016; Wang ¨ and Dong 2020). The similarity score for model $\mathcal { M } _ { k }$ is defined as: 

$$
\operatorname {S i m} _ {\text {s t r i n g}} ^ {(k)} = \frac {2 \cdot | \operatorname {L C S} \left(\hat {T} _ {\text {s u f f i x}} ^ {(k)} , T _ {\text {s u f f i x}}\right) |}{| \hat {T} _ {\text {s u f f i x}} ^ {(k)} | + | T _ {\text {s u f f i x}} |} \tag {11}
$$

Here: 

• $\mathcal { M } _ { k }$ denotes the $k$ -th evaluated model. 

• $T _ { \mathrm { s u f f i x } }$ is the reference suffix (i.e., the ground-truth continuation of a given task). 

• Tˆ(k) $\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) } ~ = ~ \mathcal { M } _ { k } ( T _ { \mathrm { p r e f i x } } )$ is the suffix generated by model $\mathcal { M } _ { k }$ when prompted with the task prefix $T _ { \mathrm { p r e f i x } }$ . 

• $\operatorname { L C S } ( A , B )$ denotes the Longest Common Subsequence between sequences $A$ and $B$ , i.e., the longest sequence of characters that appear left-to-right (but not necessarily contiguously) in both $A$ and $B$ . 

• $| \cdot |$ denotes the number of characters in a sequence. 

This normalized LCS score ranges from 0 to 1, where 1 indicates that the two sequences are identical (character order preserved), and 0 indicates no character-level overlap. The formula symmetrically normalizes the LCS length by the average length of the two sequences, ensuring robustness to differing output lengths. 

2. TF-IDF Cosine Similarity. We compute lexical similarity between the generated suffix and the reference suffix using cosine similarity over their TF-IDF representations (Castano et al. 2016; Wang and Dong 2020). The score ˜ for model $\mathcal { M } _ { k }$ is given by: 

$$
\operatorname {S i m} _ {\mathrm {t f i d f}} ^ {(k)} = \frac {\mathbf {v} ^ {(k)} \cdot \mathbf {v} _ {T}}{\| \mathbf {v} ^ {(k)} \| \cdot \| \mathbf {v} _ {T} \|} \tag {12}
$$

Here: 

• $\mathcal { M } _ { k }$ denotes the $k$ -th evaluated model. 

. ˆ(k) $\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) }$ and $T _ { \mathrm { s u f f i x } }$ are the model-generated and reference suffixes, respectively. 

• $\mathbf { v } ^ { ( k ) } \in \mathbb { R } ^ { d }$ is the TF-IDF vector of $\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) }$ . 

• $\mathbf { v } _ { T } \in \mathbb { R } ^ { d }$ is the TF-IDF vector of $T _ { \mathrm { s u f f i x } }$ 

• $\mathbf { v } ^ { ( k ) } \cdot \mathbf { v } _ { T }$ denotes the dot product between the two vectors. 

• $\| \mathbf { v } \|$ denotes the Euclidean norm (i.e., $\| \mathbf { v } \| = \sqrt { \textstyle \sum _ { i } v _ { i } ^ { 2 } } )$ of vector v. 

TF-IDF vectors are computed over a fixed vocabulary, transforming each suffix into a weighted bag-of-words representation. Cosine similarity then measures the angular similarity between these two vectors, ranging from 0 (completely dissimilar) to 1 (identical in direction). 

3. Word Overlap Ratio. We compute word-level lexical overlap between the generated and reference suffixes using the normalized word set intersection (Jindal and Leema 2024). The score for model $\mathcal { M } _ { k }$ is defined as: 

$$
\operatorname {S i m} _ {\text {o v e r l a p}} ^ {(k)} = \frac {\left| W ^ {(k)} \cap W _ {T} \right|}{\left| W _ {T} \right|} \tag {13}
$$

Here: 

• $\mathcal { M } _ { k }$ denotes the $k$ -th evaluated model. 

$\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) }$ and $T _ { \mathrm { s u f f i x } }$ are the model-generated and reference suffixes, respectively. 

• $W ^ { ( k ) }$ is the set of unique words in $\hat { T } _ { \mathrm { s u f f i x } } ^ { ( k ) }$ , after tokenization and lowercasing. 

• $W _ { T }$ is the set of unique words in $T _ { \mathrm { s u f f i x } }$ , processed identically. 

• $| A |$ denotes the cardinality (i.e., number of elements) of set $A$ . 

This metric captures the proportion of reference words that are correctly recovered in the model output, regardless of order or repetition. A higher score indicates greater lexical fidelity to the reference. 

4. Composite Similarity. To obtain a unified similarity score that balances multiple aspects of textual similarity, we compute a weighted combination of the three individual metrics (De Boom et al. 2015): 

$$
\operatorname {S i m} _ {\text {c o m p o s i t e}} ^ {(k)} = 0. 4 \cdot \operatorname {S i m} _ {\text {s t r i n g}} ^ {(k)} + 0. 4 \cdot \operatorname {S i m} _ {\text {t f i d f}} ^ {(k)} + 0. 2 \cdot \operatorname {S i m} _ {\text {o v e r l a p}} ^ {(k)} \tag {14}
$$

Here: 

• $\mathrm { S i m } _ { \mathrm { s t r i n g } } ^ { ( k ) }$ measures normalized character-level alignment via longest common subsequence. 

• Sim(k)tfidf $\mathrm { S i m } _ { \mathrm { t f i d f } } ^ { ( k ) }$ measures cosine similarity over TF-IDF vector representations. 

• Sim(k) $\mathrm { S i m } _ { \mathrm { o v e r l a p } } ^ { ( k ) }$ measures word-level lexical overlap based on unique token sets. 

The weights (0.4, 0.4, 0.2) were heuristically chosen to prioritize structural and semantic similarity (string and TF-IDF), while still accounting for lexical coverage (overlap). The resulting composite score lies in the range [0, 1], with higher values indicating greater alignment with the reference text. 

# A.3 Leakage Criterion

We consider a task as potentially leaked by model $\mathcal { M } _ { k }$ if the composite score exceeds a threshold: 

$$
\text {i s} _ {\text {l e a k e d}} ^ {(k)} = \mathbb {I} \left[ \operatorname {S i m} _ {\text {c o m p o s i t e}} ^ {(k)} > \tau \right], \quad \text {w i t h} \tau = 0. 7 \tag {15}
$$

We set the threshold $\tau = 0 . 7$ as a conservative criterion to identify potential cases of memorization or contamination. This choice is supported by prior work on training data extraction (Carlini et al. 2021) and sensitive domain leakage (Lehman et al. 2021), which report that similarity scores at or above 0.7 often correspond to memorized or verbatim training content. Such a threshold ensures high precision in detecting potential data leakage while minimizing false positives. 

# A.4 Experimental Setup

We evaluate all 8 models on the same set of 100 benchmark tasks. Each model is accessed via external API. We use a decoding temperature of 0.1, a maximum output length of 500 tokens. 

For each model-task pair, we log: 

• Input prefix $T _ { \mathrm { p r e f i x } }$ 

• Model continuation ˆ(k) $\hat { T } _ { \mathrm { s u f f } } ^ { ( k ) }$ x 

• Reference suffix $T _ { \mathrm { s u f f i x } }$ 

• Three similarity scores and a composite score 

• Binary leakage flag 

The following example illustrates a typical case where the model-generated continuation remains semantically and lexically distinct from the ground truth, thereby avoiding the leakage threshold: 

# Data Leakage Detection Example (Non-Leaked Sample)

# Input Prefix:

Test the effectiveness of transformer architecture visualization tools in helping software architects understand generative AI systems compared to traditional documentation 

# Reference Suffix:

methods. Conduct controlled experiments measuring comprehension and decision-making quality, delivering statistical analysis results and recommendations. 

# Model-Generated Suffix:

To assess the effectiveness of transformer architecture visualization tools in aiding software architects’ understanding of generative AI systems compared to traditional documentation, a comprehensive... 

# Similarity Scores:

• String similarity: $1 5 . 3 \%$ 

• TF-IDF similarity: $9 . 4 \%$ 

• Word overlap: $1 4 . 3 \%$ 

• Composite similarity: $1 2 . 7 \%$ 

Leakage Flag: False 

# A.5 Results and Analysis

Table 4 presents the detection summary for all 8 models. 

Across all evaluated models, none of the 100 sampled tasks triggered the leakage criterion, indicating that no model exceeded the composite similarity threshold of 0.7. The average similarity scores remain consistently low across string-level, semantic, and lexical dimensions. This suggests that the generated continuations are largely dissimilar from the ground-truth suffixes and unlikely to be the result of memorization. These results provide strong evidence that our benchmark is free from pretraining contamination or data leakage. 

# B Alignment Between Automated Evaluation and Human Judgment

# B.1 Motivation

To ensure the reliability of our benchmark evaluations, it is essential to verify that our automated scoring metrics (KAE and ACE) align well with human judgments. This section provides a systematic analysis of their agreement with expert annotations. 

# B.2 Experimental Setup

We randomly sample a representative subset of benchmark tasks and collect human evaluations for model-generated responses. Human annotators are instructed to assess each response according to the same criteria used in our automated evaluation. Each response is rated independently by three annotators, and their scores are averaged. 

<table><tr><td>Model</td><td>Leak</td><td>Avg. Comp.</td><td>Avg. StrSim</td><td>Avg. TFIDF</td><td>Avg. Overlap</td><td>Count</td></tr><tr><td>gpt-4o-search-preview</td><td>0.0%</td><td>9.8%</td><td>10.4%</td><td>7.1%</td><td>14.1%</td><td>0</td></tr><tr><td>gpt-4o-mini-search-preview</td><td>0.0%</td><td>9.4%</td><td>7.7%</td><td>7.2%</td><td>17.2%</td><td>0</td></tr><tr><td>gpt-4.1</td><td>0.0%</td><td>14.8%</td><td>22.4%</td><td>8.3%</td><td>12.4%</td><td>0</td></tr><tr><td>gpt-4.1-mini</td><td>0.0%</td><td>13.6%</td><td>17.9%</td><td>8.9%</td><td>14.4%</td><td>0</td></tr><tr><td>o4-mini</td><td>0.0%</td><td>10.5%</td><td>5.7%</td><td>9.4%</td><td>21.9%</td><td>0</td></tr><tr><td>gemini-2.5-pro</td><td>0.0%</td><td>13.8%</td><td>20.8%</td><td>7.5%</td><td>12.4%</td><td>0</td></tr><tr><td>gemini-2.5-flash</td><td>0.0%</td><td>13.7%</td><td>22.2%</td><td>6.9%</td><td>10.1%</td><td>0</td></tr><tr><td>grok-4</td><td>0.0%</td><td>14.8%</td><td>22.2%</td><td>8.4%</td><td>12.7%</td><td>0</td></tr><tr><td>Average</td><td>0.0%</td><td>12.6%</td><td>16.1%</td><td>8.0%</td><td>14.4%</td><td>0.0</td></tr></table>


Table 4: Average similarity scores across 100 benchmark tasks for each evaluated model. Each row reports how similar the model-generated suffix is to the ground-truth suffix, given the same task prefix. Avg. Comp. denotes the composite similarity score, computed as a weighted average of Avg. StrSim (string similarity), Avg. TFIDF (TF-IDF cosine similarity), and Avg. Overlap (token overlap rate). Leak shows the proportion of tasks whose composite similarity exceeds 0.7, indicating potential data leakage. Count reflects the number of suspected leakage cases (all zero). Averages are computed over 100 tasks per model.


Metric Definitions We compute the following correlation coefficients between the automated scores and the averaged human scores: 

• Spearman’s Rank Correlation $( \rho )$ : Measures the monotonic relationship between two ranked variables (Spearman 1904). It is computed as: 

$$
\rho = 1 - \frac {6 \sum_ {i = 1} ^ {n} d _ {i} ^ {2}}{n \left(n ^ {2} - 1\right)} \tag {16}
$$

where $d _ { i }$ is the difference between the ranks of the $i$ -th observation and $n$ is the total number of samples. 

• Pearson Correlation $( r )$ : Measures the linear correlation between two variables $X$ and $Y$ (Pearson 1895): 

$$
r = \frac {\sum_ {i = 1} ^ {n} \left(X _ {i} - \bar {X}\right) \left(Y _ {i} - \bar {Y}\right)}{\sqrt {\sum_ {i = 1} ^ {n} \left(X _ {i} - \bar {X}\right) ^ {2}} \sqrt {\sum_ {i = 1} ^ {n} \left(Y _ {i} - \bar {Y}\right) ^ {2}}} \tag {17}
$$

where $\bar { X }$ and $\bar { Y }$ denote the means of $X$ and $Y$ , respectively. 

• Kendall’s Tau $( \tau )$ : Measures ordinal association by comparing concordant and discordant pairs (Kendall 1938): 

$$
\tau = \frac {C - D}{\frac {1}{2} n (n - 1)} \tag {18}
$$

where $C$ and $D$ are the number of concordant and discordant pairs among all $n ( n - 1 ) / 2$ possible pairs. 

# B.3 Results and Analysis

<table><tr><td>Metric</td><td>KAE vs. Human</td><td>ACE vs. Human</td></tr><tr><td>Spearman&#x27;s ρ</td><td>0.84</td><td>0.81</td></tr><tr><td>Pearson&#x27;s r</td><td>0.79</td><td>0.76</td></tr><tr><td>Kendall&#x27;s τ</td><td>0.68</td><td>0.65</td></tr></table>


Table 5: Agreement between automated evaluation methods and human judgments on a representative set of benchmark tasks.


As shown in Table 5, both KAE and ACE exhibit strong correlations with human scores, particularly in terms of ranking consistency. This demonstrates that our evaluation protocol provides a faithful and efficient approximation of human preference and judgment. 

# B.4 Qualitative Case Study

To complement the quantitative analysis, we present a representative example illustrating how ACE aligns with human intuition in a realistic task setting. This case is shown in Table 6. 

# B.5 Summary

The observed correlations and case study confirm that KAE and ACE offer scalable, interpretable, and human-aligned metrics for evaluating model performance on research tasks. They allow for reliable comparisons without incurring the cost and variability of manual annotation. 

# C Sample Checklist Generated by ACE

We present a full example of a task-specific checklist automatically generated by a strong LLM (gemini-2.5-flash) as part of the ACE framework. The checklist is conditioned on a challenging task in the Design phase, requiring methodological synthesis and theoretical precision. Each criterion includes a semantic title, a detailed description, and a relative weight, summing to 1.0 across all dimensions. 

Task: Design an experimental protocol to compare the 2-approximation guarantee of greedy maximal independent set algorithms against other linear-time edge-colored clustering methods on hypergraphs. Include benchmark datasets, performance metrics for $O ( \Sigma$ hyperedge sizes) time complexity validation, and statistical significance testing procedures in a detailed methodology document. 

# Model Output:

# Methodology 

Datasets: We will evaluate on a suite of real-world hypergraphs with categorical (edge-colored) interactions that have been used as benchmarks in prior ECC research... 

Human Score: 4.5/10 ACE Score: 4.35 

Comment: Both human and ACE assign similar moderate scores, suggesting the response partially meets the task objective with a coherent but limited methodology description. 

Table 6: Example of strong agreement between ACE and human judgment. 

# Generated Checklist

# Task Query (Design Phase):

Design an experimental protocol to compare the 2-approximation guarantee of greedy maximal independent set algorithms against other linear-time edge-colored clustering methods on hypergraphs. Include benchmark datasets, performance metrics for $O ( \Sigma$ hyperedge sizes) time complexity validation, and statistical significance testing procedures in a detailed methodology document. 

# Checklist Criteria:

1. Methodological Rigor and Experimental Design Quality 

(Weight: 0.45) 

Evaluates the scientific soundness of the experimental protocol including: proper control variables, valid comparison methodology between greedy maximal independent set algorithms and edge-colored clustering methods, appropriate experimental conditions, clear hypothesis formulation, and rigorous approach to validating $O ( \Sigma$ hyperedge sizes) time complexity. Must demonstrate understanding of algorithmic analysis principles and fair comparison frameworks. 

2. Technical Accuracy and Theoretical Grounding 

(Weight: 0.30) 

Assesses correctness of technical concepts including: accurate understanding of 2-approximation guarantees, proper characterization of greedy maximal independent set algorithms on hypergraphs, correct complexity analysis methodology, valid performance metrics for the specified time complexity, and appropriate statistical significance testing procedures. Must demonstrate deep understanding of graph theory, approximation algorithms, and computational complexity. 

3. Completeness and Implementation Feasibility 

(Weight: 0.15) 

Evaluates whether the response addresses all required components: benchmark dataset specifications with hypergraph characteristics, comprehensive performance metrics beyond time complexity, detailed statistical testing procedures, practical implementation considerations, and completeness of the methodology document structure. Must provide actionable protocols that can be realistically executed. 

4. Clarity and Professional Documentation Standards 

(Weight: 0.10) 

Assesses the quality of presentation including: clear structure suitable for a methodology document, precise technical language, logical flow of experimental steps, appropriate level of detail for reproducibility, and professional formatting. Must be comprehensible to researchers in the field while maintaining technical precision. 

# Checklist Metadata:

• Generated by: gemini-2.5-flash 

• Task Type: Method Blueprint 

• Task Category: Science & Technology 

• Task Difficulty: Advanced 

• Video Source: DSI Seminar Series — Algorithms and Applications of Edge-Colored Hypergraph Clustering 

# D Prompt Templates

In this section, we include all the prompt templates employed during the data construction and model evaluation stages. These prompts are carefully crafted to align with the task objectives and ensure standardized interactions across models and tasks, thereby supporting transparency and reproducibility of our benchmark. 

Specifically: 

# • INSPIRATION EXTRACTION PROMPT

Extracts categorized research inspirations (Limitation, Methodology, Transdisciplinarity, Hypothesis) from seminar transcripts, capturing authentic research motivations to seed task generation. 

# • TASK GENERATOR PROMPT

Transforms extracted inspirations into structured Deep-Research tasks that span the full research workflow (Synthesize, Design, Evaluate), grounding the benchmark in real research challenges. 

# • RESEARCH TASK SCORING PROMPT

Enables head-to-head comparison of task quality, where a judge assesses competing task formulations based on clarity, specificity, feasibility, and academic value. 

# • KEY POINT EXTRACTION PROMPT

Extracts key points from the content retrieved via URL associated with a research query. These points serve as targeted evidence crucial for evaluating response faithfulness. 

# • KEY POINT RELEVANCE PROMPT

Evaluates whether a model-generated response appropriately reflects a specific key point, helping assess alignment with source-grounded facts or requirements. 

# • CHECKLIST TEMPLATE PROMPT

Supports the construction of comprehensive, taskspecific evaluation rubrics used to guide human or model-based scoring of open-ended responses. 

# • SINGLE CRITERION SCORING PROMPT

Enables fine-grained assessment of LLM responses along a single evaluation criterion from the checklist, promoting transparency and score traceability. 

# INSPIRATION EXTRACTION PROMPT

# System Role:

You are Inspiration-Extractor, an expert research assistant. 

# Goal:

Read the transcript below and output a list of inspirations — concise research leads with academic value. Each inspiration must satisfy at least two of the following four qualities: 

• Novelty — introduces or implies a new idea, method, or perspective. 

• Explorability — offers a clear starting point for further modeling, experiments, or policy analysis. 

• Challenge — exposes a limitation, bottleneck, or unresolved issue. 

• Verifiability — can ultimately be confirmed or refuted via data, experimentation, or simulation. 

Categorization Schema: Each inspiration must be assigned exactly one of the following types: 

• Limitation — Typical Focus: unresolved issue or missing evidence; Required Traits: Challenge $^ +$ Explorability 

• Methodology — Typical Focus: new technique or framework; Required Traits: Novelty $^ +$ Explorability 

• Transdisciplinary — Typical Focus: cross-domain application; Required Traits: Novelty $^ +$ Explorability 

• Hypothesis — Typical Focus: causal or quantitative statement; Required Traits: Verifiability $^ +$ Explorability 

Output Format: Each line must be a compact JSON object: 

```json
{ "text": "< 4-5 sentences, <= 300 words, faithful to transcript >", "type": "Limitation | Methodology | Transdisciplinary | Hypothesis" } 
```

# Extraction Algorithm:

1. Scan: Detect cue phrases:  
Limitation $\rightarrow$ "unsolved", "bottleneck", "lack of..."  
Methodology $\rightarrow$ "we propose..." "new framework..."  
Transdisciplinary $\rightarrow$ "apply A to B", "bridge..."  
Hypothesis $\rightarrow$ causal verbs (e.g., "leads to"), quantitative predictions 

2. Cluster: Combine adjacent lines on the same idea $\leq 1 0 0$ words). 

3. Qualify: Ensure each candidate satisfies ${ \geq } 2$ of the four qualities. 

4. Limit: Output maximum 10 inspirations. 

5. Faithfulness: No hallucination; paraphrase lightly. 

6. Reasoning: You may reason internally, but output only JSONL. 

# Transcript Format:

```txt
<|begin_of_transcript|> {transcript} <|end_of_transcript|> 
```

# TASK GENERATOR PROMPT

# System Role:

You are DeepResearch-Task-Generator. 

# Goal:

Transform a set of research inspirations into concrete DeepResearch tasks that span the full research workflow. 

# 1. Input:

```typescript
You will receive a JSON array named <<INSPIRATIONS>>>, where each element has the schema:  
{ "text": "< 4-5 sentences, <= 300 words, faithful to transcript>", "type": "Limitation | Methodology | Transdisciplinary | Hypothesis" } 
```

# 2. Output:

Return 5–8 objects in a JSON array. Nothing else. Each object must include exactly these fields: 

# Each object must include exactly the following fields:

• phase (string): One of Synthesize, Design, or Evaluate. 

• task type (string): Choose from the task families listed in Section 3. 

• difficulty (string): Basic or Advanced. 

• task (string): A self-contained description of at most 100 words, including a concrete deliverable. 

# 3. Exhaustive Task-Family Menu:

(You may NOT invent new families.) 

# Phase: Synthesize

• Literature Survey — e.g., map arguments in scholarly debates about Universal Basic Income (2020–2024) 

• Trend / Market Scan — e.g., analyze company reports to identify top 3 priorities in the auto industry 

• Requirements Gathering / Needs Analysis — e.g., survey researchers to uncover unmet needs in DNA software 

# Phase: Design

• Hypothesis Generation — e.g., propose a testable hypothesis on remote work and retention 

• Method / Experiment Blueprint — e.g., design a double-blind protocol for supplement efficacy 

• Prototype / System Specification — e.g., write a functional spec for a library checkout system 

• Evaluation Metric Design — e.g., define a “Fairness-Accuracy Score” for AI algorithm evaluation 

# Phase: Evaluate

• Empirical / Simulation Test — e.g., simulate tax cut impact using economic models 

• Replicability & Bias Review — e.g., audit published experiments for sampling bias 

• Comparative Analysis — e.g., compare feature sets of major cloud storage providers 

# 4. Construction Rules:

1. Cover at least one task from each phase; no family repeated more than twice. 

2. Ground every task in one or more inspirations. Explicitly weave key wording from the inspiration(s) into the task. 

3. Let the type steer emphasis: Limitation find gaps; Methodology design; Transdisciplinary bridge domains; Hypothesis test assertions. 

4. Difficulty: Basic $=$ feasible with public data in $\leq 3 \mathrm { h }$ ; Advanced $=$ needs novel data, tools, or reasoning. 

5. Each task must be self-contained and include a deliverable (e.g., “deliver a taxonomy table”). 

6. Do not reference the full transcript or original inspirations; the task must stand alone. 

# 5. Final Output:

Respond only with the JSON array. No extra commentary. 

# RESEARCH TASK SCORING PROMPT

# System Role:

You are DeepResearch-Task-Judge, a strict reviewer who must decide which of two research tasks is higher quality. 

# Rubric (equal weight for each dimension):

• Clarity – Wording unambiguous; reader needs no transcript lookup. 

• Actionability – Deliverable concrete; scope doable via LLM reasoning or code-writing. 

• Novelty – Offers non-obvious angle; avoids duplication of similar tasks. 

• Depth-Fit – Difficulty tag (Basic — Advanced) matches workload and construction rules. 

• Consistency – Fully follows template $\leq 1 0 0$ words, no meta phrases like “the seminar noted...”, etc.). 

# Scoring Procedure:

1. Compare task A and task B holistically under the rubric. 

2. Assign each dimension an integer score from 1 to 5. 

3. Compute: overall $=$ round((clarity $^ +$ actionability $^ +$ novelty $^ +$ depth fit $^ +$ consistency) / 5, 2). 

4. Select the task with the higher overall score as the winner. 

5. If the scores tie, choose the task that is slightly better and set confidence to 0.55. 

6. Return only valid JSON. No other explanation or preamble. 

# Output Format (One JSON Object):

```json
{
    "winner_id": "A or B",
    "loser_id": "A or B",
    "scores": {
        "winner_overall": x.xx,
        "loser_overall": y.yy
   },
    "winner_reason": "<= 40-word justification>", "confidence": 0-1 float
} 
```

# Assume:

The assistant receives one user message containing: 

```txt
{ "task_A": { ... full task object ... }, "task_B": { ... full task object ... } } 
```

# Begin Judgement.

# KEY POINT EXTRACTION PROMPT

# System Role:

You are an expert assistant performing key point extraction for question answering. 

# Goal:

Given a query and a supporting text passage, identify key points that are crucial to answering the query. These are not generic important sentences, but the specific evidence that directly helps address the query. 

# Instructions:

• Each key point must help respond to the query. 

• Each point should be associated with one or more verbatim spans copied directly from the text. 

• Do not modify or rephrase any span. 

• Keep key point descriptions concise and abstract if needed, but all spans must be exact copies from the source text. 

• No extra commentary, no markdown, no free-text outside of the JSON object. 

# Output Format:

```python
{
    "points": [
        "point_number": point_number,
        "point_content": point_content,
        "spans": [span1, span2, ...]
    ],
    ...
} 
```

# Reminders:

• Key point content can be abstracted or summarized. 

• Every span must be copied exactly as-is from the passage. 

• Multiple spans can be associated with a single key point. 

• Respond strictly with a valid JSON object — no explanations, no markdown, no extra text. 

# Inputs:

• [Query]: {question} 

• [Text]: {text} 

# KEY POINT RELEVANCE PROMPT

# System Role:

You are a professional text relationship analyst. Your job is to evaluate whether a model-generated response appropriately reflects a specific key point in relation to the original research task. 

# Original Task:

{original task} 

# Response Content:

{response content} 

# Key Point to Analyze:

{key point} 

# Analysis Instructions:

• Carefully read the key point, the original task, and the response content. 

• Determine whether the response: 

– SUPPORTS the key point — it affirms, explains, or reinforces the point. 

– OMITS the key point — it does not mention or address the point at all. 

– CONTRADICTS the key point — it says something that disagrees with or negates the point. 

# Output Format (Valid JSON Only):

```jsonl
{ "relationship": "SUPPORTS | OMITS | CONTRADICTS", "confidence": 0.0--1.0, "reasoning": "Detailed explanation of your judgment.", "key"Aspects": ["list", "key", "determining", "factors"] } 
```

# Important Notes:

• relationship must be exactly one of: SUPPORTS, OMITS, CONTRADICTS. 

• confidence is a float between 0.0 and 1.0 indicating confidence in the judgment. 

• reasoning should clearly justify the decision. 

• key aspects should list the main textual or semantic factors that influenced the judgment. 

# Final Instruction:

Please analyze the response according to the above instructions and return only the JSON object, with no extra commentary or formatting. 

# CHECKLIST TEMPLATE PROMPT (Page 1/2)

# System Role:

You are a helpful assistant who creates comprehensive evaluation rubrics for LLM responses to help humans evaluate LLMs efficiently and accurately. 

# Goal:

Given a user query, generate a task-specific evaluation checklist to guide accurate and efficient human assessment of LLM responses. 

# Instruction:

• You will be given a user query. 

• Your task is to analyze the query and produce a comprehensive evaluation rubric covering all key aspects for scoring LLM responses. 

• Each rubric item must be actionable, weighted, and specific to the query’s type and requirements. 

# Query Format:

```txt
<|begin_of_query|>  
{user_query}  
<|end_of_query|> 
```

# Checklist Construction Requirements:

• Be specific to the query (e.g., technical, creative, instructional). 

• Cover multiple aspects: content accuracy, completeness, clarity, formatting, instruction following, etc. 

• Include weights (0.0–1.0) that reflect each criterion’s relative importance. 

• Use 3–6 items per rubric depending on query complexity. 

• Do not use identical weights across tasks. Vary by phase and task type. 

# Phase-Specific Priorities:

# Synthesize Phase

• Literature Survey: Emphasize comprehensiveness and source quality 

• Trend / Market Scan: Emphasize data accuracy and trend insight 

• Requirements Analysis: Emphasize stakeholder coverage and need validation 

# Design Phase

• Hypothesis Generation: Emphasize testability and theoretical grounding 

• Method / Experiment Blueprint: Emphasize methodological rigor and feasibility 

• Prototype / System Specification: Emphasize technical accuracy and completeness 

• Evaluation Metric Design: Emphasize metric validity and applicability 

# Evaluate Phase

• Empirical / Simulation Test: Emphasize statistical rigor and result interpretation 

• Replicability Review: Emphasize methodology clarity and bias detection 

• Comparative Analysis: Emphasize fairness and analytical depth 


CHECKLIST TEMPLATE PROMPT (Page 2/2)



Output Format (Valid JSON Only):


```json
{
    "evaluation criteria": [
        {
            "title": "Most Critical Aspect for This Query Type",
            "weight": 0.4,
            "description": "Detailed description of what to evaluate and criteria"
        },
        {
            "title": "Secondary Important Aspect",
            "weight": 0.3,
            "description": "Detailed description of what to evaluate and criteria"
        },
        {
            "title": "Supporting Aspect",
            "weight": 0.2,
            "description": "Detailed description of what to evaluate and criteria"
        },
        {
            "title": "Additional Quality Check",
            "weight": 0.1,
            "description": "Detailed description of what to evaluate and criteria"
        }
    ]
} 
```

# Final Guidelines:

• Highest-weighted criterion should match the task’s critical requirement. 

• Do not use generic titles or descriptions; each item must match the query type. 

• All weights must sum to approximately 1.0. 

• Output must be valid JSON that is directly parseable. 

# SINGLE CRITERION SCORING PROMPT (Page 1/2)

# System Role:

You are a highly respected academic evaluator known for upholding the most rigorous standards in your field. Institutions seek your expertise when they require a meticulous and uncompromisingly thorough assessment grounded in scholarly precision. 

# Evaluation Criterion:

Single Criterion Evaluation: {checklist item.title} {checklist item.description} 

# Task Context:

• Category: {category} 

• Task Type: {task type} 

• Difficulty: {difficulty} 

# Critical Instruction:

You are evaluating this response solely based on this specific criterion. While the focus is narrow, your expectations for this dimension should remain rigorous and well-calibrated to the task type and category. 

# Research Task:

{task query} 

# Submitted Response:

{response content} 

# Evaluation Approach:

Assess how well the response performs on the criterion ”{checklist item.title}” using the same exacting standards applied to work submitted to top-tier venues. Evaluating a single aspect does not lower the bar — it raises the bar for that one dimension. 

# Uncompromising Quality Benchmarks:

# Exceptional Mastery (8–10):

Handled with extraordinary rigor and insight: 

• Comprehensive, flawless treatment of every nuance in the criterion 

• Demonstrates domain-advancing insight and precision 

• Impressive rigor, originality, and completeness 

# Basic Competence (5–7):

Functional but significantly limited in rigor or completeness: 

• Covers the basics but lacks depth 

• Demonstrates gaps or missed opportunities 

• Requires improvement to meet high standards 

# Inadequate (1–4):

Deep deficiencies that compromise this criterion: 

• Incomplete, flawed, or misguided 

• Demonstrates poor understanding of what the criterion requires 

• Fails to meet professional standards 

# Complete Failure (0):

No meaningful engagement with this specific criterion. 

# SINGLE CRITERION SCORING PROMPT (Page 2/2)

# Rigorous Single-Criterion Analysis:

• Precision of Coverage: Does the response address every essential element of this criterion? 

• Quality of Treatment: Is the handling sophisticated enough to satisfy domain experts? 

• Depth vs. Superficiality: Does it reflect genuine mastery or just surface-level familiarity? 

• Criterion-Specific Rigor: Are claims and evidence within this criterion held to top-tier standards? 

• Professional Adequacy: Would a specialist approve this for publication? 

• Gap Detection: What deficiencies or oversights exist for this criterion? 

# Strict Evaluation Principles:

• No mercy for single dimensions — maximal scrutiny applies 

• High bar $=$ domain expert satisfaction 

• Zero tolerance for mediocrity 

• Actively seek flaws, gaps, and weaknesses 

• Assume inadequacy by default 

# Response Format (Valid JSON Only):

```txt
{ "rating":integer(0-10),"justification":"Explain how this response meets the criterion."   
} 
```

# Final Reminder:

Your evaluation should maintain high standards, even when focusing on a single dimension. High scores should be reserved for responses that demonstrate truly exceptional performance on this specific criterion. ', '{"title": "DeepResearch Arena: The First Exam of LLMs’ Research Abilities via Seminar-Grounded Tasks", "sections": [{"level": 1, "title": "Abstract"}, {"level": 1, "title": "Introduction"}, {"level": 1, "title": "Related Works"}, {"level": 1, "title": "Multi-Agent Hierarchical Task Generation."}, {"level": 1, "title": "Evaluation Methodology"}, {"level": 1, "title": "Experiments"}, {"level": 1, "title": "Conclusion"}, {"level": 1, "title": "References"}, {"level": 1, "title": "A Data Leakage Detection", "children": [{"level": 2, "title": "A.1 Experimental Procedure"}, {"level": 2, "title": "A.2 Similarity Metrics"}, {"level": 2, "title": "A.3 Leakage Criterion"}, {"level": 2, "title": "A.4 Experimental Setup"}, {"level": 2, "title": "A.5 Results and Analysis"}]}, {"level": 1, "title": "Data Leakage Detection Example (Non-Leaked Sample)", "children": [{"level": 2, "title": "Input Prefix:"}, {"level": 2, "title": "Reference Suffix:"}, {"level": 2, "title": "Model-Generated Suffix:"}, {"level": 2, "title": "Similarity Scores:"}]}, {"level": 1, "title": "B Alignment Between Automated Evaluation and Human Judgment", "children": [{"level": 2, "title": "B.1 Motivation"}, {"level": 2, "title": "B.2 Experimental Setup"}, {"level": 2, "title": "B.3 Results and Analysis"}, {"level": 2, "title": "B.4 Qualitative Case Study"}, {"level": 2, "title": "B.5 Summary"}]}, {"level": 1, "title": "C Sample Checklist Generated by ACE", "children": [{"level": 2, "title": "Model Output:"}, {"level": 2, "title": "Methodology"}, {"level": 2, "title": "Generated Checklist"}, {"level": 2, "title": "Task Query (Design Phase):"}, {"level": 2, "title": "Checklist Criteria:"}, {"level": 2, "title": "Checklist Metadata:"}]}, {"level": 1, "title": "D Prompt Templates", "children": [{"level": 2, "title": "• INSPIRATION EXTRACTION PROMPT"}, {"level": 2, "title": "• TASK GENERATOR PROMPT"}, {"level": 2, "title": "• RESEARCH TASK SCORING PROMPT"}, {"level": 2, "title": "• KEY POINT EXTRACTION PROMPT"}, {"level": 2, "title": "• KEY POINT RELEVANCE PROMPT"}, {"level": 2, "title": "• CHECKLIST TEMPLATE PROMPT"}, {"level": 2, "title": "• SINGLE CRITERION SCORING PROMPT"}, {"level": 2, "title": "INSPIRATION EXTRACTION PROMPT", "children": [{"level": 3, "title": "System Role:"}, {"level": 3, "title": "Goal:"}, {"level": 3, "title": "Extraction Algorithm:"}, {"level": 3, "title": "Transcript Format:"}]}, {"level": 2, "title": "TASK GENERATOR PROMPT", "children": [{"level": 3, "title": "System Role:"}, {"level": 3, "title": "Goal:"}, {"level": 3, "title": "1. Input:"}, {"level": 3, "title": "2. Output:"}, {"level": 3, "title": "Each object must include exactly the following fields:"}, {"level": 3, "title": "3. Exhaustive Task-Family Menu:", "children": [{"level": 4, "title": "Phase: Synthesize"}, {"level": 4, "title": "Phase: Design"}, {"level": 4, "title": "Phase: Evaluate"}]}, {"level": 3, "title": "4. Construction Rules:"}, {"level": 3, "title": "5. Final Output:"}]}, {"level": 2, "title": "RESEARCH TASK SCORING PROMPT", "children": [{"level": 3, "title": "System Role:"}, {"level": 3, "title": "Rubric (equal weight for each dimension):"}, {"level": 3, "title": "Scoring Procedure:"}, {"level": 3, "title": "Output Format (One JSON Object):"}, {"level": 3, "title": "Assume:"}, {"level": 3, "title": "Begin Judgement."}]}, {"level": 2, "title": "KEY POINT EXTRACTION PROMPT", "children": [{"level": 3, "title": "System Role:"}, {"level": 3, "title": "Goal:"}, {"level": 3, "title": "Instructions:"}, {"level": 3, "title": "Output Format:"}, {"level": 3, "title": "Reminders:"}, {"level": 3, "title": "Inputs:"}]}, {"level": 2, "title": "KEY POINT RELEVANCE PROMPT", "children": [{"level": 3, "title": "System Role:"}, {"level": 3, "title": "Original Task:"}, {"level": 3, "title": "Response Content:"}, {"level": 3, "title": "Key Point to Analyze:"}, {"level": 3, "title": "Analysis Instructions:"}, {"level": 3, "title": "Output Format (Valid JSON Only):"}, {"level": 3, "title": "Important Notes:"}]}]}]}', '2026-03-15 20:13:32.896576', 'success', NULL);
INSERT INTO "public"."doc_parsed" VALUES (3, 3, '# DEEP RESEARCH AGENTS:

# A SYSTEMATIC EXAMINATION AND ROADMAP

Yuxuan Huang†1, Yihang Chen†2, Haozheng Zhang†2, Kang $\mathrm { L i } ^ { 3 }$ , Huichi Zhou4, Meng Fang1, Linyi Yang4, Xiaoguang $\mathrm { L i } ^ { 2 }$ , Lifeng Shang2, Songcen ${ \bar { \mathrm { X } } } \mathrm { u } ^ { 2 }$ , Jianye $\mathrm { H a o } ^ { 2 }$ , Kun Shao‡2, and Jun Wang‡4 

1 University of Liverpool 2 Huawei Noah’s Ark Lab 3 University of Oxford 4 University College London 

# ABSTRACT

The rapid progress of Large Language Models (LLMs) has given rise to a new category of autonomous AI systems, referred to as Deep Research (DR) agents. These agents are designed to tackle complex, multi-turn informational research tasks by leveraging a combination of dynamic reasoning, adaptive long-horizon planning, multi-hop information retrieval, iterative tool use, and the generation of structured analytical reports. In this paper, we conduct a detailed analysis of the foundational technologies and architectural components that constitute Deep Research agents. We begin by reviewing information acquisition strategies, contrasting API-based retrieval methods with browser-based exploration. We then examine modular tool-use frameworks, including code execution, multimodal input processing, and the integration of Model Context Protocols (MCPs) to support extensibility and ecosystem development. To systematise existing approaches, we propose a taxonomy that differentiates between static and dynamic workflows, and we classify agent architectures based on planning strategies and agent composition, including single-agent and multi-agent configurations. We also provide a critical evaluation of current benchmarks, highlighting key limitations such as restricted access to external knowledge, sequential execution inefficiencies, and misalignment between evaluation metrics and the practical objectives of DR agents. Finally, we outline open challenges and promising directions for future research. A curated and continuously updated repository of DR agent research is available at: https://github.com/ai-agents-2030/awesome-deep-research-agent. 

# 1 Introduction

Recent advances in large language models (LLMs) have led to the rapid emergence of sophisticated AI agents capable of autonomous research. Early models such as GPT-3 [11] primarily addressed isolated tasks, including question answering and machine translation. Subsequently, integration with external tools enabled models such as WebGPT [73] to navigate the web and synthesise information from diverse sources autonomously. Most recently, a new class of advanced autonomous systems, termed Deep Research (DR) agents, has emerged, exemplified by industry-leading solutions such as OpenAI DR [78], Gemini DR [33], Grok DeepSearch [124], and Perplexity DR [81]. These deep research agents significantly extend LLMs by incorporating advanced reasoning, dynamic task planning, and adaptive interaction with web resources and analytical tools. 

Formally, we define “Deep Research Agents” as: 

AI agents powered by LLMs, integrating dynamic reasoning, adaptive planning, and iterative tool use to acquire, aggregate, and analyse external information, culminating in comprehensive outputs for accomplishing open-ended informational research tasks. 

Specifically, DR agents leverage LLMs as their cognitive core, retrieving external knowledge in real-time through web browsers and structured APIs, and dynamically invoking analytical tools via customised toolkits or standardised interfaces such as the Model Context Protocol (MCP). This architecture enables DR agents to autonomously manage complex, end-to-end research workflows by seamlessly integrating reasoning processes with multimodal resources. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/22fdfa4d7c4d8a95af4310628ae301bbd189ce28102aa8efeee8a9bd1ef61410.jpg)



Figure 1: A structural overview of a DR agent in a multi-agent architecture for ease of illustration.


Compared with traditional Retrieval-Augmented Generation (RAG) methods [95], which primarily enhance factual accuracy but lack sustained reasoning capabilities [17], and conventional Tool Use (TU) systems [85] that heavily depend on pre-defined workflows [114], DR agents offer significantly greater autonomy, continual and deep reasoning abilities, dynamic task planning, and adaptive real-time interaction. These advanced capabilities uniquely position DR agents to handle complex, evolving, and knowledge-intensive research scenarios. A representative example of such a DR agent architecture is illustrated in Figure 1, which demonstrates the complete workflow from user input through optional planning and intent clarification, to iterative tool utilization encompassing offline retrieval (vector and relational databases), online retrieval (APIs and browsers), and extended capabilities including data analytics, coding (etc.), and multimodal generation, ultimately producing comprehensive structured report. 

Contribution. This survey systematically reviews recent advancements in DR agents, providing a comprehensive analysis of core technologies, methodologies, optimisation pipelines, and representative implementations. Specifically, the contributions of this survey include: 

• A thorough analysis of representative DR systems, explicitly examining their system architectures, retrieval mechanisms, tool invocation methods, and performance characteristics, alongside optimisation and tuning paradigms. 

• A unified classification framework (Figure 4) that systematically categorises DR systems based on workflow characteristics (static versus dynamic), planning strategies, and agent-based architectures (single-agent versus multi-agent), bridging diverse technical methodologies and current industrial solutions. 

• A systematic review and categorisation of existing benchmarks utilised to evaluate DR systems, highlighting how these benchmarks assess critical capabilities, such as retrieval accuracy, reasoning depth, and adaptive tool invocation proficiency. 

• A systematic analysis of critical open challenges and research directions, focusing on expanding retrieval scope beyond traditional methods, enabling asynchronous parallel execution, developing comprehensive multi-modal benchmarks, and optimising multi-agent architectures for enhanced robustness and efficiency. 

Survey Organization. This survey methodically explores recent advancements in DR agents, organised as follows: Section 2 provides foundational concepts, examining recent progress in reasoning, retrieval-augmented generation, and agent communication protocols. Section 3 comprehensively analyses key DR agent components, including search engine integration (Section 3.1), tool invocation strategies (Section 3.2), architectural workflows (Section 3.3), and optimisation methodologies (Section 3.4). Section 4 reviews major industrial applications and practical implementations of DR agents by leading organisations. Section 5 surveys benchmarks used for evaluating DR systems, categorising them into question-answering and task execution scenarios. Section 6 highlights critical challenges and outlines promising directions for future research, focusing on enhancing information acquisition, asynchronous parallel execution, benchmark alignment, and optimising multi-agent architectures. Finally, Section 7 concludes with a summary and provides insights into the broader implications and opportunities within DR agent research. 

# 2 Background and Preliminaries

# 2.1 Advances in Reasoning and Tool Integration

Recent advancements in large reasoning models (LRMs) have greatly enhanced the ability of language models to tackle complex and abstract tasks. These models have shown significant improvements in tasks such as arithmetic, common-sense reasoning, and symbolic problem-solving, largely due to innovations in model architectures and training techniques. One such advancement is Chain-of-Thought (CoT) prompting, introduced by Wei et al. [116], which explicitly guides models to articulate intermediate logical steps, decomposing complex problems into simpler, sequential stages. This has led to notable improvements in both the interpretability and accuracy of LLMs on various reasoning benchmarks. Building upon CoT, subsequent research has introduced methods to further enhance LLM reasoning, particularly in handling lengthy textual contexts. Approaches such as positional interpolation and sparse attention mechanisms [9, 113] have been proposed to extend the effective context window. Furthermore, specialised benchmarks like LongBench [10] and LongFinanceQA [61] have been developed to rigorously evaluate and improve the performance of these models in extended-context reasoning. 

To address reasoning tasks that require real-time or specialised external knowledge, frameworks like Toolformer [87] and MultiTool-CoT [46] have been proposed, enabling LLMs to autonomously incorporate external computational resources and APIs directly within reasoning workflows. These approaches effectively enhance performance in tasks dependent on precise numerical calculations and dynamic information retrieval. Maintaining reasoning coherence across multiple conversational turns also poses distinct challenges. Techniques such as Dialogue CoT [13] and Structured CoT (SCoT) [99] explicitly integrate dialogue states and conversational contexts within reasoning chains, significantly improving coherence, context-awareness, and the ability to manage iterative interactions and clarify complex user queries. However, despite substantial improvements, existing reasoning frameworks still encounter critical issues, including hallucinations, static or outdated internal knowledge, and insufficient responsiveness to rapidly changing information needs. These limitations highlight the necessity of integrating external information sources, real-time retrieval mechanisms, and adaptive reasoning strategies, which are core motivations driving recent advances toward more comprehensive and robust reasoning frameworks suitable for DR Agent applications. 

# 2.2 Advances in Retrieval-Augmented Generation and Agentic Retrieval

Retrieval-augmented Generation (RAG), leveraging external knowledge bases (e.g., webs, APIs), has emerged as an effective strategy to mitigate hallucination problems and enhance the accuracy of web information search [24, 28, 95]. Early RAG architectures typically involved a static pipeline, where retrievers fetched relevant documents from external sources such as Wikipedia or search engines, and generators (e.g., LLMs) produced answers based solely on these retrieved passages. However, static approaches were limited in handling complex or multi-step queries, motivating recent advances toward iterative and interactive retrieval mechanisms to generate richer and more relevant responses, including FLARE [133], Self-RAG [7], IAG [134], and ToC [54]. In addition, studies [48, 62] expanded retrieval sources from structured databases (e.g., Wikipedia) to large-scale, diverse web corpora such as the Common Crawl dump preprocessed via the CCNet pipeline [27]. Further improvements of RAG include hybrid approaches that combine internal LLM knowledge and external retrievals for better accuracy and coherence [6]. Recently, Huang et al. [44] proposed RAG-RL, introducing reinforcement learning and curriculum learning techniques, enabling reasoning language models (RLMs) to more effectively identify and utilise relevant contexts. 

Despite these advancements in retrieval methods and reasoning-enhanced models, RAG approaches still face limitations in effectively managing complex reasoning workflows and dynamically adapting to varied task requirements. To address these challenges, recent research extends RAG into an agentic paradigm, integrating additional reasoning and decisionmaking layers atop conventional RAG pipelines [95]. Agentic RAG approaches leverage iterative retrieval, adaptive querying, and dynamic workflow adjustments, significantly enhancing multi-step reasoning capabilities. For example, RL-based query refinement techniques (e.g., Hsu et al. [42]) improve retrieval for complex queries, while graph-based retrieval (e.g., GeAR [93]) further enhances the processing of multi-hop queries. Despite these advancements, agentic RAG still faces critical challenges, including balancing computational overhead from dynamic reasoning processes [95], aligning agent behaviours with user intentions [132], and ensuring interpretability in adaptive workflows [42, 95]. Moreover, even advanced agentic RAG approaches remain constrained by their reliance on pre-existing or periodically updated corpora, limiting their ability to handle real-time, rapidly changing, or long-tail information needs effectively. Addressing this challenge requires integrating external APIs and web browsing capabilities into RAG architectures, motivating recent DR methods aimed at further enhancing retrieval comprehensiveness and adaptability. 

# 2.3 Model Context Protocol and Agent-to-Agent Policy

Model Context Protocol (MCP) and Agent-to-Agent (A2A) have been proposed to address interoperability challenges in LLM-based agent systems, enabling efficient tool access and effective multi-agent collaboration. MCP: Traditional Tool Use (TU) agents face significant challenges, including inconsistent APIs, high maintenance costs, and redundant development efforts, severely limiting interoperability across systems [87]. To address these issues, Anthropic introduced the MCP, a unified communication layer allowing LLM-based agents to interact securely and consistently with external services and data sources via standardised interfaces. MCP mitigates data silo problems by providing dynamic service discovery and uniform access patterns. A2A: Google’s A2A protocol facilitates decentralised multi-agent collaboration through structured, task-oriented dialogues. Agents from diverse vendors and model architectures can discover peers, delegate responsibilities, and collaboratively manage complex tasks as equal participants [32]. By abstracting agent discovery into Agent Cards and task coordination into Tasks and Artefacts, A2A supports flexible, incremental, multi-modal workflows, ideally suited to sophisticated collaborative scenarios. 

MCP and A2A complement each other by clearly separating responsibilities: MCP serves as a standardised interface for accessing external tools, while A2A orchestrates collaborative agent interactions. Together, they establish a modular and scalable foundation for open, interoperable agent ecosystems, significantly enhancing the practical capabilities of AI systems in tackling complex real-world challenges. 

# 3 Deep Research: Search Engine, Tool Use, Workflow, Tuning, Non-parametric Continual Learning

Comparison with Conventional RAG-based Approaches. DR agents expand the capabilities of traditional RAG methods by integrating dynamic retrieval, real-time TU, and adaptive reasoning into a unified system. RAG-based approaches typically rely on fixed pipelines, limiting their flexibility in handling complex, multi-step queries or rapidly changing contexts. In contrast, DR agents provide greater autonomy, context-awareness, and accuracy by dynamically engaging with external tools and managing multi-stage research tasks in real time. 

In this section, we explore five core components essential for the development and optimization of DR agents: (3.1) search engine integration, which compares API-based interfaces with browser-based exploration to enhance dynamic knowledge acquisition; (3.2) Tool Use capabilities, which investigate the integration of code execution, mathematical computation, file manipulation, and multimodal processing modules within the agent’s inference pipeline; (3.3) workflow architecture, analysing foundational designs, the balance between multi-agent and single-agent paradigms, memory mechanisms, and auxiliary components that facilitate the orchestration of complex research workflows; (3.4) tuning methodologies, which examine prompt-driven structured generation, LLM-driven prompting, fine-tuning strategies, and reinforcement learning approaches aimed at optimizing agent performance, and (3.5) Non-parametric continual learning, which enables LLM agents to self-evolve by dynamically adapting external tools, memory, and workflows without updating internal model weights, offering scalable optimization for complex tasks. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/c48bdcda9d462d4b1fe70f32e67f192247f8462332af9630176dc5530ae34cf2.jpg)



Figure 2: General Comparison of API-Based and Browser-Based Retrieval Workflow.


# 3.1 Search Engine: API vs. Browser

To enhance reasoning depth and accuracy for handling evolving tasks, DR agents employ search engines (SE) to update their knowledge through interaction with the external environment. In Table 1, we present a comparative overview of SEs, base models, and evaluation benchmarks employed by existing DR agents. The SEs can be broadly categorised into two types: 

1) API-Based SEs, which interact with structured data sources, such as search-engine APIs or scientific database APIs, enabling efficient retrieval of organised information. 

2) Browser-Based SEs, which simulate human-like interactions with web pages, facilitating real-time extraction of dynamic or unstructured content, improving the comprehensiveness of the external knowledge. 


Table 1: Comparison of DR Agents with Search Engine Details



= Primary focus, $| =$ Secondary/minor focus, = Not present


<table><tr><td rowspan="2">DR Agent</td><td colspan="2">Search Engine</td><td colspan="2">Benchmark</td><td rowspan="2">Base Model</td><td rowspan="2">Release</td></tr><tr><td>API</td><td>Browser</td><td>GAIA HLE</td><td>Other QA</td></tr><tr><td>Avatar [123]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Stark</td><td>Claude-3-Opus, GPT-4</td></tr><tr><td>CoSearch-Agent [31]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>□</td><td>GPT-3.5-turbo</td></tr><tr><td>MMAC-Copilot [97]</td><td>■</td><td>□</td><td>■</td><td>□</td><td>□</td><td>GPT-3.5, GPT-4</td></tr><tr><td>Storm [91]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>FreshWiki</td><td>GPT-3.5-turbo</td></tr><tr><td>OpenResearcher [136]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Privately Collected QA Data</td><td>DeepSeek-V2-Chat</td></tr><tr><td>The AI Scientist [63]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>MLE-Bench</td><td>GPT-4o, o1-mini, o1-preview</td></tr><tr><td>Gemini DR [33]</td><td>■</td><td>■</td><td>□</td><td>■</td><td>GPQA</td><td>Gemini-2.0-Flash</td></tr><tr><td>Agent Laboratory [89]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>MLE-Bench</td><td>GPT-4o, o1-preview</td></tr><tr><td>Search-o1 [58]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>GPQA, NQ, TriviaQA</td><td>QwQ-32B-preview</td></tr><tr><td>WebWalker [121]</td><td>□</td><td>□</td><td>□</td><td>□</td><td>WebWalkerQA</td><td>GPT-4o, Qwen-2.5</td></tr><tr><td>Agentic Reasoning [122]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>GPQA</td><td>DeepSeek-R1, Qwen2.5</td></tr><tr><td>AutoAgent [101]</td><td>□</td><td>■</td><td>■</td><td>□</td><td>□</td><td>Claude-Sonnet-3.5</td></tr><tr><td>Grok DeepSearch [124]</td><td>■</td><td>■</td><td>□</td><td>□</td><td>GPQA</td><td>Grok3</td></tr><tr><td>OpenAI DR [78]</td><td>□</td><td>■</td><td>■</td><td>■</td><td>■</td><td>GPT-o3</td></tr><tr><td>Perplexity DR [81]</td><td>■</td><td>■</td><td>□</td><td>■</td><td>SimoleQA</td><td>Flexible</td></tr><tr><td>Towards an AI co-scientist [34]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>GPQA</td><td>Gemini 2.0</td></tr><tr><td>Nouswise [75]</td><td>□</td><td>□</td><td>□</td><td>□</td><td>—</td><td>Mar-2025</td></tr><tr><td>AgentRxiv [88]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>GPQA, MedQA</td><td>GPT-4o-mini</td></tr><tr><td>Agent-R1 [80]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>HotpotQA</td><td>Qwen2.5-1.5B-Inst</td></tr><tr><td>AutoGLM Rumination[137]</td><td>□</td><td>■</td><td>□</td><td>□</td><td>GPQA</td><td>GLM-Z1-Air</td></tr><tr><td>Copilot Researcher [69]</td><td>□</td><td>■</td><td>□</td><td>□</td><td>□</td><td>o3-mini</td></tr><tr><td>H2O.ai DR [39]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>□</td><td>h2ogpt-oasst1-512-12b</td></tr><tr><td>Manus [66]</td><td>■</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Claude3.5, GPT-4o</td></tr><tr><td>Openmanus [60]</td><td>■</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Claude3.5, GPT-4o</td></tr></table>


Continued on next page 



Table 1 continued from previous page


<table><tr><td rowspan="2">DR Agent</td><td colspan="2">Search Engine</td><td colspan="2">Benchmark</td><td rowspan="2">Base Model</td><td rowspan="2">Release</td></tr><tr><td>API</td><td>Browser</td><td>GAIA HLE</td><td>Other QA</td></tr><tr><td>OWL [12]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>Deepeek-R1, Gemini2.5-Pro, GPT-4o</td><td>Mar-2025</td></tr><tr><td>R1-Searcher [96]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Llama3.1-8B-Inst, Qwen2.5-7B</td><td>Mar-2025</td></tr><tr><td>ReSearch [16]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Qwen2.5-7B, Qwen2.5-7B-Inst</td><td>Mar-2025</td></tr><tr><td>Search-R1 [52]</td><td>■</td><td>■</td><td>□</td><td>□</td><td>Llama3.2-3B, Qwen2.5-3B/7B</td><td>Mar-2025</td></tr><tr><td>DeepRescher [135]</td><td>□</td><td>■</td><td>■</td><td>□</td><td>HotpotQA, NQ, TriviaQA</td><td>Apr-2025</td></tr><tr><td>Genspark Super Agent [106]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>Mixture of Agents*</td><td>Apr-2025</td></tr><tr><td>WebThinker [59]</td><td>■</td><td>■</td><td>■</td><td>■</td><td>GPQA, WebWalkerQA</td><td>Apr-2025</td></tr><tr><td>SWIRL [30]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>HotQA, BeerQA</td><td>Apr-2025</td></tr><tr><td>SimpleDeepSearcher [100]</td><td>□</td><td>■</td><td>■</td><td>□</td><td>2WikiMultiHopQA</td><td>Qwen-2.5-7B-In, Qwen-2.5-32B-In, DeepSeek-Distilled-Qwen-2.5-32B, QwQ-32B</td></tr><tr><td>Suna AI [4]</td><td>■</td><td>■</td><td>□</td><td>□</td><td>GPT-4o, Claude</td><td>Apr-2025</td></tr><tr><td>Tool-Star [22]</td><td>■</td><td>■</td><td>■</td><td>■</td><td>WebWalker, HotpotQA, 2WikiMultiHopQA</td><td>May-2025</td></tr><tr><td>WebDancer [120]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>WebWalkerQA</td><td>May-2025</td></tr><tr><td>AgenticSeek [67]</td><td>□</td><td>■</td><td>□</td><td>□</td><td>GPT-4o, DeepSeek-R1, Claude</td><td>May-2025</td></tr><tr><td>Alita [84]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>PathVQA</td><td>May-2025</td></tr><tr><td>DeerFlow [20]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>Doubao-1.5-Pro-32k, DeepSeek-R1, GPT-4o, Qwen</td><td>May-2025</td></tr><tr><td>PANGU DEEP-DIVER [94]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>C-SimpleQA, HotpotQA, ProxyQA</td><td>May-2025</td></tr><tr><td>O-agents [140]</td><td>■</td><td>□</td><td>■</td><td>□</td><td>GPT-4o, GPT-4.1, Claude-3.7-Sonnet, DeepSeek-R1, Gemini-2.5</td><td>Jun-2025</td></tr><tr><td>Kimi-Researcher [70]</td><td>■</td><td>■</td><td>□</td><td>■</td><td>SimpleQA</td><td>Jun-2025</td></tr><tr><td>WebSailor [57]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>SimpleQA</td><td>Jul-2025</td></tr><tr><td>Agent-KB [103]</td><td>■</td><td>□</td><td>■</td><td>□</td><td>SWE-bench</td><td>Jul-2025</td></tr></table>


Continued on next page 



Table 1 continued from previous page


<table><tr><td rowspan="2">DR Agent</td><td colspan="2">Search Engine</td><td colspan="2">Benchmark</td><td rowspan="2">Base Model</td><td rowspan="2">Release</td><td></td></tr><tr><td>API</td><td>Browser</td><td>GAIA HLE</td><td>Other QA</td><td></td></tr><tr><td>WebShaper [104]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>WebWalkerQA</td><td>Qwen-2.5, QwQ-32B</td><td>Jul-2025</td></tr><tr><td>Deep Researcher with Test-Time Diffusion [40]</td><td>■</td><td>□</td><td>■</td><td>■</td><td>□</td><td>Gemini-2.5-Pro</td><td>Jul-2025</td></tr><tr><td>ChatGPT-Agent [77]</td><td>□</td><td>□</td><td>□</td><td>□</td><td>□</td><td>—</td><td>Jul-2025</td></tr><tr><td>AWorld [8]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>HotpotQA</td><td>Gemini-2.5-Pro, GPT-4o</td><td>Jul-2025</td></tr><tr><td>Cognitive Kernel-Pro [109]</td><td>■</td><td>□</td><td>■</td><td>□</td><td>AgentWebQA, WebWalkerQA, Multi-hop URLQA, DocBench, TableBench</td><td>Claude-3.7-Sonnet, CK-Pro-8B</td><td>Aug-2025</td></tr><tr><td>WebWatcher [29]</td><td>■</td><td>■</td><td>□</td><td>■</td><td>Browsercom-VL, LiveVQA, MMSearch</td><td>Qwen-2.5-VL-32B</td><td>Aug-2025</td></tr><tr><td>WideSearch [119]</td><td>■</td><td>□</td><td>□</td><td>□</td><td>WideSearch</td><td>DeepSeek-R1, Doubao-Seed-1.6, Claude Sonnet 4, Gemini-2.5-Pro</td><td>Aug-2025</td></tr><tr><td>MiroRL [107]</td><td>■</td><td>■</td><td>■</td><td>□</td><td>□</td><td>Qwen3-14B</td><td>Aug-2025</td></tr></table>

API-based retrieval is a fast, efficient, and scalable way for deep-research (DR) agents to access external knowledge with relatively low latency and computational overhead. For example, Gemini DR [33] coordinates multiple interfaces, most notably the Google Search and arXiv APIs, to conduct large-scale retrieval over hundreds to thousands of web pages, substantially broadening coverage. Grok DeepSearch [124] maintains a continuously updated index via news-outlet feeds, the Wikipedia API, and X’s native interface, and, on demand, dispatches a query-driven agent to decompose questions into targeted subqueries and fetch relevant pages in real time. (author?) [81] first crawls hundreds of sources and then aggregates them to produce a final report. Cognitive Kernel-Pro [109] leverages the free DuckDuckGo search interface to enable a fully open-source, low-cost DR pipeline. Agentic Reasoning, ReSearch, R1-Search and SWIRL [122, 16, 96, 30] explicitly teach models when to search, what to search for, and how to incorporate retrieved evidence into the reasoning process. PANGU DeepDiver [94] uses reinforcement learning to adapt search intensity to task difficulty. Agent Laboratory [89] calls the arXiv API to extract paper metadata and abstracts for automated literature reviews, while AI Scientist [63] queries the Semantic Scholar API to validate novelty and citation relations among model-generated ideas. CoSearch-Agent [31] integrates SerpApi to deliver Slack-based, real-time search. DeepRetrieval [49] operates within a reinforcement-learning framework to optimise queries against the PubMed and ClinicalTrials.gov APIs for high-recall biomedical retrieval, and Search-o1 [58] combines the Bing Search API with the Jina Reader API to dynamically extract and refine passages for downstream reasoning. While these API-driven approaches excel at structured, high-throughput acquisition, they can struggle with deeply nested, client-side JavaScript–rendered content, interactive components, or authentication barriers, motivating complementary browser-based mechanisms capable of comprehensively extracting and analysing dynamic or unstructured information. 

Browser-based retrieval provides DR agents with dynamic, flexible, and interactive access to multimodal and unstructured web content through simulated human-like browser interactions. For example, Manus AI’s browsing agent operates a sandboxed Chromium instance for each research session, programmatically opening new tabs, issuing search queries, clicking through result links, scrolling pages until content thresholds are met, filling out form elements when necessary, executing in-page JavaScript to reveal lazily loaded sections, and downloading files or PDFs for local analysis [66]. Although OpenAI DR, Grok DeepSearch, and Gemini 2.5 DR do not publicly disclose the implementation details of their browsing capabilities, their ability to handle interactive widgets, dynamically rendered content, and multi-step navigation strongly suggests that they too employ comparable headless-browser frameworks behind the scenes. Among open-source studies, AutoAgent [131] operates within a BrowserGym environment to scroll, interact with page components, and download files when APIs are unavailable; DeepResearcher [135] employs a dedicated Web Browsing Agent that, upon receiving a browse request, processes each segment of a webpage in turn, decides whether to continue to subsequent segments based on relevance, and incrementally aggregates pertinent information into a short-term memory buffer before returning it for reasoning. Kimi-Researcher [70] uses an internal search engine 

with a text-based browser to retrieve information. Search-R1 and MiroRL [52, 107] employ both search and browser tools during training. AutoGLM [137] operationalises browsing through a plan–execute loop that opens and reads web pages, layering “rumination” cycles over browser actions to refine evidence and produce long-form reports. Genspark Super Agent [106] orchestrates a mixture-of-agents in which a research sub-agent performs web search and page reading, handing structured notes to downstream writing/analysis agents rather than relying on a single monolithic browser. SimpleDeepSearcher [100] follows a lightweight search-fetch-summarise loop using web search APIs plus HTTP fetching in lieu of full browser automation, caching pages and compressing them before further reasoning. Tool-Star [22] explicitly separates a Search Engine tool from a Web Browser Agent: after link retrieval, the browser agent opens pages, extracts salient snippets, and returns compressed evidence to the planner. AgenticSeek [67] couples a local metasearch front end with a headless, stealth browser so the agent can click, scroll, and submit forms on live sites, exposing knobs for budget and anti-bot robustness. AWorld [8] provides a multi-agent runtime with built-in browser automation and tracing, enabling teams of agents to divide research, browsing, and synthesis for deep-research workflows over dynamic sites. WebThinker [59] performs information seeking by issuing searches and following links on returned result pages. WebDancer, WebSailor, and WebShaper [120, 57, 104] combine web search with on-page navigation as a minimal sufficient toolset, linking structured tool invocations with observations in a ReAct-style closed loop: they first locate candidate sources horizontally, then drill down vertically, trading a compact action space for training stability and stronger generalisation. WebWatcher [29] uses the Google SerpApi for multimodal search and applies OCR-based image processing to emulate browser interactions. While browser-based retrieval excels at capturing real-time and deeply nested content that API calls cannot reach, it also incurs greater latency, resource consumption, and complexity in handling page variability and errors, suggesting that DR agents may benefit from hybrid architectures that combine the efficiency of API-based methods with the comprehensiveness of browser-driven exploration. 

# 3.2 Tool Use: Empowering Agents with Extended Functionalities


Table 2: Comparison of DR Agents with Tool Use Capabilities


<table><tr><td>DR Agent</td><td>Code Interpreter</td><td>Data Analytics</td><td>Multimodal</td><td>Release</td></tr><tr><td>CoSearchAgent [31]</td><td>□</td><td>■</td><td>□</td><td>Feb-2024</td></tr><tr><td>Storm [91]</td><td>■</td><td>□</td><td>□</td><td>Jul-2024</td></tr><tr><td>The AI Scientist [63]</td><td>■</td><td>□</td><td>□</td><td>Aug-2024</td></tr><tr><td>Agent Laboratory [89]</td><td>■</td><td>□</td><td>□</td><td>Jan-2025</td></tr><tr><td>Agentic Reasoning [122]</td><td>■</td><td>□</td><td>□</td><td>Feb-2025</td></tr><tr><td>AutoAgent [101]</td><td>■</td><td>□</td><td>■</td><td>Feb-2025</td></tr><tr><td>Genspark DR [106]</td><td>■</td><td>■</td><td>■</td><td>Feb-2025</td></tr><tr><td>Grok DeepSearch [124]</td><td>■</td><td>■</td><td>■</td><td>Feb-2025</td></tr><tr><td>OpenAI DR [78]</td><td>■</td><td>■</td><td>■</td><td>Feb-2025</td></tr><tr><td>Perplexity DR [81]</td><td>■</td><td>■</td><td>■</td><td>Feb-2025</td></tr><tr><td>Towards an AI co-scientist [34]</td><td>□</td><td>■</td><td>■</td><td>Feb-2025</td></tr><tr><td>Agent-R1 [80]</td><td>■</td><td>□</td><td>□</td><td>Mar-2025</td></tr><tr><td>AutoGLM Romination [137]</td><td>■</td><td>□</td><td>■</td><td>Mar-2025</td></tr><tr><td>Copilot Researcher [69]</td><td>■</td><td>■</td><td>■</td><td>Mar-2025</td></tr><tr><td>Manus [66]</td><td>■</td><td>■</td><td>■</td><td>Mar-2025</td></tr><tr><td>OpenManus [60]</td><td>■</td><td>■</td><td>□</td><td>Mar-2025</td></tr><tr><td>OWL [12]</td><td>■</td><td>■</td><td>■</td><td>Mar-2025</td></tr><tr><td>H2O.ai DR [39]</td><td>■</td><td>■</td><td>■</td><td>Mar-2025</td></tr><tr><td>Genspark Super Agent [106]</td><td>■</td><td>■</td><td>■</td><td>Apr-2025</td></tr><tr><td>WebThinker [59]</td><td>■</td><td>■</td><td>□</td><td>Apr-2025</td></tr><tr><td>Suna Ai [4]</td><td>■</td><td>■</td><td>□</td><td>Apr-2025</td></tr><tr><td>Tool-Star [22]</td><td>■</td><td>■</td><td>□</td><td>May-2025</td></tr><tr><td>AgenticSeek [67]</td><td>■</td><td>■</td><td>□</td><td>May-2025</td></tr><tr><td>Alita [84]</td><td>■</td><td>■</td><td>■</td><td>May-2025</td></tr><tr><td>DeerFlow [20]</td><td>■</td><td>■</td><td>□</td><td>May-2025</td></tr><tr><td>O-agents [140]</td><td>■</td><td>■</td><td>■</td><td>Jun-2025</td></tr><tr><td>Kimi-Researcher [70]</td><td>■</td><td>■</td><td>□</td><td>Jun-2025</td></tr><tr><td>Agent-KB [103]</td><td>■</td><td>■</td><td>■</td><td>Jul-2025</td></tr><tr><td>AWorld [8]</td><td>■</td><td>■</td><td>■</td><td>Jul-2025</td></tr><tr><td>Cognitive Kernel-Pro [109]</td><td>■</td><td>■</td><td>■</td><td>Aug-2025</td></tr><tr><td>WebWatcher [29]</td><td>■</td><td>■</td><td>■</td><td>Aug-2025</td></tr><tr><td>MiroRL [107]</td><td>■</td><td>■</td><td>□</td><td>Aug-2025</td></tr></table>

To expand DR agents’ capacity to interact with external environments in complex research tasks, specifically by actively invoking and handling diverse tools and data sources, various DR agents have introduced three core tool modules: code interpreters, data analytics, multimodal processing, along with the Model Context Protocol. 

Code Interpreter. The code interpreter capability enables DR agents to execute scripts during inference, allowing them to perform data processing, algorithm verification and model simulation. Most DR agents, except CoSearchAgent, embed a script execution environment. They typically rely on Python utilities such as Aider and Java utilities to orchestrate dynamic scripting, conduct literature-driven analysis and carry out real-time computational reasoning. 

Data Analytics. By integrating data analytics modules, DR agents transform raw retrievals into structured insights by computing summary statistics, generating interactive visualisations and conducting quantitative model evaluations, thereby accelerating hypothesis testing and decision-making. Many commercial DR agents have implemented analytics features such as charting, table generation and statistical analysis, either locally or via remote services. However, most of these systems have not publicly disclosed technical details of their implementations. In contrast, academic studies often provide concrete examples: CoSearchAgent [31] integrates SQL-based queries within team communication platforms to run aggregate analyses and produce reports; AutoGLM [137] extracts and analyses structured datasets directly from table-based web interfaces. 

Multimodal Processing and Generation. Multimodal processing and generation tools enable DR agents to integrate, analyse and generate heterogeneous data such as text, images, audio and video within a unified reasoning pipeline, thereby enriching their contextual understanding and broadening the range of their outputs. Only a subset of mature commercial and open-source projects, for example Manus [66], OWL [12], AutoAgent [101], AutoGLM [137], OpenAI [78], Gemini [33], Perplexity [81] and Grok DeepSearch [124], support this capability, whereas most academic prototypes have not implemented it, often due to the high computational cost. As the typical open source studies, OWL and Openmanus extend their pipelines to include interactions with platforms such as GitHub, Notion and Google Maps and to leverage numerical libraries such as Sympy and Excel for combined data analysis and multimodal media processing [12, 60]. 

Deep Research Agent with Computer Use. Most recently, the boundaries of DR agents have been progressively expanded through integrating computer-assisted task execution capabilities (i.e., computer use). For example, Zhipu AI introduced AutoGLM Rumination [137], an RL-based system incorporating self-reflection and iterative refinement mechanisms, which significantly enhances multi-step reasoning and advanced function-calling abilities. Specifically, AutoGLM Rumination [137] autonomously interacts with web environments, executes code, invokes external APIs, and effectively accomplishes sophisticated tasks, including data retrieval, analysis, and structured generation of comprehensive reports. Comparison with OpenAI’s DR: While OpenAI DR primarily focus on intricate reasoning and information retrieval, AutoGLM Rumination exhibits superior autonomy in practical execution. This enhanced autonomy allows it to transform abstract analytical insights into concrete operational tasks, such as automated interactions with web interfaces and real-time data processing. Moreover, AutoGLM Rumination addresses and resolves limitations inherent in simulated browsing environments by seamlessly integrating advanced reasoning capabilities with authentic browser-based interactions. Therefore, the agent gains reliable access to user-authenticated resources, including platforms such as CNKI, Xiaohongshu, and WeChat official accounts. Such integration significantly elevates the agent’s autonomy and adaptability in both information acquisition and execution of real-world tasks. 

OpenAI DR, Perplexity DR, Grok DR, H2O, Manus, Genspark Super Agent (author?) [78, 81, 124, 39, 66, 106] orchestrate multi-step web research with browser or tool use, code execution, and analytics to produce cited, structured reports at industrial scale. OWL, OpenManus, Suna, DeerFlow, WebThinker, AgenticSeek, and AWorld [12, 60, 4, 20, 59, 67, 8] provide open-source stacks that integrate browser automation, code interpreters, and (often) MCPstyle tooling for end-to-end deep research workflows. AutoGLM Rumination, Tool-Star, Kimi-Researcher, and MiroRL [137, 22, 70, 107] use reinforcement learning or self-reflection to plan searches, invoke tools and code, and improve multi-step reasoning autonomy. The AI Scientist, Storm, Agent Laboratory, Agent-R1, AutoAgent, and CoSearchAgent [63, 91, 89, 80, 101, 31] automate literature review, code/experiment execution, and structured drafting through tool-augmented research pipelines. Towards an AI co-scientist and O-agents [34, 140] outline blueprints and empirical recipes for building, training, and evaluating effective tool-using research agents. Agent-KB [103] introduces a KB-driven framework for cross-domain experience transfer to boost generalisation on complex tasks. Microsoft Copilot Researcher [69] embeds multi-step research and analytics in the Microsoft 365 ecosystem, producing reports and charts within enterprise workflows. Alita [84] explores self-evolving agents that generate and wrap MCP tools, alongside code execution, to extend capabilities with minimal predefined schemas. 

# 3.3 Architecture and Workflow

As shown in Figure 4, this section systematically analyses the construction of DR systems, focusing on workflows categorised into static and dynamic types. We first introduce the static workflows and then discuss planning strategies, which enhance task allocation and execution through three distinctive user interaction types to clarify intent: planning-only (direct planning without clarifying user intent), intent-to-planning (clarifying intent before planning to align the task with user goals), and unified intent-planning (generating a plan and requesting user confirmation). The distinction between single-agent and multi-agent systems is examined in the context of dynamic workflows, emphasising specialisation in task management. Additionally, we examine memory mechanisms for managing and integrating retrieved information, which enhance the performance and adaptability of DR systems. 

During the Paris 2024 Olympics, I want to watch the men’s 100 m final, and then catch Les Misérables in London’s West End that same evening.  What is the latest Eurostar I can take without being late? 

<search> men’s 100 m final Paris 2024 date and time </search> <result> The men’s 100 m final is scheduled for 4 Aug 2024 at 21:50 </result> <answer> It’s on 4 Aug 2024 at 21:50 (Paris time). Search 

Search 

<query> 100 m final Paris 2024 & Eurostar last train Paris to London 4 Aug 2024</query> <result> …final at 21:50… last Eurostar 21:13 … arrives 22:30 … </result> <answer> The 21:13 Eurostar is the last one you can take. 

RAG 

<think> To solve this, I need three steps: 

(1) Confirm the 100 m final end time. 

(2) Estimate travel from Stade de France Gare du Nord (≈45 min). 

(3) Check Paris–London Eurostar slots + 30 min theatre buffer. </think> 

<search> 100 m final Paris 2024 exact timetable </search> 

<answer> The final is expected to finish between 21:50–22:00 (Paris time). </answer> 

<search> Les Misérables in London’s West End on 4 Aug 2024 exact timetable </search> <answer> The performance is expected to be at 19:30 (London time). </answer> 

<think> 22:00 + 45 min = 22:45 arrival at Gare du Nord. 

Check-in closes ~45 min before departure $\Rightarrow$ need to be there by ~22:00—[ Impossible Tonight.] 

[Change to New plan] : see if the first Eurostar next morning still gets to a 19:30 show.</think> 

<query> first Eurostar Paris to London 5 Aug 2024 timetable </query> 

<result> First train 07:13 → 08:30 (London time) … </result> 

<answer> 07:13 from Paris-Nord, arriving 08:30 at St Pancras (London time). 

DR: Search and Query with Reasoning 

Figure 3: Comparison of Information Retrieval Methods. The upper left corner (Search) represents the searching methods, which can use the browser or API; the lower left corner (RAG, Query) represents Retrieval-Augmented Generation, combining retrieval and generative models to output natural language answers; the right side (Deep Research) represents the deep research process, generating complex decisions or analyses through retrieval and explicit reasoning. 

# 3.3.1 Static vs. Dynamic Workflows

Static Workflows. Static workflows rely on manually predefined task pipelines, decomposing research processes into sequential subtasks executed by dedicated agents. These workflows follow explicitly structured procedures, making them particularly suitable for well-defined, structured research scenarios. For instance, AI Scientist [63] automates scientific discovery through distinct sequential phases, including ideation, experimentation, and reporting. Similarly, Agent Laboratory [89] segments research activities into formalised stages, such as literature review, experimentation, and synthesis of findings. Extending this static paradigm further, AgentRxiv [88] incorporates inter-agent collaboration mechanisms, enabling incremental knowledge reuse through sharing intermediate research outcomes among specialised agents. 

Whist their ease of implementation and structured clarity, static workflows suffer from limited generalisation capabilities, as each distinct task necessitates a specifically tailored pipeline. 

Dynamic Workflows. To overcome the limitations in flexibility and generalizability inherent in static workflows, dynamic workflows support adaptive task planning, allowing agents to dynamically reconfigure task structures based on iterative feedback and evolving contexts. Dynamic architectures leverage advanced mechanisms including automated planning, iterative refinement, and interactive task allocation, enabling tasks to evolve in real-time as new knowledge or external inputs become available. Consequently, dynamic workflows exhibit superior generality and adaptability, making them highly suitable for complex, knowledge-intensive tasks commonly encountered in AI-driven research scenarios. 

# 3.3.2 Dynamic Workflows: Planning Strategies

To enhance DR agents’ adaptability in response to evolving user requirements and contexts, existing studies propose three distinctive LLM-based planning strategies, each differing in whether and how they interact with the user to clarify intent: 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/c72c2040fa30bca103fb9d941ac24e3924309d15e42d4354374710a9fe7e91b1.jpg)



Static Workflow § 3.3.1


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/26cc0797006de4a760ea80483ee35654fc746993b44b19c6f9999ed80281729d.jpg)



(a) Static Workflow: Manually predefined pipeline; fixed agent roles; simple yet limited adaptability, requiring tailored designs for each distinct task.



Dynamic Workflow


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/9b522f4cfb3927402780daef17448b3557384f7d059d79a90b7ea2ee17dfb7e4.jpg)



Each Icon Represents a Tool



(b)Dynamic-Single-Agent Workflow S 3.3.3:



A powerful LRM iteratively generates and updates plans, dynamically invokes tools (e.g., search,coding),and produces reports.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/a9566dda362a497088400471c7002c67e1c4ce09da1b939ba04f1c2572a38bc4.jpg)



(c)Dynamic-Multi-Agent Workflow $\$ 3.3.3$ ：



LLMs generate plans, assign tasks to agents, refine plans fromreal-time response,iteratively reassign tasks until produce final reports.



Figure 4: Comparison of DR Workflows: (1) Static vs. Dynamic Workflows: Static workflows rely on predefined task sequences, while dynamic workflows allow LLM-based task planning. (2) Planning Strategies: Three types include: planning-only (direct planning without clarifying user intent), intent-to-planning (clarifying intent before planning), and unified intent-planning (generating a plan and requesting user confirmation). (3) Single-Agent vs. Multi-Agent: Dynamic workflows can be categorised into dynamic-multi-agent systems (tasks distributed across specialised agents) or dynamic-single-agent systems (an LRM autonomously updates and executes tasks). For a continuously updated, per-work taxonomy of DR workflows, see https://github.com/ai-agents-2030/awesome-deep-researchagent.


1) The Planning-Only approach directly generates task plans based solely on initial user prompts without actively engaging in further clarification, adopted by the majority of existing DR agents, including Grok [124], H2O [39] and Manus [66]. 

2) The Intent-to-Planning strategy actively clarifies user intent prior to planning through targeted questions, subsequently generating tailored task sequences based on clarified user inputs; this method is utilised by OpenAI DR [78]. 

3) The Unified Intent-Planning approach synthesises these methods by generating a preliminary plan from the initial prompt, together with interactively engaging the user to confirm or revise the proposed plan. Gemini DR [33] is representative of this strategy, effectively adopts the strength of user-guided refinement. 

# 3.3.3 Dynamic Workflows: Single-Agent vs. Multi-Agent

Dynamic workflows of DR agents can be differentiated based on agent architectures into single-agent and multi-agent frameworks, each exhibiting distinct characteristics concerning task specialisation, coordination complexity, and scalability of execution. 

Dynamic Single-Agent Systems. Dynamic single-agent systems integrate planning, tool invocation, and execution within a unified LRM, streamlining task management into a cohesive cognitive loop. Single-agent architectures autonomously refine task plans and invoke appropriate tools based on evolving contexts, typically without explicit inter-agent coordination. Compared to multi-agent architectures, single-agent systems enable direct end-to-end reinforcement learning (RL) optimisation across the entire workflow, facilitating smoother and more coherent integration of reasoning, planning, and tool invocation. Systems such as Search-o1 [58], R1-Searcher [96], DeepResearcher [135], WebDancer [120], WebSailor [57], PANGU Deepdiver [94], Agent-R1 [80], ReSearch [16], Search-R1 [52], Web-Watcher [121], MiroRL [107], Memento [138] and Kimi-Researcher [70] exemplify this paradigm through iterative cycles of explicit reasoning, action, and reflection, aligning with the ReAct framework [127]. However, this streamlined approach places significant demands on the foundation model’s reasoning capabilities, contextual understanding, and autonomous selection and invocation of tools. Additionally, the tightly integrated nature of single-agent systems may limit modular flexibility, complicating independent scaling or optimisation of individual functional components. 

Dynamic Multi-Agent Systems. Dynamic multi-agent systems leverage multiple specialised agents to collaboratively execute subtasks generated and dynamically allocated through adaptive planning strategies. These systems typically employ hierarchical or centralised planning mechanisms, wherein a coordinator agent continuously assigns and redistributes tasks based on real-time feedback and replanning. Representative frameworks include OpenManus [60] and Manus [66], both adopting hierarchical planner-toolcaller architectures. Similarly, OWL [12] includes a workforceoriented model, utilising a central manager agent to orchestrate task distribution among specialised execution agents. Furthermore, Alita [84] incorporates a self-evolution mechanism into DR agents, allowing the agent to online instantiate and configure new MCP servers tailored to specific tasks and environmental conditions. AWorld [8] is an open-source framework for building, orchestrating, and training tools using agents and larger multi-agent systems, offering memory and context services and MCP tool integration for scalable evaluation and self-improvement. Webwalker [121] mimics human-like web navigation through an explore-critic paradigm. WebThinker [59] uses both executed and auxiliary agents to autonomously search, deeply explore web pages, and draft research reports. Such multi-agent configurations effectively handle complex, parallelizable research tasks, thereby enhancing flexibility and scalability in open-ended research scenarios. Nevertheless, a major current challenge of multi-agent systems lies in the inherent complexity of coordinating multiple independent agents, making it difficult to conduct effective end-to-end reinforcement learning optimisation. 

# 3.3.4 Memory Mechanism for Long-Context Optimisation

Memory mechanisms empower DR agents to persistently capture, organise, and recall relevant information across multiple retrieval rounds, thereby reducing redundant queries and improving both the efficiency and coherence of DR tasks. During the DR process, agents typically perform extensive multi-round retrieval, generating hundreds of thousands of tokens (or even millions). Although recent advances in LLMs have significantly expanded context window sizes, current limits still constrain tasks involving extremely long contexts. To address these challenges, DR systems have implemented various optimisations for processing extended contexts. Broadly, these optimisations can be categorised into three main strategies: (i) Expanding the Context Window Length; (ii) Compressing Intermediate Steps; (iii) Utilising External Structured Storage for Temporary Results. 

Extending the Context Window Length. It is the simple but intuitively effective approach, exemplified by Google’s Gemini model [33], which supports a context window of up to one million tokens, supplemented by a RAG setup. 

Despite its straightforwardness, this method often incurs high computational costs and may lead to inefficiencies in resource utilisation during practical deployments. 

Compressing Intermediate Step. An alternative strategy involves compressing or summarising intermediate reasoning steps, significantly reducing the number of tokens processed by the model and thereby improving both efficiency and output quality. Representative frameworks such as The AI Scientist [63] and CycleResearcher [117] pass summarised intermediate results between workflow phases. Further, Search-o1 [58] introduced the concept of “Reason-in-Documents”, utilising LRMs to compress documents, substantially reducing token volume and enhancing model decision-making efficiency. Meanwhile, WebThinker [59] uses an auxiliary model to compress the external information. However, a potential drawback of this approach is the loss of detailed information, potentially impacting the precision of subsequent reasoning. 

Utilising External Structured Storage. This is for preserving and retrieving historical information, enabling DR agents to persistently and efficiently store vast amounts of past context beyond the constraints of the context window, improving memory capacity, retrieval speed, and semantic relevance. Popular open-source frameworks such as Manus [66], OWL [12], Open Manus [60], and Avatar [123] utilise external file systems to store intermediate outcomes and historical data for subsequent retrieval. Frameworks like AutoAgent [101] have developed self-managing modules that leverage vector databases to support scalable memory storage and fast similarity-based lookup. Beyond plain text or vector stores, some works propose more semantically structured memory frameworks: for instance, Agentic Reasoning [122] employ knowledge graphs to capture intermediate reasoning processes and thereby enhance the precision of information reuse, while Agentrxiv [88] simulates an academic repository akin to arXiv for storing and retrieving relevant outcomes from other agents. Furthermore, Agent-KB [103] and Alita [84] construct shared knowledge bases and optimised toolsets for agentic problem-solving. Although these structured approaches offer superior semantic retrieval efficiency and accuracy, they typically entail higher development and maintenance costs due to the need for meticulous data structure design and management. 

# 3.4 Tuning: Beyond Prompting toward Capability Enhancement


Table 3: Comparison of DR Agents with Tuning Methods



= Yes, = Yes but details unknown, = Not present


<table><tr><td>DR Agent</td><td>SFT</td><td>RL</td><td>Base Model</td><td>Data</td><td>Reward Design</td><td>Release</td></tr><tr><td>Gemini DR [33]</td><td>■</td><td>■</td><td>Gemini-2.0-Flash</td><td>□</td><td>■</td><td>Dec-2024</td></tr><tr><td>WebWalker</td><td>□</td><td>□</td><td>GPT-4o, Qwen-2.5 7-72B</td><td>WebWalkerQA</td><td>□</td><td>Jan-2025</td></tr><tr><td>Grok DeepSearch [124]</td><td>□</td><td>■</td><td>Grok3</td><td>□</td><td>■</td><td>Feb-2025</td></tr><tr><td>OpenAI DR [78]</td><td>□</td><td>■</td><td>GPT-o3</td><td>□</td><td>■</td><td>Feb-2025</td></tr><tr><td>Agentic Reasoning [122]</td><td>■</td><td>□</td><td>DeepSeek-R1, Qwen2.5</td><td>GPQA</td><td>Rule-Outcome</td><td>Feb-2025</td></tr><tr><td>AutoAgent [101]</td><td>□</td><td>■</td><td>Claude-Sonnet-3.5</td><td>□</td><td>□</td><td>Feb-2025</td></tr><tr><td>Towards an AI co-scientist</td><td>□</td><td>□</td><td>Gemini 2.0</td><td>□</td><td>□</td><td>Feb-2025</td></tr><tr><td>Agent-R1 [80]</td><td>□</td><td>PPO [90], Reinforce++ [43], GRPO [92]</td><td>Qwen2.5-1.5B-Inst</td><td>HotpotQA</td><td>Rule-Outcome</td><td>Mar-2025</td></tr><tr><td>AutoGLM Romain-tion [137]</td><td>■</td><td>■</td><td>GLM-Z1-Air</td><td>□</td><td>■</td><td>Mar-2025</td></tr><tr><td>H2O.ai DR [39]</td><td>■</td><td>■</td><td>h2ogpt-oasst1-512-12b</td><td>□</td><td>■</td><td>Mar-2025</td></tr><tr><td>Copilot Researcher [69]</td><td>■</td><td>■</td><td>o3-mini</td><td>□</td><td>□</td><td>Mar-2025</td></tr></table>


Continued on next page 



Table 3 continued from previous page


<table><tr><td>DR Agent</td><td>SFT</td><td>RL</td><td>Base Model</td><td>Data</td><td>Reward Design</td><td>Release</td></tr><tr><td>ReSearch [16]</td><td>□</td><td>GRPO [92]</td><td>Qwen2.5-7B-Inst, Qwen2.5-32B-Inst</td><td colspan="2">2WikiMultiHopQARule-Outcome</td><td>Mar-2025</td></tr><tr><td>R1-Searcher [96]</td><td>■</td><td>Reinforce++ [43], GRPO [92]</td><td>Qwen2.5-7B-InSt, LLaMA-3.1-8B-Inst</td><td>2WikiMultiHop( HotpotQA</td><td>Rule-Outcome</td><td>Mar-2025</td></tr><tr><td>Search-R1 [52]</td><td>■</td><td>PPO [90], GRPO [92]</td><td>Qwen2.5-3B/7B, LLaMA3.2-3B-Inst</td><td>NQ, HotpotQA</td><td>Rule-Outcome</td><td>Mar-2025</td></tr><tr><td>Nouswise [75]</td><td>■</td><td>■</td><td>Nouswise</td><td>□</td><td>■</td><td>Mar-2025</td></tr><tr><td>DeepResearcher [135]</td><td>□</td><td>GRPO [92]</td><td>Qwen2.5-7B-Inst</td><td>NQ, HotpotQA</td><td>Rule-Outcome</td><td>Apr-2025</td></tr><tr><td>Genspark Super Agent [106]</td><td>□</td><td>■</td><td>Mixture of Agents</td><td>□</td><td>■</td><td>Apr-2025</td></tr><tr><td>WebThinker [59]</td><td>■</td><td>Iterative Online DPO [86]</td><td>QwQ-32B</td><td>Expert Dataset</td><td>Rule-Outcome</td><td>Apr-2025</td></tr><tr><td>SWIRL [30]</td><td>□</td><td>Offline-RL</td><td>Gemma-2-27B</td><td>HotPotQA</td><td>□</td><td>Apr-2025</td></tr><tr><td>SimpleDeepSearcher [100]</td><td>■</td><td>PPO [90]</td><td>Qwen-2.5-7B-In, Qwen-2.5-32B-In, Deepseek-Distilled-Qwen-32B, QwQ-32B</td><td>NQ, HotpotQA, 2WikiMulti-HopQA, Musique, SimpleQA, MultiHop-RAG</td><td>Process-based reward</td><td>Apr-2025</td></tr><tr><td>PANGU DEEP-DIVER [94]</td><td>■</td><td>GRPO [92]</td><td>Pangu-7B-Reasoner</td><td>WebPuzzle</td><td>Rule-Outcome</td><td>May-2025</td></tr><tr><td>Tool-Star [22]</td><td>■</td><td>GRPO [92]</td><td>Qwen-2.5</td><td>NuminaMath, HotpotQA, 2WikiMulti-HopQA</td><td>Rule-Outcome</td><td>May-2025</td></tr><tr><td>WebDancer [120]</td><td>■</td><td>DAPO [130]</td><td>Qwen-2.5-7B/32B, QwQ-32B, DeepSeek-R1, GPT-4o</td><td>CRAWLQA, E2HQA</td><td>Rule-Outcome</td><td>May-2025</td></tr><tr><td>O-agents [140]</td><td>□</td><td>□</td><td>GPT-4o, GPT-4.1, Claude-3.7-Sonnet, DeepSeek-R1, Gemini-2.5</td><td>□</td><td>□</td><td>Jun-2025</td></tr><tr><td>Kimi-Researcher [70]</td><td>□</td><td>REINFORCE</td><td>Kimi k1.5/k2</td><td>□</td><td>Rule-Outcome</td><td>Jun-2025</td></tr><tr><td>WebSailor [57]</td><td>■</td><td>DUPO</td><td>Qwen-2.5-3B/7B/32B/72B</td><td>SailorFog-QA</td><td>Rule-Outcome</td><td>Jul-2025</td></tr><tr><td>Agent-KB [103]</td><td>□</td><td>□</td><td>GPT-4o, GPT-4.1, Claude-3.7-Sonnet, o3-mini, Qwen-3 32B, DeepSeek-R1</td><td>□</td><td>□</td><td>Jul-2025</td></tr><tr><td>WebShaper [104]</td><td>■</td><td>GRPO [92]</td><td>Qwen-2.5-3B/7B/32B/72B, QwQ-32B</td><td>WebShaper</td><td>Rule-Outcome</td><td>Jul-2025</td></tr></table>


Continued on next page 



Table 3 continued from previous page


<table><tr><td>DR Agent</td><td>SFT</td><td>RL</td><td>Base Model</td><td>Data</td><td>Reward Design</td><td>Release</td></tr><tr><td>Cognitive Kernel- 
Pro [109]</td><td>■</td><td>□</td><td>Claude-3.7-Sonnet, 
CK-Pro-8B</td><td>OpenWebVoyage 
Multi-hop 
URLQA, 
AgentWe-
bQA, 
WebWalk-
erQA, 
DocBench, 
TableBench</td><td>□</td><td>Aug-2025</td></tr><tr><td>WebWatcher [29]</td><td>□</td><td>GRPO [92]</td><td>Qwen-2.5-VL-32B</td><td>BrowseComp-
VL, Long-tail 
VQA, Hard 
VQA</td><td>Rule-Outcome</td><td>Aug-2025</td></tr><tr><td>MiroRL [107]</td><td>■</td><td>GRPO [92]</td><td>Qwen3-14B</td><td>MiroRL-
GenQA</td><td>Rule-Outcome</td><td>Aug-2025</td></tr></table>

Parametric Approaches. Prompt-based methods directly leverage the capabilities of pre-trained LLMs, enabling complex functionalities without expensive fine-tuning or additional training. However, it remains challenging to systematically optimise prompt structures and workflows. Moreover, since an agent’s performance is inherently limited by its backbone LLM, increasing the complexity of decision-making processes quickly reaches the model’s performance ceiling. To overcome these limitations, it is essential to incorporate advanced optimisation techniques such as fine-tuning, reinforcement learning (RL) or hybrid training paradigms to further extend the model’s inherent capabilities. Below, we discuss the two main tuning paradigms, supervised fine-tuning (SFT) and RL, and highlight how each extends agent capabilities beyond prompt-only methods. 

# 3.4.1 SFT-based Optimization

Prompt-based approaches, while effective for rapid adaptation, are fundamentally constrained by the intrinsic generalisation capacity of backbone LLMs and often exhibit limited robustness in complex task settings. In order to address these limitations, researchers have increasingly explored fine-tuning methodologies aimed at systematically optimising LLMs for critical components of deep research agents. These components include search query formulation, structured report generation, and external tool utilisation. These efforts aim to enhance retrieval quality, mitigate hallucinations, and enable more reliable long-form and evidence-grounded generation. 

An early milestone in this research direction is Open-RAG [47], which augments data construction with diverse supervisory signals, including retrieval tokens, relevance tokens, grounding tokens, and utility tokens. Through adversarial training, Open-RAG improves the model’s capability to filter irrelevant information, thereby enhancing both retrieval accuracy and the quality of downstream tasks. Building upon this foundation, AUTO-RAG [131] enhances the autonomous iterative retrieval capabilities of LLMs. In contrast to earlier multi-hop retrieval approaches that relied on few-shot prompting or hand-crafted templates [50, 25, 111], AUTO-RAG constructs reasoning-grounded instruction datasets, enabling models to autonomously plan retrieval queries and engage in multi-round interactions with retrievers. The model dynamically refines its retrieval strategy during generation, gathering sufficient evidence before synthesising a final answer. Extending these retrieval-centric innovations, DeepRAG [36] proposes a binary tree search mechanism that recursively generates sub-queries and constructs multi-turn retrieval trajectories. This mechanism enables the model to judiciously balance between internal parametric knowledge and external retrieval-based rollouts. Consequently, it enhances search efficiency and mitigates redundant external queries. 

In order to further reduce reliance on manually constructed supervised fine-tuning (SFT) datasets, recent work has sought to reduce dependence on manually constructed supervised fine-tuning datasets by developing fine-tuning strategies based on rejection sampling. CoRAG [112] uses rejection sampling to extract intermediate retrieval chains from standard question answering datasets, allowing for stepwise retrieval augmentation and dynamic reformulation of subqueries as context evolves instead of supervising only final outputs. Li et al. [56] propose a hint-infer mechanism that monitors token patterns during generation and triggers external computational tools, such as Python executors 

or hint libraries, when specific cues are detected. After an initial supervised fine-tuning phase, the model undergoes a rejection sampling fine-tuning process that teaches it to generate its own prompts and invoke tools autonomously without reliance on hand-curated demonstrations. ATLAS [18] proposes a novel approach for LLM-based agents that trains exclusively on selected critical steps from expert trajectories, significantly improving generalisation performance. 

Although these SFT methods enhance the generalisation of deep research agents by supporting dynamic retrieval planning, structured information synthesis, and integrated tool use, they remain confined to offline, static retrieval pipelines characteristic of retrieval-augmented systems. In contrast, reinforcement learning offers a more adaptive solution for online query generation and tool invocation. By learning from real-time reward signals, reinforcement learning agents acquire the ability to formulate effective search queries and determine the optimal timing for tool calls. This approach addresses the limitations of synthetic demonstration data and distributional shifts, yielding more robust and adaptive performance in open-ended research environments. 

# 3.4.2 Reinforcement Learning-based Optimisation

RL-based methods optimise DR agents by directly enhancing their adaptive capabilities and generalisation across diverse tasks, surpassing conventional instruction-following or pattern learning approaches. Recent advances have demonstrated that end-to-end RL training significantly strengthens iterative information retrieval, dynamic tool invocation, and integrated reasoning capabilities within DR agents. See comparative analysis in Table 3. 

Early RL-based approaches such as DeepRetrieval [49] optimised query generation for improved information retrieval quality, effectively enhancing downstream text generation by producing more relevant search results. Building on query optimisation, ReSearch [16] extended RL to adaptive reasoning over retrieved information. The model dynamically refined search strategies and iteratively updated results based on continuous feedback, significantly improving tasksolving accuracy. Subsequently, R1-Searcher [96] further optimised retrieval interactions, explicitly training models to refine search strategies through carefully designed reward functions. This allowed better exploitation of external information and improved search result relevance. 

Search-R1 [52] advanced RL-based retrieval by structurally integrating sophisticated search interactions with complex reasoning processes. The method systematically bridged query generation and information reasoning, enabling nuanced responses through refined integration of retrieved content. Finally, this research line culminated in the development of Agent-R1 [80], a comprehensive DR framework integrating RL into end-to-end training of LLM agents. Agent-R1 leveraged diverse tools such as APIs, search engines, and databases, achieving autonomous multi-step task execution and dynamic tool coordination. Through RL-driven optimisation across its entire pipeline, Agent-R1 demonstrated advanced capabilities in adaptive planning, iterative execution, and task refinement. Moreover, WebThinker [59] integrates a Web Explorer module for dynamic multi-hop web exploration and employs Iterative Online Direct Preference Optimisation (DPO) to seamlessly interleave search, navigation, and report drafting during reasoning, while Pangu DeepDiver [94] builds on the 7B Pangu model pretrained on Huawei’s Ascend NPUs by introducing Search Intensity Scaling (SIS) through a two-phase SFT and RL curriculum, enabling adaptive adjustment of search depth and frequency in open-web environments. 

Table 3 reveals three key RL implementation patterns in DR systems: 1) Industrial systems like Gemini DR [33] and Grok DeepSearch [124] employ proprietary RL implementations with undisclosed details, 2) Academic approaches [16, 96] favor modular RL optimization using GRPO [92] and Reinforce $^ { + + }$ [43] with transparent reward designs, and 3) Emerging hybrid systems like SimpleDeepSearcher [100] combine process-based rewards with multi-task training across 6 QA datasets. The table also highlights the prevalence of Qwen2.5 and LLaMA3 model families as preferred base architectures for RL optimisation. 

Reward Model and Policy Model. Most current open-source RL implementations of DR agents, including the methods discussed above, commonly adopt rule-based reward models that explicitly define task-specific objectives such as retrieval relevance, information accuracy, or successful tool invocation. To efficiently perform policy optimisation, recent systems have increasingly utilised Proximal Policy Optimisation (PPO) [90] and Group Relative Policy Optimisation (GRPO) [92]. In particular, GRPO fundamentally reconfigures the advantage estimation paradigm by replacing traditional value functions with group-relative advantage computation. It expands reward space through intra-group normalisation, and sparse binary rewards are transformed into continuous advantage values spanning wider ranges. This expanded signal space provides richer gradient information for policy updates, as evidenced higher high-reward response density compared to PPO. In addition, GRPO provides a variance suppression mechanism by constraining advantage estimation within dynamically clustered response groups, such as grouping by reasoning depth or tool usage patterns, reducing policy gradient variance through local standardisation. In contrast to PPO, GRPO eliminates separate value networks, removing conflicting optimisation objectives between policy and value functions. Empirical measurements 

show GRPO reduces gradient direction conflicts from 12 to 3 per training epoch, significantly accelerating convergence. As a result, GRPO outperforms conventional PPO in wider reward distribution coverage, enhancing exploration capacity and faster KL divergence stabilisation during alignment. 

# 3.5 Non-parametric Continual Learning

DR agents depend heavily on LRMs and often utilise complex hierarchical workflows. Parameter-based learning approaches such as SFT and RL encounter significant obstacles in this context, including the need to scale model parameters, manage extensive volumes of structured experience data, and design increasingly intricate training algorithms. In contrast, non-parametric continual learning approaches offer a scalable alternative: agents refine their capabilities at runtime by optimising external memory, workflows, and tool configurations through continuous interaction with the external environment rather than by updating internal weights. This non-parametric continual learning paradigm enables efficient online adaptation with minimal data and computational overhead, making it well-suited to DR agents with complex architectures. 

Non-parametric continual learning approaches, most notably case-based reasoning (CBR), are currently a mainstream method in LLM-driven agent systems. The CBR-based method enables agents to retrieve, adapt, and reuse structured problem-solving trajectories from an external case bank dynamically. Unlike traditional RAG-based methods, which rely on static databases, CBR facilitates online contextual adaptation and effective task-level generalisation. Such flexibility underscores its potential as a scalable and practical optimisation solution for DR agents with complex architecture. DS-Agent [37] is a pioneering LLM-driven agent that introduced CBR into automated data science workflows, employing approximate online retrieval from a constructed case bank. Similarly, LAM [38] applies CBR techniques to functional test generation, combining trajectory-level retrieval with LLM planning in a modular system design. Although DS-Agent itself does not include a learning phase, Agent K [35]advances this paradigm with dynamic external case retrieval and reuse guided by a reward-based memory policy, which exemplifies genuine self-evolution enabling continual adaptation and optimisation without updating model parameters. Focusing on DR agents, AgentRxiv [88] further extends this paradigm by enabling autonomous research agents to collaboratively share and access a centralised repository of prior research outputs. This framework allows LLM agent laboratories to upload and retrieve reports from a shared preprint server, simulating an online-updating arXiv-like platform, which can be seen as a comprehensive case bank. Such a system empowers agents to enhance their capabilities and knowledge through contextual adaptation without modifying their model parameters. 

Compared to prompt-based methods, which encode fixed demonstrations or task heuristics into static input templates, Non-parametric methods enable dynamic retrieval and adaptation of structured trajectories, thereby facilitating continual task generalisation without manual prompt engineering. Relative to RAG, which typically retrieves unstructured textual content from static corpora, CBR operates at the trajectory level and emphasises reasoning-centred memory organisation. A notable example is the Kaggle Grandmaster Agent [35], which demonstrates how LLMs equipped with modular reasoning components and persistent memory can achieve expert-level structured problem solving, aligning closely with the CBR paradigm. These characteristics make CBR particularly well-suited for agents requiring procedural adaptation and context-sensitive optimisation across tasks. Except memory-based method, self-evolution can also arise from dynamic infrastructure adaptation. For example, Alita [84] monitors task requirements and environmental signals to provision and configure new MCP servers at runtime, seamlessly extending and refining its toolset on demand. 

In summary, these self-evolution paradigms in LLM-driven DR agent systems offer substantial promise for structured reasoning and dynamic retrieval and open new pathways for efficient knowledge reuse and continual learning. Although these methods have not yet achieved widespread attention, they address the high data and computational demands inherent to parameter-based approaches and therefore represent an attractive direction for future research and practical deployment. 

# 4 Industrial Applications of Deep Research Agents

# 4.1 Open AI Deep Research

OpenAI recently introduced its DR capability [78], employing a single-agent architecture centred around a reinforcement learning-based, fine-tuned o3 reasoning model. Upon receiving a research query, the system initiates a concise interactive clarification step to accurately define user intent and research objectives. It then autonomously formulates and executes a sophisticated, multi-step research strategy, encompassing multimodal information retrieval, web browsing, and computational tasks such as data analysis and visualisation through browser tools. Technologically, this solution delivers 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/de285f1c-391e-4a57-b37e-cfc33092d601/5b748f572bb2125e7dfc06bdf59132fd7ef937ad34c2400a6bb82cd99f9b198e.jpg)



Figure 5: An overview of DR agents’ evolution over years.


three significant advancements: (1) A dynamically adaptive iterative research workflow: Capable of refining its strategy throughout task execution. (2) Enhanced context memory and robust multimodal processing capabilities: Facilitating effective integration of diverse information sources. (3) Comprehensive toolchain integration: Combining web browsing capabilities with built-in programming tools to produce structured, authoritative reports supported by precise citations. 

# 4.2 Gemini Deep Research

Google DeepMind recently introduced Gemini DR [33], an advanced DR agent based on its multimodal Gemini 2.0 Flash Thinking model. Gemini’s reinforcement learning-driven fine-tuning, facilitated by a single-agent architecture, has been shown to enhance planning and adaptive research capabilities, enabling the system to autonomously and expeditiously complete complex tasks. Technologically, this solution delivers four significant advancements: (1) Interactive Research Planning: Upon receiving a research query, Gemini autonomously formulates a multi-step investigation plan for interactive user review and modification. (2) Asynchronous Task Management: Adopts an asynchronous task management architecture to efficiently handle multiple simultaneous tasks. (3) Large-scale context windows RAG ensembles: Enabling effective management and coherent synthesis of multimodal data (eg, text, images)for in-depth professional research analysis. (4) High speed adaptive retrieval: Implements fast, multi-round adaptive web search that significantly outperforms other agents in terms of retrieval speed and amount of information per iteration. 

# 4.3 Perplexity Deep Research

Perplexity’s recently developed DR agent [81] has demonstrated an advanced capability to decompose complex queries into well-defined subtasks. The system is capable of conducting targeted web searches iteratively, critically evaluating authoritative sources, and synthesising structured, comprehensive reports. Technologically, this solution delivers two significant advancements: (1) Iterative Information Retrieval: Conducts successive rounds of targeted web searches with dynamic adjustments based on interim insights, ensuring comprehensive information coverage and accuracy. (2) Dynamic Prompt-Guided Model Selection: Use a hybrid architecture to autonomously select the optimal combination of specialised models based on the requirements and context of specific tasks, thereby enhancing adaptability and effectiveness in various research scenarios. 

# 4.4 Grok DeepSearch

Grok DeepSearch [124], developed by xAI, is a computational framework that combines real-time information retrieval with multimodal reasoning to dynamically solve complex and information-rich problems. Technologically, this solution delivers two significant advancements: (1) Segment-level module processing pipeline: Upon receiving a query, Grok3 initiates the credibility assessment module to identify and filter out low-quality information. Subsequently, the system’s real-time data acquisition engine gathers multimodal inputs (e.g. text, images, and code) from various sources. Subsequently, employing the sparse attention mechanism, the system undertakes key reasoning subtasks, including data cleaning, cross-source verification, and multimodal integration, in a concurrent manner. Finally, the iterative optimisation process culminates in the generation of structured outputs, encompassing analysis summaries, advanced visualisations (e.g. 3D trajectories), and verifiable citations. (2) Dynamic resource allocation: Capacity for adaptively alternating between lightweight retrieval and intensive analysis modes is noteworthy, and it is further augmented by the incorporation of a secure sandbox environment for computational verification. 

# 4.5 Microsoft Copilot Researcher and Analyst

Microsoft recently introduced two innovative reasoning agents within Microsoft 365 Copilot: Researcher and Analyst [98]. These agents securely and compliantly access users’ work data (such as emails, meeting notes, documents, and chats) as well as web information, delivering on-demand expert knowledge. 

Researcher is designed to assist users in tackling complex, multi-step research tasks, delivering insights with unprecedented quality and accuracy. It combines OpenAI’s advanced research models with Microsoft 365 Copilot’s sophisticated orchestration and deep search capabilities. Users can employ Researcher to craft detailed market entry strategies, identify market opportunities for new products by integrating internal and external data, or prepare comprehensive quarterly reports for client reviews. Additionally, Researcher enhances its insights through connectors to third-party data sources such as Salesforce, ServiceNow, and Confluence. 

Analyst is built as an advanced data analytics agent that rapidly transforms raw data into valuable insights within minutes. It leverages OpenAI’s o3-mini inference model, specifically optimised for advanced analytical tasks in professional environments. Analyst uses a chain-of-thought reasoning approach, solving problems step-by-step, generating high-quality responses that closely mirror human analytical thinking. 

# 4.6 Qwen Deep Research

Alibaba Qwen recently launched Qwen Deep Research, an advanced research agent powered by its flagship multimodal model Qwen3-235B-A22B. Through reinforcement learning-optimised task scheduling within a unified agent framework, the system demonstrates enhanced autonomous planning and adaptive execution capabilities, enabling rapid completion of complex research workflows. Key technological advancements include: (1) Dynamic Research Blueprinting with interactive plan refinement. (2) Concurrent Task Orchestration enabling parallel retrieval validation synthesis. 

# 4.7 Kimi K2 Deep Research

Moonshot AI’s Kimi K2 [? ] advances deep research through token-efficient learning, targeted data engineering, a scalable sparse design, and tool-aligned post-training. Concretely, it delivers four contributions: (1) Token-efficient pretraining: stabilised optimisation with selective attention regularisation for reliable large-scale training. (2) Data rewriting: synthetic rephrasing for knowledge and learning-note style transformation for mathematics, yielding a vetted corpus of about 15.5 trillion tokens across web text, code, math, and knowledge. (3) Sparse architecture and systems: mixture-of-experts with multi-head latent attention and an observed sparsity scaling regularity, supported by flexible parallelism and memory-aware execution on H800 clusters. (4) Post-training for agents: supervised tool-use trajectories with sandboxed code execution followed by reinforcement learning that combines verifiable rewards for objective tasks and rubric-based self-critique for subjective tasks. 

In addition to the pioneering DR services previously discussed, major technology corporations such as Microsoft and ByteDance, alongside emerging startups including Jina AI [3], H2O [39], and Zhipu AI [137], have also introduced their proprietary DR platforms. The advent of these solutions has spurred considerable global interest, reflected by their rapid proliferation, thereby underscoring both the technological attractiveness and substantial market potential of DR applications. Looking forward, continuous advancements in LLM reasoning, retrieval integration techniques, and 

multimodal generation are expected to enable DR agents to transcend traditional information retrieval and basic tool invocation tasks. Consequently, DR systems are anticipated to tackle increasingly sophisticated reasoning and complex knowledge-construction challenges, ultimately positioning DR as a foundational technological pillar for next-generation intelligent collaborative research platforms. 

# 5 Benchmarks for DR Agent

Evaluating DR agents requires benchmarks that capture their full research workflow, including multi-step information retrieval, cross-source synthesis, dynamic tool invocation, and structured evidence-grounded report generation. Existing evaluations fall into two main categories. Question-Answering (QA) benchmarks range from single-turn factual queries to complex research-style problems, assessing agents’ factual knowledge, domain-specific reasoning, and ability to locate and integrate relevant information. Task Execution benchmarks evaluate broader capabilities such as long-horizon planning, multimodal understanding, tool usage, and environment interaction by measuring how well agents carry out end-to-end research tasks. Although long-form generation datasets such as Qasper [21] and ELI5 [23] provide tests of extended output coherence, their free-form nature does not align with the structured evidence-based reporting expected of DR agents. Consequently, there is a pressing need for specialised benchmarks that reflect the multi-stage, multimodal characteristics of DR workflows and ensure rigorous and relevant assessment of agent performance across all phases of autonomous research. 


Table 4: Performance of DR agents on major QA benchmarks. The best performance is highlighted in bold, and the second-best is indicated with an underline.



□ $=$ Not present


<table><tr><td rowspan="2">DR Agent</td><td rowspan="2">Base Model</td><td colspan="5">QA Benchmarks</td><td rowspan="2">Release</td></tr><tr><td>Hotpot</td><td>2Wiki</td><td>NQ</td><td>TQ</td><td>GPQA</td></tr><tr><td>Search-o1 [58]</td><td>QwQ-32B-preview</td><td>57.3</td><td>71.4</td><td>49.7</td><td>74.1</td><td>57.9</td><td>Jan-2025</td></tr><tr><td>Agentic Reasoning [122]</td><td>DeepSeek-R1, Qwen2.5</td><td>□</td><td>□</td><td>□</td><td>□</td><td>67.0</td><td>Feb-2025</td></tr><tr><td>Grok DeepSearch [124]</td><td>Grok3</td><td>□</td><td>□</td><td>□</td><td>□</td><td>84.6</td><td>Feb-2025</td></tr><tr><td>AgentRxiv [88]</td><td>GPT-4o-mini</td><td>□</td><td>□</td><td>□</td><td>□</td><td>41.0</td><td>Mar-2025</td></tr><tr><td>R1-Searcher [96]</td><td>Qwen2.5-7B-Base</td><td>71.9</td><td>63.8</td><td>□</td><td>□</td><td>□</td><td>Mar-2025</td></tr><tr><td>ReSearch [16]</td><td>Qwen2.5-32B-Inst</td><td>67.7</td><td>50.0</td><td>□</td><td>□</td><td>□</td><td>Mar-2025</td></tr><tr><td>Search-R1 [52]</td><td>Qwen2.5-7B-Inst</td><td>34.5</td><td>36.9</td><td>40.9</td><td>55.2</td><td>□</td><td>Mar-2025</td></tr><tr><td>DeepResearcher [135]</td><td>Qwen2.5-7B-Inst</td><td>64.3</td><td>66.6</td><td>61.9</td><td>85.0</td><td>□</td><td>Apr-2025</td></tr><tr><td>WebThinker [59]</td><td>QwQ-32B</td><td>□</td><td>□</td><td>□</td><td>□</td><td>68.7</td><td>Apr-2025</td></tr><tr><td>SimpleDeepSearch [100]</td><td>QwQ-32B</td><td>73.5</td><td>□</td><td>□</td><td>□</td><td>□</td><td>Apr-2025</td></tr><tr><td>SWIRL [30]</td><td>Gemma-2-27B</td><td>72.0</td><td>□</td><td>□</td><td>□</td><td>□</td><td>Apr-2025</td></tr><tr><td>Tool-Star [22]</td><td>Qwen2.5-3B</td><td>51.9</td><td>40.0</td><td>□</td><td>□</td><td>□</td><td>May-2025</td></tr></table>

QA Benckmarks. QA benchmarks span a spectrum of complexity, from simple factual recall to multi-hop reasoning and research-style question answering. At the lower end, datasets such as SimpleQA [115], TriviaQA [53], and PopQA [65]focus on parametric or single-hop factual recall, evaluating whether models can retrieve short factual answers from memory or minimal context. Natural Questions (NQ) [55] and TELEQnA [64] add complexity by requiring answer extraction from long documents or domain-specific sources. Benchmarks like HotpotQA [126], 2WikiMultihopQA [41], and Bamboogle [5] emphasize multi-hop reasoning and supporting evidence selection across documents. At the highest level of difficulty lies Humanity’s Last Exam (HLE) [82], which targets expert-level, open-domain scientific questions crafted by leading professors in various fields. These questions often require multi-turn retrieval, complex inference, and even multimodal understanding. Additionally, BrowseComp [79] is another challenging benchmark proposed by OpenAI to measure the ability of AI agents to locate hard-to-find information. It retains the answer verifiability of the Simple QA benchmark while filtering out those that can be easily solved by LLMs with web search, thus testing agents’ information retrieval and synthesis capabilities. Despite recent advancements, leading DR agents still exhibit suboptimal performance on the HLE and BrowserComp benchmark compared to human experts. This highlights these two benchmarks as the most critical and unresolved challenges in the evaluation of DR agents. 

Task Execution Benchmarks. Task execution benchmarks evaluate an agent’s integrated capabilities in tool use, environment perception, and information filtering. These can be grouped into two subcategories. The first category comprises general-purpose assistant tasks such as GAIA [68], AssistantBench [128], and Magentic-One [26]. These tasks require agents to plan and execute tool-based workflows (for example, searching, browsing, or form filling) within environments that are open-ended and often web-based. Among them, GAIA has emerged as 


Table 5: Performance of DR agents on GAIA test and validation sets. The best performance is highlighted in bold, and the second-best is indicated with an underline.



= Not present


<table><tr><td rowspan="2">DR Agent</td><td rowspan="2">Base Model</td><td colspan="4">GAIA</td><td rowspan="2">Release</td></tr><tr><td>Level-1</td><td>Level-2</td><td>Level-3</td><td>Ave.</td></tr><tr><td>Test set</td><td></td><td></td><td></td><td></td><td></td><td></td></tr><tr><td>MMAC-Copilot [97]</td><td>GPT-3.5, GPT-4</td><td>45.16</td><td>20.75</td><td>6.12</td><td>25.91</td><td>Mar-2024</td></tr><tr><td>H2O.ai DR [39]</td><td>Claude3.7-Sonnet</td><td>89.25</td><td>79.87</td><td>61.22</td><td>79.73</td><td>Mar-2025</td></tr><tr><td>Alita [84]</td><td>Claude-Sonnet-4, GPT-4o</td><td>92.47</td><td>71.7</td><td>55.1</td><td>75.42</td><td>May-2025</td></tr><tr><td>Agent-KB [103]</td><td>GPT-4.1, Claude-3.7</td><td>84.91</td><td>74.42</td><td>57.69</td><td>75.15</td><td>Jul-2025</td></tr><tr><td>O-agents [140]</td><td>Claude-3.7</td><td>83.02</td><td>74.42</td><td>53.85</td><td>73.93</td><td>Jun-2025</td></tr><tr><td>WebDancer [120]</td><td>QwQ-32B</td><td>61.5</td><td>50.0</td><td>25.0</td><td>51.5</td><td>May-2025</td></tr><tr><td>WebShaper [104]</td><td>Qwen-2.5-72B</td><td>69.2</td><td>63.4</td><td>16.6</td><td>60.1</td><td>Jul-2025</td></tr><tr><td>Deep Researcher with Test-Time Diffusion [40]</td><td>Gemini-2.5-Pro</td><td>□</td><td>□</td><td>□</td><td>69.1</td><td>Jul-2025</td></tr><tr><td>Cognitive Kernel-Pro [109]</td><td>Claude-3-7</td><td>83.02</td><td>68.60</td><td>53.85</td><td>70.91</td><td>Aug-2025</td></tr><tr><td>Dev set</td><td></td><td></td><td></td><td></td><td></td><td></td></tr><tr><td>AutoAgent [101]</td><td>Claude-Sonnet-3.5</td><td>71.7</td><td>53.5</td><td>26.9</td><td>55.2</td><td>Feb-2025</td></tr><tr><td>OpenAI DR [78]</td><td>GPT-o3-customized</td><td>78.7</td><td>73.2</td><td>58.0</td><td>67.4</td><td>Feb-2025</td></tr><tr><td>Manus [66]</td><td>Claude3.5, GPT-4o</td><td>86.5</td><td>70.1</td><td>57.7</td><td>71.4</td><td>Mar-2025</td></tr><tr><td>OWL [12]</td><td>Claude-3.7-Sonnet</td><td>84.9</td><td>68.6</td><td>42.3</td><td>69.7</td><td>Mar-2025</td></tr><tr><td>H2O.ai DR [39]</td><td>h2ogpt-oasst1-512-12b</td><td>67.92</td><td>67.44</td><td>42.31</td><td>63.64</td><td>Mar-2025</td></tr><tr><td>Genspark Super Agent [106]</td><td>Claude 3 Opus</td><td>87.8</td><td>72.7</td><td>58.8</td><td>73.1</td><td>Apr-2025</td></tr><tr><td>WebThinker [59]</td><td>QwQ-32B</td><td>53.8</td><td>44.2</td><td>16.7</td><td>44.7</td><td>Apr-2025</td></tr><tr><td>SimpleDeepSearch [100]</td><td>QwQ-32B</td><td>50.5</td><td>45.8</td><td>13.8</td><td>43.9</td><td>Apr-2025</td></tr><tr><td>Alita [84]</td><td>Claude-Sonnet-4, GPT-4o</td><td>75.15</td><td>□</td><td>87.27</td><td>□</td><td>May-2025</td></tr></table>


Table 6: Overview of nine widely used QA benchmark datasets employed in recent DR-agent studies. The first group covers single-hop QA tasks, while the second group focuses on multi-hop and multi-turn reasoning.


<table><tr><td>Benchmark</td><td>Release</td><td>Size</td><td>Task &amp; Context</td><td>Domain</td><td>Multi-hop Nums</td></tr><tr><td>TriviaQA [53]</td><td>2017</td><td>95 k</td><td>Single-hop retrieval (Long web/Wiki docs)</td><td>Open</td><td>1</td></tr><tr><td>Natural Questions [55]</td><td>2019</td><td>307 k</td><td>Document answer extraction (Full Wikipedia article)</td><td>Open</td><td>1</td></tr><tr><td>PopQA [65]</td><td>2023</td><td>14 k</td><td>Single-hop parametric recall (None)</td><td>Open</td><td>1</td></tr><tr><td>TELEQnA [64]</td><td>2023</td><td>10 k</td><td>Domain factual QA (Telecom standards/articles)</td><td>Telecom</td><td>1</td></tr><tr><td>SimpleQA [115]</td><td>2024</td><td>4.3 k</td><td>Single-hop factual recall (None / parametric)</td><td>Open</td><td>1</td></tr><tr><td>HotpotQA [126]</td><td>2018</td><td>113 k</td><td>Multi-hop reasoning (2 Wikipedia paragraphs)</td><td>Open</td><td>2</td></tr><tr><td>2WikiMultihopQA [41]</td><td>2020</td><td>192 k</td><td>Multi-hop reasoning (Retrieval across Wikipedia)</td><td>Open</td><td>2+</td></tr><tr><td>Bamboogle [5]</td><td>2023</td><td>125</td><td>Compositional reasoning (Online search)</td><td>Open</td><td>2–3</td></tr><tr><td>Humanity&#x27;s Last Exam [82]</td><td>2025</td><td>2.5 k</td><td>Expert-level multi-turn (Mixed external sources)</td><td>Multi-discipline</td><td>2+</td></tr></table>

the most important benchmark, offering diverse, realistic tasks that are easily human-solvable but remain highly challenging for current agents. The second subcategory focuses on research and code-oriented tasks, including SWE-bench [51], HumanEvalFix [71], MLGym [74], MLE-bench [14], MLBench [102], MLAgentBench [45], and ScienceAgentBench [19], which test agents on completing machine learning pipelines, repairing real-world code, or replicating scientific experiments. These tasks require long-horizon planning, precise tool invocation, and often code generation and validation. Additionally, benchmarks like RE-Bench [118] and RESEARCHTOWN [129] simulate multi-agent research environments, evaluating how well agents collaborate and iterate in multi-role scientific workflows. 

As DR agents continue to integrate more interactive tools, future evaluation may expand into GUI-based manipulation environments. Benchmarks such as OSWorld [125], WebArena [139], and SpaBench [15] allow agents to control applications or web interfaces directly, opening new avenues for testing embodied research capabilities in realistic, user-facing scenarios. 

# 6 Challenge and Future Directions

Despite the rapid evolution of DR agents and their demonstrated efficacy in automating multi-step information discovery and synthesis, two overarching challenges persist, defining the roadmap for future innovation. First, the breadth and depth of accessible information remain tightly constrained by reliance on static knowledge repositories or conventional search interfaces. Second, the efficiency and robustness of execution workflows and system architectures are limited by linear planning paradigms and monolithic agent designs. Addressing these challenges will be critical to enabling DR agents to function as truly autonomous, adaptable research assistants capable of navigating complex, heterogeneous data landscapes and orchestrating high-throughput, parallelised reasoning processes. 

Broaden Information Source. To meet the information needs of complex tasks, current DR agents adopt static knowledge bases (such as the RAG method) or rely exclusively on search engines and browsers; the former approach is insufficient, while the latter is confined to publicly available web content, thereby significantly constraining their information-acquisition capabilities. This inherent limitation renders them incapable of retrieving information concealed behind applications, proprietary interfaces or specialised databases. For example, conventional browsing and search techniques cannot penetrate enterprise software, mobile applications, or subscription-only services, such as the Bloomberg Terminal, thereby precluding access to critical, real-time market intelligence. In order to surmount this limitation, it is imperative to integrate a more granular and extensive range of modular tools via MCPs. This approach enables agents to dynamically access specialised tools and resources beyond the scope of standard browsers or search engines. Such resources may include proprietary applications, databases, or APIs, thereby facilitating the retrieval of previously inaccessible data. Consequently, DR agents have the capacity to deliver more precise, adaptive, and context-aware interactions, thereby effectively fulfilling diverse and complex user requirements. 

Following the integration of proprietary APIs and databases, the rate-limiting factor in the workflow shifts from data acquisition to webpage interaction efficiency. Conventional human-centred browsers create a further bottleneck for agents. Because they optimise for visual rendering rather than programmatic control, they suffer from sluggish page loads, fragile element locators that shift with every layout change, and aggressive anti-bot defences that often break automated sessions. These shortcomings translate into high latency, unstable scraping and limited parallelism whenever DR agents try to harvest data at scale. To address this bottleneck, researchers have begun to design AI-native browsers such as Browserbase [2], Browser Use [72], Dia, Fellou [105], and the Comet [108] from Perplexity. expose a stable, structured DOM view that agents can traverse programmatically [2, 72, 108]. [2, 105] supply explicit API hooks for clicking elements and filling forms, which removes the need for brittle coordinate-based actions. [2] further executes pages asynchronously in a headless container, reducing load-time variance and avoiding the overhead of a visible interface. [2] embeds a vision–language model that tracks dynamic page changes and automatically resolves login gates and anti-bot challenges. [72, 108] coordinates dozens of tabs in parallel, allowing DR agents to interact with private dashboards, single-page applications, and interactive visualisations at scale. In combination, these capabilities eliminate the delays and fragility that arise when conventional, human-centred browsers sit between the agent and newly unlocked proprietary data sources. 

Fact Checking. To further boost factual accuracy, the latest methods add a structured verification loop and selfreflection abilities on top of multi-step retrieval. Concretely, once an agent has drafted a preliminary answer, it does not rush to deliver a verdict. Instead, it proactively launches cross-checks: it looks for independent sources that confirm the same fact and searches for evidence of contradictions. Grok DeepSearch, for example, follows this strategy—it rates the credibility of every source, inspects consistency through as many as seven layers of depth, and verifies each key claim across multiple origins [124]. This multi-source cross-validation sharply reduces single-source errors and raises answer reliability. At the same time, agents have begun to reflect on their own reasoning. During inference, they inspect and test intermediate results, much like a human researcher’s reflective thinking. Zhipu’s Rumination model [137], for instance, pauses after concluding, keeps searching to check whether that conclusion holds, and only then finalises the answer. Such introspection is typically encouraged by adding correctness-oriented rewards in reinforcement learning. If the model detects conflict or uncertainty, it replans its retrieval strategy and, when necessary, backtracks to revise earlier inferences [78]. Through this blend of structured verification and self-reflection, research agents now attain an unprecedented level of rigour in fact-checking: they not only supply an answer but also explain why it is trustworthy, dramatically lowering factual errors and hallucinations. In short, modern agents can lay out a search plan, adapt queries as intermediate evidence comes in, and—where needed—rewind prior steps to recover missing information [78]. 

Asynchronous Parallel Execution. To address the limitation that most existing DR agents rely exclusively on linear task planning, i.e. the sequential execution of subtasks, we introduce two possible methodologies. These methods overcome the inherent efficiency and robustness constraints of purely linear strategies and enable both the exploitation of parallelism and the implementation of dynamic adjustments during task execution. Firstly, an asynchronous, parallel architecture leveraging advanced task-modelling structures, such as directed acyclic graphs (DAGs), presents a promising future direction which could enable parallel execution and dynamic prioritisation of subtasks, effectively managing complex interdependencies among tasks and facilitating potentially sophisticated planning capabilities such as replanning. Secondly, a learned scheduling agent, trained via reinforcement learning to allocate subtasks and adjust execution order based on runtime performance signals (e.g. execution latency), could be proposed. By treating scheduling decisions as actions in an RL environment, the agent progressively discovers policies that balance parallelism, resource utilisation, and task criticality, yielding more robust and efficient end-to-end research workflows. 

Tool-Integrated Reasoning. A fundamental challenge in developing effective DR agents lies in the implementation of Tool-Integrated Reasoning (TIR), a paradigm that extends beyond simple tool usage to encompass complex, multi-step 

reasoning with dynamic tool integration. TIR requires agents to not only invoke appropriate tools in logical sequence but also to adaptively adjust their reasoning pathways based on intermediate results. Traditional supervised fine-tuning approaches have demonstrated limited generalisation capabilities in tool-based reasoning tasks, often leading to overreasoning or inappropriate tool selection. Recent research by [83] has shown that reinforcement learning frameworks with carefully designed reward structures can significantly enhance models’ tool reasoning abilities. By incorporating fine-grained rewards that evaluate not only final answer correctness but also tool selection appropriateness, parameter specification accuracy, and reasoning efficiency, TIR-optimised agents have demonstrated performance improvements of $1 5 \mathrm { - } 1 7 \%$ across multiple benchmarks. Furthermore, these agents exhibit superior generalisation to unseen tools and tasks, more rational invocation patterns, and better balance between tool utilisation and self-knowledge. Implementing TIR effectively within DR agents represents a critical step toward achieving truly autonomous research assistants capable of navigating complex information landscapes with minimal human intervention. 

Benchmark Misalignment. Most public DR evaluations remain anchored in traditional QA suites whose items are harvested chiefly from static corpora such as Wikipedia. Since a considerable amount of this content is now embedded in backbone model parameters, current competitive agents can often answer directly from memory, bypassing any research procedure and thus inflating their performance. To probe genuine capabilities of retrieval, reasoning and tool usage, the field of DR urgently needs open-web, time-sensitive benchmarks. From this perspective, BrowseComp [79] constitutes a meaningful step forward by filtering out questions solvable with parametric knowledge and forcing agents to locate hard-to-find information online. Besides, a complementary direction is a continually refreshed leaderboard that updates problems from the latest web environment and events, deterring benchmark hacking through parametric memorisation. 

Beyond parametric knowledge hacking of QA benchmark, the metrics of the most existing DR research still collapse open-ended research workflows into narrowly scoped QA prompts or rudimentary GUI-control tasks, overlooking the paradigm’s defining outcome, a structured, multi-modal research report that weaves together textual narrative, tables, figures, and citations. Since the metrics of these benchmarks centre almost exclusively on information retrieval and extraction and tool invocation, they under-assess higher-level competencies such as evidence aggregation across heterogeneous sources, cross-modal synthesis, and discourse-level organisation. Thus, a key research priority is the development of comprehensive benchmarks that evaluate DR agents’ capacity for end-to-end report generation, encompassing long-form narrative, integrated tables and figures, and multimodal coherence, thereby assessing factual accuracy, discourse structure, and cross-modal alignment within a single task. 

Parametric Optimisation of Multi-Agent Architectures. End-to-end RL has been demonstrated by OpenAI [78, 80] to significantly enhance the reasoning capabilities of backbone models for DR tasks, a result successfully replicated by several open-source initiatives. However, current implementations predominantly utilise single-agent architectures, requiring the backbone model to simultaneously manage planning, tool invocation, and report generation. This multitasking places excessive computational and cognitive demands on backbone models, thereby reducing their efficiency and robustness. Distributing workloads across multiple specialised agents has shown promising improvements in system performance [110], yet achieving effective end-to-end training and efficient coordination among multiple agents remains a critical open challenge. 

To optimize multi-agent architectures for DR tasks, we propose two promising future directions: (i) adopting hierarchical reinforcement learning (HRL), which introduces layered internal reward mechanisms that facilitate efficient feedback propagation and foster cooperative learning among agents; or implementing a post-training optimization pipeline consisting of multiple refinement stages specifically tailored for DR tasks, which could iteratively enhance inter-agent interactions and thus improve overall system stability and adaptability; and (ii) employing an RL-based dedicated scheduling agent designed to dynamically allocate subtasks and adjust execution order based on real-time performance metrics. By modelling scheduling decisions as actions within an RL framework, this method progressively learns adaptive policies that optimally balance parallel execution, resource utilisation, and task prioritisation, enhancing both the robustness and efficiency of end-to-end research workflows. 

Self-Evolving Language Model Agents. Although initial attempts at self-evolution methods for DR agents have emerged, exemplified by simulated collaborative platforms such as AgentRxiv [88] that facilitate online sharing and reuse of structured research experiences, the paradigm remains underdeveloped and narrowly focused on only the case-based reasoning paradigm. Similarly, CycleResearcher [117] enables the entire research process simulation (research-evaluation-refine) through iterative preference learning with a robust verifier [141], representing a significant step toward fully automated scientific inquiry and sharing the similar self-evolution concept with AlphaEvolve [76]. 

To fully realise the potential of self-evolution in DR agents, future research should expand the self-evolution method along two complementary directions. (i) Comprehensive case-based reasoning framework. Case-based reasoning 

approaches [1] leverage hierarchical experience traces, including planning trajectories and structured tool invocation logs, and employ advanced retrieval and selection mechanisms to enable fine-grained, context-specific adaptation. (ii) Autonomous workflow evolution promises enhanced efficiency and flexibility. By representing agent workflows as mutable structures such as trees or graphs, researchers can apply evolutionary algorithms or adaptive graph optimisation to explore, modify and refine execution plans dynamically. Pursuing both directions in tandem will strengthen the robustness of frameworks and reduce the reliance on data and computation resources. 

# 7 Conclusion

LLM-driven Deep Research Agents represent an emerging paradigm for automated research support, integrating advanced techniques such as iterative information retrieval, long-form content generation, autonomous planning, and sophisticated tool utilisation. In this survey, we systematically reviewed recent advancements in DR agents, categorising existing methodologies into prompt-based, fine-tuning-based, and reinforcement learning-based approaches from the perspectives of information retrieval and report generation. Non-parametric methods utilise LLMs and carefully designed prompts to achieve efficient and cost-effective deployment, making them suitable for rapid prototyping. In contrast, fine-tuning and reinforcement learning approaches explicitly optimise model parameters, significantly enhancing the agents’ reasoning and decision-making capabilities. We also examined prominent DR agent systems developed by industry leaders and discussed their technical implementations, strengths, and limitations. 

# Limitation

Despite notable progress, key challenges remain, including limited generalisation across diverse tasks, inflexible task workflows, difficulty in integrating granular external tools, and substantial computational complexity associated with advanced planning and optimisation. Future research directions thus emphasise broader and more flexible tool integration through modular capability providers (e.g., Operator-based architectures), development of asynchronous and parallel planning frameworks (e.g., Directed Acyclic Graph-based approaches), and sophisticated end-to-end optimisation methods for multi-agent architectures, such as hierarchical reinforcement learning or multi-stage finetuning pipelines. With continued advancements in LLM technologies, DR agents have significant potential to transform complex research workflows, enhance human productivity, and drive innovation across academic and industrial domains. 

# References



[1] Agnar Aamodt and Enric Plaza. Case-based reasoning: Foundational issues, methodological variations, and system approaches. AI communications, 7(1):39–59, 1994. 





[2] McQuilkin Adam, Kamath Anirudh, McGuire Sean, and Chance Sophie. Browserbase: A web browser for your ai, 2024. 





[3] Jina AI. Jina ai. https://jina.ai/deepsearch/, 2025. Accessed: 2025-04-28. 





[4] Kortix AI. Suna: Open source generalist ai agent. https://github.com/kortix-ai/suna, 2025. Accessed: 2025-05-28. 





[5] Renat Aksitov, Sobhan Miryoosefi, Zonglin Li, Daliang Li, Sheila Babayan, Kavya Kopparapu, Zachary Fisher, Ruiqi Guo, Sushant Prakash, Pranesh Srinivasan, Manzil Zaheer, Felix Yu, and Sanjiv Kumar. Rest meets react: Self-improvement for multi-step reasoning llm agent, 2023. 





[6] Mohammad Aliannejadi, Zahra Abbasiantaeb, Shubham Chatterjee, Jeffery Dalton, and Leif Azzopardi. Trec ikat 2023: The interactive knowledge assistance track overview. arXiv preprint arXiv:2401.01330, 2024. 





[7] Akari Asai, Zeqiu Wu, Yizhong Wang, Avirup Sil, and Hannaneh Hajishirzi. Self-rag: Learning to retrieve, generate, and critique through self-reflection. In The Twelfth International Conference on Learning Representations, 2023. 





[8] Agent Team at InclusionAI. Aworld: Enabling agent self-improvement through interactive experience with dynamic runtime, 2025. 





[9] Yushi Bai, Xin Lv, Jiajie Zhang, Yuze He, Ji Qi, Lei Hou, Jie Tang, Yuxiao Dong, and Juanzi Li. Longalign: A recipe for long context alignment of large language models. arXiv preprint arXiv:2401.18058, 2024. 





[10] Yushi Bai, Shangqing Tu, Jiajie Zhang, Hao Peng, Xiaozhi Wang, Xin Lv, Shulin Cao, Jiazheng Xu, Lei Hou, Yuxiao Dong, et al. Longbench v2: Towards deeper understanding and reasoning on realistic long-context multitasks. arXiv preprint arXiv:2412.15204, 2024. 





[11] Tom B. Brown, Benjamin Mann, Nick Ryder, Melanie Subbiah, Jared Kaplan, Prafulla Dhariwal, Arvind Neelakantan, Pranav Shyam, Girish Sastry, Amanda Askell, Sandhini Agarwal, Ariel Herbert-Voss, Gretchen Krueger, Tom Henighan, Rewon Child, Aditya Ramesh, Daniel M. Ziegler, Jeffrey Wu, Clemens Winter, Christopher Hesse, Mark Chen, Eric Sigler, Mateusz Litwin, Scott Gray, Benjamin Chess, Jack Clark, Christopher Berner, Sam McCandlish, Alec Radford, Ilya Sutskever, and Dario Amodei. Language models are few-shot learners. arXiv preprint arXiv:2005.14165, 2020. 





[12] CAMEL-AI.org. Owl: Optimized workforce learning for general multi-agent assistance in real-world task automation. https://github.com/camel-ai/owl, 2025. Accessed: 2025-03-07. 





[13] Hyungjoo Chae, Yongho Song, Kai Tzu-iunn Ong, Taeyoon Kwon, Minjin Kim, Youngjae Yu, Dongha Lee, Dongyeop Kang, and Jinyoung Yeo. Dialogue chain-of-thought distillation for commonsense-aware conversational agents. arXiv preprint arXiv:2310.09343, 2023. 





[14] Jun Shern Chan, Neil Chowdhury, Oliver Jaffe, James Aung, Dane Sherburn, Evan Mays, Giulio Starace, Kevin Liu, Leon Maksin, Tejal Patwardhan, Lilian Weng, and Aleksander M ˛adry. Mle-bench: Evaluating machine learning agents on machine learning engineering, 2025. 





[15] Jingxuan Chen, Derek Yuen, Bin Xie, Yuhao Yang, Gongwei Chen, Zhihao Wu, Li Yixing, Xurui Zhou, Weiwen Liu, Shuai Wang, Kaiwen Zhou, Rui Shao, Liqiang Nie, Yasheng Wang, Jianye Hao, Jun Wang, and Kun Shao. Spa-bench: A comprehensive benchmark for smartphone agent evaluation. arXiv preprint arXiv:2410.15164, 2025. 





[16] Mingyang Chen, Tianpeng Li, Haoze Sun, Yijie Zhou, Chenzheng Zhu, Fan Yang, Zenan Zhou, Weipeng Chen, Haofen Wang, Jeff Z Pan, et al. Learning to reason with search for llms via reinforcement learning. arXiv preprint arXiv:2503.19470, 2025. 





[17] Yiqun Chen, Lingyong Yan, Weiwei Sun, Xinyu Ma, Yi Zhang, Shuaiqiang Wang, Dawei Yin, Yiming Yang, and Jiaxin Mao. Improving retrieval-augmented generation through multi-agent reinforcement learning. arXiv preprint arXiv:2501.15228, 2025. 





[18] Zhixun Chen, Ming Li, Yuxuan Huang, Yali Du, Meng Fang, and Tianyi Zhou. Atlas: Agent tuning via learning critical steps. arXiv preprint arXiv:2503.02197, 2025. 





[19] Ziru Chen, Shijie Chen, Yuting Ning, Qianheng Zhang, Boshi Wang, Botao Yu, Yifei Li, Zeyi Liao, Chen Wei, Zitong Lu, Vishal Dey, Mingyi Xue, Frazier N. Baker, Benjamin Burns, Daniel Adu-Ampratwum, Xuhui Huang, Xia Ning, Song Gao, Yu Su, and Huan Sun. Scienceagentbench: Toward rigorous assessment of language agents for data-driven scientific discovery. arXiv preprint arXiv:2410.05080, 2025. 





[20] DanielWalnut. Deerflow. https://github.com/bytedance/deer-flow, 2025. Accessed: 2025-05-28. 





[21] Pradeep Dasigi, Kyle Lo, Iz Beltagy, Arman Cohan, Noah A Smith, and Matt Gardner. A dataset of informationseeking questions and answers anchored in research papers. arXiv preprint arXiv:2105.03011, 2021. 





[22] Guanting Dong, Yifei Chen, Xiaoxi Li, Jiajie Jin, Hongjin Qian, Yutao Zhu, Hangyu Mao, Guorui Zhou, Zhicheng Dou, and Ji-Rong Wen. Tool-star: Empowering llm-brained multi-tool reasoner via reinforcement learning. arXiv preprint arXiv:2505.16410, 2025. 





[23] Angela Fan, Yacine Jernite, Ethan Perez, David Grangier, Jason Weston, and Michael Auli. Eli5: Long form question answering. arXiv preprint arXiv:1907.09190, 2019. 





[24] Wenqi Fan, Yujuan Ding, Liangbo Ning, Shijie Wang, Hengyun Li, Dawei Yin, Tat-Seng Chua, and Qing Li. A survey on rag meeting llms: Towards retrieval-augmented large language models. In Proceedings of the 30th ACM SIGKDD Conference on Knowledge Discovery and Data Mining, pages 6491–6501, 2024. 





[25] Zhangyin Feng, Xiaocheng Feng, Dezhi Zhao, Maojin Yang, and Bing Qin. Retrieval-generation synergy augmented large language models. In ICASSP 2024-2024 IEEE International Conference on Acoustics, Speech and Signal Processing (ICASSP), pages 11661–11665. IEEE, 2024. 





[26] Adam Fourney, Gagan Bansal, Hussein Mozannar, Cheng Tan, Eduardo Salinas, Erkang, Zhu, Friederike Niedtner, Grace Proebsting, Griffin Bassman, Jack Gerrits, Jacob Alber, Peter Chang, Ricky Loynd, Robert West, Victor Dibia, Ahmed Awadallah, Ece Kamar, Rafah Hosn, and Saleema Amershi. Magentic-one: A generalist multi-agent system for solving complex tasks. arXiv preprint arXiv:2411.04468, 2024. 





[27] Tong Fu, Liquan Chen, Zhangjie Fu, Kunliang Yu, and Yu Wang. Ccnet: Cnn model with channel attention and convolutional pooling mechanism for spatial image steganalysis. Journal of Visual Communication and Image Representation, 88:103633, 2022. 





[28] Yunfan Gao, Yun Xiong, Xinyu Gao, Kangxiang Jia, Jinliu Pan, Yuxi Bi, Yi Dai, Jiawei Sun, Haofen Wang, and Haofen Wang. Retrieval-augmented generation for large language models: A survey. arXiv preprint arXiv:2312.10997, 2, 2023. 





[29] Xinyu Geng, Peng Xia, Zhen Zhang, Xinyu Wang, Qiuchen Wang, Ruixue Ding, Chenxi Wang, Jialong Wu, Yida Zhao, Kuan Li, et al. Webwatcher: Breaking new frontiers of vision-language deep research agent. arXiv preprint arXiv:2508.05748, 2025. 





[30] Anna Goldie, Azalia Mirhoseini, Hao Zhou, Irene Cai, and Christopher D Manning. Synthetic data generation & multi-step rl for reasoning & tool use. arXiv preprint arXiv:2504.04736, 2025. 





[31] Peiyuan Gong, Jiamian Li, and Jiaxin Mao. Cosearchagent: a lightweight collaborative search agent with large language models. In Proceedings of the 47th International ACM SIGIR Conference on Research and Development in Information Retrieval, pages 2729–2733, 2024. 





[32] Google. Announcing the Agent2Agent Protocol (A2A), 2025. Accessed: 2025-04-22. 





[33] Google Team. Introducing gemini deep research. https://gemini.google/overview/deep-research/, 2025. Accessed: 2025-04-06. 





[34] Juraj Gottweis, Wei-Hung Weng, Alexander Daryin, Tao Tu, Anil Palepu, Petar Sirkovic, Artiom Myaskovsky, Felix Weissenberger, Keran Rong, Ryutaro Tanno, et al. Towards an ai co-scientist. arXiv preprint arXiv:2502.18864, 2025. 





[35] Antoine Grosnit, Alexandre Maraval, James Doran, Giuseppe Paolo, Albert Thomas, Refinath Shahul Hameed Nabeezath Beevi, Jonas Gonzalez, Khyati Khandelwal, Ignacio Iacobacci, Abdelhakim Benechehab, Hamza Cherkaoui, Youssef Attia El-Hili, Kun Shao, Jianye Hao, Jun Yao, Balazs Kegl, Haitham Bou-Ammar, and Jun Wang. Large language models orchestrating structured reasoning achieve kaggle grandmaster level, 2024. 





[36] Xinyan Guan, Jiali Zeng, Fandong Meng, Chunlei Xin, Yaojie Lu, Hongyu Lin, Xianpei Han, Le Sun, and Jie Zhou. Deeprag: Thinking to retrieval step by step for large language models. arXiv preprint arXiv:2502.01142, 2025. 





[37] Siyuan Guo, Cheng Deng, Ying Wen, Hechang Chen, Yi Chang, and Jun Wang. Ds-agent: Automated data science by empowering large language models with case-based reasoning, 2024. 





[38] Siyuan Guo, Huiwu Liu, Xiaolong Chen, Yuming Xie, Liang Zhang, Tao Han, Hechang Chen, Yi Chang, and Jun Wang. Optimizing case-based reasoning system for functional test script generation with large language models. arXiv preprint arXiv:2503.20576, 2025. 





[39] H2O.ai. H2o.ai, 2025. Accessed: 2025-04-28. 





[40] Rujun Han, Yanfei Chen, Zoey CuiZhu, Lesly Miculicich, Guan Sun, Yuanjun Bi, Weiming Wen, Hui Wan, Chunfeng Wen, Solène Maître, et al. Deep researcher with test-time diffusion. arXiv preprint arXiv:2507.16075, 2025. 





[41] Xanh Ho, Anh-Khoa Duong Nguyen, Saku Sugawara, and Akiko Aizawa. Constructing a multi-hop qa dataset for comprehensive evaluation of reasoning steps. arXiv preprint arXiv:2011.01060, 2020. 





[42] Sheryl Hsu, Omar Khattab, Chelsea Finn, and Archit Sharma. Grounding by trying: Llms with reinforcement learning-enhanced retrieval. arXiv preprint arXiv:2410.23214, 2024. 





[43] Jian Hu. Reinforce $^ { + + }$ : A simple and efficient approach for aligning large language models. arXiv preprint arXiv:2501.03262, 2025. 





[44] Jerry Huang, Siddarth Madala, Risham Sidhu, Cheng Niu, Julia Hockenmaier, and Tong Zhang. Rag-rl: Advancing retrieval-augmented generation via rl and curriculum learning. arXiv preprint arXiv:2503.12759, 2025. 





[45] Qian Huang, Jian Vora, Percy Liang, and Jure Leskovec. Mlagentbench: Evaluating language agents on machine learning experimentation. arXiv preprint arXiv:2310.03302, 2024. 





[46] Tatsuro Inaba, Hirokazu Kiyomaru, Fei Cheng, and Sadao Kurohashi. Multitool-cot: Gpt-3 can use multiple external tools with chain of thought prompting. arXiv preprint arXiv:2305.16896, 2023. 





[47] Shayekh Bin Islam, Md Asib Rahman, KSM Hossain, Enamul Hoque, Shafiq Joty, and Md Rizwan Parvez. Open-rag: Enhanced retrieval-augmented reasoning with open-source large language models. arXiv preprint arXiv:2410.01782, 2024. 





[48] Gautier Izacard, Patrick Lewis, Maria Lomeli, Lucas Hosseini, Fabio Petroni, Timo Schick, Jane Dwivedi-Yu, Armand Joulin, Sebastian Riedel, and Edouard Grave. Atlas: Few-shot learning with retrieval augmented language models. Journal of Machine Learning Research, 24(251):1–43, 2023. 





[49] Pengcheng Jiang. Deepretrieval: Powerful query generation for information retrieval with reinforcement learning. arXiv preprint arXiv:2503.00223, 2025. 





[50] Zhengbao Jiang, Frank F Xu, Luyu Gao, Zhiqing Sun, Qian Liu, Jane Dwivedi-Yu, Yiming Yang, Jamie Callan, and Graham Neubig. Active retrieval augmented generation. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing, pages 7969–7992, 2023. 





[51] Carlos E. Jimenez, John Yang, Alexander Wettig, Shunyu Yao, Kexin Pei, Ofir Press, and Karthik Narasimhan. Swe-bench: Can language models resolve real-world github issues? arXiv preprint arXiv:2310.06770, 2024. 





[52] Bowen Jin, Hansi Zeng, Zhenrui Yue, Dong Wang, Hamed Zamani, and Jiawei Han. Search-r1: Training llms to reason and leverage search engines with reinforcement learning. arXiv preprint arXiv:2503.09516, 2025. 





[53] Mandar Joshi, Eunsol Choi, Daniel S. Weld, and Luke Zettlemoyer. Triviaqa: A large scale distantly supervised challenge dataset for reading comprehension. arXiv preprint arXiv:1705.03551, 2017. 





[54] Gangwoo Kim, Sungdong Kim, Byeongguk Jeon, Joonsuk Park, and Jaewoo Kang. Tree of clarifications: Answering ambiguous questions with retrieval-augmented large language models. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing, pages 996–1009, 2023. 





[55] Tom Kwiatkowski, Jennimaria Palomaki, Olivia Redfield, Michael Collins, Ankur Parikh, Chris Alberti, Danielle Epstein, Illia Polosukhin, Jacob Devlin, Kenton Lee, et al. Natural questions: a benchmark for question answering research. Transactions of the Association for Computational Linguistics, 7:453–466, 2019. 





[56] Chengpeng Li, Mingfeng Xue, Zhenru Zhang, Jiaxi Yang, Beichen Zhang, Xiang Wang, Bowen Yu, Binyuan Hui, Junyang Lin, and Dayiheng Liu. Start: Self-taught reasoner with tools. arXiv preprint arXiv:2503.04625, 2025. 





[57] Kuan Li, Zhongwang Zhang, Huifeng Yin, Liwen Zhang, Litu Ou, Jialong Wu, Wenbiao Yin, Baixuan Li, Zhengwei Tao, Xinyu Wang, et al. Websailor: Navigating super-human reasoning for web agent. arXiv preprint arXiv:2507.02592, 2025. 





[58] Xiaoxi Li, Guanting Dong, Jiajie Jin, Yuyao Zhang, Yujia Zhou, Yutao Zhu, Peitian Zhang, and Zhicheng Dou. Search-o1: Agentic search-enhanced large reasoning models. arXiv preprint arXiv:2501.05366, 2025. 





[59] Xiaoxi Li, Jiajie Jin, Guanting Dong, Hongjin Qian, Yutao Zhu, Yongkang Wu, Ji-Rong Wen, and Zhicheng Dou. Webthinker: Empowering large reasoning models with deep research capability. https://www.notion.so/WebThinker-Empowering-Large-Reasoning-Models-with-Deep-Research-Capability-d13158a27d924a4b9df7f9ab94066b64, 2025. Notion Blog. 





[60] Xinbin Liang, Jinyu Xiang, Zhaoyang Yu, Jiayi Zhang, and Sirui Hong. Openmanus: An open-source framework for building general ai agents. https://github.com/mannaandpoem/OpenManus, 2025. Accessed: 2025- 04-06. 





[61] Jingyang Lin, Andy Wong, Tian Xia, Shenghua He, Hui Wei, Mei Han, and Jiebo Luo. Facilitating long context understanding via supervised chain-of-thought reasoning. arXiv preprint arXiv:2502.13127, 2025. 





[62] Xi Victoria Lin, Xilun Chen, Mingda Chen, Weijia Shi, Maria Lomeli, Richard James, Pedro Rodriguez, Jacob Kahn, Gergely Szilvasy, Mike Lewis, et al. Ra-dit: Retrieval-augmented dual instruction tuning. In The Twelfth International Conference on Learning Representations, 2023. 





[63] Chris Lu, Cong Lu, Robert Tjarko Lange, Jakob Foerster, Jeff Clune, and David Ha. The ai scientist: Towards fully automated open-ended scientific discovery. arXiv preprint arXiv:2408.06292, 2024. 





[64] Ali Maatouk, Fadhel Ayed, Nicola Piovesan, Antonio De Domenico, Merouane Debbah, and Zhi-Quan Luo. Teleqna: A benchmark dataset to assess large language models telecommunications knowledge, 2023. 





[65] Alex Mallen, Akari Asai, Victor Zhong, Rajarshi Das, Daniel Khashabi, and Hannaneh Hajishirzi. When not to trust language models: Investigating effectiveness of parametric and non-parametric memories, 2023. 





[66] Manus AI. Leave it to manus. https://manus.im/, 2025. Accessed: 2025-04-06. 





[67] Martin. Agenticseek: Private, local manus alternative. https://github.com/Fosowl/agenticSeek, 2025. Accessed: 2025-05-28. 





[68] Grégoire Mialon, Clémentine Fourrier, Thomas Wolf, Yann LeCun, and Thomas Scialom. Gaia: a benchmark for general ai assistants. In The Twelfth International Conference on Learning Representations, 2023. 





[69] Microsoft. Introducing researcher and analyst in microsoft 365 copilot. https://www.microsoft.com/enus/microsoft-365/blog/2025/03/25/introducing-researcher-and-analyst-in-microsoft-365-copilot/, March 2025. Accessed: 2025-04-28. 





[70] Moonshot AI. Kimi-researcher: End-to-end RL training for emerging agentic capabilities. https:// moonshotai.github.io/Kimi-Researcher/, June 2025. Accessed: 2025-08-18. 





[71] Niklas Muennighoff, Qian Liu, Armel Zebaze, Qinkai Zheng, Binyuan Hui, Terry Yue Zhuo, Swayam Singh, Xiangru Tang, Leandro von Werra, and Shayne Longpre. Octopack: Instruction tuning code large language models. arXiv preprint arXiv:2308.07124, 2024. 





[72] Magnus Müller and Gregor Žunic. Browser use: Enable ai to control your browser, 2024. ˇ 





[73] Reiichiro Nakano, Jacob Hilton, Suchir Balaji, Jeff Wu, Long Ouyang, Christina Kim, Christopher Hesse, Shantanu Jain, Vineet Kosaraju, William Saunders, et al. Webgpt: Browser-assisted question-answering with human feedback. arXiv preprint arXiv:2112.09332, 2021. 





[74] Deepak Nathani, Lovish Madaan, Nicholas Roberts, Nikolay Bashlykov, Ajay Menon, Vincent Moens, Amar Budhiraja, Despoina Magka, Vladislav Vorotilov, Gaurav Chaurasia, Dieuwke Hupkes, Ricardo Silveira Cabral, Tatiana Shavrina, Jakob Foerster, Yoram Bachrach, William Yang Wang, and Roberta Raileanu. Mlgym: A new framework and benchmark for advancing ai research agents. arXiv preprint arXiv:2502.14499, 2025. 





[75] Nouswise. Nouswise — the research agent grounded in the information you trust the most. https://nouswise. com/homepage, 2025. Accessed: 2025-08-18. 





[76] Alexander Novikov, Ngân Vu, Marvin Eisenberger, Emilien Dupont, Po-Sen Huang, Adam Zsolt Wagner, Sergey Shirobokov, Borislav Kozlovskii, Francisco JR Ruiz, Abbas Mehrabian, et al. Alphaevolve: A coding agent for scientific and algorithmic discovery. Google DeepMind, 2025. 





[77] OpenAI. Introducing chatgpt agent: bridging research and action. https://openai.com/index/ introducing-chatgpt-agent/, July 2025. Accessed: 2025-08-18. 





[78] OpenAI. Introducing deep research. https://openai.com/index/introducing-deep-research/, 2025. Accessed: 2025-04-06. 





[79] OpenAI Team. Browsecomp: a benchmark for browsing agents. https://openai.com/index/browsecomp/, 2025. Accessed: 2025-04-29. 





[80] Jie Ouyang, Ruiran Yan, Yucong Luo, Mingyue Cheng, Qi Liu, Zirui Liu, Shuo Yu, and Daoyu Wang. Training powerful llm agents with end-to-end reinforcement learning. https://github.com/0russwest0/Agent-R1, 2025. Accessed: 2025-04-06. 





[81] Perplexity Team. Introducing perplexity deep research. https://www.perplexity.ai/hub/blog/ introducing-perplexity-deep-research, 2025. Accessed: 2025-04-06. 





[82] Long Phan, Alice Gatti, Ziwen Han, Nathaniel Li, Josephina Hu, Hugh Zhang, Chen Bo Calvin Zhang, Mohamed Shaaban, John Ling, Sean Shi, et al. Humanity’s last exam. arXiv preprint arXiv:2501.14249, 2025. 





[83] Cheng Qian, Emre Can Acikgoz, Qi He, Hongru Wang, Xiusi Chen, Dilek Hakkani-Tür, Gokhan Tur, and Heng Ji. Toolrl: Reward is all tool learning needs, 2025. 





[84] Jiahao Qiu, Xuan Qi, Tongcheng Zhang, Xinzhe Juan, Jiacheng Guo, Yifu Lu, Yimin Wang, Zixin Yao, Qihan Ren, Xun Jiang, et al. Alita: Generalist agent enabling scalable agentic reasoning with minimal predefinition and maximal self-evolution. arXiv preprint arXiv:2505.20286, 2025. 





[85] Changle Qu, Sunhao Dai, Xiaochi Wei, Hengyi Cai, Shuaiqiang Wang, Dawei Yin, Jun Xu, and Ji-Rong Wen. Tool learning with large language models: A survey. Frontiers of Computer Science, 19(8):198343, 2025. 





[86] Rafael Rafailov, Archit Sharma, Eric Mitchell, Christopher D Manning, Stefano Ermon, and Chelsea Finn. Direct preference optimization: Your language model is secretly a reward model. Advances in neural information processing systems, 36:53728–53741, 2023. 





[87] Timo Schick, Jane Dwivedi-Yu, Roberto Dessì, Roberta Raileanu, Maria Lomeli, Luke Zettlemoyer, Nicola Cancedda, and Thomas Scialom. Toolformer: Language models can teach themselves to use tools, 2023. 





[88] Samuel Schmidgall and Michael Moor. Agentrxiv: Towards collaborative autonomous research. arXiv preprint arXiv:2503.18102, 2025. 





[89] Samuel Schmidgall, Yusheng Su, Ze Wang, Ximeng Sun, Jialian Wu, Xiaodong Yu, Jiang Liu, Zicheng Liu, and Emad Barsoum. Agent laboratory: Using llm agents as research assistants. arXiv preprint arXiv:2501.04227, 2025. 





[90] John Schulman, Filip Wolski, Prafulla Dhariwal, Alec Radford, and Oleg Klimov. Proximal policy optimization algorithms. arXiv preprint arXiv:1707.06347, 2017. 





[91] Yijia Shao, Yucheng Jiang, Theodore A. Kanell, Peter Xu, Omar Khattab, and Monica S. Lam. Assisting in writing wikipedia-like articles from scratch with large language models. arXiv preprint arXiv:2402.14207, 2024. 





[92] Zhihong Shao, Peiyi Wang, Qihao Zhu, Runxin Xu, Junxiao Song, Xiao Bi, Haowei Zhang, Mingchuan Zhang, YK Li, Y Wu, et al. Deepseekmath: Pushing the limits of mathematical reasoning in open language models. arXiv preprint arXiv:2402.03300, 2024. 





[93] Zhili Shen, Chenxin Diao, Pavlos Vougiouklis, Pascual Merita, Shriram Piramanayagam, Damien Graux, Dandan Tu, Zeren Jiang, Ruofei Lai, Yang Ren, et al. Gear: Graph-enhanced agent for retrieval-augmented generation. arXiv preprint arXiv:2412.18431, 2024. 





[94] Wenxuan Shi, Haochen Tan, Chuqiao Kuang, Xiaoguang Li, Xiaozhe Ren, Chen Zhang, Hanting Chen, Yasheng Wang, Lifeng Shang, Fisher Yu, et al. Pangu deepdiver: Adaptive search intensity scaling via open-web reinforcement learning. arXiv preprint arXiv:2505.24332, 2025. 





[95] Aditi Singh, Abul Ehtesham, Saket Kumar, and Tala Talaei Khoei. Agentic retrieval-augmented generation: A survey on agentic rag. arXiv preprint arXiv:2501.09136, 2025. 





[96] Huatong Song, Jinhao Jiang, Yingqian Min, Jie Chen, Zhipeng Chen, Wayne Xin Zhao, Lei Fang, and Ji-Rong Wen. R1-searcher: Incentivizing the search capability in llms via reinforcement learning. arXiv preprint arXiv:2503.05592, 2025. 





[97] Zirui Song, Yaohang Li, Meng Fang, Zhenhao Chen, Zecheng Shi, Yuan Huang, and Ling Chen. Mmac-copilot: Multi-modal agent collaboration operating system copilot. arXiv preprint arXiv:2404.18074, 2024. 





[98] Jared Spataro. Introducing Researcher and Analyst in Microsoft 365 Copilot, March 2025. 





[99] Md Arafat Sultan, Jatin Ganhotra, and Ramón Fernandez Astudillo. Structured chain-of-thought prompting for few-shot generation of content-grounded qa conversations. arXiv preprint arXiv:2402.11770, 2024. 





[100] Shuang Sun*, Huatong Song*, Yuhao Wang, Ruiyang Ren, Jinhao Jiang, Junjie Zhang, Lei Fang, Zhongyuan Wang, and Ji-Rong Wen Wayne Xin Zhao. Simpledeepsearcher: Deep information seeking via web-powered reasoning trajectory synthesis. 2025. 





[101] Jiabin Tang, Tianyu Fan, and Chao Huang. Autoagent: A fully-automated and zero-code framework for llm agents, 2025. 





[102] Xiangru Tang, Yuliang Liu, Zefan Cai, Yanjun Shao, Junjie Lu, Yichi Zhang, Zexuan Deng, Helan Hu, Kaikai An, Ruijun Huang, Shuzheng Si, Sheng Chen, Haozhe Zhao, Liang Chen, Yan Wang, Tianyu Liu, Zhiwei Jiang, Baobao Chang, Yin Fang, Yujia Qin, Wangchunshu Zhou, Yilun Zhao, Arman Cohan, and Mark Gerstein. Ml-bench: Evaluating large language models and agents for machine learning tasks on repository-level code. arXiv preprint arXiv:2311.09835, 2024. 





[103] Xiangru Tang, Tianrui Qin, Tianhao Peng, Ziyang Zhou, Daniel Shao, Tingting Du, Xinming Wei, Peng Xia, Fang Wu, He Zhu, et al. Agent kb: Leveraging cross-domain experience for agentic problem solving. arXiv preprint arXiv:2507.06229, 2025. 





[104] Zhengwei Tao, Jialong Wu, Wenbiao Yin, Junkai Zhang, Baixuan Li, Haiyang Shen, Kuan Li, Liwen Zhang, Xinyu Wang, Yong Jiang, et al. Webshaper: Agentically data synthesizing via information-seeking formalization. arXiv preprint arXiv:2507.15061, 2025. 





[105] Fellou AI Team. Fellou: The world’s first agentic browser, 2025. 





[106] Genspark Team. Genspark super agent with enhancements in mixture of agents, 2025. 





[107] MiroMind Foundation Model Team and MiroMind AI Infra Team. Mirorl: An mcp-first reinforcement learning framework for deep research agent. https://github.com/MiroMindAI/MiroRL, 2025. 





[108] Perplexity Team. Comet: A browser for agentic search by perplexity, 2024. 





[109] Kaiyang Wan, Honglin Mu, Rui Hao, Haoran Luo, Tianle Gu, and Xiuying Chen. A cognitive writing perspective for constrained long-form text generation. arXiv preprint arXiv:2502.12568, 2025. 





[110] Junyang Wang, Haiyang Xu, Haitao Jia, Xi Zhang, Ming Yan, Weizhou Shen, Ji Zhang, Fei Huang, and Jitao Sang. Mobile-agent-v2: Mobile device operation assistant with effective navigation via multi-agent collaboration. arXiv preprint arXiv:2406.01014, 2024. 





[111] Keheng Wang, Feiyu Duan, Peiguang Li, Sirui Wang, and Xunliang Cai. Llms know what they need: Leveraging a missing information guided framework to empower retrieval-augmented generation. arXiv preprint arXiv:2404.14043, 2024. 





[112] Liang Wang, Haonan Chen, Nan Yang, Xiaolong Huang, Zhicheng Dou, and Furu Wei. Chain-of-retrieval augmented generation. arXiv preprint arXiv:2501.14342, 2025. 





[113] Xindi Wang, Mahsa Salmani, Parsa Omidi, Xiangyu Ren, Mehdi Rezagholizadeh, and Armaghan Eshaghi. Beyond the limits: A survey of techniques to extend the context length in large language models. arXiv preprint arXiv:2402.02244, 2024. 





[114] Yaoxiang Wang, Zhiyong Wu, Junfeng Yao, and Jinsong Su. Tdag: A multi-agent framework based on dynamic task decomposition and agent generation. Neural Networks, page 107200, 2025. 





[115] Jason Wei, Nguyen Karina, Hyung Won Chung, Yunxin Joy Jiao, Spencer Papay, Amelia Glaese, John Schulman, and William Fedus. Measuring short-form factuality in large language models. arXiv preprint arXiv:2411.04368, 2024. 





[116] Jason Wei, Xuezhi Wang, Dale Schuurmans, Maarten Bosma, Brian Ichter, Fei Xia, Ed Chi, Quoc Le, and Denny Zhou. Chain-of-thought prompting elicits reasoning in large language models, 2023. 





[117] Yixuan Weng, Minjun Zhu, Guangsheng Bao, Hongbo Zhang, Jindong Wang, Yue Zhang, and Linyi Yang. Cycleresearcher: Improving automated research via automated review. arXiv preprint arXiv:2411.00816, 2024. 





[118] Hjalmar Wijk, Tao Lin, Joel Becker, Sami Jawhar, Neev Parikh, Thomas Broadley, Lawrence Chan, Michael Chen, Josh Clymer, Jai Dhyani, Elena Ericheva, Katharyn Garcia, Brian Goodrich, Nikola Jurkovic, Megan Kinniment, Aron Lajko, Seraphina Nix, Lucas Sato, William Saunders, Maksym Taran, Ben West, and Elizabeth Barnes. Re-bench: Evaluating frontier ai r&d capabilities of language model agents against human experts. arXiv preprint arXiv:2411.15114, 2024. 





[119] Ryan Wong, Jiawei Wang, Junjie Zhao, Li Chen, Yan Gao, Long Zhang, Xuan Zhou, Zuo Wang, Kai Xiang, Ge Zhang, et al. Widesearch: Benchmarking agentic broad info-seeking. arXiv preprint arXiv:2508.07999, 2025. 





[120] Jialong Wu, Baixuan Li, Runnan Fang, Wenbiao Yin, Liwen Zhang, Zhengwei Tao, Dingchu Zhang, Zekun Xi, Gang Fu, Yong Jiang, et al. Webdancer: Towards autonomous information seeking agency. arXiv preprint arXiv:2505.22648, 2025. 





[121] Jialong Wu, Wenbiao Yin, Yong Jiang, Zhenglin Wang, Zekun Xi, Runnan Fang, Linhai Zhang, Yulan He, Deyu Zhou, Pengjun Xie, et al. Webwalker: Benchmarking llms in web traversal. arXiv preprint arXiv:2501.07572, 2025. 





[122] Junde Wu, Jiayuan Zhu, and Yuyuan Liu. Agentic reasoning: Reasoning llms with tools for the deep research. arXiv preprint arXiv:2502.04644, 2025. 





[123] Shirley Wu, Shiyu Zhao, Qian Huang, Kexin Huang, Michihiro Yasunaga, Kaidi Cao, Vassilis N. Ioannidis, Karthik Subbian, Jure Leskovec, and James Zou. Avatar: Optimizing llm agents for tool usage via contrastive reasoning. arXiv preprint arXiv:2406.11200, 2024. 





[124] xAI Team. Introducing grok deepsearch. https://x.ai/news/grok-3, 2025. Accessed: 2025-04-06. 





[125] Tianbao Xie, Danyang Zhang, Jixuan Chen, Xiaochuan Li, Siheng Zhao, Ruisheng Cao, Toh Jing Hua, Zhoujun Cheng, Dongchan Shin, Fangyu Lei, Yitao Liu, Yiheng Xu, Shuyan Zhou, Silvio Savarese, Caiming Xiong, Victor Zhong, and Tao Yu. Osworld: Benchmarking multimodal agents for open-ended tasks in real computer environments. arXiv preprint arXiv:2404.07972, 2024. 





[126] Zhilin Yang, Peng Qi, Saizheng Zhang, Yoshua Bengio, William W. Cohen, Ruslan Salakhutdinov, and Christopher D. Manning. Hotpotqa: A dataset for diverse, explainable multi-hop question answering. arXiv preprint arXiv:1809.09600, 2018. 





[127] Shunyu Yao, Jeffrey Zhao, Dian Yu, Nan Du, Izhak Shafran, Karthik Narasimhan, and Yuan Cao. React: Synergizing reasoning and acting in language models. arXiv preprint arXiv:2210.03629, 2023. 





[128] Ori Yoran, Samuel Joseph Amouyal, Chaitanya Malaviya, Ben Bogin, Ofir Press, and Jonathan Berant. Assistantbench: Can web agents solve realistic and time-consuming tasks? arXiv preprint arXiv:2407.15711, 2024. 





[129] Haofei Yu, Zhaochen Hong, Zirui Cheng, Kunlun Zhu, Keyang Xuan, Jinwei Yao, Tao Feng, and Jiaxuan You. Researchtown: Simulator of human research community. arXiv preprint arXiv:2412.17767, 2024. 





[130] Qiying Yu, Zheng Zhang, Ruofei Zhu, Yufeng Yuan, Xiaochen Zuo, Yu Yue, Weinan Dai, Tiantian Fan, Gaohong Liu, Lingjun Liu, et al. Dapo: An open-source llm reinforcement learning system at scale. arXiv preprint arXiv:2503.14476, 2025. 





[131] Tian Yu, Shaolei Zhang, and Yang Feng. Auto-rag: Autonomous retrieval-augmented generation for large language models. arXiv preprint arXiv:2411.19443, 2024. 





[132] Saber Zerhoudi and Michael Granitzer. Personarag: Enhancing retrieval-augmented generation systems with user-centric agents. arXiv preprint arXiv:2407.09394, 2024. 





[133] Liang Zhang, Katherine Jijo, Spurthi Setty, Eden Chung, Fatima Javid, Natan Vidra, and Tommy Clifford. Enhancing large language model performance to answer questions and extract information more accurately. arXiv preprint arXiv:2402.01722, 2024. 





[134] Zhebin Zhang, Xinyu Zhang, Yuanhang Ren, Saijiang Shi, Meng Han, Yongkang Wu, Ruofei Lai, and Zhao Cao. Iag: Induction-augmented generation framework for answering reasoning questions. arXiv preprint arXiv:2311.18397, 2023. 





[135] Yuxiang Zheng, Dayuan Fu, Xiangkun Hu, Xiaojie Cai, Lyumanshan Ye, Pengrui Lu, and Pengfei Liu. Deepresearcher: Scaling deep research via reinforcement learning in real-world environments. arXiv preprint arXiv:2504.03160, 2025. 





[136] Yuxiang Zheng, Shichao Sun, Lin Qiu, Dongyu Ru, Cheng Jiayang, Xuefeng Li, Jifan Lin, Binjie Wang, Yun Luo, Renjie Pan, et al. Openresearcher: Unleashing ai for accelerated scientific research. arXiv preprint arXiv:2408.06941, 2024. 





[137] Zhipu AI. Autoglm rumination. https://autoglm-research.zhipuai.cn/, 2025. Accessed: 2025-04-06. 





[138] Huichi Zhou, Yihang Chen, Siyuan Guo, Xue Yan, Kin Hei Lee, Zihan Wang, Ka Yiu Lee, Guchun Zhang, Kun Shao, Linyi Yang, et al. Agentfly: Fine-tuning llm agents without fine-tuning llms. arXiv preprint arXiv:2508.16153, 2025. 





[139] Shuyan Zhou, Frank F. Xu, Hao Zhu, Xuhui Zhou, Robert Lo, Abishek Sridhar, Xianyi Cheng, Tianyue Ou, Yonatan Bisk, Daniel Fried, Uri Alon, and Graham Neubig. Webarena: A realistic web environment for building autonomous agents. arXiv preprint arXiv:2307.13854, 2024. 





[140] He Zhu, Tianrui Qin, King Zhu, Heyuan Huang, Yeyi Guan, Jinxiang Xia, Yi Yao, Hanhao Li, Ningning Wang, Pai Liu, et al. Oagents: An empirical study of building effective agents. arXiv preprint arXiv:2506.15741, 2025. 





[141] Minjun Zhu, Yixuan Weng, Linyi Yang, and Yue Zhang. Deepreview: Improving llm-based paper review with human-like deep thinking process. arXiv preprint arXiv:2503.08569, 2025. 

', '{"title": "DEEP RESEARCH AGENTS: A SYSTEMATIC EXAMINATION AND ROADMAP", "sections": [{"level": 1, "title": "ABSTRACT"}, {"level": 1, "title": "1 Introduction"}, {"level": 1, "title": "2 Background and Preliminaries", "children": [{"level": 2, "title": "2.1 Advances in Reasoning and Tool Integration"}, {"level": 2, "title": "2.2 Advances in Retrieval-Augmented Generation and Agentic Retrieval"}, {"level": 2, "title": "2.3 Model Context Protocol and Agent-to-Agent Policy"}]}, {"level": 1, "title": "3 Deep Research: Search Engine, Tool Use, Workflow, Tuning, Non-parametric Continual Learning", "children": [{"level": 2, "title": "3.1 Search Engine: API vs. Browser"}, {"level": 2, "title": "3.2 Tool Use: Empowering Agents with Extended Functionalities"}, {"level": 2, "title": "3.3 Architecture and Workflow", "children": [{"level": 3, "title": "3.3.1 Static vs. Dynamic Workflows"}, {"level": 3, "title": "3.3.2 Dynamic Workflows: Planning Strategies"}, {"level": 3, "title": "3.3.3 Dynamic Workflows: Single-Agent vs. Multi-Agent"}, {"level": 3, "title": "3.3.4 Memory Mechanism for Long-Context Optimisation"}]}, {"level": 2, "title": "3.4 Tuning: Beyond Prompting toward Capability Enhancement", "children": [{"level": 3, "title": "3.4.1 SFT-based Optimization"}, {"level": 3, "title": "3.4.2 Reinforcement Learning-based Optimisation"}]}, {"level": 2, "title": "3.5 Non-parametric Continual Learning"}]}, {"level": 1, "title": "4 Industrial Applications of Deep Research Agents", "children": [{"level": 2, "title": "4.1 Open AI Deep Research"}, {"level": 2, "title": "4.2 Gemini Deep Research"}, {"level": 2, "title": "4.3 Perplexity Deep Research"}, {"level": 2, "title": "4.4 Grok DeepSearch"}, {"level": 2, "title": "4.5 Microsoft Copilot Researcher and Analyst"}, {"level": 2, "title": "4.6 Qwen Deep Research"}, {"level": 2, "title": "4.7 Kimi K2 Deep Research"}]}, {"level": 1, "title": "5 Benchmarks for DR Agent"}, {"level": 1, "title": "6 Challenge and Future Directions"}, {"level": 1, "title": "7 Conclusion"}, {"level": 1, "title": "Limitation"}, {"level": 1, "title": "References"}]}', '2026-03-15 20:13:32.896576', 'success', NULL);
INSERT INTO "public"."doc_parsed" VALUES (4, 4, '# DeepResearcher: Scaling Deep Research via Reinforcement Learning in Real-world Environments

Yuxiang Zheng $^{1,2,3*}$ Dayuan Fu $^{2,3*}$ Xiangkun Hu $^{2*}$ 

Xiaojie Cai $^{1,3}$ Lyumanshan Ye $^{1,3}$ Pengrui Lu $^{1,3}$ Pengfei Liu $^{1,2,3\dagger}$ 

$^{1}$ Shanghai Jiao Tong University $^{2}$ Shanghai Innovation Institute 

3Generative AI Research Lab (GAIR) 

catchiz.1@sjtu.edu.cn, fdy@bupt.edu.cn, xkhu17@fudan.edu.cn 

pengfei@sjtu.edu.cn 

# Abstract

Large Language Models (LLMs) with web search capabilities show significant potential for deep research, yet current methods—brittle prompt engineering or RAG-based reinforcement learning in controlled environments—fail to capture real-world complexities. In this paper, we introduce DeepResearcher, the first comprehensive framework for end-to-end training of LLM-based deep research agents through scaling reinforcement learning (RL) in real-world environments with authentic web search interactions. Unlike RAG approaches reliant on fixed corpora, DeepResearcher trains agents to navigate the noisy, dynamic open web. We implement a specialized multi-agent architecture where browsing agents extract relevant information from various webpage structures and overcoming significant technical challenges. Extensive experiments on open-domain research tasks demonstrate that DeepResearcher achieves substantial improvements of up to 28.9 points over prompt engineering-based baselines and up to 7.2 points over RAG-based RL agents. Our qualitative analysis reveals emergent cognitive behaviors from end-to-end RL training, such as planning, cross-validation, self-reflection for research redirection, and maintain honesty when unable to find definitive answers. Our results highlight that end-to-end training in real-world web environments is fundamental for developing robust research capabilities aligned with real-world applications. The source code for DeepResearcher is released at: https://github.com/GAIR-NLP/DeepResearcher. 

# 1 Introduction

The emergence of Large Language Models (LLMs) has fundamentally transformed the landscape of artificial intelligence, enabling increasingly autonomous problem-solving capabilities. When 

equipped with external tools such as web search and code execution (Li et al., 2025c), these models can tackle complex research tasks that previously required significant human workload and expertise. Notable examples include Gemini and OpenAI Deep Research (Google, 2024; OpenAI, 2025), Grok3''s DeeperSearch (xAI, 2025), and open-source projects like MetaGPT (Hong et al., 2024), OpenManus (Liang et al., 2025), and OWL agents (CAMEL-AI.org, 2025). While impressive commercial products exist, reproducible frameworks for systematically developing robust research agents remain largely elusive. 

Recent advances suggest that reinforcement learning (RL) offers a promising path forward for improving LLM capabilities. Studies by Guo et al. (2025) and Team et al. (2025) demonstrate that scaling reinforcement learning for LLMs on math and coding tasks (Li et al., 2025b) substantially improves their reasoning abilities. Current open-source efforts to integrate RL with information retrieval, such as Search-R1 (Jin et al., 2025), R1-Searcher (Song et al., 2025), and ReSearch (Chen et al., 2025), have primarily focused on Retrieval-Augmented Generation (RAG) using static, local text corpora. While these approaches provide valuable insights, they fundamentally fail to capture the dynamic, unpredictable nature of real-world web search environments. RAG systems also fail to account for the substantial noise, variability in search quality, and the challenges of navigating diverse web content formats and structures. 

In this work, we present the first comprehensive study of RL scaling for LLM agents operating with real-world web search capabilities. Our approach, DeepResearcher, trains agents to interact directly with live search engines, thereby learning to handle the inherent variability and complexity of the open web. By training in genuine web environments rather than controlled simulations, our system develops robust capabilities for handling 

the unpredictable nature of real-world information retrieval and synthesis. 

DeepResearcher represents a significant departure from prompt-based and RAG-based methods. Its novelty lies in integrating several critical techniques, previously explored only in isolation, for end-to-end training in real-world web environments: 

- Scaling RL for Deep Research: In contrast to prompt and SFT-based methods, we directly scale RL training for deep research tasks using solely outcome-based rewards. 

Real-world Environment: Unlike controlled RAG environments, real web search presents noisy, unstructured, and heterogeneous information sources that require sophisticated filtering and relevance assessment capabilities. 

- End-to-end Training: We train the model end-to-end without human priors, enabling the agent to discover its own problem-solving strategies. This end-to-end approach significantly departs from human-designed workflows. 

- **Addressing Implementation Challenges:** Training with real web search introduces unique challenges absent in RAG settings, including stringently managing search API rate limits, handling network latency, addressing anti-crawling mechanisms, and processing diverse webpage structures. 

- Multi-agent Framework: Our approach employs a specialized multi-agent architecture where dedicated browsing agents extract relevant information from entire webpages—a stark contrast to RAG-based systems that simply retrieve and present pre-processed text passages. 

To conclude, we make the following contributions: 

- We introduce DeepResearcher, a novel RL framework specifically designed for training LLM agents in real web environments, enabling iterative reasoning and search, and synthesizing diverse web information to answer open-domain questions. 

- We overcome numerous technical challenges inherent to RL scaling with real-world web search, making this the first successful implementation of RL at scale in genuine web environments. 

- We conduct extensive experiments across open-domain tasks, demonstrating significant improvements over prompt-engineered baselines and RAG-based RL approaches. 

- We perform detailed analysis examining emergent behaviors from DeepResearcher''s end-to-end RL scaling, finding that the system can formulate plans, cross-checks answers, reflects on its process, and is honest about limitations. 

- We open-source our complete training framework to the research community, fostering transparency and enabling further advancements in deep research systems. 

# 2 Related Work

In this section, we review existing approaches to enhance large language models'' (LLMs) ability to access external knowledge with search. We categorize these methods into prompt-based and training-based search agents. Furthermore, we examine the operational environments in which these methods are deployed—namely, local retrieval-augmented generation (RAG) frameworks and real-world, dynamic web search settings—and situate our approach within this broader technological and methodological landscape. 

# 2.1 Prompt-Based Search Agents

Many current approaches rely on manually crafted workflows that specify how LLMs should interact with external knowledge sources (Wang et al., 2024a). Recent works such as OpenResearcher (Zheng et al., 2024), AirRAG (Feng et al., 2025), IterDRAG (Yue et al., 2024b), Plan*RAG (Verma et al., 2025), Search-o1 (Li et al., 2025a) and Open Deep Search (Alzubi et al., 2025) have demonstrated significant progress in search capabilities through designed workflows. 

# 2.2 Training-Based Search Agents

Recent developments have moved beyond manually crafted prompts toward training-based approaches that enable more flexible and adaptive search behaviors. 

Supervised Fine-Tuning (SFT) SFT for RAG have become an enhanced alternative to manual optimization of RAG workflows (Yu et al., 2024; Wang et al., 2024b). For example, CoRAG (Wang et al., 2024b) utilizes Monte Carlo Tree Search (MCTS) to dynamically select the best document blocks under budget constraints. 

Reinforcement Learning (RL) End-to-end reinforcement learning offers a promising alternative that effectively unlocks LLMs'' inherent capabilities. By late 2024, large language models 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/f55a9e27756b70799462e46309cf8e1363417e1b80d5c950cdcaf2022cc060e8.jpg)



Figure 1: The trajectory of a single sample from a batch of questions processed in parallel by a distributed cluster. Each question undergoes multiple independent rollouts with distinct memory. Upper-left: Displays the batch of questions and their concurrent rollout paths. Upper-right: Shows the browsing agent retrieving web pages via URLs, processing them sequentially to incrementally extract relevant information. Bottom: Details the iterative decision-making steps, from initial query formulation and search to snippet retrieval, further reasoning, browsing, information extraction, and answer generation.


achieved remarkable breakthroughs in reasoning capability enhancement through RL (Guo et al., 2025; OpenAI, 2024; Team et al., 2025). Recent research has explored applying RL to external knowledge retrieval, with systems such as Search-R1 (Jin et al., 2025), ReSearch (Chen et al., 2025), and R1-Searcher (Song et al., 2025) abandoning manually specified cues in favor of models that autonomously develop reasoning during the retrieval process. 

# 2.3 Training Environments

Training environments for search agents can be broadly categorized into two types: 

Local RAG Environments Current mainstream local RAG frameworks (Gao et al., 2023; Yu et al., 2024) rely on pre-built fixed knowledge repositories, resulting in three critical issues: information timeliness decay, poor domain adaptability, and storage efficiency bottlenecks. While RAG-based RL approaches like Search-R1 (Jin et al., 2025), Research (Chen et al., 2025), and R1-Searcher (Song et al., 2025) have made progress, their experimental validation remains primarily confined to predefined knowledge bases and similarity-based search, restricting the search space and potentially limiting 

generalizability to real-world applications. 

Real-World Web Search Environments Web search-based methods (Schick et al., 2023; Qin et al., 2023) integrate open search engines with LLMs to access and utilize real-time information. However, search-based methods requiring external system participation are seldom trained end-to-end, with research often gravitating toward optimization through manually crafted or heuristically designed workflows (Wang et al., 2024a). 

We introduce a novel approach that uniquely integrates reinforcement learning (RL) with training in genuine web environments. Unlike prior RL methods reliant on static, local corpora, our agents directly interact with live search engines. This enables them to navigate the open web''s variability, developing robust capabilities for real-world information retrieval and synthesis, thereby addressing limitations of prompt-based and RAG-confined methods by learning adaptive search strategies. 

# 3 Methodology

In this section, we describe the methodology used to train an agent capable of solving problems with web search in dynamic real-world environments. 

# 3.1 Deep Research Trajectory

In a typical DeepResearcher''s trajectory, it conducts reasoning and tool selection based on the user question and accumulated observations iteratively as illustrated in Figure 1. 

Reasoning We restrict DeepResearcher to do reasoning before taking action. Each reasoning process is wrapped in a <think> tag following the setting in DeepSeek-R1 (Guo et al., 2025). 

Web Search Tool DeepResearcher invokes the web search tool by generating a JSON-formatted request with the tool name web_search and the search queries as arguments. Search results are returned in a structured format comprising title, URL, and snippet for each webpage. The current implementation employs a fixed top-k (e.g., 10) value for search results retrieval. Future work could explore LLM-driven dynamic parameter optimization for enhanced search efficacy. 

Web Browsing Agent The web browsing agent provides reliable, question-relevant, and incrementally updated information in to the DeepResearcher system. Specifically, the agent maintains a short-term memory repository for each query. Upon receiving a web browse request, it processes the first-page segment of the URL in the request. Subsequently, the web browsing agent takes two actions based on the query, historical memory, and the newly acquired webpage content: (1) determining whether to continue reading the next URL/segment or stop and (2) appending relevant information to the short-term memory. Once the agent decides to discontinue further browsing, it compiles all newly added information from the short-term memory and returns it to the DeepResearcher system. The "specialized multi-agent architecture" mentioned earlier is an internal implementation detail of this web browse tool. It is designed to effectively process information from webpages, but the primary agent''s policy—which decides when and how to use this tool—is learned end-to-end without being constrained by this internal structure. Thus, the tool''s architecture does not impose human priors on the agent''s learned decision-making process. 

Answering When the model determines it has sufficient information to answer the question, it generates a final response within <answer></answer> as the answer to return to the user. 

# 3.2 Addressing Challenges in Dynamic Real-World Web Environments

In our open, real-world web setting, several unique challenges arise that necessitate specialized solutions. The following sections detail our strategies for managing these issues effectively. 

Challenge I: High-concurrency requests at a single moment The implementation of GRPO results in a large number of sampling iterations, leading to a significant volume of search queries and webpage crawling operations (e.g., 4096), causing long delays. To resolve this issue, we created a distributed CPU server cluster with 50 nodes, specifically designed to manage the Tool requests generated during the RL rollout process. Each server is tasked with handling a portion of these requests, processing search results, and crawling webpages based on the URLs identified by the language model for further reading. It is noteworthy that the use of a 50-node cluster was determined by the hardware resources available to us; the core technical requirement is high-concurrency I/O to manage simultaneous web requests, which could also be achieved with a smaller number of more powerful servers with high-bandwidth connections. 

Challenge II: Managing Web Crawling and API Limitations During the crawling phase, the system frequently encounters anti-crawl measures deployed by web servers, which may return irrelevant content or fail to respond entirely. Similarly, when interfacing with search engines or LLM APIs, restrictions such as provider rate limits (e.g. 200 per second) can arise. To mitigate these issues, we implemented a robust retry mechanism that effectively addresses exceptions encountered during API calls or webpage crawling. In addition, we introduced a caching strategy for search results: if an identical search query is made within a predetermined period (e.g., 7 days), the system retrieves the results from the cache. This approach not only reduces the API call frequency but also helps manage the associated costs, particularly for expensive services like the Google Search API. 

Challenge III: Optimizing Information Extraction via a Multi-Agent Approach We employ a multi-agent framework wherein a dedicated reading agent is tasked with extracting pertinent information from crawled webpages. Given that many webpages are lengthy and may contain limited relevant content, these pages are partitioned 

into smaller segments. The reading agent mimics human behavior by processing content sequentially from the first page. Under the assumption that if the initial segments of a URL predominantly contain irrelevant information, the webpage is likely unproductive and can be skipped, this method enables more efficient resource allocation and improves overall information extraction accuracy. Specifically, when handling multiple URLs, our browse tool internally utilizes several "Reading Agents" in parallel, each processing a different webpage. A "Synthesis Agent" then merges the findings into a cohesive output for the main agent. 

# 3.3 RL Training Framework

Our approach utilizes Reinforcement Learning (RL) to train the agent. This section outlines how we employ the RL framework to train the agent and the tools used within it. 

GRPO In this work, we adopt the Group Relative Policy Optimization (GRPO) algorithm. GRPO optimizes the current policy $\pi_{\theta}$ by leveraging a reference policy $\pi_{\theta_{\mathrm{ref}}}$ along with a set of rollouts generated by an existing policy $\pi_{\theta_{\mathrm{old}}}$ . Specifically, given $G$ rollouts 

$$
\tau = \left\{y _ {i} \right\} _ {i = 1} ^ {G} \sim \pi_ {\theta_ {\text {o l d}}} (\cdot | x) \tag {1}
$$

(with each input $x \sim D$ , where $D$ is the experience distribution), GRPO estimates the baseline using these trajectories instead of training a separate critic. The current policy is then optimized by maximizing the following objective function: 

$$
\begin{array}{l} \mathcal {J} (\theta) = \mathbb {E} _ {x \sim \mathcal {D}, \{y _ {i} \} _ {i = 1} ^ {G} \sim \pi_ {\theta_ {\mathrm {o l d}} (\cdot | x)}} \frac {1}{G} \sum_ {i = 1} ^ {G} \left[ \min \left(\frac {\pi_ {\theta} (y _ {i} | x)}{\pi_ {\theta_ {\mathrm {o l d}}} (y _ {i} | x)} A _ {i}, \right. \right. \\ \operatorname {c l i p} \left(\frac {\pi_ {\theta} \left(y _ {i} \mid x\right)}{\pi_ {\theta_ {\mathrm {o l d}}} \left(y _ {i} \mid x\right)}, 1 - \epsilon , 1 + \epsilon\right) A _ {i}\bigg) - \beta \mathbb {D} _ {\mathrm {K L}} \left(\pi_ {\theta} \left| \left| \pi_ {\theta_ {\mathrm {r e f}}}\right) \right] \right. \tag {2} \\ \end{array}
$$

Masking Observations The output of the tool is an observation, not the desired result that the model is expected to produce. Therefore, we apply masking to prevent the observation from being involved in training, allowing only the model''s responses to contribute to the training process. 

# 3.4 Reward

Rewards play a crucial role during the training process and guide the agent in continuously improving its performance. This section defines the reward structure and describes how the agent''s behavior is rewarded. 

We employ the F1 score as our primary reward metric due to our utilization of open-domain QA datasets with short-answer ground truth. For future work involving long-form answers, more sophisticated reward may be necessary, as noted in the Deep Research system card (OpenAI, 2025). The reward is determined by the following conditions: 

$$
\text {r e w a r d} = \left\{ \begin{array}{l l} - 1 & \text {i f f o r m a t i s i n c o r r e c t} \\ \text {F 1 s c o r e} & \text {i f f o r m a t i s c o r r e c t} \end{array} \right.
$$

- Format Penalty: If the format is incorrect (e.g., missing tags or structural errors), the agent receives a penalty of -1. 

- F1 Reward: If the format is correct, the reward is based on the word-level F1 score, which measures the accuracy of the generated answer compared to the reference answer. A higher F1 score results in a higher reward. 

# 4 Experiments

# 4.1 Experimental Setups

# 4.1.1 Training Data Curation

To ensure our models genuinely learn search strategies and to mitigate data contamination, we meticulously curated training data from existing open-domain QA benchmarks. A rigorous two-stage filtering process eliminated low-quality questions and instances where the base model could answer without search, yielding a final dataset of 80,000 examples deliberately emphasizing multi-hop scenarios (75% of the total). The complete methodology for data curation is detailed in Appendix A. 

# 4.1.2 Model and Hyperparameters

We adopt Qwen2.5-7B-Instruct<sup>1</sup> (Qwen et al., 2025) as the backbone model for our training pipeline. The training is conducted using the verl framework<sup>2</sup>. At each training step, we sample 256 prompts, and sample 16 rollouts for each prompt. Each rollout consists of up to 10 tool calls followed by a final answer step. The training is performed with a mini-batch size of 4,096, which means one rollout stage will backprop for one time. 

# 4.2 Evaluation and Results

# 4.2.1 Benchmarks

To thoroughly evaluate model performance across both in-domain (ID) and out-of-domain (OOD) set-

tings, we construct a diverse benchmark suite spanning a range of open-domain QA challenges. For in-domain evaluation, we include the dev sets of NQ (Kwiatkowski et al., 2019), TQ (Joshi et al., 2017), HotpotQA (Yang et al., 2018), and 2Wiki (Ho et al., 2020) as mentioned in Section A. 

For out-of-domain evaluation, we introduce three datasets that differ significantly in question style and information distribution: MuSiQue (Trivedi et al., 2022), Bamboogle (Press et al., 2022), and PopQA (Mallen et al., 2022). These datasets test the model''s generalization ability beyond the training domain. 

To ensure a fair and balanced evaluation, we randomly sample 512 examples from the development sets of NQ, TQ, HotpotQA, 2Wiki, MuSiQue, and PopQA as well as all 125 samples from Bamboogle''s development set. This sampling strategy allows us to assess model robustness across a broad range of topics and reasoning requirements. 

# 4.2.2 Baselines

To comprehensively evaluate the effectiveness and practical utility of DeepResearcher, we compare it against the following baseline methods: 

- CoT Only: Employs Chain-of-Thought (CoT) reasoning for answer generation without access to external reference context. 

- RAG: Integrates CoT reasoning with retrieved reference context to guide the answer generation process. 

- Search-o1: A multi-step reasoning baseline in which the model generates search queries or intermediate answers. 

- Search-o1 + Web Search: Extends Search-o1 by enabling open web access through real-time search APIs and URL Browse. 

- ReAct-style Agent: A zero-shot prompting baseline where the base model is instructed to use the provided web search and browsing tools to answer questions. 

- Search-r1: A RL method for question answering that utilizes a retriever to search Wikipedia during training and inference. 

- R1-Searcher: Conducts Bing searches by appending "site:en.wikipedia.org" to queries and summarizes the top three search results. DeepResearcher differs from this approach in three key aspects: (1) DeepResearcher is trained with real-world environment; (2) DeepResearcher does not restrict the search space to a specific domain; and (3) Our method allows the model to autonomously select URLs rather than compulsorily summarizing the top three search results. 

- DeepResearcher (Local RAG): A direct ablation of our proposed method. This agent is trained using the exact same RL framework as DeepResearcher but is restricted to a local RAG environment instead of the live web. 

# 4.2.3 Evaluation Metrics

Rule-based Metrics We evaluate the performance of the model using the F1 score that aligns with the reward for training. Both ground-truth and predicted answers are normalized by converting to lowercase and removing all punctuation before computing the metrics. 

Model-based Evaluation Rule-based evaluation doesn''t suit long-form responses, so we adopt a model-based evaluation (MBE) approach using LLM-as-a-Judge (Zheng et al., 2023). Specifically, we prompt GPT-4o-mini (Hurst et al., 2024) to assess the model''s answer against the question and ground truth answer, and label it as either "correct" or "incorrect." The MBE score is then computed as the accuracy of these judgments. (Zheng et al., 2023) The full prompt is provided in Appendix C.3. 

# 4.2.4 Main Results

Table 1 and Table 2 present the main results of DeepResearcher and the baselines in-domain and out-of-domain, respectively. From these results, we draw the following observations: 

DeepResearcher outperforms the baselines within training domains. As shown in Table 1, DeepResearcher achieves the highest performance across the four datasets when measured by the more reliable MBE metric, outperforming baselines by a substantial margin on TQ and 2Wiki. While Search-r1-base shows comparable MBE results on NQ and HotpotQA, it''s important to note that Search-r1-base was specifically trained and evaluated using a local RAG system with direct access to the relevant 

<table><tr><td rowspan="2">Method</td><td rowspan="2">Inference Environment</td><td colspan="2">NQ</td><td colspan="2">TQ</td><td colspan="2">HotpotQA</td><td colspan="2">2Wiki</td></tr><tr><td>F1</td><td>MBE</td><td>F1</td><td>MBE</td><td>F1</td><td>MBE</td><td>F1</td><td>MBE</td></tr><tr><td colspan="10">Prompt Based</td></tr><tr><td>CoT</td><td>Local RAG</td><td>19.8</td><td>32.0</td><td>45.6</td><td>48.2</td><td>24.4</td><td>27.9</td><td>26.4</td><td>27.3</td></tr><tr><td>CoT + RAG</td><td>Local RAG</td><td>42.0</td><td>59.6</td><td>68.9</td><td>75.8</td><td>37.1</td><td>43.8</td><td>24.4</td><td>24.8</td></tr><tr><td>Search-o1*</td><td>Local RAG</td><td>34.5</td><td>57.4</td><td>52.6</td><td>61.1</td><td>31.6</td><td>40.8</td><td>28.6</td><td>32.8</td></tr><tr><td>Search-o1</td><td>Web Search</td><td>32.4</td><td>55.1</td><td>58.9</td><td>69.5</td><td>33.0</td><td>42.4</td><td>30.9</td><td>37.7</td></tr><tr><td>ReAct-style Agent</td><td>Web Search</td><td>22.7</td><td>39.6</td><td>41.9</td><td>49.2</td><td>19.7</td><td>26.2</td><td>17.6</td><td>17.6</td></tr><tr><td colspan="10">Training Based</td></tr><tr><td>Search-r1-base</td><td>Local RAG</td><td>45.4</td><td>60.0</td><td>71.9</td><td>76.2</td><td>55.9</td><td>63.0</td><td>44.6</td><td>47.9</td></tr><tr><td>Search-r1-instruct</td><td>Local RAG</td><td>33.1</td><td>49.6</td><td>44.7</td><td>49.2</td><td>45.7</td><td>52.5</td><td>43.4</td><td>48.8</td></tr><tr><td>R1-Searcher</td><td>Web Search</td><td>35.4</td><td>52.3</td><td>73.1</td><td>79.1</td><td>44.8</td><td>53.1</td><td>59.4</td><td>65.8</td></tr><tr><td>DeepResearcher (Local RAG)</td><td>Local RAG</td><td>29.5</td><td>46.3</td><td>51.9</td><td>55.5</td><td>29.4</td><td>35.4</td><td>26.3</td><td>27.5</td></tr><tr><td>DeepResearcher</td><td>Web Search</td><td>39.6</td><td>61.9</td><td>78.4</td><td>85.0</td><td>52.8</td><td>64.3</td><td>59.7</td><td>66.6</td></tr></table>


Table 1: In-domain results on four datasets (NQ, TQ, HotpotQA, 2Wiki), evaluated by F1 and MBE metrics. DeepResearcher outperforms all baseline methods in MBE and shows competitive performance in F1, particularly excelling on TQ and 2Wiki. It is worth noting that Search-r1-base was trained and evaluated in a local RAG environment with direct access to the relevant Wikipedia corpus, while DeepResearcher must navigate the entire Internet to find information, achieving excellent results despite facing a more realistic and challenging scenario.


Wikipedia corpus. In contrast, DeepResearcher must navigate the entire Internet to find relevant information, representing a more realistic and significantly more challenging scenario even though the answers ultimately come from Wikipedia. 

DeepResearcher demonstrates exceptional generalization to novel domains. As revealed in Table 2, DeepResearcher consistently outperforms all other baselines across three OOD datasets. This indicates that the model successfully learns generalizable skills for reasoning, searching, and synthesizing information from different sources through RL scaling, rather than merely adapting to specific training distributions. 

Importance of Real-World Environment in Training The most direct evidence comes from our ablation study comparing DeepResearcher with its counterpart trained in a local RAG environment. The results show a dramatic drop in performance for "DeepResearcher (Local RAG)" across all datasets, which empirically validates our central thesis: the noisy and dynamic nature of the live web is a necessary training ground for fostering generalizable and robust research capabilities. This advantage is further exemplified on benchmarks like Bamboogle, which requires knowledge beyond Wikipedia''s coverage. On this dataset, not only does DeepResearcher significantly outperform local RAG-based methods, but it also surpasses R1-Searcher even when the latter is granted web access at inference time. These results collectively demonstrate that end-to-end training in a real-world environment develops robust information retrieval 

and synthesis skills that cannot be replicated in controlled, static settings. 

# 5 Analysis

# 5.1 Training Dynamics

- Performance gradually scaling with reinforcement learning: Figure 2 (a) present the evaluation of F1 scores, across different training steps. The F1 score 0.375, and gradually increases to around 0.55 demonstrating a consistent upward trend. This result indicates the progressive improvement of the model''s performance in reinforcement learning. 

- Training leads to increased reasoning steps in hard question: Figure 2 (b) illustrates the average number of turns required for different reasoning hops. The general trend indicates that as the training progresses, the required number of tool calls also increases across different difficulty levels. Unlike the other three settings, the 4-hop setting continues to exhibit an increasing trend even after 34 steps. This suggests that the model is still learning to retrieve more information when dealing with more difficult questions. 

- Continuous learning makes long response without saturation: Figure 2 (c) presents the length of responses for different reasoning hops. The response lengths also increase with reasoning complexity. However, all four settings show a sustained upward trend, indicating that the model continues to expand 

<table><tr><td rowspan="2">Method</td><td rowspan="2">Inference Environment</td><td colspan="2">Musique</td><td colspan="2">Bamboogle</td><td colspan="2">PopQA</td></tr><tr><td>F1</td><td>MBE</td><td>F1</td><td>MBE</td><td>F1</td><td>MBE</td></tr><tr><td>Prompt Based</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr><tr><td>CoT</td><td>Local RAG</td><td>8.5</td><td>7.4</td><td>22.1</td><td>21.6</td><td>17.0</td><td>15.0</td></tr><tr><td>CoT + RAG</td><td>Local RAG</td><td>10.0</td><td>10.0</td><td>25.4</td><td>27.2</td><td>46.9</td><td>48.8</td></tr><tr><td>Search-o1*</td><td>Local RAG</td><td>16.8</td><td>21.3</td><td>35.8</td><td>38.4</td><td>36.9</td><td>42.4</td></tr><tr><td>Search-o1</td><td>Web Search</td><td>14.7</td><td>19.7</td><td>46.6</td><td>53.6</td><td>38.3</td><td>43.4</td></tr><tr><td>ReAct-style Agent</td><td>Web Search</td><td>8.9</td><td>10.0</td><td>34.4</td><td>36.8</td><td>19.1</td><td>20.5</td></tr><tr><td>Training Based</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr><tr><td>Search-r1-base</td><td>Local RAG</td><td>26.7</td><td>27.5</td><td>56.5</td><td>57.6</td><td>43.2</td><td>47.0</td></tr><tr><td>Search-r1-instruct</td><td>Local RAG</td><td>26.5</td><td>28.3</td><td>45.0</td><td>47.2</td><td>43.0</td><td>44.5</td></tr><tr><td>R1-Searcher</td><td>Web Search</td><td>22.8</td><td>25.6</td><td>64.8</td><td>65.6</td><td>42.7</td><td>43.4</td></tr><tr><td>DeepResearcher (Local RAG)</td><td>Local RAG</td><td>12.7</td><td>12.5</td><td>42.7</td><td>46.4</td><td>23.2</td><td>23.4</td></tr><tr><td>DeepResearcher</td><td>Web Search</td><td>27.1</td><td>29.3</td><td>71.0</td><td>72.8</td><td>48.5</td><td>52.7</td></tr></table>


Table 2: This table shows the performance of different methods on three out-of-domain datasets (Musique, Bamboogle, PopQA), evaluated by F1 and MBE metrics. DeepResearcher leads in both F1 and MBE on all datasets, demonstrating strong generalization capabilities compared to other methods. Notably, unlike the other datasets, Bamboogle''s corpus is not entirely derived from Wikipedia pages.


its reasoning processes during training. This further supports the idea that the model adapts to increasingly complex queries by generating more detailed outputs like double-check, refinement, planning, etc. 

# 5.2 Case Study

Figures 3 and 4 present four cases illustrating the model''s behavior after reinforcement learning. From these examples, we identify several key behavioral patterns: 

- Behavior I: Planning when addressing multi-hop questions: As demonstrated on the left side of Figure 3, DeepResearcher is capable of making plans and dynamically adjusting it throughout the reasoning process. Notably, the model can merge steps when appropriate, indicating that planning abilities emerge naturally without the necessity of SFT on explicit planning data (Yue et al., 2024a). 

- Behavior II: Cross-validation before finalizing its answers: As observed on the right side of Figure 3, DeepResearcher identifies the correct answer during its first tool call. However, rather than immediately committing to this result, it proceeds to verify its accuracy through subsequent steps. This cautious approach enhances the reliability of model''s responses, ensuring greater robustness in final predictions. 

- Behavior III: Reflection when observations deviate from expectations: The left side of Figure 4 illustrates the model''s ability to reflect on its search process. When the retrieved 

information does not fully align with the question, DeepResearcher recognizes this discrepancy based on environmental feedback and refines its search query in subsequent tool calls. This reflective capability is essential for preventing the model from getting stuck (Fu et al., 2025) in reasoning, enabling it to enhance overall problem-solving efficiency. 

- Behavior IV: Honesty by acknowledging its limitations: A reliable model should minimize hallucinations and provide honest responses when it lacks the necessary knowledge (Yang et al., 2024). We observe that DeepResearcher is capable of recognizing when it has not found the correct answer and appropriately declines to provide a response. This behavior is beneficial, however, current question-answering evaluation metrics do not yet account for this aspect of model reliability. 

# 6 Conclusion

In conclusion, we presents DeepResearcher, a groundbreaking approach for scaling reinforcement learning in LLMs to operate effectively in real-world web search environments. Unlike approaches dependent on static knowledge bases, DeepResearcher trains agents to interact with live search engines, allowing them to navigate the inherent complexity and variability of the open web. This direct engagement with dynamic search environments leads to substantial improvements in task completion and deep research capabilities. 

Through an end-to-end training methodology, DeepResearcher addresses real-world challenges like network latency while enabling agents to autonomously develop robust problem-solving strate 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/e77d44e785cceb3f1eb619bd998168116f61686bf1bf55bd2a1b8b3d14cd5193.jpg)



(a)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/1648b3133e88dfd271d97b83930c14dca2ebf521ca7c9a48377225076605bcd6.jpg)



(b)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/7965aa3552f9a0ee119437421e8b7b8aea068cff19609847b4bf4c621080e189.jpg)



(c)



Figure 2: Training dynamics of F1, turns and response length. In this figure, we find the performance gradually scaling with reinforcement learning. The numbers of tool calls and responses also increase.


gies and cultivates cognitive behaviors such as planning, reflection, and cross-validation through its multi-agent architecture. The success of Deep-Researcher represents a significant milestone for LLM agents, showcasing how scaling reinforcement learning in real-world environments can unlock superior research performance and pave the way for more adaptive systems capable of tackling complex, open-domain problems. 

# Limitations

While DeepResearcher demonstrates significant advancements, this study has certain limitations. Firstly, our experiments were conducted using a 7B parameter model (Qwen2.5-7B-Instruct). Although this model size yielded substantial improvements, we have not yet explored the potential performance gains or emergent capabilities that might arise from applying the DeepResearcher framework to significantly larger language models. Future work could investigate the scalability of our approach with more powerful base models. 

Secondly, the reward mechanism employed in this study, while effective for the open-domain QA tasks with short, factual answers (relying on F1 scores and a format penalty), may not adequately address the complexities of more open-ended deep research inquiries. Such inquiries often involve ill-defined problem spaces, require extensive synthesis of diverse information, and may result in long-form, nuanced outputs where traditional metrics like F1 are less applicable. Consequently, a critical area for future exploration is the development of training methodologies and reward structures specifically tailored to deep research on these more open questions. 

# Ethical Considerations

The advanced information retrieval and reasoning capabilities of DeepResearcher, while powerful, could potentially be misused by malicious actors for tasks such as infringing upon individual privacy by accessing sensitive information without consent. We emphasize that the DeepResearcher framework is intended for beneficial research, and developers must ensure its responsible and ethical application, adhering to privacy and legal standards. 

# Acknowledgments

The authors would like to thank the anonymous reviewers for their suggestions and feedback on the work. This work was partially funded by the National Natural Science Foundation of China (62476168), National High Technology Research and Development Program of China (2015AA015408), Shanghai Science and Technology Development Funds (14ZR1403200). This project is supported by SJTU SEIEE - ByteDance Large Language Model Joint Laboratory. 

# References



Salaheddin Alzubi, Creston Brooks, Purva Chiniya, Edoardo Contente, Chiara von Gerlach, Lucas Irwin, Yihan Jiang, Arda Kaz, Windsor Nguyen, Sewoong Oh, and 1 others. 2025. Open deep search: Democratizing search with open-source reasoning agents. arXiv preprint arXiv:2503.20201. 





CAMEL-AI.org. 2025. Owl: Optimized workforce learning for general multi-agent assistance in real-world task automation. https://github.com/camel-ai/owl. Accessed: 2025-03-07. 





Mingyang Chen, Tianpeng Li, Haoze Sun, Yijie Zhou, Chenzheng Zhu, Haofen Wang, Jeff Z. Pan, Wen 





Zhang, Huajun Chen, Fan Yang, Zenan Zhou, and Weipeng Chen. 2025. Research: Learning to reason with search for llms via reinforcement learning. Preprint, arXiv:2503.19470. 





Wenfeng Feng, Chuzhan Hao, Yuewei Zhang, Jingyi Song, and Hao Wang. 2025. Airrag: Activating intrinsic reasoning for retrieval augmented generation via tree-based search. arXiv preprint arXiv:2501.10053. 





Dayuan Fu, Keqing He, Yejie Wang, Wentao Hong, Zhuoma Gongque, Weihao Zeng, Wei Wang, Jinggang Wang, Xunliang Cai, and Weiran Xu. 2025. Agentrefine: Enhancing agent generalization through refinement tuning. arXiv preprint arXiv:2501.01702. 





Yunfan Gao, Yun Xiong, Xinyu Gao, Kangxiang Jia, Jinliu Pan, Yuxi Bi, Yi Dai, Jiawei Sun, Haofen Wang, and Haofen Wang. 2023. Retrieval-augmented generation for large language models: A survey. arXiv preprint arXiv:2312.10997, 2. 





Google. 2024. Gemini deep research. 





Daya Guo, Dejian Yang, Haowei Zhang, Junxiao Song, Ruoyu Zhang, Runxin Xu, Qihao Zhu, Shirong Ma, Peiyi Wang, Xiao Bi, and 1 others. 2025. Deepseek-r1: Incentivizing reasoning capability in llms via reinforcement learning. arXiv preprint arXiv:2501.12948. 





Xanh Ho, Anh-Khoa Duong Nguyen, Saku Sugawara, and Akiko Aizawa. 2020. Constructing a multi-hop QA dataset for comprehensive evaluation of reasoning steps. In Proceedings of the 28th International Conference on Computational Linguistics, pages 6609-6625, Barcelona, Spain (Online). International Committee on Computational Linguistics. 





Sirui Hong, Mingchen Zhuge, Jonathan Chen, Xiawu Zheng, Yuheng Cheng, Jinlin Wang, Ceyao Zhang, Zili Wang, Steven Ka Shing Yau, Zijuan Lin, Liyang Zhou, Chenyu Ran, Lingfeng Xiao, Chenglin Wu, and Jirgen Schmidhuber. 2024. MetaGPT: Meta programming for a multi-agent collaborative framework. In The Twelfth International Conference on Learning Representations. 





Aaron Hurst, Adam Lerer, Adam P Goucher, Adam Perelman, Aditya Ramesh, Aidan Clark, AJ Ostrow, Akila Welihinda, Alan Hayes, Alec Radford, and 1 others. 2024. Gpt-4o system card. arXiv preprint arXiv:2410.21276. 





Bowen Jin, Hansi Zeng, Zhenrui Yue, Dong Wang, Hamed Zamani, and Jiawei Han. 2025. Search1: Training llms to reason and leverage search engines with reinforcement learning. arXiv preprint arXiv:2503.09516. 





Mandar Joshi, Eunsol Choi, Daniel Weld, and Luke Zettlemoyer. 2017. TriviaQA: A large scale distantly supervised challenge dataset for reading comprehension. In Proceedings of the 55th Annual Meeting of 





the Association for Computational Linguistics (Volume 1: Long Papers), pages 1601-1611, Vancouver, Canada. Association for Computational Linguistics. 





Tom Kwiatkowski, Jennimaria Palomaki, Olivia Redfield, Michael Collins, Ankur Parikh, Chris Alberti, Danielle Epstein, Illia Polosukhin, Jacob Devlin, Kenton Lee, Kristina Toutanova, Llion Jones, Matthew Kelcey, Ming-Wei Chang, Andrew M. Dai, Jakob Uszkoreit, Quoc Le, and Slav Petrov. 2019. Natural questions: A benchmark for question answering research. Transactions of the Association for Computational Linguistics, 7:452-466. 





Xiaoxi Li, Guanting Dong, Jiajie Jin, Yuyao Zhang, Yujia Zhou, Yutao Zhu, Peitian Zhang, and Zhicheng Dou. 2025a. Search-o1: Agentic search-enhanced large reasoning models. arXiv preprint arXiv:2501.05366. 





Xuefeng Li, Haoyang Zou, and Pengfei Liu. 2025b. Limr: Less is more for rl scaling. Preprint, arXiv:2502.11886. 





Xuefeng Li, Haoyang Zou, and Pengfei Liu. 2025c. Torl: Scaling tool-integrated rl. Preprint, arXiv:2503.23383. 





Xinbin Liang, Jinyu Xiang, Zhaoyang Yu, Jiayi Zhang, and Sirui Hong. 2025. Openmanus: An open-source framework for building general ai agents. https://github.com/mannaandpoem/OpenManus. 





Alex Mallen, Akari Asai, Victor Zhong, Rajarshi Das, Hannaneh Hajishirzi, and Daniel Khashabi. 2022. When not to trust language models: Investigating effectiveness and limitations of parametric and non-parametric memories. arXiv preprint. 





OpenAI. 2024. Learning to reason with llms, september 2024. 





OpenAI. 2025. Deep research system card. Technical report, OpenAI. 





Ofir Press, Muru Zhang, Sewon Min, Ludwig Schmidt, Noah A Smith, and Mike Lewis. 2022. Measuring and narrowing the compositionality gap in language models. arXiv preprint arXiv:2210.03350. 





Yujia Qin, Shihao Liang, Yining Ye, Kunlun Zhu, Lan Yan, Yaxi Lu, Yankai Lin, Xin Cong, Xiangru Tang, Bill Qian, and 1 others. 2023. Toollm: Facilitating large language models to master $16000+$ real-world apis. arXiv preprint arXiv:2307.16789. 





Qwen, :: An Yang, Baosong Yang, Beichen Zhang, Binyuan Hui, Bo Zheng, Bowen Yu, Chengyuan Li, Dayiheng Liu, Fei Huang, Haoran Wei, Huan Lin, Jian Yang, Jianhong Tu, Jianwei Zhang, Jianxin Yang, Jiaxi Yang, Jingren Zhou, and 25 others. 2025. Qwen2.5 technical report. Preprint, arXiv:2412.15115. 





Timo Schick, Jane Dwivedi-Yu, Roberto Dessì, Roberta Raileanu, Maria Lomeli, Eric Hambro, Luke Zettle-moyer, Nicola Cancedda, and Thomas Scialom. 2023. Toolformer: Language models can teach themselves to use tools. Advances in Neural Information Processing Systems, 36:68539-68551. 





Huatong Song, Jinhao Jiang, Yingqian Min, Jie Chen, Zhipeng Chen, Wayne Xin Zhao, Lei Fang, and JiRong Wen. 2025. R1-searcher: Incentivizing the search capability in llms via reinforcement learning. arXiv preprint arXiv:2503.05592. 





Kimi Team, Angang Du, Bofei Gao, Bowei Xing, Changjiu Jiang, Cheng Chen, Cheng Li, Chenjun Xiao, Chenzhuang Du, Chonghua Liao, and 1 others. 2025. Kimi k1.5: Scaling reinforcement learning with llms. arXiv preprint arXiv:2501.12599. 





Harsh Trivedi, Niranjan Balasubramanian, Tushar Khot, and Ashish Sabharwal. 2022. MuSiQue: Multi-hop questions via single-hop question composition. Transactions of the Association for Computational Linguistics. 





Prakhar Verma, Sukruta Prakash Midigeshi, Gaurav Sinha, Arno Solin, Nagarajan Natarajan, and Amit Sharma. 2025. Plan*rag: Efficient test-time planning for retrieval augmented generation. Preprint, arXiv:2410.20753. 





Xiaohua Wang, Zhenghua Wang, Xuan Gao, Feiran Zhang, Yixin Wu, Zhibo Xu, Tianyuan Shi, Zhengyuan Wang, Shizheng Li, Qi Qian, and 1 others. 2024a. Searching for best practices in retrieval-augmented generation. In Proceedings of the 2024 Conference on Empirical Methods in Natural Language Processing, pages 17716-17736. 





Ziting Wang, Haitao Yuan, Wei Dong, Gao Cong, and Feifei Li. 2024b. Corag: A cost-constrained retrieval optimization system for retrieval-augmented generation. arXiv preprint arXiv:2411.00744. 





xAI. 2025. Grok 3. 





Yuqing Yang, Ethan Chern, Xipeng Qiu, Graham Neubig, and Pengfei Liu. 2024. Alignment for honesty. Advances in Neural Information Processing Systems, 37:63565-63598. 





Zhilin Yang, Peng Qi, Saizheng Zhang, Yoshua Bengio, William W. Cohen, Ruslan Salakhutdinov, and Christopher D. Manning. 2018. HotpotQA: A dataset for diverse, explainable multi-hop question answering. In Conference on Empirical Methods in Natural Language Processing (EMNLP). 





Tian Yu, Shaolei Zhang, and Yang Feng. 2024. Auto-rag: Autonomous retrieval-augmented generation for large language models. arXiv preprint arXiv:2411.19443. 





Murong Yue, Wenlin Yao, Haitao Mi, Dian Yu, Ziyu Yao, and Dong Yu. 2024a. Dots: Learning to reason dynamically in llms via optimal reasoning trajectories search. arXiv preprint arXiv:2410.03864. 





Zhenrui Yue, Honglei Zhuang, Aijun Bai, Kai Hui, Rolf Jagerman, Hansi Zeng, Zhen Qin, Dong Wang, Xuanhui Wang, and Michael Bendersky. 2024b. Inference scaling for long-context retrieval augmented generation. arXiv preprint arXiv:2410.04343. 





Lianmin Zheng, Wei-Lin Chiang, Ying Sheng, Siyuan Zhuang, Zhanghao Wu, Yonghao Zhuang, Zi Lin, Zhuohan Li, Dacheng Li, Eric P. Xing, Hao Zhang, Joseph E. Gonzalez, and Ion Stoica. 2023. Judging llm-as-a-judge with mt-bench and chatbot arena. In Advances in Neural Information Processing Systems 36: Annual Conference on Neural Information Processing Systems 2023, NeurIPS 2023, New Orleans, LA, USA, December 10 - 16, 2023. 





Yuxiang Zheng, Shichao Sun, Lin Qiu, Dongyu Ru, Cheng Jiayang, Xuefeng Li, Jifan Lin, Binjie Wang, Yun Luo, Renjie Pan, Yang Xu, Qingkai Min, Zizhao Zhang, Yiwen Wang, Wenjie Li, and Pengfei Liu. 2024. OpenResearcher: Unleashing AI for accelerated scientific research. In Proceedings of the 2024 Conference on Empirical Methods in Natural Language Processing: System Demonstrations, pages 209-218, Miami, Florida, USA. Association for Computational Linguistics. 



# A Beyond Memorization: Curating Search-Dependent Training Data

# A.1 Leveraging Open Domain QA Data

Despite the growing interest in deep research capabilities for LLM agents, there currently exists no open-source training dataset specifically designed for this purpose. To address this gap, we leverage existing open-domain question-answering datasets, which contain single-hop to multi-hop questions that inherently require online search to find accurate answers. 

Our training corpus comprises a diverse collection of QA datasets that require varying degrees of retrieval complexity. Specifically, we utilize NaturalQuestions (NQ) (Kwiatkowski et al., 2019) and TriviaQA (TQ) (Joshi et al., 2017) for single-hop scenarios, where answers can typically be found within a single web document. For more complex multi-hop scenarios, which require integrating information across multiple sources, we incorporate examples from HotpotQA (Yang et al., 2018) and 2WikiMultiHopQA (2Wiki) (Ho et al., 2020), both of which were specifically designed to evaluate multi-step reasoning capabilities. 

# A.2 The Issue of Data Contamination

For training models that genuinely learn to leverage web search tools—rather than simply recalling memorized information—it is critical to address the problem of data contamination. Large language models have been pretrained on vast internet corpora, which likely include many of the QA pairs in standard benchmarks. Without proper contamination detection, the model might appear to successfully complete research tasks while actually using its parametric knowledge, defeating the purpose of learning web search strategies. 

This contamination issue is particularly problematic in the context of our work, as it could lead to: 

- Models that falsely appear to benefit from web search when actually using memorized knowledge. 

- Failure to develop genuine search strategies when deployed on truly novel questions. 

- Inability to generalize to real-world research scenarios where answers cannot be found in the model''s training data. 

# A.3 Data Cleaning and Contamination Detection

To ensure the integrity of our training process, we implemented a comprehensive two-stage filtering methodology: 

Low-Quality Question Filtering We exclude questions that could yield unreliable or problematic search results. Specifically, we eliminate: 1) Time-sensitive questions (e.g., "Who is the current CEO of Apple?"); 2) Highly subjective queries (e.g., "What is the best smartphone?"); and 3) Potentially harmful or policy-violating content. This filtering was implemented using DeepSeek-R1 (Guo et al., 2025) with a carefully designed evaluation prompt to systematically identify and mark problematic questions. 

Contamination Detection To ensure the model genuinely learns to use search tools rather than memorizing answers, we employed a robust contamination detection procedure. For each candidate question, we randomly sample 10 responses from the base model we will use in training, and check if any response contains the ground truth answer (i.e., pass@10). Questions where the model demonstrated prior knowledge (by producing the correct answer without search) were excluded from the training set. This contamination screening is critical for preventing the model from developing a false reliance on parametric knowledge when search-based knowledge is required. 

The prompts used for data cleaning and contamination detection are listed in Appendix C.1. After applying these quality control measures, we constructed a final training dataset of 80,000 examples with a distribution ratio of 1:1:3:3 for NQ:TQ:HotpotQA:2Wiki. This proportion deliberately emphasizes multi-hop scenarios (75% of examples), as these better reflect the complex information-seeking behaviors required for deep research questions. 

# B Case Study Example

This Section provides supplementary visual examples to illustrate distinct behavioral characteristics of the DeepResearcher during its reasoning processes. These case studies serve to concretize the model''s capabilities in dynamic planning, cross-validation, reflection, and honest self-assessment. 

<table><tr><td>Planning
Question: What is the name of the famous bridge in the birthplace of Gloria in D Major&#x27;s composer?
Ground Truth: Rialto Bridge</td><td>Cross Validation
Question: Which filmmaker is considered a pioneer, Herschell Gordon Lewis or Leah Meyerhoff?
Ground Truth: Herschell Gordon Lewis was a pioneer</td></tr><tr><td>Response Trajectory from DeepResearcher:
&lt;think&gt;
To answer this question, I need to figure out who Gloria in D Major&#x27;s composer was and their birthplace. Then I can find the famous bridge in that city.
Step 1: Identify the composer of Gloria in D Major.
Step 2: Find the place of birth of that composer.
Step 3: Look for a famous bridge in that city.
Make a plan first</td><td>Response Trajectory from DeepResearcher:
&lt;think&gt;
To answer this question, I need to investigate the contributions of both Herschell Gordon Lewis and Leah Meyerhoff to filmmaking. Specifically, I need to understand if either of them is considered a pioneer. First, I will perform a web search to find out more about the filmmakers and what they are known for.
&lt;/think&gt;
&lt;search&gt;
Herschell Gordon Lewis filmmaker pioneer
Leah Meyerhoff filmmaker pioneer
&lt;/search&gt;
&lt;tool_response&gt;
{
&#x27;title&#x27;: &#x27;Herschell Gordon Lewis - Wikipedia&#x27;,
&#x27;nippets&#x27;: &#x27;Herschell Gordon Lewis ( June 15, 1926 September 26, 2016) was an American filmmaker, best known for creating the &#x27;splatter&#x27; subgenre of horror films.,
&#x27;url&#x27;: &#x27;https://en.wikipedia.org/wiki/Herschell_Gordon_Lewis&#x27;
}
...(more results are omitted to save space)
&lt;tool_response&gt;
From the search results, I can see that Antonio Vivaldi is the composer of Gloria in D Major and he was born in Venice. Now I need to find the famous bridge in Venice.
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice
Step 2
famous bridge in Venice</td></tr><tr><td>Based on the information retrieved, it seems that Herschell Gordon Lewis is the filmmaker considered a pioneer.
The next step is to narrow down the exact reason why he is considered a pioneer. I will conduct another web search with more specific keywords to pinpoint the characteristics of his work that set him apart as a pioneer.
&lt;think&gt;
&lt;search&gt;
herschell Gordon Lewis why considered a pioneer
Herschell Gordon Lewis pioneer features
&lt;/search&gt;
&lt;tool_response&gt;
{
&#x27;title&#x27;: &#x27;Herschell Gordon Lewis, a Pioneer of Gore Cinema, Dies at 90&#x27;,
&#x27;nippets&#x27;: &#x27;Mr. Lewis set the bar for low-budget horror in movies like &quot;Blood Feast&quot; that went on to inspire filmmakers like Wes Craven and Quentin ...
&#x27;,&lt;think&gt;
&lt;search&gt;
Herschell Gordon Lewis is a pioneer of horror genre films
&lt;think&gt;
From the refined search, it is clear that Herschell Gordon Lewis is considered a pioneer due to his pioneering the &quot;splatter&quot; subgenre of horror films. His films introduced the extreme visuals and violent content that set them apart, even though they were often considered an &quot;insult to the art of filmmaking&quot;. Therefore, Herschell Gordon Lewis is the filmmaker considered a pioneer.
&lt;think&gt;
&lt;answer&gt;
Herschell Gordon Lewis
&lt;/answer&gt;</td><td></td></tr></table>

Figure 3: Planning and Cross Validation Behaviors. Left: DeepResearcher is capable of making plans and dynamically adjusting it throughout the reasoning process. Notably, the model can merge steps when appropriate. Right: DeepResearcher identifies the correct answer during its first tool call. However, rather than immediately committing to this result, it proceeds to verify its accuracy through subsequent steps. This rigorous behavior enhances the reliability of the model''s responses, ensuring greater robustness in its final answers. Note: In the actual model, the tool call and tool response format is a JSON string, rather than a tag. However, for clarity and ease of presentation, we have used tags in the figure to represent the output. 

<table><tr><td>Reflection
Question: Where was the place of burial of Djedefhor&#x27;s father?
Ground Truth: Great Pyramid of Giza</td><td>Honesty
Question: In the seventh-largest country in Africa, what is the oil production of the city at the mouth of the Congo River?
Ground Truth: 1200000 oilbbl/d</td></tr><tr><td>Response Trajectory from DeepResearcher:
&lt;think&gt;
To answer this question, I need to find out information about Djedefhor&#x27;s father and the place of his burial. I will start with a web search.
&lt;/think&gt;
&lt;search&gt;
Herschell Gordon Lewis filmmaker pioneer
Leah Meyerhoff filmmaker pioneer
place of burial of Djedefhor&#x27;s father
Djedefhor father burial site
who was Djedefhor&#x27;s father and where was he buried
&lt;/search&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
&lt;think&gt;
The web search results provide clues about Djedefhor&#x27;s father. However, the search results are mostly about Boromir&#x27;s father Denethor from the Lord of the Rings, not Djedefhor&#x27;s father. I need to refine my search to find information about Djedefhor specifically.
&lt;/think&gt;
&lt;search&gt;
who was Djedefhor&#x27;s father and where was he buried
Djedefhor father name
Djedefhor father identity
&lt;think&gt;
&lt;tool_response&gt;
...(omitted to save space)
Reflection and adjust research direction
&lt;/tool_response&gt;
&lt;think&gt;
The new search results provide information about Djedefhor&#x27;s father, Khufu, and also his burial place. However, the search results for his burial need to be more specific. I will use the web browser tool to look at the pages where the information may be more relevant.
&lt;/think&gt;
&lt;browse_webpage&gt;
https://en.wikipedia.org/wiki/Djedefre
https://www.ancient-egypt.org/history/old-kingdom/4th-dynasty/djedefre/biography-of-djedefre.html
https://ancientegyptonline.co.uk/djedefre/
&lt;/browse_webpage&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
From the browsing pages, it is evident that Djedefhor&#x27;s father is Khufu. The pages specifically mention that Khufu was the father of Djedefhor. However, I need to find the place of burial of Djedefhor&#x27;s father, Khufu.
&lt;/think&gt;
&lt;search&gt;
place of burial of Khufu
Khufu burial site
where was Khufu buried
&lt;/search&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
&lt;think&gt;
The search results clearly indicate that Khufu&#x27;s burial place was in the Great Pyramid of Giza. This pyramid served as the tomb for pharaoh Khufu.
&lt;/think&gt;
&lt;answer&gt;
Great Pyramid of Giza
&lt;/answer&gt;</td><td>Response Trajectory from DeepResearcher:
&lt;think&gt;
To answer this question, I need to identify the city at the mouth of the Congo River in the seventh-largest country in Africa, and then find its current oil production.
&lt;/think&gt;
&lt;search&gt;
seventh largest country in africa
city at the mouth of the Congo River in the seventh largest country in africa
&lt;/search&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
&lt;think&gt;
From the search results, I found that Angola is the seventh largest country in Africa, and its capital Luanda is located near the mouth of the Congo River. Now I need to find the oil production of Luanda.
&lt;/think&gt;
&lt;search&gt;
oil production of Luanda
oil production in Angola
&lt;/search&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
&lt;think&gt;
from the search results, I can see that Angola currently produces around 1.16 million barrels of oil per day. However, I should find the specific production of the city at the mouth of the Congo River, which is Luanda.
&lt;/think&gt;
&lt;search&gt;
oil production of Luanda
oil production in Luanda
&lt;/search&gt;
&lt;tool_response&gt;
...(omitted to save space)
&lt;/tool_response&gt;
&lt;think&gt;
After a series of web searches, I couldn&#x27;t find specific information about the oil production of Luanda. The results are mostly about Angola&#x27;s total oil production. Since Luanda is the capital and the largest city of Angola, it&#x27;s likely that a significant portion of Angola&#x27;s oil production happens there. For a more exact figure, we might need to explore specialized databases or recent reports about the oil industry in Luanda.
&lt;/think&gt;
&lt;browse_webpage&gt;
https://en.wikipedia.org/wiki/Luanda
https://www.worldometers.info/country-data/angola/oil-production
&lt;/browse_webpage&gt;
It seems the information about the oil production of Luanda is not directly available in the search results or in the previously browsed webpages. Given the information from previous searches, Angola is a major oil producer, and as the capital and largest city, Luanda likely plays a key role in the country&#x27;s oil production. However, to answer the question precisely, we may need a more detailed report on the city&#x27;s oil production, which might be included in specialized databases or recent reports. Since the exact oil production of Luanda is not available from the searches and browsing, and given the context and the previously found information that Angola is a major oil producer, it&#x27;s reasonable to infer that the oil production in the city at the mouth of the Congo River (Luanda) is a significant part of Angola&#x27;s total oil production. However, without a precise figure, I will not provide a number.
&lt;/think&gt;
&lt;answer&gt;
significant portion
&lt;/answer&gt;
Be honest when didn&#x27;t find the exact answer</td></tr></table>

Figure 4: Reflection and Honesty Behavior. The search and browse are 2 apis in json format in the real inference stage. Left: When the retrieved information does not fully align with the question, DeepResearcher recognizes this discrepancy based on environmental feedback and refines its search query in subsequent tool calls. This proves its reflection ability. Right: DeepResearcher is capable of recognizing when it has not found the correct answer and appropriately declines to provide a response to be honesty. Note: In the actual model, the tool call and tool response format is a JSON string, rather than a tag. However, for clarity and ease of presentation, we have used tags in the figure to represent the output. 

# C Prompts

# C.1 Prompt for Question Quality Level Evaluation

The prompt below displays two templates. Identifies if questions are time-sensitive, subjective, or potentially harmful. Includes classification guidelines, question placeholder, and required answer tag format. 

# Prompt for training data quality checking

Please identify whether the given question is time-sensitive, subjective, or may cause harmful answers. 

- Time-sensitive: The answer to the question may change over time. 

- Harmful: The answer to the question may be harmful or offensive. 

- Subjective: The answer to the question may be subjective and not based on facts. 

Here is the question: <question> {question} </question> 

Wrap your answer in <answer> tags with one of the following values: 

- timeSensitive: if the question is time-sensitive 

- harmful: if the question may cause harmful answers 

- subjective: if the question is subjective 

- good: if the question is none of the above 

The prompt below shows the template prompt for contamination detection. To tests if AI responses are influenced by training data contamination. 

# Prompt for contamination detection

Give a short answer to the following question. The answer should be in English. 

Question: {question} 

Your answer: 

# C.2 Prompt for Model''s Answer Quality Level Evaluation

The prompt below provides instructions for evaluating the correctness of AI-generated answers (pred answer) against a list of ground truth answers. To 

judge if a predicted answer correctly answers a question by comparing it to ground truth answers. 

# Prompt for Model-based Evaluation

You will be given a question and its ground truth answer list where each item can be a ground truth answer. Provided a pred_answer, you need to judge if the pred_answer correctly answers the question based on the ground truth answer list. 

You should first give your rationale for the judgement, and then give your judgement result (i.e., correct or incorrect). 

Here is the criteria for the judgement: 

1. The pred_answer doesn''t need to be exactly the same as any of the ground truth answers, but should be semantically same for the question. 

2. Each item in the ground truth answer list can be viewed as a ground truth answer for the question, and the pred_answer should be semantically same to at least one of them. 

question: {question}  
ground truth answers: {gt_answer}  
pred_answer: {pred_answer} 

The output should in the following json format: 

”ison 

3 

"rationale": "your rationale for the judgement, as a text", 

"judgement": "your judgement result, can only be 

''correct'' or ''incorrect" 

1 

Your output: 

# C.3 Prompt for Research Plan on Question Answering

The prompt below outlines the structured approach for addressing complex questions, utilizing web search and webpage browsing tools to conduct in-depth research and gather the necessary information for a comprehensive response. 

# Prompt for Research Plan on Complex Question Answering

Background information 

* Today is YYYYY-MM-DD 

* You are Deep AI Research Assistant 

The question I give you is a complex question that requires a *deep research* to answer. 

I will provide you with two tools to help you answer the question: 

* A web search tool to help you perform google search. 

* A webpage browsing tool to help you get new page content. 

You don''t have to answer the question now, but you should first think about the research plan or what to search next. 

Your output format should be one of the following two formats: 

```txt
<think>  
YOUR THINKING PROCESS  
</think>  
<answer> 
```

YOUR ANSWER AFTER GETTING ENOUGH INFORMATION 

```txt
</answer>  
or  
<think> 
```

YOUR THINKING PROCESS 

```txt
</think> <tool_call> 
```

YOUR TOOL CALL WITH CORRECT FORMAT </tool_call> 

You should always follow the above two formats strictly. 

Only output the final answer (in words, numbers or phrase) inside the <answer></answer> tag, without any explanations or extra information. If this is a yes-or-no question, you should only answer yes or no. 

Tools 

You may call one or more functions to assist with the user query. 

You are provided with function signatures within <tools></tools> XML tags: <tools> 

{''type'': ''function'', ''function'': {''name'': ''web_search'', ''description'': ''Search the web for relevant information from google. You should use this tool if the historical page content is not enough to answer the question. Or last search result is not relevant to the question'', ''parameters'': {''type'': ''object'', ''properties'': {''query'': {''type'': ''array'', ''items'': {''type'': ''string'', ''description'': ''The query to search, which helps answer the question''}, ''description'': ''The queries to search''}}}, {''required'': [''query''], [''minItems'': 1, ''uniqueItems'': true}}} 

{''type'': ''function'', ''function'': {''name'': ''browse_webpage'', ''description'': ''Browse the webpage and return the content that not appeared in the conversation history. You should use this tool if the last action is search and the search result maybe relevant to the question.'', ''parameters'': {''type'': ''object'', ''properties'': {''url_list'': {''type'': ''array'', ''items'': {''type'': ''string'', ''description'': ''The chosen url from the search result, do not use url that not appeared in the search result''}, ''description'': ''The chosen urls from the search result.''}}}, ''required'': [''url_list''])''} </tools> 

For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags: 

```xml
<tool_call>
    "name": <function-name>, "arguments": <args-jason-object>
</tool_call> 
```

# D Training Scaling Result

Figure 5 presents the F1 score in 7 benchmarks. We sampled 125 cases from each benchmarks'' development set. DeepResearcher can scale in all benchmarks, especially in OOD benchmarks. 

# E Performance

Figure 6 provides a consolidated visualization of DeepResearcher''s performance in comparison to other models across a comprehensive suite of seven distinct datasets. This consistent outperformance not only serves as a robust validation of the model''s advanced capabilities and effectiveness but also strongly indicates its significant generalization ability across diverse data domains and task types. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/432dfd04f19e0f5de69e0420f573372be10f7acb77c1ba495df6a6eca754570b.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/dcfb12f22aef277c40b260e52b74ad3f5e5fdfd667d88671aa3b09eb5d6c727f.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/da15c69b9ee4592aed538267f7ee6a8cb23f0653b9c322355741c95c053113a3.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/a8df910aaccaec8becf3654d117c7573de3c93bf931d39c8e5ef0c6058e4f33a.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/e266065e5bbb211d2a363259f4b2631082b316d1e9a20a3b73bd0549bf2953d3.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/d49550e3308471612f07a26ae1157165c51f5a60602f9f5e31ac49c61d22b433.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/b122c4a451159567eac016fd3616b8a79a0577ac764a0cf5b738a659e911579d.jpg)



Figure 5: F1 score during training


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-11/0b49b704-aae8-476e-b9f1-357157d66b4b/bc94717e78115dee7ea0b91914a32b29ab63691795555cf90e4d0c71deebe6b1.jpg)



Figure 6: DeepResearcher performs the best on all 7 datasets measured by reliable model-based evaluation.
', '{"title": "DeepResearcher: Scaling Deep Research via Reinforcement Learning in Real-world Environments", "sections": [{"level": 1, "title": "Abstract"}, {"level": 1, "title": "1 Introduction"}, {"level": 1, "title": "2 Related Work", "children": [{"level": 2, "title": "2.1 Prompt-Based Search Agents"}, {"level": 2, "title": "2.2 Training-Based Search Agents"}, {"level": 2, "title": "2.3 Training Environments"}]}, {"level": 1, "title": "3 Methodology", "children": [{"level": 2, "title": "3.1 Deep Research Trajectory"}, {"level": 2, "title": "3.2 Addressing Challenges in Dynamic Real-World Web Environments"}, {"level": 2, "title": "3.3 RL Training Framework"}, {"level": 2, "title": "3.4 Reward"}]}, {"level": 1, "title": "4 Experiments", "children": [{"level": 2, "title": "4.1 Experimental Setups", "children": [{"level": 3, "title": "4.1.1 Training Data Curation"}, {"level": 3, "title": "4.1.2 Model and Hyperparameters"}]}, {"level": 2, "title": "4.2 Evaluation and Results", "children": [{"level": 3, "title": "4.2.1 Benchmarks"}, {"level": 3, "title": "4.2.2 Baselines"}, {"level": 3, "title": "4.2.3 Evaluation Metrics"}, {"level": 3, "title": "4.2.4 Main Results"}]}]}, {"level": 1, "title": "5 Analysis", "children": [{"level": 2, "title": "5.1 Training Dynamics"}, {"level": 2, "title": "5.2 Case Study"}]}, {"level": 1, "title": "6 Conclusion"}, {"level": 1, "title": "Limitations"}, {"level": 1, "title": "Ethical Considerations"}, {"level": 1, "title": "Acknowledgments"}, {"level": 1, "title": "References"}, {"level": 1, "title": "A Beyond Memorization: Curating Search-Dependent Training Data", "children": [{"level": 2, "title": "A.1 Leveraging Open Domain QA Data"}, {"level": 2, "title": "A.2 The Issue of Data Contamination"}, {"level": 2, "title": "A.3 Data Cleaning and Contamination Detection"}]}, {"level": 1, "title": "B Case Study Example"}, {"level": 1, "title": "C Prompts", "children": [{"level": 2, "title": "C.1 Prompt for Question Quality Level Evaluation"}, {"level": 2, "title": "Prompt for training data quality checking"}, {"level": 2, "title": "Prompt for contamination detection"}, {"level": 2, "title": "C.2 Prompt for Model''s Answer Quality Level Evaluation"}, {"level": 2, "title": "Prompt for Model-based Evaluation"}, {"level": 2, "title": "C.3 Prompt for Research Plan on Question Answering"}, {"level": 2, "title": "Prompt for Research Plan on Complex Question Answering"}]}, {"level": 1, "title": "D Training Scaling Result"}, {"level": 1, "title": "E Performance"}]}', '2026-03-15 20:13:32.896576', 'success', NULL);
INSERT INTO "public"."doc_parsed" VALUES (5, 5, '# A Survey on RAG Meeting LLMs: Towards Retrieval-Augmented Large Language Models

Wenqi Fan 

wenqifan03@gmail.com 

The Hong Kong Polytechnic 

University, HK SAR 

Shijie Wang 

shijie.wang@connect.polyu.hk 

The Hong Kong Polytechnic 

University, HK SAR 

Yujuan Ding∗ 

dingyujuan385@gmail.com 

The Hong Kong Polytechnic 

University, HK SAR 

Hengyun Li 

neilhengyun.li@polyu.edu.hk 

The Hong Kong Polytechnic 

University, HK SAR 

Liangbo Ning 

BigLemon1123@gmail.com 

The Hong Kong Polytechnic 

University, HK SAR 

Dawei Yin 

yindawei@acm.org 

Baidu Inc, China 

Tat-Seng Chua 

dcscts@nus.edu.sg 

National University of Singapore, 

Singapore 

# ABSTRACT

As one of the most advanced techniques in AI, Retrieval-Augmented Generation (RAG) can offer reliable and up-to-date external knowledge, providing huge convenience for numerous tasks. Particularly in the era of AI-Generated Content (AIGC), the powerful capacity of retrieval in providing additional knowledge enables RAG to assist existing generative AI in producing high-quality outputs. Recently, Large Language Models (LLMs) have demonstrated revolutionary abilities in language understanding and generation, while still facing inherent limitations, such as hallucinations and out-ofdate internal knowledge. Given the powerful abilities of RAG in providing the latest and helpful auxiliary information, Retrieval-Augmented Large Language Models (RA-LLMs) have emerged to harness external and authoritative knowledge bases, rather than solely relying on the model’s internal knowledge, to augment the generation quality of LLMs. In this survey, we comprehensively review existing research studies in RA-LLMs, covering three primary technical perspectives: architectures, training strategies, and applications. As the preliminary knowledge, we briefly introduce the foundations and recent advances of LLMs. Then, to illustrate the practical significance of RAG for LLMs, we systematically review mainstream relevant work by their architectures, training strategies, and application areas, detailing specifically the challenges of each and the corresponding capabilities of RA-LLMs. Finally, to deliver deeper insights, we discuss current limitations and several promising directions for future research. Updated information about this survey can be found at https:// advanced-recommendersystems.github.io/ RAG-Meets-LLMs/ 1. 

# KEYWORDS

Retrieval-Augmented Generation (RAG), Large Language Model (LLM), Pre-training, Fine-tuning, In-context Learning, Prompting. 

Qing Li 

csqli@comp.polyu.edu.hk 

The Hong Kong Polytechnic 

University, HK SAR 

# 1 INTRODUCTION

As one of the most fundamental data mining techniques, retrieval aims to understand the input query and extract relevant information from external data sources [24, 30, 67, 140]. It has found extensive application in various fields [8, 28, 106, 179], such as search, question answering, and recommender systems. For instance, search engines (e.g., Google, Bing, and Baidu) are the most successful applications of retrieval in the industry; they can filter and retrieve the most relevant web pages or documents that can match a user’s query [19, 179], enabling users to find the desired information effectively. Meanwhile, retrieval models, through effective data maintenance in external databases, can provide faithful and timely external knowledge, thereby serving vital functions in various knowledge-intensive tasks. Due to their powerful capacities, retrieval techniques have been successfully incorporated into advanced generative models in the era of AI-Generated Content (AIGC) [77, 132, 163]. Notably, the integration of retrieval models with language models has given rise to Retrieval-Augmented Generation (RAG) [74], which has emerged as one of the most representative techniques in the field of generative AI, aiming to enhance the quality of the generated text content with retrieved information [6, 74, 77]. 

To advance generation models and enhance the generated results, RAG incorporates information or knowledge from external data sources, which serves as supplementary for the input query or the generated output [62, 103]. Specifically, RAG first invokes the retriever to search and extract the relevant documents from external databases, which are then leveraged as the context to enhance the generation process [54]. In practice, RAG techniques are feasible and efficient to apply in various generation tasks with simple adaptation of the retrieval component, requiring minimal or even no additional training [117]. Recent studies have demonstrated the great potential of RAG not only for knowledge-intensive tasks such as the Open-domain Question Answering (OpenQA) [6, 46, 109, 133], but also for general language tasks [48, 62, 170], and various downstream applications [90, 163]. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/89964a7485ac1b9ec88676783d0c2aacd1e1e151bd79bb510a090445e48e4bec.jpg)



Figure 1: Retrieval-Augmented Generation (RAG) meets Large Language Models (LLMs). When the user’s query is outof-scope, e.g., unseen content in training data or the need for the latest information for the answer, LLMs might show inferior generation performance. With the help of RAG, LLMs can leverage additional relevant information from external database to enhance their text generation capability.


Recent years have witnessed the rapid development of pre-trained foundation models, particularly Large Language Models (LLMs), which have demonstrated impressive performance across various tasks [1, 18], including recommender systems [195], molecule discovery [77], and report generation [27]. Technically, the great success of LLMs can be technically attributed to the advanced architectures with billion-level parameters pre-training on a huge amount of training corpus from various sources. These technical improvements have given rise to the remarkable emergence capabilities of LLMs [194, 195], particularly in language understanding and generation, in-context learning, and others. For instance, GPT-FAR introduces detailed prompts to teach GPT-4 to perform image tagging, statistical analysis, and text analysis for multi-modal fashion report generation [27]. LLMs also achieve promising performance in recommender systems by understanding users’ preferences towards items [154, 195]. Despite the success, LLMs still suffer from intrinsic limitations [194, 195], such as the lack of domain-specific knowledge, the problem of “hallucination”, and the substantial computational resources required for updating the models. These problems are particularly notable in domain-specific fields like medicine and law. For instance, a recent study has demonstrated that legal hallucinations are pervasive and disturbing, with hallucination rates ranging from $6 9 \%$ to $8 8 \%$ in responses to specific legal queries for state-of-the-art LLMs [21]. Moreover, the challenges of tackling the hallucination problem become even harder due to the substantial computational resources required for fine-tuning LLMs with domain-specific or the latest data. This, in turn, significantly hinders the widespread adoption of LLMs in various real-world applications. 

To address these limitations, recent efforts have been made to take advantage of RAG to enhance the capabilities of LLMs in various tasks [6, 53, 62, 135], especially those demanding high for the latest and reliable knowledge such as Question Answer (QA), AI4Science, and software engineering. For example, Lozano et al. [92] introduces a scientific QA system based on retrieving scientific 

literature dynamically. MolReGPT leverages RAG to enhance the in-context learning ability of ChatGPT for molecular discovery [77]. It is also been demonstrated that RAG can effectively reduce hallucinations in conversational tasks [137, 171]. As illustrated in Figure 1, an LLM-based dialog system will not be able to answer well for out-of-scope queries. With the help of RAG to retrieve relevant knowledge from external database and integrate it into the process of generation, the dialog system succeeds in giving correct answers. Given the remarkable progress in advancing LLMs with RAG, there is an imperative need for a systematic review of recent advances in Retrieval-Augmented Large Language Models (RA-LLMs). 

This survey aims to provide a comprehensive overview of RA-LLMs by summarizing representative methods from the aspects of the architecture, training strategy, and application area respectively. More specifically, following a brief introduction to the background knowledge of LLMs in Section 2, we review existing research from several primary perspectives of RA-LLMs in terms of retrieval, generation, and augmentation in Section 3, as well as the necessity and application frequency of retrieval in RAG. Then, we summarize the main training techniques of RA-LLMs in Section 4 and various RA-LLMs applications in Section 5. Finally, in Section 6, we discuss key challenges and potential directions for future exploration. 

Concurrent to our survey, several related surveys have diverse focuses for RAG and LLMs. For example, Zhao et al. [193] specifically review multi-modal information-based RAG techniques and Zhao et al. [192] discuss the RAG for AIGC. Gao et al. [41] conduct a relatively comprehensive overview of RAG for LLMs. Our survey differs from these surveys in concentrating on technical perspectives and systematically reviewing models according to the architecture and training paradigm in RA-LLMs, as well as application tasks. 

# 2 BACKGROUND

In this section, we briefly present the background of large language models and prompt learning. 

# 2.1 Large Language Models (LLMs)

Recently, the significant breakthrough of LLMs has revolutionized the field of artificial intelligence [7, 37, 194]. The advanced LLMs are typically pre-trained on extensive data with billion-level parameters and have demonstrated the ability to understand and generate human-like text, leading to advancements in various natural language processing tasks such as text generation and information retrieval [194, 195]. LLMs can be adapted to a variety of downstream tasks by fine-tuning them on specific datasets, allowing them to specialize in particular domains or applications. In general, most existing LLMs can be broadly divided into three main categories: Encoder-only, Decoder-only, and Encoder-Decoder models. Encoder-only models, such as the BERT (Bidirectional Encoder Representations from Transformers) [25] family of models, process input text by encoding it into a high-dimensional space. The key feature of Encoder-only models is their bi-directional nature, meaning that they can take into account both the left and right context of each token when encoding it. This bi-directionality allows Encoder-only models to better understand the meaning of words in context, which is crucial for tasks like sentiment analysis, review reading, and text classification [25, 169]. In contrast to these models, 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/78ff7b19369151da9d5ea102ebe0edce5524845c1e9a59ed62aaf88552007dd8.jpg)



Figure 2: Representing RAG and RA-LLMs methods organized by their main design focus, proposed time and impact (shown by citation). Note that the first author and year shown in the figure along with the model name can be used to locate corresponding reference.


Decoder-only models generate text in a left-to-right fashion. As a representative Decoder-only model, GPT (Generative Pre-trained Transformer) [114] predicts the next token in a sequence based on the context provided by the previous tokens. Their architecture makes them particularly effective for tasks like language generation, code generation, and creative writing. Encoder-Decoder models, such as T5 (Text-To-Text Transfer Transformer) [116], uniquely transform a variety of NLP tasks into text generation problems. To be more specific, the encoder in T5 processes the input sequence to capture its meaning, while the decoder generates the output sequence based on the encoded information. This T5 architecture is well-suited for tasks that involve converting one sequence into another, such as machine translation, summarization, and conversational response generation. 

# 2.2 Prompt Learning

2.2.1 Prompting Engineering. Due to the massive parameters of LLMs, prompt learning emerged as a paradigm to leverage the power of LLM to implement various tasks [194, 195], instead of fine-tuning the LLMs extensively. Prompt learning carefully designs the input that guides the model to perform downstream tasks in LLMs. For example, early methods [7, 110] provide manually crafted templates to handle various tasks in NLP. Specifically, Encoder-only models like BERT typically adopt cloze prompts because they very 

closely match the form of their pre-training task [20, 110]. For other models like GPT, prefix prompts tend to be more suitable as they mesh well with the generation tasks [7]. However, manually designed prompts rely on human experience without effectiveness guarantees. To address this limitation, soft prompt tuning was developed to learn the trainable continuous prompt embeddings [83, 150, 151]. For instance, Prefix-Tuning [83] prepends a series of prefix embedding in the input, which can be trained and updated. This apportion allows prompts not to be real text, giving more flexibility in the generation of prompts. However, due to the lack of domainspecific knowledge, the model might still not generate accurate responses when facing new tasks. 

2.2.2 In-Context Learning (ICL). To overcome the limitations of vanilla prompt learning, recent efforts [66, 89, 191] have developed in-context learning (ICL). ICL is a specific method of prompt learning that gives the model a few demonstrations of tasks within the prompt. This paradigm allows pre-trained LLMs to understand the pattern provided by the demonstrations to solve novel tasks without the need for fine-tuning. For example, by carefully selecting a few demonstrations, GPT-3 [7] has shown the capability to perform few-shot tasks [89]. This success indicates that LLMs have a remarkable ability to rapidly adapt to new tasks based on task-specific knowledge. 

Despite its effectiveness, ICL usually relies heavily on the quality of the provided demonstrations [143? ], which may lead to the generation of sub-optimal outputs. Even worse, ICL may not have enough necessary information or prior knowledge to guide the LLMs in generating accurate responses. To address the aforementioned limitations of ICL, more recent studies introduce Retrieval-Augmented Generation (RAG) technologies [74, 117, 135]. By integrating retrieval with generation, RAG models provide a promising direction for enhancing the performance and adaptability of LLMs across various tasks. 

# 3 RETRIEVAL-AUGMENTED LARGE LANGUAGE MODELS (RA-LLMS)

The RAG framework in the era of LLMs consists of several major processes: retrieval, generation, and augmentation, as well as the mechanism to determine whether the retrieval is needed. In this section, we will introduce important techniques involved in each process. 

# 3.1 Retrieval

Given the query from the input of LLMs, the retrieval process in RAG aims to provide relevant information from the external knowledge sources, which can be either open-sourced or closed-sourced as shown in Figure 3. The key component, retriever, as further detailed in Figure 4, consists of several procedures, functioning as a whole to measure the relevance between the query and documents in the database for effective information retrieval. The specific pipeline of the retrieval is further determined by whether the preand post-retrieval processes are included. In this subsection, we will introduce the major techniques involved in the retrieval of traditional and LLM-based RAGs, including the retriever type, retrieval granularity, pre- and post-retrieval enhancement, and database construction. 

3.1.1 Retriever Type. Retrieval methods can be generally categorized into two types: sparse and dense, based on the information encoding methods. Sparse retrieval is word-based and applied in text retrieval mostly, while dense retrieval embeds queries and external knowledge into vector spaces and can applied to various data formats. 

As a straightforward approach, sparse retrieval, e.g., TF-IDF and BM25 [125, 142], usually relies on inverted index matching along with the raw data input. For example, many studies directly apply BM25 for passage-level retrieval to facilitate their RAG [10, 57, 117, 168, 196, 197], where passages are specifically represented as a bag of words and ranked based on term and inverse document frequencies [54]. On top of offering supplementary to enhance the input of the generator, sparse retrieval has also been used to find demonstrations to function in in-context learning for RA-LLMs [2, 96, 126, 138, 176]. The main limitation of applying sparse retrieval in RAG is its no-training nature, which makes the retrieval performance heavily rely on the quality of the database and the query. Moreover, such fixed term-based methods only support similarity-based retrieval, while cannot be adapted for other retrieval criteria possibly existing in LLM applications, such as the diversity [31]. 

Dense retrieval, on the contrary, embeds the query and documents into continuous vector space with certain criteria, for example, semantic similarity [61]. Dense retrieval methods are usually trainable, therefore holding more flexibility and potential in adaptation. As the key component of dense retriever, the embedding models have delicately different designs in existing RAG models. A simple design [62, 72, 165] is to directly use a part of the generation model as the embedding layer of the retriever, which might be able to enhance the alignment between the retrieval and generation processes. BERT-based backbone [25] is widely applied in retrieval models. One common retriever design in RAG is to construct two-stream encoders with the BERT structure (one encoder for the query and the other for the documents), which is also called bi-encoder [135, 164]. Early-stage RAG methods tend to freeze [6, 117] or partially freeze [74] the parameters of the retriever to perform general-level relevant knowledge extraction and pay more attention to the knowledge leveraging and generator finetuning. Large-scale specialized pre-training further enhances RAG models to excel in more knowledge-intensive tasks. One typical success is Dense Passage Retriever (DPR) [61], which uses a BERTbased backbone and is pre-trained specifically for the OpenQA task with question-answer pair data. DPR has shown strong capacity as a pre-trained retriever, facilitating many RAG models to succeed in various downstream tasks [54, 74, 135, 139, 141]. It has also been regarded as the first step in the RAG paradigm for improving the performance of LLMs, which may further enhance the alignment of the embeddings between queries and relevant textual data through fine-tuning [16]. A recent study [122] has also discovered that DPR training decentralizes how knowledge is stored in the network, creating multiple access pathways to the same information. With effective fine-tuning, bi-encoder retrievers are also applied widely in ICL-based RAG [82, 93, 101, 111, 126, 176]. Specifically, they have been more often used for sentence embedding similarity-based retrieval, as well as for some special requirement in ICL, such as diverse example retrieval [176]. 

Another stream of dense retrievers having been widely applied in RA-LLMs uses one encoder only, which may be based on Transformer, BERT or other off-the-shelf sequence modeling backbones. These one-encoder retrievers are generally pre-trained on largescale unaligned documents by contrastive learning [122], which may therefore excel for their versatility, meaning that they can transfer and generalize better to new domains or tasks. Such generalpurpose pre-trained retrievers, e.g., Contriever [42] and Spider [118], would be more flexible to use in LLMs targeting on various tasks and have demonstrated their effectiveness in many RA-LLM methods, such as In-Context RALM [117], Atlas [55] and Self-RAG [5]. According to experimental results in existing studies [182], for opendomain QA tasks, when cooperated with InstructGPT [107], applying general-purpose pre-trained retriever (Contriever) without fine-tuning achieves comparable performance to sparse retriever (BM25). However, they are both worse than the DPR model finetuned on target datasets, showing the effectiveness of fine-tuning on targeted tasks and data. 

3.1.2 Retrieval Granularity. Retrieval granularity denotes the retrieval unit in which the corpus is indexed, e.g., document, passage, token, or other levels like entity. For RAG, the choice of retrieval 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/9f81c3cbd7e3aba051fb1e2cb72d7068e6d75fd3867280543a1ed7551b8f11a6.jpg)



Figure 3: Illustration of the basic Retrieval-Augmented Large Language Models (RA-LLMs) framework for a specific QA task, which consists of three main components: retrieval, augmentation, and generation. Retrieval may have different procedures with various designs, which optionally includes pre-retrieval and post-retrieval processes. The retrieved documents are further leveraged in generation with the augmentation module, which may be at different integration stages.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/865e5649c74d8f548cf9a59b631cdb0bbb12ac8f0d1d4cb82cfa3164673ef1a1.jpg)



Figure 4: Illustration of the retriever in RA-LLMs, which can be implemented in either dense or sparse manners, each with several key operations.


granularity can significantly impact the overall performance of the model in terms of effectiveness and efficiency as they determine the saving space for the database as well as the computational cost for searching [4]. Early stage retrieval-augmented language models [10] propose to retrieve whole pieces of documents, and then apply a machine comprehension model trained to detect answer spans in the returned documents, which focuses more on language reading and key information locating in the document. In generative language models, Chunk retrieval (also called passages in some references [46, 57, 61]) is common, which has been used in both traditional and LLM-based RAG models such as REALM [46], RAG [74] and Atlas [55]. A more fine-grained retrieval, i.e., token retrieval, instead can be done with faster searching but will bring 

more burden for the database saving. Token retrieval is more suitable in cases requiring rare patterns or out-of-domain data [62], meanwhile cooperates well with the every-token retrieval strategy as applied in kNN-LM and other similar work [47, 104, 180]. In comparison, a text chunk may contain compact and complete information with less redundancy and irrelevancy, therefore becoming the mainstream retrieval text granularity in RAG. 

Another major retrieval granularity proposed in RAG is entity retrieval. Unlike the above types of granularity, entity retrieval is designed from the perspective of knowledge rather than language. Févry et al. [39] introduce the Entities as Experts (EAE) model, which divides the parameter space of language models according to the entity identity. The proposed EAE model aims to learn entity representations from the text along with other model parameters with the Wikipedia database and represent knowledge with entity memory. At a more fine-grained level, de Jong et al. [22] propose to build the knowledge base by learning and retrieving mention rather than entity. Overall, applying entity or mention-level retrieval in RAG would be more effective for entity-centric tasks, and more efficient in space compared to token-wise retrieval. 

3.1.3 Pre-retrieval and Post-retrieval Enhancement. To ensure the retrieval quality, i.e., increase the accuracy and relevance of the retrieved results, various pre- and post-retrieval strategies have been proposed to further enhance the input and output of the retriever. Wang et al. [156] propose a query expansion approach Query2doc, which generates pseudo-documents by few-shot prompting LLMs and expands the query with the relevant information in pseudodocuments to improve the query disambiguation and guide the retrievers. They have empirically demonstrated that such a method can boost the performance of both the sparse and dense retriever [61] 

on ad-hoc information retrieval datasets. Similarly, Gao et al. [40] propose Hypothetical Document Embedding (HyDE) method, which instructs an LLM to generate hypothetical documents for the given query. The hypothetical documents are then used as new queries to get embedded and search for neighbors with the dense retriever. 

Another pre-retrieval strategy, query rewrite [98], aims to close the gaps between the input text and the needed knowledge in retrieval, to reformulate the original question into a more conducive version to retrieve. Specifically, Ma et al. [98] propose the Rewrite-Retrieve-Read framework, which prompts an LLM to generate the query for the retrieval function. The motivation of the rewriting step is to clarify the retrieval need in the new query to ease the burden on the retrieval function to comprehend the input and enhance the output, i.e., retrieved relevant information. They have tested both the settings of using a frozen LLM and a trainable model to be the rewriter, both outperforming naive RAG or generation models, demonstrating diverse performance on different tested QA datasets though. Tan et al. [146] also formulate a query rewriting strategy in their model that decomposes the heuristic answer from a proxy generation model into distinct claims. 

Yu et al. [183] propose query augmentation to combine the original query and the preliminary generated outputs as a new query, which is further used to retrieve relevant information from the external database. The retrieved results can inspire the language model to rethink the generated results and enhance them. Compared to applying only the original query, such augmentation may contribute more relevant information retrieved from the corpus for the directly clarification of query-output relationships. Including initial output in the new query further enhances the lexical and semantic overlap between the supporting documents to be retrieved with the given question. Query augmentation achieves overall better performance among these query enhancement strategies since it may process all retrieved knowledge collectively while generating answers [155]. 

Post-retrieval enhancement denotes the procedure to process the extracted top-k documents from the retriever before feeding them to the generator for the sake of better alignment between the retrieval and generation stages [173], particularly for closed-source generators such as LLMs. For example, Yang et al. [173] propose the Pluggable Reward-driven Context Adapter (PRCA) that enables to fine-tune the lightweight adapter instead of the generator on specific datasets. It also distills the retrieved documents through reinforcement learning with the rewards resulting from the generator. Glass et al. [44] propose Retrieve-Rerank-Generate $\left( \mathrm { R } ^ { 2 } \mathrm { G } \right)$ method, which assembles the retrieved documents of different retrieval approaches with the rerank operation to boost the robustness of the retrieval results. Another consideration for applying post-retrieval enhancement is that the retrieved information may sometimes be irrelevant or contain noise, which might not help with the generation model for the task, or even worse, harm the generation process [159]. Wang et al. [159], Asai et al. [5], Yu et al. [183] propose different strategies to mitigate the noise in retrieved knowledge documents. However, Xiong et al. [166] empirically studied that these methods are dependent on the LLM’s confidence levels, which might not be as precise as expected. For this problem, Wang et al. [155] propose BlendFilter, which simultaneously considers the pre-retrieval 

query generation blending and the post-retrieval knowledge filtering. This method can tackle the complex questions as well as the noisy retrieved knowledge problems, therefore comprehensively enhancing the RA-LLM performance. 

More recently, advanced RAG pipelines have been proposed using LLMs to generate reasoning paths and plans with the Information Retrieval (IR) module to iteratively retrieve knowledge to enhance LLM-based generation [130, 172, 175]. However, Zhu et al. [198] point out that if the outputs of IR and LLM are low-quality, the retrieval and generation processes will get hindered by each other with such an iterative guidance pipeline. To overcome this barrier, they propose a new reasoning approach for query and retrieved knowledge enhancement. Post-retrieval strategies may also function to enhance the compatibility between the retrieved results and the generation models. For example, one of the main limitations of existing LLMs is the length of the input tokens, which prevents long retrieved documents being directly incorporated into existing RA-LLMs. For this limitation, Xu et al. [168] propose Retrieve, Compress, Prepend (RECOMP), which adds an intermediate step to process the retrieved documents into a textual summary before in-context augmentation in the generation process. From another perspective, long retrieved passage list leads to a high inference latency when using auto-regressive decoding at generation stage, which hurts the model’s efficiency. For this limitation, Hofstätter et al. [50] propose a light version of FiD model that compresses the encoded vectors per retrieved passage before concatenating and feeding them through the decoder and also includes a re-ranker on the retrieved results before applying them in the generation. 

3.1.4 Database. Retrieval in RAG is conducted based on external knowledge source, which can be a closed- or open-sourced [98, 100], as illustrated in Figure 3. Closed-sourced database generally stores key-value pairs for knowledge, which can be constructed in various ways. The keys are primarily used for similarity matching, being as sparse vectors such as in BM25 or dense embeddings from the retrieval encoding. The value depends on the specific retrieval target, which is raw text in most cases [6, 46, 54, 72, 74, 129]. For example, each Wikipedia article is split into disjoint 100-word chunks, to make a total of 21M documents in early RAG [74]. Each document is encoded by a dense embedding and saved in the database as the value and key, respectively. The value can store tokens too, one for each as applied in kNN-LM [62] and SPALM [180]. The source of the database depends on the specific application domains and tasks. Wikipedia is one of the most commonly applied general retrieval sets in previous RAG work, which stores factual structured 

<table><tr><td>Time</td><td>Model</td><td>Cite</td><td>Retriever</td><td>RetTrain</td><td>RetAug Stage</td><td>Pre-/Post- Retrieval</td><td>Generator</td><td>Aug</td><td>Evaluation</td></tr><tr><td>2019</td><td>kNN-LM [62]</td><td>619</td><td>DR(GP)</td><td>No</td><td>Inf</td><td>RA</td><td>DT</td><td>Output</td><td>LG</td></tr><tr><td>2020</td><td>REALM [46]</td><td>1437</td><td>DR(BE,BT)</td><td>Yes</td><td>PT+FT</td><td>/</td><td>ET</td><td>Input</td><td>OpenQA(NQ,WQ,CT)</td></tr><tr><td>2020</td><td>RAG [74]</td><td>2125</td><td>DR(DPR)</td><td>Yes</td><td>FT</td><td>/</td><td>ED (BART)</td><td>Input</td><td>OpenQA, AQA, Jeopardy QG, FV</td></tr><tr><td>2021</td><td>FiD [54]</td><td>780</td><td>SR(BM25)/ DR(DPR)</td><td>No</td><td>FT</td><td>/</td><td>ED (T5/BART)</td><td>Input</td><td>OpenQA</td></tr><tr><td>2021</td><td>SE-FiD [68]</td><td>286</td><td>SE(Bing)</td><td>No</td><td>Inf</td><td>RQG</td><td>FiD</td><td>Input</td><td>WizInt, WoW</td></tr><tr><td>2021</td><td>FiD-KD [53]</td><td>190</td><td>DR(BE)</td><td>Yes</td><td>FT</td><td>CR</td><td>FiD</td><td>Input</td><td>OpenQA</td></tr><tr><td>2021</td><td>RETRO [6]</td><td>683</td><td>DR(BERT, DPR)</td><td>No</td><td>PT</td><td>/</td><td>ED</td><td>Inter</td><td>LM, OpenQA</td></tr><tr><td>2021</td><td>EPR [126]</td><td>384</td><td>DR(DPR)</td><td>Yes</td><td>Inf</td><td>CR</td><td>GPT-3,J,Neo, CODEX</td><td>Demon</td><td>UR</td></tr><tr><td>2022</td><td>OpenBook [70]</td><td>145</td><td>SE+SR</td><td>No</td><td></td><td>QE</td><td>GOPHER LM</td><td>Input</td><td>QA, FV</td></tr><tr><td>2022</td><td>DSP [63]</td><td>117</td><td>ColBERTv2</td><td>No</td><td>Inf</td><td>RQG, RF</td><td>GPT-3.5</td><td>Demon</td><td>OpenQA, MHQA, CQA</td></tr><tr><td>2023</td><td>In-Context RALM [117]</td><td>211</td><td>DR/SR</td><td>No</td><td>Inf</td><td>TRR</td><td>GPT-2,J,Neo</td><td>Input</td><td>LM, OpenQA</td></tr><tr><td>2023</td><td>Atlas [55]</td><td>367</td><td>DR(OE)</td><td>Yes</td><td>PT+FT</td><td>/</td><td>ED</td><td>Input</td><td>OpenQA, FV, WoW, EL,SF, MMLU</td></tr><tr><td>2023</td><td>FLARE [57]</td><td>133</td><td>SR(BM25)/ SE(Bing)</td><td>No</td><td>Inf</td><td>RQG</td><td>GPT-3.5</td><td>Input</td><td>MHQA, CR, LongQA, OS</td></tr><tr><td>2023</td><td>IRCoT [149]</td><td>114</td><td>SR(BM25)</td><td>No</td><td>Inf</td><td>/</td><td>GPT-3,Flan-T5</td><td>Input</td><td>OpenQA</td></tr><tr><td>2023</td><td>Self-RAG [5]</td><td>85</td><td>DR(OE)</td><td>No</td><td>FT</td><td>CM</td><td>tunable LLM</td><td></td><td>OpenQA, LongQA, FV, BG</td></tr><tr><td>2023</td><td>REPLUG [135]</td><td>48</td><td>DR(BE)</td><td>Yes</td><td>FT</td><td>TRA</td><td>GPT-2,3</td><td>Input</td><td>MMLU, OpenQA</td></tr><tr><td>2023</td><td>UDR [80]</td><td>42</td><td>DR(DPR)</td><td>Yes</td><td>FT</td><td>CR</td><td>GPT-Neo</td><td>Demon</td><td>40 NLP tasks</td></tr><tr><td>2023</td><td>ITER- RETGEN [130]</td><td>40</td><td>DR(DPR)</td><td>Yes</td><td>FT</td><td>RR</td><td>InstructGPT, Llama-2</td><td>Input</td><td>MHQA, FV, CR</td></tr></table>


Table 1: Basic publication information and main technical designs of high-impact RAG and RA-LLM models.1


information and has several versions differing in scale, from billion token-level [22, 39, 46, 62, 74, 117, 135, 168, 180] to trillion tokenlevel [6]. Domain-specific database is also used for downstream tasks. For example, for the code generation task, Zan et al. [185] collect API information and code files of public libraries to build their APIretriever database. In addition, Zhou et al [197] propose to use a documentation pool frequently updated with new content (newly released libraries) in their model. 

Applying Internet searching engine [95] such as Bing and Google avoids the maintenance of the search index and can access up-todate knowledge [68, 70]. Meanwhile, it provides a broader knowledge base than the closed-sourced database [5, 70]. It can also provide high-quality ranking after being tuned over decades of use. Internet search has been widely incorporated with black-box LLMs and shows effectiveness for different functions such as knowledge augmentation [70], fact-checking [100] and LLM agent enhancement [175]. Compared to traditional RAG, Internet search has been leveraged more as the retriever in RA-LLMs owing to the extraordinary capability of LLMs to be the Reader to comprehend the searching results, i.e., the retrieved documents, as well as LLMs’ ability to use tools to process and analyze the them [98]. Existing studies [182] have shown that leveraging search engines (e.g., InstrucGPT) is particularly effective for LLMs on zero-shot knowledge-intensive tasks such as OpenQA and fact checking. 

# 3.2 Generation

The design of the generator heavily depends on the downstream tasks. For most text generation tasks, Decoder-only and Encoder-Decoder are two dominant structures [194]. The recent development of commercial closed-sourced large foundation models makes black-box generation models mainstream in RA-LLMs. In this part, we will briefly review studies with these two types of generators: parameter-accessible (white-box) and parameter-inaccessible (black-box). 

3.2.1 Parameter-Accessible Generators (White-box). The structure of Encoder-Decoder processes the input and the target independently with different sets of parameters, in which a cross-attention component is developed to connect input tokens to target tokens. Representative Encoder-Decoder models include T5 [116] and BART [73]. In comparison, Decoder-only models process inputs and targets after concatenation, which makes the representations of the two parts concurrently built layer-by-layer as they propagate up the network. These two types of generators are widely applied in existing RAG work. For example, RAG [74] and $\mathrm { R e } ^ { 2 } \mathrm { G }$ [44] employ BART; FID [54] and EMDR2 utilize T5. There are other models [6, 84] leveraging Transformer-based Encoder-Decoder architecture but with some customized design. Generators in RAG differ themselves from general ones by incorporating retrieved data to enhance the generation 

accuracy and relevance. Furthermore, white-box generators allow parameter optimization, which can be trained to adapt to different retrieval and augmentation approaches for a better performance of generation. 

3.2.2 Parameter-Inaccessible Generators (Black-box). A certain proportion of LLMs are released without the disclosure of internal structures or the accessibility of parameters, especially those particularly large-scale ones such as GPT series [1], Codex [12] and Claude, which are called black-box generation models. These generators only allow the operations of feeding queries (input) and receiving responses (output) while not allowing the internal structure to be altered or parameters to be updated. From another perspective, LLMs, even those open for fine-tuning, are large in scale and difficult to tune for downstream domain-specific tasks with only a limited amount of data. Black-box RA-LLMs, therefore, focus more on the retrieval and augmentation processes, trying to enhance the generator by augmenting the input (also called prompt in the context of LLMs) with better knowledge, guidance, or examples for the generation. For example, Rubin et al. [126] proposes to train a prompt retriever with the data labeled by language models themselves, which can be used to provide better examples for in-context learning, therefore enhancing the final generation performance. Xu et al. [168] propose to compress the retrieved documents before in-context integration, which can reduce the computational costs and also relieve the burden of LMs to identify relevant information in long retrieved documents. 

# 3.3 Retrieval Integration for Generation Augmentation

Augmentation describes the technical process that integrates retrieval and generation parts, which is the essential part of RA-LLMs. In this subsection, we introduce three main designs of augmentation, which are conducted at the input, output, and intermediate layers of generator respectively, as illustrated in Figure 3. 

3.3.1 Input-Layer Integration. A common way to integrate retrieved information/documents is to combine them with the original input/query and jointly pass them to the generator, which is called input-layer integration. For example, In-Context RALM [117] applies input-layer integration by specifically concatenating the original input and all retrieved documents into a single sequence as the new input for the generation model. Despite the effectiveness, such integration is limited to the number of retrieved documents, since the concatenated new input may be too long to be processed by the generation model. In-context RALM specifically alleviates this limitation by removing tokens from the beginning of the new input. To avoid information loss with such a token removing strategy, FID [54] employs a different integration method that processes each retrieved document independently in the encoder. This strategy is scalable to a large number of contexts as it only performs selfattention over one context at a time in the follow-up processing. Atlas [55] and REPLUG [135] apply a similar parallel integration by concatenating the query and one retrieved document at a time. In general, most black-box generation-based RAG methods apply input-layer integration since neither the intermediate layer of the generation model or the output distribution is accessible. 

More specially for LLMs, input-layer integration may use the retrieved content as (additional) prompts or demonstrations on top of using it as supplementary to the original input as in traditional RAGs [126]. Prompt retrieval aims to find suitable natural language prompts automatically through retrieval to teach the LLM to learn in context [7] or to induce the LLM to reason[162]. It may boost the zero-shot ability of LLMs without delicate prompt engineering. For example, Cheng et al. [16] propose to learn a prompt retriever based on the input-prompt pair data with score labels resulting from a frozen LLM. 

3.3.2 Output-Layer Integration. Another kind of augmentation is post-hoc, i.e., output-layer integration, which joints retrieval and generation results. For example, kNN-LM [62] interpolates two next-token distributions in prediction: one induced by the LM and the other induced by the nearest neighbors from the retrieval corpus. Output-layer linear integration [45, 196] is flexible to apply since it can be plugged into most generation models without additional training. However, the simplicity of output-layer integration also limits the model’s ability to reason about the retrieved text. To tackle this limitation, Yogatama et al. [180] propose to add an extra gating network to post-process the retrieved data and achieve comparatively better performance. For LLMs, output-layer integration is as reasonable and adaptive as input-layer integration. REFEED [183] proposes an answer refining mechanism that applies an LLM to evaluate the retrieved information and adjust the initial answer accordingly to enhance the accuracy of the response. Similarly, Zhang et al. [190] propose the COMBO framework, which matches LLM-generated passages with retrieved counterparts into compatible pairs based on pre-trained discriminators. The passage pairs are then handled by a Fusion-in-Decoder-based [54] to derive a final answer. 

3.3.3 Intermediate-Layer Integration. Compared to the above two non-parametric approaches, a more engaging augmentation is to design a semi-parametric module to integrate the retrieved results through the internal layers of the generation model, which is called intermediate-layer integration. Such integration might add additional complexity and is promising to enhance the capability of the generation model with effective training. Typically, a Transformer module is introduced to leverage retrieved information (mostly encoded into dense representations) into the generation model to interact with the representations in the middle stage of the generation. For example, RETRO [6] introduces a Chunked Cross Attention (CCA) layer to process the retrieved chunks in the generator blocks, and Wu et al. [165] introduces the kNN-Augmented Attention Layer. Similarly, EAE [39] and TOME [22] use Entity Memory and MemoryAttention layer to incorporate the retrieved Entity and Entity Mentions, respectively. Such intermediate-layer integration can use many blocks frequently and efficiently to enhance the capability of the whole RAG model. It offers an efficient alternative to incorporate a large number of text chunks frequently retrieved, which are challenging to process with input-layer integration due to the input length limit of LMs [6]. However, it also needs to be noted that intermediate-layer integration requires high access to the generation models, which is not feasible for most LLMs that are accessible through inference APIs [98]. 

# 3.4 Retrieval Augmentation Necessity and Frequency

The retrieval operation in LLM-based generation generally aims to supplement knowledge to enhance generation. Although retrievalaugmented models have emerged promising, they have been criticized for not being a universal solution [75, 109] as indiscriminately augmenting LLMs with irrelevant passages can override potentially correct knowledge already possessed by LLMs and result in incorrect responses instead [99]. Thakur et al. [147] contribute a human-annotated dataset to help evaluate the robustness of LLMs against errors in external retrieved knowledge and observe that LLMs may double the hallucination rate on the non-relevant retrieved passages than on the relevant ones. Therefore, it is critical for RA-LLMs to accurately recall the prior knowledge while selectively incorporating retrieved information only when necessary, which is the path to robust RA-LLMs. 

Most existing methods determine the necessity of retrieval based on the preliminary answers of LLMs or their internal reasoning results [102, 117]. For example, Self-RAG [5] introduces special tokens to assess the necessity of retrieval and control retrieval behavior. Other methods design iterative prompts to decide if extra information is required during generation, which thereby needs to invoke retrieval or other actions for LLMs [162, 175]. Wang et al. [159] propose Self-Knowledge guided Retrieval augmentation (SKR) method, which uses LLMs themselves or explicit small trainable models to offer self-knowledge as the reference for the adaptive calling of a retriever. In traditional RAGs, retrieval necessity judgment has also been explored and proposed to address by intuitive approaches such as assessing the confidence of the logits produced by the generation models [47, 56, 59]. Such a solution is also applicable to RA-LLMs, for example, FLARE [57] dynamically triggers RAG if logits are lower than a specific threshold. Tan et al. [146] introduce a more flexible model SlimPLM, which detects missing knowledge in LLMs with a slim proxy model, which functions to generate a “heuristic answer”. The “heuristic answer” is used to assess the necessity of retrieval and facilitate the retrieval process for query rewriting when necessary. 

In traditional RAGs that rarely consider retrieval necessity, retrieval frequency (also called retrieval stride) is an important design aspect to determine the degree of using the retrieval in the generation, thereby greatly affecting the overall performance of RAG models [117]. Retrieval frequency controls how much to rely on the retrieval results, thereby affecting both the efficiency and effectiveness of the model. When the necessity of retrieval is not considered, retrieval frequency is often pre-defined and fixed, which have three common settings: one-time, every-n-token, and every-token. Onetime retrieval invokes the retrieval function only once and tries to find all desired information in that one-time operation. One-time retrieval is usually operated at the beginning of the generation process, and then provides all retrieved documents to the generation models along with the original input, as applied in REALM [46]. One-time retrieval is more suitable for the cases that the information needs in external databases are obvious to LLMs [57]. However, for language tasks requiring long-form output such as open-domain summarization, the dependency among the tokens in the output is more important to be considered during the generation. In these 

cases, pre-retrieved documents (through one-time retrieval) might not be enough to support the generation of the whole sequence of output, which calls for in-generation retrieval operations. To this end, In-Context RALM [117] and RETRO [6] apply every-n-token retrieval in the process of generation for better augmentation. In comparison, kNN-LM [62] adopts a more frequent retrieval strategy, which retrieves information for the prediction of every token during the generation. Overall, applying different frequencies of retrieval can impact both the effectiveness and efficiency of the whole RAG method. For example, more frequent retrieval leads to better performance but also increases the computing cost [117]. Choosing retrieval frequency is almost a trade-off between computing cost and performance. 

# 4 RA-LLMS TRAINING

Based on whether training is required or not, existing RAG methods can be categorized into two main classes: train-free approaches and training-based approaches. Training-free methods usually directly leverage the retrieved knowledge during inference time without introducing extra training by inserting the retrieved text into the prompt, which is computationally efficient. However, one potential challenge is that the retriever and generator components are not specifically optimized for downstream tasks, which could easily lead to sub-optimal utilization of the retrieved knowledge. To fully exploit the external knowledge, extensive methods are proposed to fine-tune the retriever and generator, thereby guiding large language models to effectively adapt and integrate retrieved information [127, 128, 130, 135, 153, 199]. 

According to the training strategies, we categorize these trainingbased approaches into three classes: 1) Independent Training approaches independently train each component in the RAG procedure, 2) Sequential Training methods train one module first and freeze the well-trained component to guide the tuning process of the other part, and 3) Joint Training approaches train retriever and generator simultaneously. In the following section, we will comprehensively review the training-free, independent training, sequential training, and joint training methods. The comparison of these different training methods is depicted in Figure 5. 

# 4.1 Training-free

With the huge number of parameters, LLMs have exhibited humanlevel intelligence and achieved promising prediction performance on various downstream tasks. However, it is extremely challenging to frequently perform fine-tuning and update the knowledge stored in the model parameters [74] due to the considerable time and computational resources required. Recently, numerous studies have suggested enhancing LLMs with retrieval mechanisms, enabling them to dynamically acquire new knowledge from external sources without extra training processes (i.e., training-free) [54, 57, 63], instead of relying solely on the implicit knowledge encoded in the model’s parameters. These approaches have shown significant performance improvement for various knowledge-intensive tasks, such as open-domain question answering [74]. According to the different ways in which LLMs utilize retrieved information, we categorize these training-free methods into two categories: 1) Prompt Engineering-based Methods integrate retrieved knowledge into 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/4162fe781eac4fd2ac0b83f7fd748c355a7d9a15312b67db4d4c3618e113bec5.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/cf663d482dd23c6afbcce166a17a93356ebb9e24120da17359c19b41890c4408.jpg)



Figure 5: An illustration of different training methods in Retrieval-Augmented Large Language Models (RA-LLMs). Existing RA-LLMs approaches can be categorized into two classes: training-free approaches usually directly leverage retrieved information during the inference time by integrating the retrieved knowledge into the prompt, and training-based approaches fine-tune the retrieval and generator to enhance the generation performance. Based on the training strategies, training-based methods can be further categorized into three groups: independent training, where the retrieval and generator components are trained independently; sequential training, where they are trained sequentially; and joint training, where they are trained jointly.


the original prompt directly, and 2) Retrieval-Guided Token Generation Methods retrieve information to calibrate the token generation process. 

4.1.1 Prompt Engineering-based Methods. As the LLMs’ generation performance highly depends on the input query, numerous trainingfree RAG approaches employ external knowledge by refining the original prompts [57, 63, 81]. Specifically, the retrieved texts are usually used as contextual information and combined with the original prompt to guide the generation of LLMs [54, 57, 63, 65, 81, 112, 158]. For example, In-Context RALM [117] keeps the LLM parameters unchanged and directly incorporates the retrieved document before the original prompt to augment the generation process. IRCoT [149] interleaves chain-of-thought (CoT) generation and knowledge retrieval steps, enabling the retrieval of more relevant information for subsequent reasoning steps compared to standard retrieval methods that rely solely on the question as the query. Instead of retrieving knowledge from a large corpus, GENREAD [182] first prompts a LLM to generate contextual documents based on the query, and then generate answers based on the given context and question. SKR [159] proposes guiding LLMs to determine whether they can 

answer a given question based on their internal knowledge, enabling flexible utilization of both internal and external knowledge by selectively calling the retriever. TOC [65] first retrieves relevant knowledge for ambiguous questions and recursively constructs a tree structure by clarifying ambiguous questions into multiple disambiguate questions, which is further aggregated to generate long-form answers. 

4.1.2 Retrieval-Guided Token Generation Methods. In addition to directly integrating external knowledge into the original prompt, the auxiliary information can be employed to adjust the token generation process. For example, KNN-KMs [62] first retrieves $k$ most relevant contexts from the datastore based on the given query, and computes a neighbor distribution based on the distance. The output distribution is calibrated by interpolating the neighbor distribution and the original model’s output distribution. Rest [49] is proposed to replace the parametric draft model with a non-parametric retrieval datastore and retrieves relevant tokens based on the current context for speculative decoding [9, 71, 145]. 

# 4.2 Independent Training

Independent training refers to training the retriever and LLMs as two entirely independent processes, in which there is no interaction between the retriever and the LLMs during the training process [61, 69, 197]. Compared with training-free methods, the performance of the RAG-empowered models can be effectively enhanced by training LLMs to leverage the retrieved knowledge or retrievers to bridge the gap between information retrieval and language generation. For the training of LLMs, the negative loglikelihood loss is the most representative training objective [115, 148], which aims to guide the LLMs to generate desired output based on the given input. Regarding the retriever, it can be categorized into two types: 1) Sparse retriever [120, 125], and 2) Dense retriever [61, 69, 197]. The sparse retrievers usually exploit sparse features, e.g., word frequencies, to represent the documents and calculate the relevance scores based on task-specific metrics [77, 120, 125] such as TF-IDF and BM25. As for the dense retrievers, deep neural networks are employed to encode the query and documents into dense representations, and then the inner product is usually used to calculate relevance scores and retrieve the relevant external knowledge. For example, DPR [61] adopts two independent BERT [25] networks to encode the query and passages respectively, and trains these models by utilizing contrastive learning. CoG [69] proposes to train a prefix encoder and a phrase encoder for retrieval and reformulate the text generation as multiple copy-and-paste operations from existing source text collection. 

# 4.3 Sequential Training

Independent training is an efficient approach to exploit the external knowledge during the generation process since the retriever and generator can be trained offline and any off-the-shelf models can be utilized, avoiding extra training costs. To better enhance the synergy between the retriever and generator, several methods have been proposed to train the retriever and LLMs sequentially. In these sequential training methods, the process typically begins with the independent pre-training of either the retriever or the generator, after which the pre-trained module is fixed while the other module undergoes training. Note that various existing models (e.g., BERT [25, 64, 123], CLIP [113], T5 [116]) can be directly employed as the fixed retriever and generator, thereby bypassing the first pertaining process. Compared to independent training, sequential training involves coordinated training of the retriever and generator, where the trainable module benefits from the assistance of the fixed module. Based on the training order between the retriever and generator, sequential training can be categorized into two classes: 1) Retriever First [5, 127, 128, 153, 199], and 2) LLMs First [130, 135, 157]. 

4.3.1 Retriever First. These methods first train the retrieval model and then fix it. LLMs are then trained by utilizing the retrieved knowledge. For instance, RETRO [6] adopts the BERT model that is pre-trained independently as the retriever, and an encoder-decoder architecture is trained to integrate retrieval chunks into the model’s predictions. RALMs [181] adopts Google Search and the opensource COLBERTV2 [64] as the pre-trained retriever and finetunes the LLM to effectively leverage the retrieved passages. ITER-RTGEN [124] utilizes the pre-trained S-BERT [123] as the retriever 

and introduces an adaptive hybrid retrieval strategy for retrieving demonstrations. Additionally, it leverages T5 [116] as the generator, which undergoes further fine-tuning based on the target label and input combining the original prompt with retrieved demonstrations. SMALLCAP [121] proposes using the CLIP [113], which is a powerful pre-trained multi-modal network, to encode the input image and the textual data of the external datastore and retrieve the most relevant items based on the cosine similarity. A cross-attention layer is trained and GPT-2 [115] is used as the decoder to produce captions. 

4.3.2 LLMs First. Similarly, it can also pre-train LLMs first, and then tune the retriever under the supervision of the well-trained LLMs. For example, DKRR [53] shows that attention scores from a sequence-to-sequence model can indicate the document’s relevance. Therefore, they propose to leverage the attention scores of a reader model to produce synthetic labels to train the retriever. AAR [184] proposes using a small language model to generate the supervised signal for training retrievers. The well-trained retriever can be further leveraged to enhance the performance of black-box LLMs. RA-DIT [86] first fine-tunes the LLMs to enhance their ability to leverage retrieved knowledge, and then train the retriever to better align its output with LLMs. UPRISE [16] proposes a lightweight method to enhance the zero-shot performance of LLMs in unseen tasks by introducing a prompt retriever. A frozen LLM is employed to guide the fine-tuning process of the prompt retriever, and this retriever then retrieves prompts for different tasks with various LLMs during inference. 

# 4.4 Joint Training

Joint training methods [17, 51, 60, 79, 167, 196] employ the end-toend paradigm to optimize the retriever and generator simultaneously. Instead of training each module sequentially, joint training methods effectively enhance the retriever’s ability to locate external knowledge for generation and the generator’s capacity to effectively leverage the retrieved information. For instance, RAG [74] minimizes the negative loglikelihood to jointly train the retriever and generator. REALM [46] adopts a similar training paradigm to that of RAG [74], and Maximum Inner Product Search (MIPS) [15, 29, 119, 131] technique is used to locate the most relevant documents. To employ MIPS, all external documents are embedded first and a search index is produced for each embedding. An asynchronous index updating strategy [46, 52, 55, 141] is proposed to refresh the index every several hundred training steps to avoid time consumption of re-indexing all documents. 

# 5 APPLICATIONS

In this section, we will introduce some representative applications of retrieval-augmented large language models (RA-LLMs). To provide a clear overview of the applications of RA-LLMs, we will review them from three perspectives: NLP applications, downstream tasks, and domain-specific applications. The studies mentioned in this section are summarized and categorized in Figure 6. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-03-15/d77424f6-34b8-4110-9f4e-9d846eddc728/086342e1c329aa6cf7f6e2efaeefd83b4711482a11c25ad7d65b59a8e9dfec9d.jpg)



Figure 6: A summary of applications of RA-LLMs categorized by NLP applications, downstream tasks, and domain-specific application. Specifically, NLP applications include QA systems, ChatBots, and fact verification; downstream tasks include recommendations and software engineering; and domain-specific applications include AI for Science and Finance.


# 5.1 NLP Applications

Due to the intrinsic capability in text generation, RA-LLMs have various applications in the NLP field, such as Question Answer (QA) Systems, ChatBot, and Fact Verification. 

5.1.1 QA Systems. QA Systems aim to provide precise answers to user’s queries. However, even when trained on extensive data, these systems may lack the latest information or specific domain knowledge that is not included in their training data [54, 91]. To address this limitation, the integration of RA-LLMs has played a crucial role in advancing the capabilities of QA systems by enhancing their ability to retrieve and synthesize relevant information [6, 54]. Specifically, RA-LLMs can provide coherent and contextually relevant answers by leveraging their retrieval component to access a vast knowledge base. For example, REALM [46] integrates a knowledge retriever that can retrieve information from a large corpus during pre-training, fine-tuning, and inference. This approach allows REALM to effectively retrieve from a vast knowledge corpus, thereby improving the accuracy of its responses. Similarly, Fusionin-Decoder [54] retrieves passages from support documents and then fuses them with questions to generate the answer, achieving higher accuracy. In addition, Borgeaud et al. [6] indicate that the quality of the answers may rely more on the output of retrieval. 

5.1.2 ChatBot. ChatBot is designed to interact with users in a natural and conversational manner [87]. Different from the QA system, ChatBot focuses on maintaining a coherent and contextually rich conversation with the user. To enhance these capabilities, recent methods focus on integrating RA-LLMs [60, 68, 188] for its ability to augment the ChatBot with relevant external knowledge, facilitating more engaging and context-rich interactions with users. For example, some studies [14, 43] retrieve relevant knowledge from static databases (e.g., a Wikipedia dump) to augment conversation. Komeili et al. [68] propose retrieving information from the 

internet search to further augment conversation performance. Considering the dynamic nature of knowledge in the world, another model [152] further accesses large amounts of dynamic information in search engines to generate responses. 

5.1.3 Fact Verification. Fact Verification is a critical task in verifying the accuracy and reliability of information. With the need for trusted evidence, RA-LLMs are being utilized to enhance the capabilities of fact verification [55, 74, 74]. Lewis et al. [74] first propose retrieval of external knowledge to augment a range of knowledge-intensive tasks including fact verification. On the other hand, Atlas [55] examines the performance of the RA-LLMs for fact verification under few-shot learning. Recently, Self-RAG [5] has greatly made a notable impression by incorporating a self-reflective mechanism. Specifically, Self-RAG reflects on whether retrieved information is helpful and judges the reliability of retrieved information, thereby greatly improving the verification accuracy. 

# 5.2 Downstream Tasks

In addition to NLP applications, RA-LLMs can also be applied to various downstream tasks, such as recommendations and software engineering. 

5.2.1 Recommendations. Recommender systems play an important role in modeling users’ preferences and providing personalized recommendations [34–36, 154, 189, 195]. Recently, RA-LLMs have demonstrated great potential in providing personalized and contextually relevant recommendations by integrating retrieval and generation processes [26, 94, 163]. For example, Di Palma [26] proposes a simple retrieval-augmented recommendation model, that leverages knowledge from movie or book datasets to enhance recommendations. Additionally, Lu et al. [94] further retrieval from the reviews to enrich item information in recommender systems. 

CoRAL [163] utilizes reinforcement learning to retrieve collaborative information from the dataset and align it with semantic information for more accurate recommendations. 

5.2.2 Software Engineering. The rise of RA-LLMs has influenced many aspects of software engineering [105, 177, 197]. For example, some studies propose the retrieval-augmented generation paradigm for code generation [197] and program repair [105]. Similarly, Parvez et al. [108] retrieve top-ranked codes or summaries from the codebase and aggregate them with input to enhance code generation and summarization. In addition, RA-LLMs show potential in tabular data processing [76, 177] and Text-to-SQL semantic parsing [111, 134]. 

# 5.3 Domain-specific Applications

RA-LLMs have been widely adopted for various domain-specific tasks, such as AI for Science and Finance. 

5.3.1 AI for Science. RA-LLMs have proven to be beneficial for the realms of science, such as molecular and protein. Molecules include identifying the molecule’s property and predicting new molecules, thereby favoring drug discovery. Currently, some RA-LLMs have been applied to molecules by integrating retrieval of molecule structure and biomedical entities like protein, molecule, and disease [90, 160, 161, 174], etc. Li et al. [77], Wang et al. [160] propose retrieval-based frameworks by retrieving from the database to guide molecule generation. Liu et al. [90] introduce a multi-modal molecule structure-text model by retrieving textual knowledge from a large-scale dataset for molecular property prediction. In addition, RA-LLMs also significantly influence Protein representation and generation [97, 144]. For instance, RSA [97] queries protein sequences associated with a collection of structurally or functionally similar sequences in the database to enhance protein representations. Furthermore, Lozano et al. [92] present a clinical QA system based on retrieving published review articles. 

5.3.2 Finance. In the highly data-driven and information-intensive field of finance, RA-LLMs have proved to be a significant technology for enhancing decision-making [78, 178, 187]. For example, Zhang et al. [187] retrieve financial information from external sources, such as news platforms (e.g., Bloomberg and Reuters) and social media platforms (e.g., Twitter, Reddit), to combine with the original query to enhance the precision of financial sentiment analysis. In addition, financial QA is another primary task of financial analysis, which usually extracts relevant knowledge from financial documents. As professional documents are usually stored in PDF format, Lin [85] introduces a PDF parser combined with RA-LLMs to retrieve knowledge from financial reports. On the other hand, Yepes et al. [178] propose a document chunking method based on structure instead of chunking based on paragraphs, further improving the quality of RA-LLMs outputs. 

# 6 FUTURE CHALLENGES AND OPPORTUNITIES

Since the studies of RA-LLMs are still in the early stage, we present some potential research directions that can be explored in the future in the field of RA-LLMs. 

Trustworthy RA-LLMs. The essential objective of developing RAG-empowered LLMs is to enhance the capability of the language models, thereby benefiting users and society by alleviating redundant and meaningless labor, increasing conveniences, and spurring social progress. However, recent research indicates that RA-LLMs can be maliciously and unintentionally manipulated to make unreliable decisions and harm humans [23, 200], which may have serious consequences in safety-critical scenarios [11, 13, 32, 38, 88]. In addition, private retrieval database has a risk of leakage, raising concerns regarding the privacy of RA-LLMs [186]. Therefore, developing trustworthy RA-LLMs is of paramount importance as it can significantly mitigate the potential negative impacts of LLMs technology and provide people with powerful AI models that can be fully trusted. To be specific, the ideal trustworthiness in RA-LLMs systems should possess the following characteristics: 1) robustness, 2) fairness, 3) explainability, and 4) privacy. For example, robustness means a trustworthy RA-LLMs system should be robust against malicious or inadvertent perturbations introduced by attackers. Fairness indicates a trustworthy RA-LLMs system ought to avoid discrimination during the decision-making process. Explainability requires a complete understanding of the intrinsic workings of RA-LLMs systems, i.e., the predictions of RA-LLMs systems are explainable and transparent. Privacy entails safeguarding the safety of this private information housed within the datastore when establishing trustworthy RA-LLMs systems. 

Multi-Lingual RA-LLMs. The ability of leveraging knowledge from multiple languages can greatly enhance the capabilities of retrieval-augmented language models. As the world becomes increasingly interconnected, there is a growing need for AI systems that can understand and communicate across different languages. By incorporating multilingual knowledge retrieval and generation, these models can access and synthesize information from diverse linguistic sources, enabling more comprehensive and nuanced understanding and generation capabilities. Additionally, multilingual models can facilitate cross-cultural communication and knowledge sharing and breaking down language barriers, thereby bringing convenience to people across different regions of the world, especially those in areas with minority languages [58, 81]. For example, users from countries with less prevalent languages can utilize abundant English and Chinese corpora for knowledge retrieval, enhancing the performance of large language models in downstream tasks. 

Multi-modal RA-LLMs. Multi-modal retrieval-augmented generation extends the knowledge sources beyond text to include various data modalities such as images, videos, and audio. By integrating various modalities, LLMs can leverage richer contextual information than single-modal RAG and develop a more comprehensive understanding of users’ needs, bringing precise, fine-grained, and high-quality generation. For instance, an image or video can provide valuable visual cues that complement textual information, leading to more precise language generation [51, 199]. By fusing multiple modalities, multi-modal RA-LLMs can develop a more comprehensive understanding of the world, leading to more accurate and insightful outputs, benefiting a wide range of domains, including healthcare [199], drug discovery [136], molecular analysis [3, 90], etc. 

Quality of External Knowledge. As a commonly used datastore in current RAG systems, Wikipedia [61, 199] serves as a vast repository of external textual knowledge used to augment the generation process, which contains millions of articles covering various disciplines. However, the reliability and accuracy of individual articles within Wikipedia vary significantly, and the introduction of some texts that deviate from facts might even mislead the model’s generation process. Therefore, it is crucial to enhance the quality of the external knowledge corpus and mitigate the negative impact of lowquality knowledge on the performance of LLMs. By enhancing the quality of the external knowledge and tailing robust mechanisms by filtering out low-quality or unreliable information, the RA-LLM systems might produce more accurate, reliable outputs, thereby improving their effectiveness in various real-world applications. 

# 7 CONCLUSION

Retrieval-augmented generation (RAG), a cutting-edge AI technique, has achieved remarkable success across various applications, including recommendation, molecule generation, protein representation, and software engineering, owing to the potent capabilities of retrieval in providing supplementary information to enhance generation performance. Recently, increasing efforts have been made to alleviate the limitations of large language models (LLMs), such as hallucination and out-of-date internal knowledge, by leveraging retrieval to provide the latest auxiliary information and teaching LLMs to harness the retrieved external knowledge. With the rapid advancements in retrieval-augmented large language models (RA-LLMs), there is a pressing need for a comprehensive and systematic overview. To bridge this gap, in this paper, we comprehensively review the RA-LLMs from the perspectives of morel architecture, training strategy, and application area, providing researchers with an in-depth understanding. Moreover, since the studies of RA-LLMs are still in the early stage, we also discuss the current limitations and several potential research directions for future research. 

# REFERENCES



[1] Josh Achiam, Steven Adler, Sandhini Agarwal, Lama Ahmad, Ilge Akkaya, Florencia Leoni Aleman, Diogo Almeida, Janko Altenschmidt, Sam Altman, Shyamal Anadkat, et al. 2023. Gpt-4 technical report. arXiv preprint arXiv:2303.08774 (2023). 





[2] Sweta Agrawal, Chunting Zhou, Mike Lewis, Luke Zettlemoyer, and Marjan Ghazvininejad. 2023. In-context Examples Selection for Machine Translation. In ACL (Findings). Association for Computational Linguistics, 8857–8873. 





[3] Miles C Andrews, Junna Oba, Chang-Jiun Wu, Haifeng Zhu, Tatiana Karpinets, Caitlin A Creasy, Marie-Andrée Forget, Xiaoxing Yu, Xingzhi Song, Xizeng Mao, et al. 2022. Multi-modal molecular programs regulate melanoma cell state. Nature communications 13, 1 (2022), 4000. 





[4] Akari Asai, Sewon Min, Zexuan Zhong, and Danqi Chen. 2023. Retrieval-based language models and applications. In Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 6: Tutorial Abstracts). 41–46. 





[5] Akari Asai, Zeqiu Wu, Yizhong Wang, Avirup Sil, and Hannaneh Hajishirzi. 2023. Self-RAG: Learning to Retrieve, Generate, and Critique through Self-Reflection. In The Twelfth International Conference on Learning Representations. 





[6] Sebastian Borgeaud, Arthur Mensch, Jordan Hoffmann, Trevor Cai, Eliza Rutherford, Katie Millican, George Bm Van Den Driessche, Jean-Baptiste Lespiau, Bogdan Damoc, Aidan Clark, et al. 2022. Improving language models by retrieving from trillions of tokens. In International conference on machine learning. PMLR, 2206–2240. 





[7] Tom Brown, Benjamin Mann, Nick Ryder, Melanie Subbiah, Jared D Kaplan, Prafulla Dhariwal, Arvind Neelakantan, Pranav Shyam, Girish Sastry, Amanda Askell, et al. 2020. Language models are few-shot learners. Advances in neural information processing systems 33 (2020), 1877–1901. 





[8] Stefan Buttcher, Charles LA Clarke, and Gordon V Cormack. 2016. Information retrieval: Implementing and evaluating search engines. Mit Press. 





[9] Charlie Chen, Sebastian Borgeaud, Geoffrey Irving, Jean-Baptiste Lespiau, Laurent Sifre, and John Jumper. 2023. Accelerating large language model decoding with speculative sampling. arXiv preprint arXiv:2302.01318 (2023). 





[10] Danqi Chen, Adam Fisch, Jason Weston, and Antoine Bordes. 2017. Reading Wikipedia to Answer Open-Domain Questions. In ACL (1). Association for Computational Linguistics, 1870–1879. 





[11] Jingfan Chen, Wenqi Fan, Guanghui Zhu, Xiangyu Zhao, Chunfeng Yuan, Qing Li, and Yihua Huang. 2022. Knowledge-enhanced Black-box Attacks for Recommendations. In Proceedings of the 28th ACM SIGKDD Conference on Knowledge Discovery and Data Mining. 108–117. 





[12] Mark Chen, Jerry Tworek, Heewoo Jun, Qiming Yuan, Henrique Ponde de Oliveira Pinto, Jared Kaplan, Harri Edwards, Yuri Burda, Nicholas Joseph, Greg Brockman, et al. 2021. Evaluating large language models trained on code. arXiv preprint arXiv:2107.03374 (2021). 





[13] Xiao Chen, Wenqi Fan, Jingfan Chen, Haochen Liu, Zitao Liu, Zhaoxiang Zhang, and Qing Li. 2023. Fairly adaptive negative sampling for recommendations. In Proceedings of the ACM Web Conference 2023. 3723–3733. 





[14] Xiuyi Chen, Fandong Meng, Peng Li, Feilong Chen, Shuang Xu, Bo Xu, and Jie Zhou. 2020. Bridging the gap between prior and posterior knowledge selection for knowledge-grounded dialogue generation. In Proceedings of the 2020 conference on empirical methods in natural language processing (EMNLP). 3426–3437. 





[15] Yudong Chen, Zhihui Lai, Yujuan Ding, Kaiyi Lin, and Wai Keung Wong. 2019. Deep supervised hashing with anchor graph. In Proceedings of the IEEE/CVF international conference on computer vision. 9796–9804. 





[16] Daixuan Cheng, Shaohan Huang, Junyu Bi, Yuefeng Zhan, Jianfeng Liu, Yujing Wang, Hao Sun, Furu Wei, Weiwei Deng, and Qi Zhang. 2023. UPRISE: Universal Prompt Retrieval for Improving Zero-Shot Evaluation. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing. 12318–12337. 





[17] Xin Cheng, Di Luo, Xiuying Chen, Lemao Liu, Dongyan Zhao, and Rui Yan. 2024. Lift yourself up: Retrieval-augmented text generation with self-memory. Advances in Neural Information Processing Systems 36 (2024). 





[18] Aakanksha Chowdhery, Sharan Narang, Jacob Devlin, Maarten Bosma, Gaurav Mishra, Adam Roberts, Paul Barham, Hyung Won Chung, Charles Sutton, Sebastian Gehrmann, et al. 2023. Palm: Scaling language modeling with pathways. Journal of Machine Learning Research 24, 240 (2023), 1–113. 





[19] W Bruce Croft, Donald Metzler, and Trevor Strohman. 2010. Search engines: Information retrieval in practice. Vol. 520. Addison-Wesley Reading. 





[20] Leyang Cui, Yu Wu, Jian Liu, Sen Yang, and Yue Zhang. 2021. Template-Based Named Entity Recognition Using BART. In ACL/IJCNLP (Findings) (Findings of ACL, Vol. ACL/IJCNLP 2021). Association for Computational Linguistics, 1835– 1845. 





[21] Matthew Dahl, Varun Magesh, Mirac Suzgun, and Daniel E Ho. 2024. Large legal fictions: Profiling legal hallucinations in large language models. arXiv preprint arXiv:2401.01301 (2024). 





[22] Michiel de Jong, Yury Zemlyanskiy, Nicholas FitzGerald, Fei Sha, and William W. Cohen. 2022. Mention Memory: incorporating textual knowledge into Transformers through entity mention attention. In ICLR. OpenReview.net. 





[23] Gelei Deng, Yi Liu, Kailong Wang, Yuekang Li, Tianwei Zhang, and Yang Liu. 2024. Pandora: Jailbreak GPTs by Retrieval Augmented Generation Poisoning. arXiv preprint arXiv:2402.08416 (2024). 





[24] Ziqing Deng, Zhihui Lai, Yujuan Ding, Heng Kong, and Xu Wu. 2024. Deep Scaling Factor Quantization Network for Large-scale Image Retrieval. In ICMR. ACM, 851–859. 





[25] Jacob Devlin, Ming-Wei Chang, Kenton Lee, and Kristina Toutanova. 2019. BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding. In NAACL-HLT (1). Association for Computational Linguistics, 4171–4186. 





[26] Dario Di Palma. 2023. Retrieval-augmented recommender system: Enhancing recommender systems with large language models. In Proceedings of the 17th ACM Conference on Recommender Systems. 1369–1373. 





[27] Yujuan Ding, Yunshan Ma, Wenqi Fan, Yige Yao, Tat-Seng Chua, and Qing Li. 2024. FashionReGen: LLM-Empowered Fashion Report Generation. arXiv preprint arXiv:2403.06660 (2024). 





[28] Yujuan Ding, P. Y. Mok, Yunshan Ma, and Yi Bin. 2023. Personalized fashion outfit generation with user coordination preference learning. Inf. Process. Manag. 60, 5 (2023), 103434. 





[29] Yujuan Ding, Wai Keung Wong, Zhihui Lai, and Zheng Zhang. 2020. Bilinear Supervised Hashing Based on 2D Image Features. IEEE Trans. Circuits Syst. Video Technol. 30, 2 (2020), 590–602. 





[30] Yujuan Ding, Wai Keung Wong, Zhihui Lai, and Zheng Zhang. 2020. Discriminative dual-stream deep hashing for large-scale image retrieval. Information Processing & Management 57, 6 (2020), 102288. 





[31] Andrew Drozdov, Nathanael Schärli, Ekin Akyürek, Nathan Scales, Xinying Song, Xinyun Chen, Olivier Bousquet, and Denny Zhou. 2022. Compositional semantic parsing with large language models. In The Eleventh International Conference on Learning Representations. 





[32] Wenqi Fan, Tyler Derr, Xiangyu Zhao, Yao Ma, Hui Liu, Jianping Wang, Jiliang Tang, and Qing Li. 2021. Attacking black-box recommendations via copying 





cross-domain user profiles. In 2021 IEEE 37th International Conference on Data Engineering (ICDE). IEEE, 1583–1594. 





[33] Wenqi Fan, Yujuan Ding, Liangbo Ning, Shijie Wang, Hengyun Li, Dawei Yin, Tat-Seng Chua, and Qing Li. 2024. A Survey on RAG Meeting LLMs: Towards Retrieval-Augmented Large Language Models. Proroceedings of the 30th ACM SIGKDD Conference on Knowledge Discovery & Data Mining (2024). 





[34] Wenqi Fan, Xiaorui Liu, Wei Jin, Xiangyu Zhao, Jiliang Tang, and Qing Li. 2022. Graph Trend Filtering Networks for Recommendation. In Proceedings of the 45th International ACM SIGIR Conference on Research and Development in Information Retrieval. 112–121. 





[35] Wenqi Fan, Yao Ma, Qing Li, Yuan He, Eric Zhao, Jiliang Tang, and Dawei Yin. 2019. Graph neural networks for social recommendation. In The world wide web conference. 417–426. 





[36] Wenqi Fan, Yao Ma, Qing Li, Jianping Wang, Guoyong Cai, Jiliang Tang, and Dawei Yin. 2020. A graph neural network framework for social recommendations. IEEE Transactions on Knowledge and Data Engineering (2020). 





[37] Wenqi Fan, Shijie Wang, Jiani Huang, Zhikai Chen, Yu Song, Wenzhuo Tang, Haitao Mao, Hui Liu, Xiaorui Liu, Dawei Yin, et al. 2024. Graph Machine Learning in the Era of Large Language Models (LLMs). arXiv preprint arXiv:2404.14928 (2024). 





[38] Wenqi Fan, Xiangyu Zhao, Xiao Chen, Jingran Su, Jingtong Gao, Lin Wang, Qidong Liu, Yiqi Wang, Han Xu, Lei Chen, et al. 2022. A Comprehensive Survey on Trustworthy Recommender Systems. arXiv preprint arXiv:2209.10117 (2022). 





[39] Thibault Févry, Livio Baldini Soares, Nicholas FitzGerald, Eunsol Choi, and Tom Kwiatkowski. 2020. Entities as Experts: Sparse Memory Access with Entity Supervision. In EMNLP (1). Association for Computational Linguistics, 4937– 4951. 





[40] Luyu Gao, Xueguang Ma, Jimmy Lin, and Jamie Callan. 2023. Precise Zero-Shot Dense Retrieval without Relevance Labels. In ACL (1). Association for Computational Linguistics, 1762–1777. 





[41] Yunfan Gao, Yun Xiong, Xinyu Gao, Kangxiang Jia, Jinliu Pan, Yuxi Bi, Yi Dai, Jiawei Sun, and Haofen Wang. 2023. Retrieval-augmented generation for large language models: A survey. arXiv preprint arXiv:2312.10997 (2023). 





[42] Izacard Gautier, Caron Mathilde, Hosseini Lucas, Riedel Sebastian, Bojanowski Piotr, Joulin Armand, and Grave Edouard. 2022. Unsupervised dense information retrieval with contrastive learning. Transactions on Machine Learning Research (2022). 





[43] Marjan Ghazvininejad, Chris Brockett, Ming-Wei Chang, Bill Dolan, Jianfeng Gao, Wen-tau Yih, and Michel Galley. 2018. A knowledge-grounded neural conversation model. In Proceedings of the AAAI Conference on Artificial Intelligence, Vol. 32. 





[44] Michael R. Glass, Gaetano Rossiello, Md. Faisal Mahbub Chowdhury, Ankita Naik, Pengshan Cai, and Alfio Gliozzo. 2022. Re2G: Retrieve, Rerank, Generate. In NAACL-HLT. Association for Computational Linguistics, 2701–2715. 





[45] Edouard Grave, Armand Joulin, and Nicolas Usunier. 2017. Improving Neural Language Models with a Continuous Cache. In ICLR (Poster). OpenReview.net. 





[46] Kelvin Guu, Kenton Lee, Zora Tung, Panupong Pasupat, and Mingwei Chang. 2020. Retrieval augmented language model pre-training. In International conference on machine learning. PMLR, 3929–3938. 





[47] Junxian He, Graham Neubig, and Taylor Berg-Kirkpatrick. 2021. Efficient Nearest Neighbor Language Models. In EMNLP (1). Association for Computational Linguistics, 5703–5714. 





[48] Qiuxiang He, Guoping Huang, Qu Cui, Li Li, and Lemao Liu. 2021. Fast and accurate neural machine translation with translation memory. In Proceedings of the 59th Annual Meeting of the Association for Computational Linguistics and the 11th International Joint Conference on Natural Language Processing (Volume 1: Long Papers). 3170–3180. 





[49] Zhenyu He, Zexuan Zhong, Tianle Cai, Jason D Lee, and Di He. 2023. Rest: Retrieval-based speculative decoding. arXiv preprint arXiv:2311.08252 (2023). 





[50] Sebastian Hofstätter, Jiecao Chen, Karthik Raman, and Hamed Zamani. 2023. FiD-Light: Efficient and Effective Retrieval-Augmented Text Generation. In SIGIR. ACM, 1437–1447. 





[51] Ziniu Hu, Ahmet Iscen, Chen Sun, Zirui Wang, Kai-Wei Chang, Yizhou Sun, Cordelia Schmid, David A Ross, and Alireza Fathi. 2023. Reveal: Retrievalaugmented visual-language pre-training with multi-source multimodal knowledge memory. In Proceedings of the IEEE/CVF conference on computer vision and pattern recognition. 23369–23379. 





[52] Jie Huang, Wei Ping, Peng Xu, Mohammad Shoeybi, Kevin Chen-Chuan Chang, and Bryan Catanzaro. 2023. Raven: In-context learning with retrieval augmented encoder-decoder language models. arXiv preprint arXiv:2308.07922 (2023). 





[53] Gautier Izacard and Edouard Grave. 2021. Distilling Knowledge from Reader to Retriever for Question Answering. In ICLR 2021-9th International Conference on Learning Representations. 





[54] Gautier Izacard and Edouard Grave. 2021. Leveraging Passage Retrieval with Generative Models for Open Domain Question Answering. In EACL 2021-16th Conference of the European Chapter of the Association for Computational Linguistics. Association for Computational Linguistics, 874–880. 





[55] Gautier Izacard, Patrick Lewis, Maria Lomeli, Lucas Hosseini, Fabio Petroni, Timo Schick, Jane Dwivedi-Yu, Armand Joulin, Sebastian Riedel, and Edouard 





Grave. 2023. Atlas: Few-shot Learning with Retrieval Augmented Language Models. Journal of Machine Learning Research 24, 251 (2023), 1–43. 





[56] Zhengbao Jiang, Jun Araki, Haibo Ding, and Graham Neubig. 2021. How can we know when language models know? on the calibration of language models for question answering. Transactions of the Association for Computational Linguistics 9 (2021), 962–977. 





[57] Zhengbao Jiang, Frank F Xu, Luyu Gao, Zhiqing Sun, Qian Liu, Jane Dwivedi-Yu, Yiming Yang, Jamie Callan, and Graham Neubig. 2023. Active Retrieval Augmented Generation. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing. 7969–7992. 





[58] Anubha Kabra, Emmy Liu, Simran Khanuja, Alham Fikri Aji, Genta Winata, Samuel Cahyawijaya, Anuoluwapo Aremu, Perez Ogayo, and Graham Neubig. 2023. Multi-lingual and Multi-cultural Figurative Language Understanding. In The 61st Annual Meeting Of The Association For Computational Linguistics. 





[59] Saurav Kadavath, Tom Conerly, Amanda Askell, Tom Henighan, Dawn Drain, Ethan Perez, Nicholas Schiefer, Zac Hatfield-Dodds, Nova DasSarma, Eli Tran-Johnson, et al. 2022. Language models (mostly) know what they know. arXiv preprint arXiv:2207.05221 (2022). 





[60] Minki Kang, Jin Myung Kwak, Jinheon Baek, and Sung Ju Hwang. 2023. Knowledge graph-augmented language models for knowledge-grounded dialogue generation. arXiv preprint arXiv:2305.18846 (2023). 





[61] Vladimir Karpukhin, Barlas Oguz, Sewon Min, Patrick S. H. Lewis, Ledell Wu, Sergey Edunov, Danqi Chen, and Wen-tau Yih. 2020. Dense Passage Retrieval for Open-Domain Question Answering. In EMNLP (1). Association for Computational Linguistics, 6769–6781. 





[62] Urvashi Khandelwal, Omer Levy, Dan Jurafsky, Luke Zettlemoyer, and Mike Lewis. 2020. Generalization through Memorization: Nearest Neighbor Language Models. In International Conference on Learning Representations. 





[63] Omar Khattab, Keshav Santhanam, Xiang Lisa Li, David Hall, Percy Liang, Christopher Potts, and Matei Zaharia. 2022. Demonstrate-search-predict: Composing retrieval and language models for knowledge-intensive nlp. arXiv preprint arXiv:2212.14024 (2022). 





[64] Omar Khattab and Matei Zaharia. 2020. Colbert: Efficient and effective passage search via contextualized late interaction over bert. In Proceedings of the 43rd International ACM SIGIR conference on research and development in Information Retrieval. 39–48. 





[65] Gangwoo Kim, Sungdong Kim, Byeongguk Jeon, Joonsuk Park, and Jaewoo Kang. 2023. Tree of Clarifications: Answering Ambiguous Questions with Retrieval-Augmented Large Language Models. In The 2023 Conference on Empirical Methods in Natural Language Processing. 





[66] Hyuhng Joon Kim, Hyunsoo Cho, Junyeob Kim, Taeuk Kim, Kang Min Yoo, and Sang-goo Lee. 2022. Self-generated in-context learning: Leveraging autoregressive language models as a demonstration generator. arXiv preprint arXiv:2206.08082 (2022). 





[67] Mei Kobayashi and Koichi Takeda. 2000. Information retrieval on the web. ACM computing surveys (CSUR) 32, 2 (2000), 144–173. 





[68] Mojtaba Komeili, Kurt Shuster, and Jason Weston. 2022. Internet-Augmented Dialogue Generation. In ACL (1). Association for Computational Linguistics, 8460–8478. 





[69] Tian Lan, Deng Cai, Yan Wang, Heyan Huang, and Xian-Ling Mao. 2022. Copy is All You Need. In The Eleventh International Conference on Learning Representations. 





[70] Angeliki Lazaridou, Elena Gribovskaya, Wojciech Stokowiec, and Nikolai Grigorev. 2022. Internet-augmented language models through few-shot prompting for open-domain question answering. arXiv preprint arXiv:2203.05115 (2022). 





[71] Yaniv Leviathan, Matan Kalman, and Yossi Matias. 2023. Fast inference from transformers via speculative decoding. In International Conference on Machine Learning. PMLR, 19274–19286. 





[72] Mike Lewis, Marjan Ghazvininejad, Gargi Ghosh, Armen Aghajanyan, Sida Wang, and Luke Zettlemoyer. 2020. Pre-training via paraphrasing. Advances in Neural Information Processing Systems 33 (2020), 18470–18481. 





[73] Mike Lewis, Yinhan Liu, Naman Goyal, Marjan Ghazvininejad, Abdelrahman Mohamed, Omer Levy, Veselin Stoyanov, and Luke Zettlemoyer. 2020. BART: Denoising Sequence-to-Sequence Pre-training for Natural Language Generation, Translation, and Comprehension. In ACL. Association for Computational Linguistics, 7871–7880. 





[74] Patrick Lewis, Ethan Perez, Aleksandra Piktus, Fabio Petroni, Vladimir Karpukhin, Naman Goyal, Heinrich Küttler, Mike Lewis, Wen-tau Yih, Tim Rocktäschel, et al. 2020. Retrieval-augmented generation for knowledge-intensive nlp tasks. Advances in Neural Information Processing Systems 33 (2020), 9459–9474. 





[75] Daliang Li, Ankit Singh Rawat, Manzil Zaheer, Xin Wang, Michal Lukasik, Andreas Veit, Felix Yu, and Sanjiv Kumar. 2022. Large language models with controllable working memory. arXiv preprint arXiv:2211.05110 (2022). 





[76] Hongxin Li, Jingran Su, Yuntao Chen, Qing Li, and ZHAO-XIANG ZHANG. 2024. SheetCopilot: Bringing Software Productivity to the Next Level through Large Language Models. Advances in Neural Information Processing Systems 36 (2024). 





[77] Jiatong Li, Yunqing Liu, Wenqi Fan, Xiao-Yong Wei, Hui Liu, Jiliang Tang, and Qing Li. 2023. Empowering Molecule Discovery for Molecule-Caption Translation with Large Language Models: A ChatGPT Perspective. arXiv preprint arXiv:2306.06615 (2023). 





[78] Xiang Li, Zhenyu Li, Chen Shi, Yong Xu, Qing Du, Mingkui Tan, Jun Huang, and Wei Lin. 2024. AlphaFin: Benchmarking Financial Analysis with Retrieval-Augmented Stock-Chain Framework. arXiv preprint arXiv:2403.12582 (2024). 





[79] Xinze Li, Zhenghao Liu, Chenyan Xiong, Shi Yu, Yu Gu, Zhiyuan Liu, and Ge Yu. 2023. Structure-Aware Language Model Pretraining Improves Dense Retrieval on Structured Data. In The 61st Annual Meeting Of The Association For Computational Linguistics. 





[80] Xiaonan Li, Kai Lv, Hang Yan, Tianyang Lin, Wei Zhu, Yuan Ni, Guotong Xie, Xiaoling Wang, and Xipeng Qiu. 2023. Unified Demonstration Retriever for In-Context Learning. In ACL (1). Association for Computational Linguistics, 4644–4668. 





[81] Xiaoqian Li, Ercong Nie, and Sheng Liang. 2023. From Classification to Generation: Insights into Crosslingual Retrieval Augmented ICL. In NeurIPS 2023 Workshop on Instruction Tuning and Instruction Following. 





[82] Xiaonan Li and Xipeng Qiu. 2023. MoT: Memory-of-Thought Enables ChatGPT to Self-Improve. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing. Association for Computational Linguistics, Singapore, 6354–6374. 





[83] Xiang Lisa Li and Percy Liang. 2021. Prefix-Tuning: Optimizing Continuous Prompts for Generation. In ACL/IJCNLP (1). Association for Computational Linguistics, 4582–4597. 





[84] Zonglin Li, Ruiqi Guo, and Sanjiv Kumar. 2022. Decoupled context processing for context augmented language modeling. Advances in Neural Information Processing Systems 35 (2022), 21698–21710. 





[85] Demiao Lin. 2024. Revolutionizing Retrieval-Augmented Generation with Enhanced PDF Structure Recognition. arXiv preprint arXiv:2401.12599 (2024). 





[86] Xi Victoria Lin, Xilun Chen, Mingda Chen, Weijia Shi, Maria Lomeli, Richard James, Pedro Rodriguez, Jacob Kahn, Gergely Szilvasy, Mike Lewis, et al. 2023. RA-DIT: Retrieval-Augmented Dual Instruction Tuning. In The Twelfth International Conference on Learning Representations. 





[87] Haochen Liu, Jamell Dacon, Wenqi Fan, Hui Liu, Zitao Liu, and Jiliang Tang. 2020. Does Gender Matter? Towards Fairness in Dialogue Systems. In Proceedings of the 28th International Conference on Computational Linguistics. 4403–4416. 





[88] Haochen Liu, Yiqi Wang, Wenqi Fan, Xiaorui Liu, Yaxin Li, Shaili Jain, Yunhao Liu, Anil K Jain, and Jiliang Tang. 2021. Trustworthy ai: A computational perspective. arXiv preprint arXiv:2107.06641 (2021). 





[89] Jiachang Liu, Dinghan Shen, Yizhe Zhang, Bill Dolan, Lawrence Carin, and Weizhu Chen. 2022. What Makes Good In-Context Examples for GPT-3?. In DeeLIO@ACL. Association for Computational Linguistics, 100–114. 





[90] Shengchao Liu, Weili Nie, Chengpeng Wang, Jiarui Lu, Zhuoran Qiao, Ling Liu, Jian Tang, Chaowei Xiao, and Animashree Anandkumar. 2023. Multi-modal molecule structure–text model for text-based retrieval and editing. Nature Machine Intelligence 5, 12 (2023), 1447–1457. 





[91] Ye Liu, Semih Yavuz, Rui Meng, Dragomir Radev, Caiming Xiong, and Yingbo Zhou. 2022. Uni-Parser: Unified Semantic Parser for Question Answering on Knowledge Base and Database. In EMNLP. Association for Computational Linguistics, 8858–8869. 





[92] Alejandro Lozano, Scott L Fleming, Chia-Chun Chiang, and Nigam Shah. 2023. Clinfo. ai: An open-source retrieval-augmented large language model system for answering medical questions using scientific literature. In PACIFIC SYMPOSIUM ON BIOCOMPUTING 2024. World Scientific, 8–23. 





[93] Pan Lu, Liang Qiu, Kai-Wei Chang, Ying Nian Wu, Song-Chun Zhu, Tanmay Rajpurohit, Peter Clark, and Ashwin Kalyan. 2023. Dynamic Prompt Learning via Policy Gradient for Semi-structured Mathematical Reasoning. In ICLR. OpenReview.net. 





[94] Yu Lu, Junwei Bao, Yan Song, Zichen Ma, Shuguang Cui, Youzheng Wu, and Xiaodong He. 2021. RevCore: Review-Augmented Conversational Recommendation. In ACL/IJCNLP (Findings) (Findings of ACL, Vol. ACL/IJCNLP 2021). Association for Computational Linguistics, 1161–1173. 





[95] Hongyin Luo, Tianhua Zhang, Yung-Sung Chuang, Yuan Gong, Yoon Kim, Xixin Wu, Helen Meng, and James R. Glass. 2023. Search Augmented Instruction Learning. In EMNLP (Findings). Association for Computational Linguistics, 3717– 3729. 





[96] Man Luo, Xin Xu, Zhuyun Dai, Panupong Pasupat, Mehran Kazemi, Chitta Baral, Vaiva Imbrasaite, and Vincent Y Zhao. 2023. Dr. icl: Demonstration-retrieved in-context learning. arXiv preprint arXiv:2305.14128 (2023). 





[97] Chang Ma, Haiteng Zhao, Lin Zheng, Jiayi Xin, Qintong Li, Lijun Wu, Zhihong Deng, Yang Lu, Qi Liu, and Lingpeng Kong. 2023. Retrieved Sequence Augmentation for Protein Representation Learning. bioRxiv (2023), 2023–02. 





[98] Xinbei Ma, Yeyun Gong, Pengcheng He, Hai Zhao, and Nan Duan. 2023. Query rewriting for retrieval-augmented large language models. arXiv preprint arXiv:2305.14283 (2023). 





[99] Seiji Maekawa, Hayate Iso, Sairam Gurajada, and Nikita Bhutani. 2024. Retrieval Helps or Hurts? A Deeper Dive into the Efficacy of Retrieval Augmentation to 





Language Models. arXiv preprint arXiv:2402.13492 (2024). 





[100] Jacob Menick, Maja Trebacz, Vladimir Mikulik, John Aslanides, Francis Song, Martin Chadwick, Mia Glaese, Susannah Young, Lucy Campbell-Gillingham, Geoffrey Irving, et al. 2022. Teaching language models to support answers with verified quotes. arXiv preprint arXiv:2203.11147 (2022). 





[101] Aristides Milios, Siva Reddy, and Dzmitry Bahdanau. 2023. In-context learning for text classification with many labels. In Proceedings of the 1st GenBench Workshop on (Benchmarking) Generalisation in NLP. 173–184. 





[102] Sewon Min, Xinxi Lyu, Ari Holtzman, Mikel Artetxe, Mike Lewis, Hannaneh Hajishirzi, and Luke Zettlemoyer. 2022. Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?. In EMNLP. Association for Computational Linguistics, 11048–11064. 





[103] Sewon Min, Julian Michael, Hannaneh Hajishirzi, and Luke Zettlemoyer. 2020. AmbigQA: Answering Ambiguous Open-domain Questions. In EMNLP (1). Association for Computational Linguistics, 5783–5797. 





[104] Sewon Min, Weijia Shi, Mike Lewis, Xilun Chen, Wen-tau Yih, Hannaneh Hajishirzi, and Luke Zettlemoyer. 2023. Nonparametric Masked Language Modeling. In ACL (Findings). Association for Computational Linguistics, 2097–2118. 





[105] Noor Nashid, Mifta Sintaha, and Ali Mesbah. 2023. Retrieval-based prompt selection for code-related few-shot learning. In 2023 IEEE/ACM 45th International Conference on Software Engineering (ICSE). IEEE, 2450–2462. 





[106] Neil O’Hare, Paloma De Juan, Rossano Schifanella, Yunlong He, Dawei Yin, and Yi Chang. 2016. Leveraging user interaction signals for web image search. In Proceedings of the 39th International ACM SIGIR conference on Research and Development in Information Retrieval. 559–568. 





[107] Long Ouyang, Jeffrey Wu, Xu Jiang, Diogo Almeida, Carroll Wainwright, Pamela Mishkin, Chong Zhang, Sandhini Agarwal, Katarina Slama, Alex Ray, et al. 2022. Training language models to follow instructions with human feedback. Advances in neural information processing systems 35 (2022), 27730–27744. 





[108] Md. Rizwan Parvez, Wasi Uddin Ahmad, Saikat Chakraborty, Baishakhi Ray, and Kai-Wei Chang. 2021. Retrieval Augmented Code Generation and Summarization. In EMNLP (Findings). Association for Computational Linguistics, 2719–2734. 





[109] Fabio Petroni, Patrick S. H. Lewis, Aleksandra Piktus, Tim Rocktäschel, Yuxiang Wu, Alexander H. Miller, and Sebastian Riedel. 2020. How Context Affects Language Models’ Factual Predictions. In AKBC. 





[110] Fabio Petroni, Tim Rocktäschel, Patrick Lewis, Anton Bakhtin, Yuxiang Wu, Alexander H Miller, and Sebastian Riedel. 2019. Language models as knowledge bases? arXiv preprint arXiv:1909.01066 (2019). 





[111] Gabriel Poesia, Alex Polozov, Vu Le, Ashish Tiwari, Gustavo Soares, Christopher Meek, and Sumit Gulwani. 2022. Synchromesh: Reliable Code Generation from Pre-trained Language Models. In ICLR. OpenReview.net. 





[112] Anupam Purwar and Rahul Sundar. 2023. Keyword Augmented Retrieval: Novel framework for Information Retrieval integrated with speech interface. arXiv preprint arXiv:2310.04205 (2023). 





[113] Alec Radford, Jong Wook Kim, Chris Hallacy, Aditya Ramesh, Gabriel Goh, Sandhini Agarwal, Girish Sastry, Amanda Askell, Pamela Mishkin, Jack Clark, et al. 2021. Learning transferable visual models from natural language supervision. In International conference on machine learning. PMLR, 8748–8763. 





[114] Alec Radford, Karthik Narasimhan, Tim Salimans, Ilya Sutskever, et al. 2018. Improving language understanding by generative pre-training. (2018). 





[115] Alec Radford, Jeffrey Wu, Rewon Child, David Luan, Dario Amodei, Ilya Sutskever, et al. 2019. Language models are unsupervised multitask learners. OpenAI blog 1, 8 (2019), 9. 





[116] Colin Raffel, Noam Shazeer, Adam Roberts, Katherine Lee, Sharan Narang, Michael Matena, Yanqi Zhou, Wei Li, and Peter J Liu. 2020. Exploring the limits of transfer learning with a unified text-to-text transformer. Journal of machine learning research 21, 140 (2020), 1–67. 





[117] Ori Ram, Yoav Levine, Itay Dalmedigos, Dor Muhlgay, Amnon Shashua, Kevin Leyton-Brown, and Yoav Shoham. 2023. In-context retrieval-augmented language models. Transactions of the Association for Computational Linguistics 11 (2023), 1316–1331. 





[118] Ori Ram, Gal Shachaf, Omer Levy, Jonathan Berant, and Amir Globerson. 2022. Learning to Retrieve Passages without Supervision. In NAACL-HLT. Association for Computational Linguistics, 2687–2700. 





[119] Parikshit Ram and Alexander G Gray. 2012. Maximum inner-product search using cone trees. In Proceedings of the 18th ACM SIGKDD international conference on Knowledge discovery and data mining. 931–939. 





[120] Juan Ramos et al. 2003. Using tf-idf to determine word relevance in document queries. In Proceedings of the first instructional conference on machine learning, Vol. 242. Citeseer, 29–48. 





[121] Rita Ramos, Bruno Martins, Desmond Elliott, and Yova Kementchedjhieva. 2023. Smallcap: lightweight image captioning prompted with retrieval augmentation. In Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition. 2840–2849. 





[122] Benjamin Z. Reichman and Larry Heck. 2024. Retrieval-Augmented Generation: Is Dense Passage Retrieval Retrieving? CoRR abs/2402.11035 (2024). 





[123] Nils Reimers and Iryna Gurevych. 2019. Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. In Proceedings of the 2019 Conference on Empirical Methods in Natural Language Processing and the 9th International Joint Conference on Natural Language Processing (EMNLP-IJCNLP). 3982–3992. 





[124] Yubing Ren, Yanan Cao, Ping Guo, Fang Fang, Wei Ma, and Zheng Lin. 2023. Retrieve-and-sample: Document-level event argument extraction via hybrid retrieval augmentation. In Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers). 293–306. 





[125] Stephen Robertson, Hugo Zaragoza, et al. 2009. The probabilistic relevance framework: BM25 and beyond. Foundations and Trends® in Information Retrieval 3, 4 (2009), 333–389. 





[126] Ohad Rubin, Jonathan Herzig, and Jonathan Berant. 2022. Learning To Retrieve Prompts for In-Context Learning. In NAACL-HLT. Association for Computational Linguistics, 2655–2671. 





[127] Sara Sarto, Marcella Cornia, Lorenzo Baraldi, and Rita Cucchiara. 2022. Retrievalaugmented transformer for image captioning. In Proceedings of the 19th international conference on content-based multimedia indexing. 1–7. 





[128] Timo Schick, Jane Dwivedi-Yu, Roberto Dessì, Roberta Raileanu, Maria Lomeli, Eric Hambro, Luke Zettlemoyer, Nicola Cancedda, and Thomas Scialom. 2024. Toolformer: Language models can teach themselves to use tools. Advances in Neural Information Processing Systems 36 (2024). 





[129] Minjoon Seo, Jinhyuk Lee, Tom Kwiatkowski, Ankur P Parikh, Ali Farhadi, and Hannaneh Hajishirzi. 2019. Real-time open-domain question answering with dense-sparse phrase index. arXiv preprint arXiv:1906.05807 (2019). 





[130] Zhihong Shao, Yeyun Gong, Minlie Huang, Nan Duan, Weizhu Chen, et al. 2023. Enhancing Retrieval-Augmented Large Language Models with Iterative Retrieval-Generation Synergy. In The 2023 Conference on Empirical Methods in Natural Language Processing. 





[131] Fumin Shen, Wei Liu, Shaoting Zhang, Yang Yang, and Heng Tao Shen. 2015. Learning binary codes for maximum inner product search. In Proceedings of the IEEE International Conference on Computer Vision. 4148–4156. 





[132] Shelly Sheynin, Oron Ashual, Adam Polyak, Uriel Singer, Oran Gafni, Eliya Nachmani, and Yaniv Taigman. 2023. kNN-Diffusion: Image Generation via Large-Scale Retrieval. In ICLR. OpenReview.net. 





[133] Kaize Shi, Xueyao Sun, Qing Li, and Guandong Xu. 2024. Compressing Long Context for Enhancing RAG with AMR-based Concept Distillation. arXiv preprint arXiv:2405.03085 (2024). 





[134] Peng Shi, Rui Zhang, He Bai, and Jimmy Lin. 2022. XRICL: Cross-lingual Retrieval-Augmented In-Context Learning for Cross-lingual Text-to-SQL Semantic Parsing. In EMNLP (Findings). Association for Computational Linguistics, 5248–5259. 





[135] Weijia Shi, Sewon Min, Michihiro Yasunaga, Minjoon Seo, Rich James, Mike Lewis, Luke Zettlemoyer, and Wen-tau Yih. 2023. Replug: Retrieval-augmented black-box language models. arXiv preprint arXiv:2301.12652 (2023). 





[136] Guy Shtar. 2021. Multimodal machine learning for drug knowledge discovery. In Proceedings of the 14th ACM International Conference on Web Search and Data Mining. 1115–1116. 





[137] Kurt Shuster, Spencer Poff, Moya Chen, Douwe Kiela, and Jason Weston. 2021. Retrieval Augmentation Reduces Hallucination in Conversation. In EMNLP (Findings). Association for Computational Linguistics, 3784–3803. 





[138] Suzanna Sia and Kevin Duh. 2023. In-context learning as maintaining coherency: A study of on-the-fly machine translation using large language models. arXiv preprint arXiv:2305.03573 (2023). 





[139] Devendra Singh, Siva Reddy, Will Hamilton, Chris Dyer, and Dani Yogatama. 2021. End-to-end training of multi-document reader and retriever for opendomain question answering. Advances in Neural Information Processing Systems 34 (2021), 25968–25981. 





[140] Amit Singhal et al. 2001. Modern information retrieval: A brief overview. IEEE Data Eng. Bull. 24, 4 (2001), 35–43. 





[141] Shamane Siriwardhana, Rivindu Weerasekera, Elliott Wen, Tharindu Kaluarachchi, Rajib Rana, and Suranga Nanayakkara. 2023. Improving the domain adaptation of retrieval augmented generation (RAG) models for open domain question answering. Transactions of the Association for Computational Linguistics 11 (2023), 1–17. 





[142] Karen Sparck Jones. 1972. A statistical interpretation of term specificity and its application in retrieval. Journal of documentation 28, 1 (1972), 11–21. 





[143] Hongjin Su, Jungo Kasai, Chen Henry Wu, Weijia Shi, Tianlu Wang, Jiayi Xin, Rui Zhang, Mari Ostendorf, Luke Zettlemoyer, Noah A. Smith, and Tao Yu. 2023. Selective Annotation Makes Language Models Better Few-Shot Learners. In ICLR. OpenReview.net. 





[144] Fang Sun, Zhihao Zhan, Hongyu Guo, Ming Zhang, and Jian Tang. 2023. Graphvf: Controllable protein-specific 3d molecule generation with variational flow. arXiv preprint arXiv:2304.12825 (2023). 





[145] Ziteng Sun, Ananda Theertha Suresh, Jae Hun Ro, Ahmad Beirami, Himanshu Jain, and Felix Yu. 2024. Spectr: Fast speculative decoding via optimal transport. Advances in Neural Information Processing Systems 36 (2024). 





[146] Jiejun Tan, Zhicheng Dou, Yutao Zhu, Peidong Guo, Kun Fang, and Ji-Rong Wen. 2024. Small Models, Big Insights: Leveraging Slim Proxy Models To Decide 





When and What to Retrieve for LLMs. arXiv preprint arXiv:2402.12052 (2024). 





[147] Nandan Thakur, Luiz Bonifacio, Xinyu Zhang, Odunayo Ogundepo, Ehsan Kamalloo, David Alfonso-Hermelo, Xiaoguang Li, Qun Liu, Boxing Chen, Mehdi Rezagholizadeh, et al. 2023. NoMIRACL: Knowing When You Don’t Know for Robust Multilingual Retrieval-Augmented Generation. arXiv preprint arXiv:2312.11361 (2023). 





[148] Hugo Touvron, Louis Martin, Kevin Stone, Peter Albert, Amjad Almahairi, Yasmine Babaei, Nikolay Bashlykov, Soumya Batra, Prajjwal Bhargava, Shruti Bhosale, et al. 2023. Llama 2: Open foundation and fine-tuned chat models. arXiv preprint arXiv:2307.09288 (2023). 





[149] Harsh Trivedi, Niranjan Balasubramanian, Tushar Khot, and Ashish Sabharwal. 2023. Interleaving Retrieval with Chain-of-Thought Reasoning for Knowledge-Intensive Multi-Step Questions. In The 61st Annual Meeting Of The Association For Computational Linguistics. 





[150] Lifu Tu, Caiming Xiong, and Yingbo Zhou. 2022. Prompt-Tuning Can Be Much Better Than Fine-Tuning on Cross-lingual Understanding With Multilingual Language Models. In EMNLP (Findings). Association for Computational Linguistics, 5478–5485. 





[151] Tu Vu, Brian Lester, Noah Constant, Rami Al-Rfou’, and Daniel Cer. 2022. SPoT: Better Frozen Model Adaptation through Soft Prompt Transfer. In ACL (1). Association for Computational Linguistics, 5039–5059. 





[152] Ante Wang, Linfeng Song, Qi Liu, Haitao Mi, Longyue Wang, Zhaopeng Tu, Jinsong Su, and Dong Yu. 2023. Search-engine-augmented dialogue response generation with cheaply supervised query production. Artificial Intelligence 319 (2023), 103874. 





[153] Boxin Wang, Wei Ping, Peng Xu, Lawrence McAfee, Zihan Liu, Mohammad Shoeybi, Yi Dong, Oleksii Kuchaiev, Bo Li, Chaowei Xiao, et al. 2023. Shall We Pretrain Autoregressive Language Models with Retrieval? A Comprehensive Study. In Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing. 7763–7786. 





[154] Hanbing Wang, Xiaorui Liu, Wenqi Fan, Xiangyu Zhao, Venkataramana Kini, Devendra Yadav, Fei Wang, Zhen Wen, Jiliang Tang, and Hui Liu. 2024. Rethinking Large Language Model Architectures for Sequential Recommendations. arXiv preprint arXiv:2402.09543 (2024). 





[155] Haoyu Wang, Tuo Zhao, and Jing Gao. 2024. BlendFilter: Advancing Retrieval-Augmented Large Language Models via Query Generation Blending and Knowledge Filtering. arXiv preprint arXiv:2402.11129 (2024). 





[156] Liang Wang, Nan Yang, and Furu Wei. 2023. Query2doc: Query Expansion with Large Language Models. In EMNLP. Association for Computational Linguistics, 9414–9423. 





[157] Liang Wang, Nan Yang, and Furu Wei. 2024. Learning to Retrieve In-Context Examples for Large Language Models. In EACL (1). Association for Computational Linguistics, 1752–1767. 





[158] Xintao Wang, Qianwen Yang, Yongting Qiu, Jiaqing Liang, Qianyu He, Zhouhong Gu, Yanghua Xiao, and Wei Wang. 2023. Knowledgpt: Enhancing large language models with retrieval and storage access on knowledge bases. arXiv preprint arXiv:2308.11761 (2023). 





[159] Yile Wang, Peng Li, Maosong Sun, and Yang Liu. 2023. Self-Knowledge Guided Retrieval Augmentation for Large Language Models. In The 2023 Conference on Empirical Methods in Natural Language Processing. 





[160] Zichao Wang, Weili Nie, Zhuoran Qiao, Chaowei Xiao, Richard G. Baraniuk, and Anima Anandkumar. 2023. Retrieval-based Controllable Molecule Generation. In ICLR. OpenReview.net. 





[161] Zifeng Wang, Zichen Wang, Balasubramaniam Srinivasan, Vassilis N Ioannidis, Huzefa Rangwala, and Rishita Anubhai. 2023. BioBridge: Bridging Biomedical Foundation Models via Knowledge Graph. arXiv preprint arXiv:2310.03320 (2023). 





[162] Jason Wei, Xuezhi Wang, Dale Schuurmans, Maarten Bosma, Fei Xia, Ed Chi, Quoc V Le, Denny Zhou, et al. 2022. Chain-of-thought prompting elicits reasoning in large language models. Advances in neural information processing systems 35 (2022), 24824–24837. 





[163] Junda Wu, Cheng-Chun Chang, Tong Yu, Zhankui He, Jianing Wang, Yupeng Hou, and Julian McAuley. 2024. CoRAL: Collaborative Retrieval-Augmented Large Language Models Improve Long-tail Recommendation. arXiv preprint arXiv:2403.06447 (2024). 





[164] Ledell Wu, Fabio Petroni, Martin Josifoski, Sebastian Riedel, and Luke Zettlemoyer. 2020. Scalable Zero-shot Entity Linking with Dense Entity Retrieval. In EMNLP (1). Association for Computational Linguistics, 6397–6407. 





[165] Yuhuai Wu, Markus Norman Rabe, DeLesley Hutchins, and Christian Szegedy. 2022. Memorizing Transformers. In ICLR. OpenReview.net. 





[166] Miao Xiong, Zhiyuan Hu, Xinyang Lu, Yifei Li, Jie Fu, Junxian He, and Bryan Hooi. 2023. Can llms express their uncertainty? an empirical evaluation of confidence elicitation in llms. arXiv preprint arXiv:2306.13063 (2023). 





[167] Benfeng Xu, Chunxu Zhao, Wenbin Jiang, PengFei Zhu, Songtai Dai, Chao Pang, Zhuo Sun, Shuohuan Wang, and Yu Sun. 2023. Retrieval-augmented domain adaptation of language models. In Proceedings of the 8th Workshop on Representation Learning for NLP (RepL4NLP 2023). 54–64. 





[168] Fangyuan Xu, Weijia Shi, and Eunsol Choi. 2023. RECOMP: Improving retrievalaugmented LMs with context compression and selective augmentation. In The Twelfth International Conference on Learning Representations. 





[169] Hu Xu, Bing Liu, Lei Shu, and Philip S. Yu. 2019. BERT Post-Training for Review Reading Comprehension and Aspect-based Sentiment Analysis. In NAACL-HLT (1). Association for Computational Linguistics, 2324–2335. 





[170] Jitao Xu, Josep-Maria Crego, and Jean Senellart. 2020. Boosting neural machine translation with similar translations. In Annual Meeting of the Association for Computational Linguistics. Association for Computational Linguistics, 1570– 1579. 





[171] Jing Xu, Arthur Szlam, and Jason Weston. 2022. Beyond Goldfish Memory: Long-Term Open-Domain Conversation. In ACL (1). Association for Computational Linguistics, 5180–5197. 





[172] Shicheng Xu, Liang Pang, Huawei Shen, Xueqi Cheng, and Tat-seng Chua. 2023. Search-in-the-chain: Towards the accurate, credible and traceable content generation for complex knowledge-intensive tasks. arXiv preprint arXiv:2304.14732 (2023). 





[173] Haoyan Yang, Zhitao Li, Yong Zhang, Jianzong Wang, Ning Cheng, Ming Li, and Jing Xiao. 2023. PRCA: Fitting Black-Box Large Language Models for Retrieval Question Answering via Pluggable Reward-Driven Contextual Adapter. In EMNLP. Association for Computational Linguistics, 5364–5375. 





[174] Ling Yang, Zhilin Huang, Xiangxin Zhou, Minkai Xu, Wentao Zhang, Yu Wang, Xiawu Zheng, Wenming Yang, Ron O Dror, Shenda Hong, et al. 2023. Promptbased 3d molecular diffusion models for structure-based drug design. (2023). 





[175] Shunyu Yao, Jeffrey Zhao, Dian Yu, Nan Du, Izhak Shafran, Karthik R. Narasimhan, and Yuan Cao. 2023. ReAct: Synergizing Reasoning and Acting in Language Models. In ICLR. OpenReview.net. 





[176] Jiacheng Ye, Zhiyong Wu, Jiangtao Feng, Tao Yu, and Lingpeng Kong. 2023. Compositional exemplars for in-context learning. In International Conference on Machine Learning. PMLR, 39818–39833. 





[177] Yunhu Ye, Binyuan Hui, Min Yang, Binhua Li, Fei Huang, and Yongbin Li. 2023. Large Language Models are Versatile Decomposers: Decomposing Evidence and Questions for Table-based Reasoning. In SIGIR. ACM, 174–184. 





[178] Antonio Jimeno Yepes, Yao You, Jan Milczek, Sebastian Laverde, and Leah Li. 2024. Financial Report Chunking for Effective Retrieval Augmented Generation. arXiv preprint arXiv:2402.05131 (2024). 





[179] Dawei Yin, Yuening Hu, Jiliang Tang, Tim Daly, Mianwei Zhou, Hua Ouyang, Jianhui Chen, Changsung Kang, Hongbo Deng, Chikashi Nobata, et al. 2016. Ranking relevance in yahoo search. In Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining. 323–332. 





[180] Dani Yogatama, Cyprien de Masson d’Autume, and Lingpeng Kong. 2021. Adaptive semiparametric language models. Transactions of the Association for Computational Linguistics 9 (2021), 362–373. 





[181] Ori Yoran, Tomer Wolfson, Ori Ram, and Jonathan Berant. 2023. Making Retrieval-Augmented Language Models Robust to Irrelevant Context. In The Twelfth International Conference on Learning Representations. 





[182] Wenhao Yu, Dan Iter, Shuohang Wang, Yichong Xu, Mingxuan Ju, Soumya Sanyal, Chenguang Zhu, Michael Zeng, and Meng Jiang. 2023. Generate rather than Retrieve: Large Language Models are Strong Context Generators. In ICLR. OpenReview.net. 





[183] Wenhao Yu, Zhihan Zhang, Zhenwen Liang, Meng Jiang, and Ashish Sabharwal. 2023. Improving language models via plug-and-play retrieval feedback. arXiv preprint arXiv:2305.14002 (2023). 





[184] Zichun Yu, Chenyan Xiong, Shi Yu, and Zhiyuan Liu. 2023. Augmentation-Adapted Retriever Improves Generalization of Language Models as Generic Plug-In. In Proceedings of the 61st Annual Meeting of the Association for Computational 





Linguistics (Volume 1: Long Papers). 2421–2436. 





[185] Daoguang Zan, Bei Chen, Zeqi Lin, Bei Guan, Yongji Wang, and Jian-Guang Lou. 2022. When Language Model Meets Private Library. In EMNLP (Findings). Association for Computational Linguistics, 277–288. 





[186] Shenglai Zeng, Jiankun Zhang, Pengfei He, Yue Xing, Yiding Liu, Han Xu, Jie Ren, Shuaiqiang Wang, Dawei Yin, Yi Chang, et al. 2024. The Good and The Bad: Exploring Privacy Issues in Retrieval-Augmented Generation (RAG). arXiv preprint arXiv:2402.16893 (2024). 





[187] Boyu Zhang, Hongyang Yang, Tianyu Zhou, Muhammad Ali Babar, and Xiao-Yang Liu. 2023. Enhancing financial sentiment analysis via retrieval augmented large language models. In Proceedings of the Fourth ACM International Conference on AI in Finance. 349–356. 





[188] Houyu Zhang, Zhenghao Liu, Chenyan Xiong, and Zhiyuan Liu. 2020. Grounded Conversation Generation as Guided Traverses in Commonsense Knowledge Graphs. In ACL. Association for Computational Linguistics, 2031–2043. 





[189] Jiahao Zhang, Rui Xue, Wenqi Fan, Xin Xu, Qing Li, Jian Pei, and Xiaorui Liu. 2024. Linear-Time Graph Neural Networks for Scalable Recommendations. arXiv preprint arXiv:2402.13973 (2024). 





[190] Yunxiang Zhang, Muhammad Khalifa, Lajanugen Logeswaran, Moontae Lee, Honglak Lee, and Lu Wang. 2023. Merging generated and retrieved knowledge for open-domain QA. arXiv preprint arXiv:2310.14393 (2023). 





[191] Zhuosheng Zhang, Aston Zhang, Mu Li, and Alex Smola. 2023. Automatic Chain of Thought Prompting in Large Language Models. In ICLR. OpenReview.net. 





[192] Penghao Zhao, Hailin Zhang, Qinhan Yu, Zhengren Wang, Yunteng Geng, Fangcheng Fu, Ling Yang, Wentao Zhang, and Bin Cui. 2024. Retrieval-Augmented Generation for AI-Generated Content: A Survey. arXiv preprint arXiv:2402.19473 (2024). 





[193] Ruochen Zhao, Hailin Chen, Weishi Wang, Fangkai Jiao, Xuan Long Do, Chengwei Qin, Bosheng Ding, Xiaobao Guo, Minzhi Li, Xingxuan Li, et al. 2023. Retrieving multimodal information for augmented generation: A survey. arXiv preprint arXiv:2303.10868 (2023). 





[194] Wayne Xin Zhao, Kun Zhou, Junyi Li, Tianyi Tang, Xiaolei Wang, Yupeng Hou, Yingqian Min, Beichen Zhang, Junjie Zhang, Zican Dong, et al. 2023. A survey of large language models. arXiv preprint arXiv:2303.18223 (2023). 





[195] Zihuai Zhao, Wenqi Fan, Jiatong Li, Yunqing Liu, Xiaowei Mei, Yiqi Wang, Zhen Wen, Fei Wang, Xiangyu Zhao, Jiliang Tang, et al. 2024. Recommender systems in the era of large language models (llms). IEEE Transactions on Knowledge and Data Engineering (2024). 





[196] Zexuan Zhong, Tao Lei, and Danqi Chen. 2022. Training Language Models with Memory Augmentation. In 2022 Conference on Empirical Methods in Natural Language Processing, EMNLP 2022. 





[197] Shuyan Zhou, Uri Alon, Frank F Xu, Zhengbao Jiang, and Graham Neubig. 2022. Docprompting: Generating code by retrieving the docs. In The Eleventh International Conference on Learning Representations. 





[198] Yin Zhu, Zhiling Luo, and Gong Cheng. 2023. Furthest Reasoning with Plan Assessment: Stable Reasoning Path with Retrieval-Augmented Large Language Models. arXiv preprint arXiv:2309.12767 (2023). 





[199] Yinghao Zhu, Changyu Ren, Shiyun Xie, Shukai Liu, Hangyuan Ji, Zixiang Wang, Tao Sun, Long He, Zhoujun Li, Xi Zhu, et al. 2024. REALM: RAG-Driven Enhancement of Multimodal Electronic Health Records Analysis via Large Language Models. arXiv preprint arXiv:2402.07016 (2024). 





[200] Wei Zou, Runpeng Geng, Binghui Wang, and Jinyuan Jia. 2024. PoisonedRAG: Knowledge Poisoning Attacks to Retrieval-Augmented Generation of Large Language Models. arXiv preprint arXiv:2402.07867 (2024). 

', '{"title": "A Survey on RAG Meeting LLMs: Towards Retrieval-Augmented Large Language Models", "sections": [{"level": 1, "title": "ABSTRACT"}, {"level": 1, "title": "KEYWORDS"}, {"level": 1, "title": "1 INTRODUCTION"}, {"level": 1, "title": "2 BACKGROUND", "children": [{"level": 2, "title": "2.1 Large Language Models (LLMs)"}, {"level": 2, "title": "2.2 Prompt Learning"}]}, {"level": 1, "title": "3 RETRIEVAL-AUGMENTED LARGE LANGUAGE MODELS (RA-LLMS)", "children": [{"level": 2, "title": "3.1 Retrieval"}, {"level": 2, "title": "3.2 Generation"}, {"level": 2, "title": "3.3 Retrieval Integration for Generation Augmentation"}, {"level": 2, "title": "3.4 Retrieval Augmentation Necessity and Frequency"}]}, {"level": 1, "title": "4 RA-LLMS TRAINING", "children": [{"level": 2, "title": "4.1 Training-free"}, {"level": 2, "title": "4.2 Independent Training"}, {"level": 2, "title": "4.3 Sequential Training"}, {"level": 2, "title": "4.4 Joint Training"}]}, {"level": 1, "title": "5 APPLICATIONS", "children": [{"level": 2, "title": "5.1 NLP Applications"}, {"level": 2, "title": "5.2 Downstream Tasks"}, {"level": 2, "title": "5.3 Domain-specific Applications"}]}, {"level": 1, "title": "6 FUTURE CHALLENGES AND OPPORTUNITIES"}, {"level": 1, "title": "7 CONCLUSION"}, {"level": 1, "title": "REFERENCES"}]}', '2026-03-15 20:13:32.896576', 'success', NULL);

-- ----------------------------
-- Primary Key structure for table doc_parsed
-- ----------------------------
ALTER TABLE "public"."doc_parsed" ADD CONSTRAINT "doc_parsed_pk" PRIMARY KEY ("id");
