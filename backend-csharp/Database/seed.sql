--
-- PostgreSQL database dump
--

\restrict TtP54XFboXVbU2lOEyl4p3wREF5Qt0HF00Hjm5eN0pQGt0F5Y8dsMTRm29a9Tpi

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: achievements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.achievements (id, key, name_en, name_fr, description_en, description_fr, icon, category, condition_type, condition_value, xp_reward, created_at) FROM stdin;
2ae066fc-345f-41cd-bbb9-5f2efe33b606	accuracy_80	Sharp Mind	Esprit Vif	80% accuracy (10+ questions)	80% de précision (10+ questions)	🎯	accuracy	accuracy_percent	80	200	2026-04-26 17:45:40.220824+00
a9ce56b9-0f7c-4f41-8622-3dc0389b0324	accuracy_95	Perfectionist	Perfectionniste	95% accuracy (10+ questions)	95% de précision (10+ questions)	💎	accuracy	accuracy_percent	95	500	2026-04-26 17:45:40.220824+00
b0806707-3ba3-4124-9f38-589ab7b1c3db	pvp_first_win	First Victory	Première Victoire	Win your first PvP match	Gagnez votre premier match PvP	⚔️ 	pvp	pvp_wins	1	200	2026-04-26 17:45:40.220824+00
009e3885-24b1-4a6d-b6fe-f480e82e0bce	pvp_10_wins	Arena Fighter	Combattant d'Arène	Win 10 PvP matches	Gagnez 10 matchs PvP	🏆	pvp	pvp_wins	10	500	2026-04-26 17:45:40.220824+00
d552b66a-8928-4c6c-9439-e55b6e67f4cc	pvp_50_wins	Arena Champion	Champion d'Arène	Win 50 PvP matches	Gagnez 50 matchs PvP	🥇	pvp	pvp_wins	50	1500	2026-04-26 17:45:40.220824+00
66867d53-8ec5-4f86-903d-fe3f2825dccb	pvp_3_wins	First Blood	Premier Sang	Win 3 PvP matches	Gagnez 3 matchs PvP	🗡️ 	pvp	pvp_wins	3	100	2026-04-27 07:21:52.878451+00
f65d65c9-2ee6-4a7c-9f1f-cf6a7c5881d3	pvp_5_wins	Fighter	Combattant	Win 5 PvP matches	Gagnez 5 matchs PvP	⚔️ 	pvp	pvp_wins	5	150	2026-04-27 07:21:52.878451+00
55c3613e-6acc-4802-859e-d081a62a0115	pvp_25_wins	Warrior	Guerrier	Win 25 PvP matches	Gagnez 25 matchs PvP	🔱	pvp	pvp_wins	25	750	2026-04-27 07:21:52.878451+00
bf848af9-4ae8-4d6a-8822-e84e7c9df22d	pvp_100_wins	Arena Master	Maître de l'Arène	Win 100 PvP matches	Gagnez 100 matchs PvP	👑	pvp	pvp_wins	100	3000	2026-04-27 07:21:52.878451+00
d79eef3b-f0e5-45e5-986b-05f2b75389fe	pvp_200_wins	Gladiator	Gladiateur	Win 200 PvP matches	Gagnez 200 matchs PvP	⚜️ 	pvp	pvp_wins	200	5000	2026-04-27 07:21:52.878451+00
89455129-e520-457d-8558-ed3d441927dd	accuracy_70	Good Aim	Bonne Visée	70% accuracy (10+ questions)	70% de précision (10+ questions)	🎯	accuracy	accuracy_percent	70	100	2026-04-27 07:21:52.878451+00
50c77f04-e40c-4f2d-8bfb-56fa4f80c4c4	accuracy_90	Sharpshooter	Tireur d'Élite	90% accuracy (10+ questions)	90% de précision (10+ questions)	🏹	accuracy	accuracy_percent	90	350	2026-04-27 07:21:52.878451+00
2b352372-ec54-4612-93cd-59349bc9c256	theme_explorer_1	Curious Mind	Esprit Curieux	Explore your first theme	Explore ton premier thème	auto_stories	theme_master	themes_explored	1	25	2026-04-27 07:44:32.627116+00
cf01d5d9-585f-4ce6-9b49-77e26200e9c8	theme_explorer_3	Theme Sampler	Explorateur	Explore 3 different themes	Explore 3 thèmes différents	auto_stories	theme_master	themes_explored	3	75	2026-04-27 07:44:32.627116+00
eba4f608-9025-4044-94ef-6816c11194fd	theme_explorer_5	Knowledge Seeker	Chercheur de Savoir	Explore 5 different themes	Explore 5 thèmes différents	auto_stories	theme_master	themes_explored	5	150	2026-04-27 07:44:32.627116+00
de6163b4-5546-4989-ae5a-16ab1f3b1ce2	theme_explorer_10	Polymath	Polymathe	Explore 10 different themes	Explore 10 thèmes différents	auto_stories	theme_master	themes_explored	10	300	2026-04-27 07:44:32.627116+00
46119186-22b4-4d20-ae37-c57d8d4b2d75	theme_explorer_15	Renaissance Mind	Esprit Renaissance	Explore 15 different themes	Explore 15 thèmes différents	auto_stories	theme_master	themes_explored	15	500	2026-04-27 07:44:32.627116+00
e332c1e2-72a7-4634-b892-f100d09095ec	theme_explorer_25	Encyclopedist	Encyclopédiste	Explore 25 different themes	Explore 25 thèmes différents	auto_stories	theme_master	themes_explored	25	1000	2026-04-27 07:44:32.627116+00
a7ad6bf7-593e-4000-a350-8d42770f3bb6	social_1	Noticed	Remarqué	Get your first follower	Obtiens ton premier abonné	people	social	followers_count	1	25	2026-04-27 07:44:32.627116+00
32f8966a-033c-4dff-aaaf-4cdcb5d28a93	social_5	Rising Star	Étoile Montante	Reach 5 followers	Atteins 5 abonnés	people	social	followers_count	5	75	2026-04-27 07:44:32.627116+00
28eccc70-da55-4baf-abdf-2c4afe2b842d	social_10	Influencer	Influenceur	Reach 10 followers	Atteins 10 abonnés	people	social	followers_count	10	150	2026-04-27 07:44:32.627116+00
69273a4d-34f1-4374-86d6-95b194fc098b	social_25	Popular	Populaire	Reach 25 followers	Atteins 25 abonnés	people	social	followers_count	25	300	2026-04-27 07:44:32.627116+00
aa506777-1e20-410b-9a03-27f89631bff1	social_50	Celebrity	Célébrité	Reach 50 followers	Atteins 50 abonnés	people	social	followers_count	50	600	2026-04-27 07:44:32.627116+00
9c922854-82d2-42f6-a311-f8b37d8633f7	social_100	Brain Legend	Légende du Brain	Reach 100 followers	Atteins 100 abonnés	people	social	followers_count	100	1500	2026-04-27 07:44:32.627116+00
904ea831-413e-4e9b-b2e8-42e7876f6c98	daily_3	Habit Forming	Prise d'Habitude	Complete the daily quiz 3 days in a row	Complète le quiz du jour 3 jours de\r\n  suite	today	daily_streak	daily_streak	3	50	2026-04-27 08:59:18.826743+00
a51c1428-b8cf-487b-a9ba-dacbf3487afd	daily_7	Week Warrior	Guerrier de la Semaine	Complete the daily quiz 7 days in a row	Complète le quiz du jour 7 jours de\r\n  suite	today	daily_streak	daily_streak	7	100	2026-04-27 08:59:18.826743+00
d91bc8c2-9f4c-4936-a31f-460cee09b0ff	daily_14	Fortnight Focus	Deux Semaines	Complete the daily quiz 14 days in a row	Complète le quiz du jour 14 jours de\r\n  suite	today	daily_streak	daily_streak	14	200	2026-04-27 08:59:18.826743+00
a9522c69-fc22-4376-ab8a-1e63e72b11e6	quiz_10	Getting Started	Bon Début	Answer 100 questions	Répondez à 100 questions	📚	quiz	total_questions	100	100	2026-04-26 17:45:40.220824+00
20a9146c-1296-42db-b7af-3014bdc48041	streak_3	On Fire	En Feu	3-day streak	3 jours de suite	🔥	streak	current_streak	3	150	2026-04-26 17:45:40.220824+00
8d8bf8af-0e71-4d30-9ac4-3cbfcd649fa6	streak_7	Week Warrior	Guerrier Hebdo	7-day streak	7 jours de suite	⚡	streak	current_streak	7	300	2026-04-26 17:45:40.220824+00
2828dd13-ea36-45b5-9397-61e93803ae58	streak_30	Monthly Master	Maître du Mois	30-day streak	30 jours de suite	👑	streak	current_streak	30	1000	2026-04-26 17:45:40.220824+00
182056cb-bd1e-48ae-a100-58cb22ffbe8f	streak_100	Unstoppable	Inarrêtable	100-day streak	100 jours de suite	🌟	streak	current_streak	100	3000	2026-04-26 17:45:40.220824+00
b12f0c57-5ba6-4c05-9dd3-6c6c3b10ab51	streak_14	Two Weeks	Deux Semaines	14-day streak	14 jours de suite	📅	streak	current_streak	14	500	2026-04-27 07:21:52.878451+00
c0a1b3ca-d0c5-45c9-afe5-0471bc722dfc	streak_50	Relentless	Implacable	50-day streak	50 jours de suite	💪	streak	current_streak	50	1500	2026-04-27 07:21:52.878451+00
185ad9ce-9698-4ca2-a914-be0fceb8b2dd	streak_200	Invincible	Invincible	200-day streak	200 jours de suite	🦾	streak	current_streak	200	5000	2026-04-27 07:21:52.878451+00
fab444c1-ad5d-4a32-a908-f2cd58defe2c	streak_365	Annual Champion	Champion Annuel	365-day streak	365 jours de suite	🎖️ 	streak	current_streak	365	10000	2026-04-27 07:21:52.878451+00
176a1027-95a1-4fad-ac1b-f33d2c146ab8	daily_30	Monthly Master	Maître du Mois	Complete the daily quiz 30 days in a row	Complète le quiz du jour 30 jours de\r\n  suite	today	daily_streak	daily_streak	30	400	2026-04-27 08:59:18.826743+00
4441b9cb-3ddc-4562-8ff9-9212dcfb300c	daily_60	Unstoppable	Inarrêtable	Complete the daily quiz 60 days in a row	Complète le quiz du jour 60 jours de\r\n  suite	today	daily_streak	daily_streak	60	750	2026-04-27 08:59:18.826743+00
1f155141-37c7-4c19-beab-df06b0bc696e	daily_100	Daily Legend	Légende Quotidienne	Complete the daily quiz 100 days in a row	Complète le quiz du jour 100 jours de\r\n  suite	today	daily_streak	daily_streak	100	1500	2026-04-27 08:59:18.826743+00
c5532f64-45ec-4100-9080-d36ebe049cb5	first_question	First Step	Premier Pas	Answer your first 10 questions	Répondez à vos 10 premières questions	🎯	quiz	total_questions	10	50	2026-04-26 17:45:40.220824+00
26a84791-30e9-412f-8490-0132fd4f7df9	quiz_25	Warm Up	Échauffement	Answer 250 questions	Répondez à 250 questions	🎮	quiz	total_questions	250	75	2026-04-27 07:21:52.878451+00
602f6c77-b5cd-4387-a172-363c61e73b23	quiz_50	Half Century	Demi-Centurion	Answer 500 questions	Répondez à 500 questions	🏅	quiz	total_questions	500	150	2026-04-27 07:21:52.878451+00
8c8508b0-0b30-4245-81cd-e79ead6579bb	quiz_100	Century	Centurion	Answer 1000 questions	Répondez à 1000 questions	💯	quiz	total_questions	1000	500	2026-04-26 17:45:40.220824+00
3a8b0966-5076-44c8-b787-52ea5ebf962c	quiz_200	Veteran	Vétéran	Answer 2000 questions	Répondez à 2000 questions	⭐	quiz	total_questions	2000	300	2026-04-27 07:21:52.878451+00
482b7e8b-ef1b-4cd7-8769-356a35bda194	quiz_500	Scholar	Érudit	Answer 5000 questions	Répondez à 5000 questions	🎓	quiz	total_questions	5000	1000	2026-04-26 17:45:40.220824+00
82d32049-95d5-49bf-8ccf-ef89d53795c2	quiz_1000	Brain Master	Maître Cerveau	Answer 10000 questions	Répondez à 10000 questions	🧠	quiz	total_questions	10000	2000	2026-04-26 17:45:40.220824+00
5ab14dd5-da57-4b31-abcb-ae7f492a3ce4	quiz_2000	Expert	Expert	Answer 20000 questions	Répondez à 20000 questions	🔬	quiz	total_questions	20000	3000	2026-04-27 07:21:52.878451+00
af715a30-d418-4ef5-831b-d6d8da4f41cf	quiz_5000	Omniscient	Omniscient	Answer 50000 questions	Répondez à 50000 questions	🌠	quiz	total_questions	50000	5000	2026-04-27 07:21:52.878451+00
\.


