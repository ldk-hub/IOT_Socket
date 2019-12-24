PGDMP     ,                    w            postgres    10.10    12.0 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    12938    postgres    DATABASE     �   CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Korean_Korea.949' LC_CTYPE = 'Korean_Korea.949';
    DROP DATABASE postgres;
                postgres    false            �           0    0    DATABASE postgres    COMMENT     N   COMMENT ON DATABASE postgres IS 'default administrative connection database';
                   postgres    false    3045                        3079    16384 	   adminpack 	   EXTENSION     A   CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;
    DROP EXTENSION adminpack;
                   false            �           0    0    EXTENSION adminpack    COMMENT     M   COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';
                        false    1            �            1255    16393 $   func_estimate_time(text, text, text)    FUNCTION     �  CREATE FUNCTION public.func_estimate_time(floor_dt text, build_code_dt text, equip_nm_dt text) RETURNS numeric
    LANGUAGE plpgsql
    AS $$DECLARE
 	WIND_PW INT;	 	--풍량
	SET_TMP  NUMERIC; 	--설정온도
	SET_HUMI NUMERIC;   --설정습도
	TMP_YN INT;         --냉방유무
	------------온도-----------------
	TMP_SUM NUMERIC;    --합산온도
	TMP_CNT INT; 	 	--온도갯수
	TMP_AVG NUMERIC;	--평균온도
	TMP_CNG NUMERIC;	--온도변화
	RST_TMP NUMERIC;     	--현열
	------------습도----------------
	HUMI_SUM INT;    	--합산습도
	HUMI_CNT INT; 	 	--습도갯수
	HUMI_AVG NUMERIC;	--평균습도
	AVG_CNG_HUMI_TOTAL NUMERIC;-- 평균엔탈피
	SET_CNG_HUMI_TOTAL NUMERIC;-- 설정엔탈피
	HUMI_CNG NUMERIC;	--습도변화
	RST_HUMI NUMERIC;    	--잠열
	---------RT값-----------------
	RST_RT NUMERIC; 	--최종RT값
BEGIN 
	--------------------------------재료준비-----------------------------------------

	--풍량
   SELECT wind_sa 
   INTO   WIND_PW 
	FROM   fc_info_tbl 
	where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
		
	--RAISE NOTICE '풍량값 : %', WIND_PW; 
	
	--설정온도
	SELECT set_temp_info 
		into   SET_TMP 
		FROM   set_info_tbl 
		where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
	
	--RAISE NOTICE '설정온도값 : %', SET_TMP; 
	
	--설정습도
	SELECT set_humi_info 
		into   SET_HUMI 
		FROM   set_info_tbl 
		where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
	
	--RAISE NOTICE '설정습도값 : %', SET_HUMI; 
	
	
	--냉방유무
	SELECT cool_heat_yn 
	INTO TMP_YN
	FROM   set_info_tbl 
	where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
	
   --RAISE NOTICE '냉방유무 값 : %', TMP_YN;
   --------------------------------재료준비-----------------------------------------
   
   
   
   ---------------------------------연산--------------------------------------------
	--온도센서 설치대수 집계
	SELECT (  CASE WHEN temp_info_1 = 0.0 THEN 0 WHEN temp_info_1 IS NULL THEN 0 ELSE Count(temp_info_1) END
			+ CASE WHEN temp_info_2 = 0.0 THEN 0 WHEN temp_info_2 IS NULL THEN 0 ELSE Count(temp_info_2) END 
			+ CASE WHEN temp_info_3 = 0.0 THEN 0 WHEN temp_info_3 IS NULL THEN 0 ELSE Count(temp_info_3) END 
			+ CASE WHEN temp_info_4 = 0.0 THEN 0 WHEN temp_info_4 IS NULL THEN 0 ELSE Count(temp_info_4) END 
			+ CASE WHEN temp_info_5 = 0.0 THEN 0 WHEN temp_info_5 IS NULL THEN 0 ELSE Count(temp_info_5) END) 
		   s_tmp_cnt 
	INTO   TMP_CNT 
	FROM   general_info_tbl 
		where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt
		group by seq;
  	--RAISE NOTICE '온도센서설치대수 집계 : %', TMP_CNT; 
	
	--온도센서 합산
	SELECT ( Coalesce(temp_info_1, 0) 
         + Coalesce(temp_info_2, 0) 
         + Coalesce(temp_info_3, 0) 
         + Coalesce(temp_info_4, 0) 
         + Coalesce(temp_info_5, 0) ) t_temp 
	INTO   tmp_sum 
	FROM   general_info_tbl 
	where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
		
	--RAISE NOTICE '합산 온도집계 : %', TMP_SUM; 
	
	--습도센서 설치대수 집계
	SELECT (  CASE WHEN humi_info_1 = 0.0 THEN 0 WHEN humi_info_1 IS NULL THEN 0 ELSE Count(humi_info_1) END
			+ CASE WHEN humi_info_2 = 0.0 THEN 0 WHEN humi_info_2 IS NULL THEN 0 ELSE Count(humi_info_2) END 
			+ CASE WHEN humi_info_3 = 0.0 THEN 0 WHEN humi_info_3 IS NULL THEN 0 ELSE Count(humi_info_3) END 
			+ CASE WHEN humi_info_4 = 0.0 THEN 0 WHEN humi_info_4 IS NULL THEN 0 ELSE Count(humi_info_4) END 
			+ CASE WHEN humi_info_5 = 0.0 THEN 0 WHEN humi_info_5 IS NULL THEN 0 ELSE Count(humi_info_5) END) 
		   s_humi_cnt 
	INTO   HUMI_CNT 
	FROM   general_info_tbl 
		where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt
		group by seq;
  	--RAISE NOTICE '습도센서설치대수 집계 : %', HUMI_CNT; 
	
	--습도센서합산
	SELECT ( Coalesce(humi_info_1, 0) 
         + Coalesce(humi_info_2, 0) 
         + Coalesce(humi_info_3, 0) 
         + Coalesce(humi_info_4, 0) 
         + Coalesce(humi_info_5, 0) ) h_humi 
	INTO   humi_sum 
	FROM   general_info_tbl 
	where build_code = build_code_dt
		and floor = floor_dt
		and equip_nm = equip_nm_dt;
		
	--RAISE NOTICE '합산 습도 집계 : %', HUMI_SUM; 
	
	--평균온도
	TMP_AVG =  ROUND(TMP_SUM / TMP_CNT,1);
	--RAISE NOTICE '평균온도치 : %', TMP_AVG; 
	
	--평균습도
	HUMI_AVG =  HUMI_SUM / HUMI_CNT;
	--RAISE NOTICE '평균습도치 : %', HUMI_AVG; 
	
	--엔탈피(평균치)
	AVG_CNG_HUMI_TOTAL = ROUND(((-0.0052653348-0.00062202171*TMP_AVG+0.03788993*HUMI_AVG+0.00003756779*POWER(TMP_AVG,2)-0.00000126819*POWER(HUMI_AVG,2)+0.0016741451*TMP_AVG*HUMI_AVG)/
							(1-0.030664741*TMP_AVG-0.00011389447*HUMI_AVG+0.00028884007*POWER(TMP_AVG,2)+0.00000038884*POWER(HUMI_AVG,2)-0.00000325535*TMP_AVG*HUMI_AVG))/1000,8);	
	--RAISE NOTICE '엔탈피(평균) : %', AVG_CNG_HUMI_TOTAL; 				 
	    
	--엔탈피(설정치)
	 SET_CNG_HUMI_TOTAL = ROUND(((-0.0052653348-0.00062202171*SET_TMP+0.03788993*SET_HUMI+0.00003756779*POWER(SET_TMP,2)-0.00000126819*POWER(SET_HUMI,2)+0.0016741451*SET_TMP*SET_HUMI)/
	 							(1-0.030664741*SET_TMP-0.00011389447*SET_HUMI+0.00028884007*POWER(SET_TMP,2)+0.00000038884*POWER(SET_HUMI,2)-0.00000325535*SET_TMP*SET_HUMI))/1000,8);
	 --RAISE NOTICE '엔탈피(설정) : %', SET_CNG_HUMI_TOTAL; 	
	 
	 --습도변화값(평균치 - 설정치) 
	HUMI_CNG = 	ABS(AVG_CNG_HUMI_TOTAL - SET_CNG_HUMI_TOTAL);				 
	
	--RAISE NOTICE '습도변화값 : %', HUMI_CNG; 
	
	-- 평균센서온도 - 설정온도  = 온도변화 
	TMP_CNG =  TMP_AVG- SET_TMP;
	--RAISE NOTICE '온도변화 값 (IF타기 전) : %', TMP_CNG; 
	
	-- 온도변화값에서 음수 값이나올경우 0으로 치환 양수일경우 그대로
	IF TMP_CNG <= 0 THEN
		TMP_CNG = 0;
	ELSE 
		
	END IF;
	--RAISE NOTICE '온도변화 값 : %', TMP_CNG; 

	--현열 = 풍량 * 0.288 * 온도변화값 
	RST_TMP = ROUND(WIND_PW * 0.288 * TMP_CNG,0);
	--RAISE NOTICE '현열 산출결과 : %', RST_TMP;
								 
	--잠열 = 풍량 * 717 * 습도변화 							 
	 RST_HUMI = ROUND(WIND_PW * 717 * HUMI_CNG,0);
	 --RAISE NOTICE '잠열 산출결과: %', RST_HUMI;
								 
	--RT값 산출
	IF  TMP_YN = 0	THEN
		RST_RT = 0.0;
	ELSE
		RST_RT = ROUND(((RST_TMP + RST_HUMI)/3024), 1);
	END IF;
	--RAISE NOTICE '개별 알티 : %', RST_RT;
	 ---------------------------------연산--------------------------------------------
	return RST_RT;
