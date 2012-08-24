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

SELECT pg_catalog.setval('active_task_id_seq', 17, true);


--
-- Data for Name: active_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY active_task (id, rank, title, slug, work_time) FROM stdin;
8	12	Ceci est une tâche	my-own-slug	0
11	11	Complètement autre chose	b33-completement-autre-chose	0
15	9	Complètement autre chose	bf2-completement-autre-chose	0
4	10	Ceci est une tâche	222-ceci-est-une-tache	0
9	7	Complètement autre chose	e74-completement-autre-chose	0
7	8	Ceci est une tâche	b60-ceci-est-une-tache	0
10	13	Pour la forme...	e74-pour-la-forme	0
17	3	plop plop et replop	5c5-plop-plop-et-replop	0
12	6	Pour la forme...	7f4-pour-la-forme	0
16	5	Pour la forme...	6f8-pour-la-forme	0
13	4	Complètement autre chose	777-completement-autre-chose	0
14	1	Pour la forme...	e69-pour-la-forme	0
5	2	Ceci est une autre tâche	75d-ceci-est-une-autre-tache	0
\.


--
-- Data for Name: finished_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY finished_task (id, title, slug, work_time, created_at) FROM stdin;
\.


--
-- Data for Name: suspended_task; Type: TABLE DATA; Schema: taf; Owner: -
--

COPY suspended_task (id, title, slug, work_time, created_at) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

