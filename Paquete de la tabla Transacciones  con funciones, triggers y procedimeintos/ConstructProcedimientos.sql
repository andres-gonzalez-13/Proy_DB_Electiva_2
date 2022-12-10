-- procedimiento para comprar un NUEVO producto

CREATE OR REPLACE PROCEDURE buy_new_product (
    units        IN   NUMBER,
    nameprod     IN   VARCHAR2,
    price        IN   NUMBER,
    idsucursal   IN   NUMBER
) IS
-- Declaración de variables locales
    id_prod   NUMBER := 0;
    id_tran   NUMBER := 0;
    num_coinc NUMBER := 0;
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
        where nombre_producto = nameprod;
    EXCEPTION
        WHEN no_data_found THEN
            num_coinc := 0;
    END;
-- si hay nombre repetido salta la excepcion
    if num_coinc != 0 then
        raise_application_error(-20010
                , 'informacion repetida usar, funcion de compra para productos registrado');
    end if;
    -- se llaman funciones de creacion o insert directos
    INSERT INTO Productos VALUES ((id_prod+1), nameprod, price);
    INSERT INTO sucursal_producto VALUES (idsucursal, (id_prod + 1), 0, price);
    INSERT INTO transacciones VALUES (id_tran+1, idsucursal,null,units,(id_prod + 1),sysdate,'C');
END buy_new_product;

--===============================================
-- procedimiento para comprar un producto que ya esta registrado

CREATE OR REPLACE PROCEDURE buy_product (
    units        IN   NUMBER,
    idProduct     IN   NUMBER,
    idsucursal   IN   NUMBER
) IS
-- Declaración de variables locales
    id_tran   NUMBER := 0;
    num_coinc number := 0;
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
        where id_prod_inv = idProduct;
    EXCEPTION
        WHEN no_data_found THEN
            num_coinc := 0;
    END;
    if num_coinc = 0 then
        raise_application_error(-20011
                , 'no se puede hacer la compra, el producto no esta registrado');
    end if;
    -- insercion y cambio automatico usando el trigger de transacciones
    INSERT INTO transacciones VALUES (id_tran+1, idsucursal,null ,units, idProduct ,sysdate,'C');
END buy_product;

------------------------------------------------------
-- procedimientop para tranferir un producto
CREATE OR REPLACE PROCEDURE tranfer_product (
    units        IN   NUMBER,
    idProduct     IN   NUMBER,
    idsucursalOri   IN   NUMBER,
    idsucursalDest   IN   NUMBER
) IS
-- Declaración de variables locales
    id_tran   NUMBER := 0;
    num_coinc number := 0;
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
        where id_prod_inv = idProduct
        and id_sucursal = idsucursalOri;
    EXCEPTION
        WHEN no_data_found THEN
            num_coinc := 0;
    END;
-- si esa id no existe se salta la excepcion
    if num_coinc = 0 then
        raise_application_error(-20013
                , 'no se puede hacer la tranferencia, el producto no esta registrado');
    end if;
-- insercion y cambio automatico usando el trigger de transacciones
    
    INSERT INTO transacciones VALUES (id_tran+1, idsucursalOri,idsucursalDest, units, idProduct ,sysdate,'T');
END tranfer_product;

-----------------------------------------
-- procedimiento para vender un producto

CREATE OR REPLACE PROCEDURE sell_product (
    units        IN   NUMBER,
    idProduct     IN   NUMBER,
    idsucursal   IN   NUMBER
) IS
-- Declaración de variables locales
    id_tran   NUMBER := 0;
    num_coinc number := 0;
    num_disp_origin NUMBER := 0;
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
        where id_prod_inv = idProduct;
    EXCEPTION
        WHEN no_data_found THEN
            num_coinc := 0;
    END;
-- cancelar la trasaccion si no lo hay
    if num_coinc = 0 then
        raise_application_error(-20011
                , 'no se puede hacer la venta, el producto no esta registrado');
    end if;
-- insercion y cambio automatico usando el trigger de transacciones
    
    INSERT INTO transacciones VALUES (id_tran+1,null, idsucursal ,units, idProduct ,sysdate,'V');
END sell_product;


-----------------------------------------



--begin
--    buy_product(30,40388,11778);
--end;

--begin
  --  sell_product(10,40388,11778);
--end;

--begin
--    buy_new_product(30,'remaches',500,11778);
--end;

--INSERT INTO transacciones VALUES (23, 11778, null, 20, 99628, sysdate, 'C');