END ; $$;
 ^   DROP FUNCTION public.func_estimate_time(floor_dt text, build_code_dt text, equip_nm_dt text);
       public          postgres    false            �            1255    16395    insert_t1_tr()    FUNCTION     �  CREATE FUNCTION public.insert_t1_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
  
  DECLARE 
    c_cd text;   --센터코드 
    c_nm text;   --센터명 
    client text; --고객명 
    b_nm text;   --건물명 
	c_detail text;  --고정값
    push_dt timestamp; --발생시간 
	
  BEGIN 
    IF (tg_op = 'INSERT') THEN 
      RAISE notice 'IMEI코드 : %', NEW.imei_cd; 
      RAISE notice 'tag1_val : %', NEW.tag1_val; 
      RAISE notice 'push_date : %', NEW.push_date; 
     
	SELECT NEW.push_date
      INTO   push_dt;
	  
      SELECT --fms.imei_cd, 
             --fms.center_cd, 
             -- fms.center_nm, 
             fmb.center_cd, 
             fmb.center_nm, 
             fmb.customer, 
		     fmb.center_nm, 
             fmb.build_nm 
      INTO   c_cd, 
             c_nm, 
             client, 
			 c_detail,
             b_nm 
      FROM   fire_manage_sensor fms 
      join   fire_manage_build fmb 
      ON     fmb.center_cd = fms.center_cd 
      WHERE  fms.imei_cd = NEW.imei_cd; 
       
      RAISE notice '센터코드 : %', c_cd; 
      RAISE notice '센터명 : %', c_nm; 
      RAISE notice '고객명 : %', client; 
	  RAISE notice '문자 전송 멘트 : %', c_detail; 
      RAISE notice '건물명 : %', b_nm; 
      RAISE notice '날짜 : %', push_dt;
	  
      INSERT INTO fire_event_tbl 
		  ( 
			  seq_no, 
			  center_cd, 
			  center_nm, 
			  sensor_stat,
			  event_content,
			  issue_date, 
			  customer, 
			  build_nm,
			  imei_cd
		  ) 
		  VALUES 
		  ( 
			  NEXTVAL('trg_seq'), 
			  c_cd, 
			  c_nm, 
			  '발생', 
			  c_detail,
			  push_dt, 
			  client, 
			  b_nm,
			  NEW.imei_cd
		  ); 
     
    END IF; 
    RETURN NULL; 
  END $$;
 %   DROP FUNCTION public.insert_t1_tr();
       public          postgres    false            �            1255    16396    insert_t2_tr()    FUNCTION       CREATE FUNCTION public.insert_t2_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
  data_cnt int;
BEGIN 
    IF (tg_op = 'INSERT') THEN 
	 -- 받은정보
      RAISE notice 'IMEI코드 : %', NEW.imei_cd; 
      RAISE notice 'tag1_val : %', NEW.tag1_val; 
      RAISE notice 'push_date : %', NEW.push_date; 
   
	--  select 검색해서 결과가 없으면 update문 안걸리게 처리
	 
	 select count(*) 
		 into data_cnt
	 from fire_sensor_occur
		 where imei_cd = NEW.imei_cd
		 and restore_info is null
		 and push_date <= now();
	 
	 
	 RAISE notice '데이터 갯수: %', data_cnt;
	 
	 IF(data_cnt > 0 ) THEN
		 --fire_sensor_occur에 해당 조건 업데이트 처리
		 update fire_sensor_occur set
		 restore_info = 'ok', restore_date = now()  
		 where imei_cd = NEW.imei_cd
		 and restore_info is null
		 and push_date <= now();
		 
		  RAISE notice '센서 발생테이블에 수정완료';
		 
		 
		 --이벤트 테이블 복구처리
		 update fire_event_tbl 
		 set sensor_stat = '복구', restore_date = now() 
		 where imei_cd = NEW.imei_cd 
		 and sensor_stat = '발생' 
		 and issue_date <=  now();
		 
		  RAISE notice '이벤트 관리 테이블 수정완료';
		  
		 END IF;
		 
		 RAISE notice '조건문끝나는지점';
	 
	END IF;
	RETURN NULL; 