--
-- Data for Name: themes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.themes (id, icon, color, created_at) FROM stdin;
b65934a1-6bd3-4ff1-b1e1-4516455c3c11	🦁	#10B981	2026-01-21 13:27:09.346329+00
59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	📜	#EF4444	2026-01-21 13:27:09.346329+00
eb50291e-5d1d-4b20-875e-0fdfa59f9118	🌍	#3B82F6	2026-01-21 13:27:09.346329+00
67f21e5a-a5ad-4557-9bdb-1321e5278ee0	🎬	#E91E63	2026-01-26 15:17:18.600968+00
3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	🎵	#9C27B0	2026-01-26 15:17:18.600968+00
31db30c5-7871-4498-94eb-a8314aa81982	💻	#2196F3	2026-01-26 15:17:18.600968+00
3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	⚽	#4CAF50	2026-01-26 15:17:18.600968+00
38648836-0348-4a8d-9ba5-ef48bc151e1f	🎨	#FF9800	2026-01-26 15:17:18.600968+00
643ddd77-130c-41ff-8a7c-63e9c872c61d	🚀	#3F51B5	2026-01-26 15:17:18.600968+00
0055a076-82f5-4272-8502-053bd8976caa	🔬	#00BCD4	2026-01-26 15:17:18.600968+00
137a24ef-330a-423b-bdd2-bffcb132fefb	🎮	#F44336	2026-01-26 15:17:18.600968+00
\.


