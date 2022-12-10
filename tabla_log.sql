DROP TABLE LOG_EVENTS CASCADE CONSTRAINTS;
DROP SEQUENCE LOG_SEQUENCE;

CREATE TABLE LOG_EVENTS(
   log_id NUMBER NOT NULL,
   message_error VARCHAR2(200),
   codigo_error NUMBER,
   CONSTRAINT log_event_pk PRIMARY KEY(log_id )
);

CREATE SEQUENCE LOG_SEQUENCE;

CREATE TRIGGER TR_LOG_ID
BEFORE INSERT ON LOG_EVENTS
FOR EACH ROW
BEGIN
  SELECT LOG_SEQUENCE.nextval
  INTO :new.log_id
  FROM dual;
END;
-- Ejemplo de insercion No es necesario ingresar el id ya que este es auto incremental
-- insert into LOG_EVENTS (message_error, codigo_error) values ('ocurrio un problema', 321312);
-- commit;
-- select * from LOG_EVENTS;