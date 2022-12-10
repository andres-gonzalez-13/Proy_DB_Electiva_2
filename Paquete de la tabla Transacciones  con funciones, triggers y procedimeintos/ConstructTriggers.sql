--- trigger principal

create or replace TRIGGER tr_suc_prod BEFORE
    INSERT OR UPDATE OR DELETE ON transacciones
    FOR EACH ROW
DECLARE
    v_dif       NUMBER := 0;
    v_num_ori   NUMBER := 0;
    v_num_dest  NUMBER := 0;
    v_coin_ori  NUMBER := 0;
    v_coin_des  NUMBER := 0;

    v_prec_des  NUMBER := 0;
    v_prec_ori  NUMBER := 0;

BEGIN
    -- buscar unidades origen
    BEGIN    
        SELECT
            units_producto
        INTO v_num_ori
        FROM
            sucursal_producto
        WHERE
            ( id_sucursal = :new.id_suc_origen )
            AND ( id_prod_inv = :new.id_pro_tran );
    EXCEPTION
            
        when no_data_found then
            v_num_ori := 0;
            dbms_output.put_line('cero unidades de origen');
    end;
    -- buscar precio origen
    BEGIN
        SELECT
            PRECIO
        INTO v_prec_ori
        FROM
            sucursal_producto
        WHERE
            ( id_sucursal = :new.id_suc_origen )
            AND ( id_prod_inv = :new.id_pro_tran )
        and rownum <= 1;
    EXCEPTION    
        when no_data_found then
            v_prec_ori := 0;
            dbms_output.put_line('no hay precio de origen');
    end;

    -- BUSCAR SI HAY PRODUCTO DE DESTINO
    BEGIN
        SELECT
            count(*)
        INTO v_coin_des
        FROM
            sucursal_producto
        WHERE
            ( id_sucursal = :new.id_suc_destino )
            AND ( id_prod_inv = :new.id_pro_tran );
    EXCEPTION    
        when no_data_found then
           v_coin_des := 0;
            dbms_output.put_line('no hay productos en destino');
    END;
    --añadir producto en inventario pero con cero unidades CON datos de sucursal de origen
    -- es decir solo para trasacciones entre sucursales
    ------------|||---------------
    if v_coin_des = 0 and :new.ID_SUC_DESTINO is not null and v_prec_ori != 0 then
        insert INTO sucursal_producto (ID_PROD_INV, id_sucursal, units_producto, precio)
        VALUES (:new.id_pro_tran, :new.ID_SUC_DESTINO, 0, v_prec_ori );
        v_coin_des := 1;
    end if;

    ----------|||-------------
    
    -- comprobar que el producto existe
    BEGIN
        SELECT
            count(*)
        INTO v_coin_ori
        FROM
            sucursal_producto
        WHERE
            id_prod_inv = :new.id_pro_tran;
    EXCEPTION    
        when no_data_found then
           v_coin_ori := 0;
    END;

    IF inserting THEN
        IF :new.tipo_transaccion = 'T' AND :new.units_producto <= v_num_ori THEN
            -- ORIGEN
            UPDATE sucursal_producto
            SET
                units_producto = units_producto - :new.units_producto
            WHERE
                ( id_sucursal = :new.id_suc_origen )
                AND ( id_prod_inv = :new.id_pro_tran );
            -- DESTINO
            UPDATE sucursal_producto
            SET
                units_producto = units_producto + :new.units_producto
            WHERE
                ( id_sucursal = :new.id_suc_destino )
                AND ( id_prod_inv = :new.id_pro_tran );
        elsif :new.tipo_transaccion = 'V' AND :new.units_producto <= v_num_ori then
            UPDATE sucursal_producto
            SET
                units_producto = units_producto - :new.units_producto
            WHERE
                ( id_sucursal = :new.id_suc_origen )
                AND ( id_prod_inv = :new.id_pro_tran );
        elsif :new.tipo_transaccion = 'C' then
            if v_coin_des = 0 then
                raise_application_error(-20001
                , 'NO se puede añadir directamente si no existe el producto');
            end if;
            UPDATE sucursal_producto
            SET
                units_producto = units_producto + :new.units_producto
            WHERE
                ( id_sucursal = :new.id_suc_destino )
                AND ( id_prod_inv = :new.id_pro_tran );
        ELSE 
            raise_application_error(-20001
                , 'NO se puede completar la trasaccion');
        END IF;

    END IF;

    IF deleting THEN
        raise_application_error(-20002
                , 'NO se puede borrar un historial');
    END IF;

    IF updating THEN
        raise_application_error(-20003
                , 'NO se puede modificar un historial');
    END IF;
END;

-- trigger anti borradp

CREATE OR REPLACE TRIGGER trigger_ddl BEFORE TRUNCATE OR DROP ON construct.SCHEMA BEGIN
    raise_application_error(-20000, 'NO se puede de ni DEBE borrar tablas.');
END;

-- trigger de registro de log

CREATE OR REPLACE TRIGGER tr_transaccion BEFORE
    INSERT ON TRANSACCIONES
    FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO log_events (message_error, codigo_error)  VALUES (
            'se hizo una trasaccion de tipo: ' + :new.TIPO_TRANSACCION,
            4712
        );
        COMMIT;
    END IF;
END;