END
$$;
 %   DROP FUNCTION public.insert_t2_tr();
       public          postgres    false            �            1259    16603 
   ap_autoseq    SEQUENCE     s   CREATE SEQUENCE public.ap_autoseq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE public.ap_autoseq;
       public          postgres    false            �            1259    16397    ap_role    TABLE     Y   CREATE TABLE public.ap_role (
    id bigint NOT NULL,
    name character varying(255)
);
    DROP TABLE public.ap_role;
       public            postgres    false            �            1259    16400 	   ap_sample    TABLE     q  CREATE TABLE public.ap_sample (
    seq integer,
    status_info character varying,
    person_info character varying,
    damage character varying,
    addr_info character varying,
    detail_info character varying,
    occur_dt timestamp with time zone,
    chk_dt timestamp with time zone,
    restore_dt timestamp with time zone,
    file_name character varying
);
    DROP TABLE public.ap_sample;
       public            postgres    false            �            1259    16406    ap_schedule    TABLE     �   CREATE TABLE public.ap_schedule (
    seq integer NOT NULL,
    title character varying,
    content character varying,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    int_name character varying
);
    DROP TABLE public.ap_schedule;
       public            postgres    false            �            1259    16412    ap_statistic    TABLE     �   CREATE TABLE public.ap_statistic (
    seq integer,
    item_number character varying,
    brand_name character varying,
    season_reason character varying,
    status character varying
);
     DROP TABLE public.ap_statistic;
       public            postgres    false            �            1259    16418    ap_user_role    TABLE     _   CREATE TABLE public.ap_user_role (
    user_id bigint NOT NULL,
    role_id bigint NOT NULL
);
     DROP TABLE public.ap_user_role;
       public            postgres    false            �            1259    16421    ap_users    TABLE       CREATE TABLE public.ap_users (
    id bigint NOT NULL,
    email character varying(255),
    nickname character varying(255),
    password character varying(255),
    regdate timestamp without time zone,
    sex character varying(255),
    username character varying(255)
);
    DROP TABLE public.ap_users;
       public            postgres    false            �            1259    16427    build_fc_amt_tbl    TABLE     �  CREATE TABLE public.build_fc_amt_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    chw_gas_amt numeric(6,1),
    chw_gas_amt2 numeric(6,1),
    frz_pwr_amt numeric(6,1),
    cwp_pwr_amt numeric(6,1),
    clp_pwr_amt numeric(6,1),
    ct_pwr_amt numeric(6,1),
    air_pwr_amt numeric(6,1),
    create_date timestamp with time zone,
    insert_user character varying(20)
);
 $   DROP TABLE public.build_fc_amt_tbl;
       public            postgres    false            �           0    0    TABLE build_fc_amt_tbl    COMMENT     M   COMMENT ON TABLE public.build_fc_amt_tbl IS '건물별 소비량 테이블';
          public          postgres    false    203            �            1259    16430    build_fc_tbl    TABLE     1  CREATE TABLE public.build_fc_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    fc_gubun character varying(40),
    fc_nm character varying(30),
    create_date timestamp with time zone,
    insert_user character varying(50),
    fc_capacity integer,
    efficiency numeric(6,2)
);
     DROP TABLE public.build_fc_tbl;
       public            postgres    false            �           0    0    TABLE build_fc_tbl    COMMENT     P   COMMENT ON TABLE public.build_fc_tbl IS '건물별열원장비정보테이블';
          public          postgres    false    204            �            1259    16433    build_info_tbl    TABLE     ;  CREATE TABLE public.build_info_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    build_nm character varying(100),
    zip_code character varying(6),
    address character varying(100),
    create_date timestamp with time zone,
    insert_user character varying(20),
    temp_flag integer
);
 "   DROP TABLE public.build_info_tbl;
       public            postgres    false            �           0    0    TABLE build_info_tbl    COMMENT     P   COMMENT ON TABLE public.build_info_tbl IS '건물기본정보 입력테이블';
          public          postgres    false    205            �            1259    16436 	   build_seq    SEQUENCE     r   CREATE SEQUENCE public.build_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
     DROP SEQUENCE public.build_seq;
       public          postgres    false            �            1259    16605    cht_tt    TABLE       CREATE TABLE public.cht_tt (
    seq integer NOT NULL,
    m_date date,
    town_nm character varying,
    town_size character varying,
    distance character varying,
    duration character varying,
    latituded character varying,
    create_dt timestamp without time zone
);
    DROP TABLE public.cht_tt;
       public            postgres    false            �            1259    16438 
   energy_seq    SEQUENCE     s   CREATE SEQUENCE public.energy_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE public.energy_seq;
       public          postgres    false            �            1259    16440    fc_info_tbl    TABLE     7  CREATE TABLE public.fc_info_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    floor character varying(8),
    equip_nm character varying(30),
    wind_sa integer,
    sa_kw numeric(8,1),
    wind_ra integer,
    ra_kw numeric(8,1),
    cool_capacity integer,
    heat_capacity integer,
    air_area integer,
    side_area integer,
    floor_data numeric(8,1),
    base_date_info timestamp(4) with time zone,
    insert_user character varying(20),
    etc character varying(200),
    cool_heat_rt integer,
    sort_data character varying(5)
);
    DROP TABLE public.fc_info_tbl;
       public            postgres    false            �           0    0    TABLE fc_info_tbl    COMMENT     H   COMMENT ON TABLE public.fc_info_tbl IS '장비스펙 정보 테이블';
          public          postgres    false    208            �            1259    16443    fc_seq    SEQUENCE     o   CREATE SEQUENCE public.fc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
    DROP SEQUENCE public.fc_seq;
       public          postgres    false            �            1259    16445 
   fire_agent    TABLE     �   CREATE TABLE public.fire_agent (
    seq integer NOT NULL,
    center_cd character varying(3),
    center_nm character varying(50),
    name character varying(30),
    phone character varying(15),
    insert_date timestamp without time zone
);
    DROP TABLE public.fire_agent;
       public            postgres    false            �            1259    16448    fire_agent_seq    SEQUENCE     w   CREATE SEQUENCE public.fire_agent_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.fire_agent_seq;
       public          postgres    false            �            1259    16450    fire_event_seq    SEQUENCE     w   CREATE SEQUENCE public.fire_event_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.fire_event_seq;
       public          postgres    false            �            1259    16452    fire_event_tbl    TABLE     �  CREATE TABLE public.fire_event_tbl (
    seq_no integer NOT NULL,
    center_cd character varying(30),
    center_nm character varying(50),
    event_content character varying(500),
    sensor_stat character varying(10),
    chk_agent_nm character varying(50),
    last_chk_agent_nm character varying(50),
    cause character varying(20),
    cause_detail character varying(500),
    issue_date timestamp with time zone,
    chk_date timestamp with time zone,
    restore_date timestamp with time zone,
    end_date timestamp with time zone,
    customer character varying(50),
    build_nm character varying(50),
    imei_cd character varying(20)
);
 "   DROP TABLE public.fire_event_tbl;
       public            postgres    false            �            1259    16458    fire_his_seq    SEQUENCE     u   CREATE SEQUENCE public.fire_his_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.fire_his_seq;
       public          postgres    false            �            1259    16460    fire_manage_build    TABLE     �   CREATE TABLE public.fire_manage_build (
    seq integer NOT NULL,
    center_nm character varying(45),
    address character varying(500),
    center_cd character varying(30),
    customer character varying(50),
    build_nm character varying(50)
);
 %   DROP TABLE public.fire_manage_build;
       public            postgres    false            �            1259    16466    fire_manage_sensor    TABLE     �   CREATE TABLE public.fire_manage_sensor (
    seq_no integer NOT NULL,
    imei_cd character varying,
    center_cd character varying,
    center_nm character varying,
    use_yn character varying,
    create_date timestamp with time zone
);
 &   DROP TABLE public.fire_manage_sensor;
       public            postgres    false            �            1259    16472    fire_mobile_seq    SEQUENCE     x   CREATE SEQUENCE public.fire_mobile_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.fire_mobile_seq;
       public          postgres    false            �            1259    16474    fire_sensor_occur    TABLE     3  CREATE TABLE public.fire_sensor_occur (
    sensor_seq integer NOT NULL,
    imei_cd character varying(16),
    tag1_val character varying(10),
    comm_yn character varying(10),
    push_date timestamp without time zone,
    restore_info character varying(50),
    restore_date timestamp with time zone
);
 %   DROP TABLE public.fire_sensor_occur;
       public            postgres    false            �           0    0    TABLE fire_sensor_occur    COMMENT     Q   COMMENT ON TABLE public.fire_sensor_occur IS 'NB-IOT센서 들어올 테이블';
          public          postgres    false    218            �            1259    16477    fire_sensor_restore    TABLE     �   CREATE TABLE public.fire_sensor_restore (
    alarm_seq integer,
    imei_cd character varying,
    tag1_val character varying,
    push_date timestamp with time zone
);
 '   DROP TABLE public.fire_sensor_restore;
       public            postgres    false            �            1259    16483    fire_seq    SEQUENCE     �   CREATE SEQUENCE public.fire_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999999999
    CACHE 1;
    DROP SEQUENCE public.fire_seq;
       public          postgres    false            �            1259    16485    fire_sms_his    TABLE     �  CREATE TABLE public.fire_sms_his (
    seq integer NOT NULL,
    msg_title character varying(100),
    msg_content character varying(1000),
    sender character varying(11),
    center_nm character varying(50),
    agent character varying(50),
    sms_send_chk character varying(15),
    receiver character varying(11),
    send_time timestamp with time zone,
    send_id character varying(50)
);
     DROP TABLE public.fire_sms_his;
       public            postgres    false            �           0    0    COLUMN fire_sms_his.seq    COMMENT     7   COMMENT ON COLUMN public.fire_sms_his.seq IS '순번';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.msg_title    COMMENT     C   COMMENT ON COLUMN public.fire_sms_his.msg_title IS '문자제목';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.msg_content    COMMENT     E   COMMENT ON COLUMN public.fire_sms_his.msg_content IS '문자내용';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.sender    COMMENT     F   COMMENT ON COLUMN public.fire_sms_his.sender IS '문자받는사람';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.center_nm    COMMENT     I   COMMENT ON COLUMN public.fire_sms_his.center_nm IS '유저소속센터';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.agent    COMMENT     K   COMMENT ON COLUMN public.fire_sms_his.agent IS '문자받는사람이름';
          public          postgres    false    221            �           0    0     COLUMN fire_sms_his.sms_send_chk    COMMENT     M   COMMENT ON COLUMN public.fire_sms_his.sms_send_chk IS '문자발송 여부';
          public          postgres    false    221            �           0    0    COLUMN fire_sms_his.send_time    COMMENT     D   COMMENT ON COLUMN public.fire_sms_his.send_time IS '발송 시간';
          public          postgres    false    221            �            1259    16491    general_info_tbl    TABLE     S  CREATE TABLE public.general_info_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    equip_nm character varying(30),
    general_date timestamp(4) with time zone,
    floor character varying(8),
    temp_info_1 numeric(5,1),
    humi_info_1 numeric(5,1),
    temp_info_2 numeric(5,1),
    humi_info_2 numeric(5,1),
    temp_info_3 numeric(5,1),
    humi_info_3 numeric(5,1),
    temp_info_4 numeric(5,1),
    humi_info_4 numeric(5,1),
    temp_info_5 numeric(5,1),
    humi_info_5 numeric(5,1),
    imei_code character varying(30),
    device_info character varying(25)
);
 $   DROP TABLE public.general_info_tbl;
       public            postgres    false            �           0    0    TABLE general_info_tbl    COMMENT     I   COMMENT ON TABLE public.general_info_tbl IS '수집데이터 테이블';
          public          postgres    false    222            �            1259    16494    hibernate_sequence    SEQUENCE     {   CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.hibernate_sequence;
       public          postgres    false            �            1259    16496    mobile_application_info_tbl    TABLE     Y  CREATE TABLE public.mobile_application_info_tbl (
    seq integer NOT NULL,
    center_nm character varying(20),
    center_cd character varying(5),
    agent_nm character varying(30),
    cause character varying(10),
    cause_detail character varying(500),
    reception_date timestamp with time zone,
    int_date timestamp with time zone
);
 /   DROP TABLE public.mobile_application_info_tbl;
       public            postgres    false            �            1259    16502    mobile_fire_user    TABLE     �  CREATE TABLE public.mobile_fire_user (
    id bigint NOT NULL,
    email character varying(255),
    nickname character varying(255),
    password character varying(255),
    phone character varying(255),
    reception character varying(255),
    regdate timestamp without time zone,
    username character varying(255),
    center_cd character varying(255),
    user_id character varying(255),
    name character varying(255)
);
 $   DROP TABLE public.mobile_fire_user;
       public            postgres    false            �            1259    16508    price_date_tbl    TABLE     �  CREATE TABLE public.price_date_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    gas_price_hot numeric(7,1),
    gas_price_cool numeric(7,1),
    pwr_price_0 numeric(7,1),
    pwr_price_1 numeric(7,1),
    pwr_price_2 numeric(7,1),
    reduce_day integer,
    reduce_month numeric(5,1),
    base_date_info date,
    insert_user character varying(20),
    etc character varying(200)
);
 "   DROP TABLE public.price_date_tbl;
       public            postgres    false            �           0    0    TABLE price_date_tbl    COMMENT     X   COMMENT ON TABLE public.price_date_tbl IS '단가 및 기준일정보 입력테이블';
          public          postgres    false    226            �            1259    16511 	   price_seq    SEQUENCE     r   CREATE SEQUENCE public.price_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
     DROP SEQUENCE public.price_seq;
       public          postgres    false            �            1259    16513    sensor_udp_info_tbl    TABLE     �  CREATE TABLE public.sensor_udp_info_tbl (
    seq integer NOT NULL,
    delive_date timestamp(6) with time zone,
    imei_code character varying(30),
    device_info character varying(25),
    tag_1 integer,
    length_1 integer,
    temp integer,
    tag_2 integer,
    length_2 integer,
    humi integer,
    tag_3 integer,
    length_3 integer,
    battery integer,
    err_chk character varying(5)
);
ALTER TABLE ONLY public.sensor_udp_info_tbl ALTER COLUMN seq SET STATISTICS 1;
 '   DROP TABLE public.sensor_udp_info_tbl;
       public            postgres    false            �           0    0    TABLE sensor_udp_info_tbl    COMMENT     N   COMMENT ON TABLE public.sensor_udp_info_tbl IS '센서 UDP 정보 테이블';
          public          postgres    false    228            �            1259    16516    set_info_tbl    TABLE     �  CREATE TABLE public.set_info_tbl (
    seq integer NOT NULL,
    build_code character varying(10),
    equip_nm character varying(30),
    floor character varying(8),
    set_temp_info numeric(5,1),
    set_humi_info numeric(5,1),
    cool_heat_yn character varying(15),
    cool_per numeric(5,1),
    heat_per numeric(5,1),
    etc character varying(200),
    insert_date timestamp with time zone,
    yesterday_yn character varying(10),
    rt_per numeric(4,1)
);
     DROP TABLE public.set_info_tbl;
       public            postgres    false            �           0    0    TABLE set_info_tbl    COMMENT     B   COMMENT ON TABLE public.set_info_tbl IS '설정정보 테이블';
          public          postgres    false    229            �            1259    16519    set_temp_seq    SEQUENCE     u   CREATE SEQUENCE public.set_temp_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.set_temp_seq;
       public          postgres    false            �            1259    16521    t1    TABLE     8   CREATE TABLE public.t1 (
    c1 integer,
    c2 date
);
    DROP TABLE public.t1;
       public            postgres    false            �            1259    16524    t2    TABLE     8   CREATE TABLE public.t2 (
    c1 integer,
    c2 date
);
    DROP TABLE public.t2;
       public            postgres    false            �            1259    16527    t3    TABLE     8   CREATE TABLE public.t3 (
    c1 integer,
    c2 date
);
    DROP TABLE public.t3;
       public            postgres    false            �            1259    16530    temp_sensor_tbl    TABLE     P  CREATE TABLE public.temp_sensor_tbl (
    sensor_seq integer NOT NULL,
    imei_cd character varying(16),
    device_id character varying(8),
    tag_val_1 character varying(10),
    tag_val_2 character varying(10),
    tag_val_3 character varying(10),
    parity_chk character varying(10),
    push_date timestamp without time zone
);
 #   DROP TABLE public.temp_sensor_tbl;
       public            postgres    false            �           0    0    TABLE temp_sensor_tbl    COMMENT     E   COMMENT ON TABLE public.temp_sensor_tbl IS 'NB-IOT 센서테이블';
          public          postgres    false    234            �            1259    16533 	   temp_user    TABLE     Y  CREATE TABLE public.temp_user (
    seq bigint NOT NULL,
    email character varying(50),
    nickname character varying(40),
    password character varying(30),
    username character varying(30),
    organization_code character varying(30),
    u_flag integer,
    add_date timestamp with time zone,
    regdate timestamp without time zone
);
    DROP TABLE public.temp_user;
       public            postgres    false            �           0    0    TABLE temp_user    COMMENT     ?   COMMENT ON TABLE public.temp_user IS '유저정보 테이블';
          public          postgres    false    235            �           0    0    COLUMN temp_user.seq    COMMENT     @   COMMENT ON COLUMN public.temp_user.seq IS '기본키(순번)
