create or replace PACKAGE PKG_GRUPO_SLA IS
  TYPE recGrupoSlaDia IS RECORD (
    num_dia_semana NUMBER, /** 1 - Domingo; 7 - Sábado */
    hor_incio_sla VARCHAR2(20),
    hor_fim_sla VARCHAR2(20)
  );
  TYPE tGrupoSlaDia IS TABLE OF recGrupoSlaDia;

  TYPE recGrupoSla IS RECORD (
    prk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE,
    nom_grupo_sla cfg_grupo_sla.nom_grupo_sla%TYPE,
    sts_grupo_sla cfg_grupo_sla.sts_grupo_sla%TYPE,
    tem_limite_sla VARCHAR(20),
    frk_nivel_hierarquico cfg_grupo_sla.frk_nivel_hierarquico%TYPE
  );
 ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para recuperar os dados de um Grupo Sla
   * @param v_prk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fDadosGrupoSla(v_prk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE) RETURN cfg_grupo_sla%ROWTYPE;
  ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
  * Consulta todos os grupos ativos de SLA daquele nível Hierarquico ;
  * @param v_frk_nivel_hierarquico: ID do nível hieraquico pesquisado;
  * @return RECORD tGrupoSlaNivel com todos os grupos que se aplica ao nível hierarquico passado;
  **/
  FUNCTION fListarGrupoSlaNivelHierarq (v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED;

  ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para gerenciar as configurações do grupo SLA
   * @param v_cod_usuario
   * @param v_rWorkFlow: Record com os dados principais do workflow
   * @param v_tem_sla: Tempo SLA do registro no formato HH:MI
   * @param lWorkflowSlaDia: Array com o SLA de cada dia de trabalho a ser considerado
   * @return recRetorno com o resultado da ação
   **/
  FUNCTION fGerenciarGrupoSla(v_cod_usuario tab_usuario.des_matricula%TYPE
                            , v_rGrupoSla recGrupoSla
                            , lGrupoSlaDia tGrupoSlaDia) RETURN pkg_dominio.recRetorno;

  ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para adicionar um novo sla dia
   * @param v_lGrupoSlaDia: Lista de Sla's diarios
   * @param v_rGrupoSlaDia: Novo Sla dia
   **/
  PROCEDURE pAdicionarGrupoSlaDia(v_lGrupoSlaDia IN OUT tGrupoSlaDia
                                 , v_rGrupoSlaDia recGrupoSlaDia);

  ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para recuperar os dados para a edição de um Grupo Sla
   * @param v_prk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fDadosGrupoSla(v_prk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE
                        , v_rGrupoSla IN OUT recGrupoSla) RETURN pkg_dominio.recRetorno;

  ------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função que lista os SLAs de trabalho de um Grupo Sla
   * v_frk_grupo_sla: Código do Grupo Sla
   **/
  FUNCTION fListarGrupoSlaDia(v_frk_grupo_sla cfg_grupo_sla_dia.frk_grupo_sla%TYPE) RETURN tGrupoSlaDia PIPELINED;

  ------------------------------------------------------------------------------------------------------------------------------------------------
 /**
  * Ativa/Desativa o Grupo Sla;
  * @param v_cod_usuario: Código do usuário;
  * @param v_frk_grupo_sla: Código do Grupo SLA;
  * @return: Status atual do campo;
  **/
  FUNCTION fAtivarDesativarGrupoSla(v_cod_usuario tab_usuario.des_matricula%TYPE
                                 ,  v_frk_grupo_sla cfg_grupo_sla.prk_grupo_sla%TYPE) RETURN pkg_dominio.recRetorno;


END PKG_GRUPO_SLA;

