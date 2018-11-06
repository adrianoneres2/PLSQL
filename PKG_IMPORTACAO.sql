create or replace PACKAGE pkg_importacao IS

    ---DECLARAÇÕES DE TIPOS.
    negocio_exception EXCEPTION;
    rEmpresa tb_empresa%ROWTYPE;
    rEnderecoEmpresa tb_endereco_empresa%ROWTYPE;
    
    ---teste modificação
    
    
    ---DECLARAÇÕES DE FUNÇÕES.
    
    ---Valida se a string passada como argumento coincide com Layout padrão definido.
    ---@PARAM: vLayout
    FUNCTION fValidarLayoutImportacao(vLayout varchar) return NUMBER;
        
        
---teste de alteração
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
