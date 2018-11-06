create or replace PACKAGE BODY PKG_GRUPO_SLA IS

  /**
  * Consulta todos os grupos ativos de SLA daquele nível Hierarquico ;
  * @param v_frk_nivel_hierarquico: ID do nível hieraquico pesquisado;
  * @return RECORD tGrupoSlaNivel com todos os grupos que se aplica ao nível hierarquico passado;
  
  **/
  FUNCTION fListarGrupoSlaNivelHierarq (v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED IS
  BEGIN
    FOR tab_temp IN
    (
    SELECT prk_grupo_sla
         , nom_grupo_sla
      FROM cfg_grupo_sla
     WHERE sts_grupo_sla  = pkg_constante.CONST_ATIVO
       AND frk_nivel_hierarquico = v_frk_nivel_hierarquico
    )
    LOOP
      PIPE ROW (tab_temp);
    END LOOP;
    RETURN;
  END fListarGrupoSlaNivelHierarq;

  /**
   * Verifica a existência de outro código de Workflow
   * @param v_rGrupoSla: Record do workflow para validação
   **/
  FUNCTION fExisteGrupoSlaCod(v_rGrupoSla recGrupoSla) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN

    SELECT COUNT(1)
      INTO nTotal
      FROM cfg_grupo_sla
    WHERE LOWER(nom_grupo_sla) = LOWER(v_rGrupoSla.nom_grupo_sla)
    AND (prk_grupo_sla <> v_rGrupoSla.prk_grupo_sla OR v_rGrupoSla.prk_grupo_sla IS NULL);

    IF nTotal > 0 THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END fExisteGrupoSlaCod;

    /**
    
   * Função para gerenciar as configurações gerais do workflow
   * @param v_cod_usuario
   * @param v_rGrupoSla: Record com os dados principais do workflow
   * @param v_tem_sla: Tempo SLA do registro no formato HH:MI
   * @param lGrupoSlaDia: Array com o SLA de cada dia de trabalho a ser considerado
   * @return recRetorno com o resultado da ação
   **/
  FUNCTION fGerenciarGrupoSla(v_cod_usuario tab_usuario.des_matricula%TYPE
                            , v_rGrupoSla recGrupoSla
                            , lGrupoSlaDia tGrupoSlaDia) RETURN pkg_dominio.recRetorno IS
    rGrupoSlaDia cfg_grupo_sla_dia%ROWTYPE;
    EXCEPT_HORA_SLA_INVALIDO EXCEPTION;
    pragma exception_init(EXCEPT_HORA_SLA_INVALIDO, -1850);

    v_PrkGrupoSla NUMBER;
  BEGIN
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -27);
    ELSIF v_rGrupoSla.frk_nivel_hierarquico IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -28);
    ELSIF v_rGrupoSla.nom_grupo_sla IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -25);
    ELSIF v_rGrupoSla.tem_limite_sla IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -26);
    ELSIF fExisteGrupoSlaCod(v_rGrupoSla) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -24);
    END IF;

    IF v_rGrupoSla.prk_grupo_sla IS NULL THEN
      INSERT INTO cfg_grupo_sla (frk_nivel_hierarquico, nom_grupo_sla, tem_limite_sla, des_matricula_criacao)
      VALUES (v_rGrupoSla.frk_nivel_hierarquico
            , v_rGrupoSla.nom_grupo_sla
            , pkg_base.fTransformarTempoToSegundo(v_rGrupoSla.tem_limite_sla)
            , v_cod_usuario) RETURNING prk_grupo_sla into v_PrkGrupoSla;
    ELSE
      UPDATE cfg_grupo_sla  a
             SET nom_grupo_sla = v_rGrupoSla.nom_grupo_sla
               , tem_limite_sla = pkg_base.fTransformarTempoToSegundo(v_rGrupoSla.tem_limite_sla)
               , des_matricula_alteracao = v_cod_usuario
               , dat_alteracao = SYSDATE
             WHERE prk_grupo_sla = v_rGrupoSla.prk_grupo_sla;

      v_PrkGrupoSla := v_rGrupoSla.prk_grupo_sla;
    END IF;

    DELETE cfg_grupo_sla_dia
     WHERE frk_grupo_sla = v_rGrupoSla.prk_grupo_sla;

    IF lGrupoSlaDia.COUNT > 0 THEN
      FOR nIndex IN 1..lGrupoSlaDia.COUNT
      LOOP
        rGrupoSlaDia.num_dia_semana := lGrupoSlaDia(nIndex).num_dia_semana;
        IF lGrupoSlaDia(nIndex).hor_incio_sla IS NULL OR lGrupoSlaDia(nIndex).hor_fim_sla IS NULL THEN
          RAISE EXCEPT_HORA_SLA_INVALIDO;
        END IF;
        rGrupoSlaDia.hor_incio_sla := TO_DATE(lGrupoSlaDia(nIndex).hor_incio_sla, 'hh24:mi');
        IF lGrupoSlaDia(nIndex).hor_fim_sla = '23:59' THEN
          rGrupoSlaDia.hor_fim_sla := TO_DATE(lGrupoSlaDia(nIndex).hor_fim_sla || ':59', 'hh24:mi:ss');
        ELSE
          rGrupoSlaDia.hor_fim_sla := TO_DATE(lGrupoSlaDia(nIndex).hor_fim_sla, 'hh24:mi');
        END IF;
        IF rGrupoSlaDia.hor_incio_sla > rGrupoSlaDia.hor_fim_sla THEN
          RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -29);
        END IF;
        INSERT INTO cfg_grupo_sla_dia (frk_grupo_sla, num_dia_semana, hor_incio_sla, hor_fim_sla)
         VALUES (v_PrkGrupoSla, rGrupoSlaDia.num_dia_semana, rGrupoSlaDia.hor_incio_sla , rGrupoSlaDia.hor_fim_sla);
      END LOOP;
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, 1);
  EXCEPTION
    WHEN EXCEPT_HORA_SLA_INVALIDO THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, -30);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM, v_sql_code => SQLCODE);
  END fGerenciarGrupoSla;

  /**
   * Função para adicionar um novo sla dia
   * @param v_lGrupoSlaDia: Lista de Sla's diarios
   * @param v_rGrupoSlaDia: Novo Sla dia
   **/
  PROCEDURE pAdicionarGrupoSlaDia(v_lGrupoSlaDia IN OUT tGrupoSlaDia
                                , v_rGrupoSlaDia recGrupoSlaDia) IS
  BEGIN
    v_lGrupoSlaDia.EXTEND;
    v_lGrupoSlaDia(v_lGrupoSlaDia.COUNT) := v_rGrupoSlaDia;
  END pAdicionarGrupoSlaDia;


  /**
   * Função para recuperar os dados de um Grupo Sla
   * @param v_prk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fDadosGrupoSla(v_prk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE) RETURN cfg_grupo_sla%ROWTYPE IS

    rGrupoSla cfg_grupo_sla%ROWTYPE;
  BEGIN
    SELECT *
      INTO rGrupoSla
      FROM cfg_grupo_sla
     WHERE prk_grupo_sla = v_prk_grupo_sla;

    RETURN rGrupoSla;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosGrupoSla;

  /**
   * Função para recuperar os dados para a edição de um Grupo Sla
   * @param v_prk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fDadosGrupoSla(v_prk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE
                        , v_rGrupoSla IN OUT recGrupoSla) RETURN pkg_dominio.recRetorno IS

  BEGIN
    SELECT prk_grupo_sla
           , nom_grupo_sla
           , sts_grupo_sla
           , pkg_base.fTransformarSegundosTempo(tem_limite_sla) as tem_limite_sla
           , frk_nivel_hierarquico
      INTO v_rGrupoSla
      FROM cfg_grupo_sla
     WHERE prk_grupo_sla = v_prk_grupo_sla;

    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fDadosGrupoSla;

  /**
   * Função que lista os SLAs de trabalho de um Grupo Sla
   * v_frk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fListarGrupoSlaDia(v_frk_grupo_sla cfg_grupo_sla_dia.frk_grupo_sla%TYPE) RETURN tGrupoSlaDia PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT num_dia_semana
           , TO_CHAR(hor_incio_sla, 'HH24:MI') as hor_incio_sla
           , TO_CHAR(hor_fim_sla, 'HH24:MI') as hor_fim_sla
        FROM cfg_grupo_sla_dia
       WHERE frk_grupo_sla = v_frk_grupo_sla
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarGrupoSlaDia;

 /**
  * Ativa/Desativa o Grupo Sla;
  * @param v_cod_usuario: Código do usuário;
  * @param v_frk_grupo_sla: Código do Grupo SLA;
  * @return: Status atual do campo;
  **/
  FUNCTION fAtivarDesativarGrupoSla(v_cod_usuario tab_usuario.des_matricula%TYPE
                                  , v_frk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE) RETURN pkg_dominio.recRetorno IS
    nStatus cfg_grupo_sla.sts_grupo_sla%TYPE;
  BEGIN
    UPDATE cfg_grupo_sla
       SET sts_grupo_sla = CASE
                             WHEN sts_grupo_sla = pkg_constante.CONST_ATIVO THEN pkg_constante.CONST_INATIVO
                             ELSE pkg_constante.CONST_ATIVO
                           END
         , dat_alteracao = SYSDATE
         , des_matricula_alteracao = v_cod_usuario
    WHERE prk_grupo_sla = v_frk_grupo_sla
    RETURNING sts_grupo_sla INTO nStatus;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GRUPO_SLA, 2, nStatus);
  END fAtivarDesativarGrupoSla;

END PKG_GRUPO_SLA;

