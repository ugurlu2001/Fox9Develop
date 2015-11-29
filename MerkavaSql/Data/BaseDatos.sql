﻿/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
 *                          BASE DE DATOS (DATABASE)                          *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
CREATE DATABASE merkava_80004234_001
   WITH OWNER = postgres
        ENCODING = 'UTF8'
        TABLESPACE = pg_default
        LC_COLLATE = 'Spanish_Spain.1252'
        LC_CTYPE = 'Spanish_Spain.1252'
        CONNECTION LIMIT = -1;

/* -------------------------------------------------------------------------- */
/* Determina si la cadena de caracteres especificada está compuesta solo por  */
/* los dígitos del 0 al 9.                                                    */
/* -------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION pa_es_digito (TEXT) RETURNS BOOLEAN
   AS 'SELECT $1 ~ ''^(-)?[0-9]+$'' AS resultado;'
   LANGUAGE SQL;

/* -------------------------------------------------------------------------- */
/* PA para calcular el dígito verificador numérico con entrada alfanumérica   */
/* y basemax 11.                                                              */
/* -------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION pa_calcular_dv_11_a (p_numero IN VARCHAR, p_basemax IN NUMERIC DEFAULT 11) RETURNS NUMERIC AS $$
DECLARE
   v_total      NUMERIC(6);
   v_resto      NUMERIC(2);
   k            NUMERIC(2);
   v_numero_aux NUMERIC(1);
   v_numero_al  VARCHAR(255) DEFAULT '';
   v_caracter   VARCHAR(1);
   v_digit      NUMERIC;
BEGIN
   -- Cambia la última letra por ASCII en caso que la cédula termine en letra.
   FOR i IN 1..LENGTH(p_numero) LOOP
      v_caracter := UPPER(SUBSTR(p_numero, i, 1));
      IF ASCII(v_caracter) NOT BETWEEN 48 AND 57 THEN   -- de 0 a 9.
         v_numero_al := v_numero_al || ASCII(v_caracter);
      ELSE
         v_numero_al := v_numero_al || v_caracter;
      END IF;
   END LOOP;

   -- Calcula el DV.
   k       := 2;
   v_total := 0;

   FOR i IN REVERSE LENGTH(v_numero_al)..1 LOOP
      IF k > p_basemax THEN
         k := 2;
      END IF;

      v_numero_aux := TO_NUMBER(SUBSTR(v_numero_al, i, 1), '99G999D9S');
      v_total      := v_total + (v_numero_aux * k);
      k            := k + 1;
   END LOOP;

   v_resto := MOD(v_total,11);

   IF v_resto > 1 THEN
      v_digit := 11 - v_resto;
   ELSE
      v_digit := 0;
   END IF;

   RETURN v_digit;
END;
$$ LANGUAGE plpgsql;

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *
 *                                TABLA (TABLE)                               *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

/* -------------------------------------------------------------------------- */
CREATE TABLE depar (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE depar
   ADD CONSTRAINT pk_depar_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_depar_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_depar_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_depar_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE ciudad (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   departamen SMALLINT NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE ciudad
   ADD CONSTRAINT pk_ciudad_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_ciudad_departamen
      FOREIGN KEY (departamen) REFERENCES depar (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_ciudad_departamen_nombre
      UNIQUE (departamen, nombre),
   ADD CONSTRAINT unq_ciudad_departamen_codigo
      UNIQUE (departamen, codigo),
   ADD CONSTRAINT chk_ciudad_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_ciudad_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE barrio (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   departamen SMALLINT NOT NULL,
   ciudad SMALLINT NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE barrio
   ADD CONSTRAINT pk_barrio_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_barrio_departamen
      FOREIGN KEY (departamen) REFERENCES depar (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_barrio_ciudad
      FOREIGN KEY (ciudad) REFERENCES ciudad (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_barrio_departamen_ciudad
      FOREIGN KEY (departamen, ciudad) REFERENCES ciudad (departamen, codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_barrio_departamen_ciudad_nombre
      UNIQUE (departamen, ciudad, nombre),
   ADD CONSTRAINT unq_barrio_departamen_ciudad_codigo
      UNIQUE (departamen, ciudad, codigo),
   ADD CONSTRAINT chk_barrio_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_barrio_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE cobrador (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   documento VARCHAR(15),
   vigente BOOLEAN NOT NULL
);

ALTER TABLE cobrador
   ADD CONSTRAINT pk_cobrador_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_cobrador_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_cobrador_documento
      UNIQUE (documento),
   ADD CONSTRAINT chk_cobrador_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_cobrador_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_cobrador_documento
      CHECK (documento IS NULL OR documento <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE familia (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   p1 NUMERIC(19,6),
   p2 NUMERIC(19,6),
   p3 NUMERIC(19,6),
   p4 NUMERIC(19,6),
   p5 NUMERIC(19,6),
   vigente BOOLEAN NOT NULL
);

ALTER TABLE familia
   ADD CONSTRAINT pk_familia_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_familia_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_familia_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_familia_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_familia_p1
      CHECK (p1 IS NULL OR p1 > 0),
   ADD CONSTRAINT chk_familia_p2
      CHECK (p2 IS NULL OR p2 > 0),
   ADD CONSTRAINT chk_familia_p3
      CHECK (p3 IS NULL OR p3 > 0),
   ADD CONSTRAINT chk_familia_p4
      CHECK (p4 IS NULL OR p4 > 0),
   ADD CONSTRAINT chk_familia_p5
      CHECK (p5 IS NULL OR p5 > 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE maquina (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE maquina
   ADD CONSTRAINT pk_maquina_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_maquina_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_maquina_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_maquina_nombre
      CHECK (nombre <> '');

INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (1, 'MOTOSIERRA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (2, 'DESMALEZADORA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (3, 'BORDEADORA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (4, 'CORTACESPED', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (5, 'FUMIGADORA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (6, 'SOPLADORA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (7, 'CORTASETOS', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (8, 'TRACTOR CORTACESPED', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (9, 'PODADORA DE ALTURA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (10, 'FORRAJERA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (11, 'TALADRO', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (12, 'MOTOBOMBA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (13, 'HIDROLAVADORA', '1');
INSERT INTO maquina (codigo, nombre, vigente)
   VALUES (14, 'BOMBA SUMERGIBLE', '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE marca (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE marca
   ADD CONSTRAINT pk_marca_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_marca_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_marca_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_marca_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE marca_taller (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE marca_taller
   ADD CONSTRAINT pk_marca_taller_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_marca_taller_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_marca_taller_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_marca_taller_nombre
      CHECK (nombre <> '');

INSERT INTO marca_taller (codigo, nombre, vigente)
   VALUES (1, 'HUSQVARNA', '1');
INSERT INTO marca_taller (codigo, nombre, vigente)
   VALUES (2, 'STIHL', '1');
INSERT INTO marca_taller (codigo, nombre, vigente)
   VALUES (3, 'TRAPP', '1');
INSERT INTO marca_taller (codigo, nombre, vigente)
   VALUES (4, 'KAWASHIMA', '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE mecanico (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   documento VARCHAR(15),
   vigente BOOLEAN NOT NULL
);

ALTER TABLE mecanico
   ADD CONSTRAINT pk_mecanico_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_mecanico_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_mecanico_documento
      UNIQUE (documento),
   ADD CONSTRAINT chk_mecanico_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_mecanico_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_mecanico_documento
      CHECK (documento IS NULL OR documento <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE modelo (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   maquina SMALLINT NOT NULL,
   marca SMALLINT NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE modelo
   ADD CONSTRAINT pk_modelo_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_modelo_maquina
      FOREIGN KEY (maquina) REFERENCES maquina (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_modelo_marca
      FOREIGN KEY (marca) REFERENCES marca_taller (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_modelo_maquina_marca_nombre
      UNIQUE (maquina, marca, nombre),
   ADD CONSTRAINT chk_modelo_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_modelo_nombre
      CHECK (nombre <> '');

INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (1, '359', 1, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (2, '365', 1, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (3, '372 XP', 1, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (4, '61', 1, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (5, 'MS 180', 1, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (6, 'MS 250', 1, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (7, 'MS 361', 1, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (8, 'MS 381', 1, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (9, 'MS 660', 1, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (10, '143RII', 2, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (11, '226R', 2, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (12, '236R', 2, 1, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (13, 'FS 160', 2, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (14, 'FS 220', 2, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (15, 'FS 250', 2, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (16, 'FS 280', 2, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (17, 'YCM-200 TU43', 2, 4, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (18, 'FSE 31', 3, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (19, 'FSE 41', 3, 2, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (20, 'MASTER 500L', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (21, 'MASTER 700L', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (22, 'MASTER 800', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (23, 'MASTER 1000L', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (24, 'MASTER 800 PLUS', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (25, 'MASTER 1000 PLUS', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (26, 'SUPER 500', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (27, 'SUPER 700', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (28, 'SUPER 800', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (29, 'SUPER 1000', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (30, 'SUPER 800 PLUS', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (31, 'SUPER 1000 PLUS', 3, 3, '1');
INSERT INTO modelo (codigo, nombre, maquina, marca, vigente)
   VALUES (32, 'SUPER TURBO 1000', 3, 3, '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE moneda (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   simbolo VARCHAR(5) NOT NULL,
   decimales BOOLEAN NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE moneda
   ADD CONSTRAINT pk_moneda_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_moneda_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_moneda_simbolo
      UNIQUE (simbolo),
   ADD CONSTRAINT chk_moneda_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_moneda_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_moneda_simbolo
      CHECK (simbolo <> '');

INSERT INTO moneda (codigo, nombre, simbolo, decimales, vigente)
   VALUES (1, 'GUARANI', 'PYG', '0', '1');
INSERT INTO moneda (codigo, nombre, simbolo, decimales, vigente)
   VALUES (2, 'DOLAR ESTADOUNIDENSE', 'USD', '1', '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE cotizacion (
   moneda SMALLINT NOT NULL,
   fecha DATE NOT NULL,
   compra NUMERIC(19,6) NOT NULL,
   venta NUMERIC(19,6) NOT NULL
);

ALTER TABLE cotizacion
   ADD CONSTRAINT pk_cotizacion_moneda_fecha
      PRIMARY KEY (moneda, fecha),
   ADD CONSTRAINT fk_cotizacion_moneda
      FOREIGN KEY (moneda) REFERENCES moneda (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT chk_cotizacion_fecha
      CHECK (fecha <= CURRENT_DATE),
   ADD CONSTRAINT chk_cotizacion_compra
      CHECK (compra > 0),
   ADD CONSTRAINT chk_cotizacion_venta
      CHECK (venta > 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE cotizacion_set (
   moneda SMALLINT NOT NULL,
   fecha DATE NOT NULL,
   compra NUMERIC(19,6) NOT NULL,
   venta NUMERIC(19,6) NOT NULL
);

ALTER TABLE cotizacion_set
   ADD CONSTRAINT pk_cotizacion_set_moneda_fecha
      PRIMARY KEY (moneda, fecha),
   ADD CONSTRAINT fk_cotizacion_set_moneda
      FOREIGN KEY (moneda) REFERENCES moneda (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT chk_cotizacion_set_fecha
      CHECK (fecha <= CURRENT_DATE),
   ADD CONSTRAINT chk_cotizacion_set_compra
      CHECK (compra > 0),
   ADD CONSTRAINT chk_cotizacion_set_venta
      CHECK (venta > 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE motivocl (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE motivocl
   ADD CONSTRAINT pk_motivocl_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_motivocl_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_motivocl_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_motivocl_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE pais (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE pais
   ADD CONSTRAINT pk_pais_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_pais_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_pais_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_pais_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE plazo (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   num_vtos SMALLINT NOT NULL,
   separacion CHARACTER(1) NOT NULL,
   primero SMALLINT NOT NULL,
   resto SMALLINT NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE plazo
   ADD CONSTRAINT pk_plazo_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_plazo_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_plazo_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_plazo_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_plazo_num_vtos
      CHECK (num_vtos >= 0),
   ADD CONSTRAINT chk_plazo_separacion
      CHECK (separacion IN ('D', 'M')),
   ADD CONSTRAINT chk_plazo_primero
      CHECK (primero >= 0),
   ADD CONSTRAINT chk_plazo_resto
      CHECK (resto >= 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE proveedor (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   direc1 VARCHAR(60),
   direc2 VARCHAR(60),
   ciudad VARCHAR(25),
   telefono VARCHAR(40),
   fax VARCHAR(25),
   e_mail VARCHAR(60),
   ruc VARCHAR(15),
   dv CHARACTER(1),
   dias_plazo SMALLINT,
   dueno VARCHAR(40),
   teldueno VARCHAR(25),
   gtegral VARCHAR(40),
   telgg VARCHAR(25),
   gteventas VARCHAR(40),
   telgv VARCHAR(25),
   gtemkg VARCHAR(40),
   telgm VARCHAR(25),
   stecnico VARCHAR(40),
   stdirec1 VARCHAR(60),
   stdirec2 VARCHAR(60),
   sttel VARCHAR(25),
   sthablar1 VARCHAR(60),
   vendedor1 VARCHAR(40),
   larti1 VARCHAR(25),
   tvend1 VARCHAR(25),
   vendedor2 VARCHAR(40),
   larti2 VARCHAR(25),
   tvend2 VARCHAR(25),
   vendedor3 VARCHAR(40),
   larti3 VARCHAR(25),
   tvend3 VARCHAR(25),
   vendedor4 VARCHAR(40),
   larti4 VARCHAR(25),
   tvend4 VARCHAR(25),
   vendedor5 VARCHAR(40),
   larti5 VARCHAR(25),
   tvend5 VARCHAR(25),
   saldo_actu NUMERIC(19,6) NOT NULL,
   saldo_usd NUMERIC(19,6) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE proveedor
   ADD CONSTRAINT pk_proveedor_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_proveedor_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_proveedor_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_proveedor_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_proveedor_direc1
      CHECK (direc1 IS NULL OR direc1 <> ''),
   ADD CONSTRAINT chk_proveedor_direc2
      CHECK (direc2 IS NULL OR direc2 <> ''),
   ADD CONSTRAINT chk_proveedor_ciudad
      CHECK (ciudad IS NULL OR ciudad <> ''),
   ADD CONSTRAINT chk_proveedor_telefono
      CHECK (telefono IS NULL OR telefono <> ''),
   ADD CONSTRAINT chk_proveedor_fax
      CHECK (fax IS NULL OR fax <> ''),
   ADD CONSTRAINT chk_proveedor_e_mail
      CHECK (e_mail IS NULL OR e_mail <> ''),
   ADD CONSTRAINT chk_proveedor_ruc
      CHECK (ruc IS NULL OR ruc <> ''),
   ADD CONSTRAINT chk_proveedor_dv
      CHECK (dv IS NULL OR dv <> ''),
   ADD CONSTRAINT chk_proveedor_dias_plazo
      CHECK (dias_plazo IS NULL OR dias_plazo > 0),
   ADD CONSTRAINT chk_proveedor_dueno
      CHECK (dueno IS NULL OR dueno <> ''),
   ADD CONSTRAINT chk_proveedor_teldueno
      CHECK (teldueno IS NULL OR teldueno <> ''),
   ADD CONSTRAINT chk_proveedor_gtegral
      CHECK (gtegral IS NULL OR gtegral <> ''),
   ADD CONSTRAINT chk_proveedor_telgg
      CHECK (telgg IS NULL OR telgg <> ''),
   ADD CONSTRAINT chk_proveedor_gteventas
      CHECK (gteventas IS NULL OR gteventas <> ''),
   ADD CONSTRAINT chk_proveedor_telgv
      CHECK (telgv IS NULL OR telgv <> ''),
   ADD CONSTRAINT chk_proveedor_gtemkg
      CHECK (gtemkg IS NULL OR gtemkg <> ''),
   ADD CONSTRAINT chk_proveedor_telgm
      CHECK (telgm IS NULL OR telgm <> ''),
   ADD CONSTRAINT chk_proveedor_stecnico
      CHECK (stecnico IS NULL OR stecnico <> ''),
   ADD CONSTRAINT chk_proveedor_stdirec1
      CHECK (stdirec1 IS NULL OR stdirec1 <> ''),
   ADD CONSTRAINT chk_proveedor_stdirec2
      CHECK (stdirec2 IS NULL OR stdirec2 <> ''),
   ADD CONSTRAINT chk_proveedor_sttel
      CHECK (sttel IS NULL OR sttel <> ''),
   ADD CONSTRAINT chk_proveedor_sthablar1
      CHECK (sthablar1 IS NULL OR sthablar1 <> ''),
   ADD CONSTRAINT chk_proveedor_vendedor1
      CHECK (vendedor1 IS NULL OR vendedor1 <> ''),
   ADD CONSTRAINT chk_proveedor_larti1
      CHECK (larti1 IS NULL OR larti1 <> ''),
   ADD CONSTRAINT chk_proveedor_tvend1
      CHECK (tvend1 IS NULL OR tvend1 <> ''),
   ADD CONSTRAINT chk_proveedor_vendedor2
      CHECK (vendedor2 IS NULL OR vendedor2 <> ''),
   ADD CONSTRAINT chk_proveedor_larti2
      CHECK (larti2 IS NULL OR larti2 <> ''),
   ADD CONSTRAINT chk_proveedor_tvend2
      CHECK (tvend2 IS NULL OR tvend2 <> ''),
   ADD CONSTRAINT chk_proveedor_vendedor3
      CHECK (vendedor3 IS NULL OR vendedor3 <> ''),
   ADD CONSTRAINT chk_proveedor_larti3
      CHECK (larti3 IS NULL OR larti3 <> ''),
   ADD CONSTRAINT chk_proveedor_tvend3
      CHECK (tvend3 IS NULL OR tvend3 <> ''),
   ADD CONSTRAINT chk_proveedor_vendedor4
      CHECK (vendedor4 IS NULL OR vendedor4 <> ''),
   ADD CONSTRAINT chk_proveedor_larti4
      CHECK (larti4 IS NULL OR larti4 <> ''),
   ADD CONSTRAINT chk_proveedor_tvend4
      CHECK (tvend4 IS NULL OR tvend4 <> ''),
   ADD CONSTRAINT chk_proveedor_vendedor5
      CHECK (vendedor5 IS NULL OR vendedor5 <> ''),
   ADD CONSTRAINT chk_proveedor_larti5
      CHECK (larti5 IS NULL OR larti5 <> ''),
   ADD CONSTRAINT chk_proveedor_tvend5
      CHECK (tvend5 IS NULL OR tvend5 <> ''),
   ADD CONSTRAINT chk_proveedor_saldo_actu
      CHECK (saldo_actu >= 0),
   ADD CONSTRAINT chk_proveedor_saldo_usd
      CHECK (saldo_usd >= 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE rubro (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE rubro
   ADD CONSTRAINT pk_rubro_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_rubro_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_rubro_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_rubro_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE ruta (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE ruta
   ADD CONSTRAINT pk_ruta_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_ruta_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_ruta_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_ruta_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE subrubro (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE subrubro
   ADD CONSTRAINT pk_subrubro_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_subrubro_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_subrubro_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_subrubro_nombre
      CHECK (nombre <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE sucursal (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   direccion VARCHAR(100),
   departamen SMALLINT,
   ciudad SMALLINT,
   barrio SMALLINT,
   moneda SMALLINT NOT NULL,
   venta SMALLINT,
   devolucion_venta SMALLINT,
   compra SMALLINT,
   devolucion_compra SMALLINT,
   ot_terminado SMALLINT,
   ot_en_reparacion SMALLINT,
   ot_devolucion SMALLINT,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE sucursal
   ADD CONSTRAINT pk_sucursal_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_sucursal_departamen
      FOREIGN KEY (departamen) REFERENCES depar (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_ciudad
      FOREIGN KEY (ciudad) REFERENCES ciudad (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_departamen_ciudad
      FOREIGN KEY (departamen, ciudad) REFERENCES ciudad (departamen, codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_barrio
      FOREIGN KEY (barrio) REFERENCES barrio (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_departamen_ciudad_barrio
      FOREIGN KEY (departamen, ciudad, barrio) REFERENCES barrio (departamen, ciudad, codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_moneda
      FOREIGN KEY (moneda) REFERENCES moneda (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_sucursal_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_sucursal_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_sucursal_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_sucursal_direccion
      CHECK (direccion IS NULL OR direccion <> '');

INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (1, 'CASA CENTRAL [001]', 'MECANICOS DE AVIACION Nº 1610 ESQ. DR. FELIX PAIVA', NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '1');
INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (2, 'PAKSA [002]', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0');
INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (3, 'AVDA. EUSEBIO AYALA [003]', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0');
INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (4, 'DEPOSITO DR. FELIX PAIVA [004]', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1');
INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (5, 'SAN BERNARDINO [005]', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0');
INSERT INTO sucursal (codigo, nombre, direccion, departamen, ciudad, barrio, moneda, venta, devolucion_venta, compra, devolucion_compra, ot_terminado, ot_en_reparacion, ot_devolucion, vigente)
   VALUES (6, 'AVDA. EUSEBIO AYALA [006]', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE deposito (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   sucursal SMALLINT NOT NULL,
   venta BOOLEAN NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE deposito
   ADD CONSTRAINT pk_deposito_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_deposito_sucursal
      FOREIGN KEY (sucursal) REFERENCES sucursal (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_deposito_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_deposito_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_deposito_nombre
      CHECK (nombre <> '');

INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (1, 'PRINCIPAL [001]', 1, '1', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (2, 'DEVOLUCION VENTA [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (3, 'COMPRA [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (4, 'DEVOLUCION COMPRA [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (5, 'OT - TERMINADO [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (6, 'OT - EN REPARACION [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (7, 'OT - DEVOLUCION [001]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (8, 'PRINCIPAL [006]', 6, '1', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (9, 'DEVOLUCION VENTA [006]', 6, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (10, 'EN TRANSITO [001] -> [006]', 1, '0', '1');
INSERT INTO deposito (codigo, nombre, sucursal, venta, vigente)
   VALUES (11, 'EN TRANSITO [006] -> [001]', 6, '0', '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE ejercicio (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   periodo SMALLINT NOT NULL,
   fecha_inicio DATE NOT NULL,
   fecha_fin DATE NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE ejercicio
   ADD CONSTRAINT pk_ejercicio_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_ejercicio_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_ejercicio_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_ejercicio_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_ejercicio_periodo
      CHECK (periodo >= 2000 AND periodo <= 2038),
   ADD CONSTRAINT chk_ejercicio_fecha_inicio
      CHECK (fecha_inicio <= fecha_fin),
   ADD CONSTRAINT chk_ejercicio_fecha_fin
      CHECK (fecha_fin >= fecha_inicio),
   ADD CONSTRAINT chk_ejercicio_fecha
      CHECK ((fecha_fin - fecha_inicio) <= 365),
   ADD CONSTRAINT chk_ejercicio_fecha_inicio_periodo
      CHECK (EXTRACT(ISOYEAR FROM fecha_inicio) = periodo);

INSERT INTO ejercicio (codigo, nombre, periodo, fecha_inicio, fecha_fin, vigente)
   VALUES (2015, 'EJERCICIO 2015', 2015, '2015-01-01', '2015-12-31', '1');

/* -------------------------------------------------------------------------- */
CREATE TABLE empresa (
   nombre VARCHAR(100) NOT NULL,
   razon_social VARCHAR(100),
   ruc VARCHAR(15) NOT NULL,
   dv CHARACTER(1) NOT NULL,
   sitio_web VARCHAR(100),
   e_mail VARCHAR(100),
   sucursal SMALLINT NOT NULL,
   ejercicio SMALLINT NOT NULL
);

ALTER TABLE empresa
   ADD CONSTRAINT pk_empresa_ruc_dv
      PRIMARY KEY (ruc, dv),
   ADD CONSTRAINT fk_empresa_sucursal
      FOREIGN KEY (sucursal) REFERENCES sucursal (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_empresa_ejercicio
      FOREIGN KEY (ejercicio) REFERENCES ejercicio (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT chk_empresa_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_empresa_razon_social
      CHECK (razon_social IS NULL OR razon_social <> ''),
   ADD CONSTRAINT chk_empresa_ruc
      CHECK (ruc <> ''),
   ADD CONSTRAINT chk_empresa_dv
      CHECK (dv <> ''),
   ADD CONSTRAINT chk_empresa_sitio_web
      CHECK (sitio_web IS NULL OR sitio_web <> ''),
   ADD CONSTRAINT chk_empresa_e_mail
      CHECK (e_mail IS NULL OR e_mail <> '');

INSERT INTO empresa (nombre, razon_social, ruc, dv, sitio_web, e_mail, sucursal, ejercicio)
   VALUES ('A & A IMPORTACIONES S.R.L.', 'A & A IMPORTACIONES S.R.L.', '80004234', '4', 'www.ayaimportaciones.com.py', 'ayaimportaciones@gmail.com', 1, 2015);

/* -------------------------------------------------------------------------- */
CREATE TABLE unidad (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   simbolo VARCHAR(5) NOT NULL,
   divisible BOOLEAN NOT NULL,
   vigente BOOLEAN NOT NULL
);

ALTER TABLE unidad
   ADD CONSTRAINT pk_unidad_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_unidad_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_unidad_simbolo
      UNIQUE (simbolo),
   ADD CONSTRAINT chk_unidad_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_unidad_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_unidad_simbolo
      CHECK (simbolo <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE articulo (
   codigo INTEGER NOT NULL,
   nombre VARCHAR(100) NOT NULL,
   cod_articulo VARCHAR(20) NOT NULL,
   cod_barra VARCHAR(20),
   cod_original VARCHAR(20),
   cod_alternativo VARCHAR(20),
   aplicacion VARCHAR(480),
   familia SMALLINT NOT NULL,
   rubro SMALLINT NOT NULL,
   subrubro SMALLINT NOT NULL,
   marca SMALLINT NOT NULL,
   unidad SMALLINT NOT NULL,
   proveedor SMALLINT NOT NULL,
   pais SMALLINT NOT NULL,
   ubicacion VARCHAR(20),
   vigente BOOLEAN NOT NULL,
   lprecio BOOLEAN NOT NULL,
   gravado BOOLEAN NOT NULL,
   porc_iva NUMERIC(19,6),
   pcostog NUMERIC(19,6),
   pcostod NUMERIC(19,6),
   pventag1 NUMERIC(19,6),
   pventag2 NUMERIC(19,6),
   pventag3 NUMERIC(19,6),
   pventag4 NUMERIC(19,6),
   pventag5 NUMERIC(19,6),
   pventad1 NUMERIC(19,6),
   pventad2 NUMERIC(19,6),
   pventad3 NUMERIC(19,6),
   pventad4 NUMERIC(19,6),
   pventad5 NUMERIC(19,6),
   stock_min NUMERIC(19,6),
   stock_max NUMERIC(19,6),
   polinvsmin BOOLEAN NOT NULL,
   polinvsmax BOOLEAN NOT NULL,
   caracter1 VARCHAR(60),
   caracter2 VARCHAR(60),
   caracter3 VARCHAR(60),
   otros1 VARCHAR(60),
   otros2 VARCHAR(60),
   fecucompra DATE,
   fecuventa DATE,
   stock_actual NUMERIC(19,6) NOT NULL,
   stock_ot NUMERIC(19,6) NOT NULL,
   stock_comprometido NUMERIC(19,6) NOT NULL,
   stock_solicitado NUMERIC(19,6) NOT NULL
);

ALTER TABLE articulo
   ADD CONSTRAINT pk_articulo_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_articulo_familia
      FOREIGN KEY (familia) REFERENCES familia (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_rubro
      FOREIGN KEY (rubro) REFERENCES rubro (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_subrubro
      FOREIGN KEY (subrubro) REFERENCES subrubro (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_marca
      FOREIGN KEY (marca) REFERENCES marca (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_unidad
      FOREIGN KEY (unidad) REFERENCES unidad (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_proveedor
      FOREIGN KEY (proveedor) REFERENCES proveedor (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_articulo_pais
      FOREIGN KEY (pais) REFERENCES pais (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_articulo_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_articulo_cod_articulo
      UNIQUE (cod_articulo),
   ADD CONSTRAINT unq_articulo_cod_barra
      UNIQUE (cod_barra),
   ADD CONSTRAINT unq_articulo_cod_original
      UNIQUE (cod_original),
   ADD CONSTRAINT unq_articulo_cod_alternativo
      UNIQUE (cod_alternativo),
   ADD CONSTRAINT chk_articulo_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_articulo_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_articulo_cod_articulo
      CHECK (cod_articulo <> ''),
   ADD CONSTRAINT chk_articulo_cod_barra
      CHECK (cod_barra IS NULL OR cod_barra <> ''),
   ADD CONSTRAINT chk_articulo_cod_original
      CHECK (cod_original IS NULL OR cod_original <> ''),
   ADD CONSTRAINT chk_articulo_cod_alternativo
      CHECK (cod_alternativo IS NULL OR cod_alternativo <> ''),
   ADD CONSTRAINT chk_articulo_aplicacion
      CHECK (aplicacion IS NULL OR aplicacion <> ''),
   ADD CONSTRAINT chk_articulo_ubicacion
      CHECK (ubicacion IS NULL OR ubicacion <> ''),
   ADD CONSTRAINT chk_articulo_porc_iva
      CHECK (porc_iva IS NULL OR porc_iva IN (5, 10)),
   ADD CONSTRAINT chk_articulo_pcostog
      CHECK (pcostog IS NULL OR pcostog > 0),
   ADD CONSTRAINT chk_articulo_pcostod
      CHECK (pcostod IS NULL OR pcostod > 0),
   ADD CONSTRAINT chk_articulo_pventag1
      CHECK (pventag1 IS NULL OR pventag1 > 0),
   ADD CONSTRAINT chk_articulo_pventag2
      CHECK (pventag2 IS NULL OR pventag2 > 0),
   ADD CONSTRAINT chk_articulo_pventag3
      CHECK (pventag3 IS NULL OR pventag3 > 0),
   ADD CONSTRAINT chk_articulo_pventag4
      CHECK (pventag4 IS NULL OR pventag4 > 0),
   ADD CONSTRAINT chk_articulo_pventag5
      CHECK (pventag5 IS NULL OR pventag5 > 0),
   ADD CONSTRAINT chk_articulo_pventad1
      CHECK (pventad1 IS NULL OR pventad1 > 0),
   ADD CONSTRAINT chk_articulo_pventad2
      CHECK (pventad2 IS NULL OR pventad2 > 0),
   ADD CONSTRAINT chk_articulo_pventad3
      CHECK (pventad3 IS NULL OR pventad3 > 0),
   ADD CONSTRAINT chk_articulo_pventad4
      CHECK (pventad4 IS NULL OR pventad4 > 0),
   ADD CONSTRAINT chk_articulo_pventad5
      CHECK (pventad5 IS NULL OR pventad5 > 0),
   ADD CONSTRAINT chk_articulo_stock_min
      CHECK (stock_min IS NULL OR stock_min > 0),
   ADD CONSTRAINT chk_articulo_stock_max
      CHECK (stock_max IS NULL OR stock_max > 0),
   ADD CONSTRAINT chk_articulo_caracter1
      CHECK (caracter1 IS NULL OR caracter1 <> ''),
   ADD CONSTRAINT chk_articulo_caracter2
      CHECK (caracter2 IS NULL OR caracter2 <> ''),
   ADD CONSTRAINT chk_articulo_caracter3
      CHECK (caracter3 IS NULL OR caracter3 <> ''),
   ADD CONSTRAINT chk_articulo_otros1
      CHECK (otros1 IS NULL OR otros1 <> ''),
   ADD CONSTRAINT chk_articulo_otros2
      CHECK (otros2 IS NULL OR otros2 <> ''),
   ADD CONSTRAINT chk_articulo_fecucompra
      CHECK (fecucompra IS NULL OR fecucompra <= CURRENT_DATE),
   ADD CONSTRAINT chk_articulo_fecuventa
      CHECK (fecuventa IS NULL OR fecuventa <= CURRENT_DATE),
   ADD CONSTRAINT chk_articulo_stock_actual
      CHECK (stock_actual >= 0),
   ADD CONSTRAINT chk_articulo_stock_ot
      CHECK (stock_ot >= 0),
   ADD CONSTRAINT chk_articulo_stock_comprometido
      CHECK (stock_comprometido >= 0),
   ADD CONSTRAINT chk_articulo_stock_solicitado
      CHECK (stock_solicitado >= 0);

/* -------------------------------------------------------------------------- */
CREATE TABLE vendedor (
   codigo SMALLINT NOT NULL,
   nombre VARCHAR(50) NOT NULL,
   documento VARCHAR(15),
   vigente BOOLEAN NOT NULL
);

ALTER TABLE vendedor
   ADD CONSTRAINT pk_vendedor_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT unq_vendedor_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT unq_vendedor_documento
      UNIQUE (documento),
   ADD CONSTRAINT chk_vendedor_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_vendedor_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_vendedor_documento
      CHECK (documento IS NULL OR documento <> '');

/* -------------------------------------------------------------------------- */
CREATE TABLE cliente (
   codigo INTEGER NOT NULL,
   nombre VARCHAR(100) NOT NULL,
   direc1 VARCHAR(60),
   direc2 VARCHAR(60),
   direc3 VARCHAR(60),
   direc4 VARCHAR(60),
   direc5 VARCHAR(60),
   direc6 VARCHAR(60),
   direc7 VARCHAR(60),
   direc8 VARCHAR(60),
   direc9 VARCHAR(60),
   departamen SMALLINT,
   ciudad SMALLINT,
   barrio SMALLINT,
   ruta SMALLINT NOT NULL,
   telefono VARCHAR(30),
   fax VARCHAR(30),
   e_mail VARCHAR(40),
   contacto VARCHAR(30),
   fechanac DATE,
   documento VARCHAR(15) NOT NULL,
   ruc VARCHAR(15),
   dv CHARACTER(1),
   plazo SMALLINT,
   vendedor SMALLINT,
   lista SMALLINT NOT NULL,
   limite_cre NUMERIC(19,6) NOT NULL,
   saldo_actu NUMERIC(19,6) NOT NULL,
   saldo_usd NUMERIC(19,6) NOT NULL,
   facturar BOOLEAN NOT NULL,
   fec_ioper DATE,
   motivoclie SMALLINT NOT NULL,
   odatosclie VARCHAR(40),
   obs1 VARCHAR(72),
   obs2 VARCHAR(72),
   obs3 VARCHAR(72),
   obs4 VARCHAR(72),
   obs5 VARCHAR(72),
   obs6 VARCHAR(72),
   obs7 VARCHAR(72),
   obs8 VARCHAR(72),
   obs9 VARCHAR(72),
   obs10 VARCHAR(72),
   ref1 VARCHAR(72),
   ref2 VARCHAR(72),
   ref3 VARCHAR(72),
   ref4 VARCHAR(72),
   ref5 VARCHAR(72),
   cuenta VARCHAR(18),
   vigente BOOLEAN NOT NULL
);

ALTER TABLE cliente
   ADD CONSTRAINT pk_cliente_codigo
      PRIMARY KEY (codigo),
   ADD CONSTRAINT fk_cliente_departamen
      FOREIGN KEY (departamen) REFERENCES depar (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_ciudad
      FOREIGN KEY (ciudad) REFERENCES ciudad (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_departamen_ciudad
      FOREIGN KEY (departamen, ciudad) REFERENCES ciudad (departamen, codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_barrio
      FOREIGN KEY (barrio) REFERENCES barrio (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_departamen_ciudad_barrio
      FOREIGN KEY (departamen, ciudad, barrio) REFERENCES barrio (departamen, ciudad, codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_ruta
      FOREIGN KEY (ruta) REFERENCES ruta (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_plazo
      FOREIGN KEY (plazo) REFERENCES plazo (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_vendedor
      FOREIGN KEY (vendedor) REFERENCES vendedor (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_cliente_motivoclie
      FOREIGN KEY (motivoclie) REFERENCES motivocl (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT unq_cliente_nombre
      UNIQUE (nombre),
   ADD CONSTRAINT chk_cliente_codigo
      CHECK (codigo > 0),
   ADD CONSTRAINT chk_cliente_nombre
      CHECK (nombre <> ''),
   ADD CONSTRAINT chk_cliente_direc1
      CHECK (direc1 IS NULL OR direc1 <> ''),
   ADD CONSTRAINT chk_cliente_direc2
      CHECK (direc2 IS NULL OR direc2 <> ''),
   ADD CONSTRAINT chk_cliente_direc3
      CHECK (direc3 IS NULL OR direc3 <> ''),
   ADD CONSTRAINT chk_cliente_direc4
      CHECK (direc4 IS NULL OR direc4 <> ''),
   ADD CONSTRAINT chk_cliente_direc5
      CHECK (direc5 IS NULL OR direc5 <> ''),
   ADD CONSTRAINT chk_cliente_direc6
      CHECK (direc6 IS NULL OR direc6 <> ''),
   ADD CONSTRAINT chk_cliente_direc7
      CHECK (direc7 IS NULL OR direc7 <> ''),
   ADD CONSTRAINT chk_cliente_direc8
      CHECK (direc8 IS NULL OR direc8 <> ''),
   ADD CONSTRAINT chk_cliente_direc9
      CHECK (direc9 IS NULL OR direc9 <> ''),
   ADD CONSTRAINT chk_cliente_telefono
      CHECK (telefono IS NULL OR telefono <> ''),
   ADD CONSTRAINT chk_cliente_fax
      CHECK (fax IS NULL OR fax <> ''),
   ADD CONSTRAINT chk_cliente_e_mail
      CHECK (e_mail IS NULL OR e_mail <> ''),
   ADD CONSTRAINT chk_cliente_contacto
      CHECK (contacto IS NULL OR contacto <> ''),
   ADD CONSTRAINT chk_cliente_fechanac
      CHECK (fechanac IS NULL OR fechanac <= CURRENT_DATE),
   ADD CONSTRAINT chk_cliente_documento
      CHECK (documento <> ''),
   ADD CONSTRAINT chk_cliente_ruc
      CHECK (ruc IS NULL OR ruc <> ''),
   ADD CONSTRAINT chk_cliente_dv
      CHECK (dv IS NULL OR dv <> ''),
   ADD CONSTRAINT chk_cliente_lista
      CHECK (lista BETWEEN 1 AND 5),
   ADD CONSTRAINT chk_cliente_limite_cre
      CHECK (limite_cre >= 0),
   ADD CONSTRAINT chk_cliente_saldo_actu
      CHECK (saldo_actu >= 0),
   ADD CONSTRAINT chk_cliente_fec_ioper
      CHECK (fec_ioper IS NULL OR fec_ioper <= CURRENT_DATE),
   ADD CONSTRAINT chk_cliente_odatosclie
      CHECK (odatosclie IS NULL OR odatosclie <> ''),
   ADD CONSTRAINT chk_cliente_obs1
      CHECK (obs1 IS NULL OR obs1 <> ''),
   ADD CONSTRAINT chk_cliente_obs2
      CHECK (obs2 IS NULL OR obs2 <> ''),
   ADD CONSTRAINT chk_cliente_obs3
      CHECK (obs3 IS NULL OR obs3 <> ''),
   ADD CONSTRAINT chk_cliente_obs4
      CHECK (obs4 IS NULL OR obs4 <> ''),
   ADD CONSTRAINT chk_cliente_obs5
      CHECK (obs5 IS NULL OR obs5 <> ''),
   ADD CONSTRAINT chk_cliente_obs6
      CHECK (obs6 IS NULL OR obs6 <> ''),
   ADD CONSTRAINT chk_cliente_obs7
      CHECK (obs7 IS NULL OR obs7 <> ''),
   ADD CONSTRAINT chk_cliente_obs8
      CHECK (obs8 IS NULL OR obs8 <> ''),
   ADD CONSTRAINT chk_cliente_obs9
      CHECK (obs9 IS NULL OR obs9 <> ''),
   ADD CONSTRAINT chk_cliente_obs10
      CHECK (obs10 IS NULL OR obs10 <> ''),
   ADD CONSTRAINT chk_cliente_ref1
      CHECK (ref1 IS NULL OR ref1 <> ''),
   ADD CONSTRAINT chk_cliente_ref2
      CHECK (ref2 IS NULL OR ref2 <> ''),
   ADD CONSTRAINT chk_cliente_ref3
      CHECK (ref3 IS NULL OR ref3 <> ''),
   ADD CONSTRAINT chk_cliente_ref4
      CHECK (ref4 IS NULL OR ref4 <> ''),
   ADD CONSTRAINT chk_cliente_ref5
      CHECK (ref5 IS NULL OR ref5 <> ''),
   ADD CONSTRAINT chk_cliente_cuenta
      CHECK (cuenta IS NULL OR cuenta <> '');

/* -------------------------------------------------------------------------- */
ALTER TABLE sucursal
   ADD CONSTRAINT fk_sucursal_venta
      FOREIGN KEY (venta) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_devolucion_venta
      FOREIGN KEY (devolucion_venta) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_compra
      FOREIGN KEY (compra) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_devolucion_compra
      FOREIGN KEY (devolucion_compra) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_ot_terminado
      FOREIGN KEY (ot_terminado) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_ot_en_reparacion
      FOREIGN KEY (ot_en_reparacion) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION,
   ADD CONSTRAINT fk_sucursal_ot_devolucion
      FOREIGN KEY (ot_devolucion) REFERENCES deposito (codigo)
         ON DELETE NO ACTION
         ON UPDATE NO ACTION;