';
          public          postgres    false    235            �           0    0    COLUMN temp_user.email    COMMENT     @   COMMENT ON COLUMN public.temp_user.email IS '이메일주소
';
          public          postgres    false    235            �           0    0    COLUMN temp_user.nickname    COMMENT     @   COMMENT ON COLUMN public.temp_user.nickname IS '관리자명
';
          public          postgres    false    235            �           0    0    COLUMN temp_user.password    COMMENT     @   COMMENT ON COLUMN public.temp_user.password IS '패스워드
';
          public          postgres    false    235            �           0    0    COLUMN temp_user.username    COMMENT     =   COMMENT ON COLUMN public.temp_user.username IS '아이디
';
          public          postgres    false    235            �            1259    16536    trg_seq    SEQUENCE     |   CREATE SEQUENCE public.trg_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999999
    CACHE 1;
    DROP SEQUENCE public.trg_seq;
       public          postgres    false            �            1259    16538    user_seq    SEQUENCE     q   CREATE SEQUENCE public.user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
    DROP SEQUENCE public.user_seq;
       public          postgres    false            �          0    16397    ap_role 
   TABLE DATA                 public          postgres    false    197   /�       �          0    16400 	   ap_sample 
   TABLE DATA                 public          postgres    false    198   I�       �          0    16406    ap_schedule 
   TABLE DATA                 public          postgres    false    199   ��       �          0    16412    ap_statistic 
   TABLE DATA                 public          postgres    false    200   ��       �          0    16418    ap_user_role 
   TABLE DATA                 public          postgres    false    201   @�       �          0    16421    ap_users 
   TABLE DATA                 public          postgres    false    202   Z�       �          0    16427    build_fc_amt_tbl 
   TABLE DATA                 public          postgres    false    203   ��       �          0    16430    build_fc_tbl 
   TABLE DATA                 public          postgres    false    204   �       �          0    16433    build_info_tbl 
   TABLE DATA                 public          postgres    false    205   z�       �          0    16605    cht_tt 
   TABLE DATA                 public          postgres    false    239   7�       �          0    16440    fc_info_tbl 
   TABLE DATA                 public          postgres    false    208   ��       �          0    16445 
   fire_agent 
   TABLE DATA                 public          postgres    false    210   ��       �          0    16452    fire_event_tbl 
   TABLE DATA                 public          postgres    false    213   ��       �          0    16460    fire_manage_build 
   TABLE DATA                 public          postgres    false    215   _�       �          0    16466    fire_manage_sensor 
   TABLE DATA                 public          postgres    false    216   s�       �          0    16474    fire_sensor_occur 
   TABLE DATA                 public          postgres    false    218   �       �          0    16477    fire_sensor_restore 
   TABLE DATA                 public          postgres    false    219   �       �          0    16485    fire_sms_his 
   TABLE DATA                 public          postgres    false    221   ��       �          0    16491    general_info_tbl 
   TABLE DATA                 public          postgres    false    222   �      �          0    16496    mobile_application_info_tbl 
   TABLE DATA                 public          postgres    false    224   �      �          0    16502    mobile_fire_user 
   TABLE DATA                 public          postgres    false    225   T      �          0    16508    price_date_tbl 
   TABLE DATA                 public          postgres    false    226   �
      �          0    16513    sensor_udp_info_tbl 
   TABLE DATA                 public          postgres    false    228   �      �          0    16516    set_info_tbl 
   TABLE DATA                 public          postgres    false    229   �      �          0    16521    t1 
   TABLE DATA                 public          postgres    false    231   y      �          0    16524    t2 
   TABLE DATA                 public          postgres    false    232   �      �          0    16527    t3 
   TABLE DATA                 public          postgres    false    233         �          0    16530    temp_sensor_tbl 
   TABLE DATA                 public          postgres    false    234   W      �          0    16533 	   temp_user 
   TABLE DATA                 public          postgres    false    235   q                  0    0 
   ap_autoseq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.ap_autoseq', 41, true);
          public          postgres    false    238                       0    0 	   build_seq    SEQUENCE SET     8   SELECT pg_catalog.setval('public.build_seq', 82, true);
          public          postgres    false    206                       0    0 
   energy_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.energy_seq', 244, true);
          public          postgres    false    207                       0    0    fc_seq    SEQUENCE SET     6   SELECT pg_catalog.setval('public.fc_seq', 153, true);
          public          postgres    false    209                       0    0    fire_agent_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.fire_agent_seq', 116, true);
          public          postgres    false    211                       0    0    fire_event_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.fire_event_seq', 1, false);
          public          postgres    false    212                       0    0    fire_his_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.fire_his_seq', 40, true);
          public          postgres    false    214                       0    0    fire_mobile_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.fire_mobile_seq', 12, true);
          public          postgres    false    217                       0    0    fire_seq    SEQUENCE SET     7   SELECT pg_catalog.setval('public.fire_seq', 1, false);
          public          postgres    false    220            	           0    0    hibernate_sequence    SEQUENCE SET     A   SELECT pg_catalog.setval('public.hibernate_sequence', 24, true);
          public          postgres    false    223            
           0    0 	   price_seq    SEQUENCE SET     8   SELECT pg_catalog.setval('public.price_seq', 90, true);
          public          postgres    false    227                       0    0    set_temp_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.set_temp_seq', 157, true);
          public          postgres    false    230                       0    0    trg_seq    SEQUENCE SET     6   SELECT pg_catalog.setval('public.trg_seq', 36, true);
          public          postgres    false    236                       0    0    user_seq    SEQUENCE SET     7   SELECT pg_catalog.setval('public.user_seq', 96, true);
          public          postgres    false    237            	           2606    16541    ap_role ap_role_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.ap_role
    ADD CONSTRAINT ap_role_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.ap_role DROP CONSTRAINT ap_role_pkey;
       public            postgres    false    197                       2606    16614    ap_schedule ap_schedule_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.ap_schedule
    ADD CONSTRAINT ap_schedule_pkey PRIMARY KEY (seq);
 F   ALTER TABLE ONLY public.ap_schedule DROP CONSTRAINT ap_schedule_pkey;
       public            postgres    false    199                       2606    16543    ap_user_role ap_user_role_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.ap_user_role
    ADD CONSTRAINT ap_user_role_pkey PRIMARY KEY (user_id, role_id);
 H   ALTER TABLE ONLY public.ap_user_role DROP CONSTRAINT ap_user_role_pkey;
       public            postgres    false    201    201                       2606    16545    ap_users ap_users_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.ap_users
    ADD CONSTRAINT ap_users_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.ap_users DROP CONSTRAINT ap_users_pkey;
       public            postgres    false    202                       2606    16547 &   build_fc_amt_tbl build_fc_amt_tbl_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.build_fc_amt_tbl
    ADD CONSTRAINT build_fc_amt_tbl_pkey PRIMARY KEY (seq);
 P   ALTER TABLE ONLY public.build_fc_amt_tbl DROP CONSTRAINT build_fc_amt_tbl_pkey;
       public            postgres    false    203                       2606    16549    build_fc_tbl build_fc_tbl_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.build_fc_tbl
    ADD CONSTRAINT build_fc_tbl_pkey PRIMARY KEY (seq);
 H   ALTER TABLE ONLY public.build_fc_tbl DROP CONSTRAINT build_fc_tbl_pkey;
       public            postgres    false    204                       2606    16551 "   build_info_tbl build_info_tbl_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.build_info_tbl
    ADD CONSTRAINT build_info_tbl_pkey PRIMARY KEY (seq);
 L   ALTER TABLE ONLY public.build_info_tbl DROP CONSTRAINT build_info_tbl_pkey;
       public            postgres    false    205            5           2606    16612    cht_tt cht_tt_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.cht_tt
    ADD CONSTRAINT cht_tt_pkey PRIMARY KEY (seq);
 <   ALTER TABLE ONLY public.cht_tt DROP CONSTRAINT cht_tt_pkey;
       public            postgres    false    239                       2606    16553    fc_info_tbl fc_info_tbl_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.fc_info_tbl
    ADD CONSTRAINT fc_info_tbl_pkey PRIMARY KEY (seq);
 F   ALTER TABLE ONLY public.fc_info_tbl DROP CONSTRAINT fc_info_tbl_pkey;
       public            postgres    false    208                       2606    16555    fire_agent fire_agent_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.fire_agent
    ADD CONSTRAINT fire_agent_pkey PRIMARY KEY (seq);
 D   ALTER TABLE ONLY public.fire_agent DROP CONSTRAINT fire_agent_pkey;
       public            postgres    false    210                       2606    16557 "   fire_event_tbl fire_event_tbl_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.fire_event_tbl
    ADD CONSTRAINT fire_event_tbl_pkey PRIMARY KEY (seq_no);
 L   ALTER TABLE ONLY public.fire_event_tbl DROP CONSTRAINT fire_event_tbl_pkey;
       public            postgres    false    213                       2606    16559 '   fire_manage_build fire_manage_area_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.fire_manage_build
    ADD CONSTRAINT fire_manage_area_pkey PRIMARY KEY (seq);
 Q   ALTER TABLE ONLY public.fire_manage_build DROP CONSTRAINT fire_manage_area_pkey;
       public            postgres    false    215                       2606    16561 *   fire_manage_sensor fire_manage_sensor_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.fire_manage_sensor
    ADD CONSTRAINT fire_manage_sensor_pkey PRIMARY KEY (seq_no);
 T   ALTER TABLE ONLY public.fire_manage_sensor DROP CONSTRAINT fire_manage_sensor_pkey;
       public            postgres    false    216            !           2606    16563 '   fire_sensor_occur fire_sensor_data_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.fire_sensor_occur
    ADD CONSTRAINT fire_sensor_data_pkey PRIMARY KEY (sensor_seq);
 Q   ALTER TABLE ONLY public.fire_sensor_occur DROP CONSTRAINT fire_sensor_data_pkey;
       public            postgres    false    218            #           2606    16565    fire_sms_his fire_sms_his_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.fire_sms_his
    ADD CONSTRAINT fire_sms_his_pkey PRIMARY KEY (seq);
 H   ALTER TABLE ONLY public.fire_sms_his DROP CONSTRAINT fire_sms_his_pkey;
       public            postgres    false    221            %           2606    16567 &   general_info_tbl general_info_tbl_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.general_info_tbl
    ADD CONSTRAINT general_info_tbl_pkey PRIMARY KEY (seq);
 P   ALTER TABLE ONLY public.general_info_tbl DROP CONSTRAINT general_info_tbl_pkey;
       public            postgres    false    222            '           2606    16569 <   mobile_application_info_tbl mobile_application_info_tbl_pkey 
   CONSTRAINT     {   ALTER TABLE ONLY public.mobile_application_info_tbl
    ADD CONSTRAINT mobile_application_info_tbl_pkey PRIMARY KEY (seq);
 f   ALTER TABLE ONLY public.mobile_application_info_tbl DROP CONSTRAINT mobile_application_info_tbl_pkey;
       public            postgres    false    224            )           2606    16571 &   mobile_fire_user mobile_fire_user_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.mobile_fire_user
    ADD CONSTRAINT mobile_fire_user_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.mobile_fire_user DROP CONSTRAINT mobile_fire_user_pkey;
       public            postgres    false    225            +           2606    16573 "   price_date_tbl price_date_tbl_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.price_date_tbl
    ADD CONSTRAINT price_date_tbl_pkey PRIMARY KEY (seq);
 L   ALTER TABLE ONLY public.price_date_tbl DROP CONSTRAINT price_date_tbl_pkey;
       public            postgres    false    226            -           2606    16575 ,   sensor_udp_info_tbl sensor_udp_info_tbl_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.sensor_udp_info_tbl
    ADD CONSTRAINT sensor_udp_info_tbl_pkey PRIMARY KEY (seq);
 V   ALTER TABLE ONLY public.sensor_udp_info_tbl DROP CONSTRAINT sensor_udp_info_tbl_pkey;
       public            postgres    false    228            /           2606    16577    set_info_tbl set_info_tbl_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.set_info_tbl
    ADD CONSTRAINT set_info_tbl_pkey PRIMARY KEY (seq);
 H   ALTER TABLE ONLY public.set_info_tbl DROP CONSTRAINT set_info_tbl_pkey;
       public            postgres    false    229            1           2606    16579 %   temp_sensor_tbl temp_sensor_data_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.temp_sensor_tbl
    ADD CONSTRAINT temp_sensor_data_pkey PRIMARY KEY (sensor_seq);
 O   ALTER TABLE ONLY public.temp_sensor_tbl DROP CONSTRAINT temp_sensor_data_pkey;
       public            postgres    false    234            3           2606    16581    temp_user temp_user_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.temp_user
    ADD CONSTRAINT temp_user_pkey PRIMARY KEY (seq);
 B   ALTER TABLE ONLY public.temp_user DROP CONSTRAINT temp_user_pkey;
       public            postgres    false    235            :           2620    16582    fire_sensor_restore restore_trg    TRIGGER     |   CREATE TRIGGER restore_trg AFTER INSERT ON public.fire_sensor_restore FOR EACH ROW EXECUTE PROCEDURE public.insert_t2_tr();
 8   DROP TRIGGER restore_trg ON public.fire_sensor_restore;
       public          postgres    false    254    219            9           2620    16583    fire_sensor_occur sensor_trg    TRIGGER     y   CREATE TRIGGER sensor_trg AFTER INSERT ON public.fire_sensor_occur FOR EACH ROW EXECUTE PROCEDURE public.insert_t1_tr();
 5   DROP TRIGGER sensor_trg ON public.fire_sensor_occur;
       public          postgres    false    218    253            ;           2620    16584 	   t1 t1_trg    TRIGGER     f   CREATE TRIGGER t1_trg AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE PROCEDURE public.insert_t1_tr();
 "   DROP TRIGGER t1_trg ON public.t1;
       public          postgres    false    253    231            6           2606    16585 (   ap_user_role fk59xisyxas47yt2pa1qyv4g4q0    FK CONSTRAINT     �   ALTER TABLE ONLY public.ap_user_role
    ADD CONSTRAINT fk59xisyxas47yt2pa1qyv4g4q0 FOREIGN KEY (user_id) REFERENCES public.ap_users(id);
 R   ALTER TABLE ONLY public.ap_user_role DROP CONSTRAINT fk59xisyxas47yt2pa1qyv4g4q0;
       public          postgres    false    202    2831    201            7           2606    16590 (   ap_user_role fk5c7s7yosqex5utl47t2l9s3mp    FK CONSTRAINT     �   ALTER TABLE ONLY public.ap_user_role
    ADD CONSTRAINT fk5c7s7yosqex5utl47t2l9s3mp FOREIGN KEY (role_id) REFERENCES public.ap_role(id);
 R   ALTER TABLE ONLY public.ap_user_role DROP CONSTRAINT fk5c7s7yosqex5utl47t2l9s3mp;
       public          postgres    false    197    201    2825            8           2606    16595 (   ap_user_role fkhbvywopp0wflg2f166npd9m5m    FK CONSTRAINT     �   ALTER TABLE ONLY public.ap_user_role
    ADD CONSTRAINT fkhbvywopp0wflg2f166npd9m5m FOREIGN KEY (user_id) REFERENCES public.mobile_fire_user(id);
 R   ALTER TABLE ONLY public.ap_user_role DROP CONSTRAINT fkhbvywopp0wflg2f166npd9m5m;
       public          postgres    false    225    2857    201            �   
   x���          �   J  x�ݘ�kA���+�VE潙��ē�!�m�JB��xO�B�J����=x�a�1ԃ����pvv�h�,wvم�������Z�ݝ�{���{D�o��|^?�>}}�{��<y����%w�>�҃���\9R_�[�wr5K�)�K @fWɏ��uLԢ���~P�Q2�X���{HAn�pڤ�	P�����G�*��,�.e�Q�`hx�u)x��t����j��a��-�s=�x��NWlhِ����NG��.�{zt���^L�G�R��}v�/NVX,]�Wb�6E�D���RW�~g9��TϢ�qg�x�L�� R�o٪o>B��C����$	�& �׷Z��(�`3S��S�!SBz���԰@��͖����~ �Ά�G�#oy����Д��I'���d�I0G�+7P�L�U�Y/�Qa�� ��|�B7֭��PL sse�������KX�lq7��k�UYY��Ed2�jٵ���4��&����74*� ���Y9'��zV
��^
�jf
s	��U��v
�r�{?���W?���c?��Q��~
��
��+T��X���??�
�%�S�����      �   !  x���?K�@�=��*���$�]�:Bۺ�ւB��tOR���Z2�-�ѯ�~�"�iiƃ�{~��6��M��#��w����wzݾ�\��tr���C�Q�n�l
i\�o���=�������U"��#Z�8��\H��="�	�� �=���H̐ty�}�J_~I�?��MA��l�� L�b�J�����y�����s�=0�B�
騰�����:�R��6=\�O���6og�H�Tr^HZ�#9�Gs%}�� ��no 1�BJG�#-$����      �   \  x���?K�@��|�ۢ�����89tHۺJ�p(4�Z38D�D)�ĢS%?�w���T�A_�;���L�C�V�y�aA�s���a�78F�(Fa��u�m����υ,.��vu�w�!1�,��ғ�����͌��I�Rs�d�S��~�Ň�FM�Ң��,�ݵ�^J��~��S�?��/+�\���X��׀W��-~�_��7h���x�K���|A�'^.'�.'�.���,R���Ib&��ū��D���&٧�~��o�@d;�Ⱦz�}�"{D� �\�A�*� ʀ��e�D(&ʀ��2`"��(&ʀ��2`"���U��2(WeP�-��� �23�      �   
   x���          �   J  x���Mo�@໿���mR�]��^
��X*��,
�+�__���6=�I��L&�d̹k8c�=��HTd6�>N����4\��;f ��OI�n�6 �!���f���Z����K�Vn	J��)Ω'�K�ݺ(�H���R�z"݇PƜ<�H��
��BG�4�	>�n��5N�_'�/����������r}*�GD٭z�^��֗������I:�Y�󔓿PA�e V���i�q������ơ�iQ��5/�Ͷ�/��[��<�$?idiLS�֬��g��)���xV���*XuF�[��1�SR��J@�y,N��6�����ϒ�      �   V  x����jB1��>Evi�9anIN�UR�P�[�҂�����$����L��|���`4�L�`4yV���f�4��z���/g��n�[l���p����UJ?ЕB�MS��t8���J1�H�cC���j�A!G�h� ;�r!}����C����Ф�zi�=�`i�2)��as�N`�FQ1�7@����Ʒ��B�E��&]��Rb.���c⚒@E��Ɓ���\Io��c�"�Q�Q���ɜ�R*2Fa�w�6���1Y�m,J)��>�D�a���Z/`r���0��0׆i(�@�^8˽e� D¼JB�.��k�H�`���?{��}��      �   P  x���OkA �{>�ޢ�,oޛ�����k�6�V��R<����
=�V�C?�I��ovI��t����������y�iw�7�zQ��{�f�x/���`g��s��ѓ�Nc;��ע��&��o��ӓ��ۏ��<�sq�.lG-�&"i�hFB���1��� q_�<?�I�������E�`ʻ�ɯ���󗕃�k"_BAЈ7�
��e���Q�z�����o�����RqbQh,��R�lb&+_ƅ�����	�94o��Щ^W��_�]����t�ldGe�2��x��)�llQ�D_��R+,rI������]�R��I��;�(�5�M={�iz�}v|1��s���:���]��
M�h1 ���{mI�,������"Va���5���������дMŮ��n�W�ȥ��5��o��x(MtI׾Un.��Dl@)o�{A@lUPx_j�ͥ�T�ֵ�T)pJM���
�w5k>Ͳ"��`?�}����ˣa�֜n�:������	�ݎ�#��6z�9,d$ E�Ji�r��B+�ȇ������hW���k��T`��.�F�/�˙�      �   �  x����K�@����nF9��n��zUP!�AZo#�@���ً(��ViI/*0,R�/ڝ�Cw΢� �`�vw�}wK��3�He���^�XXճ{�bn�������-�����L�D�Ѧ�irH��j-xڗuj1��O���n���;�8jq�W��Ʌjtb�1�M�Q�1ݲ-�88j�Jn��!��$~m�U��A���k�k��
Wϭa�+��ِ&��ȭs Z�݊�<�>/��^��>�	�2�L�y%g'��]��톢Wkc���.utJٟ�8�U��T4m��F���|�(ʯ�h��?Fk+f���5���.���0Qj�G&:|�0Q��<�A��5QC� ��.�u ;�߬�b��:��������U
�@Gk���A���8�F�э(��,F� u�5M�tl0޵ÿAZ#�7�/s�      �   �  x���]O�0����Ci����+#$�A�W��F��Ͱ��߻��7z�dY{��<{����l1y\��l9G��w[��jݾ�-z�Ο&tF/А�F�vװ�f������)sw�27"��3X�}�F��X���$����W��L2��uQ}�u�"�qp������Z��	
��!I����EQEH.՝^�M]�kMϞ���E�E�HN0O��IȅT�� �o+��?r�`ɣxi�K]���V�u���(���)�(nr��}�[kt��r�;�o��JDQeH�Է���1��T=1�өB"�k�O
�X�k�a��$�Q�ʼ쎳�htS����*o'%X�U)�s�w'�����W�T�k\ḆDÎ�{��T{�u3�pp��`� �#
bڶ(ץ9J��¼���_�a0�ݡd      �   �  x�ݜ�nE��y����U�5=��(!���`���[DrpF��r �	��r��ᆝw`�{v�v׳ޞ�h��jg<k{�����߽�s������ϳ��?<~��8z�������Ӈ�ٗ7�����>@������ �=ܸ���d}�1v=Ӆ�ϥ�9/t}.�{ ��y��z��rd`�l1���BS0��cf�{�޽��?�vw3f�3:�9�� LZi�=����y���gϼ`�㪀+�b��:��9��,np�WMW��[�q���B���L�F&�$�< ���`!��dÙ$�B���FE"�w����b/�@J\��*���}es��A%��b��Y�I��<99�PAs-��0B�cb�(�,z2���ŷG-Dp�3�o���� �[D�o��h�{����6쟿~s��o�ꭋ���cC?��^\�̸�m����/#񋅱	�șW�<�Th���.��G�+<� 
�Ǥ�c�׮F��9<8��͵��xІ�iAo�FG�>���ʠPtQ8�O�Dd��>���qR�Ģ�=��G�^{޻�I���w���2����)&@^�:�jV戉}ztB�^������#�t*^p��gF����}gф��?��Y' �o(�}E����T�}�܂�e۪��}��~@�9��mQ�@OIӶ�J@�^N�������v^�\������q�:�ֳgA!Ƹ��s�Lƍ�^c�6�u�#�X+�]@&��9��*�$-�fn��d�IB��,0Yo�G`�+�ҬD<YV�!�v�S��I��Q$��P�(2������iRK!"h��d
�|���b�	z���W��{��_�l�C���`�z���< t����Ԥ"����?ߞ��'��o?�n��¤��dI��$T`*x*D*t
*t*J��
��
EJ�**E�~)����jУ)�S�������=WSY�V���h�4�e���*9?ćg�.T��ݜ{vl宍�L%���P���p&��e .;�\�I��|�lc�̂x�v��b����?�o�uo�}k/�n"�n7X�M�3GQ���J�u�-d�A�������
ڼEF!�1	}��]�ȸ��QC��c�b���*.�z<cg��޺��/�'b�x�$ۤ��I0�D�a��n'0�o���.ɹz�P
%I$�1�P�~4�Zq�����fG�'��fyS�~��ܢ�ߔ��0����v���J��ۯZ�`��Wa���nOq�� ,zږE���rJ#`QФP�['�n�Y��V3� ��L����G�睃'�Γǧ_�R��p>�ca΄��X!TL�q1]\�C{�܌q8<3���i����yr���c{v���a�?B]�*�+�lUV�#��8* #e
��S"��p����\�N�6E��b$����ӏq��L
��tG���h2�#Oˆb6��_^��lb�ݝ����.Vvf�Vm`guI\ơ�7
W\��g%i��2ԙuY㋅��K���� ����6�q��On��ʳ����6��/W9K�P��ݽ���e�z���h�CwUǃ� =td<h���Z��n�
4�/hIB��m�ͩ�:��I�|�?��I�����¡K��IB���Z��8���x�$-��15ɋ�ϻǣ&�q��x�$3>�^��D�$5��z�d�TƬ���]�c`�      �   	  x���mO����S�8j�}���j�(ErIp�Vm�V��������@ҮY�]��$�jQX�/4s�;��3�0��k��B^c�Ͻ�����YX\���幅�����������?|�ǯ���o��/����/~���'Ks���������ٓ��{�^�]o�EWY�_�����4>uk+�h�/&��F���Ǐ}��{?N��?�{�3���(�rah��Lz��\�y�*�T`E
_5��q|xo
d0N���޷�[s(fd�/y���!�����#�8H�{H�d�0��z֋ʫ�Y��]��r���$��2���f�~�z3��8�wy��(���$��qQ߽�dk-�r�A3�\�W6�fc��5�4B7heϿN�n���mM�`���E�B��V�y�)QS�4�;��vM�����_��ǘe�W�uYQy� g�s��n}#�l����A/}�O㮋���q�ѡ\{�&����C��W��n�ެ7q���r�[��
�l�M�4}��V�K��\��i�*!}�m�0K�5%�G<�iL
��*CT"�|��Y:�L��[�qr[2�;�#����b�%o������޳��a׽�..?�ٰ
.d��ˑ���r�_��e�E�%�~��#����O��ٳQ-���v���q�ET�"�|�t���f���~��=�F%4�NFF��:\��:�h�o׏�ֲ�R�j!�P���1n��ZI܂�K;�sMj;G��:[�П���Y��K�F�o~]�
�T孡Ih#��#�0BIޗ���'
>����e��Dm�����f��vO]~Ñ�!/�C���mԫ�<8�J��p��d�V�&Wl�ڬ�=D�6*�
+d`�w�'�P�#D�;�w�AC�]�|��*�R��2�mxI�vhXK��9�f�q򪄷VJ��<79�PFE�{��#����	��Q�A�4�����5�	-��='�pY�xv1���2ޓ"�����۫�c���\\N6,W�D�D*�i�BCl�V���@��*�����xg� ^����F�jF�Ћ�ǅ��*���#1���=^��%Y�l�5��2@����'��8hC�m7h]���TmJ��po�	B�(Q�>$L��u�����g���<|_5(�QJ�`�`��׳� N7F��V9/���V$Έ�3�	�Xo���RZ��H��0E�P7c�M��_�3�Q
�oE�(8�6����ar��.lw��JJܩx�mDA�ʻ���a�*k_2˿@�6��*fk}�_��8�pʩFI��0�{+mD�{H��7P������`�sօ�/�%��+/�>2��%r�ۈ�������:�o	sz��*V	FD�k�$��?9n7���yƧK�)�K,q.5�g�n�!�N�N�Ly�]��Ƚ�$����@)��V{�t��s

��W�	�����%�e`�gyk��肋u����"�Vτ"�.KI ��x=�u/��oF ܴ����mdȘP��ONb�4̓��א��y��
�� 	D�@�h	��{���˓�\�E��~C�%B��%"�+�,�,\n�J�+��J�;!E,RAɘ�I���ګq����;SOdB.��ުD!u�B/&͓u�jy&Ї)�
RD!��B2_S���M(����k�T�m>�d�+�y��mnf+�j�O7�m��@k�C&>�|����u;���{4�f��]��_J�|����g뾝��iVYM��E��HELR���y��|�p����y�/���w�R�$ef�dà��lV]^(�����Kb��7*$=/}�.I=f�MmC�ީ�A*,|3�dG����[�!YqQ�t���u/ˇj��u�U��E`U�f�D!TBoc�0����"�N�>�����ٍ{����n٠ݶ{�Zj�<�$W���� �gc����I�3x��u����-�j&�,�*k�0��$��E�4:8���[���74���ͧ[8aB�$�Vz�O�6�^Ӹ�ؽ���U��)8����)����E,��_ [o��Aqɭ��>P�
㢏%3��$�����$�I�~���\����2}���`3����ƺ��KpQ@���d�x$D�S�?��� ]���d�ayh
F�)e!2H���q�El��Y��@v�lRm����`9�D����Z[��,8>���L5�j��Ȑ�_a1�i)bP���>��[��cD^���=<A(����)�����EȤ��-T	:4��L�KW{�y��lC�N�������!���/3�>�w�e���T[c44�`�������m      �   c  x����JBA�Oqw�(��3��̙V-\b��V0n HDX��]-"�-�r�Dy}��6!xMS����9g��g��Z��������i���y�L.��n���DG��F�m�ٍ⺊C�7������vt��>��Wi�s��u7���p�6*�i�T\�XT)��H����w$�X����By~���ңΐd�/oz~_�2�{@a�'z���K#Y�m=��ڰt*����k���D��@�T��V^j�iGk�����w�2�f�;��j'�EG��k����}I:m�Vt&���B�S��O�$,�,{A�l�<�0GrA��$�62�� bRƮT(|���      �     x��Z�o�~�_�O��D�~��Sm�� �)":�[��ia m� y׏�A�T%��EڤB5�i�z�(�.�?�/ܽ��3;{��y���!��澛�����[{���gU����)�����y��_���w_��/��埾���|����>�x�����m�D�x���b,;�2����6^z��D6zL�O/FL�v��D���Z8�������;����> ,01��D�ӣ����Y �5x8"�#�f�ۙ�{��U��=��oDϟMö�z�$]W N����r9K���t����F��,�1L�޵)�N��<�!8�ay��&8�e�U#�.���Y�ȃ=Yk��|ʃ��w�nP���)��6��o�x�If;��B�!�#��J��9X�	�a��u7���g��^uJ���A�����nMn�!7��F/��
�_a���������O�g`o�vMa;
q]��v��Q6Q�qA����H�d��&�1Դ�|�卨��
�����e��?�/���K����Q�cn�Wݦ��Iq�<��S��$+B�i㪠��m��6�8����� ڹ�lfn����1��v�� ��(]'���"	3 ���7o�d��ka��4ȧMh&2UF�@���u�Ru��ua�SJ#	���p��臉�կU����Ye��A��Ԅ�� �GݖM�M
5ޮ�x`I%'epYƈ�43����>7 `D��Q0�	3fn��@H�Ycɪ�fz�\n`Τ���O2��q]yP�Ժ��d�8)7��'<8�a��d����\fn�si����r�U��Q�
�+��W���(�'n���IL
>b���K�i'�!�﷒�����l�3��D�<����x�"L_C��T���JV+%��� j5ŏ#Ԏ9KD���y�̤��RR�`��"Ü?SrH���fK4Fq�U�	��,�~�a�b�A���m�z��xS���8��@�߂ τ�ַe&%�M	"d� �D�[�tMӍ��y ~:RT��⬎l�y��L?,��tv
//�/T2����	\����9��u�����0Ni�$3�ܔ�d�X��8�80q��(���O�h�i�套,�j�d*Y�x�cj4��@{��0��3Ak��![�`����w�X3U��X�{�+ �1[��V�^H1ژ��c�9�Лi�E���b�42��)��Q�0r@!���y�]Be&&V���r3��O���KA���($�洦W��ចZ�W�M�g�)�Mʂ����t]%�Mk�ppʚtl��m3հy��!����bjFDÀ�� �*���L/l+E9�}p��oz�'����2�ri��q�F2�Al��E	�a��N+o�͡�R^�D�8����WX���m&4�Մ��˗y9N4�Vw�
%�a��A�fTM���BkU�L�l78dп	`Hę��m��%����$3�&���a�ܨ��ԣvG%?��y���LilR���bSC&���ϡ&:�x)|fZb�S���2����J�l3��Q>��rq�uD,��u����J���Z3:8��k��2�R�LF��2�����-�T�P�zY�-,���붪R�5�7G-k3�qx�WaX@��z�����TfXKI�n�+����6!G�Px"¢�\ʫ8���1x��:�M��1��VU�u�r��vuE;�2[vg�1�I!I���hw'��ϔ��.��L &��L<�81;X��N�s�)'i�d]��Bf2k%U�8f��x:�yי�� 
����;��u������-m��i��/�9��^�K�"�ܐ�^��蒋�E�LGԑ��8q��=`�'��@�4{�WzGE9�N��a�uL%YB9w�m�8i��Uz5�ɑ��?�IT�A�[�Μ�ۛ⨯w
�� tZ����ɋ��9Vp͈ߵf�Om�	Uqۙ�_ҫ�U�mƱ�ڴ~ۊZW���F�f��[�)�������˖8�Q�����ݸO�vӖ�&�f���G�|��_�V��(�r7�]�±�WX'�ֱ�_E�1z���{�&ۙ��v�kƳ���7�g��\qI׈���G��U�����kF����XTd$@���@]kE�F��rgQ��7%2>6cc��N�`~�?�W�d:�N���b�֪7S�8?{���$�r���t-�e�Z�_���u� �x� �ܮ��;��{|��2�Y����Xc��G_��)%�EsT�~��1������<,C���7���H�B�����Ӫ�[Ԏ�̲t�J9*Ꞡv,uT�!��i�&q�g&
ƣ�D���������r���[���ټ��_Q�5�8��3S�C�0���	BgM=�f���wHm&������	�}�晉��t-��Q��KtYkW\n29�f9�9h�� �E�=nb�q�U+�y��Ռ�=����֫+�1R��Pu6G���ͽmیF�[QSS}r2@-����&�Y��Qh̾6�1�o��ޣu ś|�A#U�ܭp�d�Xj�꙱�Wѻ�Ҭ������<[}8��>�� Oc5�r�D��ovs�BҸ�N�s�v �P����]F���1��S��R���� o<�,P��f<�[�*�=r}��V,*L(���6G�Y��2�X�<����b�V���@���[IcZ��\c�+9��Z,c+_��fﻊ��F`2��9e6�������J(�c}J+|�4��t�����Ђ߇5Hz�!�S���a�!?�}zO�Q\�����8�u�-<�n���jZ�@51a��C�Y�Q� �u���x�@      �   �  x����NG����j��fv���Wm�H�V���(�h�M�$�7`GL�6qT�d��T�vgߡ3{��g�\Tb,�,�|:s��|s�S3��w+����7�_��G��ã'�~~��Ᏻ��>~�˓��/���.���OK�����HH	����J�L��վ������e�ؾK�#0{���4*Qr���\#�嫟_��_�h}�8���g�4ԝ�l��w^U0)��`��ֳ�f���i�����0�(��So��~5��z>N�M�sVz�#�I��ɣ��V��ʷ__�ڲ�6'a���CQ�����<���($���A�(ؓ5���[滦��$nYi�}�~�UT��C�s���(�{��C�&P=Qa��W�%O]���Zݭf/Lt��?�j�dL�(	C@#��''k~�`�r�"��e��mS���6�z;֛}�m��5��0uED������L��jbh�"ʅ۸<��&�Δ#%2���N.��5�86 {�Y�o�S��P>����Ŷ�1)���c"������tJz5���_%
+�*��@(�۫e�4��(b�!M��;�������$=>ɋȧ�+ʹ(��D����m�v�W*!�/`�k� e>���W�ʷ�q%�y��ӖG,���'���-�Z������<��P%`.ON�FH�)��P(�� k{�ƺ_��
�88�`�V �IԖ�M)]�D���On����j����
���09��We��oบ�ֽ�#B�P2T.EQM7�������&�qEj��$��ZׯLԈ���FD=駯���87L���K�;ƕ%ǽ$��z
Da�b�jKf"��a�*2b;��J������ZY��y��h5�������@oܙ����a�Ґ*�:#Ξ���,�/_�U�Q���!`j\��̋ ��l'�]�y�o��?�l��=�j�C��+�C�9M���.ߝ�$�%!��#�9h���-☽�4�Pr
��	��9���87 w�M�gYۯ7�xJ@�^�/�𙵶�7�t����J��ZF����X���];��җ}#ȯL�0
�ۙ<I>�Q�Nb���K��`�xN��ŭ)dp���uS�=�p�2�Ls���$B��%�!� ��Ki}��Wll�c߄��&}�5
��p�0� �I�	ăޤ�6���Y�����0�o�H����F?�[MoW!{;F���p�ӃA��M���#Ie��1Q8Ԙ�r3�i}-T��ݱ��KC��]��z��%��d$�r���-Z�{�'=B�(rY��]�f�̫�W�`V*"�I�u����&��\qEN����ž��7���,�O=�9s�4�;��)]��I�dX5����a�&�;�{��B�J�����7g�F�)*�Q��5^F9�3Jk��n�����.�<#����^:��=�ILې�2V�q��=��BpV�xou��3��x'�9K%{Y�*���޶�z�N|{Y�������֝/3��a���, .�<�w�v�1hL�X��|Sn����u��V���;k���&#���rsB�}���
�5{5�
�Gw�����=��%�C0x��l����\�(dq�P�e�\�+ �Ü0"h0�vC�I�JY�a]��}���w��q���X��l��3�O�y�K�i�Ƌ��oޝ�7=O�ĥK��7�      �   �  x���Mk1���{KK1�#��r0��k�&��R�������-�\���a߇�i����|3��7����_�?��������Ï���~��=����۫��M��&4�5C��/��u^�\�\"NhU�2%U�y7���f���j�$[fY-l2�B��ֵʖ$���Ф��$"cӳ��]XC���a}��NP��gp1�yw�폘|�)4�	��r����L�I0S�QL~��)sf���ya�)䢞�Aq�3�0���D�D�A��<�Y��{|������>�g��<���^�$4V}�dt�
XE�2��aPMF(�*��)�q}
��T�HU*Ir*�S�\%�,e���}T�:%�b�>_h��X����0�>(iJUPE�JB/�㠬J�E���$W��f���ۡȓI^(���WS��x�I�&/�0��(AJJ�3��*�T�jQhV����*qA:}">��Z���4+      �   �  x���KkA �����E��~�'9,Hs(+�Ȯ�{g`��0M�GwWW�o�n>�O���������>}�/O�������|~<�.?�ϧ�����7w�z=]��xa�2^�)\�רהɬ5�CZ��+���o�-BH�t����e]NV��e83����͒�Q"�����t�Q�%%7��:+@E�[�A��=�E#�����u�Xb�HIMV�&S�U��a`y��X��R6��r\��-��@h�s�Ԣzn�x����v1Dd�^�%rk��Xb��bͲ�M�Z�0+Z�P ���B	dzUK�U@SĖ�W�y�ui������a	�����XˏJ�X2 V�=7~[��d��Z��j��gy��b-֨������-�0�V�1��La����J�F{���a^�9�j�D�1��X���1[� b㭍�jL=��`��/u.5      �   �  x�͘�K[A���{K�u������^ڃA,T�U�U�R�DEs�P��#m�r�����o�?t^h+�W���^ryd_�ϛ��|'s��ϗ����3�v��f{Mn�߭�t�:+��������x ��h�w�����U:��*�?}L�~�p�.���(�W�w(~+�(P�*o��\�N�����p�,�����t�����{�vay~��t����;��88
�*?k4�̌�\D�%Xc�L��o���j�i=|<5w_(�4(�� �4eC���b"�Ko���L~r�P����ZI�ѹl�0QP�Y�$Y��P�w�֯�?B7m��7�
�s{G5r��j�8&�����htv8p;�UY�;��_���ۨ\�J�a��C����uR"��f��Ί��a���2���Em�`�,�R!*�_L�0�+k��a���gc��14�h��8�-��7�a �)h�����70�Z��VA65�1�m�$Sx��[����mIjTD�-n�<�s0,k.�;���uǌyz�` k��kʞ�/C�T���e��I���QW���⠟�.����x2��XQ<�q%���0�[����;�f��hH*K��YSaj�P5H���#��,��GU���'�&_O*,C�0,��xq��GU�q�Ɣ��oX�=��
�P7���ã�!dW���u�P���f'���?5�	�      �   �  x�Ś�nE��~����ꪮ�?�)H,Y�Dl�AE�B�yN��qE⍒��g<3����-�����#��ru��}��ׯ^|s�]^߼�~������Տo޽������~������ݷϯn_��>���{vc̳�����m�>�������/��p����{F���t��|_��w�T�M�
����Օ�㧟�]>3lS�u��
���t�Ox�	�ʥ������5�kT�͸-%�K��y�G�����s+��ĵ��ђ�6��n׬���-o���&$V�c�����Oĵpy���/��Em�X?�viU2|��OQZz	8�>���>N���<�>O>���a������;�v�d~��\;����>ÕtЄKIuC\~���͋��4kZ誴��ʯYZ�V��[ARZ\��,��Z�]]���Ua]v�D]���m[ې�J�v��mF�7�Oc��٪�q���^X�Lz�k(å��>��<���6�,�%�<�ٜq�K�i�5�����@ϼ�K%;���W�y3�}R_n����u�UD7˱.�+Q�7�x1(F�٢u�GK�!4�y&R�e��1v�]��fW�� � �z����e �y�����ӛ2�	ʅ�! ��Q������+ǎ��`���i����N8�����^Ғme�,v���M��X�8/�fC��.-9n���p�0�����ݒ�'m^��!�]���RN�j�؞�;;r�EN󒑬7r��?${f���Y��+4F��m�=
�/����h� �쑗"��E�YT�L�k%!$���z�aia�%Y�jT��U;��j��%ٮ�;����*���z0ʃ�e;��y�_i}pG[��0>�M��q3����zxPV�y�~�Z�d�P���M|�*�:
xV�X��W��N�IUd�;��GC�ȸ�D�TEX+����*�DiT=X��?v,�����bi!��Bii�eq�h�V�u�>0��'Q�W�`à�6,��*�
�6V�D�^���â�^Jv�ᰬ"m~�ʴ�ȑ,)�H���ma��Φ��*���Lk�tB/�a� ��C�z/3�i!�F���#n�"�@ DXF�HFf%+�
���`�>�"m�ǸHW��]p~�D֣�%ͳ+�芺���)Ӽ$�}9ڛ�����?O��:�5[�	F�"N�G��n�4�c�����a�WT_����	�1�\�����)      �   �  x��ԱN�@��Fi���;�H&��ږ�  ���qQ7M��ހń�al}�5���Mz�]�~��Vj��EC�������u�����Y��p�Wm�;跺}{�r��tyVm���!9�j�j5�X���X���K��-X���x+"�X�D�Bǈ�&��&D�)Ց���N��)��ҳFodu��V'���vA� �I%%dL)�p>���bE��9]���`�&wb"�j���\�Q�0! 3T!��4�4�t�4�aڎ�Ĕ4�d�2L@�@��|J����L:2ۋIY�a�RVR��QL�JP]�q3v}_�q��'D��1�ќBHM������؎]�5��}~�P*�/!Tf�!��<N��&c���_���a��}�}�����W���>�/�Di����v�D�.�y��5      �   `  x����n�@�{��C$Z)�����x6���1�0���l�y�^[)=��C���C�T��D���F�>F��?���� $�P�UGEK7��i��7y�'�u.��� �����N�'����B1e�Z>F�1�|{�5�l~����,�N[Bj��Z81���L��¾��m������"��/;" �S��B@@(�j�Z���I����^�>�?>ܓ?I����&�R�ܭ�p),z�dn�1�eN��^�M��oe��.�Wo�Қ_n����=bE@S�P3��O��i�W��o??}���`�v�#}��h��p��+��mn-{��3\KN���:h4�ҁS�W����"ÈM��Ce;=i����z3��{=S�`.iIy��"�M��m7U���ƨ�6�QjѸ�!����Z����`������.2��I!P}�Oq�y���>��_�� ak���Nkko�W^SC���4�R�v9��6��;.=��˫j-������p�m������9���8��L�Q6Z0�\}d��(yym�풷Þ�g�9h+̹%;�Ű��$�4���V�9W׏��z�If�lw���~ыm7      �     x���Kk�0����y���a'5;uPF d����>r����}������р��~�q�.o����U�?w�ao�þ���~s��zެK����π:We��re�	"��9���@���y04�� ��Nû��i����t����,!$�7OaE��1F2yJ8G8���w	��.�~���3+���z�����p���h�~e[3��]��c��T��-�Yc�%ZFb�œqS���Q\P|�kY��a�      �   �  x���Mk�@໿boi������d[�X�ګ`?@�Z�J��٥dzy��}'��l�2���Y쏫�����=쾖���r���-�W�:�,F3q�}Q� @	��T	x��~��K��!��@�_i4m���BU�Ҿ/�����b29?g��޸��<ٕgu�a�w���6O�@�y*� �{d�T������Ṻ�)�c�t���g@����l�ló�}`�L����AW�͵*�\�i�m�8�'C�d�;b�\��t��i�O׷�R��[<�\��\�I��B�G����O�L�H�/��K��h�u-S��_�8�����g3~6]?��śyѬ��{��ūY�)̟�]_�/��K?'��C�/^��&ޫ�;����=��O��Bn�>q|�� ^<��=T&�־^����      �   �  x�Ś�n�F��~
ޔ��3�͞" M.�ؽ:H!�6m\$ȩEѓ����k���&��Ғ��*�pE0d��W?����g��/�>�*�/��+�������w�ۛ�?���}���������#)��l)p~=��z���M�DU�y�EY?��W��yy}qn� ��X������F8��W���@Y�kK����C��"�$��Q� J�0I�q)8*S�4�I�xx\;a�9L�0ɸ�<��aRq)u\;���0Y¤�R��vr��ẖ̂��8L�0ٸ�=�� :o�1��~��j]_�߯���P���h0��&�ζ\�� S	]	St�ˆ��C6V���	��Uc5,��t����
�\[_iUɐ�-�Zj����@6@��@͞�-N�����DO�D�X�P����]��N#����>t��D:I�NH�D�tD�)��Kd{�-:Yif��A�Q�_i�K���~���~B&A���mٔ�j���		S����s9
��'�p Vj�e2��4��dj��=��z:& Z����>�Jq\���U�v*[��H��K~b��DW�m���H
K� Qiw��X/�Dɒ�v����+E�`�&�g����B���
nJe�IeCV�]����F&�s�V��%�I;�!v����cX�Wq�Vs��.Uci�̨�j��!m�JCiZ�UM����N+5��P����${@M��FA`ZH�\ �R-���@�����2y���깿T����cG�C2'ER	Z{M�B2&ɧ�䲬�9.�M@�o��h�l$H!����y���m�7�������o,��߳+'��.~�K)�}�8!}�t����XDF�R�Z43ʝ�Pf{M��@L�xVv�*/��	�n>������C�N��89��[u�4�'�ǎ��@�r��L���5L2�)��!=��fռ\���t��dJ
(�SP.�))W O���@R�r?�̉q��4�`1�2'��I�8����SYs��0���]I2Oe�M\�����R�TZ�����1Λ�M����L�7@[�4&̇�,O�h��/m1�N�d╼&W*�J"�2���$�L:��1y�&�L<	L���y� �L<�2N,��d�Hc�KKz����<�U"��{��>\�x<��k<���)��?�+�J���8��Y@�D�ȓb$�`�$�d"G>O�޾�/��J	��P<T$�]vy8�KD������6��2����~hJ      �   :   x���v
Q���W((M��L�+1Ts�	uV�0�QP720��50�54T״��� c�      �   :   x���v
Q���W((M��L�+1Rs�	uV�0�QP720��50�54T״��� c�      �   :   x���v
Q���W((M��L�+1Vs�	uV�0�QP720��50�54T״��� c�      �   
   x���          �   �  x���OO�0 �;�b74���zA��D�+AV6d��'I��%j4Q�x�A��[ÃA/{������R��������Z���Z.�M^�N}��6���}m��u-�0I��o�%����pr}/��� "�Bթ���Peh% J �A�f��Sdas�rI&�N�n�R�(�����w����3-�\j�JC:^L����&�):���^v�D=P��!� �- b�d�E�[�cR����hz�ݡ�k��״3���^I�!s�� (-�� :R�~Y_��>���ȫ������&�Y��_R#?��)��n����?J��M�7�&^��Q���^Dt.���x�W!�� щ����������~�t�"� q�PaX^�}7���     