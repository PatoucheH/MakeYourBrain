--
-- PostgreSQL database dump
--

\restrict tt2f7jj1MsSDtjXJYG0lQ02YplHstRRCUJ23aAE28RQ8sbjuxf6hhJ5kYpiPaqI

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: add_bonus_xp(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_bonus_xp(p_user_id uuid, p_theme_id uuid, p_bonus_xp integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_new_xp INTEGER;
    v_new_level INTEGER;
  BEGIN
    INSERT INTO user_theme_progress (
      user_id,
      theme_id,
      xp,
      total_questions,
      correct_answers
    )
    VALUES (
      p_user_id,
      p_theme_id,
      p_bonus_xp,
      0,
      0
    )
    ON CONFLICT (user_id, theme_id) DO UPDATE SET
      xp = user_theme_progress.xp + p_bonus_xp,
      updated_at = NOW()
    RETURNING xp INTO v_new_xp;

    v_new_level := calculate_level_from_xp(v_new_xp);

    UPDATE user_theme_progress
    SET level = v_new_level
    WHERE user_id = p_user_id AND theme_id = p_theme_id;
  END;
  $$;


--
-- Name: add_lives_from_ad(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_lives_from_ad(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    IF (current_setting('request.jwt.claims', true)::jsonb->>'role') != 'service_role' THEN
      RAISE EXCEPTION 'Forbidden';
    END IF;

    UPDATE user_lives
    SET current_lives = LEAST(current_lives + 2, max_lives)
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
      INSERT INTO user_lives (user_id, current_lives, max_lives)
      VALUES (p_user_id, 10, 10);
    END IF;
  END;
  $$;


--
-- Name: add_quiz_completion_xp(uuid, uuid, uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_quiz_completion_xp(p_user_id uuid, p_theme_id uuid, p_question_ids uuid[], p_answer_ids uuid[]) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$                                                                                                                                    DECLARE
    v_i INTEGER;                                                                                                                                 
    v_is_correct BOOLEAN;                                                                                                                            v_xp_total INTEGER := 0;
  BEGIN                                                                                                                                              IF array_length(p_question_ids, 1) != array_length(p_answer_ids, 1) THEN
      RAISE EXCEPTION 'question_ids and answer_ids must have the same length';                                                                   
    END IF;                                                                                                                                        
    FOR v_i IN 1..array_length(p_question_ids, 1)                                                                                                
    LOOP
      SELECT a.is_correct INTO v_is_correct
      FROM answers a
      WHERE a.id = p_answer_ids[v_i]                                                                                                             
        AND a.question_id = p_question_ids[v_i];                                                                                                                                                                                                                                                        IF FOUND THEN                                                                                                                                      PERFORM add_theme_xp(p_user_id, p_theme_id, v_is_correct);
        IF v_is_correct THEN                                                                                                                               v_xp_total := v_xp_total + 10;
        END IF;                                                                                                                                        END IF;
    END LOOP;                                                                                                                                    
                                                                                                                                                     RETURN v_xp_total;                                                                                                                             END;                                                                                                                                           
  $$;


--
-- Name: add_theme_xp(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_theme_xp(p_user_id uuid, p_theme_id uuid, p_is_correct boolean) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_xp_gain INTEGER := CASE WHEN p_is_correct THEN 10 ELSE 0 END;
  v_new_xp INTEGER;
  v_new_level INTEGER;
BEGIN
  -- Insérer ou mettre à jour
  INSERT INTO user_theme_progress (
    user_id,
    theme_id,
    xp,
    total_questions,
    correct_answers
  )
  VALUES (
    p_user_id,
    p_theme_id,
    v_xp_gain,
    1,
    CASE WHEN p_is_correct THEN 1 ELSE 0 END
  )
  ON CONFLICT (user_id, theme_id) DO UPDATE SET
    xp = user_theme_progress.xp + v_xp_gain,
    total_questions = user_theme_progress.total_questions + 1,
    correct_answers = user_theme_progress.correct_answers + CASE WHEN p_is_correct THEN 1 ELSE 0 END,
    updated_at = NOW()
  RETURNING xp INTO v_new_xp;

  -- Calculer le nouveau niveau
  v_new_level := calculate_level_from_xp(v_new_xp);

  -- Mettre à jour le niveau
  UPDATE user_theme_progress
  SET level = v_new_level
  WHERE user_id = p_user_id AND theme_id = p_theme_id;
END;
$$;


--
-- Name: calculate_level_from_xp(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_level_from_xp(p_total_xp integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public'
    AS $$                                                                                                                                                 DECLARE                                                                                                                                                             
    v_level INTEGER := 1;
    v_xp_accumulated INTEGER := 0;
    v_xp_for_level INTEGER;
  BEGIN
    LOOP
      v_xp_for_level := 200 + (v_level - 1) * 100 + (v_level / 10) * 500;
      IF v_xp_accumulated + v_xp_for_level > p_total_xp THEN
        RETURN v_level;
      END IF;
      v_xp_accumulated := v_xp_accumulated + v_xp_for_level;
      v_level := v_level + 1;
    END LOOP;
  END;
  $$;


--
-- Name: check_achievements(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_achievements(p_user_id uuid) RETURNS TABLE(id uuid, key text, name_en text, name_fr text, description_en text, description_fr text, icon text, category text, xp_reward integer, condition_value integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_total_questions integer;
    v_current_streak  integer;
    v_pvp_wins        integer;
    v_accuracy        integer;
    v_daily_streak    integer;
    v_themes_explored integer;
    v_followers_count integer;
  BEGIN
    SELECT
      COALESCE(us.total_questions, 0),
      COALESCE(us.current_streak, 0),
      COALESCE(us.pvp_wins, 0),
      CASE
        WHEN COALESCE(us.total_questions, 0) > 0
          THEN ROUND(COALESCE(us.correct_answers, 0) * 100.0 / us.total_questions)::integer
        ELSE 0
      END,
      COALESCE(us.daily_streak, 0)
    INTO v_total_questions, v_current_streak, v_pvp_wins, v_accuracy, v_daily_streak
    FROM public.user_stats us
    WHERE us.user_id = p_user_id;

    SELECT COUNT(DISTINCT utp.theme_id)::integer
    INTO v_themes_explored
    FROM public.user_theme_progress utp
    WHERE utp.user_id = p_user_id;

    SELECT COUNT(*)::integer
    INTO v_followers_count
    FROM public.user_follows
    WHERE following_id = p_user_id;

    INSERT INTO public.user_achievements (user_id, achievement_id)
    SELECT p_user_id, a.id
    FROM public.achievements a
    WHERE
      (a.condition_type = 'total_questions'  AND v_total_questions  >= a.condition_value) OR
      (a.condition_type = 'current_streak'   AND v_current_streak   >= a.condition_value) OR
      (a.condition_type = 'pvp_wins'         AND v_pvp_wins         >= a.condition_value) OR
      (a.condition_type = 'accuracy_percent' AND v_accuracy         >= a.condition_value) OR
      (a.condition_type = 'daily_streak'     AND v_daily_streak     >= a.condition_value) OR
      (a.condition_type = 'themes_explored'  AND v_themes_explored  >= a.condition_value) OR
      (a.condition_type = 'followers_count'  AND v_followers_count  >= a.condition_value)
    ON CONFLICT DO NOTHING;

    RETURN QUERY
    SELECT
      a.id,
      a.key,
      a.name_en,
      a.name_fr,
      a.description_en,
      a.description_fr,
      a.icon,
      a.category,
      a.xp_reward,
      a.condition_value
    FROM public.user_achievements ua
    JOIN public.achievements a ON a.id = ua.achievement_id
    WHERE ua.user_id = p_user_id
      AND ua.unlocked_at >= NOW() - INTERVAL '5 seconds';
  END;
  $$;


--
-- Name: clean_old_matchmaking_queue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clean_old_matchmaking_queue() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$                                                                                                                                                     
  BEGIN                                                                                                                                                                  
    DELETE FROM pvp_matchmaking_queue                                                                                                                                    
    WHERE created_at < NOW() - INTERVAL '24 hours';                                                                                                                      
  END;
  $$;


--
-- Name: complete_daily_concept(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_daily_concept(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
  BEGIN
    UPDATE user_stats
    SET
      daily_streak = CASE
        WHEN last_daily_completed_at = CURRENT_DATE            THEN daily_streak
        WHEN last_daily_completed_at = CURRENT_DATE - 1        THEN daily_streak + 1
        ELSE 1
      END,
      last_daily_completed_at = CURRENT_DATE
    WHERE user_id = p_user_id;
  END;
  $$;


--
-- Name: cumulative_xp_for_level(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cumulative_xp_for_level(p_level integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_total INTEGER := 0;
    v_i INTEGER;
  BEGIN
    FOR v_i IN 1..(p_level - 1) LOOP
      v_total := v_total + 200 + (v_i - 1) * 100 + (v_i / 10) * 500;
    END LOOP;
    RETURN v_total;
  END;
  $$;


--
-- Name: delete_own_account(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_own_account() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    uid uuid := auth.uid();
  BEGIN
    -- Forfeit les matches actifs : l'autre joueur gagne
    UPDATE pvp_matches
    SET
      status = 'completed',
      winner_id = CASE
        WHEN player1_id = uid THEN player2_id
        ELSE player1_id
      END
    WHERE (player1_id = uid OR player2_id = uid)
      AND status NOT IN ('completed', 'cancelled');

    -- Supprimer de la file de matchmaking
    DELETE FROM pvp_matchmaking_queue WHERE user_id = uid;

    -- Supprimer le compte (les autres tables cascadent automatiquement)
    DELETE FROM auth.users WHERE id = uid;
  END;
  $$;


--
-- Name: follow_user(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.follow_user(p_following_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.user_follows (follower_id, following_id)
  VALUES (auth.uid(), p_following_id)
  ON CONFLICT (follower_id, following_id) DO NOTHING;
END;
$$;


--
-- Name: get_daily_concept(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_daily_concept(p_user_id uuid, p_language_code text) RETURNS TABLE(concept_name text, concept_description text, theme_id uuid, theme_name text, concept_date date, already_completed boolean)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_last_completed date;
    v_today date := CURRENT_DATE;
  BEGIN
    SELECT last_daily_completed_at INTO v_last_completed
    FROM user_stats
    WHERE user_id = p_user_id;

    RETURN QUERY
    SELECT
      COALESCE(
        CASE WHEN p_language_code = 'fr' THEN qc.concept_fr ELSE qc.concept_en END,
        qc.concept
      ) AS concept_name,
      ''::text AS concept_description,
      qc.theme_id,
      COALESCE(tt.name, '')::text AS theme_name,
      qc.created_at::date AS concept_date,
      (v_last_completed IS NOT NULL AND v_last_completed = v_today) AS already_completed
    FROM question_concepts qc
    LEFT JOIN theme_translations tt
      ON tt.theme_id = qc.theme_id
      AND tt.language_code = p_language_code
    ORDER BY qc.created_at DESC
    LIMIT 1;
  END;
  $$;


--
-- Name: get_daily_questions(text, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_daily_questions(p_language_code text DEFAULT 'fr'::text, p_limit integer DEFAULT 10, p_easy_percent integer DEFAULT 100, p_medium_percent integer DEFAULT 0, p_hard_percent integer DEFAULT 0) RETURNS TABLE(question_id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_concept_id uuid;
    v_easy_count int;
    v_medium_count int;
    v_hard_count int;
  BEGIN
    SELECT id INTO v_concept_id
    FROM question_concepts
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_concept_id IS NULL THEN
      RETURN;
    END IF;

    v_easy_count   := ROUND(p_limit * p_easy_percent   / 100.0);
    v_medium_count := ROUND(p_limit * p_medium_percent / 100.0);
    v_hard_count   := p_limit - v_easy_count - v_medium_count;

    RETURN QUERY
    WITH easy_q AS (
      SELECT q.id, q.theme_id, q.difficulty
      FROM questions q
      WHERE q.concept_id = v_concept_id AND q.difficulty = 'easy'
      ORDER BY RANDOM()
      LIMIT v_easy_count
    ),
    medium_q AS (
      SELECT q.id, q.theme_id, q.difficulty
      FROM questions q
      WHERE q.concept_id = v_concept_id AND q.difficulty = 'medium'
      ORDER BY RANDOM()
      LIMIT v_medium_count
    ),
    hard_q AS (
      SELECT q.id, q.theme_id, q.difficulty
      FROM questions q
      WHERE q.concept_id = v_concept_id AND q.difficulty = 'hard'
      ORDER BY RANDOM()
      LIMIT v_hard_count
    ),
    combined AS (
      SELECT * FROM easy_q
      UNION ALL SELECT * FROM medium_q
      UNION ALL SELECT * FROM hard_q
    )
    SELECT
      c.id AS question_id,
      c.theme_id,
      c.difficulty,
      qt.question_text,
      qt.explanation,
      qt.language_code,
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'answer_id', a.id,
            'answer_text', at2.answer_text,
            'is_correct', a.is_correct,
            'display_order', a.display_order
          )
        )
        FROM answers a
        JOIN answer_translations at2 ON at2.answer_id = a.id
          AND at2.language_code = p_language_code
        WHERE a.question_id = c.id
      ) AS answers
    FROM combined c
    JOIN question_translations qt ON qt.question_id = c.id
      AND qt.language_code = p_language_code
    ORDER BY RANDOM();
  END;
  $$;


--
-- Name: get_display_name(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_display_name(p_user_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_username TEXT;
    v_display_name TEXT;
    v_email TEXT;
    email_parts TEXT[];
    masked_email TEXT;
  BEGIN
    SELECT username INTO v_username
    FROM public.user_stats
    WHERE user_id = p_user_id;

    IF v_username IS NOT NULL AND v_username != '' THEN
      RETURN v_username;
    END IF;

    SELECT display_name INTO v_display_name
    FROM public.user_profiles
    WHERE user_id = p_user_id;

    IF v_display_name IS NOT NULL AND v_display_name != '' THEN
      RETURN v_display_name;
    END IF;

    SELECT email INTO v_email
    FROM auth.users
    WHERE id = p_user_id;

    IF auth.uid() = p_user_id THEN
      RETURN COALESCE(v_email, 'Anonymous');
    END IF;

    IF v_email IS NOT NULL AND v_email LIKE '%@%' THEN
      email_parts := string_to_array(v_email, '@');
      IF length(email_parts[1]) > 0 THEN
        masked_email := substring(email_parts[1], 1, 1) || '***@' || email_parts[2];
        RETURN masked_email;
      END IF;
    END IF;

    RETURN 'Anonymous';
  END;
  $$;


--
-- Name: get_follow_counts(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_follow_counts(p_user_id uuid) RETURNS TABLE(followers_count bigint, following_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.user_follows uf WHERE uf.following_id = p_user_id) AS followers_count,
    (SELECT COUNT(*) FROM public.user_follows uf WHERE uf.follower_id = p_user_id) AS following_count;
END;
$$;


--
-- Name: get_followers(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_followers(p_user_id uuid) RETURNS TABLE(user_id uuid, username text, is_followed_back boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      us.user_id,
      us.username,
      EXISTS (
        SELECT 1 FROM public.user_follows uf2
        WHERE uf2.follower_id = p_user_id AND uf2.following_id = us.user_id
      ) AS is_followed_back
    FROM public.user_follows uf
    INNER JOIN public.user_stats us ON us.user_id = uf.follower_id
    WHERE uf.following_id = p_user_id
    ORDER BY us.username ASC;
  END;
  $$;


--
-- Name: get_following(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_following(p_user_id uuid) RETURNS TABLE(user_id uuid, username text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      us.user_id,
      us.username
    FROM public.user_follows uf
    INNER JOIN public.user_stats us ON us.user_id = uf.following_id
    WHERE uf.follower_id = p_user_id
    ORDER BY us.username ASC;
  END;
  $$;


--
-- Name: get_following_leaderboard(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_following_leaderboard(p_user_id uuid) RETURNS TABLE(user_id uuid, display_name text, total_xp bigint, accuracy numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    lg.user_id,
    lg.display_name,
    lg.total_xp,
    lg.accuracy
  FROM public.leaderboard_global lg
  WHERE lg.user_id IN (
    SELECT uf.following_id FROM public.user_follows uf WHERE uf.follower_id = p_user_id
  )
  OR lg.user_id = p_user_id
  ORDER BY lg.total_xp DESC
  LIMIT 100;
END;
$$;


--
-- Name: get_player_info(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_player_info(p_user_id uuid) RETURNS TABLE(user_id uuid, username text, pvp_rating integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      us.user_id,
      us.username,
      COALESCE(us.pvp_rating, 1000)
    FROM user_stats us
    WHERE us.user_id = p_user_id;
  END;
  $$;


--
-- Name: get_pvp_following_leaderboard(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_pvp_following_leaderboard(p_user_id uuid) RETURNS TABLE(user_id uuid, username text, pvp_rating integer, pvp_wins integer, pvp_losses integer, pvp_draws integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      us.user_id,
      us.username,
      us.pvp_rating,
      us.pvp_wins,
      us.pvp_losses,
      us.pvp_draws
    FROM public.user_follows uf
    INNER JOIN public.user_stats us ON us.user_id = uf.following_id
    WHERE uf.follower_id = p_user_id
    ORDER BY us.pvp_rating DESC;
  END;
  $$;


--
-- Name: get_random_questions(uuid, text, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_random_questions(p_theme_id uuid, p_language_code text, p_limit integer DEFAULT 10, p_easy_percent integer DEFAULT 100, p_medium_percent integer DEFAULT 0, p_hard_percent integer DEFAULT 0) RETURNS TABLE(question_id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_easy_count INTEGER;
    v_medium_count INTEGER;
    v_hard_count INTEGER;
BEGIN
    -- Calculer le nombre de questions par difficulté
    v_easy_count := FLOOR(p_limit * p_easy_percent / 100.0);
    v_medium_count := FLOOR(p_limit * p_medium_percent / 100.0);
    v_hard_count := p_limit - v_easy_count - v_medium_count;

    RETURN QUERY
    WITH selected_questions AS (
        -- Sélectionner les questions faciles
        (
            SELECT 
                q.id,
                q.theme_id,
                q.difficulty,
                qt.question_text,
                qt.explanation,
                qt.language_code
            FROM questions q
            INNER JOIN question_translations qt ON q.id = qt.question_id
            WHERE q.theme_id = p_theme_id
                AND qt.language_code = p_language_code
                AND q.difficulty = 'easy'
            ORDER BY RANDOM()
            LIMIT v_easy_count
        )
        UNION ALL
        -- Sélectionner les questions moyennes
        (
            SELECT 
                q.id,
                q.theme_id,
                q.difficulty,
                qt.question_text,
                qt.explanation,
                qt.language_code
            FROM questions q
            INNER JOIN question_translations qt ON q.id = qt.question_id
            WHERE q.theme_id = p_theme_id
                AND qt.language_code = p_language_code
                AND q.difficulty = 'medium'
            ORDER BY RANDOM()
            LIMIT v_medium_count
        )
        UNION ALL
        -- Sélectionner les questions difficiles
        (
            SELECT 
                q.id,
                q.theme_id,
                q.difficulty,
                qt.question_text,
                qt.explanation,
                qt.language_code
            FROM questions q
            INNER JOIN question_translations qt ON q.id = qt.question_id
            WHERE q.theme_id = p_theme_id
                AND qt.language_code = p_language_code
                AND q.difficulty = 'hard'
            ORDER BY RANDOM()
            LIMIT v_hard_count
        )
    ),
    question_answers AS (
        SELECT 
            sq.id AS question_id,
            jsonb_agg(
                jsonb_build_object(
                    'answer_id', a.id,
                    'answer_text', at.answer_text,
                    'is_correct', a.is_correct,
                    'display_order', a.display_order
                )
                ORDER BY a.display_order
            ) AS answers
        FROM selected_questions sq
        INNER JOIN answers a ON sq.id = a.question_id
        INNER JOIN answer_translations at ON a.id = at.answer_id
        WHERE at.language_code = p_language_code
        GROUP BY sq.id
    )
    SELECT 
        sq.id,
        sq.theme_id,
        sq.difficulty,
        sq.question_text,
        sq.explanation,
        sq.language_code,
        qa.answers
    FROM selected_questions sq
    LEFT JOIN question_answers qa ON sq.id = qa.question_id
    ORDER BY RANDOM();
END;
$$;


--
-- Name: get_random_questions(uuid, text, integer, integer, integer, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_random_questions(p_theme_id uuid, p_language_code text, p_limit integer, p_easy_percent integer DEFAULT 100, p_medium_percent integer DEFAULT 0, p_hard_percent integer DEFAULT 0, p_user_id uuid DEFAULT NULL::uuid) RETURNS TABLE(id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
  DECLARE
      v_easy_count INTEGER;
      v_medium_count INTEGER;
      v_hard_count INTEGER;
  BEGIN
      v_easy_count := FLOOR(p_limit * p_easy_percent / 100.0);
      v_medium_count := FLOOR(p_limit * p_medium_percent / 100.0);
      v_hard_count := p_limit - v_easy_count - v_medium_count;

      RETURN QUERY
      WITH selected_questions AS (
          (
              SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
              FROM questions q
              INNER JOIN question_translations qt ON q.id = qt.question_id
              LEFT JOIN (
                  SELECT question_id, MAX(answered_at) AS last_seen
                  FROM user_answers
                  WHERE user_id = p_user_id
                  GROUP BY question_id
              ) seen ON seen.question_id = q.id
              WHERE q.theme_id = p_theme_id
                  AND qt.language_code = p_language_code
                  AND q.difficulty = 'easy'
              ORDER BY (
                  RANDOM() +
                  CASE
                      WHEN seen.last_seen IS NULL THEN 1.0
                      ELSE LEAST(EXTRACT(EPOCH FROM NOW() - seen.last_seen) / (86400.0 * 30), 1.0)
                  END
              ) DESC
              LIMIT v_easy_count
          )
          UNION ALL
          (
              SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
              FROM questions q
              INNER JOIN question_translations qt ON q.id = qt.question_id
              LEFT JOIN (
                  SELECT question_id, MAX(answered_at) AS last_seen
                  FROM user_answers
                  WHERE user_id = p_user_id
                  GROUP BY question_id
              ) seen ON seen.question_id = q.id
              WHERE q.theme_id = p_theme_id
                  AND qt.language_code = p_language_code
                  AND q.difficulty = 'medium'
              ORDER BY (
                  RANDOM() +
                  CASE
                      WHEN seen.last_seen IS NULL THEN 1.0
                      ELSE LEAST(EXTRACT(EPOCH FROM NOW() - seen.last_seen) / (86400.0 * 30), 1.0)
                  END
              ) DESC
              LIMIT v_medium_count
          )
          UNION ALL
          (
              SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
              FROM questions q
              INNER JOIN question_translations qt ON q.id = qt.question_id
              LEFT JOIN (
                  SELECT question_id, MAX(answered_at) AS last_seen
                  FROM user_answers
                  WHERE user_id = p_user_id
                  GROUP BY question_id
              ) seen ON seen.question_id = q.id
              WHERE q.theme_id = p_theme_id
                  AND qt.language_code = p_language_code
                  AND q.difficulty = 'hard'
              ORDER BY (
                  RANDOM() +
                  CASE
                      WHEN seen.last_seen IS NULL THEN 1.0
                      ELSE LEAST(EXTRACT(EPOCH FROM NOW() - seen.last_seen) / (86400.0 * 30), 1.0)
                  END
              ) DESC
              LIMIT v_hard_count
          )
      ),
      question_answers AS (
          SELECT
              sq.id AS question_id,
              jsonb_agg(
                  jsonb_build_object(
                      'answer_id', a.id,
                      'answer_text', at.answer_text,
                      'is_correct', a.is_correct,
                      'display_order', a.display_order
                  )
                  ORDER BY a.display_order
              ) AS answers
          FROM selected_questions sq
          INNER JOIN answers a ON sq.id = a.question_id
          INNER JOIN answer_translations at ON a.id = at.answer_id
          WHERE at.language_code = p_language_code
          GROUP BY sq.id
      )
      SELECT sq.id, sq.theme_id, sq.difficulty, sq.question_text, sq.explanation, sq.language_code, qa.answers
      FROM selected_questions sq
      LEFT JOIN question_answers qa ON sq.id = qa.question_id
      ORDER BY RANDOM();
  END;
  $$;


--
-- Name: get_survival_leaderboard(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_survival_leaderboard(p_theme_id uuid, p_limit integer DEFAULT 20) RETURNS TABLE(rank bigint, user_id uuid, username text, best_score integer, played_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
      ROW_NUMBER() OVER (ORDER BY best.best_score DESC) AS rank,
      best.user_id,
      us.username,
      best.best_score,
      best.played_at
    FROM (
      SELECT DISTINCT ON (user_id)
        user_id,
        score AS best_score,
        played_at
      FROM survival_scores
      WHERE theme_id = p_theme_id
      ORDER BY user_id, score DESC, played_at ASC
    ) best
    JOIN user_stats us ON us.user_id = best.user_id
    ORDER BY best.best_score DESC
    LIMIT p_limit;
  $$;


--
-- Name: get_user_lives(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_lives(p_user_id uuid) RETURNS TABLE(current_lives integer, max_lives integer, next_life_in_seconds integer)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_result RECORD;
BEGIN
  -- Régénérer d'abord
  SELECT * INTO v_result FROM regenerate_lives(p_user_id);
  
  RETURN QUERY SELECT 
    v_result.current_lives,
    v_result.max_lives,
    EXTRACT(EPOCH FROM v_result.next_life_in)::INTEGER;
END;
$$;


--
-- Name: get_user_profile_summary(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_profile_summary(p_target_user_id uuid) RETURNS TABLE(user_id uuid, username text, total_questions integer, correct_answers integer, current_streak integer, best_streak integer, pvp_rating integer, pvp_wins integer, pvp_losses integer, pvp_draws integer, is_following boolean, followers_count bigint, following_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
      RETURN QUERY
      SELECT
        us.user_id,
        us.username,
        us.total_questions,
        us.correct_answers,
        us.current_streak,
        us.best_streak,
        us.pvp_rating,
        us.pvp_wins,
        us.pvp_losses,
        us.pvp_draws,
        EXISTS (
          SELECT 1 FROM public.user_follows uf
          WHERE uf.follower_id = auth.uid() AND uf.following_id = p_target_user_id
        ) AS is_following,
        (SELECT COUNT(*) FROM public.user_follows uf WHERE uf.following_id = p_target_user_id) AS followers_count,
        (SELECT COUNT(*) FROM public.user_follows uf WHERE uf.follower_id = p_target_user_id) AS following_count
      FROM public.user_stats us
      WHERE us.user_id = p_target_user_id;
  END;
  $$;


--
-- Name: get_user_progress_by_theme(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_progress_by_theme(p_user_id uuid, p_language text DEFAULT 'en') RETURNS TABLE(theme_id uuid, theme_name text, icon text, level integer, xp integer, xp_for_next_level integer, total_questions bigint, correct_answers bigint)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$BEGIN                                                                                                                                                                   RETURN QUERY                                                                                                                                                      
    SELECT                                                                                                                                                            
      t.id as theme_id,
      tt.name as theme_name,
      t.icon,
      COALESCE(utp.level, 1) as level,
      (COALESCE(utp.xp, 0) - cumulative_xp_for_level(COALESCE(utp.level, 1))) as xp,
      (200 + (COALESCE(utp.level, 1) - 1) * 100 + (COALESCE(utp.level, 1) / 10) * 500) as xp_for_next_level,
      COALESCE(utp.total_questions, 0)::BIGINT as total_questions,
      COALESCE(utp.correct_answers, 0)::BIGINT as correct_answers
    FROM themes t
    INNER JOIN theme_translations tt ON t.id = tt.theme_id
    LEFT JOIN user_theme_progress utp ON t.id = utp.theme_id AND utp.user_id = p_user_id
    WHERE tt.language_code = p_language
    ORDER BY COALESCE(utp.xp, 0) DESC;
  END;$$;


--
-- Name: get_weekly_leaderboard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_weekly_leaderboard() RETURNS TABLE(user_id uuid, display_name text, questions_answered bigint, correct_answers bigint, xp_earned bigint, accuracy numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT
      ua.user_id,
      get_display_name(ua.user_id) AS display_name,
      count(*) AS questions_answered,
      sum(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::bigint AS correct_answers,
      sum(CASE WHEN ua.is_correct THEN 10 ELSE 0 END)::bigint AS xp_earned,
      CASE
        WHEN count(*) > 0 THEN round(
          sum(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::numeric
          / count(*)::numeric * 100, 1
        )
        ELSE 0::numeric
      END AS accuracy
    FROM user_answers ua
    WHERE ua.answered_at >= date_trunc('week', now())
    GROUP BY ua.user_id
    ORDER BY xp_earned DESC, accuracy DESC;
  $$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, display_name)
  VALUES (NEW.id, NULL)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;


--
-- Name: increment_user_stats(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_user_stats(p_user_id uuid, p_is_correct boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    UPDATE user_stats
    SET
      total_questions = total_questions + 1,
      correct_answers = correct_answers + (CASE WHEN p_is_correct THEN 1 ELSE 0 END),
      last_answer_at  = NOW()
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
      INSERT INTO user_stats (user_id, total_questions, correct_answers, last_answer_at)
      VALUES (p_user_id, 1, CASE WHEN p_is_correct THEN 1 ELSE 0 END, NOW())
      ON CONFLICT (user_id) DO NOTHING;
    END IF;
  END;
  $$;


--
-- Name: pvp_check_queue_status(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_check_queue_status(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$                                                                                                                                                    
  DECLARE
    v_in_queue BOOLEAN;
    v_match_id UUID;
    v_time_in_queue INT;
  BEGIN
    SELECT EXISTS(SELECT 1 FROM pvp_matchmaking_queue WHERE user_id = p_user_id)
    INTO v_in_queue;

    SELECT id INTO v_match_id
    FROM pvp_matches
    WHERE (player1_id = p_user_id OR player2_id = p_user_id)
      AND status NOT IN ('completed', 'cancelled')
      AND created_at > NOW() - INTERVAL '30 minutes'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_match_id IS NOT NULL THEN
      DELETE FROM pvp_matchmaking_queue WHERE user_id = p_user_id;
      RETURN jsonb_build_object('in_queue', false, 'match_found', true, 'match_id', v_match_id);
    END IF;

    IF v_in_queue THEN
      SELECT EXTRACT(EPOCH FROM (NOW() - created_at))::INT INTO v_time_in_queue
      FROM pvp_matchmaking_queue WHERE user_id = p_user_id;

      UPDATE pvp_matchmaking_queue SET last_seen = NOW() WHERE user_id = p_user_id;
      RETURN jsonb_build_object('in_queue', true, 'match_found', false, 'time_in_queue', v_time_in_queue);
    END IF;

    RETURN jsonb_build_object('in_queue', false, 'match_found', false);
  END;
  $$;


--
-- Name: pvp_complete_match(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_complete_match(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_match RECORD;
  v_player1_total INTEGER;
  v_player2_total INTEGER;
  v_winner_id UUID;
  v_rating_diff INTEGER;
  v_player1_change INTEGER;
  v_player2_change INTEGER;
BEGIN
  -- Récupérer le match
  SELECT * INTO v_match FROM pvp_matches WHERE id = p_match_id;
  
  -- Calculer les scores totaux de tous les rounds
  SELECT 
    COALESCE(SUM(player1_score), 0),
    COALESCE(SUM(player2_score), 0)
  INTO v_player1_total, v_player2_total
  FROM pvp_rounds
  WHERE match_id = p_match_id;
  
  -- Déterminer le gagnant
  IF v_player1_total > v_player2_total THEN
    v_winner_id := v_match.player1_id;
  ELSIF v_player2_total > v_player1_total THEN
    v_winner_id := v_match.player2_id;
  ELSE
    v_winner_id := NULL; -- Match nul
  END IF;
  
  -- Calculer la différence de rating
  v_rating_diff := v_match.player1_rating_before - v_match.player2_rating_before;
  
  -- Calculer les changements de rating selon les règles
  IF v_winner_id = v_match.player1_id THEN
    -- Player 1 gagne
    IF v_rating_diff < -100 THEN
      v_player1_change := 10;  -- Adversaire avait plus de points
      v_player2_change := -8;
    ELSIF v_rating_diff > 100 THEN
      v_player1_change := 5;   -- Adversaire avait moins de points
      v_player2_change := -3;
    ELSE
      v_player1_change := 7;   -- Ratings équivalents
      v_player2_change := -5;
    END IF;
    
    -- Mettre à jour les stats
    UPDATE user_stats SET pvp_wins = pvp_wins + 1 WHERE user_id = v_match.player1_id;
    UPDATE user_stats SET pvp_losses = pvp_losses + 1 WHERE user_id = v_match.player2_id;
    
  ELSIF v_winner_id = v_match.player2_id THEN
    -- Player 2 gagne
    IF v_rating_diff > 100 THEN
      v_player1_change := -8;  -- Adversaire avait moins de points
      v_player2_change := 10;
    ELSIF v_rating_diff < -100 THEN
      v_player1_change := -3;  -- Adversaire avait plus de points
      v_player2_change := 5;
    ELSE
      v_player1_change := -5;  -- Ratings équivalents
      v_player2_change := 7;
    END IF;
    
    -- Mettre à jour les stats
    UPDATE user_stats SET pvp_losses = pvp_losses + 1 WHERE user_id = v_match.player1_id;
    UPDATE user_stats SET pvp_wins = pvp_wins + 1 WHERE user_id = v_match.player2_id;
    
  ELSE
    -- Match nul
    v_player1_change := 0;
    v_player2_change := 0;
    
    UPDATE user_stats SET pvp_draws = pvp_draws + 1 WHERE user_id = v_match.player1_id;
    UPDATE user_stats SET pvp_draws = pvp_draws + 1 WHERE user_id = v_match.player2_id;
  END IF;
  
  -- Appliquer les changements de rating
  UPDATE user_stats 
  SET pvp_rating = GREATEST(0, pvp_rating + v_player1_change)
  WHERE user_id = v_match.player1_id;
  
  UPDATE user_stats 
  SET pvp_rating = GREATEST(0, pvp_rating + v_player2_change)
  WHERE user_id = v_match.player2_id;
  
  -- Mettre à jour le match
  UPDATE pvp_matches
  SET 
    player1_total_score = v_player1_total,
    player2_total_score = v_player2_total,
    winner_id = v_winner_id,
    player1_rating_change = v_player1_change,
    player2_rating_change = v_player2_change,
    status = 'completed',
    completed_at = NOW()
  WHERE id = p_match_id;
  
END;
$$;


--
-- Name: pvp_create_round(uuid, integer, text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_create_round(p_match_id uuid, p_round_number integer, p_question_ids text[], p_theme_id text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_round_id UUID;
  BEGIN
    INSERT INTO pvp_rounds (
      match_id,
      round_number,
      question_ids,
      theme_id
    ) VALUES (
      p_match_id,
      p_round_number,
      p_question_ids,
      p_theme_id
    ) RETURNING id INTO v_round_id;

    RETURN v_round_id;
  END;
  $$;


--
-- Name: pvp_get_pending_invitations(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_get_pending_invitations(p_user_id uuid) RETURNS TABLE(invitation_id uuid, sender_id uuid, sender_name text, created_at timestamp with time zone, expires_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE pvp_invitations
  SET status = 'expired'
  WHERE pvp_invitations.recipient_id = p_user_id
    AND pvp_invitations.status = 'pending'
    AND pvp_invitations.expires_at <= NOW();

  RETURN QUERY
  SELECT pi.id, pi.sender_id, get_display_name(pi.sender_id), pi.created_at, pi.expires_at
  FROM pvp_invitations pi
  WHERE pi.recipient_id = p_user_id
    AND pi.status = 'pending'
    AND pi.expires_at > NOW()
  ORDER BY pi.created_at DESC;
END;
$$;


--
-- Name: pvp_get_questions_by_ids(uuid[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_get_questions_by_ids(p_question_ids uuid[], p_language_code text) RETURNS TABLE(question_id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      q.id AS question_id,
      q.theme_id,
      q.difficulty,
      qt.question_text,
      qt.explanation,
      qt.language_code,
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'answer_id', a.id,
            'answer_text', at2.answer_text,
            'is_correct', a.is_correct,
            'display_order', a.display_order
          ) ORDER BY a.display_order
        )
        FROM answers a
        JOIN answer_translations at2 ON at2.answer_id = a.id
          AND at2.language_code = p_language_code
        WHERE a.question_id = q.id
      ) AS answers
    FROM questions q
    JOIN question_translations qt ON qt.question_id = q.id
      AND qt.language_code = p_language_code
    WHERE q.id = ANY(p_question_ids);
  END;
  $$;


--
-- Name: pvp_get_random_questions(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_get_random_questions(p_language_code text, p_limit integer) RETURNS TABLE(question_id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    WITH random_questions AS (
      SELECT
        q.id,
        q.theme_id,
        q.difficulty,
        qt.question_text,
        qt.explanation,
        qt.language_code
      FROM questions q
      JOIN question_translations qt ON q.id = qt.question_id
      WHERE qt.language_code = p_language_code
      ORDER BY RANDOM()
      LIMIT p_limit
    )
    SELECT
      rq.id,
      rq.theme_id,
      rq.difficulty,
      rq.question_text,
      rq.explanation,
      rq.language_code,
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'answer_id', a.id,
            'answer_text', at2.answer_text,
            'is_correct', a.is_correct,
            'display_order', a.display_order
          ) ORDER BY a.display_order
        )
        FROM answers a
        JOIN answer_translations at2 ON a.id = at2.answer_id
          AND at2.language_code = p_language_code
        WHERE a.question_id = rq.id
      ) AS answers
    FROM random_questions rq;
  END;
  $$;


--
-- Name: pvp_get_random_questions_by_theme(text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_get_random_questions_by_theme(p_theme_id text, p_language_code text, p_limit integer, p_avg_rating integer DEFAULT 1000) RETURNS TABLE(question_id uuid, theme_id uuid, difficulty text, question_text text, explanation text, language_code text, answers jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_easy_pct INT;
    v_medium_pct INT;
    v_hard_pct INT;
    v_easy_count INT;
    v_medium_count INT;
    v_hard_count INT;
  BEGIN
    IF p_avg_rating < 1200 THEN
      v_easy_pct := 75; v_medium_pct := 20; v_hard_pct := 5;
    ELSIF p_avg_rating < 1500 THEN
      v_easy_pct := 65; v_medium_pct := 25; v_hard_pct := 10;
    ELSIF p_avg_rating < 2000 THEN
      v_easy_pct := 60; v_medium_pct := 28; v_hard_pct := 12;
    ELSIF p_avg_rating < 2500 THEN
      v_easy_pct := 50; v_medium_pct := 30; v_hard_pct := 20;
    ELSE
      v_easy_pct := 40; v_medium_pct := 35; v_hard_pct := 25;
    END IF;

    v_easy_count := GREATEST(1, (p_limit * v_easy_pct / 100));
    v_hard_count := GREATEST(1, (p_limit * v_hard_pct / 100));
    v_medium_count := p_limit - v_easy_count - v_hard_count;

    RETURN QUERY
    WITH combined AS (
      (
        SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
        FROM questions q
        JOIN question_translations qt ON q.id = qt.question_id
        WHERE qt.language_code = p_language_code AND q.theme_id = p_theme_id::UUID AND q.difficulty = 'easy'
        ORDER BY RANDOM() LIMIT v_easy_count
      )
      UNION ALL
      (
        SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
        FROM questions q
        JOIN question_translations qt ON q.id = qt.question_id
        WHERE qt.language_code = p_language_code AND q.theme_id = p_theme_id::UUID AND q.difficulty = 'medium'
        ORDER BY RANDOM() LIMIT v_medium_count
      )
      UNION ALL
      (
        SELECT q.id, q.theme_id, q.difficulty, qt.question_text, qt.explanation, qt.language_code
        FROM questions q
        JOIN question_translations qt ON q.id = qt.question_id
        WHERE qt.language_code = p_language_code AND q.theme_id = p_theme_id::UUID AND q.difficulty = 'hard'
        ORDER BY RANDOM() LIMIT v_hard_count
      )
    )
    SELECT
      c.id AS question_id,
      c.theme_id,
      c.difficulty,
      c.question_text,
      c.explanation,
      c.language_code,
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'answer_id', a.id,
            'answer_text', at2.answer_text,
            'is_correct', a.is_correct,
            'display_order', a.display_order
          ) ORDER BY a.display_order
        )
        FROM answers a
        JOIN answer_translations at2 ON a.id = at2.answer_id AND at2.language_code = p_language_code
        WHERE a.question_id = c.id
      ) AS answers
    FROM combined c
    ORDER BY RANDOM();
  END;
  $$;


--
-- Name: pvp_get_random_theme(text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_get_random_theme(p_language_code text, p_exclude_theme_ids text[]) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$                                                                                                                                                     
  DECLARE                                                                                                                                                                
    v_theme_id TEXT;
  BEGIN
    SELECT id::TEXT INTO v_theme_id
    FROM themes_localized
    WHERE language_code = p_language_code
      AND id::TEXT != ALL(p_exclude_theme_ids)
    ORDER BY RANDOM()
    LIMIT 1;

    RETURN v_theme_id;
  END;
  $$;


--
-- Name: pvp_join_queue(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_join_queue(p_user_id uuid, p_rating integer, p_language text) RETURNS TABLE(match_found boolean, match_id uuid, opponent_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    DECLARE
      v_opponent_record RECORD;
      v_new_match_id UUID;
      v_player1_rating INTEGER;
      v_player2_rating INTEGER;
    BEGIN
      PERFORM clean_old_matchmaking_queue();

      SELECT * INTO v_opponent_record
      FROM pvp_matchmaking_queue
      WHERE user_id != p_user_id
        AND ABS(rating - p_rating) <= 200
      ORDER BY created_at ASC
      LIMIT 1;

      IF FOUND THEN
        SELECT pvp_rating INTO v_player1_rating FROM user_stats WHERE user_id = p_user_id;
        SELECT pvp_rating INTO v_player2_rating FROM user_stats WHERE user_id = v_opponent_record.user_id;

        INSERT INTO pvp_matches (
          player1_id, player2_id, status, current_round,
          player1_rating_before, player2_rating_before, started_at
        ) VALUES (
          p_user_id, v_opponent_record.user_id,
          'player1_choosing_theme', 1,
          v_player1_rating, v_player2_rating, NOW()
        ) RETURNING id INTO v_new_match_id;

        DELETE FROM pvp_matchmaking_queue WHERE user_id IN (p_user_id, v_opponent_record.user_id);

        RETURN QUERY SELECT TRUE, v_new_match_id, v_opponent_record.user_id;
      ELSE
        INSERT INTO pvp_matchmaking_queue (user_id, rating, preferred_language)
        VALUES (p_user_id, p_rating, p_language)
        ON CONFLICT (user_id) DO NOTHING;

        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::UUID;
      END IF;
    END;
    $$;


--
-- Name: pvp_leave_queue(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_leave_queue(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM pvp_matchmaking_queue WHERE user_id = p_user_id;
END;
$$;


--
-- Name: pvp_respond_invitation(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_respond_invitation(p_invitation_id uuid, p_user_id uuid, p_accept boolean) RETURNS TABLE(match_id uuid, accepted boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$                             
  DECLARE v_sender_id UUID; v_match_id UUID;  
  BEGIN                                                                                                                                          
    SELECT sender_id INTO v_sender_id FROM pvp_invitations                                                                                       
    WHERE id = p_invitation_id AND recipient_id = p_user_id AND status = 'pending' AND expires_at > NOW();                                       
    IF NOT FOUND THEN RAISE EXCEPTION 'Invitation not found or expired'; END IF;                                                                 
    IF p_accept THEN                                                                                                                             
      INSERT INTO pvp_matches (player1_id, player2_id, status, player1_rating_before, player2_rating_before)                                     
      SELECT v_sender_id, p_user_id, 'player1_choosing_theme',                                                                                   
        COALESCE((SELECT pvp_rating FROM user_stats WHERE user_id = v_sender_id), 1000),                                                         
        COALESCE((SELECT pvp_rating FROM user_stats WHERE user_id = p_user_id), 1000)                                                            
      RETURNING id INTO v_match_id;                                                                                                              
      UPDATE pvp_invitations SET status = 'accepted', match_id = v_match_id WHERE id = p_invitation_id;                                          
      RETURN QUERY SELECT v_match_id, true;                                                                                                          ELSE                                                                                                                                         
      UPDATE pvp_invitations SET status = 'declined' WHERE id = p_invitation_id;                                                                 
      RETURN QUERY SELECT NULL::UUID, false;                                                                                                     
    END IF;                                                                                                                                      
  END; $$;


--
-- Name: pvp_send_invitation(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_send_invitation(p_sender_id uuid, p_recipient_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$                                                               
  DECLARE v_id UUID;                                                                                                                             
  BEGIN                                                                                                                                          
    UPDATE pvp_invitations SET status = 'expired'                                                                                                
    WHERE sender_id = p_sender_id AND recipient_id = p_recipient_id AND status = 'pending';                                                          INSERT INTO pvp_invitations (sender_id, recipient_id) VALUES (p_sender_id, p_recipient_id) RETURNING id INTO v_id;                           
    RETURN v_id;                                                                                                                                 
  END; $$;


--
-- Name: pvp_submit_round_answers(uuid, integer, uuid, jsonb, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_submit_round_answers(p_match_id uuid, p_round_number integer, p_user_id uuid, p_answers jsonb, p_score integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_match RECORD;
    v_is_player1 BOOLEAN;
    v_running_score INTEGER := 0;
    v_answer_elem JSONB;
    v_answer_id TEXT;
    v_is_correct BOOLEAN;
    v_difficulty TEXT;
    v_points INTEGER;
  BEGIN
    SELECT * INTO v_match FROM pvp_matches WHERE id = p_match_id;

    IF v_match.player1_id != p_user_id AND v_match.player2_id != p_user_id THEN
      RAISE EXCEPTION 'User is not a participant in this match';
    END IF;

    v_is_player1 := (v_match.player1_id = p_user_id);

    -- Calculer le score server-side (même logique que le client)
    FOR v_answer_elem IN SELECT jsonb_array_elements(p_answers)
    LOOP
      v_answer_id := v_answer_elem->>'answer_id';

      IF v_answer_id IS NULL OR v_answer_id = '' THEN
        v_points := 0;
      ELSE
        SELECT a.is_correct, q.difficulty
        INTO v_is_correct, v_difficulty
        FROM answers a
        JOIN questions q ON q.id = a.question_id
        WHERE a.id = v_answer_id::uuid;

        IF NOT FOUND THEN
          v_is_correct := FALSE;
          v_difficulty := 'easy';
        END IF;

        IF v_is_correct THEN
          v_points := CASE v_difficulty
            WHEN 'easy'   THEN 1
            WHEN 'medium' THEN 2
            WHEN 'hard'   THEN 3
            ELSE 1
          END;
        ELSE
          v_points := CASE WHEN v_running_score > 0 THEN -1 ELSE 0 END;
        END IF;
      END IF;

      v_running_score := GREATEST(0, v_running_score + v_points);
    END LOOP;

    IF v_is_player1 THEN
      UPDATE pvp_rounds
      SET player1_answers = p_answers,
          player1_score = v_running_score,
          player1_completed_at = NOW()
      WHERE match_id = p_match_id AND round_number = p_round_number;
    ELSE
      UPDATE pvp_rounds
      SET player2_answers = p_answers,
          player2_score = v_running_score,
          player2_completed_at = NOW()
      WHERE match_id = p_match_id AND round_number = p_round_number;
    END IF;
  END;
  $$;


--
-- Name: pvp_update_match_status(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pvp_update_match_status(p_match_id uuid, p_status text, p_current_round integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
    v_match RECORD;
    v_user_id uuid := auth.uid();
    v_allowed text[] := ARRAY[
      'player1_turn', 'player2_turn',
      'player1_choosing_theme', 'player2_choosing_theme',
      'cancelled'
    ];
  BEGIN
    IF NOT (p_status = ANY(v_allowed)) THEN
      RAISE EXCEPTION 'Invalid status: %', p_status;
    END IF;

    SELECT * INTO v_match FROM pvp_matches WHERE id = p_match_id;

    IF v_match.player1_id != v_user_id AND v_match.player2_id != v_user_id THEN
      RAISE EXCEPTION 'User is not a participant in this match';
    END IF;

    IF v_match.status IN ('completed', 'cancelled') THEN
      RAISE EXCEPTION 'Cannot update a finished match';
    END IF;

    IF p_current_round IS NOT NULL THEN
      UPDATE pvp_matches
      SET status = p_status, current_round = p_current_round
      WHERE id = p_match_id;
    ELSE
      UPDATE pvp_matches
      SET status = p_status
      WHERE id = p_match_id;
    END IF;
  END;
  $$;


--
-- Name: regenerate_lives(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.regenerate_lives(p_user_id uuid) RETURNS TABLE(current_lives integer, max_lives integer, next_life_in interval)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_current_lives INTEGER;
  v_max_lives INTEGER;
  v_last_regen TIMESTAMPTZ;
  v_regen_interval INTERVAL := INTERVAL '15 minutes';
  v_lives_to_add INTEGER;
  v_time_since_regen INTERVAL;
BEGIN
  -- Récupérer les données actuelles
  SELECT ul.current_lives, ul.max_lives, ul.last_regen_at
  INTO v_current_lives, v_max_lives, v_last_regen
  FROM user_lives ul
  WHERE ul.user_id = p_user_id;

  -- Si pas de données, initialiser avec 10 vies
  IF NOT FOUND THEN
    INSERT INTO user_lives (user_id, current_lives, max_lives)
    VALUES (p_user_id, 10, 10)
    RETURNING user_lives.current_lives, user_lives.max_lives, INTERVAL '0' INTO v_current_lives, v_max_lives, v_time_since_regen;
    
    RETURN QUERY SELECT v_current_lives, v_max_lives, INTERVAL '0';
    RETURN;
  END IF;

  -- Si déjà au max, pas besoin de régénérer
  IF v_current_lives >= v_max_lives THEN
    RETURN QUERY SELECT v_current_lives, v_max_lives, INTERVAL '0';
    RETURN;
  END IF;

  -- Calculer combien de vies régénérer
  v_time_since_regen := NOW() - v_last_regen;
  v_lives_to_add := FLOOR(EXTRACT(EPOCH FROM v_time_since_regen) / EXTRACT(EPOCH FROM v_regen_interval))::INTEGER;

  IF v_lives_to_add > 0 THEN
    -- Ajouter les vies (sans dépasser le max)
    v_current_lives := LEAST(v_current_lives + v_lives_to_add, v_max_lives);
    
    -- Mettre à jour
    UPDATE user_lives
    SET 
      current_lives = v_current_lives,
      last_regen_at = v_last_regen + (v_lives_to_add * v_regen_interval),
      updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;

  -- Calculer le temps avant la prochaine vie
  v_time_since_regen := NOW() - (v_last_regen + (v_lives_to_add * v_regen_interval));
  
  RETURN QUERY SELECT 
    v_current_lives, 
    v_max_lives,
    CASE 
      WHEN v_current_lives >= v_max_lives THEN INTERVAL '0'
      ELSE v_regen_interval - v_time_since_regen
    END;
END;
$$;


--
-- Name: search_users(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_users(p_query text) RETURNS TABLE(user_id uuid, username text, pvp_rating integer, total_questions integer, correct_answers integer, is_following boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  BEGIN
    RETURN QUERY
    SELECT
      us.user_id,
      us.username,
      us.pvp_rating,
      us.total_questions,
      us.correct_answers,
      EXISTS (
        SELECT 1 FROM public.user_follows uf
        WHERE uf.follower_id = auth.uid() AND uf.following_id = us.user_id
      ) AS is_following
    FROM public.user_stats us
    WHERE
      us.user_id != auth.uid()
      AND us.username ILIKE '%' || p_query || '%'
    ORDER BY
      CASE WHEN us.username ILIKE p_query THEN 0
           WHEN us.username ILIKE p_query || '%' THEN 1
           ELSE 2
      END,
      us.username ASC
    LIMIT 20;
  END;
  $$;


--
-- Name: unfollow_user(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.unfollow_user(p_following_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM public.user_follows
  WHERE follower_id = auth.uid() AND following_id = p_following_id;
END;
$$;


--
-- Name: update_pvp_matches_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_pvp_matches_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_user_language(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_language(user_lang text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO user_stats (user_id, preferred_language)
  VALUES (auth.uid(), user_lang)
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    preferred_language = user_lang,
    updated_at = NOW();
END;
$$;


--
-- Name: update_user_streak(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_streak(p_user_id uuid, p_timezone text DEFAULT 'Europe/Paris'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  DECLARE
      v_last_played timestamptz;
      v_current_streak int;
      v_best_streak int;
      v_today date := (NOW() AT TIME ZONE p_timezone)::date;
      v_last_date date;
  BEGIN
      SELECT last_played_at, current_streak, best_streak
      INTO v_last_played, v_current_streak, v_best_streak
      FROM user_stats
      WHERE user_id = p_user_id;

      IF v_last_played IS NULL THEN
          v_current_streak := 1;
      ELSE
          v_last_date := (v_last_played AT TIME ZONE p_timezone)::date;
          IF v_last_date = v_today THEN
              RETURN;
          ELSIF v_last_date = v_today - 1 THEN
              v_current_streak := v_current_streak + 1;
          ELSE
              v_current_streak := 1;
          END IF;
      END IF;

      IF v_current_streak > v_best_streak THEN
          v_best_streak := v_current_streak;
      END IF;

      UPDATE user_stats
      SET current_streak = v_current_streak,
          best_streak = v_best_streak,
          last_played_at = NOW()
      WHERE user_id = p_user_id;
  END;
  $$;


--
-- Name: use_life(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.use_life(p_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_current_lives INTEGER;
BEGIN
  -- Régénérer d'abord
  PERFORM regenerate_lives(p_user_id);
  
  -- Vérifier les vies disponibles
  SELECT current_lives INTO v_current_lives
  FROM user_lives
  WHERE user_id = p_user_id;

  IF v_current_lives <= 0 THEN
    RETURN FALSE; -- Pas de vie disponible
  END IF;

  -- Retirer une vie
  UPDATE user_lives
  SET 
    current_lives = current_lives - 1,
    updated_at = NOW()
  WHERE user_id = p_user_id;

  RETURN TRUE;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.achievements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    name_en text NOT NULL,
    name_fr text NOT NULL,
    description_en text NOT NULL,
    description_fr text NOT NULL,
    icon text NOT NULL,
    category text DEFAULT 'general'::text NOT NULL,
    condition_type text NOT NULL,
    condition_value integer DEFAULT 0 NOT NULL,
    xp_reward integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: ad_reward_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_reward_transactions (
    transaction_id text NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: answer_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.answer_translations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    answer_id uuid NOT NULL,
    language_code text NOT NULL,
    answer_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT answer_translations_language_code_check CHECK ((language_code = ANY (ARRAY['en'::text, 'fr'::text])))
);


--
-- Name: answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid NOT NULL,
    is_correct boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_theme_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_theme_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    theme_id uuid NOT NULL,
    xp integer DEFAULT 0,
    level integer DEFAULT 1,
    total_questions integer DEFAULT 0,
    correct_answers integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: leaderboard_by_theme; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leaderboard_by_theme WITH (security_invoker='true') AS
 SELECT theme_id,
    user_id,
    public.get_display_name(user_id) AS display_name,
    xp,
    level,
    total_questions,
    correct_answers,
        CASE
            WHEN (total_questions > 0) THEN round((((correct_answers)::numeric / (total_questions)::numeric) * (100)::numeric), 1)
            ELSE (0)::numeric
        END AS accuracy
   FROM public.user_theme_progress utp
  ORDER BY theme_id, xp DESC,
        CASE
            WHEN (total_questions > 0) THEN round((((correct_answers)::numeric / (total_questions)::numeric) * (100)::numeric), 1)
            ELSE (0)::numeric
        END DESC;


--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_achievements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    achievement_id uuid NOT NULL,
    unlocked_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_stats (
    user_id uuid NOT NULL,
    total_questions integer DEFAULT 0,
    correct_answers integer DEFAULT 0,
    current_streak integer DEFAULT 0,
    best_streak integer DEFAULT 0,
    preferred_language text DEFAULT 'en'::text,
    last_played_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now(),
    has_completed_onboarding boolean DEFAULT false,
    pvp_rating integer DEFAULT 1000,
    pvp_wins integer DEFAULT 0,
    pvp_losses integer DEFAULT 0,
    pvp_draws integer DEFAULT 0,
    username text,
    last_daily_completed_at date,
    timezone_offset_hours integer DEFAULT 0,
    last_answer_at timestamp with time zone,
    daily_streak integer DEFAULT 0,
    CONSTRAINT user_stats_preferred_language_check CHECK ((preferred_language = ANY (ARRAY['en'::text, 'fr'::text]))),
    CONSTRAINT username_format_check CHECK (((username IS NULL) OR ((length(username) >= 3) AND (length(username) <= 20) AND (username ~ '^[a-z0-9_]+$'::text))))
);


--
-- Name: leaderboard_global; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leaderboard_global AS
 SELECT us.user_id,
    public.get_display_name(us.user_id) AS display_name,
    (COALESCE(sum(utp.xp), (0)::bigint) + COALESCE(( SELECT sum(a.xp_reward) AS sum
           FROM (public.user_achievements ua
             JOIN public.achievements a ON ((a.id = ua.achievement_id)))
          WHERE (ua.user_id = us.user_id)), (0)::bigint)) AS total_xp,
    COALESCE(sum(utp.level), (0)::bigint) AS total_levels,
    us.total_questions,
    us.correct_answers,
        CASE
            WHEN (us.total_questions > 0) THEN round((((us.correct_answers)::numeric / (us.total_questions)::numeric) * (100)::numeric), 1)
            ELSE (0)::numeric
        END AS accuracy,
    us.current_streak
   FROM (public.user_stats us
     LEFT JOIN public.user_theme_progress utp ON ((us.user_id = utp.user_id)))
  GROUP BY us.user_id, us.total_questions, us.correct_answers, us.current_streak
  ORDER BY (COALESCE(sum(utp.xp), (0)::bigint) + COALESCE(( SELECT sum(a.xp_reward) AS sum
           FROM (public.user_achievements ua
             JOIN public.achievements a ON ((a.id = ua.achievement_id)))
          WHERE (ua.user_id = us.user_id)), (0)::bigint)) DESC,
        CASE
            WHEN (us.total_questions > 0) THEN round((((us.correct_answers)::numeric / (us.total_questions)::numeric) * (100)::numeric), 1)
            ELSE (0)::numeric
        END DESC;


--
-- Name: pvp_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pvp_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sender_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    match_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone DEFAULT (now() + '00:05:00'::interval),
    CONSTRAINT no_self_invite CHECK ((sender_id <> recipient_id)),
    CONSTRAINT pvp_invitations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'expired'::text])))
);


--
-- Name: pvp_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pvp_matches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    player1_id uuid NOT NULL,
    player2_id uuid NOT NULL,
    status text NOT NULL,
    current_round integer DEFAULT 1 NOT NULL,
    player1_total_score integer DEFAULT 0,
    player2_total_score integer DEFAULT 0,
    winner_id uuid,
    player1_rating_before integer NOT NULL,
    player2_rating_before integer NOT NULL,
    player1_rating_change integer DEFAULT 0,
    player2_rating_change integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pvp_matches_status_check CHECK ((status = ANY (ARRAY['waiting'::text, 'player1_turn'::text, 'player2_turn'::text, 'player1_choosing_theme'::text, 'player2_choosing_theme'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: pvp_matchmaking_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pvp_matchmaking_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    rating integer NOT NULL,
    preferred_language text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    last_seen timestamp with time zone DEFAULT now()
);


--
-- Name: pvp_rounds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pvp_rounds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    round_number integer NOT NULL,
    question_ids text[] NOT NULL,
    player1_score integer DEFAULT 0,
    player2_score integer DEFAULT 0,
    player1_answers jsonb DEFAULT '[]'::jsonb,
    player1_completed_at timestamp with time zone,
    player2_answers jsonb DEFAULT '[]'::jsonb,
    player2_completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    theme_id text,
    CONSTRAINT pvp_rounds_round_number_check CHECK (((round_number >= 1) AND (round_number <= 3)))
);


--
-- Name: question_concepts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_concepts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    concept text NOT NULL,
    theme_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    concept_en text,
    concept_fr text
);


--
-- Name: question_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_translations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid NOT NULL,
    language_code text NOT NULL,
    question_text text NOT NULL,
    explanation text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT question_translations_language_code_check CHECK ((language_code = ANY (ARRAY['en'::text, 'fr'::text])))
);


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    theme_id uuid NOT NULL,
    difficulty text,
    times_used integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    is_verified boolean DEFAULT false,
    verified_at timestamp with time zone,
    concept_id uuid,
    CONSTRAINT questions_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text])))
);


--
-- Name: questions_complete; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.questions_complete WITH (security_invoker='true') AS
 SELECT q.id,
    q.theme_id,
    q.difficulty,
    q.times_used,
    COALESCE(qt.question_text, ''::text) AS question_text,
    COALESCE(qt.explanation, ''::text) AS explanation,
    COALESCE(qt.language_code, 'en'::text) AS language_code,
    q.created_at,
    ( SELECT json_agg(json_build_object('id', a.id, 'answer_text', COALESCE(at.answer_text, ''::text), 'is_correct', a.is_correct, 'language_code', COALESCE(at.language_code, 'en'::text))) AS json_agg
           FROM (public.answers a
             LEFT JOIN public.answer_translations at ON (((a.id = at.answer_id) AND (at.language_code = COALESCE(qt.language_code, 'en'::text)))))
          WHERE (a.question_id = q.id)) AS answers
   FROM (public.questions q
     LEFT JOIN public.question_translations qt ON ((q.id = qt.question_id)));


--
-- Name: survival_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survival_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    theme_id uuid NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    played_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: theme_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.theme_translations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    theme_id uuid NOT NULL,
    language_code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT theme_translations_language_code_check CHECK ((language_code = ANY (ARRAY['en'::text, 'fr'::text])))
);


--
-- Name: themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.themes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    icon text NOT NULL,
    color text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: themes_localized; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.themes_localized WITH (security_invoker='true') AS
 SELECT t.id,
    t.icon,
    t.color,
    COALESCE(tt.name, ('Theme '::text || (t.id)::text)) AS name,
    COALESCE(tt.description, ''::text) AS description,
    COALESCE(tt.language_code, 'en'::text) AS language_code,
    t.created_at
   FROM (public.themes t
     LEFT JOIN public.theme_translations tt ON ((t.id = tt.theme_id)));


--
-- Name: user_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    question_id uuid NOT NULL,
    selected_answer_id uuid NOT NULL,
    is_correct boolean NOT NULL,
    language_used text NOT NULL,
    answered_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_answers_language_used_check CHECK ((language_used = ANY (ARRAY['en'::text, 'fr'::text])))
);


--
-- Name: user_fcm_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_fcm_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    platform text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_fcm_tokens_platform_check CHECK ((platform = ANY (ARRAY['ios'::text, 'android'::text])))
);


--
-- Name: user_follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_follows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    follower_id uuid NOT NULL,
    following_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT no_self_follow CHECK ((follower_id <> following_id))
);


--
-- Name: user_lives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_lives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    current_lives integer DEFAULT 10 NOT NULL,
    max_lives integer DEFAULT 10 NOT NULL,
    last_regen_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_ad_lives_at timestamp with time zone
);


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    user_id uuid NOT NULL,
    display_name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_theme_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_theme_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    theme_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: achievements achievements_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_key_key UNIQUE (key);


--
-- Name: achievements achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_pkey PRIMARY KEY (id);


--
-- Name: ad_reward_transactions ad_reward_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_reward_transactions
    ADD CONSTRAINT ad_reward_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: answer_translations answer_translations_answer_id_language_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_translations
    ADD CONSTRAINT answer_translations_answer_id_language_code_key UNIQUE (answer_id, language_code);


--
-- Name: answer_translations answer_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_translations
    ADD CONSTRAINT answer_translations_pkey PRIMARY KEY (id);


--
-- Name: answers answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_pkey PRIMARY KEY (id);


--
-- Name: pvp_invitations pvp_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_invitations
    ADD CONSTRAINT pvp_invitations_pkey PRIMARY KEY (id);


--
-- Name: pvp_matches pvp_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matches
    ADD CONSTRAINT pvp_matches_pkey PRIMARY KEY (id);


--
-- Name: pvp_matchmaking_queue pvp_matchmaking_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matchmaking_queue
    ADD CONSTRAINT pvp_matchmaking_queue_pkey PRIMARY KEY (id);


--
-- Name: pvp_matchmaking_queue pvp_matchmaking_queue_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matchmaking_queue
    ADD CONSTRAINT pvp_matchmaking_queue_user_id_key UNIQUE (user_id);


--
-- Name: pvp_rounds pvp_rounds_match_id_round_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_rounds
    ADD CONSTRAINT pvp_rounds_match_id_round_number_key UNIQUE (match_id, round_number);


--
-- Name: pvp_rounds pvp_rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_rounds
    ADD CONSTRAINT pvp_rounds_pkey PRIMARY KEY (id);


--
-- Name: question_concepts question_concepts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_concepts
    ADD CONSTRAINT question_concepts_pkey PRIMARY KEY (id);


--
-- Name: question_translations question_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_translations
    ADD CONSTRAINT question_translations_pkey PRIMARY KEY (id);


--
-- Name: question_translations question_translations_question_id_language_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_translations
    ADD CONSTRAINT question_translations_question_id_language_code_key UNIQUE (question_id, language_code);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: survival_scores survival_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survival_scores
    ADD CONSTRAINT survival_scores_pkey PRIMARY KEY (id);


--
-- Name: theme_translations theme_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_translations
    ADD CONSTRAINT theme_translations_pkey PRIMARY KEY (id);


--
-- Name: theme_translations theme_translations_theme_id_language_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_translations
    ADD CONSTRAINT theme_translations_theme_id_language_code_key UNIQUE (theme_id, language_code);


--
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_user_id_achievement_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_achievement_id_key UNIQUE (user_id, achievement_id);


--
-- Name: user_answers user_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_pkey PRIMARY KEY (id);


--
-- Name: user_fcm_tokens user_fcm_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_fcm_tokens user_fcm_tokens_user_id_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_user_id_token_key UNIQUE (user_id, token);


--
-- Name: user_follows user_follows_follower_id_following_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_follower_id_following_id_key UNIQUE (follower_id, following_id);


--
-- Name: user_follows user_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_pkey PRIMARY KEY (id);


--
-- Name: user_lives user_lives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lives
    ADD CONSTRAINT user_lives_pkey PRIMARY KEY (id);


--
-- Name: user_lives user_lives_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lives
    ADD CONSTRAINT user_lives_user_id_key UNIQUE (user_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: user_stats user_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stats
    ADD CONSTRAINT user_stats_pkey PRIMARY KEY (user_id);


--
-- Name: user_stats user_stats_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stats
    ADD CONSTRAINT user_stats_username_key UNIQUE (username);


--
-- Name: user_theme_preferences user_theme_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_preferences
    ADD CONSTRAINT user_theme_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_theme_preferences user_theme_preferences_user_id_theme_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_preferences
    ADD CONSTRAINT user_theme_preferences_user_id_theme_id_key UNIQUE (user_id, theme_id);


--
-- Name: user_theme_progress user_theme_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_progress
    ADD CONSTRAINT user_theme_progress_pkey PRIMARY KEY (id);


--
-- Name: user_theme_progress user_theme_progress_user_id_theme_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_progress
    ADD CONSTRAINT user_theme_progress_user_id_theme_id_key UNIQUE (user_id, theme_id);


--
-- Name: idx_answer_translations_answer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answer_translations_answer ON public.answer_translations USING btree (answer_id);


--
-- Name: idx_answer_translations_lang; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answer_translations_lang ON public.answer_translations USING btree (language_code);


--
-- Name: idx_answers_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_answers_question ON public.answers USING btree (question_id);


--
-- Name: idx_concepts_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_concepts_text ON public.question_concepts USING btree (concept);


--
-- Name: idx_concepts_theme; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_concepts_theme ON public.question_concepts USING btree (theme_id);


--
-- Name: idx_pvp_invitations_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_invitations_recipient ON public.pvp_invitations USING btree (recipient_id, status);


--
-- Name: idx_pvp_invitations_sender; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_invitations_sender ON public.pvp_invitations USING btree (sender_id, status);


--
-- Name: idx_pvp_matches_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_matches_created_at ON public.pvp_matches USING btree (created_at DESC);


--
-- Name: idx_pvp_matches_player1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_matches_player1 ON public.pvp_matches USING btree (player1_id);


--
-- Name: idx_pvp_matches_player2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_matches_player2 ON public.pvp_matches USING btree (player2_id);


--
-- Name: idx_pvp_matches_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_matches_status ON public.pvp_matches USING btree (status);


--
-- Name: idx_pvp_queue_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_queue_created_at ON public.pvp_matchmaking_queue USING btree (created_at);


--
-- Name: idx_pvp_queue_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_queue_rating ON public.pvp_matchmaking_queue USING btree (rating);


--
-- Name: idx_pvp_rounds_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pvp_rounds_match_id ON public.pvp_rounds USING btree (match_id);


--
-- Name: idx_question_translations_lang; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_question_translations_lang ON public.question_translations USING btree (language_code);


--
-- Name: idx_question_translations_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_question_translations_question ON public.question_translations USING btree (question_id);


--
-- Name: idx_questions_concept_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_concept_id ON public.questions USING btree (concept_id);


--
-- Name: idx_questions_is_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_is_verified ON public.questions USING btree (is_verified);


--
-- Name: idx_questions_theme; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questions_theme ON public.questions USING btree (theme_id);


--
-- Name: idx_theme_translations_lang; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theme_translations_lang ON public.theme_translations USING btree (language_code);


--
-- Name: idx_theme_translations_theme; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theme_translations_theme ON public.theme_translations USING btree (theme_id);


--
-- Name: idx_unique_question_text; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unique_question_text ON public.question_translations USING btree (question_text, language_code);


--
-- Name: idx_user_answers_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_answers_question ON public.user_answers USING btree (question_id);


--
-- Name: idx_user_answers_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_answers_user ON public.user_answers USING btree (user_id);


--
-- Name: idx_user_fcm_tokens_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_fcm_tokens_user ON public.user_fcm_tokens USING btree (user_id);


--
-- Name: idx_user_follows_follower; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_follows_follower ON public.user_follows USING btree (follower_id);


--
-- Name: idx_user_follows_following; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_follows_following ON public.user_follows USING btree (following_id);


--
-- Name: idx_user_lives_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_lives_user ON public.user_lives USING btree (user_id);


--
-- Name: idx_user_stats_pvp_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_pvp_rating ON public.user_stats USING btree (pvp_rating);


--
-- Name: idx_user_stats_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_username ON public.user_stats USING btree (username);


--
-- Name: idx_user_theme_preferences_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_theme_preferences_user ON public.user_theme_preferences USING btree (user_id);


--
-- Name: idx_user_theme_progress_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_theme_progress_user ON public.user_theme_progress USING btree (user_id);


--
-- Name: survival_scores_theme_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survival_scores_theme_score_idx ON public.survival_scores USING btree (theme_id, score DESC);


--
-- Name: survival_scores_user_theme_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survival_scores_user_theme_idx ON public.survival_scores USING btree (user_id, theme_id);


--
-- Name: pvp_matches trigger_update_pvp_matches_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_pvp_matches_updated_at BEFORE UPDATE ON public.pvp_matches FOR EACH ROW EXECUTE FUNCTION public.update_pvp_matches_updated_at();


--
-- Name: answer_translations answer_translations_answer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_translations
    ADD CONSTRAINT answer_translations_answer_id_fkey FOREIGN KEY (answer_id) REFERENCES public.answers(id) ON DELETE CASCADE;


--
-- Name: answers answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- Name: pvp_invitations pvp_invitations_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_invitations
    ADD CONSTRAINT pvp_invitations_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.pvp_matches(id) ON DELETE SET NULL;


--
-- Name: pvp_invitations pvp_invitations_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_invitations
    ADD CONSTRAINT pvp_invitations_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pvp_invitations pvp_invitations_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_invitations
    ADD CONSTRAINT pvp_invitations_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pvp_matches pvp_matches_player1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matches
    ADD CONSTRAINT pvp_matches_player1_id_fkey FOREIGN KEY (player1_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pvp_matches pvp_matches_player2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matches
    ADD CONSTRAINT pvp_matches_player2_id_fkey FOREIGN KEY (player2_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pvp_matches pvp_matches_winner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matches
    ADD CONSTRAINT pvp_matches_winner_id_fkey FOREIGN KEY (winner_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: pvp_matchmaking_queue pvp_matchmaking_queue_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_matchmaking_queue
    ADD CONSTRAINT pvp_matchmaking_queue_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pvp_rounds pvp_rounds_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pvp_rounds
    ADD CONSTRAINT pvp_rounds_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.pvp_matches(id) ON DELETE CASCADE;


--
-- Name: question_concepts question_concepts_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_concepts
    ADD CONSTRAINT question_concepts_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id);


--
-- Name: question_translations question_translations_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_translations
    ADD CONSTRAINT question_translations_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- Name: questions questions_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_concept_id_fkey FOREIGN KEY (concept_id) REFERENCES public.question_concepts(id) ON DELETE CASCADE;


--
-- Name: questions questions_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: survival_scores survival_scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survival_scores
    ADD CONSTRAINT survival_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: theme_translations theme_translations_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theme_translations
    ADD CONSTRAINT theme_translations_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: user_achievements user_achievements_achievement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievements(id) ON DELETE CASCADE;


--
-- Name: user_achievements user_achievements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_answers user_answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: user_answers user_answers_selected_answer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_selected_answer_id_fkey FOREIGN KEY (selected_answer_id) REFERENCES public.answers(id);


--
-- Name: user_answers user_answers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_fcm_tokens user_fcm_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_follows user_follows_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_follows user_follows_following_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_lives user_lives_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lives
    ADD CONSTRAINT user_lives_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_stats user_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stats
    ADD CONSTRAINT user_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_theme_preferences user_theme_preferences_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_preferences
    ADD CONSTRAINT user_theme_preferences_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: user_theme_preferences user_theme_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_preferences
    ADD CONSTRAINT user_theme_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_theme_progress user_theme_progress_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_progress
    ADD CONSTRAINT user_theme_progress_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: user_theme_progress user_theme_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_theme_progress
    ADD CONSTRAINT user_theme_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_follows Anyone authenticated can view follows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone authenticated can view follows" ON public.user_follows FOR SELECT TO authenticated USING (true);


--
-- Name: answer_translations Anyone can read answer translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read answer translations" ON public.answer_translations FOR SELECT USING (true);


--
-- Name: answers Anyone can read answers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read answers" ON public.answers FOR SELECT USING (true);


--
-- Name: question_concepts Anyone can read question concepts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read question concepts" ON public.question_concepts FOR SELECT USING (true);


--
-- Name: question_translations Anyone can read question translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read question translations" ON public.question_translations FOR SELECT USING (true);


--
-- Name: questions Anyone can read questions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read questions" ON public.questions FOR SELECT USING (true);


--
-- Name: theme_translations Anyone can read theme translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read theme translations" ON public.theme_translations FOR SELECT USING (true);


--
-- Name: themes Anyone can read themes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read themes" ON public.themes FOR SELECT USING (true);


--
-- Name: user_profiles Public profiles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public profiles are viewable by everyone" ON public.user_profiles FOR SELECT USING (true);


--
-- Name: survival_scores Scores are public; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Scores are public" ON public.survival_scores FOR SELECT USING (true);


--
-- Name: pvp_matchmaking_queue Users can delete own queue entry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own queue entry" ON public.pvp_matchmaking_queue FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: user_follows Users can follow others; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can follow others" ON public.user_follows FOR INSERT TO authenticated WITH CHECK ((follower_id = auth.uid()));


--
-- Name: pvp_matches Users can insert matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert matches" ON public.pvp_matches FOR INSERT WITH CHECK (((auth.uid() = player1_id) OR (auth.uid() = player2_id)));


--
-- Name: user_answers Users can insert own answers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own answers" ON public.user_answers FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_lives Users can insert own lives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own lives" ON public.user_lives FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_profiles Users can insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_theme_progress Users can insert own progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own progress" ON public.user_theme_progress FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: pvp_matchmaking_queue Users can insert own queue entry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own queue entry" ON public.pvp_matchmaking_queue FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: survival_scores Users can insert own scores; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own scores" ON public.survival_scores FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_stats Users can insert own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own stats" ON public.user_stats FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: pvp_rounds Users can insert rounds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert rounds" ON public.pvp_rounds FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.pvp_matches
  WHERE ((pvp_matches.id = pvp_rounds.match_id) AND ((pvp_matches.player1_id = auth.uid()) OR (pvp_matches.player2_id = auth.uid()))))));


--
-- Name: user_answers Users can insert their own answers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own answers" ON public.user_answers FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_stats Users can insert their own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own stats" ON public.user_stats FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_lives Users can manage own lives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own lives" ON public.user_lives USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_theme_preferences Users can manage own preferences; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own preferences" ON public.user_theme_preferences USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_theme_preferences Users can manage own theme preferences; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own theme preferences" ON public.user_theme_preferences TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: pvp_matchmaking_queue Users can manage their own queue entry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own queue entry" ON public.pvp_matchmaking_queue USING ((auth.uid() = user_id));


--
-- Name: user_fcm_tokens Users can manage their own tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own tokens" ON public.user_fcm_tokens USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_theme_progress Users can read all progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read all progress" ON public.user_theme_progress FOR SELECT USING (true);


--
-- Name: user_stats Users can read all stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read all stats" ON public.user_stats FOR SELECT USING (true);


--
-- Name: user_stats Users can read all usernames; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read all usernames" ON public.user_stats FOR SELECT USING (true);


--
-- Name: user_answers Users can read own answers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own answers" ON public.user_answers FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: pvp_matches Users can read own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own matches" ON public.pvp_matches FOR SELECT USING (((auth.uid() = player1_id) OR (auth.uid() = player2_id)));


--
-- Name: pvp_matchmaking_queue Users can read own queue entry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own queue entry" ON public.pvp_matchmaking_queue FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_theme_progress Users can read own theme progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own theme progress" ON public.user_theme_progress FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: pvp_rounds Users can read rounds of own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read rounds of own matches" ON public.pvp_rounds FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.pvp_matches
  WHERE ((pvp_matches.id = pvp_rounds.match_id) AND ((pvp_matches.player1_id = auth.uid()) OR (pvp_matches.player2_id = auth.uid()))))));


--
-- Name: user_answers Users can read their own answers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read their own answers" ON public.user_answers FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: pvp_invitations Users can read their own invitations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read their own invitations" ON public.pvp_invitations FOR SELECT USING (((auth.uid() = sender_id) OR (auth.uid() = recipient_id)));


--
-- Name: user_stats Users can read their own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read their own stats" ON public.user_stats FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: user_follows Users can unfollow; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can unfollow" ON public.user_follows FOR DELETE TO authenticated USING ((follower_id = auth.uid()));


--
-- Name: user_lives Users can update own lives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own lives" ON public.user_lives FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: pvp_matches Users can update own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own matches" ON public.pvp_matches FOR UPDATE USING (((auth.uid() = player1_id) OR (auth.uid() = player2_id)));


--
-- Name: user_profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_theme_progress Users can update own progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own progress" ON public.user_theme_progress FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_stats Users can update own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own stats" ON public.user_stats FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: pvp_rounds Users can update rounds of own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update rounds of own matches" ON public.pvp_rounds FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.pvp_matches
  WHERE ((pvp_matches.id = pvp_rounds.match_id) AND ((pvp_matches.player1_id = auth.uid()) OR (pvp_matches.player2_id = auth.uid()))))));


--
-- Name: pvp_rounds Users can update rounds of their matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update rounds of their matches" ON public.pvp_rounds FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.pvp_matches
  WHERE ((pvp_matches.id = pvp_rounds.match_id) AND ((pvp_matches.player1_id = auth.uid()) OR (pvp_matches.player2_id = auth.uid()))))));


--
-- Name: pvp_matches Users can update their own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own matches" ON public.pvp_matches FOR UPDATE USING (((auth.uid() = player1_id) OR (auth.uid() = player2_id)));


--
-- Name: user_stats Users can update their own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own stats" ON public.user_stats FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_stats Users can update their own username; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own username" ON public.user_stats FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_theme_progress Users can upsert own theme progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upsert own theme progress" ON public.user_theme_progress TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_stats Users can upsert their own stats; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upsert their own stats" ON public.user_stats TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_lives Users can view own lives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own lives" ON public.user_lives FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: pvp_rounds Users can view rounds of their matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view rounds of their matches" ON public.pvp_rounds FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.pvp_matches
  WHERE ((pvp_matches.id = pvp_rounds.match_id) AND ((pvp_matches.player1_id = auth.uid()) OR (pvp_matches.player2_id = auth.uid()))))));


--
-- Name: pvp_matches Users can view their own matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own matches" ON public.pvp_matches FOR SELECT USING (((auth.uid() = player1_id) OR (auth.uid() = player2_id)));


--
-- Name: achievements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

--
-- Name: achievements achievements_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY achievements_read_all ON public.achievements FOR SELECT USING (true);


--
-- Name: ad_reward_transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ad_reward_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: answer_translations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.answer_translations ENABLE ROW LEVEL SECURITY;

--
-- Name: answers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

--
-- Name: ad_reward_transactions no_direct_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY no_direct_access ON public.ad_reward_transactions USING (false);


--
-- Name: pvp_invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pvp_invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: pvp_matches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pvp_matches ENABLE ROW LEVEL SECURITY;

--
-- Name: pvp_matchmaking_queue; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pvp_matchmaking_queue ENABLE ROW LEVEL SECURITY;

--
-- Name: pvp_rounds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pvp_rounds ENABLE ROW LEVEL SECURITY;

--
-- Name: question_concepts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.question_concepts ENABLE ROW LEVEL SECURITY;

--
-- Name: question_translations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.question_translations ENABLE ROW LEVEL SECURITY;

--
-- Name: questions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

--
-- Name: survival_scores; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.survival_scores ENABLE ROW LEVEL SECURITY;

--
-- Name: theme_translations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.theme_translations ENABLE ROW LEVEL SECURITY;

--
-- Name: themes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements user_achievements_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_achievements_insert ON public.user_achievements FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_achievements user_achievements_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_achievements_select ON public.user_achievements FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_answers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_answers ENABLE ROW LEVEL SECURITY;

--
-- Name: user_fcm_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: user_follows; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

--
-- Name: user_lives; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_lives ENABLE ROW LEVEL SECURITY;

--
-- Name: user_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: user_stats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

--
-- Name: user_theme_preferences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_theme_preferences ENABLE ROW LEVEL SECURITY;

--
-- Name: user_theme_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_theme_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements users_read_own_achievements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_read_own_achievements ON public.user_achievements FOR SELECT USING ((auth.uid() = user_id));


--
-- PostgreSQL database dump complete
--

\unrestrict tt2f7jj1MsSDtjXJYG0lQ02YplHstRRCUJ23aAE28RQ8sbjuxf6hhJ5kYpiPaqI


