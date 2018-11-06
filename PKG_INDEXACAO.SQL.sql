--------------------------------------------------------
--  Arquivo criado - ter�a-feira-novembro-06-2018   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package PKG_INDEXACAO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BRFLOW"."PKG_INDEXACAO" IS

  --// DECLARA��O DE CONSTANTES DE TIPO DE ORIGEM
  CONST_ORIGEM_FORM_CADASTRO CONSTANT NUMBER := 1;
  CONST_ORIGEM_FORM_ARQUIVO CONSTANT NUMBER := 2;
  CONST_ORIGEM_BASE_EXTERNA CONSTANT NUMBER := 3;
  CONST_ORIGEM_BRSAFE CONSTANT NUMBER := 4;
  CONST_ORIGEM_OCR_BRSAFE CONSTANT NUMBER := 5;
  CONST_ORIGEM_FORM_DIGIT CONSTANT NUMBER := 6;
  CONST_ORIGEM_FORM_OAB CONSTANT NUMBER := 7;  
  
  --// Constantes de campos default
  CONST_IDX_COD_NUM_CPF  CONSTANT NUMBER := 1;
  CONST_IDX_COD_NUM_RG  CONSTANT NUMBER := 6;
  CONST_IDX_COD_DAT_NASCIMENTO  CONSTANT NUMBER := 3;
  CONST_IDX_COD_COD_CATEGORIA  CONSTANT NUMBER := 9;
  CONST_IDX_COD_NUM_REGISTRO  CONSTANT NUMBER := 10;
  CONST_IDX_COD_DAT_VALIDADE  CONSTANT NUMBER := 311;
  CONST_IDX_COD_DAT_HABILITACAO  CONSTANT NUMBER := 11;
  CONST_IDX_COD_DAT_EMISSAO  CONSTANT NUMBER := 310;
  CONST_IDX_COD_DAT_EXPEDICAO  CONSTANT NUMBER := 7;
  CONST_IDX_COD_COD_DOCUMENTO  CONSTANT NUMBER := 308;
  CONST_IDX_COD_COD_RENACH  CONSTANT NUMBER := 106;
  CONST_IDX_COD_COD_UF  CONSTANT NUMBER := 302;

  TYPE recIdxConsultaExterna IS RECORD (
    frk_consulta_externa cbe_tipo_consulta_externa.prk_tipo_consulta_externa%TYPE,
    nom_consulta_externa cbe_tipo_consulta_externa.nom_tipo_consulta_externa%TYPE,
    cod_cor cbe_consulta_externa_nh.cod_cor%TYPE,
    ind_alerta sph_registro_indexador.ind_alerta%TYPE,
    frk_grupo idx_grupo.prk_grupo%TYPE,
    nom_grupo idx_grupo.nom_grupo%TYPE,
    frk_campo idx_campo.prk_campo%TYPE,
    nom_campo idx_campo.nom_campo%TYPE,
    qtd_value NUMBER,
    des_value VARCHAR2(4000),
    ind_reanalisar NUMBER,
    sts_consulta_externa NUMBER,
    ind_exibir NUMBER,
    prk_tipo idx_tipo.prk_tipo%TYPE
  );
  TYPE tIdxConsultaExterna IS TABLE OF recIdxConsultaExterna;

  TYPE recFormularioIndexacao IS RECORD (
    frk_formulario idx_formulario.prk_formulario%TYPE,
    nom_formulario idx_formulario.nom_formulario%TYPE,
    frk_grupo idx_grupo.prk_grupo%TYPE,
    nom_grupo idx_grupo.nom_grupo%TYPE,
    ind_grupo_multivalorado idx_formulario_grupo.ind_multivalorado%TYPE,
    ind_grupo_obrigatorio idx_formulario_grupo.ind_obrigatorio%TYPE,
    frk_tipo_arquivo_associado idx_formulario_grupo.frk_tipo_arquivo_associado%TYPE,
    frk_campo idx_campo.prk_campo%TYPE,
    des_name_campo VARCHAR2(50),
    nom_campo idx_grupo.nom_grupo%TYPE,
    cod_campo_tipo idx_tipo.prk_tipo%TYPE,
    ind_campo_obrigatorio idx_formulario_campo.ind_obrigatorio%TYPE,
    val_campo_maximo idx_formulario_campo.num_valor_maximo%TYPE,
    val_campo_minimo idx_formulario_campo.num_valor_minimo%TYPE,
    ind_campo_invalido idx_formulario_campo.ind_invalido%TYPE,
    ind_campo_autocomplete idx_formulario_campo.ind_autocomplete%TYPE,
    ind_campo_multivalorado idx_formulario_campo.ind_multivalorado%TYPE,
    frk_campo_ocr idx_formulario_campo.frk_campo_ocr%TYPE,
    des_regex idx_formulario_campo.des_regex%TYPE,    
    des_campo_ocr ocr_campo.des_campo_ocr%TYPE,
    frk_ocr_tipo_arquivo ocr_campo.frk_ocr_tipo_arquivo%TYPE,
    nom_ocr_tipo_arquivo ocr_tipo_arquivo.nom_ocr_tipo_arquivo%TYPE,
    des_opcao_campo VARCHAR2(4000),
    des_value_campo VARCHAR2(4000),
    cod_campo idx_campo.cod_campo%TYPE,
    ind_editavel idx_campo.ind_editavel%TYPE,
    cod_cor_sinalizacao idx_formulario_campo_alerta.cod_cor_sinalizacao%TYPE
  );
  TYPE tFormularioIndexacao IS TABLE OF recFormularioIndexacao;

  --//Record para salvar os dados da indexa��o
  TYPE recCampoValorIndexacao IS RECORD (
    frk_formulario sph_registro_indexador.frk_formulario%TYPE,
    frk_grupo idx_grupo.prk_grupo%TYPE,
    frk_campo idx_campo.prk_campo%TYPE,
    val_indexador sph_registro_indexador.val_indexador%TYPE,
    cod_indexador_valor sph_registro_indexador.cod_indexador_valor%TYPE,
    sts_indexador sph_registro_indexador.sts_indexador%TYPE,
    ind_alerta sph_registro_indexador.ind_alerta%TYPE,
    num_linha sph_registro_indexador.num_linha%TYPE,
    num_pagina sph_registro_indexador.num_pagina%TYPE
  );
  TYPE tCampoValorIndexacao IS TABLE OF recCampoValorIndexacao;

  TYPE recListaIndexacaoArquivo IS RECORD (
    frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE,
    frk_arquivo sph_arquivo.prk_arquivo%TYPE
  );
  TYPE tListaIndexacaoArquivo IS TABLE OF recListaIndexacaoArquivo;

  TYPE recListaIndexacaoCampo IS RECORD (
     frk_campo NUMBER,
     des_value VARCHAR2(4000)
  );
  TYPE tListaIndexacaoCampo IS TABLE OF recListaIndexacaoCampo;

  TYPE recCampoFormulario IS RECORD (
    frk_campo idx_formulario_campo.frk_campo%TYPE,
    ind_obrigatorio   idx_formulario_campo.ind_obrigatorio%TYPE,
    num_valor_minimo  idx_formulario_campo.num_valor_minimo%TYPE,
    num_valor_maximo  idx_formulario_campo.num_valor_maximo%TYPE,
    ind_invalido      idx_formulario_campo.ind_invalido%TYPE,
    ind_autocomplete  idx_formulario_campo.ind_autocomplete%TYPE,
    ind_multivalorado idx_formulario_campo.ind_multivalorado%TYPE,
    ind_editavel      idx_formulario_campo.ind_editavel%TYPE,
    frk_campo_ocr     idx_formulario_campo.frk_campo_ocr%TYPE,
    des_regex         idx_formulario_campo.des_regex%TYPE
  );
  TYPE tCampoFormulario IS TABLE OF recCampoFormulario;

  TYPE recGrupoFormulario IS RECORD (
    nom_grupo idx_grupo.nom_grupo%TYPE,
    ind_multivalorado idx_formulario_grupo.ind_multivalorado%TYPE,
    ind_obrigatorio idx_formulario_grupo.ind_obrigatorio%TYPE,
    frk_tipo_arquivo_associado idx_formulario_grupo.frk_tipo_arquivo_associado%TYPE,
    lCampoFormulario tCampoFormulario
  );

  TYPE tGrupoFormulario IS TABLE OF recGrupoFormulario;

  TYPE recFormulario IS RECORD (
    prk_formulario idx_formulario.prk_formulario%TYPE,
    frk_nivel_hierarquico idx_formulario.frk_nivel_hierarquico%TYPE,
    nom_formulario idx_formulario.nom_formulario%TYPE,
    lGrupoFormulario tGrupoFormulario
  );

  TYPE recListaCampoOpcao IS RECORD (
    prk_campo idx_campo.prk_campo%TYPE,
    frk_tipo  idx_campo.frk_tipo%TYPE,
    nom_tipo idx_tipo.nom_tipo%TYPE,
    nom_campo idx_campo.nom_campo%TYPE,
    sts_campo idx_campo.sts_campo%TYPE,
    des_status_campo VARCHAR2(100),
    ind_editavel NUMBER,
    des_campo_opcao VARCHAR2(3500)
  );
  TYPE tListaCampoOpcao IS TABLE OF recListaCampoOpcao;

  TYPE recFormularioIndexado IS RECORD (
    frk_formulario idx_formulario.prk_formulario%TYPE,
    nom_formulario idx_formulario.nom_formulario%TYPE,
    frk_grupo idx_grupo.prk_grupo%TYPE,
    nom_grupo idx_grupo.nom_grupo%TYPE,
    ind_grupo_multivalorado NUMBER,
    frk_tipo_arquivo_associado idx_formulario_grupo.frk_tipo_arquivo_associado%TYPE,
    frk_campo idx_campo.prk_campo%TYPE,
    nom_campo idx_grupo.nom_grupo%TYPE,
    qtd_value NUMBER,
    des_value VARCHAR2(4000)
  );
  TYPE tFormularioIndexado IS TABLE OF recFormularioIndexado;


  TYPE recFormularioFiltroIndexacao IS RECORD (
    frk_grupo        idx_grupo.prk_grupo%TYPE,
    nom_grupo        Idx_grupo.nom_grupo%TYPE,
    des_name_campo   VARCHAR2(200),
    nom_campo        idx_campo.nom_campo%TYPE,
    cod_campo_tipo   idx_tipo.prk_tipo%TYPE,
    des_operadores   VARCHAR2(500),
    des_opcao_campo VARCHAR2(4000)
  );
  TYPE tFormularioFiltroIndexacao IS TABLE OF recFormularioFiltroIndexacao;

  TYPE recFormularioQuery IS RECORD (
    des_query CLOB,
    des_grupos CLOB,
    des_campos CLOB
  );
  TYPE tFormularioQuery IS TABLE OF recFormularioQuery;

  /*
  TYPE recFormularioQueryFiltro IS RECORD (
    cod_name_campo VARCHAR2(200),
    frk_tipo idx_tipo.prk_tipo%TYPE,
    cod_operador idx_operador.cod_operador%TYPE,
    val_valor1 VARCHAR2(300),
    val_valor2 VARCHAR2(300)tFormularioQueryFiltro

  );
  TYPE tFormularioQueryFiltro IS TABLE OF recFormularioQueryFiltro;
  */
  TYPE tCampo IS TABLE OF idx_campo%ROWTYPE;
  
  TYPE recFormularioAlerta IS RECORD (
    cod_cor_sinalizacao idx_formulario_campo_alerta.cod_cor_sinalizacao%TYPE,
    des_alerta cfg_alerta.des_alerta%TYPE
  );
  
  TYPE tFormularioAlerta IS TABLE OF recFormularioAlerta;
    
  -----------------------------------------------------------------------------------------
  /**
   *
   **/
  FUNCTION fFormatValorIndexacao(v_val_indexador VARCHAR2
                               , v_sts_indexador sph_registro_indexador.sts_indexador%TYPE
                               , v_nvl_null VARCHAR2 DEFAULT '-') RETURN VARCHAR2;
  -----------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna o ID do campo de acordo com o seu c�digo
   * @param v_cod_campo: C�digo do campo
   * @return: ID do campo
   **/
  FUNCTION fGetCampoByCod(v_cod_campo idx_campo.cod_campo%TYPE) RETURN idx_campo%ROWTYPE;
  -----------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna o ID do campo de acordo com o seu c�digo
   * @param v_cod_grupo: C�digo do grupo
   * @return: Record do idx_grupo
   **/
  FUNCTION fGetGrupoByCod(v_cod_grupo idx_campo.cod_campo%TYPE) RETURN idx_grupo%ROWTYPE;
  -----------------------------------------------------------------------------------------
  /**
   * Fun��o para validar um valor de um campo
   * @param v_frk_campo: C�digo do Campo
   * @param v_frk_tipo: Tipo do Campo
   * @param v_val_campo: Valor do campo
   * @return TRUE/FALSE
   **/
  FUNCTION fValidarCampo(v_frk_campo idx_campo.prk_campo%TYPE
                       , v_frk_tipo idx_campo.frk_tipo%TYPE
                       , v_val_campo sph_registro_indexador.val_indexador%TYPE
                       , v_rFormularioCampo idx_formulario_campo%ROWTYPE DEFAULT NULL) RETURN BOOLEAN;
  -----------------------------------------------------------------------------------------
  FUNCTION fFormatarCampo(frk_tipo idx_tipo.prk_tipo%TYPE
                        , des_valor sph_registro_indexador.val_indexador%TYPE
                        , cod_valor VARCHAR2 DEFAULT NULL
                        , ind_aspas NUMBER DEFAULT pkg_constante.CONST_NAO
                        , ind_processar_aspas_valor NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN VARCHAR2;

  -----------------------------------------------------------------------------------------
  /**
   * Fun��o para retornar um json dos operadores de um tipo de campo
   * @param v_frk_tipo: C�digo do tipo de campo
   * @return JSON com a lista de operadores dispon�veis
   **/
  FUNCTION fTipoCampoOperadorJSON(v_frk_tipo idx_tipo.prk_tipo%TYPE
                                , v_lOperadorManual STR_ARRAY DEFAULT STR_ARRAY()) RETURN VARCHAR2;

  -----------------------------------------------------------------------------------------
  /**
   * Fun��o que lista os tipos de campos
   **/
  FUNCTION fListarTipoCampo RETURN pkg_dominio.tSelectDefault PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar uma op��o de um campo do tipo select
   **/
  FUNCTION fBuscarCampoOpcao(v_frk_campo idx_campo.prk_campo%TYPE
                           , v_frk_campo_opcao VARCHAR2) RETURN idx_campo_opcao%ROWTYPE;
  ------------------------------------------------------------------------------------------------------------------------------------
  FUNCTION fGetOpcaoCampoJSON(v_frk_campo idx_campo.prk_campo%TYPE
                            , v_ind_retornar_id NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN VARCHAR2;
  -----------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar e montar um retorno tSelectDefault de op��es de um campo
   * Substitui a fun��o fGetOpcaoCampoJSON
   * @param v_frk_campo: C�digo do campo
   * @return pkg_dominio.tSelectDefault
   * @Demanda: http://redmine.brscan.com.br/issues/115420
   **/
  FUNCTION fListarOpcaoCampo(v_frk_campo idx_campo.prk_campo%TYPE) RETURN pkg_dominio.tSelectDefault PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * 
   **/
  FUNCTION fListarOpcaoSegmento RETURN pkg_dominio.tSelectDefault PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna os campos dispon�veis e suas op��es dispon�veis
   * @param v_frk_cliente: c�digo do cliente;
   * @param v_ind_relatorio: indica os campos s�o para exibi��o de relat�rio, ou para listagem normal
   * @return: lista de campos
   **/
  FUNCTION fListarCampos(v_frk_cliente idx_campo.frk_cliente%TYPE
                       , v_ind_relatorio NUMBER DEFAULT pkg_constante.CONST_NAO) RETURN tListaCampoOpcao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar os dados de um campo
   **/
  FUNCTION fDadosCampo(v_frk_campo idx_campo.prk_campo%TYPE) RETURN idx_campo%ROWTYPE;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna os dados salvos de um campo e sua op��es
   * @param v_frk_campo: C�digo do campo consultado
   * @param v_rCampo: Record com os Dados dos Campos
   * @v_Opcoes: Retorno JSON de op��es do campo
   * @return: pkg_dominio.recRetorno;
   **/
  FUNCTION fDadosCampo(v_frk_campo idx_campo.prk_campo%TYPE
                     , v_rCampo IN OUT idx_campo%ROWTYPE
                     , v_des_opcoes IN OUT VARCHAR2) RETURN pkg_dominio.recRetorno;
                     
  FUNCTION fDadosFormulario(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN idx_formulario%ROWTYPE;
    
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para gerenciar o Cadastro/Edi��o de um Tipo de Arquivo
   * @param v_cod_usuario: matricula do usu�rio logado
   * @param v_rCampo: Record com os dados do arquivo
   * @param v_lOpcoes: Lista de Op��es do Campo
   * @return
   **/
  FUNCTION fGerenciarCampo(v_cod_usuario tab_usuario.des_matricula%TYPE
                         , v_rCampo idx_campo%ROWTYPE
                         , v_lOpcoes STR_ARRAY) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Ativa/Desativa um Campo
   * @param v_cod_usuario: Login do usu�rio logado no Sistema;
   * @param v_frk_campo: C�digo do Campo;
   * @return: pkg_dominio.recRetorno;
   **/
  FUNCTION fAtivarDesativarCampo(v_cod_usuario tab_usuario.des_matricula%TYPE
                               , v_frk_campo idx_campo.prk_campo%TYPE) RETURN pkg_dominio.RecRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para popular os grupos em um Formul�rio
   * @param v_rFormulario: Record do formul�rio
   * @param v_rGrupoFormulario: Record do grupo que ser� inserido
   **/
  PROCEDURE pAdicionarGrupoFormulario(v_rFormulario IN OUT recFormulario
                                    , v_rGrupoFormulario recGrupoFormulario);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para popular os campos do ultimo grupo inserido em um Formul�rio
   * @param v_rFormulario: Record do formul�rio
   * @param v_rCampoFormulario: Record do campo que ser� inserido
   **/
  PROCEDURE pAdicionarCampoFormulario(v_rFormulario IN OUT recFormulario
                                    , v_rCampoFormulario recCampoFormulario);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para gerenciar um formul�rio no sistema
   * @param v_cod_usuario: C�digo do usu�rio
   * @param v_rFormulario: Record do fomul�rio
  **/
  FUNCTION fGerenciarFormulario(v_cod_usuario tab_usuario.des_matricula%TYPE
                              , v_rFormulario recFormulario) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar os formul�rios dispon�veis de um workfow
   * @param v_frk_nivel_hierarquico: N�vel Hierarquico do workflow
   **/
  FUNCTION fListarFormulario(v_frk_nivel_hierarquico idx_formulario.frk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar os grupos de um formul�rio
   * @param v_frk_formulario: c�digo do formul�rio
   **/
  FUNCTION fListarFormularioGrupo(v_frk_formulario idx_formulario_grupo.frk_formulario%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar os campos de um formul�rio
   * @param v_frk_formulario: c�digo do formul�rio
   **/
  FUNCTION fListarFormularioCampo(v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                , v_frk_tipo idx_campo.frk_tipo%TYPE DEFAULT NULL) RETURN pkg_dominio.tSelectNumber PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar os dados do formul�rio de indexa��o de acordo com o NH e o tipo de arquivo
   * @param v_frk_nivel_hierarquico: C�digo do n�vel hierarquico
   * @param v_frk_tipo_arquivo: C�digo do tipo de arquivo
   **/
  FUNCTION fListarFormularioIndexacao(v_frk_formulario idx_formulario.prk_formulario%TYPE
                                    , v_frk_registro sph_registro.prk_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para gerar uma query com pivot dos campos de formul�rio espec�fico
   * @param v_frk_formulario: C�digo do formul�rio
   * @param v_des_query: Output com a query gerada
   **/
  FUNCTION fBuscarFormularioPivot(v_frk_formulario idx_formulario.prk_formulario%TYPE
                                , v_des_query IN OUT VARCHAR2) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /** 
   * Fun��o para popular a lista lFormularioAlerta
   **/
  PROCEDURE pAdicionarFormularioAlerta(lFormularioAlerta IN OUT tFormularioAlerta
                                     , rFormularioAlerta recFormularioAlerta);
  ------------------------------------------------------------------------------------------------------------------------------------
  /** 
   * Fun��o para gerenciar a sinaliza��o de alerta dos campos
   **/
  FUNCTION fGerenciarSinalizacaoCampo(v_frk_cliente tab_cliente.prk_cliente%TYPE
                                    , v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                    , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                    , v_frk_campo idx_formulario_campo.frk_campo%TYPE
                                    , lFormularioAlerta tFormularioAlerta)  RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /** 
   * Fun��o para listar a sinaliza��o de alerta do campo
   **/
  FUNCTION fListarSinalizacaoCampo(v_frk_formulario idx_formulario_campo.frk_formulario%TYPE
                                 , v_frk_grupo idx_formulario_campo.frk_grupo%TYPE
                                 , v_frk_campo idx_formulario_campo.frk_campo%TYPE)  RETURN tFormularioAlerta PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para retornar o formul�rio de dados de acordo com o fluxo
   * @param v_frk_registro_fluxo: C�digo do fluxo de an�lise
   **/
  FUNCTION fListarFormularioRegistroFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tFormularioIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar a indexa��o
   **/
  FUNCTION fListarIndexacaoGrupoCampo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                    , v_num_linha_inicio NUMBER
                                    , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para popular um array de campos indexados
   * @param lCampoValorIndexacao: Lista de campos
   * @param rCampoValorIndexacao: recod com o novo campo indexado
   **/
  PROCEDURE pAdicionarCampoIndexacao(lCampoValorIndexacao IN OUT tCampoValorIndexacao
                                   , rCampoValorIndexacao recCampoValorIndexacao);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para popular o record com os campos indexados do registro
   * @param lCampoValorIndexacao: Array com a lista de indexa��o
   * @param frk_campo: Chave do campo indexado
   * @param val_campo: Valor do campo indexado
   **/
  PROCEDURE pAdicionarCampoIndexacao(v_lCampo IN OUT tCampoValorIndexacao
                                   , v_frk_campo NUMBER
                                   , v_val_campo VARCHAR2);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para retornar a pr�xima linha de indexa��o
   **/
  FUNCTION fBuscarCampoIndexacaoProxLinha RETURN NUMBER;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para salvar a indexa��o de um campo
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
                               , v_rRegistroFluxo pkg_registro.recRegistroFluxo DEFAULT NULL) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para salvar os campos da indexa��o do fluxo
   * @param v_frk_registro_fluxo: C�digo da Fila
   * @param v_num_pagina: N�mero da p�gina de onde foi retirada a indexa��o do arquivo
   * @param v_num_linha: N�mero da linha da indexa��o: Se NULL indica que � para adicionar uma nova linha para o campo
   * @param lCampoValorIndexacao: Campos da indexa��o
   **/
  FUNCTION fSalvarCampoIndexacaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_num_pagina sph_registro_indexador.num_pagina%TYPE
                                    , v_num_linha sph_registro_indexador.num_linha%TYPE
                                    , lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para apagar a indexa��o de uma an�lise
   * @param v_frk_registro_fluxo: C�digo da fila de an�lise
   * @param v_frk_grupo: C�digo do Grupo de indexa��o
   * @param v_frk_campo: C�digo do campo indexado (Se NULL ser� removido todos os campos do grupo)
   * @param v_num_linha: Linha da indexa��o que ser� apagada
   **/

  FUNCTION fRemoverIndexacaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                , v_frk_campo sph_registro_indexador.frk_campo%TYPE
                                , v_num_linha sph_registro_indexador.num_linha%TYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o que busca valores pr�viamente utilizados no mesmo registro para o mesmo campo
   * @param v_frk_registro_fluxo: C�digo da fila de an�lise
   * @param v_frk_campo: C�digo do campo
   * @param v_val_campo: Valor do campo
   * @return: Lista de valores que iniciam com o val_campo
   */

  FUNCTION fAutoCompleteIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_frk_campo sph_registro_indexador.frk_campo%TYPE
                                , v_val_campo sph_registro_indexador.val_indexador%TYPE) RETURN pkg_dominio.tSelectDefault PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para reclassificar um arquivo, ou tipo de arquivo, na reclassifica��o
   * @param v_frk_registro_fluxo: C�digo da fila de an�lise
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da a��o
   **/
  FUNCTION fReclassificarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para separar um arquivo em v�rios
   * @param v_frk_registro_fluxo: C�digo da fila de an�lise
   * @param lArquivoNovo: Lista de novos arquivos gerados
   * @return pkg_dominio.recRetorno: Record com o resultado da a��o
   **/
  FUNCTION fSepararArquivoIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                  , lArquivoNovo pkg_digitalizacao.tArquivo) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para atualizar os principais indexadores na sph_registro de um registro
   * @param v_frk_registro: C�digo do registro
   **/
  PROCEDURE fAtualizarIndexacaoRegistro(v_frk_registro sph_registro.prk_registro%TYPE);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para processar a indexa��o de uma fila de an�lise 
       (ATEN��O: ESSA FUN��O DEVER� SER UTILIZADA COMO COMPLEMENTAR PARA A CONCLUS�O DAS FILAS QUE POSSUEM O MESMO PADR�O DE INDEXA��O)
     -- Utlizadas tanto na indexa��o padr�o quando no modulo de Digitaliza��o/Indexa��o
   * v_frk_registro_fluxo: C�digo da fila de an�lise
   * v_rRegistro_Fluxo: Record com os dados da fila de an�lise
   * v_rUsuario: Record com os dados do usu�rio
   **/
  FUNCTION fProcessarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                             , v_rRegistroFluxo pkg_registro.recRegistroFluxo
                             , v_rUsuario tab_usuario%ROWTYPE
                             , v_lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para finalizar a etapa de indexa��o
   * @param v_frk_registro_fluxo: C�digo da fila de an�lise
   * @return pkg_dominio.recRetorno: Record com o resultado da a��o
   **/
  FUNCTION fFinalizarIndexacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                             , v_lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para processar todos os arquivos digitalizados e a indexa��o do m�dulo de Digitalizacao e Indexa��o integrados
   * @param v_frk_registro_fluxo: C�digo do Fluxo;
   * @param v_lArquivo: Lista com os arquivos enviados.
   * @param v_lCampoValorIndexacao: Lista de Indexadores do registro
   **/
  FUNCTION fFinalizarIndexacaoDigitaliza(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                       , v_lCampoValorIndexacao pkg_indexacao.tCampoValorIndexacao
                                       , v_lArquivo pkg_digitalizacao.tArquivo) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Retorna a indexa��o por documento de um determinado registro
   * @param v_frk_registro: Chave do registro
   * @return lista de campos indexados
   **/
  FUNCTION fRegistroIndexacaoCBE(v_frk_registro sph_registro.prk_registro%TYPE
                               , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                               , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                               , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tIdxConsultaExterna PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar a indexa�ao de um registro/arquivo
   * @param v_frk_registro: C�digo do Registro
   * @param v_ind_origem: C�digo da Origem
   * @param v_frk_tipo_arquivo: C�digo do tipo de arquivo (opcional)
   * @param v_frk_arquivo: C�digo do arquivo(opcional)
  **/
  FUNCTION fListarFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                   , v_ind_origem sph_registro_indexador.ind_origem%TYPE
                                   , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE DEFAULT NULL
                                   , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE DEFAULT NULL
                                   , v_ind_buscar_values NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN tFormularioIndexado PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar a indexa��o geral de um registro
   * @param v_frk_registro: codigo do registro
   **/
  FUNCTION fListarFormCadastroRegistro(v_frk_registro sph_registro.prk_registro%TYPE DEFAULT NULL
                                     , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                                     , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                                     , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexado PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar a indexa��o de um registro/formul�rio
   **/
  FUNCTION fListarFormCadastroRegistroPag(v_frk_registro sph_registro.prk_registro%TYPE
                                        , v_frk_formulario sph_registro_indexador.frk_grupo%TYPE
                                        , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                        , v_num_linha_inicio NUMBER
                                        , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED;

  /**
   * Fun��o para listar a indexa��o de um arquivo
   * @param v_frk_registro: codigo do registro
   * @param v_frk_tipo_arquivo: C�digo do tipo de arquivo
   * @param v_frk_arquivo: C�digo do arquivo
   **/
  FUNCTION fListarFormArquivoRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_cod_usuario tab_usuario.des_matricula%TYPE DEFAULT NULL
                                    , v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE DEFAULT NULL
                                    , v_frk_tipo_arquivo sph_registro_indexador.frk_tipo_arquivo%TYPE
                                    , v_frk_arquivo sph_registro_indexador.frk_arquivo%TYPE
                                    , v_frk_exportacao_registro cfg_exportacao_registro.prk_exportacao_registro%TYPE DEFAULT NULL) RETURN tFormularioIndexado PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar a indexa��o de um registro/formul�rio/arquivo
   **/
  FUNCTION fListarFormArquivoRegistroPag(v_frk_registro sph_registro.prk_registro%TYPE
                                       , v_frk_tipo_arquivo sph_registro_indexador.frk_tipo_arquivo%TYPE
                                       , v_frk_arquivo sph_registro_indexador.frk_arquivo%TYPE
                                       , v_frk_formulario sph_registro_indexador.frk_grupo%TYPE
                                       , v_frk_grupo sph_registro_indexador.frk_grupo%TYPE
                                       , v_num_linha_inicio NUMBER
                                       , v_num_quantidade NUMBER DEFAULT pkg_constante.CONST_ITENS_INICIAL_IDX) RETURN tListaIndexacaoCampo PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para buscar o dado de um determinado formul�rio em um registro
   * @param v_frk_registro: ID do registro
   * @param v_frk_formulario: ID do fomul�rio
   * @param v_frk_grupo: ID do grupo
   * @param v_frk_campo: ID do campo
  **/
  FUNCTION fGetDadoFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                    , v_frk_grupo idx_grupo.prk_grupo%TYPE
                                    , v_frk_campo idx_campo.prk_campo%TYPE) RETURN sph_registro_indexador.val_indexador%TYPE;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna lista de Multivalorados informados em linha.
   * @param v_frk_registro: Registro contendo campo multivalorado
   * @param v_frk_campo: Campo Multivalorado
   * @return record com dados do usu�rio
   **/
  FUNCTION fListarDadoFormularioRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                       , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                       , v_frk_grupo idx_grupo.prk_grupo%TYPE
                                       , v_frk_campo idx_campo.prk_campo%TYPE) RETURN STR_ARRAY;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para listar os campos para o filtro do relat�rio de indexa��o
   * @param v_frk_formul�rio: C�digo do formul�rio
   * @return: lista dos campos do formul�rio
   **/
  FUNCTION fListarCamposFiltroIndexacao(v_frk_formulario idx_formulario.prk_formulario%TYPE) RETURN tFormularioFiltroIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para popular uma lista de campos para o formul�rio din�mico
   **/
  PROCEDURE pAdicionarQueryFiltro(v_lQueryFiltro IN OUT tFormularioQueryFiltro
                                , v_rQueryFiltro recFormularioQueryFiltro);
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para gerar uma query com pivot dos campos de formul�rio espec�fico
   * @param v_frk_formulario: C�digo do formul�rio
   * @param v_des_query: Output com a query gerada
   **/
  FUNCTION fBuscarQueryFormularioDinamico(v_cod_usuario tab_usuario.des_matricula%TYPE
                                        , v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE
                                        , v_frk_formulario idx_formulario.prk_formulario%TYPE
                                        , v_lQueryFiltro tFormularioQueryFiltro) RETURN tFormularioQuery PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  FUNCTION fLayOutIndexacao(v_frk_formulario  idx_formulario.prk_formulario%TYPE) RETURN varchar2;
  ------------------------------------------------------------------------------------------------------------------------------------
  FUNCTION fListarFormularioCarga(v_frk_nivel_hierarquico idx_formulario.frk_nivel_hierarquico%TYPE) RETURN  pkg_dominio.tSelectParam PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  FUNCTION fProcessarCarga(v_cod_usuario tab_usuario.des_matricula%TYPE
                         , v_frk_formulario idx_formulario.prk_formulario%TYPE
                         , vLinhaImportada VARCHAR2
                         , v_delimitador VARCHAR2
                         , v_delimitador2 VARCHAR2) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para retornar o formul�rio de dados de acordo com o fluxo do usu�rio
   * @param v_cod_usuario: Login do usu�rio
   **/
  FUNCTION fListarFormularioUsuario(v_cod_usuario tab_usuario.des_matricula%TYPE) RETURN tFormularioIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para retornar o formul�rio de dados de acordo com o workflow informado
   * @param v_frk_workflow: ID do workflow
   **/
  FUNCTION fListarFormularioWorkflow(v_frk_workflow cfg_workflow.frk_nivel_hierarquico%TYPE) RETURN tFormularioIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  -- Fun��es para Corre��o de indexa��o
  ------------------------------------------------------------------------------
  /**
   * Fun��o para retornar o formul�rio de dados de acordo com o fluxo e o registro para core��o
   * @param v_frk_registro_fluxo: C�digo do fluxo de an�lise
   * @param v_frk_registro: C�digo do registro de origem dos dados
   **/
  FUNCTION fListarFormularioCorrecaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                        , v_frk_registro sph_registro.prk_registro%TYPE) RETURN tFormularioIndexacao PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o para salvar os campos da indexa��o do fluxo
   * @param v_frk_registro_fluxo: C�digo da Fila
   * @param v_frk_registro: C�digo do registro
   * @param lCampoValorIndexacao: Campos da indexa��o
   **/
  FUNCTION fSalvarCampoCorrecaoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                    , v_frk_registro sph_registro_indexador.frk_registro%TYPE
                                    , lCampoValorIndexacao tCampoValorIndexacao) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------
  
  /**
   * Fun��o que retorna os documentos dispon�veis de OCR
   * @return: lista de documentos de OCR
   **/
  FUNCTION fListarDocumentosOcr RETURN pkg_dominio.tSelectNumber PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Fun��o que retorna os campos OCR associado aos seus documentos
   * @param v_frk_ocr_tipo_arquivo: c�digo do documento OCR; 
   * @return: lista de campos
   **/
  FUNCTION fListarCamposOcr(v_frk_ocr_tipo_arquivo ocr_tipo_arquivo.prk_ocr_tipo_arquivo%TYPE) RETURN pkg_dominio.tSelectNumber PIPELINED ;
  ------------------------------------------------------------------------------------------------------------------------------------
  
END pkg_indexacao;

/