--
-- Data for Name: question_concepts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_concepts (id, concept, theme_id, created_at, concept_en, concept_fr) FROM stdin;
1ee0499f-1251-4bc4-bb5c-f6db4f0cad5c	Minecraft	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-21 02:01:20.580486+00	Minecraft	Minecraft
f6d49064-f7c8-4602-aaaf-53c6c23ac8dc	Soccer	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-23 02:01:48.993824+00	Soccer	Football
5f642187-e074-4507-ba62-cba9e15e7d78	Astronauts and Space Missions	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-25 02:01:34.687176+00	Astronauts and Space Missions	Astronautes et Missions Spatiales
b5494f27-0341-4f58-b67f-13597b48b29c	Pop Music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-27 02:01:11.857305+00	Pop Music	Musique Pop
fddadd88-1ca6-4b6d-9d65-23a706b6df68	Musical Instruments	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-03-01 02:01:25.072035+00	Musical Instruments	Instruments de musique
97d34fd1-a61c-42c7-b0dd-61e4fdf29f59	The Renaissance	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-03-03 02:01:22.346431+00	The Renaissance	La Renaissance
07baa376-daca-4f2a-9c79-9214d3dbbbf6	Animal Habitats and Ecosystems	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-03-05 02:01:26.026461+00	Animal Habitats and Ecosystems	Habitats et écosystèmes animaux
af821a66-a6ce-4f15-bdaa-b29f73f759b6	Meteorites and Asteroids	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-03-07 02:01:25.696214+00	Meteorites and Asteroids	Météorites et Astéroïdes
3533d046-5ebd-450f-9a91-901f8b69fc6b	The Periodic Table	0055a076-82f5-4272-8502-053bd8976caa	2026-03-09 02:01:07.562862+00	The Periodic Table	Le Tableau Périodique
4257ce16-28b8-48b7-9111-8a96491a3af6	Grand Theft Auto	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-03-11 02:01:16.418832+00	Grand Theft Auto	Grand Theft Auto
5b4dfff3-f538-461f-8073-d1d19f9eacfd	Swimming	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-03-13 14:53:59.050557+00	Swimming	Natation
b45a0e38-6d84-44d8-84cd-ad7a632b4523	Famous Movie Actors and Actresses	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-03-15 03:01:21.227329+00	Famous Movie Actors and Actresses	Acteurs et Actrices de Cinéma Célèbres
e9f1f5f3-ab59-4bea-bbe0-b09e78b9e07d	Climate Zones and Weather Patterns	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-03-17 08:07:05.227736+00	Climate Zones and Weather Patterns	Zones climatiques et régimes météorologiques
ffd8ea2f-ea1b-4082-a308-357aecf8d464	Music Theory	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-03-19 03:01:14.959247+00	Music Theory	Théorie musicale
2b96d68d-e64d-4122-ba87-e1b3ee428432	Gravity	0055a076-82f5-4272-8502-053bd8976caa	2026-03-21 03:01:16.70174+00	Gravity	Gravité
6810eb16-31c5-4dbc-8b04-a43612366084	Pokémon	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-03-23 03:01:15.520733+00	Pokémon	Pokémon
87ebdb8b-b494-4cb6-a206-3cc89a95acda	Photography	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-03-23 11:01:17.588443+00	Photography	La photographie
d9f32e16-3271-4b35-88b4-ac4430430e48	The Moon	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-03-23 11:31:59.134446+00	The Moon	La Lune
20ef2131-30ea-4520-b403-e05e05a63692	The Cold War	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-03-23 13:07:22.46815+00	The Cold War	La Guerre froide
b2ffab6a-9dee-4d4a-98d6-bfca652e9678	Golf	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-03-24 03:01:12.960877+00	Golf	Golf
9eff870a-d167-4eb1-a7b4-c7437e1797c0	Electricity and Magnetism	0055a076-82f5-4272-8502-053bd8976caa	2026-03-26 03:01:09.801103+00	Electricity and Magnetism	Électricité et Magnétisme
76b7f8ca-76c2-4152-80f0-820b777dccd3	Digital Photography	31db30c5-7871-4498-94eb-a8314aa81982	2026-03-28 03:01:32.71945+00	Digital Photography	Photographie numérique
56e750cf-9556-42a6-a59f-44ce62f34696	Weather and Climate	0055a076-82f5-4272-8502-053bd8976caa	2026-03-30 03:01:22.89784+00	Weather and Climate	Météorologie et Climat
3b51ffeb-55e6-4baa-b4d9-97eaf13839a4	Space Exploration	31db30c5-7871-4498-94eb-a8314aa81982	2026-04-01 03:01:18.696352+00	Space Exploration	Exploration spatiale
4debbf31-6aba-494e-86e7-c42d8de75ccc	Photosynthesis	0055a076-82f5-4272-8502-053bd8976caa	2026-04-03 03:01:16.309423+00	Photosynthesis	Photosynthèse
ff7659c3-24aa-459c-b9be-2f406fa3e51c	Movie Soundtracks and Film Music	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-04-05 03:01:35.262791+00	Movie Soundtracks and Film Music	Bandes sonores et musique de films
94c53f17-d932-4bc2-85ff-3459f1762e43	Music Videos	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-04-07 03:01:42.031711+00	Music Videos	Clips musicaux
4c0a6ae3-9d21-4bb0-a233-68c26299b4ea	The Viking Age	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-04-08 03:01:24.652401+00	The Viking Age	L'Âge des Vikings
4e9594d4-5194-4599-83f0-d00509f567fa	Islands and Archipelagos	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-04-09 03:01:20.195493+00	Islands and Archipelagos	Îles et Archipels
48cfe69d-0258-40f5-84e0-6073fe2eac4c	Animal Reproduction and Life Cycles	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-04-10 03:01:13.423734+00	Animal Reproduction and Life Cycles	Reproduction animale et cycles de vie
386a7723-675d-48f5-8ef6-5113bd3e8593	Space-Time and the Universe	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-04-11 03:01:15.308431+00	Space-Time and the Universe	Espace-Temps et l'Univers
d89c6659-fcb1-4953-8456-207d71481f60	Sound and Acoustics	0055a076-82f5-4272-8502-053bd8976caa	2026-04-12 03:01:08.868643+00	Sound and Acoustics	Son et Acoustique
845229e2-df88-4d78-b858-f24f861e6921	Track and Field	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-04-13 03:01:12.316846+00	Track and Field	Athlétisme
12b1c3fa-caad-4eb6-8023-b28ac89082cf	Movie Quotes and Memorable Lines	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-04-14 03:01:25.334815+00	Movie Quotes and Memorable Lines	Répliques de Films et Phrases Mémorables
9d07c69a-0140-46c4-97a2-840b5b6d59a7	3D Printing	31db30c5-7871-4498-94eb-a8314aa81982	2026-04-15 03:01:16.94074+00	3D Printing	Impression 3D
c2235807-8dbe-44c1-a040-1701876b7809	Ballet	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-04-16 03:01:19.437242+00	Ballet	Ballet
86955de6-bc72-47e8-9608-645b4fe8fdf2	Arcade Games	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-04-17 03:01:16.452011+00	Arcade Games	Jeux d'Arcade
860fa1de-3104-4670-a438-47460d5505e2	Music Genres and Styles	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-04-18 03:01:12.766819+00	Music Genres and Styles	Genres et styles musicaux
7f35b450-6384-4f9c-8db3-02c905c794e4	The Ottoman Empire	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-04-19 03:01:10.289042+00	The Ottoman Empire	L'Empire ottoman
bcde3159-c437-48c9-8ab2-d8601b7bc17d	World Cities and Urban Geography	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-04-20 03:01:13.16744+00	World Cities and Urban Geography	Villes du monde et géographie urbaine
f8c4444a-82bd-424f-8b33-1ee785d95f4b	Xbox	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-04-29 03:01:08.741202+00	Xbox	Xbox
00f0775a-cffc-4661-8688-3936eb8b929e	The American Civil War	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-02-15 02:01:18.040226+00	The American Civil War	La Guerre de Sécession
0b6792d5-f362-4b3e-9409-1871944e0e95	Video Games	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-11 02:01:18.607626+00	Video Games	Les Jeux Vidéo
10d8fbf5-eb71-4848-8c73-7fd015b9a12c	The Legend of Zelda: Ocarina of Time	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-02 18:45:07.641092+00	The Legend of Zelda: Ocarina of Time	The Legend of Zelda : Ocarina of Time
15db4390-445f-4457-a373-9293f60d255c	Basketball	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-06 14:31:22.735162+00	Basketball	Basketball
1bd4b010-ff94-4336-b639-793a206441c6	Internet	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-06 14:40:52.136759+00	Internet	Internet
1e4219fd-f1f0-46e0-8f38-abc2f4f9d9a7	Artificial intelligence	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-06 11:48:40.245665+00	Artificial Intelligence	L'Intelligence Artificielle
1ea82a38-c0f8-4242-885a-2f62fb2ee8d7	Smartphones	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-06 14:51:39.553855+00	Smartphones	Les Smartphones
1fda5016-51c9-4bf8-88b0-860f5e70925c	Disney films	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-02-06 11:33:17.020738+00	Disney Films	Les Films Disney
2184d72e-d71e-4ce1-9f04-a09f1dbe2401	Mobile games	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-06 12:51:03.550953+00	Mobile Games	Les Jeux Mobiles
28cde8f3-5ca0-46eb-8034-9415720c274f	The Solar System	0055a076-82f5-4272-8502-053bd8976caa	2026-02-09 02:01:12.409649+00	The Solar System	Le Système Solaire
2ad41a3c-78b7-44ab-b34e-bae4b7748f06	The human body	0055a076-82f5-4272-8502-053bd8976caa	2026-02-06 13:05:01.237786+00	The Human Body	Le Corps Humain
37672373-8ac3-45f5-bcf9-b6acef3b5d60	PlayStation	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-06 12:58:51.913968+00	PlayStation	PlayStation
38409d5a-f6ef-42bc-8ece-1bbdc296b2e7	Stars and Constellations	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-08 02:01:16.178699+00	Stars and Constellations	Les Étoiles et les Constellations
386338c0-7b52-4f52-8226-fa0bd70a0a97	Pets	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-02-06 13:23:01.268404+00	Pets	Les Animaux de Compagnie
3f4c8057-05b1-40ae-98b1-7afeda62e571	The Aurora Borealis (Northern Lights)	0055a076-82f5-4272-8502-053bd8976caa	2026-02-02 18:37:15.965178+00	The Aurora Borealis (Northern Lights)	Les Aurores Boréales
409d0b94-a85a-47e6-ac98-9e0593e9e25b	Animal Migration	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-02-06 09:35:49.578219+00	Animal Migration	La Migration Animale
42d33ef5-4a05-4603-9aae-f1677b7a37cd	Evolution and Natural Selection	0055a076-82f5-4272-8502-053bd8976caa	2026-02-20 02:01:31.62342+00	Evolution and Natural Selection	Évolution et Sélection Naturelle
433b7cf3-fb05-40ed-a52a-a9987b3ca684	The Beatles	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-04 08:42:43.590656+00	The Beatles	Les Beatles
44a3f070-5bbd-4a02-b3b8-0917a4da326e	Nintendo	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-06 12:29:56.519369+00	Nintendo	Nintendo
9205ba15-7e5b-4065-9249-c7c4c0c96e60	Jazz Music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-14 02:01:17.847484+00	Jazz Music	Le Jazz
45a1d518-a419-400b-9068-70924e98eb24	The capitals of Asia and Africa	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-02-06 15:16:58.702014+00	The Capitals of Asia and Africa	Les Capitales d'Asie et d'Afrique
562889fa-d83f-4b7e-9e63-5415b19e88f8	Academy Awards	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-02-04 09:07:58.427866+00	Academy Awards (Oscars)	Les Oscars
5724c718-077f-4574-8079-d49230a5348b	World Oceans and Seas	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-02-19 02:01:15.833667+00	World Oceans and Seas	Les Océans et Mers du Monde
590db296-125e-40da-8ccb-cb18cad2f40e	Pablo Picasso	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-02-13 02:01:16.358926+00	Pablo Picasso	Pablo Picasso
60de70ad-4ffa-49d4-b321-27e534ae66c0	The capitals of Europe	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-02-06 11:20:20.651776+00	The Capitals of Europe	Les Capitales d'Europe
6bfc1cbb-c3b1-4613-aa48-08c9a33be8e3	Film Directors	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-02-17 02:01:18.501494+00	Film Directors	Les Réalisateurs de Cinéma
6d77d367-943d-485b-a0c8-c8b01d941e98	Classical Music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-07 02:01:15.809942+00	Classical Music	La Musique Classique
70ecb7a2-8a60-4aa2-8c6f-f2462112009d	The Second World War	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-02-06 11:05:15.636455+00	The Second World War	La Seconde Guerre Mondiale
7ce96176-42ca-4193-8dce-bd116b58f0da	Horror films	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-02-06 13:58:37.339311+00	Horror Films	Les Films d'Horreur
81e42f5e-a6a4-4875-826b-03e3199e57c8	Modern art	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-02-07 10:52:00.571635+00	Modern Art	L'Art Moderne
8f4ffa46-f575-4f24-aba0-f7b4391bfa28	European countries	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-02-07 11:08:10.618493+00	European Countries	Les Pays Européens
9d1d9225-b463-47da-b352-0c621de25b7f	Rock music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-06 11:40:37.45593+00	Rock Music	La Musique Rock
9e0d01d2-20ea-4f22-843f-0e1fa2f01913	Marine life	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-02-06 13:31:00.426998+00	Marine Life	La Vie Marine
9e2429fc-aa0c-4854-8d56-3b123c886314	Natural disasters	0055a076-82f5-4272-8502-053bd8976caa	2026-02-06 13:13:18.883605+00	Natural Disasters	Les Catastrophes Naturelles
a1ed07e1-b7de-496c-8765-cedd5bea4683	The Football World Cup tournaments	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-06 12:05:01.411788+00	The Football World Cup	La Coupe du Monde de Football
a449fb9a-b7d2-488e-8f50-29d6b57b0b8f	Black Holes	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-04 08:53:11.797312+00	Black Holes	Les Trous Noirs
a8598369-3c0b-49d9-83b5-198be29b3f99	Baseball	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-12 02:01:14.422239+00	Baseball	Baseball
a88f7dce-4e55-4423-b5e4-220e794d63dc	Marvel films	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-02-06 14:09:53.845454+00	Marvel Films	Les Films Marvel
ab59fcf2-a25d-4360-9442-6916672c40ec	Animal Communication	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-02-18 02:01:30.059467+00	Animal Communication	La Communication Animale
acddfbf6-ae05-4145-b5ee-cc0382c54197	Ancient Egypt	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-02-06 13:47:32.390641+00	Ancient Egypt	L'Égypte Antique
aff0cfa2-3b76-4c15-b2e2-3fbf39233193	Dogs	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-02-06 10:47:49.451588+00	Dogs	Les Chiens
b09af825-f3f9-4311-991a-01bed17616bc	Tennis	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-06 14:19:40.905889+00	Tennis	Tennis
bc5cac49-6ecb-4e64-a1bb-b33c1cda9871	The solar system	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-06 12:36:32.82027+00	The Solar System	Le Système Solaire
c31302e2-cae5-4778-9b32-666f2b739815	The Renaissance	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-02-06 12:13:36.604271+00	The Renaissance	La Renaissance
c4d31c5f-083b-4c4b-b00d-87d172826c62	Mountain Ranges	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-02-04 09:24:27.020805+00	Mountain Ranges	Les Chaînes de Montagnes
c9882f28-25af-4a97-84a0-8c40d2047f38	Gravity	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-06 12:43:34.189264+00	Gravity	La Gravité
cb9ca20a-4149-4bd3-a257-9e61cf7bf5fc	Leonardo da Vinci	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-02-04 02:01:27.720734+00	Leonardo da Vinci	Léonard de Vinci
ccaf179b-a8a9-48c3-944c-2a0a4503a9f9	Famous paintings	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-02-06 15:05:32.431052+00	Famous Paintings	Les Peintures Célèbres
ce8d25d9-ee76-40ad-aae3-59e0aa901529	The Olympics	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-02-03 02:01:22.942671+00	The Olympics	Les Jeux Olympiques
d2cf5fde-52f5-4ed7-acba-63df68c91685	Super Mario Bros	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-02-10 02:01:17.927429+00	Super Mario Bros	Super Mario Bros
e6230c19-1485-46ac-a63b-96788248d488	Tropical forests	0055a076-82f5-4272-8502-053bd8976caa	2026-02-06 12:22:26.834426+00	Tropical Forests	Les Forêts Tropicales
e83fb535-e994-4c79-8242-32482940f89c	Ancient Rome	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-02-04 08:50:24.955241+00	Ancient Rome	La Rome Antique
eb42f251-95f3-43fe-af4e-75db93f469a3	Social Media	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-02 18:50:14.930247+00	Social Media	Les Réseaux Sociaux
f1566364-b0f4-4928-b446-90817f267acf	Space Exploration	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-16 02:01:20.326854+00	Space Exploration	L'Exploration Spatiale
f4c59076-e9aa-40c7-98c2-062ddf455feb	Hip hop	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-07 10:41:57.587331+00	Hip Hop	Le Hip-Hop
f8c176f7-7a05-4d58-a87c-097145c5d8da	The French Revolution	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-02-06 13:38:44.011135+00	The French Revolution	La Révolution Française
c7566e78-841e-4712-9f70-ac2bd520a5b6	Electric Vehicles	31db30c5-7871-4498-94eb-a8314aa81982	2026-02-22 02:01:26.199464+00	Electric Vehicles	Véhicules électriques
621dd09a-5873-4c63-b4dd-1ad6ff3810d9	Country Music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-02-24 02:01:23.847241+00	Country Music	Musique Country
8ae31052-ae13-4fde-85d3-320c15ad31ca	Space Technology and Spacecraft	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-26 02:01:24.075336+00	Space Technology and Spacecraft	Technologie spatiale et vaisseaux spatiaux
9ed8aa8b-526b-4401-9026-e72789adc193	Galaxies	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-02-28 02:01:28.189859+00	Galaxies	Galaxies
b9759f57-b1e6-46cc-882b-3e22ccf918d3	Vincent van Gogh	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-03-02 02:01:23.728638+00	Vincent van Gogh	Vincent van Gogh
3bc4cf05-2dcb-415d-b6d3-1173a09c4238	Movie Genres	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-03-04 02:01:22.793223+00	Movie Genres	Genres cinématographiques
8f4abd02-d1ae-4a7d-808a-2bd3cd7d345c	Rivers and Lakes	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-03-06 02:01:30.70149+00	Rivers and Lakes	Rivières et Lacs
d03d5b65-5b1d-4453-bbe8-286c26644d20	Music Festivals	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-03-08 02:01:21.21964+00	Music Festivals	Festivals de musique
1263cc57-9b5d-4f9c-bcff-fbc4115e36ad	The Industrial Revolution	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-03-10 02:01:34.120089+00	The Industrial Revolution	La Révolution industrielle
7e55967e-8fab-4da5-9d29-03e99b424b77	Personal Computers	31db30c5-7871-4498-94eb-a8314aa81982	2026-03-12 02:01:19.748649+00	Personal Computers	Ordinateurs personnels
d1c0b44f-142d-4ac8-9ea7-d498c4609d98	Classical Music	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-03-14 03:01:14.488419+00	Classical Music	Musique classique
55ae7f3e-7116-414b-8469-fddf8f8ced7a	Animal Adaptation and Evolution	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-03-16 03:01:30.152775+00	Animal Adaptation and Evolution	Adaptation et évolution animale
dbf10cb5-eb5b-4089-b4e7-60ac14bde367	Space Weather and Solar Activity	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-03-18 08:17:44.120158+00	Space Weather and Solar Activity	Météorologie spatiale et activité solaire
29f31707-b46b-42de-a407-acc5ea85ca0c	Jazz Music	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-03-20 03:01:16.399682+00	Jazz Music	Musique Jazz
2a9c51e9-ef47-4187-b08d-73ae34515b81	Ancient Greek Theater	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-03-22 03:01:27.179099+00	Ancient Greek Theater	Théâtre grec antique
93e55835-e39c-4b64-9a04-eee6360ab172	Insects	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-03-23 10:50:51.540544+00	Insects	Les insectes
60813dd7-38e4-4f73-812b-8398ae76f46c	Science fiction films	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-03-23 11:15:49.66703+00	Science fiction films	Les films de science-fiction
da0c5646-c5d7-43ea-ba60-127e0c205a7e	Deserts and extreme environments	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-03-23 12:31:11.071998+00	Deserts and extreme environments	Les deserts et environnements extremes
700e24ba-949a-4a0a-96d7-793e6386911b	Fortnite and Battle Royale games	137a24ef-330a-423b-bdd2-bffcb132fefb	2026-03-23 13:21:07.885217+00	Fortnite and Battle Royale games	Fortnite et les jeux Battle Royale
dd4b313b-d905-4a34-9eef-c246107da875	Robotics	31db30c5-7871-4498-94eb-a8314aa81982	2026-03-25 03:01:15.258506+00	Robotics	Robotique
fa75ac4a-fc27-4d8f-b3a7-dd7e4756a847	Boxing	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-03-27 04:01:19.913377+00	Boxing	Boxe
b89119c7-a544-4427-af9a-b0c3463d870e	Movie Soundtracks	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-03-29 03:01:22.828218+00	Movie Soundtracks	Bandes sonores de films
9457c42f-b751-4330-8f04-a0f53abeb59a	Ice Hockey	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-03-31 03:01:15.105881+00	Ice Hockey	Hockey sur glace
410daccf-e371-465f-802c-d49f30cdf982	Music Streaming and Digital Music	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-04-02 03:01:21.712339+00	Music Streaming and Digital Music	Streaming musical et musique numérique
68967307-a93f-41af-ae7f-e0fae1424d3e	American Football	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-04-04 03:01:20.923117+00	American Football	Football américain
1cb78072-de40-4597-baae-96495de9341f	Television Broadcasting	31db30c5-7871-4498-94eb-a8314aa81982	2026-04-06 03:01:27.63641+00	Television Broadcasting	Télédiffusion
eee405b7-c05d-4923-b3de-bb6ca67fb83f	Animal Physical Characteristics and Anatomy	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-04-21 03:01:11.745081+00	Animal Physical Characteristics and Anatomy	Caractéristiques physiques et anatomie animales
7ad5afaf-1fa9-4ef0-a095-143a2e5b3705	Space Suits and Life Support Systems	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-04-22 03:01:19.680908+00	Space Suits and Life Support Systems	Combinaisons spatiales et systèmes de survie
156aea5f-f8d2-4fb7-9208-1746a87326f3	DNA and Genetics	0055a076-82f5-4272-8502-053bd8976caa	2026-04-23 03:01:04.540388+00	DNA and Genetics	ADN et génétique
102fb302-1ef3-459e-9d84-9ff8f5d2e94b	Formula One Racing	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-04-24 03:01:17.122732+00	Formula One Racing	Formule 1
a9a2e281-6d29-49ad-8edd-34f1d0afd32f	Movie Special Effects and Visual Effects	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-04-25 03:01:20.872044+00	Movie Special Effects and Visual Effects	Effets spéciaux et effets visuels au cinéma
b5222e8f-f14e-41b1-962f-316491658f55	Virtual Reality	31db30c5-7871-4498-94eb-a8314aa81982	2026-04-26 03:01:15.582394+00	Virtual Reality	Réalité Virtuelle
93991d69-95db-4a2c-bd5e-43c340649d56	Sculpture	38648836-0348-4a8d-9ba5-ef48bc151e1f	2026-04-27 03:01:21.84876+00	Sculpture	Sculpture
4249ba34-acf8-4d8a-ab2a-7c0b6493bc15	Music Awards and Ceremonies	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	2026-04-28 03:01:12.869329+00	Music Awards and Ceremonies	Cérémonies et Prix Musicaux
dca7c42c-396e-4e1a-9193-8e4880b3602a	The Great Depression	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	2026-04-30 03:01:09.582435+00	The Great Depression	La Grande Dépression
424d32e4-c095-4976-ad47-042792a480f1	Time Zones and International Date Line	eb50291e-5d1d-4b20-875e-0fdfa59f9118	2026-05-01 03:01:04.818265+00	Time Zones and International Date Line	Fuseaux horaires et ligne de changement de date
26d23b41-4676-4b66-9009-9fc636bc25e3	Animal Behavior and Intelligence	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	2026-05-02 03:01:20.420465+00	Animal Behavior and Intelligence	Comportement et Intelligence Animale
ac34c409-9cd1-4fa3-b31c-6984d6a74ab7	Space Telescopes and Observatories	643ddd77-130c-41ff-8a7c-63e9c872c61d	2026-05-03 03:01:08.541468+00	Space Telescopes and Observatories	Télescopes spatiaux et observatoires
f8d8acf2-cdce-4e66-b6a2-6964558d2c7f	States of Matter	0055a076-82f5-4272-8502-053bd8976caa	2026-05-04 03:01:06.147101+00	States of Matter	États de la matière
75ebd17b-402e-40ba-a2ba-2946a30f869b	Cycling	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	2026-05-05 03:01:20.428073+00	Cycling	Cyclisme
10059a87-35da-45e4-84e7-894604a7c8ee	Movie Sequels and Franchises	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	2026-05-06 03:01:17.199654+00	Movie Sequels and Franchises	Suites de films et franchises cinématographiques
08b4bf73-5b46-46eb-871f-601d899943a6	Cloud Computing	31db30c5-7871-4498-94eb-a8314aa81982	2026-05-07 03:01:11.013345+00	Cloud Computing	Informatique en nuage
\.


