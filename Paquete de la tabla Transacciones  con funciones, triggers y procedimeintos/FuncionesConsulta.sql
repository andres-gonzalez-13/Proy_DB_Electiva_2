------ funcion para buscar unidades movidas por fecha y tipo de transaccion
CREATE OR REPLACE FUNCTION fn_get_units_by_date_tipo (
    idProd IN number,
    dateStart   IN   date,
    dateEnd   IN   date,
    tipo    IN   VARCHAR2
) RETURN NUMBER IS
-- Declaración de variables locales
    units   NUMBER := 0;
BEGIN
    SELECT
        SUM(UNITS_PRODUCTO)
    INTO units
    FROM
        transacciones
    WHERE
        tipo_transaccion = tipo
        and id_pro_tran = idProd
        and fecha_transaccion between datestart and dateend;
    RETURN units;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('no se encontro unidades');
END fn_get_units_by_date_tipo;



------ funcion para buscar unidades movidas por fecha, tipo de transaccion y sucursal
CREATE OR REPLACE FUNCTION get_units_sold_by_date_sucur (
    idProd IN number,
    idSucur IN number,
    dateStart   IN   date,
    dateEnd   IN   date
) RETURN NUMBER IS
-- Declaración de variables locales
    units   NUMBER := 0;
BEGIN
    SELECT
        SUM(UNITS_PRODUCTO)
    INTO units
    FROM
        transacciones
    WHERE
        id_pro_tran = idProd
        and fecha_transaccion between datestart and dateEnd
        and id_suc_origen = idsucur
        and tipo_transaccion = 'V';
    RETURN units;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('no se encontro unidades vendidas');
END get_units_sold_by_date_sucur;

CREATE OR REPLACE FUNCTION get_units_bought_by_date_sucur (
    idProd IN number,
    idSucur IN number,
    dateStart   IN   date,
    dateEnd   IN   date
) RETURN NUMBER IS
-- Declaración de variables locales
    units   NUMBER := 0;
BEGIN
    SELECT
        SUM(UNITS_PRODUCTO)
    INTO units
    FROM
        transacciones
    WHERE
        id_pro_tran = idProd
        and fecha_transaccion between datestart and dateEnd
        and id_suc_destino = idsucur
        and tipo_transaccion = 'C';
    RETURN units;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('no se encontro unidades compradas');
END get_units_bought_by_date_sucur;


CREATE OR REPLACE FUNCTION get_units_transfer_by_date (
    idProd IN number,
    idSucur IN number,
    dateStart   IN   date,
    dateEnd   IN   date
) RETURN NUMBER IS
-- Declaración de variables locales
    units   NUMBER := 0;
BEGIN
    SELECT
        SUM(UNITS_PRODUCTO)
    INTO units
    FROM
        transacciones
    WHERE
        id_pro_tran = idProd
        and fecha_transaccion between datestart and dateEnd
        and id_suc_destino = idsucur
        and tipo_transaccion = 'T';
    RETURN units;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('no se encontro unidades compradas');
END get_units_transfer_by_date;