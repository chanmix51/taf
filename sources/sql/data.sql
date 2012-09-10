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
-- Name: active_task_id_seq; Type: SEQUENCE SET; Schema: taf; Owner: -
--

SELECT pg_catalog.setval('active_task_id_seq', 33, true);


--
-- Name: worker_id_seq; Type: SEQUENCE SET; Schema: taf; Owner: -
--

SELECT pg_catalog.setval('worker_id_seq', 2, true);


--
-- Data for Name: worker; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY worker (worker_id, email, first_name, last_name, session_token, session_start) FROM stdin;
2	gregoire.hubert@knplabs.com	greg (knp)	hubert	\N	\N
1	hubert.greg@gmail.com	grégoire	hubert	64a4e8faed1a1aa0bf8bf0fc84938d25	2012-08-30 09:17:33.758522
\.


--
-- Data for Name: active_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY active_task (id, rank, title, slug, work_time, block_stack, created_at, worker_id) FROM stdin;
28	10	This is a new task	this-is-a-new-task-57d	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
12	8	Pour la forme...	7f4-pour-la-forme	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
10	9	Pour la forme...	e74-pour-la-forme	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
22	4	Insert en 8	insert-en-8-9ef	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
24	3	Insert en 8	insert-en-8-aab	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
20	5	Insert en 6	e25-insert-en-6	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
14	1	Pour la forme...	e69-pour-la-forme	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
16	2	Pour la forme...	6f8-pour-la-forme	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
8	7	Ceci est une tâche	my-own-slug	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
4	6	Ceci est une tâche	222-ceci-est-une-tache	0	{"blocks": []}	2012-08-28 16:00:48.18141	2
32	11	test with worker	test-with-worker-70c	0	{"blocks": []}	2012-08-29 16:18:20.26533	1
23	6	Insert en 8	insert-en-8-801	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
11	9	Complètement autre chose	b33-completement-autre-chose	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
15	8	Complètement autre chose	bf2-completement-autre-chose	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
33	5	test with worker	test-with-worker-e31	0	{"blocks": []}	2012-08-29 16:21:58.74556	1
21	4	Insert en 7	617-insert-en-7	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
17	2	plop plop et replop	5c5-plop-plop-et-replop	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
13	3	Complètement autre chose	777-completement-autre-chose	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
5	1	Ceci est une autre tâche	75d-ceci-est-une-autre-tache	259	{"blocks": []}	2012-08-28 16:00:48.18141	1
7	7	Ceci est une tâche	b60-ceci-est-une-tache	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
9	10	Complètement autre chose	e74-completement-autre-chose	0	{"blocks": []}	2012-08-28 16:00:48.18141	1
\.


--
-- Data for Name: finished_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY finished_task (id, title, slug, work_time, created_at, block_stack, changed_at, worker_id) FROM stdin;
\.


--
-- Data for Name: suspended_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY suspended_task (id, title, slug, work_time, created_at, block_stack, changed_at, worker_id) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

