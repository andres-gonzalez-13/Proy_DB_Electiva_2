CREATE OR REPLACE PACKAGE paq_transacciones IS
-- def. funcioens de consulta de transacciones
    FUNCTION fn_get_units_by_date_tipo (
        idprod      IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE,
        tipo        IN   VARCHAR2
    ) RETURN NUMBER;

    FUNCTION get_units_sold_by_date_sucur (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER;

    FUNCTION get_units_bought_by_date_sucur (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER;

    FUNCTION get_units_transfer_by_date (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER;

    -- corregir con objetos de otras "clases"
    -- def. procedimientos para comprar, vender y transferir productos

    PROCEDURE buy_new_product (
        units        IN   NUMBER,
        nameprod     IN   VARCHAR2,
        price        IN   NUMBER,
        idsucursal   IN   NUMBER
    );

    PROCEDURE buy_product (
        units        IN   NUMBER,
        idproduct    IN   NUMBER,
        idsucursal   IN   NUMBER
    );

    PROCEDURE tranfer_product (
        units            IN   NUMBER,
        idproduct        IN   NUMBER,
        idsucursalori    IN   NUMBER,
        idsucursaldest   IN   NUMBER
    );

    PROCEDURE sell_product (
        units        IN   NUMBER,
        idproduct    IN   NUMBER,
        idsucursal   IN   NUMBER
    );

END;

--------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY paq_transacciones IS
------ funcion para buscar unidades movidas por fecha y tipo de transaccion

    FUNCTION fn_get_units_by_date_tipo (
        idprod      IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE,
        tipo        IN   VARCHAR2
    ) RETURN NUMBER IS
-- Declaración de variables locales
        units NUMBER := 0;
    BEGIN
        SELECT
            SUM(units_producto)
        INTO units
        FROM
            transacciones
        WHERE
            tipo_transaccion = tipo
            AND id_pro_tran = idprod
            AND fecha_transaccion BETWEEN datestart AND dateend;

        RETURN units;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('no se encontro unidades');
    END fn_get_units_by_date_tipo;

------ funcion para buscar unidades movidas por fecha, tipo de transaccion y sucursal

    FUNCTION get_units_sold_by_date_sucur (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER IS
-- Declaración de variables locales
        units NUMBER := 0;
    BEGIN
        SELECT
            SUM(units_producto)
        INTO units
        FROM
            transacciones
        WHERE
            id_pro_tran = idprod
            AND fecha_transaccion BETWEEN datestart AND dateend
            AND id_suc_origen = idsucur
            AND tipo_transaccion = 'V';

        RETURN units;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('no se encontro unidades vendidas');
    END get_units_sold_by_date_sucur;

    FUNCTION get_units_bought_by_date_sucur (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER IS
-- Declaración de variables locales
        units NUMBER := 0;
    BEGIN
        SELECT
            SUM(units_producto)
        INTO units
        FROM
            transacciones
        WHERE
            id_pro_tran = idprod
            AND fecha_transaccion BETWEEN datestart AND dateend
            AND id_suc_destino = idsucur
            AND tipo_transaccion = 'C';

        RETURN units;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('no se encontro unidades compradas');
    END get_units_bought_by_date_sucur;

    FUNCTION get_units_transfer_by_date (
        idprod      IN   NUMBER,
        idsucur     IN   NUMBER,
        datestart   IN   DATE,
        dateend     IN   DATE
    ) RETURN NUMBER IS
-- Declaración de variables locales
        units NUMBER := 0;
    BEGIN
        SELECT
            SUM(units_producto)
        INTO units
        FROM
            transacciones
        WHERE
            id_pro_tran = idprod
            AND fecha_transaccion BETWEEN datestart AND dateend
            AND id_suc_destino = idsucur
            AND tipo_transaccion = 'T';

        RETURN units;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('no se encontro unidades compradas');
    END get_units_transfer_by_date;
    
    -- Procedimientos de compra venta y transafenrecia
    
    -- procedimiento para comprar un NUEVO producto

    PROCEDURE buy_new_product (
        units        IN   NUMBER,
        nameprod     IN   VARCHAR2,
        price        IN   NUMBER,
        idsucursal   IN   NUMBER
    ) IS
-- Declaración de variables locales
        id_prod     NUMBER := 0;
        id_tran     NUMBER := 0;
        num_coinc   NUMBER := 0;
    BEGIN
--se busca y guarda la ultima id colocada en productos
        BEGIN
            SELECT
                MAX(id_producto)
            INTO id_prod
            FROM
                productos;

        EXCEPTION
            WHEN no_data_found THEN
                id_prod := 0;
        END;
-- se busca y guarda la ultima id colocada en trasacciones

        BEGIN
            SELECT
                MAX(id_transaccion)
            INTO id_tran
            FROM
                transacciones;

        EXCEPTION
            WHEN no_data_found THEN
                id_tran := 0;
        END;
-- buscar  y guardar coincidencia de nombre repetido

        BEGIN
            SELECT
                COUNT(id_producto)
            INTO num_coinc
            FROM
                productos
            WHERE
                nombre_producto = nameprod;

        EXCEPTION
            WHEN no_data_found THEN
                num_coinc := 0;
        END;
-- si hay nombre repetido salta la excepcion

        IF num_coinc != 0 THEN
            raise_application_error(-20010, 'informacion repetida usar, funcion de compra para productos registrado');
        END IF;
    -- se llaman funciones de creacion o insert directos
        INSERT INTO productos VALUES (
            ( id_prod + 1 ),
            nameprod,
            price
        );

        INSERT INTO sucursal_producto VALUES (
            idsucursal,
            ( id_prod + 1 ),
            0,
            price
        );

        INSERT INTO transacciones VALUES (
            id_tran + 1,
            idsucursal,
            NULL,
            units,
            ( id_prod + 1 ),
            sysdate,
            'C'
        );

    END buy_new_product;

--===============================================
-- procedimiento para comprar un producto que ya esta registrado

    PROCEDURE buy_product (
        units        IN   NUMBER,
        idproduct    IN   NUMBER,
        idsucursal   IN   NUMBER
    ) IS
-- Declaración de variables locales
        id_tran     NUMBER := 0;
        num_coinc   NUMBER := 0;
    BEGIN
-- se busca y guarda la ultima id colocada en trasacciones
        BEGIN
            SELECT
                MAX(id_transaccion)
            INTO id_tran
            FROM
                transacciones;

        EXCEPTION
            WHEN no_data_found THEN
                id_tran := 0;
        END;
-- comprovar y guarda si existe el prodcuto

        BEGIN
            SELECT
                COUNT(id_prod_inv)
            INTO num_coinc
            FROM
                sucursal_producto
            WHERE
                id_prod_inv = idproduct;

        EXCEPTION
            WHEN no_data_found THEN
                num_coinc := 0;
        END;

        IF num_coinc = 0 THEN
            raise_application_error(-20011, 'no se puede hacer la compra, el producto no esta registrado');
        END IF;
    -- insercion y cambio automatico usando el trigger de transacciones
        INSERT INTO transacciones VALUES (
            id_tran + 1,
            idsucursal,
            NULL,
            units,
            idproduct,
            sysdate,
            'C'
        );

    END buy_product;

------------------------------------------------------
-- procedimientop para tranferir un producto

    PROCEDURE tranfer_product (
        units            IN   NUMBER,
        idproduct        IN   NUMBER,
        idsucursalori    IN   NUMBER,
        idsucursaldest   IN   NUMBER
    ) IS
-- Declaración de variables locales
        id_tran     NUMBER := 0;
        num_coinc   NUMBER := 0;
    BEGIN
-- se busca y guarda la ultima id colocada en trasacciones
        BEGIN
            SELECT
                MAX(id_transaccion)
            INTO id_tran
            FROM
                transacciones;

        EXCEPTION
            WHEN no_data_found THEN
                id_tran := 0;
        END;
-- comprovar si existe el prodcuto

        BEGIN
            SELECT
                COUNT(id_prod_inv)
            INTO num_coinc
            FROM
                sucursal_producto
            WHERE
                id_prod_inv = idproduct
                AND id_sucursal = idsucursalori;

        EXCEPTION
            WHEN no_data_found THEN
                num_coinc := 0;
        END;
-- si esa id no existe se salta la excepcion

        IF num_coinc = 0 THEN
            raise_application_error(-20013, 'no se puede hacer la tranferencia, el producto no esta registrado');
        END IF;
-- insercion y cambio automatico usando el trigger de transacciones
        INSERT INTO transacciones VALUES (
            id_tran + 1,
            idsucursalori,
            idsucursaldest,
            units,
            idproduct,
            sysdate,
            'T'
        );

    END tranfer_product;

-----------------------------------------
-- procedimiento para vender un producto

    PROCEDURE sell_product (
        units        IN   NUMBER,
        idproduct    IN   NUMBER,
        idsucursal   IN   NUMBER
    ) IS
-- Declaración de variables locales
        id_tran           NUMBER := 0;
        num_coinc         NUMBER := 0;
        num_disp_origin   NUMBER := 0;
    BEGIN
-- se busca y guarda la ultima id colocada en trasacciones
        BEGIN
            SELECT
                MAX(id_transaccion)
            INTO id_tran
            FROM
                transacciones;

        EXCEPTION
            WHEN no_data_found THEN
                id_tran := 0;
        END;
-- comprobar si existe el prodcuto

        BEGIN
            SELECT
                COUNT(id_prod_inv)
            INTO num_coinc
            FROM
                sucursal_producto
            WHERE
                id_prod_inv = idproduct;

        EXCEPTION
            WHEN no_data_found THEN
                num_coinc := 0;
        END;
-- cancelar la trasaccion si no lo hay

        IF num_coinc = 0 THEN
            raise_application_error(-20011, 'no se puede hacer la venta, el producto no esta registrado');
        END IF;
-- insercion y cambio automatico usando el trigger de transacciones
        INSERT INTO transacciones VALUES (
            id_tran + 1,
            NULL,
            idsucursal,
            units,
            idproduct,
            sysdate,
            'V'
        );

    END sell_product;
--==============================

END paq_transacciones;