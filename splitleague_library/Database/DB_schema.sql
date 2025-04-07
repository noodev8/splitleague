--
-- PostgreSQL database dump
--

-- Dumped from database version 11.18 (Debian 11.18-0+deb10u1)
-- Dumped by pg_dump version 17.1

-- Started on 2025-04-06 23:33:20

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
-- TOC entry 7 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

SET default_tablespace = '';

--
-- TOC entry 197 (class 1259 OID 21774)
-- Name: app_user; Type: TABLE; Schema: public; Owner: splitleague_user
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    nickname character varying(100) NOT NULL,
    email character varying(150),
    password_hash character varying(255) NOT NULL,
    profile_pic character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.app_user OWNER TO splitleague_user;

--
-- TOC entry 196 (class 1259 OID 21772)
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_user
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_user_id_seq OWNER TO splitleague_user;

--
-- TOC entry 2947 (class 0 OID 0)
-- Dependencies: 196
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 203 (class 1259 OID 21811)
-- Name: fixture; Type: TABLE; Schema: public; Owner: splitleague_user
--

CREATE TABLE public.fixture (
    id integer NOT NULL,
    league_id integer,
    player_1_id integer,
    player_2_id integer,
    scheduled_date date,
    played boolean DEFAULT false,
    player_1_score integer,
    player_2_score integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fixture OWNER TO splitleague_user;

--
-- TOC entry 202 (class 1259 OID 21809)
-- Name: fixture_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_user
--

CREATE SEQUENCE public.fixture_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fixture_id_seq OWNER TO splitleague_user;

--
-- TOC entry 2948 (class 0 OID 0)
-- Dependencies: 202
-- Name: fixture_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_user
--

ALTER SEQUENCE public.fixture_id_seq OWNED BY public.fixture.id;


--
-- TOC entry 199 (class 1259 OID 21788)
-- Name: league; Type: TABLE; Schema: public; Owner: splitleague_user
--

CREATE TABLE public.league (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_by integer,
    points_for_win integer DEFAULT 3,
    points_for_draw integer DEFAULT 1,
    points_for_win_margin integer DEFAULT 1,
    points_for_close_loss integer DEFAULT 1,
    win_margin_threshold integer DEFAULT 15,
    start_date date,
    end_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    public_code character varying(10),
    active boolean
);


ALTER TABLE public.league OWNER TO splitleague_user;

--
-- TOC entry 198 (class 1259 OID 21786)
-- Name: league_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_user
--

CREATE SEQUENCE public.league_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.league_id_seq OWNER TO splitleague_user;

--
-- TOC entry 2949 (class 0 OID 0)
-- Dependencies: 198
-- Name: league_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_user
--

ALTER SEQUENCE public.league_id_seq OWNED BY public.league.id;


--
-- TOC entry 201 (class 1259 OID 21802)
-- Name: league_members; Type: TABLE; Schema: public; Owner: splitleague_user
--

CREATE TABLE public.league_members (
    id integer NOT NULL,
    league_id integer,
    user_id integer,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.league_members OWNER TO splitleague_user;

--
-- TOC entry 200 (class 1259 OID 21800)
-- Name: league_members_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_user
--

CREATE SEQUENCE public.league_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.league_members_id_seq OWNER TO splitleague_user;

--
-- TOC entry 2950 (class 0 OID 0)
-- Dependencies: 200
-- Name: league_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_user
--

ALTER SEQUENCE public.league_members_id_seq OWNED BY public.league_members.id;


--
-- TOC entry 2796 (class 2604 OID 21777)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 2807 (class 2604 OID 21814)
-- Name: fixture id; Type: DEFAULT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.fixture ALTER COLUMN id SET DEFAULT nextval('public.fixture_id_seq'::regclass);


--
-- TOC entry 2798 (class 2604 OID 21791)
-- Name: league id; Type: DEFAULT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.league ALTER COLUMN id SET DEFAULT nextval('public.league_id_seq'::regclass);


--
-- TOC entry 2805 (class 2604 OID 21805)
-- Name: league_members id; Type: DEFAULT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.league_members ALTER COLUMN id SET DEFAULT nextval('public.league_members_id_seq'::regclass);


--
-- TOC entry 2811 (class 2606 OID 21785)
-- Name: app_user app_user_email_key; Type: CONSTRAINT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_email_key UNIQUE (email);


--
-- TOC entry 2813 (class 2606 OID 21783)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 2819 (class 2606 OID 21818)
-- Name: fixture fixture_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.fixture
    ADD CONSTRAINT fixture_pkey PRIMARY KEY (id);


--
-- TOC entry 2817 (class 2606 OID 21808)
-- Name: league_members league_members_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.league_members
    ADD CONSTRAINT league_members_pkey PRIMARY KEY (id);


--
-- TOC entry 2815 (class 2606 OID 21799)
-- Name: league league_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_user
--

ALTER TABLE ONLY public.league
    ADD CONSTRAINT league_pkey PRIMARY KEY (id);


--
-- TOC entry 2946 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO splitleague_user;


-- Completed on 2025-04-06 23:33:21

--
-- PostgreSQL database dump complete
--

