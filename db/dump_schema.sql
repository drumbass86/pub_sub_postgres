--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-1.pgdg100+1)
-- Dumped by pg_dump version 13.5

-- Started on 2022-02-10 09:42:42 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: user
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO "user";

--
-- TOC entry 2958 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: user
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 630 (class 1247 OID 90216)
-- Name: iot_status; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.iot_status AS ENUM (
    'unknow',
    'work',
    'fail'
);


ALTER TYPE public.iot_status OWNER TO "user";

--
-- TOC entry 627 (class 1247 OID 90206)
-- Name: req_status; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.req_status AS ENUM (
    'new',
    'processing',
    'succes',
    'error'
);


ALTER TYPE public.req_status OWNER TO "user";

--
-- TOC entry 204 (class 1255 OID 90240)
-- Name: req_jobs_status_notify(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.req_jobs_status_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
PERFORM pg_notify('req_jobs_status_channel', NEW.id::text);
RETURN NEW;
END;
$$;


ALTER FUNCTION public.req_jobs_status_notify() OWNER TO "user";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 201 (class 1259 OID 90225)
-- Name: iot_devices; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.iot_devices (
    id integer NOT NULL,
    name character varying(256),
    status public.iot_status,
    status_timeupdate timestamp without time zone
);


ALTER TABLE public.iot_devices OWNER TO "user";

--
-- TOC entry 200 (class 1259 OID 90223)
-- Name: iot_devices_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.iot_devices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.iot_devices_id_seq OWNER TO "user";

--
-- TOC entry 2959 (class 0 OID 0)
-- Dependencies: 200
-- Name: iot_devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.iot_devices_id_seq OWNED BY public.iot_devices.id;


--
-- TOC entry 203 (class 1259 OID 90233)
-- Name: req_jobs; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.req_jobs (
    id integer NOT NULL,
    request_time timestamp without time zone,
    request_data character varying(256),
    status public.req_status,
    status_update_time timestamp without time zone
);


ALTER TABLE public.req_jobs OWNER TO "user";

--
-- TOC entry 202 (class 1259 OID 90231)
-- Name: req_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.req_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.req_jobs_id_seq OWNER TO "user";

--
-- TOC entry 2960 (class 0 OID 0)
-- Dependencies: 202
-- Name: req_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.req_jobs_id_seq OWNED BY public.req_jobs.id;


--
-- TOC entry 2816 (class 2604 OID 90228)
-- Name: iot_devices id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.iot_devices ALTER COLUMN id SET DEFAULT nextval('public.iot_devices_id_seq'::regclass);


--
-- TOC entry 2817 (class 2604 OID 90236)
-- Name: req_jobs id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.req_jobs ALTER COLUMN id SET DEFAULT nextval('public.req_jobs_id_seq'::regclass);


--
-- TOC entry 2819 (class 2606 OID 90230)
-- Name: iot_devices iot_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.iot_devices
    ADD CONSTRAINT iot_devices_pkey PRIMARY KEY (id);


--
-- TOC entry 2821 (class 2606 OID 90238)
-- Name: req_jobs req_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.req_jobs
    ADD CONSTRAINT req_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 2822 (class 2620 OID 90241)
-- Name: req_jobs req_jobs_status; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER req_jobs_status AFTER INSERT OR UPDATE OF status ON public.req_jobs FOR EACH ROW EXECUTE FUNCTION public.req_jobs_status_notify();


-- Completed on 2022-02-10 09:42:42 UTC

--
-- PostgreSQL database dump complete
--

