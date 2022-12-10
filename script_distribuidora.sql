DROP TABLE SUCURSALES CASCADE CONSTRAINTS; 
DROP TABLE SUCURSAL_PRODUCTO CASCADE CONSTRAINTS; 
DROP TABLE TRANSACCIONES CASCADE CONSTRAINTS; 
DROP TABLE PRODUCTOS CASCADE CONSTRAINTS;
---alter table TRANSACCIONES
  --drop constraint CK_TIPOTRANS;

CREATE TABLE SUCURSALES(
   id_sucursal NUMBER(5),
   nombre_sucursal VARCHAR2(70),
   CONSTRAINT sucursal_pk PRIMARY KEY(id_sucursal)
);

CREATE TABLE PRODUCTOS(
   id_producto NUMBER(5),
   nombre_producto VARCHAR2(70),
   precio NUMBER(9),
   CONSTRAINT producto_pk PRIMARY KEY(id_producto)
);

CREATE TABLE SUCURSAL_PRODUCTO(
    id_sucursal NUMBER(5),
    id_prod_inv NUMBER(5),
    units_producto NUMBER(5),
    precio NUMBER(9),
    CONSTRAINT suc_produ_pk PRIMARY KEY(id_sucursal,id_prod_inv),
    CONSTRAINT suc_pro_fk FOREIGN KEY (id_prod_inv) REFERENCES productos (id_producto),
    CONSTRAINT suc_suc_fk FOREIGN KEY (id_sucursal) REFERENCES sucursales (id_sucursal)   
);

CREATE TABLE TRANSACCIONES(
    id_transaccion NUMBER(5),
    id_suc_destino NUMBER(5),
    id_suc_origen NUMBER(5),
    units_producto NUMBER(4),
    id_pro_tran NUMBER(5),
    fecha_transaccion DATE DEFAULT SYSDATE,
    tipo_transaccion VARCHAR2(1),
    CONSTRAINT transaccion_pk PRIMARY KEY(id_transaccion),
    CONSTRAINT tran_suc_fk FOREIGN KEY (id_suc_destino) REFERENCES sucursales (id_sucursal),
    CONSTRAINT tran_pro_fk FOREIGN KEY (id_pro_tran) REFERENCES productos (id_producto)
);


ALTER TABLE TRANSACCIONES ADD CONSTRAINT CK_TIPOTRANS
      CHECK (tipo_transaccion IN ('V','T','C'));