--
-- Data for Name: theme_translations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.theme_translations (id, theme_id, language_code, name, description, created_at) FROM stdin;
672548b0-2f27-475a-98b1-0ee82e9543d4	eb50291e-5d1d-4b20-875e-0fdfa59f9118	en	Geography	Questions about countries, capitals, rivers and geographical features	2026-01-21 13:27:09.346329+00
71470a1c-f11e-4f57-9cb0-86e8f2aec1d3	eb50291e-5d1d-4b20-875e-0fdfa59f9118	fr	Géographie	Questions sur les pays, capitales, fleuves et caractéristiques géographiques	2026-01-21 13:27:09.346329+00
48bc68c9-f792-4ea8-9178-3c58429e7ea2	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	en	History	Historical events, famous figures, dates and civilizations	2026-01-21 13:27:09.346329+00
ef4e8275-fb2e-4beb-917f-d427a9952967	59d9d329-a4b5-4cb3-a5f2-3bb2674d5109	fr	Histoire	Événements historiques, personnages célèbres, dates et civilisations	2026-01-21 13:27:09.346329+00
104bf244-0e8a-47d7-a6c2-470a13e10c9e	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	en	Animals	Wildlife, biodiversity, animal behaviors and habitats	2026-01-21 13:27:09.346329+00
cd48e278-8050-4461-988c-950f0e28153a	b65934a1-6bd3-4ff1-b1e1-4516455c3c11	fr	Animaux	Faune, biodiversité, comportements animaux et habitats	2026-01-21 13:27:09.346329+00
1763ddea-b4c0-412b-a160-8350b234db1f	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	en	Cinema	Movies, directors, actors and film history	2026-01-26 15:17:18.600968+00
9ee5aa0e-7c63-4332-bda0-6197e548bff8	67f21e5a-a5ad-4557-9bdb-1321e5278ee0	fr	Cinéma	Films, réalisateurs, acteurs et histoire du cinéma	2026-01-26 15:17:18.600968+00
ce8d99e1-4b39-4256-ae92-bb00c15426c1	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	en	Music	Artists, genres, instruments and music history	2026-01-26 15:17:18.600968+00
042967b4-1ad4-4516-a1c2-aed88241e2f3	3ab52e70-dbd5-4b5b-8307-e6ff34c25bcf	fr	Musique	Artistes, genres, instruments et histoire de la musique	2026-01-26 15:17:18.600968+00
88cd36bb-5d8e-4951-b21a-39e33bbd4151	31db30c5-7871-4498-94eb-a8314aa81982	en	Technology	Programming, innovations, AI and tech history	2026-01-26 15:17:18.600968+00
447ff0e8-4aab-405b-af81-150e6f8def62	31db30c5-7871-4498-94eb-a8314aa81982	fr	Technologies	Programmation, innovations, IA et histoire tech	2026-01-26 15:17:18.600968+00
af1f858f-00aa-42c4-941c-870ea6bd723b	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	en	Sports	Athletes, competitions, rules and sports history	2026-01-26 15:17:18.600968+00
e6bc306f-6bbf-4eb5-9700-95e9a68af21d	3591857c-ae20-44fc-8ab0-eba9ecb4fc8d	fr	Sports	Athlètes, compétitions, règles et histoire du sport	2026-01-26 15:17:18.600968+00
243e2bdf-5fc2-4e18-856f-73c289f91511	38648836-0348-4a8d-9ba5-ef48bc151e1f	en	Arts	Painters, sculptures, movements and art history	2026-01-26 15:17:18.600968+00
54abe927-951f-46fe-bae4-12dc90ac2fdf	38648836-0348-4a8d-9ba5-ef48bc151e1f	fr	Arts	Peintres, sculptures, mouvements et histoire de l'art	2026-01-26 15:17:18.600968+00
7355fbe1-fc88-4ea3-abf4-39cc99a52d5b	643ddd77-130c-41ff-8a7c-63e9c872c61d	en	Space	Astronomy, planets, missions and space exploration	2026-01-26 15:17:18.600968+00
bee4bb65-daf8-4b8d-a7b3-82f77b504283	643ddd77-130c-41ff-8a7c-63e9c872c61d	fr	Espace	Astronomie, planètes, missions et exploration spatiale	2026-01-26 15:17:18.600968+00
a10f8419-1ade-4e4e-ba60-32dfe6c90fff	0055a076-82f5-4272-8502-053bd8976caa	en	Science	Physics, chemistry, biology and scientific discoveries	2026-01-26 15:17:18.600968+00
b81c883e-f005-4a48-b3bd-0c14cfe205e5	0055a076-82f5-4272-8502-053bd8976caa	fr	Sciences	Physique, chimie, biologie et découvertes scientifiques	2026-01-26 15:17:18.600968+00
287d07bd-c433-4524-b6e7-613ac0326be1	137a24ef-330a-423b-bdd2-bffcb132fefb	en	Video Games	Games, consoles, characters and gaming history	2026-01-26 15:17:18.600968+00
fcf195e2-8f4b-4f4b-accc-bd1ef56dfa5f	137a24ef-330a-423b-bdd2-bffcb132fefb	fr	Jeux vidéo	Jeux, consoles, personnages et histoire du gaming	2026-01-26 15:17:18.600968+00
\.


--
-- PostgreSQL database dump complete
--

\unrestrict TtP54XFboXVbU2lOEyl4p3wREF5Qt0HF00Hjm5eN0pQGt0F5Y8dsMTRm29a9Tpi

