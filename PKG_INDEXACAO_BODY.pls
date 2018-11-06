create or replace PACKAGE BODY PKG_INDEXACAO IS
  /**
   *
   **/
  FUNCTION fValidarOrigemCampo(v_frk_tipo_campo idx_tipo.prk_tipo%TYPE
                             , v_ind_origem                   NUMBER
                             , v_frk_tipo_arquivo             NUMBER
                             , v_frk_formulario               NUMBER
                             , v_frk_grupo                    NUMBER
                             , v_frk_tipo_consulta_externa_or NUMBER
                             , v_frk_consulta_externa_or      NUMBER
                             , v_frk_campo                    NUMBER
                             , v_tip_brsafe                   NUMBER
                             , v_frk_documento_brsafe         NUMBER) RETURN BOOLEAN IS
    rConsultaExternaCampo cfg_consulta_externa_campo%ROWTYPE;
    rCampoIndexacao idx_campo%ROWTYPE;

    EXCPT_CAMPO_INVALIDO EXCEPTION;
  BEGIN
      --rConsultaExternaCampo := v_lConsultaExternaCampo(nIndex);
      --rConsultaExternaCampo.frk_consulta_externa := rConsultaExterna.prk_consulta_externa;
      IF v_ind_origem IS NOT NULL THEN
        /** Validação do campo **/
        IF v_ind_origem IS NOT NULL THEN
          IF v_frk_campo IS NULL THEN
            --// Campo não informado
            RAISE EXCPT_CAMPO_INVALIDO;
          END IF;
          rCampoIndexacao := pkg_indexacao.fDadosCampo(v_frk_campo);
          IF v_frk_tipo_campo <> rCampoIndexacao.frk_tipo THEN
            --// Campo Inválido para o tipo de indexação
            RAISE EXCPT_CAMPO_INVALIDO;
          END IF;
          CASE v_ind_origem
            WHEN pkg_indexacao.CONST_ORIGEM_FORM_CADASTRO THEN
              IF v_frk_formulario IS NULL OR v_frk_grupo IS NULL THEN
                RAISE EXCPT_CAMPO_INVALIDO;
              END IF;
            WHEN pkg_indexacao.CONST_ORIGEM_FORM_ARQUIVO THEN
              IF v_frk_formulario IS NULL OR v_frk_grupo IS NULL OR v_frk_tipo_arquivo IS NULL THEN
                RAISE EXCPT_CAMPO_INVALIDO;
              END IF;
            WHEN pkg_indexacao.CONST_ORIGEM_BASE_EXTERNA THEN
              IF v_frk_tipo_consulta_externa_or IS NULL THEN
                RAISE EXCPT_CAMPO_INVALIDO;
              END IF;
            ELSE
               NULL;
          END CASE;
        ELSE
         RAISE EXCPT_CAMPO_INVALIDO;
        END IF; 
     END IF; 
     RETURN TRUE;
  EXCEPTION 
    WHEN OTHERS THEN
      RETURN FALSE;
  END fValidarOrigemCampo;

  /**
   *
   **/
  FUNCTION fFormatValorIndexacao(v_val_indexador VARCHAR2
                               , v_sts_indexador sph_registro_indexador.sts_indexador%TYPE
                               , v_nvl_null VARCHAR2 DEFAULT '-') RETURN VARCHAR2 IS
  BEGIN
    IF v_val_indexador IS NOT NULL THEN
      RETURN v_val_indexador;
    ELSE
      RETURN
        CASE v_sts_indexador
          WHEN pkg_constante.CONST_IDX_ILEGIVEL THEN 'Ilegível'
          WHEN pkg_constante.CONST_IDX_INVALIDO THEN 'Inválido'
          WHEN pkg_constante.CONST_IDX_AUSENTE THEN 'Ausente'
          ELSE v_nvl_null
        END;
    END IF;
  END fFormatValorIndexacao;

  FUNCTION fTipoCampoOperadorJSON(v_frk_tipo idx_tipo.prk_tipo%TYPE
                                , v_lOperadorManual STR_ARRAY DEFAULT STR_ARRAY()) RETURN VARCHAR2 IS
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
    nOperadorManual NUMBER := v_lOperadorManual.COUNT;
  BEGIN
      pkg_base.pInicializarJsonLista(lListaJsonObjeto);
      FOR tab_temp IN(
        SELECT *
          FROM idx_tipo_operador
         INNER JOIN idx_operador
               ON prk_operador = frk_operador
        WHERE frk_tipo = v_frk_tipo
          AND (nOperadorManual = 0
            OR  EXISTS (
                   SELECT NULL
                     FROM TABLE(v_lOperadorManual)
                    WHERE COLUMN_VALUE = cod_operador
                )
              )
--          AND v_lListaOperadorManual.COUNT = 0
      )
      LOOP
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'desc', tab_temp.des_operador);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'val', tab_temp.cod_operador);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'qtd_campos', tab_temp.qtd_campo);
        pkg_base.pAvancarJsonLista(lListaJsonObjeto);
      END LOOP;
      RETURN pkg_base.fProcessarJsonLista(lListaJsonObjeto);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fTipoCampoOperadorJSON;

  /**
   * Função que lista os tipos de campos
   **/
  FUNCTION fListarTipoCampo RETURN pkg_dominio.tSelectDefault PIPELINED IS
  BEGIN
    FOR tab_temp IN (
        SELECT TO_CHAR(prk_tipo)
             , nom_tipo
          FROM idx_tipo
         WHERE sts_tipo = pkg_constante.CONST_ATIVO
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarTipoCampo;
  /**
   * Função para buscar o ID de um grupo, ou cria-lo caso ele não exista
   * @param v_frk_cliente: Código do cliente
   * @param v_nom_grupo: Nome do grupo
   * @return: ID do grupo
   **/
  FUNCTION fGetGrupoId(v_frk_cliente idx_grupo.frk_cliente%TYPE
                     , v_nom_grupo idx_grupo.nom_grupo%TYPE) RETURN idx_grupo.prk_grupo%TYPE IS
    nGrupo idx_grupo.prk_grupo%TYPE;
  BEGIN
    SELECT MAX(prk_grupo)
      INTO nGrupo
      FROM idx_grupo
     WHERE pkg_base.fLimparString(nom_grupo) = pkg_base.fLimparString(v_nom_grupo)
       AND frk_cliente = v_frk_cliente;
    IF nGrupo IS NULL THEN
      INSERT INTO idx_grupo (nom_grupo, frk_cliente)
                     VALUES (v_nom_grupo, v_frk_cliente)
        RETURNING prk_grupo INTO nGrupo;
    END IF;
    RETURN nGrupo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fGetGrupoId;

  /**
   * Função para buscar os dados de um campo
   **/
  FUNCTION fDadosCampo(v_frk_campo idx_campo.prk_campo%TYPE) RETURN idx_campo%ROWTYPE IS
    rCampo idx_campo%ROWTYPE;
  BEGIN
    SELECT *
      INTO rCampo
      FROM idx_campo
     WHERE prk_campo = v_frk_campo;
    RETURN rCampo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosCampo;

  FUNCTION fDadosFormulario(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN idx_formulario%ROWTYPE IS
    rFormulario idx_formulario%ROWTYPE;
  BEGIN
    SELECT *
      INTO rFormulario
      FROM idx_formulario
     WHERE prk_formulario = v_frk_formulario;
    RETURN rFormulario;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosFormulario;

  /**
   * Função para buscar e montar um retorno JSON de opções de um campo
   * @param v_frk_campo: Código do campo
   * @return String JSON do campo em questão
   * Função desativada devido a demanda http://redmine.brscan.com.br/issues/115420
   * Incluida a cláusula "RETURN NULL;" para evitar retorno de registros.
   * Criada a função fGetOpcaoCampo, em substituição, para suprir a atividade
   **/
  FUNCTION fGetOpcaoCampoJSON(v_frk_campo idx_campo.prk_campo%TYPE
                            , v_ind_retornar_id NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN VARCHAR2 IS
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
  BEGIN
      -- http://redmine.brscan.com.br/issues/115420
      RETURN NULL;
      pkg_base.pInicializarJsonLista(lListaJsonObjeto);
      FOR tab_opcao IN(
        SELECT prk_campo_opcao
             , des_campo_opcao
          FROM idx_campo_opcao
         WHERE frk_campo = v_frk_campo
           AND sts_campo_opcao = pkg_constante.CONST_ATIVO
         ORDER BY ind_ordem, des_campo_opcao
      )
      LOOP
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'desc', tab_opcao.des_campo_opcao);
        IF v_ind_retornar_id = pkg_constante.CONST_SIM THEN
          pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'val', tab_opcao.prk_campo_opcao);
        ELSE
          pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'val', tab_opcao.des_campo_opcao);
        END IF;
        pkg_base.pAvancarJsonLista(lListaJsonObjeto);
      END LOOP;
      RETURN pkg_base.fProcessarJsonLista(lListaJsonObjeto);
  END fGetOpcaoCampoJSON;

  /**
   * Função para buscar e montar um retorno tSelectDefault de opções de um campo
   * Substitui a função fGetOpcaoCampoJSON
   * @param v_frk_campo: Código do campo
   * @return pkg_dominio.tSelectDefault
   * @Demanda: http://redmine.brscan.com.br/issues/115420
   **/
  FUNCTION fListarOpcaoCampo(v_frk_campo idx_campo.prk_campo%TYPE) RETURN pkg_dominio.tSelectDefault PIPELINED IS
  BEGIN
      FOR tab_opcao IN(
        SELECT TO_CHAR(prk_campo_opcao)
             , des_campo_opcao
          FROM idx_campo_opcao
         WHERE frk_campo = v_frk_campo
           AND sts_campo_opcao = pkg_constante.CONST_ATIVO
         ORDER BY des_campo_opcao                       --#134226 alterou 'ORDER BY ind_ordem, des_campo_opcao'
      )
      LOOP
        PIPE ROW(tab_opcao);
      END LOOP;
  END fListarOpcaoCampo;

  /**
   * 
   **/
  FUNCTION fListarOpcaoSegmento RETURN pkg_dominio.tSelectDefault PIPELINED IS
  BEGIN
      FOR tab_opcao IN(
        SELECT des_campo_opcao des_label
             , des_campo_opcao des_value
          FROM idx_campo_opcao
         WHERE 1=1
           AND sts_campo_opcao = pkg_constante.CONST_ATIVO
           AND frk_campo = (SELECT MAX(prk_campo)
                              FROM idx_campo
                             WHERE cod_campo = 'nom_segmento')
         ORDER BY 1
      )
      LOOP
        PIPE ROW(tab_opcao);
      END LOOP;  
  END fListarOpcaoSegmento;
  /**
   * Função para buscar uma opção de um campo do tipo select
   **/
  FUNCTION fBuscarCampoOpcao(v_frk_campo idx_campo.prk_campo%TYPE
                           , v_frk_campo_opcao VARCHAR2) RETURN idx_campo_opcao%ROWTYPE IS
    rOpcao idx_campo_opcao%ROWTYPE;
  BEGIN
    BEGIN
      SELECT *
        INTO rOpcao
        FROM idx_campo_opcao
       WHERE prk_campo_opcao = v_frk_campo_opcao
         AND frk_campo = NVL(v_frk_campo, frk_campo);
    EXCEPTION
      WHEN OTHERS THEN
        SELECT *
          INTO rOpcao
          FROM idx_campo_opcao a
         WHERE pkg_base.fRemoverAcento(LOWER(des_campo_opcao)) = pkg_base.fRemoverAcento(LOWER(v_frk_campo_opcao))
           AND frk_campo = NVL(v_frk_campo, frk_campo);
    END;
    RETURN rOpcao;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fBuscarCampoOpcao;

  /**
   * Função que retorna o ID do campo de acordo com o seu código
   * @param v_cod_campo: Código do campo
   * @return: ID do campo
   **/
  FUNCTION fGetCampoByCod(v_cod_campo idx_campo.cod_campo%TYPE) RETURN idx_campo%ROWTYPE IS
   rCampo idx_campo%ROWTYPE;
  BEGIN
    SELECT * INTO rCampo
      FROM idx_campo
     WHERE cod_campo = v_cod_campo
       AND sts_campo = pkg_constante.CONST_SIM;
    RETURN rCampo;    
  END fGetCampoByCod;

  /**
   * Função que retorna o ID do campo de acordo com o seu código
   * @param v_cod_grupo: Código do grupo
   * @return: Record do idx_grupo
   **/
  FUNCTION fGetGrupoByCod(v_cod_grupo idx_campo.cod_campo%TYPE) RETURN idx_grupo%ROWTYPE IS
   rGrupo idx_grupo%ROWTYPE;
  BEGIN
    SELECT * INTO rGrupo
      FROM idx_grupo
     WHERE cod_grupo = v_cod_grupo;
    RETURN rGrupo;
  END fGetGrupoByCod;
 
  /**
   * Função para validar um valor de um campo
   * @param v_frk_campo: Código do Campo
   * @param v_frk_tipo: Tipo do Campo
   * @param v_val_campo: Valor do campo
   * @return TRUE/FALSE
   **/
  FUNCTION fValidarCampo(v_frk_campo idx_campo.prk_campo%TYPE
                       , v_frk_tipo idx_campo.frk_tipo%TYPE
                       , v_val_campo sph_registro_indexador.val_indexador%TYPE
                       , v_rFormularioCampo idx_formulario_campo%ROWTYPE DEFAULT NULL) RETURN BOOLEAN IS
    nTeste NUMBER;
    bRetorno BOOLEAN := TRUE;
    vValorCampo sph_registro_indexador.val_indexador%TYPE;
    nValorNumerico NUMBER;
  BEGIN
    IF v_val_campo IS NULL THEN
      RETURN TRUE;
    END IF;

    CASE v_frk_tipo
      WHEN 'numerico' THEN
        bRetorno := pkg_base.fIsNumerico(v_val_campo);
        IF bRetorno THEN
          IF v_rFormularioCampo.num_valor_minimo IS NOT NULL AND TO_NUMBER(v_val_campo) < TO_NUMBER(v_rFormularioCampo.num_valor_minimo) THEN
            bRetorno := FALSE;
          ELSIF v_rFormularioCampo.num_valor_maximo IS NOT NULL AND TO_NUMBER(v_val_campo) > TO_NUMBER(v_rFormularioCampo.num_valor_maximo) THEN
            bRetorno := FALSE;
          END IF;
        END IF;  
      WHEN 'moeda' THEN
        vValorCampo := REGEXP_REPLACE(TRIM(v_val_campo),'^R\$');
        bRetorno := pkg_base.fIsNumerico(vValorCampo);
        IF bRetorno THEN
          IF v_rFormularioCampo.num_valor_minimo IS NOT NULL AND TO_NUMBER(pkg_base.fRemoverMascaraNumero(vValorCampo)) < TO_NUMBER(pkg_base.fRemoverMascaraNumero((v_rFormularioCampo.num_valor_minimo))) THEN
            bRetorno := FALSE;
          ELSIF v_rFormularioCampo.num_valor_maximo IS NOT NULL AND TO_NUMBER(pkg_base.fRemoverMascaraNumero(vValorCampo)) > TO_NUMBER(pkg_base.fRemoverMascaraNumero((v_rFormularioCampo.num_valor_maximo))) THEN
            bRetorno := FALSE;
          END IF;          
        END IF;
      WHEN 'texto' THEN 
        nValorNumerico := LENGTH(v_val_campo);
        IF v_rFormularioCampo.frk_campo IS NOT NULL AND v_rFormularioCampo.num_valor_minimo IS NOT NULL AND nValorNumerico < TO_NUMBER(v_rFormularioCampo.num_valor_minimo) THEN
          bRetorno := FALSE;
        ELSIF v_rFormularioCampo.num_valor_maximo IS NOT NULL AND nValorNumerico > TO_NUMBER(v_rFormularioCampo.num_valor_maximo) THEN
          bRetorno := FALSE;
        END IF;   
      WHEN 'cpf' THEN
        RETURN pkg_base.fValidarCPF(v_val_campo) OR pkg_base.fValidarCNPJ(v_val_campo);
      WHEN 'data' THEN
        bRetorno := pkg_base.fIsData(TRIM(v_val_campo));
        IF bRetorno THEN
          IF v_rFormularioCampo.num_valor_minimo IS NOT NULL AND TO_DATE(v_val_campo) < TO_DATE(v_rFormularioCampo.num_valor_minimo) THEN
            bRetorno := FALSE;
          ELSIF v_rFormularioCampo.num_valor_maximo IS NOT NULL AND TO_DATE(v_val_campo) > TO_DATE(v_rFormularioCampo.num_valor_maximo) THEN
            bRetorno := FALSE;
          END IF;          
        END IF;        
      WHEN 'email' THEN
        RETURN pkg_base.fValidarEmail(TRIM(v_val_campo));
      WHEN 'select' THEN
        SELECT COUNT(1)
          INTO nTeste
          FROM idx_campo_opcao
         WHERE (des_campo_opcao = TRIM(v_val_campo))
           AND frk_campo = v_frk_campo;
        IF nTeste = 0 THEN
          RETURN FALSE;
        ELSE 
          RETURN TRUE;  
        END IF;
      ELSE
        RETURN TRUE;
    END CASE;
    RETURN bRetorno;
  END fValidarCampo;

  FUNCTION fFormatarCampo(frk_tipo idx_tipo.prk_tipo%TYPE
                        , des_valor sph_registro_indexador.val_indexador%TYPE
                        , cod_valor VARCHAR2 DEFAULT NULL
                        , ind_aspas NUMBER DEFAULT pkg_constante.CONST_NAO
                        , ind_processar_aspas_valor NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN VARCHAR2 IS
    des_valor_out VARCHAR2(1500):=TRIM(des_valor);
  BEGIN
    CASE frk_tipo
      WHEN 'cpf' THEN des_valor_out := pkg_base.fRemoverMascaraNumero(des_valor_out);
      WHEN 'cnpj' THEN des_valor_out := pkg_base.fRemoverMascaraNumero(des_valor_out);
      WHEN 'cpfCnpj' THEN des_valor_out := pkg_base.fRemoverMascaraNumero(des_valor_out);
      WHEN 'telefoneCelular' THEN des_valor_out := pkg_base.fRemoverMascaraNumero(des_valor_out);
      WHEN 'telefoneFixo' THEN des_valor_out := pkg_base.fRemoverMascaraNumero(des_valor_out);
      WHEN 'select' THEN des_valor_out := NVL(des_valor_out, cod_valor);
      WHEN 'moeda' THEN
        des_valor_out := NVL(REPLACE(REGEXP_REPLACE(des_valor, '[^0-9,]', ''), '.','.'),'0');
      WHEN 'numerico' THEN
        des_valor_out := NVL(REPLACE(REGEXP_REPLACE(des_valor, '[^0-9,]', ''), '.','.'),'0');
      WHEN 'data' THEN
        IF des_valor_out = 'SYSDATE' THEN
          des_valor_out := TO_CHAR(TRUNC(SYSDATE), 'dd/mm/yyyy');
        ELSE
          des_valor_out := TO_CHAR(TO_DATE(REGEXP_REPLACE(des_valor_out, '[^0-9\/]', ''), 'dd/mm/yyyy'), 'dd/mm/yyyy');
        END IF;
      ELSE NULL;
    END CASE;
    IF ind_processar_aspas_valor = pkg_constante.CONST_SIM THEN
      des_valor_out := REPLACE(des_valor_out, '''', '''''');
    END IF;
    IF ind_aspas = pkg_constante.CONST_SIM /* AND frk_tipo NOT IN('moeda', 'numerico') */ THEN
      des_valor_out := '''' || des_valor_out || '''';
    END IF;
    RETURN des_valor_out;
  END fFormatarCampo;
  /**
   * Função que retorna os campos disponíveis e suas opções disponíveis
   * @param v_frk_cliente: código do cliente;
   * @param v_ind_relatorio: indica os campos são para exibição de relatório, ou para listagem normal
   * @return: lista de campos
   **/
  FUNCTION fListarCampos(v_frk_cliente idx_campo.frk_cliente%TYPE
                       , v_ind_relatorio NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN tListaCampoOpcao PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT prk_campo
           , frk_tipo
           , nom_tipo
           , nom_campo
           , sts_campo
           , CASE sts_campo
               WHEN 1 THEN 'Ativado'
               ELSE 'Desativado'
             END des_status_campo
           , CASE
               WHEN frk_cliente IS NULL THEN pkg_constante.CONST_NAO
               ELSE pkg_constante.CONST_SIM
             END ind_editavel
           , CASE frk_tipo
           -- http://redmine.brscan.com.br/issues/115420
               WHEN 'select' THEN fGetOpcaoCampoJSON(prk_campo)
           --    WHEN 'select' THEN fGetOpcaoCampo(prk_campo)
               ELSE ''
             END
        FROM idx_campo a
       INNER JOIN idx_tipo
             ON prk_tipo = frk_tipo
       WHERE (frk_cliente IS NULL OR frk_cliente = v_frk_cliente)
         AND (v_ind_relatorio = pkg_constante.CONST_SIM OR sts_campo = pkg_constante.CONST_SIM)
        ORDER BY frk_cliente DESC, nom_campo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN ;
  END fListarCampos;

  /**
   * Função que retorna os dados salvos de um campo e sua opções
   * @param v_frk_campo: Código do campo consultado
   * @param v_rCampo: Record com os Dados dos Campos
   * @v_Opcoes: Retorno JSON de opções do campo
   * @return: pkg_dominio.recRetorno;
   **/
  FUNCTION fDadosCampo(v_frk_campo idx_campo.prk_campo%TYPE
                     , v_rCampo IN OUT idx_campo%ROWTYPE
                     , v_des_opcoes IN OUT VARCHAR2) RETURN pkg_dominio.recRetorno IS
  BEGIN
    SELECT *
      INTO v_rCampo
      FROM idx_campo
     WHERE prk_campo = v_frk_campo;
     v_des_opcoes := pkg_indexacao.fGetOpcaoCampoJSON(v_frk_campo, pkg_constante.CONST_NAO);

    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fDadosCampo;

  /**
   * Verifica se existe outro campo com o mesmo nome para o cliente
   * @param v_frk_cliente: código do cliente
   * @param v_nom_campo: nome do campo
   * @param v_frk_campo: código do campo em caso de edição
   * @return TRUE: existe outro campo com esse nome
   *         FALSE: não existe outro campo com esse nome
   **/
  FUNCTION fExisteCampo(v_frk_cliente tab_cliente.prk_cliente%TYPE
                      , v_nom_campo idx_campo.nom_campo%TYPE
                      , v_frk_campo idx_campo.prk_campo%TYPE) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1) INTO nTotal
      FROM idx_campo
     WHERE (frk_cliente = v_frk_cliente OR frk_cliente IS NULL)
       AND nom_campo = v_nom_campo
       AND (v_frk_campo IS NULL OR v_frk_campo <> prk_campo);
     IF nTotal = 0 THEN
       RETURN FALSE;
     ELSE
       RETURN TRUE;
     END IF;
  END fExisteCampo;

  /**
   * Função para gerenciar o Cadastro/Edição de um Tipo de Arquivo
   * @param v_cod_usuario: matricula do usuário logado
   * @param v_rCampo: Record com os dados do arquivo
   * @param v_lOpcoes: Lista de Opções do Campo
   * @return
   **/
  FUNCTION fGerenciarCampo(v_cod_usuario tab_usuario.des_matricula%TYPE
                         , v_rCampo idx_campo%ROWTYPE
                         , v_lOpcoes STR_ARRAY) RETURN pkg_dominio.recRetorno IS
    nCampo idx_campo.prk_campo%TYPE := v_rCampo.prk_campo;
    nCampoOpcao idx_campo_opcao.prk_campo_opcao%TYPE;
    rCampoIn idx_campo%ROWTYPE;
  BEGIN
    IF v_rCampo.prk_campo IS NOT NULL THEN
      rCampoIn := pkg_indexacao.fDadosCampo(v_rCampo.prk_campo);
      IF rCampoIn.frk_cliente IS NULL THEN
        RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -5);
      END IF;
    END IF;
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -2);
    ELSIF v_rCampo.frk_tipo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -3);
    ELSIF v_rCampo.nom_campo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -4);
    ELSIF v_rCampo.frk_cliente IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -6);
    ELSIF v_rCampo.frk_tipo = 'select' AND v_lOpcoes.COUNT = 0 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -8);
    ELSIF fExisteCampo(v_rCampo.frk_cliente, v_rCampo.nom_campo, v_rCampo.prk_campo) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, -7);
    ELSIF nCampo IS NULL THEN
       INSERT INTO idx_campo (frk_cliente, frk_tipo, nom_campo, des_matricula_criacao)
                      VALUES (v_rCampo.frk_cliente, v_rCampo.frk_tipo, v_rCampo.nom_campo, v_cod_usuario)
      RETURNING prk_campo INTO nCampo;
    ELSE
       UPDATE idx_campo
          SET frk_cliente             = v_rCampo.frk_cliente
            , frk_tipo                = v_rCampo.frk_tipo
            , nom_campo               = v_rCampo.nom_campo
            , num_max_length          = v_rCampo.num_max_length
            , dat_alteracao           = SYSDATE
            , des_matricula_alteracao = v_cod_usuario
        WHERE prk_campo = nCampo;
    END IF;

    IF v_lOpcoes.COUNT > 0 THEN
      /* Inativa todas as opções relacionadas ao Campo */
      UPDATE idx_campo_opcao
         SET sts_campo_opcao = pkg_constante.CONST_INATIVO
       WHERE frk_campo = nCampo;

      FOR nLoop IN 1..v_lOpcoes.COUNT
      LOOP
        /* Ativa as opções enviadas pelo Usuário ou Cadastra caso a opção não exista */
        SELECT MAX(prk_campo_opcao)
          INTO nCampoOpcao
          FROM idx_campo_opcao
        WHERE frk_campo = nCampo
          AND pkg_base.fLimparString(v_lOpcoes(nLoop)) = pkg_base.fLimparString(des_campo_opcao);
        IF nCampoOpcao IS NULL THEN
          INSERT INTO idx_campo_opcao (frk_campo, des_campo_opcao, ind_ordem)
                               VALUES (nCampo, v_lOpcoes(nLoop), nLoop);
        ELSE
          UPDATE idx_campo_opcao
             SET sts_campo_opcao = pkg_constante.CONST_ATIVO
               , des_campo_opcao = v_lOpcoes(nLoop)
               , ind_ordem = nLoop
           WHERE prk_campo_opcao = nCampoOpcao;
        END IF;

      END LOOP;
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(SQLERRM);
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_CAMPO, pkg_constante.CONST_FALHA);
  END fGerenciarCampo;

  /**
   * Ativa/Desativa um Campo
   * @param v_cod_usuario: Login do usuário logado no Sistema;
   * @param v_frk_campo: Código do Campo;
   * @return: pkg_dominio.recRetorno;
   **/
  FUNCTION fAtivarDesativarCampo (v_cod_usuario tab_usuario.des_matricula%TYPE
                                , v_frk_campo idx_campo.prk_campo%TYPE) RETURN pkg_dominio.RecRetorno IS
    nStatus idx_campo.sts_campo%TYPE;
  BEGIN
      UPDATE idx_campo
         SET sts_campo               = CASE sts_campo
                                         WHEN pkg_constante.CONST_ATIVO THEN pkg_constante.CONST_INATIVO
                                         ELSE pkg_constante.CONST_ATIVO
                                       END
           , des_matricula_alteracao = v_cod_usuario
           , dat_alteracao           = SYSDATE
       WHERE prk_campo               = v_frk_campo
      RETURNING sts_campo INTO nStatus;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => 2,  v_cod_registro_gerado => nStatus);
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem =>  pkg_constante.CONST_FALHA, v_sql_code => SQLCODE, v_sql_error => SQLERRM );
  END fAtivarDesativarCampo;



  /**
   * Função para popular os grupos em um Formulário
   * @param v_rFormulario: Record do formulário
   * @param v_rGrupoFormulario: Record do grupo que será inserido
   **/
  PROCEDURE pAdicionarGrupoFormulario(v_rFormulario IN OUT recFormulario
                                    , v_rGrupoFormulario recGrupoFormulario) IS
    lGrupo tGrupoFormulario:=v_rFormulario.lGrupoFormulario;
  BEGIN
    BEGIN
      lGrupo.EXTEND;
    EXCEPTION
      WHEN OTHERS THEN
        lGrupo := tGrupoFormulario();
        lGrupo.EXTEND;
    END;
    lGrupo(lGrupo.COUNT) := v_rGrupoFormulario;
    lGrupo(lGrupo.COUNT).lCampoFormulario := tCampoFormulario();
    v_rFormulario.lGrupoFormulario := lGrupo;
  END pAdicionarGrupoFormulario;

  /**
   * Função para popular os campos do ultimo grupo inserido em um Formulário
   * @param v_rFormulario: Record do formulário
   * @param v_rCampoFormulario: Record do campo que será inserido
   **/
  PROCEDURE pAdicionarCampoFormulario(v_rFormulario IN OUT recFormulario
                                    , v_rCampoFormulario recCampoFormulario) IS
    lCampoFormulario tCampoFormulario;
    nGrupo NUMBER;
  BEGIN
    nGrupo := v_rFormulario.lGrupoFormulario.LAST;
    lCampoFormulario := v_rFormulario.lGrupoFormulario(nGrupo).lCampoFormulario;
    lCampoFormulario.EXTEND;
    lCampoFormulario(lCampoFormulario.COUNT) := v_rCampoFormulario;
    v_rFormulario.lGrupoFormulario(nGrupo).lCampoFormulario := lCampoFormulario;
  END pAdicionarCampoFormulario;

  /**
   * Função que verifica a existência de outro formulário com o mesmo nome para um mesmo nível hierarquico
   * @param v_rFormulario: Recod do formulario a ser verificado
   * @return TRUE/FALSE
   **/
  FUNCTION fExisteFormulario(v_rFormulario recFormulario) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO nTotal
      FROM idx_formulario a
     WHERE UPPER(nom_formulario) = UPPER(v_rFormulario.nom_formulario)
       AND frk_nivel_hierarquico = v_rFormulario.frk_nivel_hierarquico
       AND (v_rFormulario.prk_formulario IS NULL OR v_rFormulario.prk_formulario <> prk_formulario);
    IF nTotal > 0 THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END fExisteFormulario;

  /**
   * Função para gerenciar um formulário no sistema
   * @param v_cod_usuario: Código do usuário
   * @param v_rFormulario: Record do fomulário
  **/
  FUNCTION fGerenciarFormulario(v_cod_usuario tab_usuario.des_matricula%TYPE
                              , v_rFormulario recFormulario) RETURN pkg_dominio.recRetorno IS
    nFormulario NUMBER := v_rFormulario.prk_formulario;
    nGrupo idx_grupo.prk_grupo%TYPE;
    rGrupoFormulario recGrupoFormulario;
    rCampoFormulario recCampoFormulario;
    rNivelHierarquico tab_nivel_hierarquico%ROWTYPE:= pkg_dominio.fDadosNivelHierarquico(v_rFormulario.frk_nivel_hierarquico);
    rRetorno pkg_dominio.recRetorno;
  BEGIN
    IF v_rFormulario.frk_nivel_hierarquico IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -2);
    ELSIF v_rFormulario.nom_formulario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -3);
    ELSIF v_rFormulario.lGrupoFormulario.COUNT = 0 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -4);
    ELSIF fExisteFormulario(v_rFormulario) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -5);
    END IF;
    IF nFormulario IS NULL THEN
      INSERT INTO idx_formulario (frk_nivel_hierarquico, nom_formulario, des_matricula_criacao)
                          VALUES (v_rFormulario.frk_nivel_hierarquico, v_rFormulario.nom_formulario, v_cod_usuario)
                 RETURNING prk_formulario INTO nFormulario;
    ELSE
      UPDATE idx_formulario
         SET frk_nivel_hierarquico = v_rFormulario.frk_nivel_hierarquico
           , nom_formulario = v_rFormulario.nom_formulario
           , dat_alteracao = SYSDATE
           , des_matricula_alteracao = v_cod_usuario
       WHERE prk_formulario = nFormulario;
      DELETE idx_formulario_campo WHERE frk_formulario = nFormulario;
      DELETE idx_formulario_grupo WHERE frk_formulario = nFormulario;
    END IF;

    FOR nIdxGrupo IN 1..v_rFormulario.lGrupoFormulario.COUNT
    LOOP
      rGrupoFormulario := v_rFormulario.lGrupoFormulario(nIdxGrupo);
      IF rGrupoFormulario.nom_grupo IS NULL THEN
        rRetorno := pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -6);
        RAISE pkg_dominio.EXPT_GERAL;
      ELSIF rGrupoFormulario.lCampoFormulario.COUNT = 0 THEN
        rRetorno := pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -7);
        RAISE pkg_dominio.EXPT_GERAL;
      END IF;
      nGrupo := fGetGrupoId(rNivelHierarquico.frk_cliente, rGrupoFormulario.nom_grupo);
      INSERT INTO idx_formulario_grupo(frk_formulario, frk_grupo, ind_orderm, ind_multivalorado, ind_obrigatorio, frk_tipo_arquivo_associado)
                               VALUES (nFormulario, nGrupo, nIdxGrupo, rGrupoFormulario.ind_multivalorado, rGrupoFormulario.ind_obrigatorio, rGrupoFormulario.frk_tipo_arquivo_associado);
      FOR nIdxCampo IN 1..rGrupoFormulario.lCampoFormulario.COUNT
      LOOP
        rCampoFormulario := rGrupoFormulario.lCampoFormulario(nIdxCampo);
        /*Valida se a expressão regular que está sendo informada é válida*/
        IF rCampoFormulario.des_regex IS NOT NULL AND pkg_base.fValidarExpReg(rCampoFormulario.des_regex) = pkg_constante.CONST_NAO THEN
          ROLLBACK;
          RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, -8);
        END IF;
        INSERT INTO idx_formulario_campo (frk_formulario, frk_grupo, frk_campo, ind_obrigatorio, num_valor_minimo, num_valor_maximo, ind_ordem, ind_invalido, ind_autocomplete, ind_multivalorado, ind_editavel, frk_campo_ocr, des_regex)
                                  VALUES (nFormulario
                                        , nGrupo
                                        , rCampoFormulario.frk_campo
                                        , NVL(rCampoFormulario.ind_obrigatorio, pkg_constante.CONST_NAO)
                                        , rCampoFormulario.num_valor_minimo
                                        , rCampoFormulario.num_valor_maximo
                                        , nIdxCampo
                                        , NVL(rCampoFormulario.ind_invalido, pkg_constante.CONST_NAO)
                                        , NVL(rCampoFormulario.ind_autocomplete, pkg_constante.CONST_NAO)
                                        , NVL(rCampoFormulario.ind_multivalorado, pkg_constante.CONST_NAO)
                                        , NVL(rCampoFormulario.ind_editavel, pkg_constante.CONST_NAO)
                                        , rCampoFormulario.frk_campo_ocr
                                        , rCampoFormulario.des_regex);
      END LOOP;
    END LOOP;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, 1, v_cod_registro_gerado => nFormulario);
  EXCEPTION
    WHEN pkg_dominio.EXPT_GERAL THEN
      ROLLBACK;
      RETURN rRetorno;
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fGerenciarFormulario;

  /**
   * Função para listar os formulários disponíveis de um workfow
   * @param v_frk_nivel_hierarquico: Nível Hierarquico do workflow
   **/
  FUNCTION fListarFormulario(v_frk_nivel_hierarquico idx_formulario.frk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT prk_formulario
           , nom_formulario
        FROM idx_formulario
       WHERE frk_nivel_hierarquico = v_frk_nivel_hierarquico
       ORDER BY 2
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarFormulario;


  /**
   * Função para listar os grupos de um formulário
   * @param v_frk_formulario: código do formulário
   **/
  FUNCTION fListarFormularioGrupo(v_frk_formulario idx_formulario_grupo.frk_formulario%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT prk_grupo
           , nom_grupo
        FROM idx_formulario_grupo
       INNER JOIN idx_grupo
             ON prk_grupo = frk_grupo
       WHERE frk_formulario = v_frk_formulario
       ORDER BY 2
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarFormularioGrupo;

  /**
   * Função para listar os campos de um formulário
   * @param v_frk_formulario: código do formulário
   **/
  FUNCTION fListarFormularioCampo(v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                , v_frk_tipo idx_campo.frk_tipo%TYPE DEFAULT NULL) RETURN pkg_dominio.tSelectNumber PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT prk_campo
           , nom_campo
        FROM idx_formulario_campo
       INNER JOIN idx_campo
             ON prk_campo = frk_campo
       WHERE frk_formulario = v_frk_formulario
         AND frk_grupo = v_frk_grupo
         AND frk_tipo = NVL(v_frk_tipo, frk_tipo)
       ORDER BY 2
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarFormularioCampo;
  /**
   * Função para listar os dados do formulário de indexação de acordo com o NH e o tipo de arquivo
   * @param v_frk_nivel_hierarquico: Código do nível hierarquico
   * @param v_frk_tipo_arquivo: Código do tipo de arquivo
   **/
  FUNCTION fListarFormularioIndexacao(v_frk_formulario idx_formulario.prk_formulario%TYPE
                                    , v_frk_registro sph_registro.prk_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexacao PIPELINED IS
  BEGIN

    FOR tab_temp IN(
      WITH alertas AS (
        SELECT frk_formulario
             , frk_grupo
             , frk_campo
             , cod_cor_sinalizacao
             , ind_ordem
          FROM sph_registro_alerta 
         INNER JOIN idx_formulario_campo_alerta c
               USING(frk_alerta)
         WHERE frk_registro = v_frk_registro
      ), sinalizacao AS (
          SELECT frk_formulario
               , frk_grupo
               , frk_campo
               , cod_cor_sinalizacao
            FROM alertas base
           WHERE ind_ordem = (SELECT MIN(ind_ordem)
                                FROM alertas dif
                               WHERE dif.frk_formulario = base.frk_formulario
                                 AND dif.frk_grupo = base.frk_grupo 
                                 AND dif.frk_campo = base.frk_campo)
      )
      SELECT prk_formulario
           , nom_formulario
           , prk_grupo
           , nom_grupo
           , ifg.ind_multivalorado ind_grupo_multivalorado
           , ifg.ind_obrigatorio ind_grupo_obrigatorio
           , ifg.frk_tipo_arquivo_associado
           , prk_campo
           , 'campo_' || prk_formulario || '_' || prk_grupo || '_' || prk_campo
           , nom_campo
           , frk_tipo
           , ifc.ind_obrigatorio ind_campo_obrigatorio
           , ifc.num_valor_maximo
           , ifc.num_valor_minimo
           , ifc.ind_invalido
           , ifc.ind_autocomplete
           , ifc.ind_multivalorado
           , ifc.frk_campo_ocr
           , ifc.des_regex
           , ocr.des_campo_ocr
           , ocr.frk_ocr_tipo_arquivo
           , doc.nom_ocr_tipo_arquivo
           , TO_CHAR(NULL) des_opcao
           , TO_CHAR(NULL) des_value
           , cod_campo
           , ifc.ind_editavel
           , cod_cor_sinalizacao
        FROM idx_formulario idf
       INNER JOIN idx_formulario_grupo ifg
             ON prk_formulario = frk_formulario
       INNER JOIN idx_formulario_campo ifc
             USING(frk_formulario, frk_grupo)
       INNER JOIN idx_grupo idg
             ON prk_grupo = frk_grupo
       INNER JOIN idx_campo idc
             ON prk_campo = frk_campo
       LEFT JOIN sinalizacao
            USING(frk_formulario, frk_grupo, frk_campo)
       LEFT JOIN ocr_campo ocr      
             ON prk_campo_ocr = frk_campo_ocr    
       LEFT JOIN ocr_tipo_arquivo doc
             ON prk_ocr_tipo_arquivo = frk_ocr_tipo_arquivo     
       WHERE prk_formulario = v_frk_formulario
       ORDER BY ifg.ind_orderm, ifc.ind_ordem
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarFormularioIndexacao;

  /**
   * Função para gerar uma query com pivot dos campos de formulário específico
   * @param v_frk_formulario: Código do formulário
   * @param v_des_query: Output com a query gerada
   **/
  FUNCTION fBuscarFormularioPivot(v_frk_formulario idx_formulario.prk_formulario%TYPE
                                , v_des_query IN OUT VARCHAR2) RETURN pkg_dominio.recRetorno IS
    vQuery VARCHAR2(3999);
    vPivot VARCHAR2(3999) := '';
    vFields VARCHAR2(3999) := '';
  BEGIN
    FOR tab_temp IN(
      SELECT frk_formulario
           , frk_grupo
           , frk_campo
           , des_name_campo
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(v_frk_formulario))
    )
    LOOP
      vFields := vFields || ', ' || tab_temp.des_name_campo;
      vPivot := vPivot || '''' || tab_temp.frk_formulario || '_' || tab_temp.frk_grupo || '_' || tab_temp.frk_campo || ''' as  ' || tab_temp.des_name_campo ||  ',';
    END LOOP;
    IF vPivot IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
    END IF;
    vPivot := SUBSTR(vPivot,1 ,LENGTH(vPivot)-1);
    vQuery := '
      SELECT frk_registro
           , frk_tipo_arquivo
           , sts_indexador
           , num_linha
           ' || vFields ||  '
        FROM (
      SELECT frk_registro
           , frk_formulario || ''_'' || frk_grupo || ''_'' || frk_campo cod_campo
           , val_indexador
           , frk_tipo_arquivo
           , sts_indexador
           , num_linha
        FROM sph_registro_indexador
      WHERE frk_formulario = ' || v_frk_formulario || ')
      PIVOT (
        MAX(val_indexador)
        FOR cod_campo IN(' || vPivot || ') )';
    v_des_query := vQuery;
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fBuscarFormularioPivot;

  /**
   * Função Responsável por buscar o ID do formulário de um fluxo e tipo de arquivo
   **/
  FUNCTION fBuscarIDFormularioFluxo(v_frk_fluxo cfg_fluxo_formulario.frk_fluxo%TYPE
                                  , v_frk_tipo_arquivo cfg_fluxo_formulario.frk_tipo_arquivo%TYPE DEFAULT NULL) RETURN cfg_fluxo_formulario.frk_formulario%TYPE IS
    nFormulario cfg_fluxo_formulario.frk_formulario%TYPE;
  BEGIN
    SELECT MAX(frk_formulario)
      INTO nFormulario
      FROM cfg_fluxo_formulario
     WHERE frk_fluxo = v_frk_fluxo
       AND NVL(frk_tipo_arquivo, -1) = NVL(v_frk_tipo_arquivo, -1);
    RETURN nFormulario;
  END fBuscarIDFormularioFluxo;

  /** 
   * Função para popular a lista lFormularioAlerta
   **/
  PROCEDURE pAdicionarFormularioAlerta(lFormularioAlerta IN OUT tFormularioAlerta
                                     , rFormularioAlerta recFormularioAlerta) IS
  BEGIN
    lFormularioAlerta.EXTEND;
    lFormularioAlerta(lFormularioAlerta.COUNT) := rFormularioAlerta;
  END pAdicionarFormularioAlerta;
  
  /** 
   * Função para gerenciar a sinalização de alerta dos campos
   **/
  FUNCTION fGerenciarSinalizacaoCampo(v_frk_cliente tab_cliente.prk_cliente%TYPE
                                    , v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                    , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                    , v_frk_campo idx_formulario_campo.frk_campo%TYPE
                                    , lFormularioAlerta tFormularioAlerta)  RETURN pkg_dominio.recRetorno IS
    nAlerta cfg_alerta.prk_alerta%TYPE;
  BEGIN
    DELETE idx_formulario_campo_alerta
     WHERE frk_formulario = v_frk_formulario
       AND frk_grupo = v_frk_grupo
       AND frk_campo = v_frk_campo;
       
    FOR nIndex IN 1..lFormularioAlerta.COUNT 
    LOOP
      nAlerta := pkg_dominio.fGetChaveAlerta(v_frk_cliente, lFormularioAlerta(nIndex).des_alerta);
      IF nAlerta IS NOT NULL THEN
        MERGE INTO idx_formulario_campo_alerta target
          USING (SELECT v_frk_formulario frk_formulario
                      , v_frk_grupo frk_grupo
                      , v_frk_campo frk_campo
                      , nAlerta frk_alerta
                   FROM dual) base
          ON (base.frk_formulario = target.frk_formulario
              AND base.frk_grupo = target.frk_grupo
              AND base.frk_campo = target.frk_campo
              AND base.frk_alerta = target.frk_alerta)
        WHEN MATCHED THEN
          UPDATE SET target.cod_cor_sinalizacao = lFormularioAlerta(nIndex).cod_cor_sinalizacao
                   , ind_ordem = nIndex
        WHEN NOT MATCHED THEN
          INSERT (frk_formulario, frk_grupo, frk_campo, frk_alerta, cod_cor_sinalizacao, ind_ordem)
          VALUES (v_frk_formulario, v_frk_grupo, v_frk_campo, base.frk_alerta, lFormularioAlerta(nIndex).cod_cor_sinalizacao, nIndex);
      END IF;
    END LOOP;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_FORMULARIO, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fGerenciarSinalizacaoCampo;
  
  /** 
   * Função para listar a sinalização de alerta do campo
   **/
  FUNCTION fListarSinalizacaoCampo(v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                 , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                 , v_frk_campo idx_formulario_campo.frk_campo%TYPE)  RETURN tFormularioAlerta PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT cod_cor_sinalizacao
           , des_alerta
        FROM idx_formulario_campo_alerta
       INNER JOIN cfg_alerta
          ON prk_alerta = frk_alerta
       WHERE frk_formulario = v_frk_formulario
         AND frk_grupo = v_frk_grupo
         AND frk_campo =v_frk_campo    
    )
    LOOP  
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarSinalizacaoCampo;
  

  PROCEDURE pBuscarPaginasFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                              , nPaginaInicial IN OUT NUMBER
                              , nPaginaFinal IN OUT NUMBER) IS
  BEGIN
    SELECT MAX((SELECT val_parametro
                  FROM dual
                 WHERE cod_parametro = pkg_constante.CONST_COD_IDX_PAG_INICIAL))
         , MAX((SELECT val_parametro
                  FROM dual
                 WHERE cod_parametro = pkg_constante.CONST_COD_IDX_PAG_FINAL))
      INTO nPaginaInicial, nPaginaFinal
      FROM sph_registro_fluxo_parametro
     WHERE cod_parametro IN(pkg_constante.CONST_COD_IDX_PAG_INICIAL
                          , pkg_constante.CONST_COD_IDX_PAG_FINAL)
       AND frk_registro_fluxo = v_frk_registro_fluxo;
  END pBuscarPaginasFluxo;


  PROCEDURE pAdicionarValorCampo(lListaJsonObjeto IN OUT pkg_base.tlistajsonobjeto
                               , v_val_indexador VARCHAR2
                               , v_des_indexador VARCHAR2
                               , v_sts_indexador VARCHAR2
                               , v_num_linha_indexador VARCHAR2
                               , v_ind_resumido NUMBER DEFAULT pkg_constante.CONST_NAO) IS
  BEGIN
      pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'l', v_num_linha_indexador);
      IF v_ind_resumido = pkg_constante.CONST_NAO THEN
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 's', v_sts_indexador);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'd', v_des_indexador);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'v', v_val_indexador);
      ELSE
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'v', fFormatValorIndexacao(v_val_indexador,v_sts_indexador));
      END IF;
      pkg_base.pAvancarJsonLista(lListaJsonObjeto);
  END pAdicionarValorCampo;


  FUNCTION fBuscarIndexacaoRegistroCampoF(rIndexacao sph_registro_indexador%ROWTYPE
                                       , v_ind_correcao OUT NUMBER
                                       , v_num_linha_inicio NUMBER DEFAULT NULL
                                       , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX
                                       , v_num_pagina_inicial NUMBER DEFAULT NULL
                                       , v_num_pagina_final NUMBER DEFAULT NULL
                                       , v_ind_ordenacao NUMBER DEFAULT 1
                                       , v_ind_resumido NUMBER DEFAULT pkg_constante.CONST_NAO
                                       , v_ind_buscar_dados_ocr NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN VARCHAR2 IS
    vIndexacao VARCHAR2(4000) :='';
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
    nIndCorrecao NUMBER:=pkg_constante.CONST_NAO;
  BEGIN
    pkg_base.pInicializarJsonLista(lListaJsonObjeto);
    FOR tab_temp IN (
      -- // l: Linha, v: Value, s: Status, d: Descrição
      SELECT  *
        FROM (
          SELECT tab.*
               , ROWNUM AS rnum
            FROM (
              SELECT NVL(TO_CHAR(cod_indexador_valor), val_indexador) cod_indexador_valor
                   , val_indexador
                   , sts_indexador
                   , num_linha
                   , num_pagina
                   , ind_alteracao
                FROM sph_registro_indexador
               WHERE frk_registro = rIndexacao.frk_registro
                 AND sts_indexador > 0
                 AND frk_campo = rIndexacao.frk_campo
                 AND NVL(frk_grupo, -1) = NVL(rIndexacao.frk_grupo, -1)
                 AND NVL(frk_formulario, -1) = NVL(rIndexacao.frk_formulario, -1)
                 AND NVL(frk_tipo_arquivo, -1) = NVL(rIndexacao.frk_tipo_arquivo, -1)
                 AND NVL(frk_arquivo, -1) = NVL(rIndexacao.frk_arquivo, -1)
                 /*AND NVL(frk_consulta_externa, -1) = NVL(rIndexacao.frk_consulta_externa, -1)*/
                 AND NVL(frk_registro_consulta_externa, -1) = NVL(rIndexacao.frk_registro_consulta_externa, -1)
                 AND (v_num_pagina_inicial IS NULL OR v_num_pagina_inicial <= num_pagina)
                 AND (v_num_pagina_final IS NULL OR v_num_pagina_final >= num_pagina)
                 AND (num_linha < v_num_linha_inicio OR v_num_linha_inicio IS NULL)
                 AND (rIndexacao.frk_registro_fluxo IS NULL OR frk_registro_fluxo = rIndexacao.frk_registro_fluxo)
               ORDER BY num_linha DESC
            ) tab
          WHERE ROWNUM <= v_num_quantidade
        )
        ORDER BY CASE
                  WHEN v_ind_ordenacao = 1 THEN rnum
                  ELSE rnum * (-1)
                 END
    )
    LOOP
      IF tab_temp.ind_alteracao = pkg_constante.CONST_SIM THEN
        nIndCorrecao := pkg_constante.CONST_SIM;
      END IF; 
      pAdicionarValorCampo(lListaJsonObjeto, tab_temp.cod_indexador_valor, tab_temp.val_indexador, tab_temp.sts_indexador, tab_temp.num_linha, v_ind_resumido);
    END LOOP;
    vIndexacao := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
    IF vIndexacao = '[]' THEN
        vIndexacao := NULL;
        IF v_ind_buscar_dados_ocr = pkg_constante.CONST_SIM THEN
          SELECT MAX(val_campo_ocr)
            INTO vIndexacao
            FROM sph_registro_ocr
           INNER JOIN idx_formulario_campo
                 USING(frk_campo_ocr)
           WHERE frk_registro = rIndexacao.frk_registro
             AND frk_formulario = rIndexacao.frk_formulario
             AND frk_campo = rIndexacao.frk_campo
             AND frk_grupo = rIndexacao.frk_grupo
             AND NVL(frk_arquivo, -1) = NVL(rIndexacao.frk_arquivo, -1);
          IF vIndexacao IS NOT NULL THEN
            pAdicionarValorCampo(lListaJsonObjeto, vIndexacao, vIndexacao, 1, 1, v_ind_resumido);
            vIndexacao := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
          END IF;
        END IF;
    END IF;
    v_ind_correcao := nIndCorrecao;
    RETURN vIndexacao;
  END fBuscarIndexacaoRegistroCampoF;
  
  FUNCTION fBuscarIndexacaoRegistroCampo(rIndexacao sph_registro_indexador%ROWTYPE
                                       , v_num_linha_inicio NUMBER DEFAULT NULL
                                       , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX
                                       , v_num_pagina_inicial NUMBER DEFAULT NULL
                                       , v_num_pagina_final NUMBER DEFAULT NULL
                                       , v_ind_ordenacao NUMBER DEFAULT 1
                                       , v_ind_resumido NUMBER DEFAULT pkg_constante.CONST_NAO
                                       , v_ind_buscar_dados_ocr NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN VARCHAR2 IS
    nCorrecao NUMBER;
  BEGIN
    RETURN fBuscarIndexacaoRegistroCampoF(rIndexacao
                                       , nCorrecao
                                       , v_num_linha_inicio
                                       , v_num_quantidade
                                       , v_num_pagina_inicial
                                       , v_num_pagina_final
                                       , v_ind_ordenacao
                                       , v_ind_resumido
                                       , v_ind_buscar_dados_ocr);
  END fBuscarIndexacaoRegistroCampo;

  /**
   * Função para retornar o formulário de dados de acordo com o fluxo
   * @param v_frk_registro_fluxo: Código do fluxo de análise
   **/
  FUNCTION fListarFormularioRegistroFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tFormularioIndexacao PIPELINED IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rFormularioLinha recFormularioIndexacao;
    rIndexacao sph_registro_indexador%ROWTYPE;
    --// Range de páginas da indexação a serem exibidas
    nPaginaInicial NUMBER;
    nPaginaFinal NUMBER;
    
    nCorrecaoFormulario NUMBER := pkg_dominio.fValidarControleAcesso(v_frk_fluxo => rRegistroFluxo.frk_fluxo, v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_CORRECAO_FORMUL);
  BEGIN
    --// Inicializa o objeto para recuperar a indexação dos campos
    rIndexacao.frk_registro := rRegistroFluxo.frk_registro;
    IF nCorrecaoFormulario = pkg_constante.CONST_NAO THEN
      rIndexacao.frk_tipo_arquivo := rRegistroFluxo.cod_analise;
      rIndexacao.frk_arquivo := rRegistroFluxo.cod_subanalise;
    END IF;
    rIndexacao.frk_formulario := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo, rRegistroFluxo.cod_analise);
    --rIndexacao.frk_registro_fluxo := v_frk_registro_fluxo;
    pBuscarPaginasFluxo(rRegistroFluxo.prk_registro_fluxo, nPaginaInicial, nPaginaFinal);

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(rIndexacao.frk_formulario, rRegistroFluxo.frk_registro))
       WHERE (nCorrecaoFormulario = pkg_constante.CONST_NAO OR frk_tipo_arquivo_associado = rRegistroFluxo.cod_analise)
    )
    LOOP
      rFormularioLinha := tab_temp;

      --// Busca a indexação do campo retornado
      rIndexacao.frk_campo := tab_temp.frk_campo;
      rIndexacao.frk_grupo := tab_temp.frk_grupo;
      rFormularioLinha.des_value_campo := fBuscarIndexacaoRegistroCampo(rIndexacao
                                                                      , v_num_pagina_inicial => nPaginaInicial
                                                                      , v_num_pagina_final => nPaginaFinal
                                                                      , v_ind_ordenacao => 2
                                                                      , v_ind_buscar_dados_ocr => pkg_dominio.fValidarControleAcesso(v_frk_fluxo    => rRegistroFluxo.frk_fluxo, v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_UTILIZA_IDX_OCR));
      IF rFormularioLinha.cod_campo_tipo = 'select' THEN
        rFormularioLinha.des_opcao_campo := fGetOpcaoCampoJSON(rFormularioLinha.frk_campo);
      END IF;
      PIPE ROW(rFormularioLinha);
    END LOOP;
    RETURN ;
  END fListarFormularioRegistroFluxo;

  /**
   * Função para buscar a indexação
   **/
  FUNCTION fListarIndexacaoGrupoCampo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                    , v_num_linha_inicio NUMBER
                                    , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRegistro sph_registro%ROWTYPE := pkg_registro.fDadosRegistro(rRegistroFluxo.frk_registro);
    rIndexacaoCampo recListaIndexacaoCampo;
    rIndexacao sph_registro_indexador%ROWTYPE;

    --// Range de páginas da indexação a serem exibidas
    nPaginaInicial NUMBER;
    nPaginaFinal NUMBER;
  BEGIN
    --// Inicializa o objeto para recuperar a indexação dos campos
    rIndexacao.frk_registro := rRegistro.prk_registro;
    rIndexacao.frk_tipo_arquivo := rRegistroFluxo.cod_analise;
    rIndexacao.frk_arquivo := rRegistroFluxo.cod_subanalise;
    rIndexacao.frk_grupo := v_frk_grupo;


    rIndexacao.frk_formulario := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo, rRegistroFluxo.cod_analise);
    pBuscarPaginasFluxo(rRegistroFluxo.prk_registro_fluxo, nPaginaInicial, nPaginaFinal);

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(rIndexacao.frk_formulario, rRegistroFluxo.frk_registro))
       WHERE frk_grupo = v_frk_grupo
    )
    LOOP
      rIndexacaoCampo.frk_campo := tab_temp.frk_campo;
        --// Busca a indexação do campo retornado
      rIndexacao.frk_campo := tab_temp.frk_campo;
      rIndexacaoCampo.des_value := fBuscarIndexacaoRegistroCampo(rIndexacao, v_num_linha_inicio, v_num_quantidade, nPaginaInicial, nPaginaFinal);
      IF TRIM(rIndexacaoCampo.des_value) IS NULL THEN
        CONTINUE;
      END IF;
      PIPE ROW(rIndexacaoCampo);
    END LOOP;
  END fListarIndexacaoGrupoCampo;


  /**
   * Função para popular o record com os campos indexados do registro
   * @param lCampoValorIndexacao: Array com a lista de indexação
   * @param frk_campo: Chave do campo indexado
   * @param val_campo: Valor do campo indexado
   **/
  PROCEDURE pAdicionarCampoIndexacao(v_lCampo IN OUT tCampoValorIndexacao
                                   , v_frk_campo NUMBER
                                   , v_val_campo VARCHAR2) IS
  BEGIN
    v_lCampo.EXTEND;
    v_lCampo(v_lCampo.COUNT).frk_campo := v_frk_campo;
    v_lCampo(v_lCampo.COUNT).val_indexador := TRIM(v_val_campo);
  END pAdicionarCampoIndexacao;
  /**
   * Função para popular um array de campos indexados
   * @param lCampoValorIndexacao: Lista de campos
   * @param rCampoValorIndexacao: recod com o novo campo indexado
   **/
  PROCEDURE pAdicionarCampoIndexacao(lCampoValorIndexacao IN OUT tCampoValorIndexacao
                                   , rCampoValorIndexacao recCampoValorIndexacao) IS
  BEGIN
    lCampoValorIndexacao.EXTEND;
    lCampoValorIndexacao(lCampoValorIndexacao.COUNT) := rCampoValorIndexacao;
  END pAdicionarCampoIndexacao;

  /**
   * Função para retornar a próxima linha de indexação
   **/
  FUNCTION fBuscarCampoIndexacaoProxLinha RETURN NUMBER IS
  BEGIN
    RETURN cod_seq_linha_indexador.nextval;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 1;
  END fBuscarCampoIndexacaoProxLinha;

  FUNCTION fValidarDuplicidade(rIndexacaoIn sph_registro_indexador%ROWTYPE
                             , lCampoValorIndexacao pkg_indexacao.tCampoValorIndexacao) RETURN BOOLEAN IS
    vWhere VARCHAR2(2000) := ' 1=1 ';
    lPivot STR_ARRAY:= STR_ARRAY();
    vPivot VARCHAR2(2000) := '';
    lCampos STR_ARRAY:=STR_ARRAY();
    vWhereValue VARCHAR2(2000) := '';
    lWhereValue STR_ARRAY := STR_ARRAY();
    nTotal NUMBER;
    nValidarDuplicidade NUMBER;

  BEGIN
    IF rIndexacaoIn.num_linha IS NOT NULL THEN
      vWhere := vWhere || ' AND num_linha <> ' || rIndexacaoIn.num_linha;
    END IF;
    vWhere := vWhere || ' AND frk_formulario = ' || rIndexacaoIn.frk_formulario;
    IF rIndexacaoIn.frk_arquivo IS NOT NULL THEN
      vWhere := vWhere || ' AND frk_arquivo = ' || rIndexacaoIn.frk_arquivo;
    ELSE
      vWhere := vWhere || ' AND frk_registro = ' || rIndexacaoIn.frk_registro;
      IF rIndexacaoIn.frk_tipo_arquivo IS NOT NULL THEN
        vWhere := vWhere || ' AND frk_tipo_arquivo = ' || rIndexacaoIn.frk_tipo_arquivo;
      END IF;
    END IF;
    FOR nIndex IN 1..lCampoValorIndexacao.COUNT
    LOOP
      SELECT ind_validar_duplicidade
        INTO nValidarDuplicidade
        FROM idx_formulario_campo
       WHERE frk_formulario = rIndexacaoIn.frk_formulario
         AND frk_grupo = lCampoValorIndexacao(nIndex).frk_grupo
         AND frk_campo = lCampoValorIndexacao(nIndex).frk_campo;
      IF nValidarDuplicidade <> pkg_constante.CONST_SIM THEN
        continue;
      END IF;
      --// Montando o WHERE de Campos
      pkg_base.pAddStrArray('(' || lCampoValorIndexacao(nIndex).frk_grupo || ',' || lCampoValorIndexacao(nIndex).frk_campo || ')', lCampos );
      --// Montando o PIVOT
      pkg_base.pAddStrArray( lCampoValorIndexacao(nIndex).frk_campo || ' AS campo_' || nIndex, lPivot );
      --// Montando o WHERE de Valores
      IF TRIM(lCampoValorIndexacao(nIndex).val_indexador) IS NULL THEN
        pkg_base.pAddStrArray( 'campo_' || nIndex || ' IS NULL ', lWhereValue );
      ELSE
        pkg_base.pAddStrArray( 'TRIM(campo_' || nIndex || ') = ''' || TRIM(lCampoValorIndexacao(nIndex).val_indexador) || '''', lWhereValue );
      END IF;

    END LOOP;
    IF lCampos.COUNT = 0 THEN
      RETURN FALSE;
    END IF;
    vWhere  := vWhere || ' AND (frk_grupo, frk_campo) IN( ' || pkg_base.fImplodeArrayStr(lCampos, ',') || ')';
    vPivot  := pkg_base.fImplodeArrayStr(lPivot, ',');
    vWhereValue := pkg_base.fImplodeArrayStr(lWhereValue, ' AND ');

    EXECUTE IMMEDIATE '
      SELECT COUNT(1)
        FROM (
          SELECT num_linha, frk_campo, val_indexador
            FROM sph_registro_indexador t
           WHERE ' || vWhere || '
        )
        PIVOT (
          MAX(val_indexador)
           FOR frk_campo IN ('|| vPivot || ')
        )
       WHERE '|| vWhereValue INTO nTotal;
    IF nTotal > 0 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END fValidarDuplicidade;

  /**
   * Função para buscar os dados dos campos de um formulário
   **/
  FUNCTION fDadosFormularioCampo(v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                               , v_frk_campo idx_formulario_campo.frk_campo%TYPE) RETURN idx_formulario_campo%ROWTYPE IS
    rFormularioCampo idx_formulario_campo%ROWTYPE;
  BEGIN
    SELECT * INTO rFormularioCampo
      FROM idx_formulario_campo a
     WHERE frk_formulario = v_frk_formulario
       AND frk_campo = v_frk_campo;
    RETURN rFormularioCampo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosFormularioCampo;

  /**
   * Função para salvar a indexação de um campo
   * @param v_cod_usuario:
   * @param rIndexacao:
   * @param lCampoValorIndexacao:
   **/
  FUNCTION fSalvarCampoIndexacao(v_cod_usuario sph_registro_fluxo.des_matricula_analise%TYPE
                               , rIndexacaoIn sph_registro_indexador%ROWTYPE
                               , v_lCampoValorIndexacao tCampoValorIndexacao
                               , v_ind_limpar NUMBER DEFAULT pkg_constante.CONST_NAO
                               , v_ind_valdar_dados NUMBER DEFAULT pkg_constante.CONST_SIM
                               , v_ind_correcao NUMBER DEFAULT pkg_constante.CONST_NAO
                               , v_ind_idx_ocr NUMBER DEFAULT pkg_constante.CONST_NAO
                               , v_rRegistroFluxo pkg_registro.recRegistroFluxo DEFAULT NULL) RETURN pkg_dominio.recRetorno IS
    rCampoValorIndexacao recCampoValorIndexacao;
    rIndexacao sph_registro_indexador%ROWTYPE := rIndexacaoIn;
    rCampo idx_campo%ROWTYPE;
    rFormularioCampo idx_formulario_campo%ROWTYPE;
    rOpcao idx_campo_opcao%ROWTYPE;
    ---#153734
    vMensagemLog cfg_tipo_arquivo.nom_tipo_arquivo%TYPE;
    bExisteRegistroIndexador BOOLEAN;
    rTipoArquivo cfg_tipo_arquivo%ROWTYPE:=pkg_digitalizacao.fDadosTipoArquivo(NVL(rIndexacaoIn.frk_tipo_arquivo, v_rRegistroFluxo.cod_analise));
  BEGIN
    IF v_ind_limpar = pkg_constante.CONST_SIM THEN
      DELETE sph_registro_indexador
      WHERE frk_registro = rIndexacao.frk_registro
        AND ind_origem = rIndexacao.ind_origem
        AND NVL(frk_formulario, -1) = NVL(rIndexacao.frk_formulario, -1)
        AND NVL(frk_arquivo, -1) = NVL(rIndexacao.frk_arquivo, -1)
        AND NVL(frk_tipo_arquivo, -1) = NVL(rIndexacao.frk_tipo_arquivo, -1)
        AND NVL(frk_tipo_consulta_externa,-1) = NVL(rIndexacao.frk_tipo_consulta_externa, -1)
        AND NVL(frk_registro_consulta_externa,-1) = NVL(rIndexacao.frk_registro_consulta_externa, -1)
        AND NVL(frk_consulta_regra,-1) = NVL(rIndexacao.frk_consulta_regra, -1);
    END IF;
    FOR nIndex IN 1..v_lCampoValorIndexacao.COUNT
    LOOP
      ---#153734 --- Inicia e reinicia como false para ser verificado novamente a cada loop.
      bExisteRegistroIndexador := false;
      rCampoValorIndexacao := v_lCampoValorIndexacao(nIndex);
      rIndexacao.num_linha := NVL(rCampoValorIndexacao.num_linha, rIndexacao.num_linha);
      rIndexacao.num_pagina := NVL(rCampoValorIndexacao.num_pagina, rIndexacao.num_pagina);
      rCampoValorIndexacao.frk_grupo := NVL(rCampoValorIndexacao.frk_grupo, rIndexacao.frk_grupo);
      rCampo := fDadosCampo(rCampoValorIndexacao.frk_campo);
      rFormularioCampo := fDadosFormularioCampo(rIndexacao.frk_formulario, rCampoValorIndexacao.frk_campo);
      IF v_ind_valdar_dados = pkg_constante.CONST_SIM AND rIndexacaoIn.ind_origem NOT IN(CONST_ORIGEM_BASE_EXTERNA, CONST_ORIGEM_BRSAFE) THEN
        IF rCampo.frk_tipo = 'select' AND rCampoValorIndexacao.val_indexador IS NOT NULL THEN
          rOpcao := fBuscarCampoOpcao(rCampoValorIndexacao.frk_campo, rCampoValorIndexacao.val_indexador);
          IF rOpcao.prk_campo_opcao IS NOT NULL THEN
            rCampoValorIndexacao.val_indexador := rOpcao.des_campo_opcao;
            rCampoValorIndexacao.cod_indexador_valor := rOpcao.prk_campo_opcao;
          ELSE
            RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -102, v_des_mensagem => 'Campo ' || rCampo.nom_campo || ' inválido.');
          END IF;
        ELSIF NOT fValidarCampo(rCampo.prk_campo, rCampo.frk_tipo, rCampoValorIndexacao.val_indexador, rFormularioCampo) THEN
          RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -102, v_des_mensagem => 'Campo ' || rCampo.nom_campo || ' inválido.');
        END IF;
      END IF;
        
        ---#153734: VERFICA SE HOUVE ALTERAÇÃO EM REGISTRO.  
        FOR tab_temp IN(
          SELECT val_indexador
               , target.rowid
            FROM sph_registro_indexador target                      
           WHERE target.frk_registro                        = rIndexacao.frk_registro
             AND target.frk_campo                             = rCampoValorIndexacao.frk_campo
             AND NVL(target.frk_grupo, -1)                    = NVL(rCampoValorIndexacao.frk_grupo, -1)
             AND target.ind_origem                            = rIndexacao.ind_origem
             AND NVL(target.frk_formulario, -1)               = NVL(NVL(rCampoValorIndexacao.frk_formulario, rIndexacao.frk_formulario), -1)
             AND NVL(target.frk_arquivo, -1)                  = NVL(rIndexacao.frk_arquivo, -1)
             AND NVL(target.frk_tipo_arquivo, -1)             = NVL(rIndexacao.frk_tipo_arquivo, -1)
             AND target.num_linha                             = NVL(rIndexacao.num_linha,1)
             AND NVL(target.frk_tipo_consulta_externa,-1)     = NVL(rIndexacao.frk_tipo_consulta_externa, -1)
             AND NVL(target.frk_consulta_externa,-1)          = NVL(rIndexacao.frk_consulta_externa, -1)
             AND NVL(target.frk_registro_consulta_externa,-1) = NVL(rIndexacao.frk_registro_consulta_externa, -1)
             AND NVL(target.frk_consulta_regra,-1)            = NVL(rIndexacao.frk_consulta_regra, -1)
        )
        LOOP
          bExisteRegistroIndexador := true;
            
          UPDATE sph_registro_indexador target 
             SET val_indexador = TRIM(rCampoValorIndexacao.val_indexador)
               , cod_indexador_valor = rCampoValorIndexacao.cod_indexador_valor
               , sts_indexador = NVL(rCampoValorIndexacao.sts_indexador, pkg_constante.CONST_IDX_PREENCHIDO)
               , des_matricula_alteracao = v_cod_usuario
               , dat_indexador_alteracao = SYSDATE
               , num_pagina = rIndexacao.num_pagina
               , ind_alerta = rCampoValorIndexacao.ind_alerta
               , ind_alteracao = CASE 
                                   WHEN pkg_base.fLimparString(NVL(val_indexador_original, val_indexador)) = pkg_base.fLimparString(rCampoValorIndexacao.val_indexador) THEN ind_alteracao
                                   ELSE pkg_constante.CONST_SIM
                                 END
           WHERE ROWID = tab_temp.rowid; 
         
        IF rIndexacao.ind_origem IN(CONST_ORIGEM_FORM_CADASTRO, CONST_ORIGEM_FORM_ARQUIVO) 
           AND (rCampoValorIndexacao.frk_campo IS NOT NULL AND (NVL(tab_temp.val_indexador, -1) != TRIM(NVL(rCampoValorIndexacao.val_indexador, -1)))) THEN

          vMensagemLog := rTipoArquivo.nom_tipo_arquivo
                       || ' editado campo ' || rCampo.nom_campo
                       || ' de '|| NVL(tab_temp.val_indexador, 'vazio')||' para '|| TRIM(NVL(rCampoValorIndexacao.val_indexador, 'vazio')) || '.';
                    
          pkg_registro.pLogarAlteracaoRegistro(v_cod_usuario, rIndexacao.frk_registro, PKG_CONSTANTE.CONST_ACT_REG_EDITADO, tab_temp.val_indexador, TRIM(rCampoValorIndexacao.val_indexador), vMensagemLog, rIndexacao.frk_arquivo);
        END IF;
            
        end loop;

    IF bExisteRegistroIndexador = FALSE then
        INSERT INTO sph_registro_indexador
              (frk_registro
              , frk_tipo_arquivo
              , frk_arquivo
              , frk_formulario
              , frk_grupo
              , frk_campo
              , ind_origem
              , val_indexador
              , cod_indexador_valor
              , sts_indexador
              , num_linha
              , num_pagina
              , des_matricula_indexador
              , frk_registro_fluxo
              , frk_consulta_externa
              , frk_tipo_consulta_externa
              , frk_registro_consulta_externa
              , frk_consulta_regra
              , frk_documento_brsafe
              , ind_alerta
              , ind_alteracao)
        VALUES (rIndexacao.frk_registro
              , rIndexacao.frk_tipo_arquivo
              , rIndexacao.frk_arquivo
              , NVL(rCampoValorIndexacao.frk_formulario, rIndexacao.frk_formulario)
              , rCampoValorIndexacao.frk_grupo
              , rCampoValorIndexacao.frk_campo
              , rIndexacao.ind_origem
              , TRIM(rCampoValorIndexacao.val_indexador)
              , rCampoValorIndexacao.cod_indexador_valor
              , NVL(rCampoValorIndexacao.sts_indexador, pkg_constante.CONST_IDX_PREENCHIDO)
              , NVL(rIndexacao.num_linha,1)
              , rIndexacao.num_pagina
              , v_cod_usuario
              , rIndexacao.frk_registro_fluxo
              , rIndexacao.frk_consulta_externa
              , rIndexacao.frk_tipo_consulta_externa
              , rIndexacao.frk_registro_consulta_externa
              , rIndexacao.frk_consulta_regra
              , rIndexacao.frk_documento_brsafe
              , rCampoValorIndexacao.ind_alerta
              , CASE 
                  WHEN v_ind_correcao = pkg_constante.CONST_SIM AND rCampoValorIndexacao.val_indexador IS NOT NULL THEN pkg_constante.CONST_SIM
                  ELSE pkg_constante.CONST_NAO
                END 
              );
      END IF;

      IF v_ind_idx_ocr = pkg_constante.CONST_SIM THEN
        UPDATE sph_registro_ocr a
           SET ind_acertividade = CASE
                                    WHEN val_campo_ocr IS NULL OR rCampoValorIndexacao.val_indexador IS NULL THEN NULL
                                    WHEN pkg_base.fLimparString(val_campo_ocr) = pkg_base.fLimparString(rCampoValorIndexacao.val_indexador)
                                      THEN pkg_constante.CONST_SIM
                                    ELSE pkg_constante.CONST_NAO
                                  END
         WHERE frk_registro = rIndexacao.frk_registro
           AND NVL(frk_arquivo, -1) = NVL(rIndexacao.frk_arquivo, -1)
           AND frk_campo_ocr = (
                 SELECT frk_campo_ocr
                   FROM idx_formulario_campo
                  WHERE 1=1
                    AND frk_formulario = NVL(rCampoValorIndexacao.frk_formulario, rIndexacao.frk_formulario)
                    AND frk_campo = rCampoValorIndexacao.frk_campo
                    AND frk_grupo = rCampoValorIndexacao.frk_grupo
               );
      END IF;
    END LOOP;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 1, rIndexacao.frk_registro);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(SQLERRM);
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -101, v_sql_code => SQLCODE, v_sql_error => SQLERRM  );
  END fSalvarCampoIndexacao;

  /**
   * Função para salvar os campos da indexação do fluxo
   * @param v_frk_registro_fluxo: Código da Fila
   * @param v_num_pagina: Número da página de onde foi retirada a indexação do arquivo
   * @param v_num_linha: Número da linha da indexação: Se NULL indica que é para adicionar uma nova linha para o campo
   * @param lCampoValorIndexacao: Campos da indexação
   ** /
  FUNCTION fSalvarCampoIndexacaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_num_pagina sph_registro_indexador.num_pagina%TYPE
                                    , v_num_linha sph_registro_indexador.num_linha%TYPE
                                    , lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno IS
    rRetorno pkg_dominio.recRetorno;
    rRegistroFluxo pkg_registro.recRegistroFluxo:=pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFluxo.frk_usuario_analise) ;
    rIndexacao sph_registro_indexador%ROWTYPE;
    rFluxo cfg_fluxo%ROWTYPE;
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -2);
    END IF;

    rFluxo := pkg_registro.fdadosfluxo(rRegistroFluxo.frk_fluxo);

    rIndexacao.frk_registro     := rRegistroFluxo.frk_registro;
    rIndexacao.frk_tipo_arquivo := rRegistroFluxo.cod_analise;
    rIndexacao.frk_arquivo      := rRegistroFluxo.cod_subanalise;
    rIndexacao.num_pagina       := v_num_pagina;
    rIndexacao.num_linha        := v_num_linha;
    rIndexacao.ind_origem       := CASE rFluxo.frk_modulo
                                     WHEN pkg_constante.CONST_MODL_INDEXACAO_DOCUMENTO THEN CONST_ORIGEM_FORM_ARQUIVO
                                     WHEN pkg_constante.CONST_MODL_INDEXACAO_REGISTRO THEN CONST_ORIGEM_FORM_CADASTRO
                                     WHEN pkg_constante.CONST_MODL_INDEXACAO_DIGITAL THEN CONST_ORIGEM_FORM_CADASTRO
                                     ELSE NULL
                                   END;
    rIndexacao.frk_formulario   := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo, rRegistroFluxo.cod_analise);
    rIndexacao.frk_registro_fluxo := v_frk_registro_fluxo;
    IF v_num_linha IS NULL THEN
      rIndexacao.num_linha := fBuscarCampoIndexacaoProxLinha;
    END IF;
    IF fValidarDuplicidade(rIndexacao, lCampoValorIndexacao) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -107);
    END IF;
    rRetorno := fSalvarCampoIndexacao(rUsuario.des_matricula, rIndexacao, lCampoValorIndexacao, v_rRegistroFluxo => rRegistroFluxo );
    IF rRetorno.prk_retorno > 0 THEN
      rRetorno.cod_registro := rIndexacao.num_linha;
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
    RETURN rRetorno;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -101);
  END fSalvarCampoIndexacaoFluxo;

  /**
   * Função para apagar a indexação de uma análise
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @param v_frk_grupo: Código do Grupo de indexação
   * @param v_frk_campo: Código do campo indexado (Se NULL será removido todos os campos do grupo)
   * @param v_num_linha: Linha da indexação que será apagada
   **/
  FUNCTION fRemoverIndexacaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                , v_frk_campo sph_registro_indexador.frk_campo%TYPE
                                , v_num_linha sph_registro_indexador.num_linha%TYPE) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo;
  BEGIN
    rRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);

    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_FLUXO, -2);
    END IF;

    DELETE sph_registro_indexador
     WHERE frk_registro = rRegistroFluxo.frk_registro
       AND frk_grupo = v_frk_grupo
       AND frk_campo = NVL(v_frk_campo, frk_campo)
       AND NVL(frk_tipo_arquivo, -1) = NVL(rRegistroFluxo.cod_analise, -1)
       AND NVL(frk_arquivo, -1) = NVL(rRegistroFluxo.cod_subanalise, -1)
       AND num_linha = v_num_linha;

    IF SQL%ROWCOUNT = 0 THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -103);
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 2);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -103);
  END fRemoverIndexacaoFluxo;

  /**
   * Função que busca valores préviamente utilizados no mesmo registro para o mesmo campo
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @param v_frk_campo: Código do campo
   * @param v_val_campo: Valor do campo
   * @return: Lista de valores que iniciam com o val_campo
   */
  FUNCTION fAutoCompleteIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_frk_campo sph_registro_indexador.frk_campo%TYPE
                                , v_val_campo sph_registro_indexador.val_indexador%TYPE) RETURN pkg_dominio.tSelectDefault PIPELINED IS
    rRegistroFluxo pkg_registro.recRegistroFluxo;
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
    rSelectDefault pkg_dominio.recSelectDefault;
  BEGIN
    rRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    /*
    IF cod_campo IN(10017, 10024) and cod_cliente = 1 THEN
       FOR tab_temp IN(
          SELECT column_value des_label
               , column_value des_value
            from TABLE(ged360db_ecm.fConsultarColaborador( cod_registro, cod_tipo_arquivo, cod_campo, val_campo))
       )
       LOOP
         PIPE ROW (tab_temp);
       END LOOP;
       RETURN;
    END IF;
    */
    FOR tab_temp IN (
      SELECT des_value
           , des_label
        FROM (SELECT DISTINCT
                     val_indexador des_label
                    , NVL(TO_CHAR(cod_indexador_valor), val_indexador) des_value
                FROM sph_registro_indexador
               WHERE 1=1
                 AND frk_registro = rRegistroFluxo.frk_registro
                 AND frk_campo = v_frk_campo
                 AND UPPER(val_indexador) LIKE UPPER(v_val_campo) || '%'
        )
       WHERE rownum <= 30
    )
    LOOP
      pkg_base.pInicializarJsonLista(lListaJsonObjeto);
      pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'frk_campo', v_frk_campo);
      pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'val', tab_temp.des_value);
      pkg_base.pAvancarJsonLista(lListaJsonObjeto);

      rSelectDefault.des_label := tab_temp.des_label;
      rSelectDefault.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);

      PIPE ROW(rSelectDefault);
    END LOOP;
    RETURN;
  END fAutoCompleteIndexacao;

  PROCEDURE fLimparIndexacaoArquivo(v_frk_registro sph_registro_indexador.frk_registro%TYPE
                                    , v_frk_tipo_arquivo sph_registro_indexador.frk_tipo_arquivo%TYPE
                                    , v_frk_arquivo sph_registro_indexador.frk_arquivo%TYPE) IS
  BEGIN
    DELETE sph_registro_indexador
     WHERE frk_registro = v_frk_registro
       AND frk_tipo_arquivo = v_frk_tipo_arquivo
       AND NVL(frk_arquivo, -1) = NVL(v_frk_arquivo, -1)
       AND ind_origem = pkg_constante.CONST_MODL_INDEXACAO_DOCUMENTO;
  END fLimparIndexacaoArquivo;

  /**
   * Função para reclassificar um arquivo, ou tipo de arquivo, na reclassificação
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fReclassificarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRetorno pkg_dominio.recRetorno;
    RECL_EXCEPTION EXCEPTION;
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.const_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -2);
    END IF;
    IF rRegistroFluxo.cod_analise = v_frk_tipo_arquivo THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -106);
    END IF;
    pkg_registro.pCancelarRegistroFluxo(v_frk_registro_fluxo, rRegistroFluxo);

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_digitalizacao.fListarArquivoRegistro(rRegistroFluxo.frk_registro, rRegistroFluxo.cod_analise, rRegistroFluxo.cod_subanalise))
    )
    LOOP
      rRetorno := pkg_digitalizacao.fReclassificarArquivo(v_frk_registro_fluxo, tab_temp.frk_arquivo, v_frk_tipo_arquivo, pkg_constante.CONST_NAO);
      IF rRetorno.prk_retorno < 0 THEN
        RAISE RECL_EXCEPTION;
      END IF;
    END LOOP;
    pkg_registro.pAtualizarFilaIndexacaoDoc(rRegistroFluxo);
    fLimparIndexacaoArquivo(rRegistroFluxo.frk_registro, rRegistroFluxo.cod_analise, rRegistroFluxo.cod_subanalise);
    pkg_registro.pEncerrarRegistro(rRegistroFluxo.frk_registro);
    COMMIT;
    RETURN rRetorno;
  EXCEPTION
    WHEN RECL_EXCEPTION THEN
      ROLLBACK;
      RETURN rRetorno;
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fReclassificarIndexacao;

  /**
   * Função para separar um arquivo em vários na etapa de indexação por documentos
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @param lArquivoNovo: Lista de novos arquivos gerados
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fSepararArquivoIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                  , lArquivoNovo pkg_digitalizacao.tArquivo) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRetorno pkg_dominio.recRetorno;
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.const_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -2);
    ELSIF rRegistroFluxo.cod_subanalise IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -105);
    END IF;
    rRetorno := pkg_digitalizacao.fSepararArquivo(v_frk_registro_fluxo, rRegistroFluxo.cod_subanalise, lArquivoNovo, pkg_constante.CONST_NAO);
    IF rRetorno.prk_retorno > 0 THEN
      pkg_registro.pAtualizarFilaIndexacaoDoc(rRegistroFluxo);
      fLimparIndexacaoArquivo(rRegistroFluxo.frk_registro, rRegistroFluxo.cod_analise, rRegistroFluxo.cod_subanalise);
      pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    END IF;

    RETURN rRetorno;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fSepararArquivoIndexacao;

  /**
   * Função para atualizar os principais indexadores na sph_registro de um registro
   * @param v_frk_registro: Código do registro
   **/
  PROCEDURE fAtualizarIndexacaoRegistro(v_frk_registro sph_registro.prk_registro%TYPE) IS
    vQueryUpdate VARCHAR2(4000);
    --nCPF VARCHAR2(200);
  BEGIN
    FOR tab_temp IN(
      WITH indexadores AS (
        SELECT cod_campo
             , frk_tipo
             , val_indexador
             , cod_indexador_valor
             , ROWNUM rnum
          FROM (
            SELECT *
              FROM sph_registro_indexador
             INNER JOIN idx_campo
                   ON prk_campo = frk_campo
             WHERE frk_registro = v_frk_registro
               AND ind_registro = pkg_constante.CONST_SIM
               AND cod_campo IS NOT NULL
             ORDER BY cod_campo, ind_origem, NVL(frk_tipo_arquivo, 0), dat_indexador
          )
      ), indx_grupo AS (
        SELECT cod_campo
             , MIN(rnum) rnum
          FROM indexadores
         GROUP BY cod_campo
      )
      SELECT *
        FROM indexadores
       INNER JOIN indx_grupo
             USING(cod_campo, rnum)
    )
    LOOP
      vQueryUpdate := vQueryUpdate || ', ' || tab_temp.cod_campo || ' = ''' || fFormatarCampo(tab_temp.frk_tipo, tab_temp.val_indexador, tab_temp.cod_indexador_valor, ind_processar_aspas_valor => pkg_constante.CONST_SIM) || ''' ';
      /*IF tab_temp.cod_campo = 'num_cpf' THEN
        nCPF := fFormatarCampo(tab_temp.frk_tipo, tab_temp.val_indexador, tab_temp.cod_indexador_valor);
      END IF;*/
    END LOOP;

    IF vQueryUpdate IS NOT NULL THEN
      vQueryUpdate := 'UPDATE sph_registro SET frk_cliente = frk_cliente ' || vQueryUpdate || ' WHERE prk_registro = ' || v_frk_registro;
      EXECUTE IMMEDIATE vQueryUpdate;
      /*IF nCPF IS NOT NULL THEN
        pkg_comparacao_base.pRegistrarSimilaridadeCPFFace(v_frk_registro, nCPF);
      END IF;*/
    END IF;

  END fAtualizarIndexacaoRegistro;

  FUNCTION fValidarPendenciaIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_rRegistroFluxo pkg_registro.recRegistroFluxo DEFAULT NULL
                                    , v_ind_correcao_formulario NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN VARCHAR2 IS
    vCamposPendente VARCHAR2(200);
    nFormulario idx_formulario.prk_formulario%TYPE;
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo, v_rRegistroFluxo);
    --// Range de páginas da indexação a serem exibidas
    nPaginaInicial NUMBER;
    nPaginaFinal NUMBER;
    vFrkTipoArquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE := rRegistroFluxo.cod_analise;
  BEGIN
    pBuscarPaginasFluxo(rRegistroFluxo.prk_registro_fluxo, nPaginaInicial, nPaginaFinal);
    nFormulario := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo, rRegistroFluxo.cod_analise);
    
    /*#133805 incluiu v_CorrecaoFormulario*/
    IF v_ind_correcao_formulario = pkg_constante.CONST_SIM THEN                          
       rRegistroFluxo.cod_analise    := NULL;
       rRegistroFluxo.cod_subanalise := NULL;   
    END IF;

    SELECT LISTAGG(nom_campo, '; ')
             WITHIN GROUP (ORDER BY nom_campo) des_campos
      INTO vCamposPendente
      FROM (
        SELECT DISTINCT
               CASE ifg.ind_multivalorado
                  WHEN 1 THEN nom_grupo
                  ELSE nom_campo
               END nom_campo
          FROM idx_formulario_campo ifc
         INNER JOIN idx_formulario_grupo ifg
               USING(frk_formulario, frk_grupo)
          INNER JOIN idx_campo
                ON prk_campo = frk_campo
          INNER JOIN idx_grupo
                ON prk_grupo = frk_grupo
          LEFT JOIN (SELECT *
                       FROM sph_registro_indexador a
                      WHERE frk_registro = rRegistroFluxo.frk_registro
                        AND NVL(frk_tipo_arquivo, -1) = NVL(rRegistroFluxo.cod_analise,-1)
                        AND NVL(frk_arquivo, -1) = NVL(rRegistroFluxo.cod_subanalise,-1)
                        AND (nPaginaInicial IS NULL OR nPaginaInicial <= num_pagina)
                        AND (nPaginaFinal IS NULL OR nPaginaFinal >= num_pagina)
                    ) spi
               USING(frk_formulario, frk_grupo, frk_campo)
         WHERE frk_formulario = nFormulario
           AND (ifc.ind_obrigatorio = pkg_constante.CONST_SIM OR ifg.ind_obrigatorio = pkg_constante.CONST_SIM)
           AND val_indexador IS NULL
           AND (sts_indexador = pkg_constante.CONST_IDX_PREENCHIDO OR sts_indexador IS NULL)
           AND (v_ind_correcao_formulario = pkg_constante.CONST_NAO OR frk_tipo_arquivo_associado = vFrkTipoArquivo)
      );
    RETURN vCamposPendente;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fValidarPendenciaIndexacao;

  /**
   * Função para processar a indexação de uma fila de análise 
       (ATENÇÃO: ESSA FUNÇÃO DEVERÁ SER UTILIZADA COMO COMPLEMENTAR PARA A CONCLUSÃO DAS FILAS QUE POSSUEM O MESMO PADRÃO DE INDEXAÇÃO)
     -- Utlizadas tanto na indexação padrão quando no modulo de Digitalização/Indexação
   * v_frk_registro_fluxo: Código da fila de análise
   * v_rRegistro_Fluxo: Record com os dados da fila de análise
   * v_rUsuario: Record com os dados do usuário
   **/
  FUNCTION fProcessarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                             , v_rRegistroFluxo pkg_registro.recRegistroFluxo
                             , v_rUsuario tab_usuario%ROWTYPE
                             , v_lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno IS
    vPendenciaFormulario VARCHAR2(1000);
    rRetorno pkg_dominio.recRetorno;

    rFluxo cfg_fluxo%ROWTYPE := pkg_registro.fdadosfluxo(v_rRegistroFluxo.frk_fluxo);
    rIndexacao sph_registro_indexador%ROWTYPE;

    nCorrecaoFormulario NUMBER := pkg_dominio.fValidarControleAcesso(v_frk_fluxo => v_rRegistroFluxo.frk_fluxo, v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_CORRECAO_FORMUL);
    nIndIdxDadosOcr NUMBER:= pkg_dominio.fValidarControleAcesso(v_frk_fluxo          => v_rRegistroFluxo.frk_fluxo
                                                              , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_UTILIZA_IDX_OCR);
  BEGIN
    IF v_rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 3);
    END IF;

    rIndexacao.frk_registro     := v_rRegistroFluxo.frk_registro;
    IF nCorrecaoFormulario = pkg_constante.CONST_NAO THEN
      rIndexacao.frk_tipo_arquivo := v_rRegistroFluxo.cod_analise;
      rIndexacao.frk_arquivo      := v_rRegistroFluxo.cod_subanalise;
    END IF;
    rIndexacao.ind_origem       := CASE rFluxo.frk_modulo
                                     WHEN pkg_constante.CONST_MODL_INDEXACAO_DOCUMENTO THEN CONST_ORIGEM_FORM_ARQUIVO
                                     WHEN pkg_constante.CONST_MODL_INDEXACAO_REGISTRO THEN CONST_ORIGEM_FORM_CADASTRO
                                     ELSE CONST_ORIGEM_FORM_CADASTRO
                                   END;
    IF nCorrecaoFormulario = pkg_constante.CONST_SIM THEN
      rIndexacao.ind_origem := CONST_ORIGEM_FORM_CADASTRO;
    END IF;
    rIndexacao.frk_formulario   := fBuscarIDFormularioFluxo(v_rRegistroFluxo.frk_fluxo, v_rRegistroFluxo.cod_analise);
    rIndexacao.frk_registro_fluxo := v_frk_registro_fluxo;

    IF nCorrecaoFormulario = pkg_constante.CONST_SIM THEN
      rRetorno := fSalvarCampoIndexacao(v_rUsuario.des_matricula, rIndexacao, v_lCampoValorIndexacao, v_ind_limpar => pkg_constante.CONST_NAO, v_ind_correcao => pkg_constante.CONST_SIM, v_ind_idx_ocr=> nIndIdxDadosOcr, v_rRegistroFluxo =>  v_rRegistroFluxo);
    ELSE 
      rRetorno := fSalvarCampoIndexacao(v_rUsuario.des_matricula, rIndexacao, v_lCampoValorIndexacao, v_ind_limpar => pkg_constante.CONST_SIM, v_ind_idx_ocr => nIndIdxDadosOcr, v_rRegistroFluxo =>  v_rRegistroFluxo);
    END IF;
    IF rRetorno.prk_retorno < 0 THEN
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    
    /*#133805 incluiu nCorrecaoFormulario no fValidarPendenciaIndexacao*/
    vPendenciaFormulario := fValidarPendenciaIndexacao(v_frk_registro_fluxo, v_rRegistroFluxo, nCorrecaoFormulario);       
    IF vPendenciaFormulario IS NOT NULL THEN
      rRetorno.prk_retorno := -1;
      rRetorno.des_mensagem := 'Informe os seguintes campos obrigatórios: ' || vPendenciaFormulario;
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    COMMIT;
    fAtualizarIndexacaoRegistro(v_rRegistroFluxo.frk_registro);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 3);
  END fProcessarIndexacao;
  
  /**
   * Função para finalizar a etapa de indexação
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fFinalizarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                             , v_lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRetorno pkg_dominio.recRetorno;
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFluxo.frk_usuario_analise) ;
     
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 3);
    END IF;

    rRetorno := fProcessarIndexacao(v_frk_registro_fluxo, rRegistroFluxo, rUsuario, v_lCampoValorIndexacao);
    IF rRetorno.prk_retorno < 0 THEN
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    COMMIT;
    pkg_consulta_externa.pVerificarConsultasExternas(rRegistroFluxo.frk_registro);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 3);
  EXCEPTION
    WHEN pkg_registro.EXCEPT_INTERROMPER_ETAPA THEN
      pkg_registro.pApagarDadosAnalise(v_frk_registro_fluxo,rRegistroFluxo);
      RETURN pkg_registro.fRetornarMensagemErroReg(v_frk_registro_fluxo);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(NULL, pkg_constante.CONST_FALHA, v_sql_code => SQLCODE, v_sql_error => SQLERRM);
  END fFinalizarIndexacao;

  /**
   * Função para processar todos os arquivos digitalizados e a indexação do módulo de Digitalizacao e Indexação integrados
   * @param v_frk_registro_fluxo: Código do Fluxo;
   * @param v_lArquivo: Lista com os arquivos enviados.
   * @param v_lCampoValorIndexacao: Lista de Indexadores do registro
   **/
  FUNCTION fFinalizarIndexacaoDigitaliza(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                       , v_lCampoValorIndexacao pkg_indexacao.tCampoValorIndexacao
                                       , v_lArquivo pkg_digitalizacao.tArquivo) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFluxo.frk_usuario_analise) ;
    rRetorno pkg_dominio.recRetorno;
    rArquivo sph_arquivo%ROWTYPE;
                                       
  BEGIN
    IF rRegistroFluxo.frk_registro IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO,-2);
    ELSIF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN 
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
    ELSIF v_frk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -5);
    ELSIF v_lArquivo.COUNT = 0 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -6);
    END IF;
    
    rRetorno := fProcessarIndexacao(v_frk_registro_fluxo, rRegistroFluxo, rUsuario, v_lCampoValorIndexacao);
    IF rRetorno.prk_retorno < 0 THEN
       ROLLBACK;
       RETURN rRetorno;
    END IF;
    
    FOR nIndex IN 1..v_lArquivo.COUNT
    LOOP
      rArquivo := v_lArquivo(nIndex);
      rArquivo.frk_registro := rRegistroFluxo.frk_registro;
      rArquivo.frk_registro_fluxo := v_frk_registro_fluxo;
      rRetorno := pkg_digitalizacao.fDigitalizarArquivo(rUsuario.des_matricula, rArquivo);
      IF rRetorno.prk_retorno < 0 THEN
         ROLLBACK;
         RETURN rRetorno;
      END IF;
      COMMIT;
    END LOOP;
    
    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    COMMIT;
    pkg_consulta_externa.pVerificarConsultasExternas(rRegistroFluxo.frk_registro);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN pkg_registro.EXCEPT_INTERROMPER_ETAPA THEN
      pkg_registro.pApagarDadosAnalise(v_frk_registro_fluxo,rRegistroFluxo);
      RETURN pkg_registro.fRetornarMensagemErroReg(v_frk_registro_fluxo);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN  pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM );
  END fFinalizarIndexacaoDigitaliza;


  /**
   * Retorna a indexação por documento de um determinado registro
   * @param v_frk_registro: Chave do registro
   * @return lista de campos indexados
   **/
  FUNCTION fRegistroIndexacaoCBE(v_frk_registro sph_registro.prk_registro%TYPE
                               , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                               , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                               , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tIdxConsultaExterna PIPELINED IS
    rIdxConsultaExterna recIdxConsultaExterna;
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
    rIndexacao sph_registro_indexador%ROWTYPE;
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    nRenalisar NUMBER := pkg_constante.CONST_NAO;
    nAcesso NUMBER := pkg_constante.CONST_SIM;
  BEGIN
    IF v_cod_usuario IS NOT NULL THEN
      nAcesso := pkg_dominio.fValidarControleAcesso(v_cod_usuario => v_cod_usuario
                                                  , v_frk_fluxo =>  rRegistroFluxo.frk_fluxo
                                                  , v_frk_modulo => pkg_constante.CONST_COD_MOD_REG_DETALHADO
                                                  , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_EXIBIR_CBE);
      IF nAcesso = pkg_constante.CONST_SIM AND v_frk_exportacao_registro IS NOT NULL THEN
        nAcesso := pkg_dominio.fValidarAcessoItemExportacao(v_frk_exportacao_registro, pkg_constante.CONST_COD_FUNC_EXIBIR_CBE);
      END IF;
      IF nAcesso <> pkg_constante.CONST_SIM THEN
        RETURN;
      END IF;
      nRenalisar := pkg_dominio.fValidarControleAcesso(v_cod_usuario => v_cod_usuario
                                                     , v_frk_fluxo => rRegistroFluxo.frk_fluxo
                                                     , v_frk_modulo => pkg_constante.CONST_COD_MOD_REG_DETALHADO
                                                     , v_frk_funcionalidade =>  pkg_constante.CONST_COD_FUNC_REANALISAR_CE);
    END IF;
    FOR tab_temp IN(
      SELECT prk_registro_consulta_externa
           , nom_consulta_externa
           , cod_cor
           , ind_alerta_consulta
           , sts_registro_consulta_externa
           , ind_origem
           , TO_CHAR(dat_consulta, 'dd/mm/yyyy hh24:mi:ss') dat_consulta
           , cce.ind_resumo
        FROM sph_registro_consulta_externa a
       INNER JOIN cfg_consulta_externa cce
             ON prk_consulta_externa = frk_consulta_externa
       WHERE frk_registro = v_frk_registro
         AND sts_registro_consulta_externa IN(pkg_consulta_externa.CONST_STS_CONSULTADO, pkg_consulta_externa.CONST_STS_NAO_CONSULTADO, pkg_consulta_externa.CONST_STS_CONSULTANDO)
    )
    LOOP
      rIdxConsultaExterna := NULL;
      rIdxConsultaExterna.ind_exibir := pkg_constante.CONST_SIM;
      rIdxConsultaExterna.frk_consulta_externa := tab_temp.prk_registro_consulta_externa;
      rIdxConsultaExterna.nom_consulta_externa := tab_temp.nom_consulta_externa;
      rIdxConsultaExterna.cod_cor := tab_temp.cod_cor;
      rIdxConsultaExterna.ind_alerta := tab_temp.ind_alerta_consulta;
      rIdxConsultaExterna.sts_consulta_externa := tab_temp.sts_registro_consulta_externa;
      rIdxConsultaExterna.ind_reanalisar := CASE
                                              WHEN tab_temp.sts_registro_consulta_externa = pkg_consulta_externa.CONST_STS_CONSULTADO THEN nRenalisar
                                              ELSE pkg_constante.CONST_NAO
                                            END;
      
      IF tab_temp.sts_registro_consulta_externa = pkg_consulta_externa.CONST_STS_CONSULTADO THEN
        rIdxConsultaExterna.frk_campo := -1;
        rIdxConsultaExterna.nom_campo := 'Origem';
        rIdxConsultaExterna.qtd_value := 1;
        rIdxConsultaExterna.des_value := pkg_consulta_externa.fBuscarOrigem(tab_temp.ind_origem);
        pkg_base.pInicializarJsonLista(lListaJsonObjeto);
        pAdicionarValorCampo(lListaJsonObjeto, rIdxConsultaExterna.des_value, rIdxConsultaExterna.des_value, NULL, 1, v_ind_resumido => pkg_constante.CONST_SIM);
        rIdxConsultaExterna.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);

        PIPE ROW(rIdxConsultaExterna);

        rIdxConsultaExterna.frk_campo := -2;
        rIdxConsultaExterna.nom_campo := 'Data da Consulta';
        rIdxConsultaExterna.qtd_value := 1;
        rIdxConsultaExterna.des_value := tab_temp.dat_consulta;
        pkg_base.pInicializarJsonLista(lListaJsonObjeto);
        pAdicionarValorCampo(lListaJsonObjeto, rIdxConsultaExterna.des_value, rIdxConsultaExterna.des_value, NULL, 1, v_ind_resumido => pkg_constante.CONST_SIM);
        rIdxConsultaExterna.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);

        PIPE ROW(rIdxConsultaExterna);


        -- // Se a consulta externa não possuir resumo, coloca pra exibir todos os campos da consulta;
        IF tab_temp.ind_resumo = pkg_constante.CONST_SIM THEN
          rIdxConsultaExterna.ind_exibir := NULL;
        END IF;
        
        FOR tab_temp2 IN (
          SELECT rIdxConsultaExterna.frk_consulta_externa
               , rIdxConsultaExterna.nom_consulta_externa
               , rIdxConsultaExterna.cod_cor
               , rIdxConsultaExterna.ind_alerta
               , frk_grupo
               , nom_grupo
               , frk_campo
               , nom_campo
               , qtd_value
               , TO_CHAR(des_value) des_value
               , rIdxConsultaExterna.ind_reanalisar
               , rIdxConsultaExterna.sts_consulta_externa
               , NVL(rIdxConsultaExterna.ind_exibir, ind_exibir_resumo)
               , prk_tipo cod_campo_tipo
            FROM (
                   SELECT frk_registro_consulta_externa prk_registro_consulta_externa
                        , MAX(frk_registro) frk_registro
                        , MAX(ind_alerta) ind_alerta
                        , idp.prk_grupo frk_grupo
                        , idp.nom_grupo nom_grupo
                        , idc.prk_campo frk_campo
                        , idc.nom_campo
                        , COUNT(1) qtd_value
                        , MAX(val_indexador) des_value
                        , ind_ordem_cbe_campo
                        , CASE 
                            WHEN MAX(ccer.frk_consulta_externa) IS NOT NULL THEN pkg_constante.CONST_SIM
                            ELSE pkg_constante.CONST_NAO
                          END ind_exibir_resumo
                        , itp.prk_tipo
                    FROM sph_registro_indexador idx
                   INNER JOIN idx_campo idc ON prk_campo = frk_campo
                    LEFT JOIN idx_grupo idp
                           ON idp.prk_grupo = frk_grupo
                    LEFT JOIN cbe_tipo_consulta_campo cbc
                           ON (cbc.frk_campo_default = idx.frk_campo AND cbc.frk_tipo_consulta_externa = idx.frk_tipo_consulta_externa AND (NVL(cbc.frk_grupo, -1) = NVL(idx.frk_grupo, -1)))
                    LEFT JOIN cfg_consulta_externa_resumo ccer
                      ON (frk_consulta_externa_campo = prk_consulta_externa_campo AND ccer.frk_consulta_externa = idx.frk_consulta_externa)
                    INNER JOIN idx_tipo itp ON itp.prk_tipo = idc.frk_tipo
                   WHERE ind_origem = CONST_ORIGEM_BASE_EXTERNA
                     AND frk_registro = v_frk_registro
                   GROUP BY frk_registro_consulta_externa
                          , idp.prk_grupo
                          , idp.nom_grupo
                          , idc.prk_campo
                          , idc.nom_campo
                          , ind_ordem_cbe_campo
                          , itp.prk_tipo
                 )
           WHERE frk_registro = v_frk_registro
             AND prk_registro_consulta_externa = tab_temp.prk_registro_consulta_externa
           ORDER BY ind_ordem_cbe_campo
                  , nom_campo
        )
        LOOP
          rIdxConsultaExterna := tab_temp2;
          IF rIdxConsultaExterna.qtd_value > 1  THEN
            rIndexacao.frk_registro := v_frk_registro;
            rIndexacao.ind_origem := CONST_ORIGEM_BASE_EXTERNA;
            rIndexacao.frk_campo := rIdxConsultaExterna.frk_campo;
            rIndexacao.frk_grupo := rIdxConsultaExterna.frk_grupo;
            rIndexacao.frk_registro_consulta_externa := tab_temp.prk_registro_consulta_externa;

            rIdxConsultaExterna.des_value := fBuscarIndexacaoRegistroCampo(rIndexacao, v_num_quantidade => pkg_constante.CONST_ITENS_CBE_INICIAL, v_ind_ordenacao => 2, v_ind_resumido => pkg_constante.CONST_SIM);
          ELSIF rIdxConsultaExterna.des_value IS NULL THEN
            CONTINUE;
          ELSE
            pkg_base.pInicializarJsonLista(lListaJsonObjeto);
            pAdicionarValorCampo(lListaJsonObjeto, rIdxConsultaExterna.des_value, rIdxConsultaExterna.des_value, NULL, 1, v_ind_resumido => pkg_constante.CONST_SIM);
            rIdxConsultaExterna.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
          END IF;
          PIPE ROW(rIdxConsultaExterna);
        END LOOP;
      ELSE
        rIdxConsultaExterna.frk_campo := -1;
        rIdxConsultaExterna.nom_campo := 'Status';

        pkg_base.pInicializarJsonLista(lListaJsonObjeto);
        pAdicionarValorCampo(lListaJsonObjeto, 'Em análise', 'Em análise', NULL, 1, v_ind_resumido => pkg_constante.CONST_SIM);
        rIdxConsultaExterna.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
        PIPE ROW(rIdxConsultaExterna);
      END IF;
    END LOOP;
    RETURN ;
  END fRegistroIndexacaoCBE;


  /**
   * Função para listar a indexaçao de um registro/arquivo
   * @param v_frk_registro: Código do Registro
   * @param v_ind_origem: Código da Origem
   * @param v_frk_tipo_arquivo: Código do tipo de arquivo (opcional)
   * @param v_frk_arquivo: Código do arquivo(opcional)
  **/
  FUNCTION fListarFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                   , v_ind_origem sph_registro_indexador.ind_origem%TYPE
                                   , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE DEFAULT NULL
                                   , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE DEFAULT NULL
                                   , v_ind_buscar_values NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN tFormularioIndexado PIPELINED IS
    rFormularioIndexado recFormularioIndexado;
    rIndexacao sph_registro_indexador%ROWTYPE;
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
  BEGIN
    FOR tab_temp IN(
      SELECT frk_formulario
           , nom_formulario
           , frk_grupo
           , nom_grupo
           , CASE
              WHEN COUNT(1) > 1 THEN pkg_constante.CONST_SIM
              ELSE pkg_constante.CONST_NAO
             END
           , MAX(frk_tipo_arquivo_associado)
           , frk_campo
           , nom_campo
           , COUNT(1) qtd_value
           , fFormatValorIndexacao(MAX(val_indexador), MAX(sts_indexador), NULL) des_value
        FROM (
          SELECT frk_formulario
               , NVL(nom_formulario, '') nom_formulario
               , frk_grupo
               , NVL(nom_grupo, '-') nom_grupo
               , ifg.ind_orderm ind_ordem_grupo
               , frk_campo
               , nom_campo
               , ifc.ind_ordem ind_ordem_campo
               , val_indexador
               , sts_indexador
               , frk_tipo_arquivo_associado
            FROM sph_registro_indexador a
           INNER JOIN idx_campo idc
                 ON prk_campo = frk_campo
            LEFT JOIN idx_grupo idg
                 ON prk_grupo = frk_grupo
            LEFT JOIN idx_formulario idf
                 ON prk_formulario = frk_formulario
            LEFT JOIN idx_formulario_grupo ifg
                 USING(frk_formulario, frk_grupo)
            LEFT JOIN idx_formulario_campo ifc
                 USING(frk_formulario, frk_grupo, frk_campo)
            WHERE frk_registro = v_frk_registro
              AND a.ind_origem = v_ind_origem
              AND NVL(frk_arquivo, -1) = NVL(v_frk_arquivo, -1)
              AND NVL(frk_tipo_arquivo, -1) = NVL(v_frk_tipo_arquivo, -1)
              AND sts_indexador <> pkg_constante.CONST_FALHA
        )
        GROUP BY frk_formulario
              , nom_formulario
              , frk_grupo
              , nom_grupo
              , ind_ordem_grupo
              , frk_campo
              , nom_campo
              , ind_ordem_campo
        ORDER BY nom_formulario, ind_ordem_grupo, nom_grupo, ind_ordem_campo, nom_campo
    )
    LOOP
      rFormularioIndexado := tab_temp;
      IF v_ind_buscar_values = pkg_constante.CONST_SIM THEN
        IF tab_temp.qtd_value > 1 THEN
          rIndexacao.frk_registro := v_frk_registro;
          rIndexacao.frk_tipo_arquivo := v_frk_tipo_arquivo;
          rIndexacao.ind_origem := v_ind_origem;
          rIndexacao.frk_arquivo := v_frk_arquivo;
          rIndexacao.frk_formulario := tab_temp.frk_formulario;
          rIndexacao.frk_campo := tab_temp.frk_campo;
          rIndexacao.frk_grupo := tab_temp.frk_grupo;

          rFormularioIndexado.des_value := fBuscarIndexacaoRegistroCampo(rIndexacao, v_ind_resumido => pkg_constante.CONST_SIM);
        ELSIF tab_temp.des_value IS NOT NULL THEN
          pkg_base.pInicializarJsonLista(lListaJsonObjeto);
          pAdicionarValorCampo(lListaJsonObjeto, tab_temp.des_value, tab_temp.des_value, NULL, 1);
          rFormularioIndexado.des_value := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
        ELSE
          CONTINUE;
        END IF;
      END IF;
      PIPE ROW(rFormularioIndexado);
    END LOOP;
  END fListarFormularioRegistro;

  /**
   * Função para listar a indexação geral de um registro
   * @param v_frk_registro: codigo do registro
   **/
  FUNCTION fListarFormCadastroRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                     , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                                     , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                                     , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexado PIPELINED IS
   rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
   nExibirDadosGerais NUMBER := pkg_constante.CONST_SIM;
  BEGIN
    IF v_cod_usuario IS NOT NULL OR v_frk_registro_fluxo IS NOT NULL THEN
      nExibirDadosGerais := pkg_dominio.fValidarControleAcesso(v_cod_usuario => v_cod_usuario
                                                             , v_frk_fluxo =>  rRegistroFluxo.frk_fluxo
                                                             , v_frk_modulo => pkg_constante.CONST_COD_MOD_REG_DETALHADO
                                                             , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_EXIBIR_FORM_CAD);
    END IF;
    IF nExibirDadosGerais = pkg_constante.CONST_SIM AND v_frk_exportacao_registro IS NOT NULL THEN
      nExibirDadosGerais := pkg_dominio.fValidarAcessoItemExportacao(v_frk_exportacao_registro, pkg_constante.CONST_COD_FUNC_EXIBIR_FORM_CAD);
    END IF;
    IF nExibirDadosGerais = pkg_constante.CONST_SIM THEN
      FOR tab_temp IN(
        SELECT *
          FROM TABLE(fListarFormularioRegistro(v_frk_registro, CONST_ORIGEM_FORM_CADASTRO))
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
    END IF;
  END fListarFormCadastroRegistro;

  /**
   * Função para buscar a indexação de um registro/formulário
   **/
  FUNCTION fListarFormCadastroRegistroPag(v_frk_registro sph_registro.prk_registro%TYPE
                                        , v_frk_formulario sph_registro_indexador.frk_grupo%TYPE
                                        , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                        , v_num_linha_inicio NUMBER
                                        , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED IS
    rIndexacaoCampo recListaIndexacaoCampo;
    rIndexacao sph_registro_indexador%ROWTYPE;
  BEGIN
    --// Inicializa o objeto para recuperar a indexação dos campos
    rIndexacao.frk_registro := v_frk_registro;
    rIndexacao.frk_grupo := v_frk_grupo;
    rIndexacao.frk_formulario := v_frk_formulario;

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioRegistro(v_frk_registro, CONST_ORIGEM_FORM_CADASTRO, v_ind_buscar_values => pkg_constante.CONST_NAO ))
       WHERE frk_grupo = v_frk_grupo
    )
    LOOP
      rIndexacaoCampo.frk_campo := tab_temp.frk_campo;
        --// Busca a indexação do campo retornado
      rIndexacao.frk_campo := tab_temp.frk_campo;
      rIndexacaoCampo.des_value := fBuscarIndexacaoRegistroCampo(rIndexacao, v_num_linha_inicio, v_num_quantidade, v_ind_resumido => pkg_constante.CONST_SIM);
      IF TRIM(rIndexacaoCampo.des_value) IS NULL THEN
        CONTINUE;
      END IF;
      PIPE ROW(rIndexacaoCampo);
    END LOOP;
  END fListarFormCadastroRegistroPag;

  /**
   * Função para listar a indexação de um arquivo
   * @param v_frk_registro: codigo do registro
   * @param v_frk_tipo_arquivo: Código do tipo de arquivo
   * @param v_frk_arquivo: Código do arquivo
   **/
  FUNCTION fListarFormArquivoRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                                    , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                                    , v_frk_tipo_arquivo sph_registro_indexador.frk_tipo_arquivo%TYPE
                                    , v_frk_arquivo sph_registro_indexador.frk_arquivo%TYPE
                                    , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexado PIPELINED IS
  BEGIN
    IF v_cod_usuario IS NULL OR v_frk_registro_fluxo IS NULL OR v_frk_exportacao_registro IS NULL THEN
      NULL;
    END IF;
    FOR tab_temp IN(
      SELECT *
        FROM TABLE(fListarFormularioRegistro(v_frk_registro, CONST_ORIGEM_FORM_ARQUIVO, v_frk_tipo_arquivo, v_frk_arquivo))
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarFormArquivoRegistro;

  /**
   * Função para buscar a indexação de um registro/formulário/arquivo
   **/
  FUNCTION fListarFormArquivoRegistroPag(v_frk_registro sph_registro.prk_registro%TYPE
                                       , v_frk_tipo_arquivo sph_registro_indexador.frk_tipo_arquivo%TYPE
                                       , v_frk_arquivo sph_registro_indexador.frk_arquivo%TYPE
                                       , v_frk_formulario sph_registro_indexador.frk_grupo%TYPE
                                       , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                       , v_num_linha_inicio NUMBER
                                       , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED IS
    rIndexacaoCampo recListaIndexacaoCampo;
    rIndexacao sph_registro_indexador%ROWTYPE;
  BEGIN
    --// Inicializa o objeto para recuperar a indexação dos campos
    rIndexacao.frk_registro := v_frk_registro;
    rIndexacao.frk_grupo := v_frk_grupo;
    rIndexacao.frk_formulario := v_frk_formulario;
    rIndexacao.frk_tipo_arquivo := v_frk_tipo_arquivo;
    rIndexacao.frk_arquivo := v_frk_arquivo;

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioRegistro(v_frk_registro, CONST_ORIGEM_FORM_ARQUIVO, v_frk_tipo_arquivo, v_frk_arquivo, v_ind_buscar_values => pkg_constante.CONST_NAO ))
       WHERE frk_grupo = v_frk_grupo
    )
    LOOP
      rIndexacaoCampo.frk_campo := tab_temp.frk_campo;
        --// Busca a indexação do campo retornado
      rIndexacao.frk_campo := tab_temp.frk_campo;
      rIndexacaoCampo.des_value := fBuscarIndexacaoRegistroCampo(rIndexacao, v_num_linha_inicio, v_num_quantidade, v_ind_resumido => pkg_constante.CONST_SIM);
      IF TRIM(rIndexacaoCampo.des_value) IS NULL THEN
        CONTINUE;
      END IF;
      PIPE ROW(rIndexacaoCampo);
    END LOOP;
  END fListarFormArquivoRegistroPag;

  /**
   * Função para buscar o dado de um determinado formulário em um registro
   * @param v_frk_registro: ID do registro
   * @param v_frk_formulario: ID do fomulário
   * @param v_frk_grupo: ID do grupo
   * @param v_frk_campo: ID do campo
  **/
  FUNCTION fGetDadoFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                    , v_frk_grupo idx_grupo.prk_grupo%TYPE
                                    , v_frk_campo idx_campo.prk_campo%TYPE) RETURN sph_registro_indexador.val_indexador%TYPE IS
    vValor VARCHAR2(200);
  BEGIN
    SELECT MAX(val_indexador)
      INTO vValor
      FROM sph_registro_indexador
     WHERE frk_registro = v_frk_registro
       AND frk_formulario = v_frk_formulario
       AND frk_grupo = v_frk_grupo
       AND frk_campo = v_frk_campo
       AND ind_origem = CONST_ORIGEM_FORM_CADASTRO;
    RETURN vValor;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fGetDadoFormularioRegistro;
  
  /**
   * Função que retorna lista de Multivalorados informados em linha.
   * @param v_frk_registro: Registro contendo campo multivalorado
   * @param v_frk_campo: Campo Multivalorado
   * @return record com dados do usuário
   **/
  FUNCTION fListarDadoFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                       , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                       , v_frk_grupo idx_grupo.prk_grupo%TYPE
                                       , v_frk_campo idx_campo.prk_campo%TYPE) RETURN STR_ARRAY IS
    lValores STR_ARRAY;
  BEGIN
    SELECT val_indexador
      BULK COLLECT INTO lValores
      FROM sph_registro_indexador
     WHERE frk_registro = v_frk_registro
       AND frk_campo    = v_frk_campo
       AND frk_grupo    = v_frk_grupo
       AND frk_formulario = v_frk_formulario;
    RETURN lValores;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fListarDadoFormularioRegistro;    

  /**
   * Função para listar os campos para o filtro do relatório de indexação
   * @param v_frk_formulário: Código do formulário
   * @return: lista dos campos do formulário
   **/
  FUNCTION fListarCamposFiltroIndexacao(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN tFormularioFiltroIndexacao PIPELINED IS

    FUNCTION fPreencherFiltroIndexacao(v_frk_grupo NUMBER
                                      , v_nom_grupo VARCHAR2
                                      , v_des_name_campo VARCHAR2
                                      , v_nom_campo VARCHAR2
                                      , v_cod_campo_tipo VARCHAR2
                                      , v_lListaOperador STR_ARRAY DEFAULT STR_ARRAY()) RETURN recFormularioFiltroIndexacao IS
      rFormularioFiltroIndexacao recFormularioFiltroIndexacao;
    BEGIN
      rFormularioFiltroIndexacao.frk_grupo      := v_frk_grupo;
      rFormularioFiltroIndexacao.nom_grupo      := v_nom_grupo;
      rFormularioFiltroIndexacao.des_name_campo := v_des_name_campo;
      rFormularioFiltroIndexacao.nom_campo      := v_nom_campo;
      rFormularioFiltroIndexacao.cod_campo_tipo := v_cod_campo_tipo;
      rFormularioFiltroIndexacao.des_operadores := pkg_indexacao.fTipoCampoOperadorJSON(v_cod_campo_tipo, v_lListaOperador);
      RETURN rFormularioFiltroIndexacao;
    END fPreencherFiltroIndexacao;

  BEGIN
    PIPE ROW(fPreencherFiltroIndexacao( -1, 'Registro', 'cod_registro_cliente', 'Protocolo', 'numerico', STR_ARRAY('=')));
    PIPE ROW(fPreencherFiltroIndexacao( -1, 'Registro', 'dat_registro', 'Data de Cadastro', 'data', STR_ARRAY('BETWEEN')));

    FOR tab_temp IN (
      SELECT frk_grupo
           , nom_grupo
           , des_name_campo
           , nom_campo
           , cod_campo_tipo
           , pkg_indexacao.fTipoCampoOperadorJSON(cod_campo_tipo)
           , CASE cod_campo_tipo
               WHEN 'select' THEN fGetOpcaoCampoJSON(frk_campo)
               ELSE NULL
             END
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(v_frk_formulario))
     )
     LOOP
       PIPE ROW(tab_temp);
     END LOOP;
  END fListarCamposFiltroIndexacao;

  /**
   *
   **/
  PROCEDURE pAdicionarQueryFiltro(v_lQueryFiltro IN OUT tFormularioQueryFiltro
                                , v_rQueryFiltro recFormularioQueryFiltro) IS
  BEGIN
    v_lQueryFiltro.EXTEND;
    v_lQueryFiltro(v_lQueryFiltro.COUNT) := v_rQueryFiltro;
  END pAdicionarQueryFiltro;

  FUNCTION fCriarObjQueryFiltro(v_cod_name_campo VARCHAR2,
                                v_frk_tipo idx_tipo.prk_tipo%TYPE,
                                v_cod_operador idx_operador.cod_operador%TYPE,
                                v_val_valor1 VARCHAR2,
                                v_val_valor2 VARCHAR2) RETURN recFormularioQueryFiltro IS
    rFormularioQueryFiltro recFormularioQueryFiltro;
  BEGIN
    rFormularioQueryFiltro.cod_name_campo  := v_cod_name_campo;
    rFormularioQueryFiltro.frk_tipo        := v_frk_tipo;
    rFormularioQueryFiltro.cod_operador    := v_cod_operador;
    rFormularioQueryFiltro.val_valor1      := v_val_valor1;
    rFormularioQueryFiltro.val_valor2      := v_val_valor2;
    RETURN rFormularioQueryFiltro;
  END fCriarObjQueryFiltro;
  /**
   * Função para gerar uma query com pivot dos campos de formulário específico
   * @param v_frk_formulario: Código do formulário
   * @param v_des_query: Output com a query gerada
   **/
  FUNCTION fBuscarQueryFormularioDinamico(v_cod_usuario tab_usuario.des_matricula%TYPE
                                        , v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE
                                        , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                        , v_lQueryFiltro tFormularioQueryFiltro) RETURN tFormularioQuery PIPELINED IS
    vQuery CLOB;
    vQueryFormulario CLOB;
    vPivot CLOB := '';
    vFields CLOB := '';
    vWhereIndexador CLOB := '';
    vOwner VARCHAR2(200):= LOWER(sys_context('userenv','current_schema') || '.');

    vWhere CLOB := '';
    rFormularioQueryFiltro recFormularioQueryFiltro;
    vGrupo CLOB;

    lListaJsonCampos pkg_base.tlistajsonobjeto;
    lListaJsonGrupos pkg_base.tlistajsonobjeto;
    nColspan NUMBER := 0;

    --// Controle de acesso da query
    nVisaoRestrita NUMBER;
    nVisaoBrFlow NUMBER;

    rFormularioQuery recFormularioQuery;

    PROCEDURE pAddGrupo(v_nom_grupo VARCHAR2) IS
    BEGIN
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonGrupos, 'nom_grupo', v_nom_grupo);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonGrupos, 'colspan', nColspan);
        pkg_base.pAvancarJsonLista(lListaJsonGrupos);
        nColspan := 0;
    END pAddGrupo;

    PROCEDURE pAddCampo(v_cod_campo VARCHAR2
                      , v_nom_campo VARCHAR2
                      , v_frk_tipo VARCHAR2 DEFAULT 'texto') IS
    BEGIN
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonCampos, 'cod_campo', v_cod_campo);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonCampos, 'nom_campo', v_nom_campo);
        pkg_base.pAdicionarJsonAtributoLista(lListaJsonCampos, 'frk_tipo', v_frk_tipo);
        nColspan := nColspan + 1;
        pkg_base.pAvancarJsonLista(lListaJsonCampos);
    END pAddCampo;
  BEGIN
    pkg_base.pInicializarJsonLista(lListaJsonCampos);
    pkg_base.pInicializarJsonLista(lListaJsonGrupos);

    pAddCampo('nom_workflow', 'Workflow', 'texto');
    pAddCampo('dat_registro', 'Data de Cadastro', 'data-hora');
    pAddCampo('cod_registro_cliente', 'Protocolo', 'numerico');
    pAddCampo('des_sts_registro', 'Status', 'texto');
    pAddCampo('dat_conclusao_registro', 'Data de Conclusão', 'data-hora');
    pAddCampo('nom_resultado', 'Resultado', 'texto');
    pAddGrupo('Geral');

    FOR tab_temp IN(
      SELECT frk_grupo
           , nom_grupo
           , nom_campo
           , frk_campo
           , des_name_campo
           , cod_campo_tipo
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(v_frk_formulario))
    )
    LOOP
      IF vGrupo IS NULL THEN
        vGrupo := tab_temp.nom_grupo;
      ELSIF vGrupo <> tab_temp.nom_grupo THEN
        pAddGrupo(vGrupo);
        vGrupo := tab_temp.nom_grupo;
      END IF;
      vFields := vFields || ', ' || 'NVL('||  tab_temp.des_name_campo || ', ''-'') ' ||  tab_temp.des_name_campo;
      vPivot := vPivot || '''' || v_frk_formulario || '_' || tab_temp.frk_grupo || '_' || tab_temp.frk_campo || ''' as  ' || tab_temp.des_name_campo ||  ',';
      vWhereIndexador := vWhereIndexador || '(' || tab_temp.frk_grupo || ',' || tab_temp.frk_campo ||'),';
      pAddCampo(tab_temp.des_name_campo, tab_temp.nom_campo, tab_temp.cod_campo_tipo);
    END LOOP;
    pAddGrupo(vGrupo);
    IF vPivot IS NULL THEN
      RETURN ;
    END IF;
    vPivot := SUBSTR(vPivot,1 ,LENGTH(vPivot)-1);
    vWhereIndexador := SUBSTR(vWhereIndexador,1 ,LENGTH(vWhereIndexador)-1);

    IF v_lQueryFiltro.COUNT <> 0 THEN
      FOR nIndex IN 1..v_lQueryFiltro.COUNT
      LOOP
        rFormularioQueryFiltro := v_lQueryFiltro(nIndex);

        IF rFormularioQueryFiltro.cod_operador IS NULL THEN
          CONTINUE;
        END IF;

        rFormularioQueryFiltro.val_valor1 := REPLACE(rFormularioQueryFiltro.val_valor1, '''', '''''');
        rFormularioQueryFiltro.val_valor2 := REPLACE(rFormularioQueryFiltro.val_valor2, '''', '''''');
        IF rFormularioQueryFiltro.cod_name_campo = 'dat_registro' THEN
          rFormularioQueryFiltro.val_valor1 := rFormularioQueryFiltro.val_valor1 || ' 00:00:00';
          rFormularioQueryFiltro.val_valor2 := rFormularioQueryFiltro.val_valor2 || ' 23:59:59';

        ELSIF rFormularioQueryFiltro.cod_operador NOT IN('=', 'LIKE') THEN
          CASE rFormularioQueryFiltro.frk_tipo
            WHEN 'moeda' THEN
              rFormularioQueryFiltro.cod_name_campo := 'TO_NUMBER(NVL(REPLACE(REGEXP_REPLACE(' || rFormularioQueryFiltro.cod_name_campo || ', ''[^0-9,]'', ''''), ''.'',''.''),''0''))';
              rFormularioQueryFiltro.val_valor1 := NVL(REPLACE(REGEXP_REPLACE(rFormularioQueryFiltro.val_valor1, '[^0-9,]', ''), '.','.'),'0');
              rFormularioQueryFiltro.val_valor2 := NVL(REPLACE(REGEXP_REPLACE(rFormularioQueryFiltro.val_valor2, '[^0-9,]', ''), '.','.'),'0');
            WHEN 'numerico' THEN
              rFormularioQueryFiltro.cod_name_campo := 'TO_NUMBER(NVL(REPLACE(REGEXP_REPLACE(' || rFormularioQueryFiltro.cod_name_campo || ', ''[^0-9,]'', ''''), ''.'',''.''),''0''))';
              rFormularioQueryFiltro.val_valor1 := NVL(REPLACE(REGEXP_REPLACE(rFormularioQueryFiltro.val_valor1, '[^0-9,]', ''), '.','.'),'0');
              rFormularioQueryFiltro.val_valor2 := NVL(REPLACE(REGEXP_REPLACE(rFormularioQueryFiltro.val_valor2, '[^0-9,]', ''), '.','.'),'0');
            WHEN 'data' THEN
              rFormularioQueryFiltro.cod_name_campo := 'TO_DATE(' || rFormularioQueryFiltro.cod_name_campo || ', ''dd/mm/yyyy'')';
            ELSE NULL;
          END CASE;
        ELSE
          CASE rFormularioQueryFiltro.frk_tipo
            WHEN 'cpf' THEN
              rFormularioQueryFiltro.cod_name_campo := 'REGEXP_REPLACE(' || rFormularioQueryFiltro.cod_name_campo ||  ', ''[^0-9]'','''')';
              rFormularioQueryFiltro.val_valor1 := REGEXP_REPLACE(rFormularioQueryFiltro.val_valor1, '[^0-9]', '');
            ELSE NULL;
          END CASE;
        END IF;
        CASE rFormularioQueryFiltro.cod_operador
          WHEN 'BETWEEN' THEN
            vWhere := vWhere || ' AND ' || rFormularioQueryFiltro.cod_name_campo || ' >= ''' || rFormularioQueryFiltro.val_valor1 || '''';
            vWhere :=  vWhere || ' AND ' || rFormularioQueryFiltro.cod_name_campo || ' <= ''' || rFormularioQueryFiltro.val_valor2 || '''';
          WHEN 'LIKE' THEN
            vWhere :=  vWhere || ' AND UPPER(' || rFormularioQueryFiltro.cod_name_campo || ') LIKE ''' || UPPER(rFormularioQueryFiltro.val_valor1) || '%''';
          ELSE
            vWhere :=  vWhere || ' AND UPPER(' || rFormularioQueryFiltro.cod_name_campo || ') ' || rFormularioQueryFiltro.cod_operador ||  ' ''' || UPPER(rFormularioQueryFiltro.val_valor1) || '''';
        END CASE;
      END LOOP;
    END IF;

    vQueryFormulario := '
      SELECT frk_registro
           , frk_tipo_arquivo
           , sts_indexador
           , num_linha
           ' || vFields ||  '
        FROM (
      SELECT frk_registro
           , frk_formulario || ''_'' || frk_grupo || ''_'' || frk_campo cod_campo
           , val_indexador
           , frk_tipo_arquivo
           , sts_indexador
           , num_linha
        FROM {OWNER}sph_registro_indexador
      WHERE frk_formulario = ' || v_frk_formulario || '
        AND val_indexador IS NOT NULL
        AND (frk_grupo, frk_campo) IN(' || vWhereIndexador || '))
      PIVOT (
        MAX(val_indexador)
        FOR cod_campo IN(' || vPivot || ') )';


    nVisaoRestrita := pkg_dominio.fValidarControleAcesso(v_cod_usuario  => v_cod_usuario, v_frk_modulo  => 220, v_frk_funcionalidade => 39);
    nVisaoBrFlow := pkg_dominio.fValidarControleAcesso(v_cod_usuario  => v_cod_usuario, v_frk_modulo         => 220, v_frk_funcionalidade => 49);

    IF nVisaoBrFlow = pkg_constante.CONST_SIM THEN
      vQuery := 'WITH nivel_hierarquico AS (
                    SELECT prk_nivel_hierarquico
                         , nom_nivel_hierarquico
                         , nom_cliente
                      FROM {OWNER}viw_nivel_hierarquico n
                  )';
    ELSE
      vQuery := 'WITH nivel_hierarquico AS ( SELECT prk_nivel_hierarquico
                           , nom_nivel_hierarquico
                           , nom_cliente
                        FROM {OWNER}viw_nivel_hierarquico n
                       START WITH n.prk_nivel_hierarquico = ' || v_frk_nivel_hierarquico || '
                     CONNECT BY PRIOR prk_nivel_hierarquico = n.frk_nivel_hierarquico)';
    END IF;


    vQuery := vQuery ||  ', status_registro AS (
                  SELECT des_value sts_registro
                       , des_label des_status_registro
                    FROM TABLE({OWNER}pkg_registro.fListarStatusRegistro('''|| v_cod_usuario || ''', ' || v_frk_nivel_hierarquico || '))
                )
                SELECT prk_registro
                     , nom_cliente
                     , nom_workflow
                     , nhr.nom_nivel_hierarquico
                     , NVL(TO_CHAR(dat_registro, ''dd/mm/yyyy hh24:mi:ss''), ''-'') dat_registro
                     , cod_registro_cliente
                     , sts_registro
                     , NVL({OWNER}pkg_registro.fBuscarStatusRegistro(sts_registro), ''-'') des_sts_registro
                     , NVL(TO_CHAR(dat_conclusao_registro, ''dd/mm/yyyy hh24:mi:ss''), ''-'') dat_conclusao_registro
                     , NVL((SELECT nom_resultado
                              FROM {OWNER}res_resultado
                             WHERE prk_resultado = frk_resultado), ''-'') nom_resultado
                     , tform.*
                  FROM (' || vQueryFormulario || ') tform
                 INNER JOIN {OWNER}sph_registro spr
                         ON prk_registro = frk_registro
                 INNER JOIN nivel_hierarquico nhr
                    ON nhr.prk_nivel_hierarquico = spr.frk_nivel_hierarquico_origem
                 INNER JOIN {OWNER}cfg_workflow cwf
                    ON cwf.frk_nivel_hierarquico = spr.frk_nivel_hierarquico
                 INNER JOIN {OWNER}tab_usuario
                    ON des_matricula_registro = des_matricula
                 WHERE sts_registro IN(SELECT sts_registro FROM status_registro)';
    IF nVisaoRestrita = pkg_constante.CONST_SIM THEN
      vQuery := vQuery || ' AND des_matricula_registro = ''' || v_cod_usuario || '''' ;
    END IF;
    vQuery := REPLACE(vQuery || ' ' || vWhere, '{OWNER}', vOwner);

    rFormularioQuery.des_query := vQuery;
    rFormularioQuery.des_campos := pkg_base.fProcessarJsonLista(lListaJsonCampos);
    rFormularioQuery.des_grupos := pkg_base.fProcessarJsonLista(lListaJsonGrupos);
    PIPE ROW(rFormularioQuery);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN;
  END fBuscarQueryFormularioDinamico;

  FUNCTION fLayOutIndexacao(v_frk_formulario  idx_formulario.prk_formulario%TYPE) RETURN varchar2 IS
   lLayout VARCHAR2(1000);
  BEGIN
    SELECT listagg (TRIM(nom_campo),';') WITHIN GROUP (ORDER BY idg.ind_orderm, idc.ind_ordem) layout INTO lLayout
     FROM idx_formulario_campo idc
    INNER JOIN idx_formulario_grupo idg
          using(frk_formulario, frk_grupo)
    INNER JOIN idx_campo
       ON (prk_campo = frk_campo)
    WHERE frk_formulario = v_frk_formulario
    GROUP BY frk_formulario;
    RETURN lLayout;
  END fLayOutIndexacao;
  
  /**
   * Função para listar os formulários disponíveis para um usuario na carga de importação
   * @param v_frk_nivel_hierarquico: Nível hierarquico do usuário do sistema
   * @return: Todos os Formulários que iniciam o processo de um Workflow em que o usuário está marcado para realizar (caso o processo de indexação não seja 
   **/
  FUNCTION fListarFormularioCarga(v_frk_nivel_hierarquico idx_formulario.frk_nivel_hierarquico%TYPE) RETURN  pkg_dominio.tSelectParam PIPELINED IS
    lListaJsonObjeto pkg_base.tlistajsonobjeto;
    rTemp pkg_dominio.recSelectParam;
  BEGIN
   FOR tab_temp IN (
      SELECT TO_CHAR(prk_formulario) prk_formulario
           , nom_workflow || ' - ' || nom_formulario AS nom_formulario
           , pkg_indexacao.fLayOutIndexacao(prk_formulario) des_parametro
        FROM cfg_workflow cwf
       INNER JOIN cfg_fluxo cff
          ON cff.prk_fluxo = cwf.frk_fluxo_inicial
       INNER JOIN cfg_fluxo_acesso cfa
          ON cfa.frk_fluxo = frk_fluxo_inicial
       INNER JOIN cfg_fluxo_formulario cfo
          ON cff.prk_fluxo = cfo.frk_fluxo
       INNER JOIN idx_formulario idf
          ON idf.prk_formulario = frk_formulario
       WHERE frk_modulo = pkg_constante.CONST_MODL_INDEXACAO_REGISTRO
         AND cfa.frk_nivel_hierarquico =  v_frk_nivel_hierarquico
      )
    LOOP
     pkg_base.pInicializarJsonLista(lListaJsonObjeto);
     pkg_base.pAdicionarJsonAtributoLista(lListaJsonObjeto, 'layout', tab_temp.des_parametro);
     pkg_base.pAvancarJsonLista(lListaJsonObjeto);
     rTemp.des_param := pkg_base.fProcessarJsonLista(lListaJsonObjeto);
     rTemp.des_value := tab_temp.prk_formulario;
     rTemp.des_label := tab_temp.nom_formulario;
     PIPE ROW(rTemp);
    END LOOP;
  END fListarFormularioCarga;

  /**
   * Função para realizar a carga de indexação em massa do sistema
   *   A função irá criar um registro com base no formulário enviado, inserir os dados enviados na linha importada e direcionar o registro para a análise
   * @param v_cod_usuario: Usuário que está realizando a carga
   * @param v_frk_formulario: Formulário para onde está indo a carga
   * @param vLinhaImportada: Linha com os dados a serem importados
   * @param v_demilitador: Delimitador que será utilizado para quebrar a vLinhaImportada e processar a carga
   **/
  FUNCTION fProcessarCarga(v_cod_usuario tab_usuario.des_matricula%TYPE
                         , v_frk_formulario idx_formulario.prk_formulario%TYPE
                         , vLinhaImportada VARCHAR2
                         , v_delimitador VARCHAR2
                         , v_delimitador2 VARCHAR2) RETURN pkg_dominio.recRetorno IS

    lLinha STR_ARRAY  := pkg_base.fExplodeStr(vString => vLinhaImportada, vDelimitrador => v_delimitador);
    lLayOut STR_ARRAY := pkg_base.fExplodeStr(vString => REPLACE(fLayOutIndexacao(v_frk_formulario),';',v_delimitador), vDelimitrador => v_delimitador);
    lCampoMultivalorado STR_ARRAY;
    lCampoValorIndexacao pkg_indexacao.tCampoValorIndexacao := pkg_indexacao.tCampoValorIndexacao();
    rCampoValorIndexacao pkg_indexacao.recCampoValorIndexacao;
    rFormulario idx_formulario%ROWTYPE:=fDadosFormulario(v_frk_formulario);
    rWorkflow cfg_workflow%ROWTYPE;
    nRegistroFluxoInicial NUMBER;
    nPosicao NUMBER := 1;

    nRegistro sph_registro.prk_registro%TYPE := NULL;
    rRetorno pkg_dominio.recRetorno;
    nCodRegistro sph_registro.cod_registro_cliente%TYPE;
    rIndexacao sph_registro_indexador%ROWTYPE;
    rUsuario tab_usuario%ROWTYPE:=pkg_dominio.fDadosUsuario(v_cod_usuario);
  BEGIN
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, v_cod_mensagem => -108);
    ELSIF v_delimitador = v_delimitador2 THEN 
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, v_cod_mensagem => -112); -- Delimitadores não podem ser iguais.
    ELSIF vLinhaImportada IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, v_cod_mensagem => -109);
    ELSIF UPPER(vLinhaImportada) = UPPER(REPLACE(fLayOutIndexacao(v_frk_formulario),';',v_delimitador)) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -110);
    ELSIF lLayOut.COUNT <> lLinha.COUNT THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, v_cod_mensagem => -111);
    ELSE
      FOR tab_temp IN(
         SELECT frk_grupo
              , frk_campo
              , nom_campo
              , idc.ind_obrigatorio
              , ifg.ind_multivalorado
              , frk_tipo
           FROM idx_formulario_campo idc
          INNER JOIN idx_formulario_grupo ifg
                USING (frk_formulario, frk_grupo)
          INNER JOIN idx_campo
                ON prk_campo = frk_campo
          WHERE frk_formulario = v_frk_formulario
          ORDER BY ifg.ind_orderm, idc.ind_ordem
      )
      LOOP
        IF tab_temp.ind_obrigatorio = pkg_constante.CONST_SIM AND lLinha(nPosicao) IS NULL THEN
          ROLLBACK;
          RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_des_mensagem =>  'Campo obrigatorio "' || tab_temp.nom_campo || '" nao informado');
        END IF;
               
        --// http://redmine.brscan.com.br/issues/102593
        /* Criação de uma outra combobox para separadores de grupos multivalorados
           Essa combobox traria os mesmos valores da atual Separador (Hífen (-), Pipe (|) e Ponto e Vírgula (;)), 
           porém o intuito desse campo seria definir como serão tratados múltiplos valores em grupos multivalorados.
        */
        IF tab_temp.ind_multivalorado = pkg_constante.CONST_NAO THEN
          --//http://redmine.brscan.com.br/issues/106829
          /*Mensagem Específica para Importação com falha em colunas - BD*/
          IF NOT fValidarCampo(tab_temp.frk_campo, tab_temp.frk_tipo, lLinha(nPosicao)) THEN
             RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -102, v_des_mensagem => 'Campo ' || tab_temp.nom_campo || ' inválido.');
          END IF;
        
          rCampoValorIndexacao.frk_grupo     := tab_temp.frk_grupo;
          rCampoValorIndexacao.frk_campo     := tab_temp.frk_campo;
          rCampoValorIndexacao.val_indexador := lLinha(nPosicao);
          pkg_indexacao.pAdicionarCampoIndexacao(lCampoValorIndexacao, rCampoValorIndexacao);
          nPosicao := nPosicao + 1;
        ELSE
          
          lCampoMultivalorado := pkg_base.fExplodeStr(lLinha(nPosicao), v_delimitador2);
          
          FOR nLinha IN 1..lCampoMultivalorado.COUNT
          LOOP
            --//http://redmine.brscan.com.br/issues/106829
            /*Mensagem Específica para Importação com falha em colunas - BD*/
            IF NOT fValidarCampo(tab_temp.frk_campo, tab_temp.frk_tipo, lCampoMultivalorado(nLinha)) THEN
               RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -102, v_des_mensagem => 'Campo ' || tab_temp.nom_campo || ' inválido.');
            END IF;
          
            rCampoValorIndexacao.frk_grupo     := tab_temp.frk_grupo;
            rCampoValorIndexacao.frk_campo     := tab_temp.frk_campo;
            rCampoValorIndexacao.val_indexador := lCampoMultivalorado(nLinha);
            rCampoValorIndexacao.num_linha     := nLinha;
            pkg_indexacao.pAdicionarCampoIndexacao(lCampoValorIndexacao, rCampoValorIndexacao);
          END LOOP;
        END IF;

      END LOOP;

      rRetorno := pkg_registro.fCriarRegistro(v_cod_usuario, rFormulario.frk_nivel_hierarquico, nCodRegistro, pkg_constante.CONST_NAO, v_ind_forcar_novo => pkg_constante.CONST_SIM);
      IF rRetorno.prk_retorno < 0 THEN
        RAISE pkg_dominio.EXPT_GERAL;
      END IF;

      nRegistro := rRetorno.cod_registro;
      --// Salvar a indexacao.
      rIndexacao.frk_registro := nRegistro;
      rIndexacao.frk_formulario := v_frk_formulario;
      rIndexacao.ind_origem := pkg_indexacao.CONST_ORIGEM_FORM_CADASTRO;
      rRetorno := pkg_indexacao.fSalvarCampoIndexacao(v_cod_usuario, rIndexacao, lCampoValorIndexacao);
      IF rRetorno.prk_retorno < 0 THEN
        RAISE pkg_dominio.EXPT_GERAL;
      END IF;
      COMMIT;

      --// Concluir criacao do registro
      pkg_registro.pRegistroInserirFila(nRegistro, rUsuario.prk_usuario);
      COMMIT;

      pkg_indexacao.fAtualizarIndexacaoRegistro(nRegistro);
      pkg_consulta_externa.pVerificarConsultasExternas(nRegistro);
      COMMIT;

      --// Busca fila de indexacao do registro
      rWorkflow := pkg_registro.fDadosWorkflow(rFormulario.frk_nivel_hierarquico);
      SELECT MAX(prk_registro_fluxo)
        INTO nRegistroFluxoInicial
        FROM sph_registro_analise
       WHERE frk_fluxo = rWorkflow.frk_fluxo_inicial
         AND frk_registro = nRegistro;
      IF nRegistroFluxoInicial IS NOT NULL THEN
        pkg_registro.pConcluirFilaRegistro(nRegistroFluxoInicial);
      END IF;

      pkg_registro.pEncerrarRegistro(nRegistro);
      COMMIT;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, pkg_constante.CONST_SUCESSO, nCodRegistro);
    END IF;
    EXCEPTION
      WHEN pkg_dominio.EXPT_GERAL THEN
        ROLLBACK;
        RETURN rRetorno;
      WHEN OTHERS THEN
        ROLLBACK;
        RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fProcessarCarga;
  
  /**
   * Função para retornar o formulário de dados de acordo com o fluxo do usuário
   * @param v_cod_usuario: Login do usuário
   **/
  FUNCTION fListarFormularioUsuario(v_cod_usuario tab_usuario.des_matricula%TYPE) RETURN tFormularioIndexacao PIPELINED IS
    rFormularioLinha recFormularioIndexacao;
    nNivelHierarquicoWF cfg_workflow.frk_nivel_hierarquico%TYPE;
    nFormulario idx_formulario.prk_formulario%TYPE;
  BEGIN
    SELECT frk_nivel_hierarquico
      INTO nNivelHierarquicoWF 
    FROM TABLE(pkg_registro.fListarWorkFlow(v_cod_usuario));

    SELECT MAX(prk_formulario)
      INTO nFormulario
      FROM cfg_workflow cwf
     INNER JOIN cfg_fluxo cff
        ON cff.prk_fluxo = cwf.frk_fluxo_inicial
     INNER JOIN cfg_fluxo_acesso cfa
        ON cfa.frk_fluxo = frk_fluxo_inicial
     INNER JOIN cfg_fluxo_formulario cfo
        ON cff.prk_fluxo = cfo.frk_fluxo
     INNER JOIN idx_formulario idf
        ON idf.prk_formulario = frk_formulario
     WHERE frk_modulo = pkg_constante.CONST_MODL_INDEXACAO_REGISTRO
       AND cfa.frk_nivel_hierarquico =  nNivelHierarquicoWF;

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(nFormulario))
    )
    LOOP
      rFormularioLinha := tab_temp;
      IF rFormularioLinha.cod_campo_tipo = 'select' THEN
        rFormularioLinha.des_opcao_campo := fGetOpcaoCampoJSON(rFormularioLinha.frk_campo);
      END IF;
      PIPE ROW(rFormularioLinha);
    END LOOP;
    RETURN ;
  END fListarFormularioUsuario;

  /**
   * Função para retornar o formulário de dados de acordo com o workflow informado
   * @param v_frk_workflow: ID do workflow
   **/
  FUNCTION fListarFormularioWorkflow(v_frk_workflow cfg_workflow.frk_nivel_hierarquico%TYPE) RETURN tFormularioIndexacao PIPELINED IS
    nFormulario idx_formulario.prk_formulario%TYPE;
  BEGIN
    SELECT MAX(prk_formulario)
      INTO nFormulario
      FROM cfg_workflow cwf
     INNER JOIN cfg_fluxo cff
        ON cff.prk_fluxo = cwf.frk_fluxo_inicial
     INNER JOIN cfg_fluxo_formulario cfo
        ON cff.prk_fluxo = cfo.frk_fluxo
     INNER JOIN idx_formulario idf
        ON idf.prk_formulario = frk_formulario
     WHERE frk_modulo = pkg_constante.CONST_MODL_INDEXACAO_REGISTRO
       AND cwf.frk_nivel_hierarquico =  v_frk_workflow;

    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(nFormulario))
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN ;
  
  END fListarFormularioWorkflow;
  
  -----------------------------------------------------------------------------
  -- Funções para Correção de indexação
  ------------------------------------------------------------------------------
  /**
   * Função para retornar o formulário de dados de acordo com o fluxo e o registro para coreção
   * @param v_frk_registro_fluxo: Código do fluxo de análise
   * @param v_frk_registro: Código do registro de origem dos dados
   **/
  FUNCTION fListarFormularioCorrecaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                        , v_frk_registro sph_registro.prk_registro%TYPE) RETURN tFormularioIndexacao PIPELINED IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rFormularioLinha recFormularioIndexacao;
    rIndexacao sph_registro_indexador%ROWTYPE;
    rFormulario idx_formulario%ROWTYPE;
    nCorrecao NUMBER;
  BEGIN
    --// Inicializa o objeto para recuperar a indexação dos campos
    rIndexacao.frk_registro := v_frk_registro;
    rIndexacao.frk_formulario := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo);
    rFormulario := fDadosFormulario(rIndexacao.frk_formulario);
    FOR tab_temp IN(
      SELECT *
        FROM TABLE(pkg_indexacao.fListarFormularioIndexacao(rIndexacao.frk_formulario, v_frk_registro))
    )
    LOOP
      rFormularioLinha := tab_temp;

      --// Busca a indexação do campo retornado
      rIndexacao.frk_campo := tab_temp.frk_campo;
      rIndexacao.frk_grupo := tab_temp.frk_grupo;
      rFormularioLinha.des_value_campo := pkg_indexacao.fBuscarIndexacaoRegistroCampoF(rIndexacao
                                                                                    , v_ind_correcao => nCorrecao
                                                                                    , v_ind_ordenacao => 2
                                                                                    , v_ind_buscar_dados_ocr => pkg_dominio.fValidarControleAcesso(v_frk_fluxo => rRegistroFluxo.frk_fluxo, v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_UTILIZA_IDX_OCR));
      IF rFormulario.cod_cor_correcao IS NOT NULL AND nCorrecao = pkg_constante.CONST_SIM THEN
        rFormularioLinha.cod_cor_sinalizacao := rFormulario.cod_cor_correcao;
      END IF;
      PIPE ROW(rFormularioLinha);
    END LOOP;
    RETURN ;
  END fListarFormularioCorrecaoFluxo;

  /**
   * Função para salvar os campos da indexação do fluxo
   * @param v_frk_registro_fluxo: Código da Fila
   * @param v_frk_registro: Código do registro
   * @param lCampoValorIndexacao: Campos da indexação
   **/
  FUNCTION fSalvarCampoCorrecaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_frk_registro sph_registro_indexador.frk_registro%TYPE
                                    , lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno IS
    vPendenciaFormulario VARCHAR2(1000);
    rRetorno pkg_dominio.recRetorno;
    rRegistroFluxo pkg_registro.recRegistroFluxo:=pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFluxo.frk_usuario_analise) ;
    rIndexacao sph_registro_indexador%ROWTYPE;
    rFluxo cfg_fluxo%ROWTYPE;
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -2);
    END IF;

    rFluxo := pkg_registro.fdadosfluxo(rRegistroFluxo.frk_fluxo);

    rIndexacao.frk_registro     := v_frk_registro;
    rIndexacao.ind_origem       := CONST_ORIGEM_FORM_CADASTRO;
    rIndexacao.frk_formulario   := fBuscarIDFormularioFluxo(rRegistroFluxo.frk_fluxo);
    rIndexacao.frk_registro_fluxo := v_frk_registro_fluxo;
    
    IF fValidarDuplicidade(rIndexacao, lCampoValorIndexacao) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -107);
    END IF;
    rRetorno := fSalvarCampoIndexacao(rUsuario.des_matricula, rIndexacao, lCampoValorIndexacao, v_rRegistroFluxo => rRegistroFluxo );
    IF rRetorno.prk_retorno < 0 THEN
      ROLLBACK;
      RETURN rRetorno;
    END IF;

    vPendenciaFormulario := fValidarPendenciaIndexacao(v_frk_registro_fluxo, rRegistroFluxo);
    IF vPendenciaFormulario IS NOT NULL THEN
      rRetorno.prk_retorno := -1;
      rRetorno.des_mensagem := 'Informe os seguintes campos obrigatórios: ' || vPendenciaFormulario;
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    fAtualizarIndexacaoRegistro(v_frk_registro);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, 3); 
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_INDEXACAO, -101);
  END fSalvarCampoCorrecaoFluxo;
  
  /**
   * Função que retorna os documentos disponíveis de OCR
   * @param v_sts_ocr_tipo_arquivo: indica o status do documento de OCR
   * @return: lista de documentos de OCR
   **/
  FUNCTION fListarDocumentosOcr RETURN pkg_dominio.tSelectNumber PIPELINED IS    
  BEGIN
    FOR tab_temp IN(
      SELECT ota.prk_ocr_tipo_arquivo           
           , ota.nom_ocr_tipo_arquivo             
      FROM ocr_tipo_arquivo ota    
     WHERE sts_ocr_tipo_arquivo = pkg_constante.CONST_SIM 
     ORDER BY nom_ocr_tipo_arquivo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN ;
  END fListarDocumentosOcr;

  /**
   * Função que retorna os campos OCR associado aos seus documentos
   * @param v_frk_ocr_tipo_arquivo: código do documento OCR;
   * @param v_sts_ocr_tipo_arquivo: indica o status do documento
   * @return: lista de campos
   **/
  FUNCTION fListarCamposOcr(v_frk_ocr_tipo_arquivo ocr_tipo_arquivo.prk_ocr_tipo_arquivo%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED IS  
  BEGIN
    FOR tab_temp IN(
      SELECT ocp.prk_campo_ocr
           --, ocp.cod_campo_ocr
           , ocp.des_campo_ocr           
      FROM ocr_tipo_arquivo ota
     INNER JOIN ocr_campo ocp
        ON prk_ocr_tipo_arquivo = frk_ocr_tipo_arquivo
     WHERE sts_ocr_tipo_arquivo = pkg_constante.CONST_SIM 
       AND frk_ocr_tipo_arquivo = v_frk_ocr_tipo_arquivo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN ;
  END fListarCamposOcr;  

  /**
   * Função para listar os dados do formulário de indexação de acordo com o NH e o tipo de arquivo
   * @param v_frk_formulario: código do formulário
   **/  
  FUNCTION fListarFormCampoOpcaoLista(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN tFormCampoOpcaoLista PIPELINED IS
  BEGIN
    FOR tab_temp IN(  
    SELECT ifc.frk_formulario
          ,ifc.frk_grupo
          ,idc.prk_campo
          ,idc.nom_campo
          ,ico.prk_campo_opcao
          ,ico.des_campo_opcao
      FROM idx_campo idc
     INNER JOIN idx_campo_opcao ico
        ON ico.frk_campo = idc.prk_campo
     INNER JOIN idx_formulario_campo ifc
        ON ifc.frk_campo = idc.prk_campo
     WHERE idc.frk_tipo = 'select'
       AND idc.sts_campo = pkg_constante.CONST_ATIVO
       AND ico.sts_campo_opcao = pkg_constante.CONST_ATIVO    
       AND ifc.frk_formulario = v_frk_formulario)
    LOOP
      PIPE ROW(tab_temp);      
    END LOOP;
    RETURN ;    
  END fListarFormCampoOpcaoLista; 
    
  /**
   * Função para listar as opções de campo de determinado formulário
   * @param v_frk_formulario: Código do Formulário
   **/
/*  FUNCTION fListarFormularioCampoOpcao(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN tFormularioIndexacao PIPELINED IS
  BEGIN
    SELECT SYSDATE FROM dual;
  END fListarFormularioCampoOpcao; */                                  
  
END pkg_indexacao;