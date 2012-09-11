--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = taf, pg_catalog;

--
-- Name: task_id_seq; Type: SEQUENCE SET; Schema: taf; Owner: -
--

SELECT pg_catalog.setval('task_id_seq', 33, true);


--
-- Name: worker_id_seq; Type: SEQUENCE SET; Schema: taf; Owner: -
--

SELECT pg_catalog.setval('worker_id_seq', 2, true);


--
-- Data for Name: active_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY active_task (task_id, title, slug, work_time, created_at, worker_id, rank, active_since, block_stack) FROM stdin;
28	This is a new task	this-is-a-new-task-57d	0	2012-08-28 16:00:48.18141	2	10	2012-09-10 16:24:14.842249	{"blocks": []}
12	Pour la forme...	7f4-pour-la-forme	0	2012-08-28 16:00:48.18141	2	8	2012-09-10 16:24:14.842249	{"blocks": []}
10	Pour la forme...	e74-pour-la-forme	0	2012-08-28 16:00:48.18141	2	9	2012-09-10 16:24:14.842249	{"blocks": []}
22	Insert en 8	insert-en-8-9ef	0	2012-08-28 16:00:48.18141	2	4	2012-09-10 16:24:14.842249	{"blocks": []}
24	Insert en 8	insert-en-8-aab	0	2012-08-28 16:00:48.18141	2	3	2012-09-10 16:24:14.842249	{"blocks": []}
20	Insert en 6	e25-insert-en-6	0	2012-08-28 16:00:48.18141	2	5	2012-09-10 16:24:14.842249	{"blocks": []}
14	Pour la forme...	e69-pour-la-forme	0	2012-08-28 16:00:48.18141	2	1	2012-09-10 16:24:14.842249	{"blocks": []}
16	Pour la forme...	6f8-pour-la-forme	0	2012-08-28 16:00:48.18141	2	2	2012-09-10 16:24:14.842249	{"blocks": []}
8	Ceci est une tâche	my-own-slug	0	2012-08-28 16:00:48.18141	2	7	2012-09-10 16:24:14.842249	{"blocks": []}
4	Ceci est une tâche	222-ceci-est-une-tache	0	2012-08-28 16:00:48.18141	2	6	2012-09-10 16:24:14.842249	{"blocks": []}
32	test with worker	test-with-worker-70c	0	2012-08-29 16:18:20.26533	1	11	2012-09-10 16:24:14.842249	{"blocks": []}
23	Insert en 8	insert-en-8-801	0	2012-08-28 16:00:48.18141	1	6	2012-09-10 16:24:14.842249	{"blocks": []}
11	Complètement autre chose	b33-completement-autre-chose	0	2012-08-28 16:00:48.18141	1	9	2012-09-10 16:24:14.842249	{"blocks": []}
15	Complètement autre chose	bf2-completement-autre-chose	0	2012-08-28 16:00:48.18141	1	8	2012-09-10 16:24:14.842249	{"blocks": []}
33	test with worker	test-with-worker-e31	0	2012-08-29 16:21:58.74556	1	5	2012-09-10 16:24:14.842249	{"blocks": []}
21	Insert en 7	617-insert-en-7	0	2012-08-28 16:00:48.18141	1	4	2012-09-10 16:24:14.842249	{"blocks": []}
17	plop plop et replop	5c5-plop-plop-et-replop	0	2012-08-28 16:00:48.18141	1	2	2012-09-10 16:24:14.842249	{"blocks": []}
13	Complètement autre chose	777-completement-autre-chose	0	2012-08-28 16:00:48.18141	1	3	2012-09-10 16:24:14.842249	{"blocks": []}
5	Ceci est une autre tâche	75d-ceci-est-une-autre-tache	259	2012-08-28 16:00:48.18141	1	1	2012-09-10 16:24:14.842249	{"blocks": []}
7	Ceci est une tâche	b60-ceci-est-une-tache	0	2012-08-28 16:00:48.18141	1	7	2012-09-10 16:24:14.842249	{"blocks": []}
9	Complètement autre chose	e74-completement-autre-chose	0	2012-08-28 16:00:48.18141	1	10	2012-09-10 16:24:14.842249	{"blocks": []}
\.


--
-- Data for Name: finished_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY finished_task (task_id, title, slug, work_time, created_at, worker_id, changed_since, block_stack) FROM stdin;
\.


--
-- Data for Name: suspended_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY suspended_task (task_id, title, slug, work_time, created_at, worker_id, changed_since, block_stack) FROM stdin;
\.


--
-- Data for Name: worker; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY worker (worker_id, email, first_name, last_name, session_token, session_start) FROM stdin;
2	gregoire.hubert@knplabs.com	greg (knp)	hubert	\N	\N
1	hubert.greg@gmail.com	grégoire	hubert	64a4e8faed1a1aa0bf8bf0fc84938d25	2012-08-30 09:17:33.758522
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY task (task_id, title, slug, work_time, created_at, worker_id, block_stack) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

