CREATE OR REPLACE PACKAGE pkg_importacao IS

    ---DECLARAÇÕES DE TIPOS.
    negocio_exception EXCEPTION;
    rEmpresa tb_empresa%ROWTYPE;
    rEnderecoEmpresa tb_endereco_empresa%ROWTYPE;
    
    ---DECLARAÇÕES DE FUNÇÕES.
    
    ---Valida se a string passada como argumento coincide com Layout padrão definido.
    ---@PARAM: vLayout
    FUNCTION fValidarLayoutImportacao(vLayout varchar) return NUMBER;
        
------------------------------------------------------------------------------------------------------------------------------------------------
    ---DECLARAÇÕES DE PROCEDURES.
    --- Obtem um array indexado a partir de uma string delimitada por ponto e vírgula.   
    PROCEDURE pObterArrayStringDelimitado(vStringDelimitado varchar, vArrayString out TArrayString);
    
    ---Importar os dados passados como parametro.
    PROCEDURE pImportar(vLayout varchar, vLinha varchar);
------------------------------------------------------------------------------------------------------------------------------------------------
    ---DECLARAÇÕES VARIÁVEIS GLOBAIS
    /*
     Layout de importação padrão número 1.
    */
    vArrayLayoutPadrao TArrayString := TArrayString('NM_FANTASIA', 'NM_RAZAO_SOCIAL', 'NR_CNPJ', 'DS_ENDERECO', 'DS_COMPLEMENTO');    
    
    
    
    
END pkg_importacao;
/


CREATE OR REPLACE PACKAGE BODY pkg_importacao IS 

    ---Valida se a string passada como argumento coincide com Layout padrão definido.
    ---@PARAM: vLayout
    FUNCTION fValidarLayoutImportacao(vLayout varchar) return NUMBER IS      
            vArrayString TArrayString := TArrayString();
            vErro EXCEPTION;
    BEGIN                        
         pObterArrayStringDelimitado(vLayout , vArrayString);
                
        FOR vIndice in pkg_importacao.vArrayLayoutPadrao.FIRST..pkg_importacao.vArrayLayoutPadrao.LAST
        LOOP
            IF(LTRIM(RTRIM(UPPER(pkg_importacao.vArrayLayoutPadrao(vIndice)))) != LTRIM(RTRIM(UPPER(vArrayString(vIndice))))) THEN
                RAISE vErro;
            END IF;
        END LOOP;

         RETURN PKG_CONSTANTE.CONSTANTE_SUCESSO;
         
         EXCEPTION 
            WHEN vErro THEN
                RETURN PKG_CONSTANTE.CONSTANTE_ERRO;
            WHEN OTHERS THEN
                RETURN PKG_CONSTANTE.CONSTANTE_ERRO;
    end;
    
----------------------------------------------------------------------------------------------------------------------------------
    ---Transforma em array a string delimitada por ponto e vírgula passada como argumento.
    ---@PARAM: vStringDelimitado
    ---@PARAM: vArrayString
    PROCEDURE pObterArrayStringDelimitado(vStringDelimitado varchar, vArrayString out TArrayString) is
        vTamanho number(2) := 0;
        i number(2):=0;
        vStrDelimitado varchar(200) := vStringDelimitado;
    begin  
        ---Inicialiando o array com o construtor do tipo(Classe).
        vArrayString := TArrayString();
        loop
            exit when vStrDelimitado is null;
            i := i+1;
            vTamanho := instr(vStrDelimitado, ';');
             if vTamanho = 0 then
                vTamanho := length(vStrDelimitado)+1;
             end if;
            vArrayString.extend;
            vArrayString(i) := ltrim(rtrim(substr(vStrDelimitado, 1, vTamanho-1)));
            vStrDelimitado := substr(vStrDelimitado, vTamanho+1, length(vStrDelimitado));
        end loop;
    end;
    
----------------------------------------------------------------------------------------------------------------------------------
    ---Importar os dados passados como parametro.
    PROCEDURE pImportar(vLayout varchar, vLinha varchar) IS
        vArrayString TArrayString := TArrayString();
        vIdentificador tb_empresa.id_empresa%TYPE := NULL;
    BEGIN

        IF fValidarLayoutImportacao(vLayout) = PKG_CONSTANTE.CONSTANTE_SUCESSO  AND vLinha IS NOT NULL THEN
          pObterArrayStringDelimitado(vLinha, vArrayString);
          IF vArrayString.COUNT = 5 THEN
            ---Empresa
            rEmpresa.nm_fantasia := vArrayString(1);
            rEmpresa.nm_razao_social := vArrayString(2);
            rEmpresa.nr_cnpj := vArrayString(3);

            --Endereco
            rEnderecoEmpresa.DS_ENDERECO := vArrayString(4);
            rEnderecoEmpresa.DS_COMPLEMENTO := vArrayString(5);
            
            vIdentificador := pkg_empresa.fsalvar(rEmpresa);
            commit;
            --IF vIdentificador THEN
            --END IF;

            
          ELSE
            RAISE negocio_exception;
          END IF;
        ELSE
          RAISE negocio_exception;
        END IF;
        
    EXCEPTION 
        WHEN negocio_exception THEN
           DBMS_OUTPUT.PUT_LINE('Layout ou dados enviados estão incorretos');
        WHEN OTHERS THEN
           DBMS_OUTPUT.PUT_LINE('Erro!');
           ROLLBACK;
    END;
----------------------------------------------------------------------------------------------------------------------------------


END pkg_importacao;
/
