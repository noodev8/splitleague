--
-- PostgreSQL database dump
--

-- Dumped from database version 11.18 (Debian 11.18-0+deb10u1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-05-20 08:29:54

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
-- TOC entry 196 (class 1259 OID 22343)
-- Name: app_user; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    nickname character varying(100) NOT NULL,
    email character varying(150),
    password_hash character varying(255) NOT NULL,
    profile_pic character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    email_verified boolean DEFAULT false,
    verification_token character varying(64),
    verification_expires timestamp without time zone,
    accessed timestamp with time zone
);


ALTER TABLE public.app_user OWNER TO splitleague_prod_user;

--
-- TOC entry 197 (class 1259 OID 22351)
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_user_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2973 (class 0 OID 0)
-- Dependencies: 197
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 198 (class 1259 OID 22353)
-- Name: app_version_requirement; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.app_version_requirement (
    id integer NOT NULL,
    platform text NOT NULL,
    minimum_version numeric(4,2) NOT NULL
);


ALTER TABLE public.app_version_requirement OWNER TO splitleague_prod_user;

--
-- TOC entry 199 (class 1259 OID 22359)
-- Name: app_version_requirement_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.app_version_requirement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_version_requirement_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2974 (class 0 OID 0)
-- Dependencies: 199
-- Name: app_version_requirement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.app_version_requirement_id_seq OWNED BY public.app_version_requirement.id;


--
-- TOC entry 209 (class 1259 OID 22453)
-- Name: deletion_log; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.deletion_log (
    id integer NOT NULL,
    user_id integer,
    email character varying(255),
    deletion_method character varying(50) NOT NULL,
    requested_by integer,
    reason text,
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.deletion_log OWNER TO splitleague_prod_user;

--
-- TOC entry 208 (class 1259 OID 22451)
-- Name: deletion_log_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.deletion_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deletion_log_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2975 (class 0 OID 0)
-- Dependencies: 208
-- Name: deletion_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.deletion_log_id_seq OWNED BY public.deletion_log.id;


--
-- TOC entry 200 (class 1259 OID 22361)
-- Name: fixture; Type: TABLE; Schema: public; Owner: splitleague_prod_user
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.fixture OWNER TO splitleague_prod_user;

--
-- TOC entry 201 (class 1259 OID 22367)
-- Name: fixture_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.fixture_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fixture_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2976 (class 0 OID 0)
-- Dependencies: 201
-- Name: fixture_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.fixture_id_seq OWNED BY public.fixture.id;


--
-- TOC entry 202 (class 1259 OID 22369)
-- Name: league; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.league (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_by integer,
    start_date date,
    end_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    public_code character varying(10),
    active boolean,
    allow_code_share boolean DEFAULT true
);


ALTER TABLE public.league OWNER TO splitleague_prod_user;

--
-- TOC entry 203 (class 1259 OID 22374)
-- Name: league_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.league_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.league_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2977 (class 0 OID 0)
-- Dependencies: 203
-- Name: league_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.league_id_seq OWNED BY public.league.id;


--
-- TOC entry 204 (class 1259 OID 22376)
-- Name: league_members; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.league_members (
    id integer NOT NULL,
    league_id integer,
    user_id integer,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean,
    last_accessed timestamp with time zone,
    organiser_notes character varying(100)
);


ALTER TABLE public.league_members OWNER TO splitleague_prod_user;

--
-- TOC entry 205 (class 1259 OID 22380)
-- Name: league_members_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.league_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.league_members_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2978 (class 0 OID 0)
-- Dependencies: 205
-- Name: league_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.league_members_id_seq OWNED BY public.league_members.id;


--
-- TOC entry 206 (class 1259 OID 22382)
-- Name: league_points; Type: TABLE; Schema: public; Owner: splitleague_prod_user
--

CREATE TABLE public.league_points (
    id integer NOT NULL,
    league_id integer,
    points_for_win integer,
    points_for_draw integer,
    points_for_win_margin integer,
    points_for_close_loss integer,
    win_margin_threshold integer,
    play_each_other integer,
    win_type character varying(10)
);


ALTER TABLE public.league_points OWNER TO splitleague_prod_user;

--
-- TOC entry 207 (class 1259 OID 22385)
-- Name: league_points_id_seq; Type: SEQUENCE; Schema: public; Owner: splitleague_prod_user
--

CREATE SEQUENCE public.league_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.league_points_id_seq OWNER TO splitleague_prod_user;

--
-- TOC entry 2979 (class 0 OID 0)
-- Dependencies: 207
-- Name: league_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitleague_prod_user
--

ALTER SEQUENCE public.league_points_id_seq OWNED BY public.league_points.id;


--
-- TOC entry 2816 (class 2604 OID 22387)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 2819 (class 2604 OID 22388)
-- Name: app_version_requirement id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.app_version_requirement ALTER COLUMN id SET DEFAULT nextval('public.app_version_requirement_id_seq'::regclass);


--
-- TOC entry 2830 (class 2604 OID 22456)
-- Name: deletion_log id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.deletion_log ALTER COLUMN id SET DEFAULT nextval('public.deletion_log_id_seq'::regclass);


--
-- TOC entry 2820 (class 2604 OID 22389)
-- Name: fixture id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.fixture ALTER COLUMN id SET DEFAULT nextval('public.fixture_id_seq'::regclass);


--
-- TOC entry 2824 (class 2604 OID 22390)
-- Name: league id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league ALTER COLUMN id SET DEFAULT nextval('public.league_id_seq'::regclass);


--
-- TOC entry 2827 (class 2604 OID 22391)
-- Name: league_members id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league_members ALTER COLUMN id SET DEFAULT nextval('public.league_members_id_seq'::regclass);


--
-- TOC entry 2829 (class 2604 OID 22392)
-- Name: league_points id; Type: DEFAULT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league_points ALTER COLUMN id SET DEFAULT nextval('public.league_points_id_seq'::regclass);


--
-- TOC entry 2833 (class 2606 OID 22396)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 2835 (class 2606 OID 22398)
-- Name: app_version_requirement app_version_requirement_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.app_version_requirement
    ADD CONSTRAINT app_version_requirement_pkey PRIMARY KEY (id);


--
-- TOC entry 2845 (class 2606 OID 22462)
-- Name: deletion_log deletion_log_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.deletion_log
    ADD CONSTRAINT deletion_log_pkey PRIMARY KEY (id);


--
-- TOC entry 2837 (class 2606 OID 22400)
-- Name: fixture fixture_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.fixture
    ADD CONSTRAINT fixture_pkey PRIMARY KEY (id);


--
-- TOC entry 2841 (class 2606 OID 22402)
-- Name: league_members league_members_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league_members
    ADD CONSTRAINT league_members_pkey PRIMARY KEY (id);


--
-- TOC entry 2839 (class 2606 OID 22404)
-- Name: league league_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league
    ADD CONSTRAINT league_pkey PRIMARY KEY (id);


--
-- TOC entry 2843 (class 2606 OID 22406)
-- Name: league_points league_points_pkey; Type: CONSTRAINT; Schema: public; Owner: splitleague_prod_user
--

ALTER TABLE ONLY public.league_points
    ADD CONSTRAINT league_points_pkey PRIMARY KEY (id);


--
-- TOC entry 2972 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-05-20 08:29:55

--
-- PostgreSQL database dump complete
--

