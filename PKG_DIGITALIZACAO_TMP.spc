CREATE OR REPLACE PACKAGE "PKG_DIGITALIZACAO_TMP" IS

  --// Tipos de Local de Digitalização de arquivos
  CONST_IND_LOCAL_ARQUIVO_LOCAL CONSTANT NUMBER := 1;
  CONST_IND_LOCAL_ARQUIVO_BRSCAN CONSTANT NUMBER := 2;

  --// Tipos de demarcação de campo dos templates
  CONST_TIPTEMPL_CAMPO_FORM CONSTANT NUMBER := 1;
  CONST_TIPTEMPL_CAMPO_ASS  CONSTANT NUMBER := 2;

  --// Tipos de assinatura realizada pelo usuário:
  CONST_TIPASSINAT_ASSINATURA CONSTANT NUMBER := 1;
  CONST_TIPASSINAT_CERTIFICADO CONSTANT NUMBER := 2;
  CONST_TIPASSINAT_PDF CONSTANT NUMBER := 3;

  TYPE tTipoArquivo IS TABLE OF cfg_tipo_arquivo%ROWTYPE;

  TYPE recListaArquivo IS RECORD (
    frk_arquivo sph_arquivo.prk_arquivo%TYPE,
    frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE,
    cam_arquivo VARCHAR2(3999),
    num_pagina sph_arquivo.num_pagina%TYPE,
    qtd_pagina sph_arquivo.qtd_pagina%TYPE,
    ind_local NUMBER,
    cod_origem VARCHAR2(50),
    ind_carimbo_tempo NUMBER
  );

  TYPE tListaArquivo IS TABLE OF recListaArquivo;
  TYPE tArquivo IS TABLE OF sph_arquivo%ROWTYPE;

  TYPE recTipoArquivoGestao IS RECORD (
       prk_tipo_arquivo   cfg_tipo_arquivo.prk_tipo_arquivo%TYPE
     , frk_cliente        cfg_tipo_arquivo.frk_cliente%TYPE
     , nom_tipo_arquivo   cfg_tipo_arquivo.nom_tipo_arquivo%TYPE
     , frk_grupo_arquivo  cfg_grupo_arquivo.prk_grupo_arquivo%TYPE
     , nom_grupo_arquivo  cfg_grupo_arquivo.nom_grupo_arquivo%TYPE
     , frk_tipo_arquivo_analise cfg_tipo_arquivo_analise.prk_tipo_arquivo_analise%TYPE
     , nom_tipo_arquivo_analise cfg_tipo_arquivo_analise.nom_tipo_arquivo_analise%TYPE
     , frk_documento_brsafe      pre_documento.prk_documento%TYPE
     , nom_documento_brsafe      pre_documento.des_documento%TYPE
     , ind_digitalizar    cfg_nivel_hierarquico_arquivo.ind_digitalizar%TYPE
     , des_digitalizar    CHAR(4)
     , ind_obrigatorio cfg_nivel_hierarquico_arquivo.ind_obrigatorio%TYPE
     , ind_reclassificar  cfg_nivel_hierarquico_arquivo.ind_reclassificar%TYPE
     , des_reclassificar  CHAR(4)
     , ind_editar         NUMBER
     , ind_fotografia cfg_nivel_hierarquico_arquivo.ind_fotografia%TYPE
     , cod_cor cfg_nivel_hierarquico_arquivo.cod_cor%TYPE
     , ind_face cfg_tipo_arquivo.ind_face%TYPE
     , cod_tipo_arquivo cfg_tipo_arquivo.cod_tipo_arquivo%TYPE
  );
  TYPE tTipoArquivoGestao IS TABLE OF recTipoArquivoGestao;


  TYPE recArquivoRegistro IS RECORD (
    prk_arquivo sph_arquivo.prk_arquivo%TYPE,
    frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE,
    nom_tipo_arquivo cfg_tipo_arquivo.nom_tipo_arquivo%TYPE,
    cam_arquivo sph_arquivo.cam_arquivo%TYPE,
    qtd_pagina sph_arquivo.qtd_pagina%TYPE
  );
  TYPE tArquivoRegistro IS TABLE OF recArquivoRegistro;

  TYPE recArquivoUnir IS RECORD (
    lArquivoOriginal NUM_ARRAY,
    rArquivoNovo sph_arquivo%ROWTYPE
  );
  TYPE tArquivoUnir IS TABLE OF recArquivoUnir;

  TYPE recConfigDigitalizacao IS RECORD (
    /**
    * URL de Upload da Imagem digitalizada, incluindo os parâmetros:
    * i = ID do Usuário
    * p = Password de Integração;
    **/
    url VARCHAR2(3999),
    /**
    * Porta no qual o Serviço NODE.JS está rodando
    **/
    port NUMBER,
    /**
    * 1 - Sim
    * 2 - Não
    **/
    AutoFeed NUMBER,
    /**
    * DPI das imagens que serão digitalizadas;
    **/
    dpi NUMBER,
    /**
    * 1 - Tons de Cinza;
    * 2 - Preto & Braco
    * 3 - Colorido
    **/
    Threshold NUMBER,
    /**
    * Mostrar interface do scanner: 1 = Sim; 2 = Não;
    **/
    ShowTwainUI NUMBER,
    /**
    * Mostra o progresso da digitalização: 1 = Sim; 2 = Não;
    **/
    ShowProgressIndicatorUI NUMBER,
    /**
    * Captura de frente e verso do documento: 1 = Sim; 2 = Não;
    **/
    UseDuplex NUMBER,
    /**
    * Alimentador de Documentos: 1 = Sim; 2 = Não;
    **/
    UseDocumentFeeder NUMBER,
    /**
    * Tipo de Scanner que está configurado para o Usuário;
    **/
    typeScanner VARCHAR2(100),
    /**
    * Lista de ID/Mensagens que serão tratados pelo Serviço de integração com o Scanner;
    **/
    msgScanner VARCHAR2(3999),
    /**
     * Url de acesso ao scanner
     **/
    urlScanner VARCHAR2(250)
  );

  TYPE recArquivoTemplateCampo IS RECORD (
      prk_arquivo_template_campo cfg_arquivo_template_campo.prk_arquivo_template_campo%TYPE
    , tip_arquivo_campo          cfg_arquivo_template_campo.tip_arquivo_campo%TYPE
    , frk_formulario             cfg_arquivo_template_campo.frk_formulario%TYPE
    , frk_grupo                  cfg_arquivo_template_campo.frk_grupo%TYPE
    , frk_campo                  cfg_arquivo_template_campo.frk_campo%TYPE
    , nom_campo                  idx_campo.nom_campo%TYPE
    , num_pagina                 cfg_arquivo_template_campo.num_pagina%TYPE
    , num_posicao_x              cfg_arquivo_template_campo.num_posicao_x%TYPE
    , num_posicao_y              cfg_arquivo_template_campo.num_posicao_y%TYPE
    , num_largura                cfg_arquivo_template_campo.num_largura%TYPE
    , num_altura                 cfg_arquivo_template_campo.num_altura%TYPE
    , frk_campo_opcao            idx_campo_opcao.prk_campo_opcao%TYPE
  );

  TYPE tArquivoTemplateCampo IS TABLE OF recArquivoTemplateCampo;


  TYPE recArquivoTemplateFluxo IS RECORD (
    frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE,
    frk_tipo_arquivo cfg_arquivo_template.frk_tipo_arquivo%TYPE,
    nom_tipo_arquivo cfg_tipo_arquivo.nom_tipo_arquivo%TYPE,
    cam_arquivo_template cfg_arquivo_template.cam_arquivo%TYPE,
    cam_arquivo_preenchido sph_arquivo.cam_arquivo%TYPE,
    cod_fonte tab_fonte.cod_fonte%TYPE,
    num_fonte cfg_arquivo_template.num_fonte%TYPE,
    qtd_pagina cfg_arquivo_template.qtd_pagina%TYPE,
    num_espessura_assinatura cfg_arquivo_template.num_espessura_assinatura%TYPE,
    cod_cor_assinatura cfg_arquivo_template.cod_cor_assinatura%TYPE

  );

  TYPE tArquivoTemplateFluxo IS TABLE OF recArquivoTemplateFluxo;

  TYPE recArquivoTemplateCampoFluxo IS RECORD (
    frk_arquivo_template_campo cfg_arquivo_template_campo.prk_arquivo_template_campo%TYPE,
    tip_arquivo_campo cfg_arquivo_template_campo.tip_arquivo_campo%TYPE,
    num_pagina      cfg_arquivo_template_campo.num_pagina%TYPE,
    num_posicao_x   cfg_arquivo_template_campo.num_posicao_x%TYPE,
    num_posicao_y   cfg_arquivo_template_campo.num_posicao_y%TYPE,
    num_largura     cfg_arquivo_template_campo.num_largura%TYPE,
    num_altura      cfg_arquivo_template_campo.num_altura%TYPE,
    val_valor       sph_arquivo.cam_arquivo%TYPE
  );

  TYPE tArquivoTemplateCampoFluxo IS TABLE OF recArquivoTemplateCampoFluxo;

  TYPE recDadosEmail IS RECORD (
    des_nome VARCHAR2(200),
    des_email VARCHAR2(200),
    des_assunto VARCHAR2(200),
    des_mensagem VARCHAR2(3999)
  );
  TYPE tDadosEmail IS TABLE OF recDadosEmail;

  TYPE tRegistroAnalise IS TABLE OF sph_registro_analise%ROWTYPE;

  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para retornar a url do arquivo dependendo da origem do arquivo
   **/
  FUNCTION fGetUrlArquivo(v_ind_local_arquivo NUMBER
                        , v_cam_arquivo VARCHAR2) RETURN VARCHAR2;
  /**
   * Busca o código da origem do arquivo com base no ind_local_arquivo
   **/
  FUNCTION fBuscarOrigemArquivo(v_ind_local_arquivo sph_arquivo.ind_local_arquivo%TYPE) RETURN VARCHAR2;
  /**
  * Carrega as configurações de Digitalização do Usuário;
  * @param v_cod_usuario: ID do usuário logado no sistema;
  * @param OUT v_rConfigDigitalizacao: RECORD com as configurações da Digitalização;
  * @return: pkg_dominio.recRetorno;
  **/
  FUNCTION fCarregarConfigDigitalizacao(v_cod_usuario tab_usuario.des_matricula%TYPE
                                      , v_rConfigDigitalizacao OUT recConfigDigitalizacao) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Grupos de Arquivos
   * @return: Lista com todos os Grupos de Arquivos;
   **/
  FUNCTION fListarGrupoArquivo(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE DEFAULT NULL) RETURN pkg_dominio.tSelectDefault PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Tipos de Documentos em conjunto com os associados ao cliente
   * @return: Lista com todos os Documentos;
   **/
  FUNCTION fListarTipoArquivoAnalise RETURN pkg_dominio.tSelectDefault PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Tipos de Analise no BrSafe
   * @return: Lista com todos os tipos de Analise BrSafe;
   **/
  FUNCTION fListarTipoAnaliseBrSafe RETURN pkg_dominio.tSelectDefault PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Relatório dos Arquivos Cadastrados para o Cliente
   * @return: Lista com todos os tipos Arquivos cadastrados para o Cliente;
   **/
  FUNCTION fListarTipoArquivoGestao(v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE) RETURN tTipoArquivoGestao PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Alertas cadastros para o Arquivo
   * @param v_frk_tipo_arquivo: Código do arquivo
   * @param v_frk_nivel_hierarquico: Código do Nível Hierarquico
   * @return: Lista com todos os Alertas cadastrados para o Arquivo;
   */
  FUNCTION fListarArquivoAlertas (v_frk_tipo_arquivo cfg_nivel_hierarquico_arquivo.frk_tipo_arquivo%TYPE
                                , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE) RETURN STR_ARRAY PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função que retorna os dados salvos de um tipo de arquivo
   * @param v_frk_tipo_arquivo: Código do arquivo
   * @param v_frk_nivel_hierarquico: Código do Nível Hierarquico
   * @rTipoArquivoGestaoGestao OUT: Dados do Arquivo para Edição
   * @return: pkg_dominio.recRetorno;
   */
  FUNCTION fDadosTipoArquivo(v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE
                           , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                           , rTipoArquivoGestao OUT recTipoArquivoGestao) RETURN pkg_dominio.recRetorno;
  -------------------------------------------------------------------------------------------------------
  /**
   * Função para retornar os dados de um tipo de arquivo especifico
   * @param v_frk_tipo_arquivo: ID do tipo de arquivo
   **/
  FUNCTION fDadosTipoArquivo(v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN cfg_tipo_arquivo%ROWTYPE;
  -------------------------------------------------------------------------------------------------------
  /**
   * Busca o ID do tipo de arquivo mais antigo de um cliente de acordo com o código informado
   * @param v_frk_cliente: ID do cliente
   * @param v_cod_tipo_arquivo: Código do tipo de arquivo
   **/
  FUNCTION fBuscarIdTipoArquivoByCod(v_frk_cliente cfg_tipo_arquivo.frk_cliente%TYPE
                                   , v_cod_tipo_arquivo cfg_tipo_arquivo.cod_tipo_arquivo%TYPE) RETURN cfg_tipo_arquivo.prk_tipo_arquivo%TYPE;
  -------------------------------------------------------------------------------------------------------
  /**
   * Função para gerenciar o Cadastro/Edição de um Tipo de Arquivo
   * @param cod_usuario: matricula do usuário logado
   * @param v_frk_nivel_hierarquico: Nivel Hierarquico do usuário
   * @param rTipoArquivoGestao: Record com os dados do arquivo
   * @param lAlertas: Lista de Alertas associados ao Arquivo
   * @return 1: acesso especial salvo com sucesso
   *        -1: Falha na gestão do acesso especial
   *        -2: usuário não informado
   *        -3: Grupo não informado
   *        -4: Nome do Arquivo não Informado
   **/
  FUNCTION fGeranciarTipoArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                               , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                               , v_rTipoArquivoGestao recTipoArquivoGestao
                               , lAlertas STR_ARRAY) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para ativar/desativar um tipo de arquivo na reclassificação ou digitalização
   * @param v_cod_usuario: Login do usuário
   * @param v_frk_nivel_hierarquico: Código do nível Hierarquico
   * @param v_frk_tipo_arquivo: Código do tipo de arquivo
   * @param v_cod_tipo_acao: tipo da ação ( digitalizar ou reclassificar ) que será ativada/desativada
   **/
  FUNCTION fAtivarDesativarArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                                 , v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE
                                 , v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE
                                 , v_cod_tipo_acao VARCHAR2) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função que lista os tipos de arquivos disponíveis para um determinado cliente
   * @param v_frk_cliente: código do cliente
   **/
  FUNCTION fListarTipoArquivo(v_frk_cliente cfg_tipo_arquivo.frk_cliente%TYPE) RETURN tTipoArquivo PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para digitalizar um arquivo
   * @param v_cod_usuario: Usuário do sistema
   * @param rArquivo: Record com as informações do arquivo
   **/
  FUNCTION fDigitalizarArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                             , rArquivo sph_arquivo%ROWTYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  --- FUNÇÕES DE RECLASSIFICAÇÃO
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Lista os tipos de arquivos disponível para reclassificação de todos os Workflows que o usuário possui acesso
   * @param v_frk_nivel_hierarquico: Nível Hierarquico do usuário
   **/
   FUNCTION fListarTipoArquivoReclUsuario(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tTipoArquivoDIgitalizacao PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Lista os tipos de arquivo disponíveis para a reclassificação
   * @param v_frk_registro_fluxo: Código do fluxo
   **/
  FUNCTION fListarTipoArquivoRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.tTipoArquivoDIgitalizacao PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para listar os tipos de arquivo disponíveis para o workflow (Digitalização ou Reclassificação)
   * @param v_frk_nivel_hierarquico: Código do nível hierarquico
   **/
  FUNCTION fListarTipoArquivoNH(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tTipoArquivoDigitalizacao PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Lista os tipos de arquivo disponíveis para a digitalizacao
   * @param v_frk_cliente: Código do cliente
   * @param v_cod_registro: Código do registro
   **/
  FUNCTION fListarTipoArquivoRegistroDig(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.tTipoArquivoDigitalizacao PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função que retorna a quantidades de documento de um registro
   * @param v_frk_registro_fluxo: Código do fluxo
   * @param v_out_qtd_arquivos: Váriavel de saída com a quantidade de arquivos digitalizados
   * @return: pkg_dominio.recRetorno
   ** /
  FUNCTION fTotalArquivoRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                   , v_out_qtd_arquivos OUT NUMBER) RETURN pkg_dominio.recRetorno;
  */
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para retornar os arquivos de um registro
   * @param v_frk_registro: prk do registro
   * @param v_frk_tipo_arquivo: Tipo de Arquivo
   * @param v_frk_arquivo: ID do arquivo
   **/
  FUNCTION fListarArquivoRegistro(v_frk_registro sph_registro_fluxo.frk_registro%TYPE
                                , v_frk_tipo_arquivo sph_registro_fluxo.cod_analise%TYPE DEFAULT NULL
                                , v_frk_arquivo sph_registro_fluxo.cod_subanalise%TYPE DEFAULT NULL) RETURN tListaArquivo PIPELINED;
  /**
   * Função para listar os arquivos a serem exibidos por uma fila de análise
   * @param v_frk_registro_fluxo: ID da Fila
   * @param v_rRegistroFila: Record da fila (usada em caso de chamada por outras funções que já buscaram a fila)
   **/
  FUNCTION fListarArquivoRegistroFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tListaArquivo PIPELINED;
  /**
   * Função que retorna lista de documentos digitalizados de um registro
   * @param v_frk_registro_fluxo: Código do fluxo
   * @return: tArquivo com a lista dos arquivos digitalizados
   **/
  FUNCTION fListarArquivoRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tListaArquivo PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para listar as alertas de um registro para um tipo de arquivo
   * @param v_frk_registro_fluxo: Código do fluxo
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return: Lista de Alertas
   **/
  FUNCTION fListarAlertaRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                           , v_frk_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN pkg_dominio.tSelectCheck PIPELINED;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Verifica se existem arquivo não reclassificados de um registro
   * @param v_frk_registro: ID do registro
   **/
  FUNCTION fExisteReclManualRegistro(v_frk_registro sph_registro.prk_registro%TYPE) RETURN BOOLEAN;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para atualizar a quantidade de páginas de um arquivo
   * @param v_frk_arquivo: Código do Arquivo
   * @param v_qtd_pagina: Quantidade de páginas do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fAtualizarQtdPaginaArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                                    , v_qtd_pagina sph_arquivo.qtd_pagina%TYPE) RETURN pkg_dominio.recRetorno;

  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para popular uma lista de arquivos
   * @param lArquivo: Lista de arquivos
   * @param rArquivo: Record com as informações do arquivo que será incluído na lista
   **/
  PROCEDURE pAdicionarArquivo(lArquivo IN OUT tArquivo
                            , rArquivo sph_arquivo%ROWTYPE);
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para reclassificar um arquivo
   * @param v_cod_usuario: Usuário que reclassificou o arquivo
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fReclassificarArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                               , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                               , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE
                               , v_ind_comit NUMBER DEFAULT pkg_constante.CONST_SIM
                               , v_ind_classificacao_automatica sph_arquivo.ind_classificacao_automatica%TYPE DEFAULT NULL) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para criar uma cópia de uma imagem no banco
   * @param v_cod_usuario: Usuário logado do sistema
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_tipo_arquivo: Novo tipo de arquivo
   **/
  FUNCTION fDuplicarArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                          , v_frk_arquivo_original sph_arquivo.prk_arquivo%TYPE
                          , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE
                          , v_cam_arquivo sph_arquivo.cam_arquivo%TYPE) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para excluír um arquivo do sistema
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
  FUNCTION fExcluirArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para unir vários arquivos em um só
   * @param v_cod_usuario: Usuário do sistema
   * @param lArquivoOriginal: Lista com os PRKs dos arquivos originais
   * @param rArquivoNovo: Record com as informações do novo arquivo gerado
   **/
  FUNCTION fUnirArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                      , lArquivoOriginal NUM_ARRAY
                      , rArquivoNovo sph_arquivo%ROWTYPE
                      , v_ind_commit BOOLEAN DEFAULT TRUE) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para popular uma lista de uniões em massa
   **/
  PROCEDURE pAdicionarArquivoUnir(lArquivoUnir IN OUT tArquivoUnir
                                , lArquivoOriginal NUM_ARRAY
                                , rArquivoNovo sph_arquivo%ROWTYPE);
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para realizar mais de
   **/
  FUNCTION fUnirAllArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , lArquivoUnir tArquivoUnir) RETURN pkg_dominio.recRetorno;

  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para unir vários arquivos em um só
   * @param v_cod_usuario: Usuário do sistema
   * @param lArquivoOriginal: Lista com os PRKs dos arquivos originais
   * @param rArquivoNovo: Record com as informações do novo arquivo gerado
   **/
  FUNCTION fSepararArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , v_frk_arquivo_original sph_arquivo.prk_arquivo%TYPE
                         , lArquivoNovo tArquivo
                         , v_ind_comit NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para criar uma cópia de uma imagem no banco
   * @param v_cod_usuario: Usuário logado do sistema
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_registro_fluxo: Código do fluxo atual
   * @param lAlerta: Códigos dos alertas a serem inseridos no módulo
   **/

  FUNCTION fAtualizarAlertaRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                      , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                                      , lAlerta NUM_ARRAY) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para finalizar a etapa de reclassificação de um registro
   * @param v_frk_registro_fluxo: Código da fila de análise
   **/
  FUNCTION fFinalizarReclassificacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.recRetorno;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para validar se todos os documentos obrigatórios foram enviados
   * @param v_frk_fluxo: Código do fluxo(etapa) da digitalização
   * @param v_lArquivo: Lista de arquivos enviados
   * @return: TRUE: Todos os arquivos obrigatórios enviados
              FALSE: Arquivos obrigatórios não enviados
   **/
  FUNCTION fValidarDigitalizaObrigatorio(v_frk_fluxo cfg_fluxo.prk_fluxo%TYPE
                                       , v_lArquivo PKG_DIGITALIZACAO_TMP.tArquivo) RETURN BOOLEAN;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para processar todos os arquivos digitalizados
   * @param v_frk_registro_fluxo: Código do Fluxo;
   * @param lArquivo: Lista com os arquivos enviados.
   * @return 1: Arquivo adicionado;
   *        -1: Falha na gestão ao Salvar o Arquivo;
   *        -2: Registro não informado;
   *        -5: Fluxo não Informado;
   *        -6: Nenhum arquivo enviado.
   **/
  FUNCTION fFinalizarDigitalizacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , lArquivo PKG_DIGITALIZACAO_TMP.tArquivo
                                 , v_lAlerta STR_ARRAY DEFAULT STR_ARRAY()) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Funcao para finalizar uma digitalizacao sem arquivos
   * @param v_frk_registro_fluxo: Codigo da fila de digitalizacao
   * @param v_des_alerta: ALERTA a ser inserido no sistema
   **/
  FUNCTION fFinalizarDigSemArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , v_des_alerta cfg_alerta.des_alerta%TYPE DEFAULT pkg_constante.CONST_DES_ALERTA_SEM_DIGIT)  RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  ---- GESTÃO DE TEMPLATES ----------
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para buscar os dados do Arquivo Template para edição
   * @param v_frk_arquivo_template: Código do arquivo template
   * @param v_rArquivoTemplate: Record com os dados do template retornado
   **/
  FUNCTION fDadosArquivoTemplate(v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE
                               , v_rArquivoTemplate IN OUT cfg_arquivo_template%ROWTYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para listar os campos configurados em um template
   * @param v_frk_arquivo_template: Código do template;
   **/
  FUNCTION fListarArquivoTemplateCampo(v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN tArquivoTemplateCampo PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para popular uma lista de campos de marcação de um template
   * @param v_lArquivoTemplateCampo: lista de campos
   * @param
   **/
  PROCEDURE pAdicionarArquivoTemplateCampo(v_lArquivoTemplateCampo IN OUT tArquivoTemplateCampo
                                         , v_rArquivoTemplateCampo recArquivoTemplateCampo);
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para gerenciar um template de arquivo
   * @param v_cod_usuario: ID do usuário
   * @param v_frk_nivel_hierarquico: ID do Nível hierarquico
   * @param v_rArquivoTemplate: Record com os dados do template
   * @param v_lArquivoTemplateCampo: Lista de campo de demarcação do template
   **/
  FUNCTION fGerenciarArquivoTemplate(v_cod_usuario tab_usuario.des_matricula%TYPE
                                   , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                                   , v_rArquivoTemplate cfg_arquivo_template%ROWTYPE
                                   , v_lArquivoTemplateCampo tArquivoTemplateCampo) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
  * Ativa/Desativa o Template;
  * @param O problema estava na que: Código do usuário;
  * @param v_frk_arquivo_template: Código do template;
  * @return: Status atual do registro;
  **/
  FUNCTION fAtivarDesativarArqTemplate(v_cod_usuario tab_usuario.des_matricula%TYPE
                                     , v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Busca os dados do template tratado no fluxo
   * @param v_frk_registro_fluxo: Código do fluxo do registro
   * @param v_rArquivoTemplateFluxo: Record com os dados do tamplate
   **/
  FUNCTION fBuscarArquivoTemplateFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                     , v_rArquivoTemplateFluxo IN OUT recArquivoTemplateFluxo) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função que lista os campos preenchidos de um template, incluindo as assinaturas
   * @param v_frk_registro: Código do registro
   * @param v_frk_arquivo_template: Código do template
   **/
  FUNCTION fListarArqTemplateRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN tArquivoTemplateCampoFluxo PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para listar os campos do template no fluxo
   **/
  FUNCTION fBuscarArqTemplateCampoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                      , v_num_pagina cfg_arquivo_template_campo.num_pagina%TYPE DEFAULT NULL) RETURN tArquivoTemplateCampoFluxo PIPELINED;

  ------------------------------------------------------------------------------------------------------------------------------
  FUNCTION fListarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tArquivoTemplateCampoFluxo PIPELINED;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Função para salvar a assinatura de um arquivo
   * @param v_frk_registro_fluxo: fila da assinatura
   * @param v_rRegistroAssinatura: Record com os dados da assinatura
   **/
  FUNCTION fSalvarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_rRegistroAssinatura sph_registro_assinatura%ROWTYPE) RETURN pkg_dominio.recRetorno;

  ------------------------------------------------------------------------------------------------------------------------------
  /**
   *
   **/
  FUNCTION fFinalizarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                  ,  v_lArquivo PKG_DIGITALIZACAO_TMP.tArquivo DEFAULT PKG_DIGITALIZACAO_TMP.tArquivo()
                                  ,  v_tip_assinatura sph_registro_analise.tip_assinatura%TYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   * Verifica se ainda existem assinaturas ou etapas do mesmo fluxo das filas
   **/
  FUNCTION fVerificarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.recRetorno;
  ------------------------------------------------------------------------------------------------------------------------------
  /**
   *
   **/
  FUNCTION fListarArquivoTemplateFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tArquivoTemplateFluxo PIPELINED;
  /**
   * Função para retornar a lista de mensagens/destinatários a serem enviados no termino da etapa de assinatura
   * @param v_frk_registro_fluxo: Código da fila atual
   **/
  FUNCTION fListarAssinaturaEmailFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tDadosEmail PIPELINED;


  FUNCTION fDadosCarimboDoTempo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE, v_rDadosCarimboTempo IN OUT sph_arquivo%ROWTYPE) RETURN pkg_dominio.recRetorno;

  /**
   * Função para expurgar um arquivo
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
 -- FUNCTION fExpurgarArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN sph_arquivo.prk_arquivo%TYPE;


END PKG_DIGITALIZACAO_TMP;
/
CREATE OR REPLACE PACKAGE BODY "PKG_DIGITALIZACAO_TMP" IS
  /**
   * Função para retornar a url do arquivo dependendo da origem do arquivo
   **/
  FUNCTION fGetUrlArquivo(v_ind_local_arquivo NUMBER
                        , v_cam_arquivo VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE v_ind_local_arquivo
              WHEN 1 THEN 'https://www.brflow.com.br/ws/file/imagem/?image=' || v_cam_arquivo
              ELSE 'https://storage.brflow.com.br/ws/file/imagem/?image=' || v_cam_arquivo
            END;
  END fGetUrlArquivo;

  /**
   * Busca o código da origem do arquivo com base no ind_local_arquivo
   **/
  FUNCTION fBuscarOrigemArquivo(v_ind_local_arquivo sph_arquivo.ind_local_arquivo%TYPE) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE v_ind_local_arquivo
                 WHEN CONST_IND_LOCAL_ARQUIVO_BRSCAN THEN pkg_constante.CONST_IMAGEM_ORIGEM_INTRANET
                 ELSE pkg_constante.CONST_IMAGEM_ORIGEM_LOCAL
            END;
  END fBuscarOrigemArquivo;
  FUNCTION fGetGrupoId(v_frk_cliente cfg_grupo_arquivo.frk_cliente%TYPE
                     , v_nom_grupo cfg_grupo_arquivo.nom_grupo_arquivo%TYPE) RETURN idx_grupo.prk_grupo%TYPE IS
    nGrupo cfg_grupo_arquivo.prk_grupo_arquivo%TYPE;
  BEGIN
    SELECT MAX(prk_grupo_arquivo)
      INTO nGrupo
      FROM cfg_grupo_arquivo
     WHERE pkg_base.fLimparString(nom_grupo_arquivo) = pkg_base.fLimparString(v_nom_grupo)
       AND (frk_cliente = v_frk_cliente OR prk_grupo_arquivo = pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT);
    IF nGrupo IS NULL THEN
      INSERT INTO cfg_grupo_arquivo (nom_grupo_arquivo, frk_cliente)
                     VALUES (v_nom_grupo, v_frk_cliente)
        RETURNING prk_grupo_arquivo INTO nGrupo;
    END IF;
    RETURN nGrupo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fGetGrupoId;

  /**
  * Carrega as configurações de Digitalização do Usuário;
  * @param v_cod_usuario: ID do usuário logado no sistema;
  * @param OUT v_rConfigDigitalizacao: RECORD com as configurações da Digitalização;
  * @return: pkg_dominio.recRetorno;
  **/
  FUNCTION fCarregarConfigDigitalizacao(v_cod_usuario tab_usuario.des_matricula%TYPE
                                      , v_rConfigDigitalizacao OUT recConfigDigitalizacao) RETURN pkg_dominio.recRetorno IS
  BEGIN
    IF v_cod_usuario IS NULL THEN
      NULL;
    END IF;
    v_rConfigDigitalizacao.AutoFeed := 1;
    v_rConfigDigitalizacao.Threshold := 1;

    v_rConfigDigitalizacao.ShowTwainUI := 2;
    v_rConfigDigitalizacao.ShowProgressIndicatorUI := 2;
    v_rConfigDigitalizacao.UseDuplex := 2;
    v_rConfigDigitalizacao.UseDocumentFeeder := 1;

    v_rConfigDigitalizacao.dpi := 200;
    v_rConfigDigitalizacao.port := 3000;
    v_rConfigDigitalizacao.typeScanner := 'usb';
    v_rConfigDigitalizacao.msgScanner := '{"-1":"Erro Inesperado. Não foi possível concluir a Digitalização","-2":"Scanner selecionado não está disponível para realizar Digitalização.","-3":"Scanner sem papel.", "-4":"Scanner desconectado."}';
    v_rConfigDigitalizacao.url := 'http://homologacao.brscan.com.br:3000';
    v_rConfigDigitalizacao.urlScanner := 'wss://wss.brscan.com.br:30001';
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  END fCarregarConfigDigitalizacao;

  -------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Grupos de Arquivos
   * @return: Lista com todos os Grupos de Arquivos;
   **/
  FUNCTION fListarGrupoArquivo(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE DEFAULT NULL) RETURN pkg_dominio.tSelectDefault PIPELINED IS
    rNivelHierarquico tab_nivel_hierarquico%ROWTYPE := pkg_dominio.fDadosNivelHierarquico(v_frk_nivel_hierarquico);
  BEGIN
    FOR tab_temp IN (
      SELECT TO_CHAR(prk_grupo_arquivo)
           , nom_grupo_arquivo
        FROM cfg_grupo_arquivo
       WHERE frk_cliente = rNivelHierarquico.frk_cliente
          OR prk_grupo_arquivo = pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarGrupoArquivo;

  -------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Tipos de Documentos em conjunto com os associados ao cliente
   * @return: Lista com todos os Documentos;
   **/
  FUNCTION fListarTipoArquivoAnalise RETURN pkg_dominio.tSelectDefault PIPELINED IS
  BEGIN
    FOR tab_temp IN (
      SELECT TO_CHAR(prk_tipo_arquivo_analise)
           , nom_tipo_arquivo_analise
        FROM cfg_tipo_arquivo_analise
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarTipoArquivoAnalise;

  -------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Tipos de Analise no BrSafe
   * @return: Lista com todos os tipos de Analise BrSafe;
   **/
  FUNCTION fListarTipoAnaliseBrSafe RETURN pkg_dominio.tSelectDefault PIPELINED IS
  BEGIN
    FOR tab_temp IN (
     SELECT TO_CHAR(prk_documento)
           , des_documento
       FROM pre_regra_imagem pri
      INNER JOIN pre_regra pr
         ON pr.prk_regra = pri.frk_regra
      INNER JOIN pre_documento pd
         ON pd.frk_regra_imagem = pri.prk_regra_imagem
      WHERE sts_regra = 1
        AND pd.nom_sistema IN('brsafe','oab')
      ORDER BY des_documento
      /*
      SELECT TO_CHAR(prk_documento)
           , des_documento
        FROM pre_documento
       INNER JOIN pre_regra
               ON prk_documento = frk_documento
       WHERE sts_regra = pkg_constante.CONST_ATIVO
       */
    )
    LOOP
        PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarTipoAnaliseBrSafe;

  -------------------------------------------------------------------------------------------------------
  /**
   * Relatório dos Arquivos Cadastrados para o Cliente
   * @return: Lista com todos os tipos Arquivos cadastrados para o Cliente;
   **/
  FUNCTION fListarTipoArquivoGestao(v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE) RETURN tTipoArquivoGestao PIPELINED IS
    rNivelHierarquico tab_nivel_hierarquico%ROWTYPE := pkg_dominio.fDadosNivelHierarquico(v_frk_nivel_hierarquico);
  BEGIN
    FOR tab_temp IN (
        SELECT prk_tipo_arquivo
             , cta.frk_cliente
             , nom_tipo_arquivo
             , NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
             , nom_grupo_arquivo
             , frk_tipo_arquivo_analise
             , NVL(nom_tipo_arquivo_analise, '-')
             , prk_documento prk_documento_brsafe
             , NVL(des_documento, '-') des_documento_brsafe
             , NVL(ind_digitalizar, 2)
             , CASE ind_digitalizar
                WHEN 1 THEN 'SIM'
                ELSE 'NÃO'
               END des_digitalizar
             , NVL(ind_obrigatorio, 2)
             , NVL(ind_reclassificar, 2)
             , CASE ind_reclassificar
                WHEN 1 THEN 'SIM'
                ELSE 'NÃO'
               END des_reclassificar
             , NVL2(cta.frk_cliente, pkg_constante.CONST_SIM, pkg_constante.CONST_NAO)
             , cnh.ind_fotografia
             , cnh.cod_cor
             , cta.ind_face
             , cta.cod_tipo_arquivo
          FROM cfg_tipo_arquivo cta
          LEFT JOIN cfg_nivel_hierarquico_arquivo cnh
                 ON (frk_tipo_arquivo = prk_tipo_arquivo AND frk_nivel_hierarquico = v_frk_nivel_hierarquico)
          LEFT JOIN cfg_grupo_arquivo cga
                 ON prk_grupo_arquivo = NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
          LEFT JOIN cfg_tipo_arquivo_analise
                 ON prk_tipo_arquivo_analise = frk_tipo_arquivo_analise
          LEFT JOIN pre_documento
                 ON prk_documento = frk_documento_brsafe
         WHERE (/*cta.frk_cliente IS NULL OR */cta.frk_cliente = rNivelHierarquico.frk_cliente)
           AND prk_tipo_arquivo > 0
         ORDER BY cga.ind_ordem, cga.nom_grupo_arquivo,  nom_tipo_arquivo
    )
    LOOP
        PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarTipoArquivoGestao;

  -------------------------------------------------------------------------------------------------------
  /**
   * Consulta todos os Alertas cadastros para o Arquivo
   * @param v_frk_tipo_arquivo: Código do arquivo
   * @param v_frk_nivel_hierarquico: Código do Nível Hierarquico
   * @return: Lista com todos os Alertas cadastrados para o Arquivo;
   */
  FUNCTION fListarArquivoAlertas (v_frk_tipo_arquivo cfg_nivel_hierarquico_arquivo.frk_tipo_arquivo%TYPE
                                , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE) RETURN STR_ARRAY PIPELINED IS
  BEGIN
    FOR tab_temp IN (
       SELECT des_alerta
         FROM cfg_tipo_arquivo_alerta
        INNER JOIN cfg_alerta
                ON (prk_alerta = frk_alerta)
        WHERE frk_tipo_arquivo = v_frk_tipo_arquivo
          AND frk_nivel_hierarquico = v_frk_nivel_hierarquico
    )
    LOOP
        PIPE ROW(tab_temp.des_alerta);
    END LOOP;
    RETURN;
  END fListarArquivoAlertas;

  -------------------------------------------------------------------------------------------------------
  /**
   * Função que retorna os dados salvos de um tipo de arquivo
   * @param v_frk_tipo_arquivo: Código do arquivo
   * @param v_frk_nivel_hierarquico: Código do Nível Hierarquico
   * @rTipoArquivoGestaoGestao OUT: Dados do Arquivo para Edição
   * @return: pkg_dominio.recRetorno;
   */
  FUNCTION fDadosTipoArquivo(v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE
                           , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                           , rTipoArquivoGestao OUT recTipoArquivoGestao) RETURN pkg_dominio.recRetorno IS
  BEGIN
    SELECT prk_tipo_arquivo
         , cta.frk_cliente
         , nom_tipo_arquivo
         , NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
         , nom_grupo_arquivo
         , frk_tipo_arquivo_analise
         , NULL nom_tipo_documento
         , frk_documento_brsafe
         , NULL nom_documento_brsafe
         , NVL(ind_digitalizar, pkg_constante.CONST_NAO)
         , NULL des_digitalizar
         , NVL(ind_obrigatorio, pkg_constante.CONST_NAO)
         , NVL(ind_reclassificar, pkg_constante.CONST_NAO)
         , NULL des_reclassificar
         , CASE
            WHEN cta.frk_cliente IS NOT NULL THEN pkg_constante.CONST_SIM
            ELSE pkg_constante.CONST_NAO
           END ind_editar
         , cnh.ind_fotografia
         , cnh.cod_cor
         , cta.ind_face
         , cta.cod_tipo_arquivo
      INTO rTipoArquivoGestao
      FROM cfg_tipo_arquivo cta
      LEFT JOIN cfg_nivel_hierarquico_arquivo cnh
             ON (frk_tipo_arquivo = prk_tipo_arquivo AND frk_nivel_hierarquico = v_frk_nivel_hierarquico)
      LEFT JOIN cfg_grupo_arquivo
             ON prk_grupo_arquivo = NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
     WHERE prk_tipo_arquivo = v_frk_tipo_arquivo;
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fDadosTipoArquivo;

  /**
   * Função para retornar os dados de um tipo de arquivo especifico
   * @param v_frk_tipo_arquivo: ID do tipo de arquivo
   **/
  FUNCTION fDadosTipoArquivo(v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN cfg_tipo_arquivo%ROWTYPE IS
    rTipoArquivo cfg_tipo_arquivo%ROWTYPE;
  BEGIN
    SELECT *
      INTO rTipoArquivo
      FROM cfg_tipo_arquivo
     WHERE prk_tipo_arquivo = v_frk_tipo_arquivo;
   RETURN rTipoArquivo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosTipoArquivo;
  /**
   * Busca o ID do tipo de arquivo mais antigo de um cliente de acordo com o código informado
   * @param v_frk_cliente: ID do cliente
   * @param v_cod_tipo_arquivo: Código do tipo de arquivo
   **/
  FUNCTION fBuscarIdTipoArquivoByCod(v_frk_cliente cfg_tipo_arquivo.frk_cliente%TYPE
                                   , v_cod_tipo_arquivo cfg_tipo_arquivo.cod_tipo_arquivo%TYPE) RETURN cfg_tipo_arquivo.prk_tipo_arquivo%TYPE IS
    nTipoArquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE;
  BEGIN
    SELECT MIN(prk_tipo_arquivo)
      INTO nTipoArquivo
      FROM cfg_tipo_arquivo
     WHERE frk_cliente = v_frk_cliente
       AND LOWER(cod_tipo_arquivo) = LOWER(v_cod_tipo_arquivo)
       AND sts_tipo_arquivo = pkg_constante.CONST_ATIVO;
    RETURN nTipoArquivo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fBuscarIdTipoArquivoByCod;

  -------------------------------------------------------------------------------------------------------
  FUNCTION fExisteTipoArquivo(v_rTipoArquivoGestao recTipoArquivoGestao) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO nTotal
      FROM cfg_tipo_arquivo
     WHERE TRIM(UPPER(nom_tipo_arquivo)) = TRIM(UPPER(v_rTipoArquivoGestao.nom_tipo_arquivo))
       AND (/*frk_cliente IS NULL OR*/ frk_cliente = v_rTipoArquivoGestao.frk_cliente)
       AND (prk_tipo_arquivo <> v_rTipoArquivoGestao.prk_tipo_arquivo OR v_rTipoArquivoGestao.prk_tipo_arquivo IS NULL);
    IF nTotal > 0 THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;

  END fExisteTipoArquivo;
  /**
   * Função para gerenciar o Cadastro/Edição de um Tipo de Arquivo
   * @param cod_usuario: matricula do usuário logado
   * @param v_frk_nivel_hierarquico: Nivel Hierarquico do usuário
   * @param rTipoArquivoGestao: Record com os dados do arquivo
   * @param lAlertas: Lista de Alertas associados ao Arquivo
   * @return 1: acesso especial salvo com sucesso
   *        -1: Falha na gestão do acesso especial
   *        -2: usuário não informado
   *        -3: Grupo não informado
   *        -4: Nome do Arquivo não Informado
   **/
  FUNCTION fGeranciarTipoArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                               , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                               , v_rTipoArquivoGestao recTipoArquivoGestao
                               , lAlertas STR_ARRAY) RETURN pkg_dominio.recRetorno IS
    nTipoArquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE := v_rTipoArquivoGestao.prk_tipo_arquivo;
    rNivelHierarquico tab_nivel_hierarquico%ROWTYPE := pkg_dominio.fDadosNivelHierarquico(v_frk_nivel_hierarquico);
    nAlerta cfg_alerta.prk_alerta%TYPE;
    nGrupoArquivo cfg_grupo_arquivo.prk_grupo_arquivo%TYPE;
  BEGIN
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -2);
    ELSIF v_frk_nivel_hierarquico IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -9);
    ELSIF fExisteTipoArquivo(v_rTipoArquivoGestao) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -5);
    ELSIF v_rTipoArquivoGestao.nom_grupo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -3);
    ELSIF v_rTipoArquivoGestao.nom_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -4);
    /*
    ELSIF nTipoArquivo IS NOT NULL THEN
      rRetorno := fDadosTipoArquivo (nTipoArquivo, v_frk_nivel_hierarquico, rDadosTipoArquivoGestao);
      IF rDadosTipoArquivoGestao.frk_cliente IS NOT NULL THEN
      END IF;
    */
    ELSIF rNivelHierarquico.frk_Cliente IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -6);
    END IF;

    IF nTipoArquivo IS NULL THEN
      INSERT INTO cfg_tipo_arquivo(nom_tipo_arquivo, frk_documento_brsafe, frk_cliente, frk_tipo_arquivo_analise, ind_face, cod_tipo_arquivo)
                           VALUES (v_rTipoArquivoGestao.nom_tipo_arquivo, v_rTipoArquivoGestao.frk_documento_brsafe, rNivelHierarquico.frk_cliente, v_rTipoArquivoGestao.frk_tipo_arquivo_analise, NVL(v_rTipoArquivoGestao.ind_face, pkg_constante.CONST_NAO), v_rTipoArquivoGestao.cod_tipo_arquivo )
      RETURNING prk_tipo_arquivo INTO nTipoArquivo;
    ELSE
       UPDATE cfg_tipo_arquivo a
          SET nom_tipo_arquivo           = v_rTipoArquivoGestao.nom_tipo_arquivo
            , frk_documento_brsafe       = v_rTipoArquivoGestao.frk_documento_brsafe
            , frk_tipo_arquivo_analise   = v_rTipoArquivoGestao.frk_tipo_arquivo_analise
            , ind_face                   = NVL(v_rTipoArquivoGestao.ind_face, pkg_constante.CONST_NAO)
            , cod_tipo_arquivo           = v_rTipoArquivoGestao.cod_tipo_arquivo
        WHERE prk_tipo_arquivo = nTipoArquivo;
    END IF;

    nGrupoArquivo := fGetGrupoId(rNivelHierarquico.frk_Cliente, v_rTipoArquivoGestao.nom_grupo_arquivo);
    MERGE INTO cfg_nivel_hierarquico_arquivo dest
         USING (SELECT v_frk_nivel_hierarquico AS prk_nivel_hierarquico
                     , nTipoArquivo AS frk_tipo_arquivo
                  FROM dual)  base
            ON (dest.frk_nivel_hierarquico = base.prk_nivel_hierarquico
           AND  dest.frk_tipo_arquivo      = base.frk_tipo_arquivo)
     WHEN MATCHED THEN
       UPDATE SET des_matricula_configuracao = v_cod_usuario
                , ind_digitalizar            = v_rTipoArquivoGestao.ind_digitalizar
                , ind_reclassificar          = v_rTipoArquivoGestao.ind_reclassificar
                , ind_obrigatorio            = v_rTipoArquivoGestao.ind_obrigatorio
                , ind_fotografia             = v_rTipoArquivoGestao.ind_fotografia
                , cod_cor                    = v_rTipoArquivoGestao.cod_cor
                , frk_grupo_arquivo          = nGrupoArquivo
                , dat_configuracao           = SYSDATE
     WHEN NOT MATCHED THEN
       INSERT (frk_nivel_hierarquico, frk_tipo_arquivo, des_matricula_configuracao, ind_digitalizar, ind_reclassificar, frk_grupo_arquivo, ind_fotografia, cod_cor)
       VALUES (v_frk_nivel_hierarquico, nTipoArquivo, v_cod_usuario, v_rTipoArquivoGestao.ind_digitalizar, v_rTipoArquivoGestao.ind_reclassificar, nGrupoArquivo, v_rTipoArquivoGestao.ind_fotografia, v_rTipoArquivoGestao.cod_cor);

    DELETE cfg_tipo_arquivo_alerta
     WHERE frk_tipo_arquivo = v_rTipoArquivoGestao.prk_tipo_arquivo
       AND frk_nivel_hierarquico = v_frk_nivel_hierarquico;

    IF lAlertas.COUNT > 0 THEN
      FOR nLoop IN 1..lAlertas.COUNT
      LOOP
        nAlerta := pkg_dominio.fGetChaveAlerta(rNivelHierarquico.Frk_Cliente, lAlertas(nLoop));
        INSERT INTO cfg_tipo_arquivo_alerta (frk_nivel_hierarquico, frk_tipo_arquivo, frk_alerta)
                                     VALUES (v_frk_nivel_hierarquico, nTipoArquivo, nAlerta);
      END LOOP;
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, pkg_constante.CONST_SUCESSO, nTipoArquivo);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, pkg_constante.CONST_FALHA, v_sql_code => SQLCODE, v_sql_error => SQLERRM  );
  END fGeranciarTipoArquivo;

  /**
   * Função para ativar/desativar um tipo de arquivo na reclassificação ou digitalização
   * @param v_cod_usuario: Login do usuário
   * @param v_frk_nivel_hierarquico: Código do nível Hierarquico
   * @param v_frk_tipo_arquivo: Código do tipo de arquivo
   * @param v_cod_tipo_acao: tipo da ação ( digitalizar ou reclassificar ) que será ativada/desativada
   **/
  FUNCTION fAtivarDesativarArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                                 , v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE
                                 , v_frk_tipo_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE
                                 , v_cod_tipo_acao VARCHAR2) RETURN pkg_dominio.recRetorno IS
    nStatus NUMBER;
  BEGIN
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -2);
    ELSIF v_frk_nivel_hierarquico IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -9);
    ELSIF v_frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -7);
    ELSIF v_cod_tipo_acao IS NULL OR v_cod_tipo_acao NOT IN('digitalizar', 'reclassificar', 'obrigatorio') THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, -8);
    END IF;

    MERGE INTO cfg_nivel_hierarquico_arquivo dest
         USING (SELECT v_frk_nivel_hierarquico AS prk_nivel_hierarquico
                     , v_frk_tipo_arquivo AS frk_tipo_arquivo
                  FROM dual)  base
            ON (dest.frk_nivel_hierarquico = base.prk_nivel_hierarquico
           AND  dest.frk_tipo_arquivo      = base.frk_tipo_arquivo)
     WHEN MATCHED THEN
       UPDATE SET des_matricula_configuracao = v_cod_usuario
                , ind_digitalizar            = CASE
                                                 WHEN v_cod_tipo_acao = 'digitalizar' AND ind_digitalizar = pkg_constante.CONST_SIM THEN pkg_constante.CONST_NAO
                                                 WHEN v_cod_tipo_acao = 'digitalizar' AND ind_digitalizar = pkg_constante.CONST_NAO THEN pkg_constante.CONST_SIM
                                                 ELSE NVL(ind_digitalizar, pkg_constante.CONST_NAO)
                                               END
                , ind_reclassificar          = CASE
                                                 WHEN v_cod_tipo_acao = 'reclassificar' AND ind_reclassificar = pkg_constante.CONST_SIM THEN pkg_constante.CONST_NAO
                                                 WHEN v_cod_tipo_acao = 'reclassificar' AND ind_reclassificar = pkg_constante.CONST_NAO THEN pkg_constante.CONST_SIM
                                                 ELSE  NVL(ind_reclassificar, pkg_constante.CONST_NAO)
                                               END
                , ind_obrigatorio            = CASE
                                                 WHEN v_cod_tipo_acao = 'obrigatorio' AND ind_obrigatorio = pkg_constante.CONST_SIM THEN pkg_constante.CONST_NAO
                                                 WHEN v_cod_tipo_acao = 'obrigatorio' AND ind_obrigatorio = pkg_constante.CONST_NAO THEN pkg_constante.CONST_SIM
                                                 ELSE  NVL(ind_obrigatorio, pkg_constante.CONST_NAO)
                                               END
                , dat_configuracao           = SYSDATE
     WHEN NOT MATCHED THEN
       INSERT (frk_nivel_hierarquico, frk_tipo_arquivo, des_matricula_configuracao, ind_digitalizar, ind_reclassificar, ind_obrigatorio)
       VALUES (v_frk_nivel_hierarquico
             , base.frk_tipo_arquivo
             , v_cod_usuario
             , CASE
                 WHEN v_cod_tipo_acao = 'digitalizar' THEN pkg_constante.CONST_SIM
                 ELSE pkg_constante.CONST_NAO
               END
             , CASE
                 WHEN v_cod_tipo_acao = 'reclassificar' THEN pkg_constante.CONST_SIM
                 ELSE pkg_constante.CONST_NAO
               END
             , CASE
                 WHEN v_cod_tipo_acao = 'obrigatorio' THEN pkg_constante.CONST_SIM
                 ELSE pkg_constante.CONST_NAO
               END);

    SELECT MAX(DECODE(v_cod_tipo_acao
                , 'digitalizar', ind_digitalizar
                , 'reclassificar', ind_reclassificar
                , 'obrigatorio', ind_obrigatorio
                ))
      INTO nStatus
      FROM cfg_nivel_hierarquico_arquivo
     WHERE frk_nivel_hierarquico = v_frk_nivel_hierarquico
       AND frk_tipo_arquivo = v_frk_tipo_arquivo;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, pkg_constante.CONST_SUCESSO, nStatus);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TIP_ARQUIVO, pkg_constante.CONST_FALHA);
  END fAtivarDesativarArquivo;
  ---------------------------------------------------------------------------------------------------------------------------------------------------------


  FUNCTION fDadosArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN sph_arquivo%ROWTYPE IS
    rArquivo sph_arquivo%ROWTYPE;
  BEGIN
    SELECT *
      INTO rArquivo
      FROM sph_arquivo
     WHERE prk_arquivo = v_frk_arquivo;
    RETURN rArquivo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosArquivo;


  FUNCTION fDadosCarimboDoTempo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                              , v_rDadosCarimboTempo IN OUT sph_arquivo%ROWTYPE) RETURN pkg_dominio.recRetorno IS
  BEGIN
    v_rDadosCarimboTempo := fDadosArquivo(v_frk_arquivo);
  IF v_rDadosCarimboTempo.prk_arquivo IS NOT NULL THEN
    RETURN pkg_dominio.fBuscarMensagemRetorno(1, pkg_constante.CONST_SUCESSO);
  ELSE
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM, v_sql_code => SQLCODE);
  END IF;
   EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM, v_sql_code => SQLCODE);
  END fDadosCarimboDoTempo;


  /**
   * Função que lista os tipos de arquivos disponíveis para um determinado cliente
   * @param v_frk_cliente: código do cliente
   **/
  FUNCTION fListarTipoArquivo(v_frk_cliente cfg_tipo_arquivo.frk_cliente%TYPE) RETURN tTipoArquivo PIPELINED IS
  BEGIN
    FOR tab_temp IN (
      SELECT *
        FROM cfg_tipo_arquivo
       WHERE (/*frk_cliente IS NULL OR*/ frk_cliente = v_frk_cliente)
         AND sts_tipo_arquivo = pkg_constante.CONST_SIM
      ORDER BY nom_tipo_arquivo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarTipoArquivo;

  /**
   * Função para digitalizar um arquivo
   * @param v_cod_usuario: Usuário do sistema
   * @param rArquivo: Record com as informações do arquivo
   **/
  FUNCTION fDigitalizarArquivo(v_cod_usuario tab_usuario.des_matricula%TYPE
                             , rArquivo sph_arquivo%ROWTYPE) RETURN pkg_dominio.recRetorno IS
    nArquivo sph_arquivo.prk_arquivo%TYPE;
    nIndLocalArquivo sph_arquivo.ind_local_arquivo%TYPE := NVL(rArquivo.ind_local_arquivo, CONST_IND_LOCAL_ARQUIVO_LOCAL);
  BEGIN
    IF rArquivo.frk_registro IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -2);
    ELSIF rArquivo.frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -3);
    ELSIF rArquivo.cam_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -4);
    ELSIF nIndLocalArquivo NOT IN(CONST_IND_LOCAL_ARQUIVO_LOCAL, CONST_IND_LOCAL_ARQUIVO_BRSCAN) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -7);
    END IF;
    INSERT /*+ append */ INTO sph_arquivo (frk_registro, frk_tipo_arquivo, vlr_largura, vlr_altura, qtd_byte, cam_arquivo, qtd_pagina, frk_arquivo_referencia, des_matricula_arquivo, cam_carimbo_tempo, ind_local_arquivo, cod_arquivo, frk_registro_fluxo)
                                  VALUES (rArquivo.frk_registro, rArquivo.frk_tipo_arquivo, rArquivo.vlr_largura, rArquivo.vlr_altura, rArquivo.qtd_byte, TRIM(rArquivo.cam_arquivo), rArquivo.qtd_pagina, rArquivo.frk_arquivo_referencia, v_cod_usuario, rArquivo.cam_carimbo_tempo, nIndLocalArquivo, rArquivo.Cod_Arquivo, rArquivo.frk_registro_fluxo)
    RETURNING prk_arquivo INTO nArquivo;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO, nArquivo);
   END fDigitalizarArquivo;

  /**
   * Função para retornar os arquivos de um registro
   * @param v_frk_registro: prk do registro
   * @param v_frk_tipo_arquivo: Tipo de Arquivo
   * @param v_frk_arquivo: ID do arquivo
   **/
  FUNCTION fListarArquivoRegistro(v_frk_registro sph_registro_fluxo.frk_registro%TYPE
                                , v_frk_tipo_arquivo sph_registro_fluxo.cod_analise%TYPE DEFAULT NULL
                                , v_frk_arquivo sph_registro_fluxo.cod_subanalise%TYPE DEFAULT NULL) RETURN tListaArquivo PIPELINED IS
  BEGIN
      FOR tab_temp IN(
        SELECT prk_arquivo
             , frk_tipo_arquivo
             , cam_arquivo
             , num_pagina
             , qtd_pagina
             , 1 ind_local
             , fBuscarOrigemArquivo(arq.ind_local_arquivo) cod_origem
             , CASE WHEN cam_carimbo_tempo IS NOT NULL THEN 1
                    ELSE 2
               END ind_carimbo_tempo
          FROM viw_arquivo arq
         WHERE frk_registro = v_frk_registro
           AND (v_frk_tipo_arquivo IS NULL OR frk_tipo_arquivo = v_frk_tipo_arquivo )
           AND (v_frk_arquivo IS NULL OR prk_arquivo = v_frk_arquivo)
         ORDER BY prk_arquivo
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
  END fListarArquivoRegistro;
  /**
   * Função para listar os arquivos a serem exibidos por uma fila de análise
   * @param v_frk_registro_fluxo: ID da Fila
   **/
  FUNCTION fListarArquivoRegistroFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tListaArquivo PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo;
    rFluxo cfg_fluxo%ROWTYPE;
    rAnaliseVisual cfg_analise_visual%ROWTYPE;
  BEGIN
    rRegistroFila := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rFluxo := pkg_registro.fDadosFluxo(rRegistroFila.frk_fluxo);
    IF rFluxo.frk_modulo IN(pkg_constante.CONST_MODL_BRSAFE_IDX
                          , pkg_constante.CONST_MODL_BRSAFE_PERG
                          , pkg_constante.CONST_MODL_BRSAFE_DOC_FRAUDE
                          , pkg_constante.CONST_MODL_BRSAFE_DOC_VERDADE
                          , pkg_constante.CONST_MODL_BRSAFE_RESULTADO
                          , pkg_constante.CONST_MODL_CONSULTA_OAB)
      AND rRegistroFila.cod_analise IS NULL THEN
      NULL;
    ELSIF rFluxo.frk_modulo IN(pkg_constante.CONST_MODL_RECLASSIFICACAO) THEN
      RETURN;
    ELSIF rFluxo.frk_modulo = pkg_constante.CONST_MODL_ANALISE_VISUAL THEN
      IF pkg_analise_visual.fDadosAnaliseVisual(rRegistroFila.cod_analise, rAnaliseVisual).prk_retorno IS NULL THEN
        NULL;
      END IF;
      FOR tab_temp IN(
        SELECT prk_arquivo
             , frk_tipo_arquivo
             , cam_arquivo
             , num_pagina
             , qtd_pagina
             , CASE
                 WHEN rAnaliseVisual.frk_tipo_arquivo_primario = frk_tipo_arquivo THEN 1
                 WHEN rAnaliseVisual.frk_tipo_arquivo_secundario = frk_tipo_arquivo THEN 2
                 WHEN rAnaliseVisual.frk_tipo_arquivo_secundario IS NOT NULL THEN 3
                 ELSE 2
               END ind_local
             , CASE arq.ind_local_arquivo
                 WHEN CONST_IND_LOCAL_ARQUIVO_BRSCAN THEN pkg_constante.CONST_IMAGEM_ORIGEM_INTRANET
                 ELSE pkg_constante.CONST_IMAGEM_ORIGEM_LOCAL
               END cod_origem
             , CASE WHEN cam_carimbo_tempo IS NOT NULL THEN 1
                    ELSE 2
               END ind_carimbo_tempo
          FROM viw_arquivo arq
         WHERE frk_registro = rRegistroFila.frk_registro
           AND (frk_tipo_arquivo IN(rAnaliseVisual.frk_tipo_arquivo_primario, rAnaliseVisual.frk_tipo_arquivo_secundario)
                OR rAnaliseVisual.tip_comparacao = 3)
         ORDER BY prk_arquivo
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
    ELSE
      FOR tab_temp IN(
        SELECT *
          FROM TABLE(fListarArquivoRegistro(rRegistroFila.frk_registro, rRegistroFila.cod_analise, rRegistroFila.cod_subanalise))
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
    END IF;

    IF rFluxo.frk_modulo = pkg_constante.CONST_MODL_BRSAFE_DOC_VERDADE THEN
      FOR tab_temp IN(
        SELECT TO_NUMBER(des_value) prk_arquivo
             , TO_NUMBER(NULL) frk_tipo_arquivo
             , des_label cam_arquivo
             , 1 num_pagina
             , 1 qtd_pagina
             , 2 ind_local
             , pkg_constante.CONST_IMAGEM_ORIGEM_PROC cod_origem
             , 2 ind_carimbo_tempo
          FROM TABLE(pkg_brsafe.fListarArquivoDocVerdadeira(v_frk_registro_fluxo))
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
    ELSIF rFluxo.frk_modulo = pkg_constante.CONST_MODL_BRSAFE_DOC_FRAUDE THEN
      FOR tab_temp IN(
        SELECT TO_NUMBER(vCampo) prk_arquivo
             , TO_NUMBER(NULL) frk_tipo_arquivo
             , vValor1 AS cam_arquivo
             , 1 num_pagina
             , 1 qtd_pagina
             , 2 ind_local
             , pkg_constante.CONST_IMAGEM_ORIGEM_PROC cod_origem
             , 2 ind_carimbo_tempo
          FROM TABLE(pkg_brsafe.fListarDadoDocFraudada(v_frk_registro_fluxo, NULL, pkg_constante.CONST_SIM))
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;
    END IF;
    RETURN;
  END fListarArquivoRegistroFluxo;

  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  --- FUNÇÕES DE DIGITALIZAÇÃO
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Lista os tipos de arquivo disponíveis para a digitalizacao
   * @param v_frk_cliente: Código do cliente
   * @param v_cod_registro: Código do registro
   **/
  FUNCTION fListarTipoArquivoRegistroDig(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.tTipoArquivoDigitalizacao PIPELINED IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRegistro sph_registro%ROWTYPE:=pkg_registro.fDadosRegistro(rRegistroFluxo.frk_registro);

    nArquivosCorrecao NUMBER;
  BEGIN
    IF rRegistro.prk_registro IS NULL THEN
      RETURN;
    END IF;

    nArquivosCorrecao := pkg_dominio.fValidarControleAcesso(v_frk_fluxo => rRegistroFluxo.frk_fluxo
                                                          , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_DIG_CORRECAO);
    IF nArquivosCorrecao = pkg_constante.CONST_SIM THEN
      FOR tab_temp IN(
        SELECT TO_NUMBER(NULL)
             , prk_tipo_arquivo prk_grupo_arquivo
             , nom_tipo_arquivo nom_grupo_arquivo
             , prk_tipo_arquivo
             , nom_tipo_arquivo
             , 1 ind_grupo_obrigatorio
             , '' cod_cor
             , cod_tipo_arquivo
          FROM cfg_tipo_arquivo cta
         WHERE EXISTS(
                 SELECT NULL
                   FROM sph_registro_alerta sra
                  WHERE frk_registro = rRegistro.prk_registro
                    AND sra.frk_tipo_arquivo = cta.prk_tipo_arquivo
               )
      )
      LOOP
        PIPE ROW(tab_temp);
      END LOOP;

      RETURN ;
    END IF;
    FOR tab_temp IN(
      SELECT cnha.frk_nivel_hierarquico
           , NVL(prk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
           , nom_grupo_arquivo
           , prk_tipo_arquivo
           , nom_tipo_arquivo
           , cfa.ind_grupo_obrigatorio
           , cod_cor
           , cod_tipo_arquivo
        FROM cfg_fluxo_arquivo cfa
       INNER JOIN cfg_tipo_arquivo
             ON prk_tipo_arquivo = frk_tipo_arquivo
       LEFT JOIN cfg_nivel_hierarquico_arquivo cnha
            ON cnha.frk_tipo_arquivo = prk_tipo_arquivo AND frk_nivel_Hierarquico = rRegistro.frk_nivel_hierarquico
       LEFT JOIN cfg_grupo_arquivo
            ON prk_grupo_arquivo = NVL(cnha.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
       WHERE cfa.frk_fluxo = rRegistroFluxo.frk_fluxo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;

  END fListarTipoArquivoRegistroDig;

  /**
   * Função para listar os tipos de arquivo disponíveis para o workflow (Digitalização ou Reclassificação)
   * @param v_frk_nivel_hierarquico: Código do nível hierarquico
   **/
  FUNCTION fListarTipoArquivoNH(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tTipoArquivoDigitalizacao PIPELINED IS
    rNivelHierarquico tab_nivel_hierarquico%ROWTYPE := pkg_dominio.fDadosNivelHierarquico(v_frk_nivel_hierarquico);
  BEGIN
    FOR tab_temp IN(
      SELECT cnh.frk_nivel_hierarquico
           , NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
           , nom_grupo_arquivo
           , prk_tipo_arquivo
           , nom_tipo_arquivo
           , ind_obrigatorio
           , cod_cor
           , cod_tipo_arquivo
        FROM TABLE(PKG_DIGITALIZACAO_TMP.fListarTipoArquivo(rNivelHierarquico.frk_cliente))
        LEFT JOIN cfg_nivel_hierarquico_arquivo cnh
             ON (frk_tipo_arquivo = prk_tipo_arquivo AND frk_nivel_hierarquico = rNivelHierarquico.prk_nivel_hierarquico)
        LEFT JOIN cfg_grupo_arquivo
             ON prk_grupo_arquivo = NVL(cnh.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
       ORDER BY nom_grupo_arquivo, nom_tipo_arquivo
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarTipoArquivoNH;
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  --- FUNÇÕES DE RECLASSIFICAÇÃO
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  /**
   * Lista os tipos de arquivos disponível para reclassificação de todos os Workflows que o usuário possui acesso
   * @param v_frk_nivel_hierarquico: Nível Hierarquico do usuário
   **/
  FUNCTION fListarTipoArquivoReclUsuario(v_frk_nivel_hierarquico tab_nivel_hierarquico.prk_nivel_hierarquico%TYPE) RETURN pkg_dominio.tTipoArquivoDIgitalizacao PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT *
        FROM (
          SELECT cnha.frk_nivel_hierarquico
               , NVL(prk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
               , nom_grupo_arquivo
               , prk_tipo_arquivo
               , nom_tipo_arquivo
               , TO_NUMBER(NULL)
               , cod_cor
               , cod_tipo_arquivo
            FROM cfg_tipo_arquivo cta
           INNER JOIN cfg_nivel_hierarquico_arquivo cnha
             ON prk_tipo_arquivo = cnha.frk_tipo_arquivo
            LEFT JOIN cfg_grupo_arquivo
                 ON prk_grupo_arquivo = NVL(cnha.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
           WHERE cnha.ind_reclassificar = pkg_constante.CONST_SIM
        )
        RIGHT JOIN (
          SELECT DISTINCT cfg.frk_nivel_hierarquico
            FROM cfg_fluxo cfg
           INNER JOIN cfg_fluxo_acesso cfa
              ON prk_fluxo = cfa.frk_fluxo
           WHERE  cfa.frk_nivel_hierarquico = v_frk_nivel_hierarquico
        ) USING(frk_nivel_Hierarquico)
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarTipoArquivoReclUsuario;

  /**
   * Lista os tipos de arquivo disponíveis para a reclassificação
   * @param v_frk_cliente: Código do cliente
   * @param v_cod_registro: Código do registro
   **/
  FUNCTION fListarTipoArquivoRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.tTipoArquivoDIgitalizacao PIPELINED IS
   rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
   rRegistro sph_registro%ROWTYPE:=pkg_registro.fDadosRegistro(rRegistroFila.frk_registro);
  BEGIN
    IF rRegistro.prk_registro IS NULL THEN
      RETURN;
    END IF;
    FOR tab_temp IN(
      SELECT cnha.frk_nivel_hierarquico
           , NVL(prk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
           , nom_grupo_arquivo
           , prk_tipo_arquivo
           , nom_tipo_arquivo
           , TO_NUMBER(NULL)
           , cod_cor
           , cod_tipo_arquivo
        FROM TABLE(fListarTipoArquivo(rRegistro.frk_cliente))
       INNER JOIN cfg_nivel_hierarquico_arquivo cnha
             ON cnha.frk_tipo_arquivo = prk_tipo_arquivo AND frk_nivel_Hierarquico = rRegistro.frk_nivel_hierarquico
       LEFT JOIN cfg_grupo_arquivo
            ON prk_grupo_arquivo = NVL(cnha.frk_grupo_arquivo, pkg_constante.CONST_ID_GRUPO_ARQUIVO_DEFAULT)
      WHERE cnha.ind_reclassificar = pkg_constante.CONST_SIM
      ORDER BY 5

    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarTipoArquivoRegistroRecl;

  /**
   * Função que retorna lista de documentos digitalizados de um registro
   * @param cod_registro: Código do Registro
   * @param cod_cliente: Código do cliente da digitalização
   * @return: tArquivo com a lista dos arquivos digitalizados
   **/
  FUNCTION fListarArquivoRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tListaArquivo PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo:= pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
  BEGIN
    FOR tab_temp IN(
      SELECT *
        FROM table(fListarArquivoRegistro(rRegistroFila.frk_registro))
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN;
  END fListarArquivoRegistroRecl;

  /**
   * Função para listar as alertas de um registro para um tipo de arquivo
   * @param cod_registro: Código do Registro
   * @param cod_cliente: Código do cliente da digitalização
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return: Lista de Alertas
   **/
  FUNCTION fListarAlertaRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                           , v_frk_arquivo cfg_tipo_arquivo.prk_tipo_arquivo%TYPE) RETURN pkg_dominio.tSelectCheck PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo;
    rRegistro sph_registro%ROWTYPE;
    rArquivo sph_arquivo%ROWTYPE;
  BEGIN
    rRegistroFila := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRegistro := pkg_registro.fDadosRegistro(rRegistroFila.frk_registro);
    rArquivo := fDadosArquivo(v_frk_arquivo);

    FOR tab_temp IN(
      SELECT TO_CHAR(frk_alerta)
           , des_alerta
           , CASE
               WHEN rta.frk_registro IS NOT NULL THEN 1
               ELSE 2
             END des_checkado
        FROM cfg_tipo_arquivo_alerta cta
        LEFT JOIN (
          SELECT *
            FROM TABLE(pkg_registro.fListarAlertaRegistro(v_frk_registro => rRegistro.prk_registro))
           WHERE frk_modulo = pkg_constante.CONST_MODL_RECLASSIFICACAO
        ) rta
             USING(frk_alerta, frk_tipo_arquivo)
       INNER JOIN cfg_alerta
             ON prk_alerta = frk_alerta
       WHERE (frk_nivel_hierarquico = rRegistro.frk_nivel_hierarquico OR frk_nivel_hierarquico IS NULL)
         AND frk_tipo_arquivo = rArquivo.frk_tipo_arquivo
       ORDER BY des_alerta
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
    RETURN ;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END fListarAlertaRecl;

  /**
   * Função para desativar um arquivo
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
  FUNCTION fDesativarArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                           , v_frk_arquivo_referencia sph_arquivo.frk_arquivo_referencia%TYPE DEFAULT NULL) RETURN sph_arquivo.prk_arquivo%TYPE IS
    nArquivo sph_arquivo.prk_arquivo%TYPE;
  BEGIN
    UPDATE sph_arquivo
       SET sts_arquivo = pkg_constante.CONST_INATIVO
         , frk_arquivo_referencia = v_frk_arquivo_referencia
     WHERE prk_arquivo = v_frk_arquivo
    RETURNING prk_arquivo INTO nArquivo;
    RETURN nArquivo;
  END fDesativarArquivo;

  /**
   * Verifica se existem arquivo com classificação apenas manual
   * @param v_frk_registro: ID do registro
   **/
  FUNCTION fExisteReclManualRegistro(v_frk_registro sph_registro.prk_registro%TYPE) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO nTotal
      FROM viw_arquivo
     WHERE ind_classificacao_automatica = pkg_constante.CONST_NAO
       AND frk_registro = v_frk_registro;
    IF nTotal = 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END fExisteReclManualRegistro;

  /**
   * Função para atualizar a quantidade de páginas de um arquivo
   * @param v_frk_arquivo: Código do Arquivo
   * @param v_qtd_pagina: Quantidade de páginas do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fAtualizarQtdPaginaArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                                    , v_qtd_pagina sph_arquivo.qtd_pagina%TYPE) RETURN pkg_dominio.recRetorno IS
  BEGIN
    UPDATE sph_arquivo
       SET qtd_pagina  = v_qtd_pagina
     WHERE prk_arquivo = v_frk_arquivo;
    IF SQL%ROWCOUNT > 0 THEN
      COMMIT;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 6);
    ELSE
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -2);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fAtualizarQtdPaginaArquivo;

  /**
   * Função para popular uma lista de arquivos
   * @param lArquivo: Lista de arquivos
   * @param rArquivo: Record com as informações do arquivo que será incluído na lista
   **/
  PROCEDURE pAdicionarArquivo(lArquivo IN OUT tArquivo
                           , rArquivo sph_arquivo%ROWTYPE) IS
  BEGIN
    lArquivo.EXTEND;
    lArquivo(lArquivo.COUNT) := rArquivo;
  END pAdicionarArquivo;

  /**
   * Função para reclassificar um arquivo
   * @param v_cod_usuario: Usuário que reclassificou o arquivo
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_tipo_arquivo: Novo tipo do arquivo
   * @return pkg_dominio.recRetorno: Record com o resultado da ação
   **/
  FUNCTION fReclassificarArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                               , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                               , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE
                               , v_ind_comit NUMBER DEFAULT pkg_constante.CONST_SIM
                               , v_ind_classificacao_automatica sph_arquivo.ind_classificacao_automatica%TYPE DEFAULT NULL) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo:= pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise);
    rArquivo sph_arquivo%ROWTYPE;
    vMensagemLog sph_registro_log.des_mensagem%TYPE;
  BEGIN
    IF rRegistroFila.prk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, -3);
    ELSIF rRegistroFila.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 2);
    ELSIF v_frk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -3);
    ELSIF v_frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;

    rArquivo := fDadosArquivo(v_frk_arquivo);
    IF rArquivo.prk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -2);
    END IF;
    IF rArquivo.frk_tipo_arquivo <> v_frk_tipo_arquivo THEN
      UPDATE sph_arquivo
         SET frk_tipo_arquivo = v_frk_tipo_arquivo
           , ind_classificacao_automatica = v_ind_classificacao_automatica
       WHERE prk_arquivo = v_frk_arquivo;

      --// Logar as alteracoes de reclassificacao
      SELECT 'De: ' || (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = rArquivo.frk_tipo_arquivo)
          || ' Para: ' || (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = v_frk_tipo_arquivo)
       INTO vMensagemLog
       FROM dual;
      pkg_registro.pLogarAlteracaoRegistro(NVL(rUsuario.des_matricula, pkg_constante.CONST_COD_USUARIO_SISTEMA), rArquivo.frk_registro, pkg_constante.CONST_ACT_RECL_ARQUIVO , rArquivo.frk_tipo_arquivo , v_frk_tipo_arquivo, v_frk_arquivo => v_frk_arquivo, v_des_mensagem => vMensagemLog);
    END IF;
    IF v_ind_comit = pkg_constante.CONST_SIM THEN
      COMMIT;
    END IF;

    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 2);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fReclassificarArquivo;


  /**
   * Função para criar uma cópia de uma imagem no banco
   * @param v_cod_usuario: Usuário logado do sistema
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_tipo_arquivo: Novo tipo de arquivo
   **/
  FUNCTION fDuplicarArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                          , v_frk_arquivo_original sph_arquivo.prk_arquivo%TYPE
                          , v_frk_tipo_arquivo sph_arquivo.frk_tipo_arquivo%TYPE
                          , v_cam_arquivo sph_arquivo.cam_arquivo%TYPE) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise);
    rArquivo sph_arquivo%ROWTYPE;
    rRetorno pkg_dominio.recRetorno;
    vMensagemLog sph_registro_log.des_mensagem%TYPE;
    nTipoArquivoOriginal sph_arquivo.frk_tipo_arquivo%TYPE;
  BEGIN
    IF rRegistroFila.prk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, -3);
    ELSIF v_frk_arquivo_original IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -3);
    ELSIF v_frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;

    rArquivo := fDadosArquivo(v_frk_arquivo_original);
    nTipoArquivoOriginal := rArquivo.frk_tipo_arquivo;
    IF rArquivo.prk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -2);
    END IF;

    rArquivo.frk_tipo_arquivo := v_frk_tipo_arquivo;
    rArquivo.frk_arquivo_referencia := rArquivo.prk_arquivo;
    rArquivo.cam_arquivo := v_cam_arquivo;
    rRetorno := fDigitalizarArquivo(rUsuario.des_matricula, rArquivo);
    IF rRetorno.prk_retorno < 0 THEN
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    COMMIT;

    SELECT 'De: ' || (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = nTipoArquivoOriginal)
        || ' Para: ' || (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = v_frk_tipo_arquivo)
     INTO vMensagemLog
      FROM dual;
    pkg_registro.pLogarAlteracaoRegistro(rUsuario.des_matricula, rArquivo.frk_registro, pkg_constante.CONST_ACT_DUPL_ARQUIVO, v_val_novo => v_frk_tipo_arquivo , v_frk_arquivo => v_frk_arquivo_original, v_des_mensagem => vMensagemLog);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 3, rRetorno.cod_registro);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fDuplicarArquivo;

  /**
   * Função para excluír um arquivo do sistema
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
  FUNCTION fExcluirArquivoRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                             , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN pkg_dominio.recRetorno IS

    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise);
    rArquivo sph_arquivo%ROWTYPE;
    nArquivo NUMBER;
    nTeste NUMBER;
    vMensagemLog sph_registro_log.des_mensagem%TYPE;
  BEGIN
    IF rRegistroFila.prk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, -3);
    ELSIF v_frk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -3);
    END IF;

    SELECT COUNT(1)
      INTO nTeste
      FROM viw_arquivo
     WHERE frk_registro = rRegistroFila.frk_registro
       AND prk_arquivo <> v_frk_arquivo;
    IF nTeste = 0 THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;

    rArquivo := fDadosArquivo(v_frk_arquivo);
    IF rArquivo.prk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -3);
    END IF;
    nArquivo := fDesativarArquivo(v_frk_arquivo);
    IF nArquivo IS NOT NULL THEN
      SELECT 'Arquivo Excluido:' || (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = rArquivo.frk_tipo_arquivo)
       INTO vMensagemLog
        FROM dual;
      pkg_registro.pLogarAlteracaoRegistro(rUsuario.des_matricula, rArquivo.frk_registro, pkg_constante.CONST_ACT_EXCL_ARQUIVO, v_frk_arquivo => v_frk_arquivo, v_val_antigo => rArquivo.frk_tipo_arquivo, v_des_mensagem => vMensagemLog );
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 7, nArquivo);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fExcluirArquivoRecl;

  /**
   * Função para excluír um arquivo do sistema
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
  FUNCTION fExcluirArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN pkg_dominio.recRetorno IS
  BEGIN
    RETURN fExcluirArquivoRecl(v_frk_registro_fluxo, v_frk_arquivo);
  END fExcluirArquivo;

  /**
   * Função para unir vários arquivos em um só
   * @param v_cod_usuario: Usuário do sistema
   * @param lArquivoOriginal: Lista com os PRKs dos arquivos originais
   * @param rArquivoNovo: Record com as informações do novo arquivo gerado
   **/
  FUNCTION fUnirArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                      , lArquivoOriginal NUM_ARRAY
                      , rArquivoNovo sph_arquivo%ROWTYPE
                      , v_ind_commit BOOLEAN DEFAULT TRUE) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise);
    rArquivoIn sph_arquivo%ROWTYPE := rArquivoNovo;
    rArquivoBase sph_arquivo%ROWTYPE;
    rRetorno pkg_dominio.recRetorno;
    vMensagemLog sph_registro_log.des_mensagem%TYPE;
  BEGIN
    IF rRegistroFila.prk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, -3);
    ELSIF lArquivoOriginal.COUNT < 2 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -3);
    ELSIF rArquivoIn.cam_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    ELSIF rArquivoIn.frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;
    rArquivoBase := fDadosArquivo(lArquivoOriginal(1));

    rArquivoIn.frk_registro := rArquivoBase.frk_registro;
    rArquivoIn.ind_local_arquivo := rArquivoBase.ind_local_arquivo;
    rRetorno := fDigitalizarArquivo(rUsuario.des_matricula, rArquivoIn);
    rArquivoIn.prk_arquivo := rRetorno.cod_registro;
    IF rRetorno.prk_retorno < 0 THEN
      ROLLBACK;
      RETURN rRetorno;
    END IF;
    COMMIT;
    FOR nIndex IN 1..lArquivoOriginal.COUNT
    LOOP
      IF fDesativarArquivo(lArquivoOriginal(nIndex), rRetorno.cod_registro) IS NULL THEN
        ROLLBACK;
        RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
      END IF;
    END LOOP;
    IF v_ind_commit THEN
      COMMIT;
      SELECT 'Arquivos Unidos: '
          || (SELECT LISTAGG(nom_tipo_arquivo, ',') WITHIN GROUP(ORDER BY nom_tipo_arquivo)
                FROM (SELECT DISTINCT nom_tipo_arquivo
                        FROM sph_arquivo t
                       INNER JOIN cfg_tipo_arquivo
                             ON prk_tipo_arquivo = frk_tipo_arquivo
                       WHERE prk_arquivo IN(SELECT COLUMN_VALUE FROM TABLE(lArquivoOriginal))
                     )
             )
          || ' Arquivo gerado: '|| (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = rArquivoIn.frk_tipo_arquivo)
       INTO vMensagemLog
       FROM dual;
      pkg_registro.pLogarAlteracaoRegistro(rUsuario.des_matricula, rArquivoIn.frk_registro, pkg_constante.CONST_ACT_JOIN_ARQUIVO, NULL, rArquivoIn.frk_tipo_arquivo, vMensagemLog, rArquivoIn.prk_arquivo);
      COMMIT;
    END IF;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 5, rRetorno.cod_registro);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fUnirArquivo;

  /**
   * Função para popular uma lista de uniões em massa
   **/
  PROCEDURE pAdicionarArquivoUnir(lArquivoUnir IN OUT tArquivoUnir
                                , lArquivoOriginal NUM_ARRAY
                                , rArquivoNovo sph_arquivo%ROWTYPE) IS
  BEGIN
    lArquivoUnir.EXTEND;
    lArquivoUnir(lArquivoUnir.COUNT).lArquivoOriginal := lArquivoOriginal;
    lArquivoUnir(lArquivoUnir.COUNT).rArquivoNovo := rArquivoNovo;
  END pAdicionarArquivoUnir;

  /**
   * Função para realizar mais de
   **/
  FUNCTION fUnirAllArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , lArquivoUnir tArquivoUnir) RETURN pkg_dominio.recRetorno IS
    rRetorno pkg_dominio.recRetorno;
  BEGIN
    FOR nIndex IN 1..lArquivoUnir.COUNT
    LOOP
      rRetorno := fUnirArquivo(v_frk_registro_fluxo, lArquivoUnir(nIndex).lArquivoOriginal, lArquivoUnir(nIndex).rArquivoNovo, FALSE);
      IF rRetorno.prk_retorno < 0 THEN
        ROLLBACK;
        RETURN rRetorno;
      END IF;
    END LOOP;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 5, rRetorno.cod_registro);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fUnirAllArquivo;
  /**
   * Função para separar um arquivo em vários
   * @param v_frk_registro_fluxo: Código da fila de análise
   * @param v_frk_arquivo_original: Codigo do Arquivo
   * @param lArquivoNovo: Lista de novos arquivos gerados
   **/
  FUNCTION fSepararArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                         , v_frk_arquivo_original sph_arquivo.prk_arquivo%TYPE
                         , lArquivoNovo tArquivo
                         , v_ind_comit NUMBER DEFAULT pkg_constante.CONST_SIM) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise) ;
    rRetorno pkg_dominio.recRetorno;
    rArquivo sph_arquivo%ROWTYPE;
    rArquivoNovo  sph_arquivo%ROWTYPE;
    vMensagemLog sph_registro_log.des_mensagem%TYPE;
    lArquivos NUM_ARRAY:=NUM_ARRAY();
  BEGIN
    IF rRegistroFila.prk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, -3);
    ELSIF v_frk_arquivo_original IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    ELSIF lArquivoNovo.COUNT < 2 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;

    rArquivo := fDadosArquivo(v_frk_arquivo_original);
    IF rArquivo.prk_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -2);
    END IF;

    IF fDesativarArquivo(v_frk_arquivo_original) IS NULL THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, -4);
    END IF;

    FOR nIndex IN 1..lArquivoNovo.COUNT
    LOOP
      rArquivoNovo := lArquivoNovo(nIndex);
      rArquivoNovo.frk_arquivo_referencia := v_frk_arquivo_original;
      rArquivoNovo.frk_registro := rArquivo.frk_registro;
      rArquivoNovo.ind_local_arquivo := rArquivo.ind_local_arquivo;
      pkg_base.pAddNumArray(rArquivoNovo.frk_tipo_arquivo, lArquivos);

      rRetorno := fDigitalizarArquivo(rUsuario.des_matricula, rArquivoNovo);
      IF rRetorno.prk_retorno < 0 THEN
        ROLLBACK;
        RETURN rRetorno;
      END IF;
    END LOOP;
    IF v_ind_comit = pkg_constante.CONST_SIM THEN
      SELECT 'Arquivo dividido: '|| (SELECT nom_tipo_arquivo FROM cfg_tipo_arquivo WHERE prk_tipo_arquivo = rArquivo.frk_tipo_arquivo)
          || ' Arquivos gerados: '
          || (SELECT LISTAGG(nom_tipo_arquivo, ',') WITHIN GROUP(ORDER BY nom_tipo_arquivo)
                FROM (SELECT DISTINCT nom_tipo_arquivo
                        FROM cfg_tipo_arquivo
                       WHERE prk_tipo_arquivo IN(SELECT COLUMN_VALUE FROM TABLE(lArquivos))))
        INTO vMensagemLog
        FROM dual;
      pkg_registro.pLogarAlteracaoRegistro(rUsuario.des_matricula, rArquivo.frk_registro, pkg_constante.CONST_ACT_SPLIT_ARQUIVO, rArquivo.frk_tipo_arquivo, NULL, vMensagemLog, rArquivo.prk_arquivo);
      COMMIT;
    END IF;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, 8, rRetorno.cod_registro);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_RECLASSIFICACAO, pkg_constante.CONST_FALHA);
  END fSepararArquivo;

  /**
   * Função para criar uma cópia de uma imagem no banco
   * @param v_cod_usuario: Usuário logado do sistema
   * @param v_frk_arquivo: Código do arquivo
   * @param v_frk_registro_fluxo: Código do fluxo atual
   * @param lAlerta: Códigos dos alertas a serem inseridos no módulo
   **/
  FUNCTION fAtualizarAlertaRegistroRecl(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                      , v_frk_arquivo sph_arquivo.prk_arquivo%TYPE
                                      , lAlerta NUM_ARRAY) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise) ;
    rArquivo sph_arquivo%ROWTYPE;
    rAlerta sph_registro_alerta%ROWTYPE;
  BEGIN
    rArquivo := fDadosArquivo(v_frk_arquivo);
    rAlerta.frk_modulo := pkg_constante.CONST_MODL_RECLASSIFICACAO;
    rAlerta.frk_registro := rArquivo.frk_registro;
    rAlerta.frk_tipo_arquivo := rArquivo.frk_tipo_arquivo;
    rAlerta.frk_registro_fluxo := v_frk_registro_fluxo;
    RETURN pkg_registro.fInserirAlertaRegistro(rUsuario.des_matricula, rAlerta, lAlerta);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN  pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fAtualizarAlertaRegistroRecl;

  /**
   * Função para finalizar a etapa de reclassificação de um registro
   * @param v_frk_registro_fluxo: Código da fila de análise
   **/
  FUNCTION fFinalizarReclassificacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, 1);
    END IF;

    --// Limpa os alertas inseridos na reclassificação para tipos de documentos que foram reclassificados e deixaram de existir
    DELETE
      FROM sph_registro_alerta sra
     WHERE frk_registro = rRegistroFluxo.frk_registro
       AND frk_registro_fluxo = v_frk_registro_fluxo
       AND NOT EXISTS (SELECT *
                         FROM sph_arquivo spa
                        WHERE frk_registro = rRegistroFluxo.frk_registro
                          AND sra.frk_tipo_arquivo = spa.frk_tipo_arquivo);

    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo, rRegistroFluxo);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, 1);
  EXCEPTION
    WHEN pkg_registro.EXCEPT_INTERROMPER_ETAPA THEN
      RETURN pkg_registro.fRetornarMensagemErroReg(v_frk_registro_fluxo);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(NULL, pkg_constante.CONST_FALHA);
  END fFinalizarReclassificacao;

  /**
   * Função para validar se todos os documentos obrigatórios foram enviados
   * @param v_frk_fluxo: Código do fluxo(etapa) da digitalização
   * @param v_lArquivo: Lista de arquivos enviados
   * @return: TRUE: Todos os arquivos obrigatórios enviados
              FALSE: Arquivos obrigatórios não enviados
   **/
  FUNCTION fValidarDigitalizaObrigatorio(v_frk_fluxo cfg_fluxo.prk_fluxo%TYPE
                                       , v_lArquivo PKG_DIGITALIZACAO_TMP.tArquivo) RETURN BOOLEAN IS
    lListaArquivos NUM_ARRAY := NUM_ARRAY();
    nQtdDocObrigatorioAusente NUMBER;
  BEGIN
    FOR nIndex IN 1..v_lArquivo.COUNT
    LOOP
      pkg_base.pAddNumArray(v_lArquivo(nIndex).frk_tipo_arquivo, lListaArquivos);
    END LOOP;
    SELECT COUNT(1)
      INTO nQtdDocObrigatorioAusente
      FROM (
        SELECT cnha.frk_grupo_arquivo, MAX(COLUMN_VALUE)
          FROM cfg_fluxo_arquivo cfa
         INNER JOIN cfg_tipo_arquivo
            ON prk_tipo_arquivo = frk_tipo_arquivo
         INNER JOIN cfg_fluxo cff
            ON prk_fluxo = cfa.frk_fluxo
         INNER JOIN cfg_nivel_hierarquico_arquivo cnha
               ON (cnha.frk_nivel_hierarquico = cff.frk_nivel_hierarquico
                  AND cnha.frk_tipo_arquivo = cfa.frk_tipo_arquivo)
          LEFT JOIN TABLE(lListaArquivos)
               ON cfa.frk_tipo_arquivo = COLUMN_VALUE
         WHERE cfa.frk_fluxo = v_frk_fluxo
           AND ind_grupo_obrigatorio = pkg_constante.CONST_ATIVO
         GROUP BY cnha.frk_grupo_arquivo
         HAVING MAX(COLUMN_VALUE) IS NULL
      );
    IF nQtdDocObrigatorioAusente = 0 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END fValidarDigitalizaObrigatorio;
  /**
   * Função para processar todos os arquivos digitalizados
   * @param v_frk_registro_fluxo: Código do Fluxo;
   * @param lArquivo: Lista com os arquivos enviados.
   * @return 1: Arquivo adicionado;
   *        -1: Falha na gestão ao Salvar o Arquivo;
   *        -2: Registro não informado;
   *        -5: Fluxo não Informado;
   *        -6: Nenhum arquivo enviado.
   **/
  FUNCTION fFinalizarDigitalizacao(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , lArquivo PKG_DIGITALIZACAO_TMP.tArquivo
                                 , v_lAlerta STR_ARRAY DEFAULT STR_ARRAY()) RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRegistro sph_registro%ROWTYPE;
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFluxo.frk_usuario_analise) ;
    rRetorno pkg_dominio.recRetorno;
    rArquivo sph_arquivo%ROWTYPE;
    rAlerta sph_registro_alerta%ROWTYPE;
    lAlerta NUM_ARRAY:=NUM_ARRAY();
  BEGIN
    IF rRegistroFluxo.frk_registro IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO,-2);
    ELSIF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
    ELSIF v_frk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -5);
    ELSIF lArquivo.COUNT = 0 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, -6);
    END IF;

    FOR nIndex IN 1..lArquivo.COUNT
    LOOP
      rArquivo := lArquivo(nIndex);
      rArquivo.frk_registro := rRegistroFluxo.frk_registro;
      rArquivo.frk_registro_fluxo := v_frk_registro_fluxo;
      rRetorno := PKG_DIGITALIZACAO_TMP.fDigitalizarArquivo(rUsuario.des_matricula, rArquivo);
      IF rRetorno.prk_retorno < 0 THEN
         ROLLBACK;
         RETURN rRetorno;
      END IF;
      COMMIT;
    END LOOP;

    IF v_lAlerta.COUNT > 0 THEN
      rAlerta.frk_registro_fluxo := v_frk_registro_fluxo;
      rAlerta.frk_registro := rRegistroFluxo.frk_registro;
      rRegistro := pkg_registro.fDadosRegistro(rRegistroFluxo.frk_registro);
      FOR nIndex IN 1..v_lAlerta.COUNT
      LOOP
        pkg_base.pAddNumArray(pkg_dominio.fGetChaveAlerta(rRegistro.frk_cliente, v_lAlerta(nIndex)), lAlerta);
      END LOOP;
      IF pkg_registro.fInserirAlertaRegistro(rUsuario.des_matricula, rAlerta, lAlerta).prk_retorno IS NULL THEN
        NULL;
      END IF;
    END IF;
    /*
    IF NOT pkg_consulta_externa.fCriarConsultaExterna(rRegistroFluxo.frk_registro, pkg_consulta_externa.CONST_TIP_CONS_CRUZAMENTO_BASE, NULL, v_frk_registro_fluxo ) THEN
      NULL;
    END IF;
    */
    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN pkg_registro.EXCEPT_INTERROMPER_ETAPA THEN
      pkg_registro.pApagarDadosAnalise(v_frk_registro_fluxo,rRegistroFluxo);
      RETURN pkg_registro.fRetornarMensagemErroReg(v_frk_registro_fluxo);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN  pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM );
  END fFinalizarDigitalizacao;

  /**
   * Funcao para finalizar uma digitalizacao sem arquivos
   * @param v_frk_registro_fluxo: Codigo da fila de digitalizacao
   * @param v_des_alerta: ALERTA a ser inserido no sistema
   **/
  FUNCTION fFinalizarDigSemArquivo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                 , v_des_alerta cfg_alerta.des_alerta%TYPE DEFAULT pkg_constante.CONST_DES_ALERTA_SEM_DIGIT)  RETURN pkg_dominio.recRetorno IS
    rRegistroFluxo pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rRegistro sph_registro%ROWTYPE:=pkg_registro.fDadosRegistro(rRegistroFluxo.frk_registro);
    nAlerta cfg_alerta.prk_alerta%TYPE:=pkg_dominio.fGetChaveAlerta(rRegistro.frk_cliente, NVL(v_des_alerta, pkg_constante.CONST_DES_ALERTA_SEM_DIGIT));
  BEGIN
    IF rRegistroFluxo.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
    END IF;
    IF nAlerta IS NOT NULL THEN
      INSERT INTO sph_registro_alerta (frk_registro, frk_alerta, frk_registro_fluxo)
                               VALUES (rRegistroFluxo.frk_registro, nAlerta , rRegistroFluxo.prk_registro_fluxo);
    END IF;

    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_DIGITALIZACAO, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN pkg_registro.EXCEPT_INTERROMPER_ETAPA THEN
      RETURN pkg_registro.fRetornarMensagemErroReg(v_frk_registro_fluxo);
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN  pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_error => SQLERRM );
  END fFinalizarDigSemArquivo;

  ------------------------------------------------------------------------------------------------------------------------------
  ---- GESTÃO DE TEMPLATES ----------
  ------------------------------------------------------------------------------------------------------------------------------
  PROCEDURE fDesativarArquivoTemplateGeral(v_frk_nivel_hierarquico cfg_arquivo_template.frk_nivel_hierarquico%TYPE
                                         , v_frk_tipo_arquivo cfg_arquivo_template.frk_tipo_arquivo%TYPE
                                         , v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) IS
  BEGIN
    UPDATE cfg_arquivo_template
       SET sts_arquivo_template = pkg_constante.CONST_INATIVO
      WHERE frk_tipo_arquivo = v_frk_tipo_arquivo
        AND frk_nivel_hierarquico = v_frk_nivel_hierarquico
        AND prk_arquivo_template <> v_frk_arquivo_template;
  END fDesativarArquivoTemplateGeral;


  FUNCTION fDadosArquivoTemplateCampo(v_frk_arquivo_template_campo cfg_arquivo_template_campo.prk_arquivo_template_campo%TYPE) RETURN cfg_arquivo_template_campo%ROWTYPE IS
    rArquivoTemplateCampo cfg_arquivo_template_campo%ROWTYPE;
  BEGIN
    SELECT *
      INTO rArquivoTemplateCampo
     FROM cfg_arquivo_template_campo
    WHERE prk_arquivo_template_campo = v_frk_arquivo_template_campo;

    RETURN rArquivoTemplateCampo;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END fDadosArquivoTemplateCampo;
  /**
   * Função para popular uma lista de campos de marcação de um template
   * @param v_lArquivoTemplateCampo: lista de campos
   * @param v_rArquivoTemplateCampo: Record com os dados do campo
   **/
  PROCEDURE pAdicionarArquivoTemplateCampo(v_lArquivoTemplateCampo IN OUT tArquivoTemplateCampo
                                         , v_rArquivoTemplateCampo recArquivoTemplateCampo) IS
  BEGIN
    v_lArquivoTemplateCampo.EXTEND;
    v_lArquivoTemplateCampo(v_lArquivoTemplateCampo.COUNT) := v_rArquivoTemplateCampo;
  END pAdicionarArquivoTemplateCampo;

  /**
   * Função para verificar se existeo template para o nivel hierarquico
   * @param v_frk_nivel_hierarquico: ID do nivel hierarquico
   * @param v_rArquivoTemplate: Record com as informações do template
   **/
  FUNCTION fExisteArquivoTemplate(v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                                , v_rArquivoTemplate cfg_arquivo_template%ROWTYPE) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO nTotal
      FROM cfg_arquivo_template t
     WHERE UPPER(nom_arquivo_template) LIKE UPPER(v_rArquivoTemplate.nom_arquivo_template)
       AND t.frk_nivel_hierarquico = v_frk_nivel_hierarquico
       AND (v_rArquivoTemplate.prk_arquivo_template IS NULL OR v_rArquivoTemplate.prk_arquivo_template <> prk_arquivo_template);
    IF nTotal = 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END fExisteArquivoTemplate;

  /**
   * Função para buscar os dados do Arquivo Template para edição
   * @param v_frk_arquivo_template: Código do arquivo template
   * @param v_rArquivoTemplate: Record com os dados do template retornado
   **/
  FUNCTION fDadosArquivoTemplate(v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE
                               , v_rArquivoTemplate IN OUT cfg_arquivo_template%ROWTYPE) RETURN pkg_dominio.recRetorno IS
  BEGIN
    SELECT * INTO v_rArquivoTemplate
      FROM cfg_arquivo_template
     WHERE prk_arquivo_template = v_frk_arquivo_template;

    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fDadosArquivoTemplate;

  /**
   * Função para listar os campos configurados em um template
   * @param v_frk_arquivo_template: Código do template;
   **/
  FUNCTION fListarArquivoTemplateCampo(v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN tArquivoTemplateCampo PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT prk_arquivo_template_campo
            , tip_arquivo_campo
            , frk_formulario
            , frk_grupo
            , frk_campo
            , NVL(nom_campo, nom_arquivo_template_campo) nom_campo
            , num_pagina
            , num_posicao_x
            , num_posicao_y
            , num_largura
            , num_altura
            , frk_campo_opcao
        FROM cfg_arquivo_template_campo
        LEFT JOIN idx_campo
             ON prk_campo = frk_campo
       WHERE frk_arquivo_template = v_frk_arquivo_template
         AND sts_arquivo_template_campo = pkg_constante.CONST_ATIVO
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarArquivoTemplateCampo;

  /**
   * Função para gerenciar um template de arquivo
   * @param v_cod_usuario: ID do usuário
   * @param v_frk_nivel_hierarquico: ID do Nível hierarquico
   * @param v_rArquivoTemplate: Record com os dados do template
   * @param v_lArquivoTemplateCampo: Lista de campo de demarcação do template
   **/
  FUNCTION fGerenciarArquivoTemplate(v_cod_usuario tab_usuario.des_matricula%TYPE
                                   , v_frk_nivel_hierarquico cfg_nivel_hierarquico_arquivo.frk_nivel_hierarquico%TYPE
                                   , v_rArquivoTemplate cfg_arquivo_template%ROWTYPE
                                   , v_lArquivoTemplateCampo tArquivoTemplateCampo) RETURN pkg_dominio.recRetorno IS
    rArquivoTemplate cfg_arquivo_template%ROWTYPE:=v_rArquivoTemplate;
    rArquivoTemplateCampo recArquivoTemplateCampo;
  BEGIN
    IF v_cod_usuario IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -3);
    ELSIF v_frk_nivel_hierarquico IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => -5);
    ELSIF rArquivoTemplate.nom_arquivo_template IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, -2);
    ELSIF fExisteArquivoTemplate(v_frk_nivel_hierarquico, rArquivoTemplate) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, -3);
    ELSIF rArquivoTemplate.frk_tipo_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, -4);
    ELSIF rArquivoTemplate.frk_fonte IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, -5);
    ELSIF rArquivoTemplate.prk_arquivo_template IS NULL AND rArquivoTemplate.cam_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, -6);
    END IF;

    rArquivoTemplate.sts_arquivo_template := NVL(rArquivoTemplate.sts_arquivo_template, pkg_constante.CONST_ATIVO);

    IF rArquivoTemplate.prk_arquivo_template IS NULL THEN
      INSERT INTO cfg_arquivo_template (frk_nivel_hierarquico, frk_tipo_arquivo, nom_arquivo_template, cam_arquivo, frk_fonte, sts_arquivo_template, qtd_pagina, num_fonte, num_espessura_assinatura, cod_cor_assinatura)
                                VALUES (v_frk_nivel_hierarquico, rArquivoTemplate.frk_tipo_arquivo, rArquivoTemplate.nom_arquivo_template, rArquivoTemplate.cam_arquivo, rArquivoTemplate.frk_fonte, rArquivoTemplate.sts_arquivo_template, rArquivoTemplate.qtd_pagina, rArquivoTemplate.num_fonte, rArquivoTemplate.num_espessura_assinatura, rArquivoTemplate.cod_cor_assinatura )
        RETURNING prk_arquivo_template INTO rArquivoTemplate.prk_arquivo_template;
    ELSE
      UPDATE cfg_arquivo_template
         SET frk_tipo_arquivo = rArquivoTemplate.frk_tipo_arquivo
           , nom_arquivo_template = rArquivoTemplate.nom_arquivo_template
           , frk_fonte = rArquivoTemplate.frk_fonte
           , sts_arquivo_template = rArquivoTemplate.sts_arquivo_template
           , num_fonte = rArquivoTemplate.num_fonte
           , num_espessura_assinatura = rArquivoTemplate.num_espessura_assinatura
           , cod_cor_assinatura = rArquivoTemplate.cod_cor_assinatura
       WHERE prk_arquivo_template = rArquivoTemplate.prk_arquivo_template;

      UPDATE cfg_arquivo_template_campo
         SET sts_arquivo_template_campo = pkg_constante.CONST_INATIVO
       WHERE frk_arquivo_template = rArquivoTemplate.prk_arquivo_template;
    END IF;

    IF rArquivoTemplate.sts_arquivo_template = pkg_constante.CONST_ATIVO THEN
      fDesativarArquivoTemplateGeral(v_frk_nivel_hierarquico, rArquivoTemplate.frk_tipo_arquivo, rArquivoTemplate.prk_arquivo_template);
    END IF;

    IF v_lArquivoTemplateCampo.COUNT <> 0 THEN
      FOR nIndex IN 1..v_lArquivoTemplateCampo.COUNT
      LOOP
        rArquivoTemplateCampo := v_lArquivoTemplateCampo(nIndex);
        MERGE INTO cfg_arquivo_template_campo target
         USING(
            SELECT rArquivoTemplateCampo.prk_arquivo_template_campo prk_arquivo_template_campo
              FROM dual
         ) base
         ON (target.prk_arquivo_template_campo = base.prk_arquivo_template_campo)
        WHEN MATCHED THEN
          UPDATE SET nom_arquivo_template_campo = rArquivoTemplateCampo.nom_campo
                   , tip_arquivo_campo =          rArquivoTemplateCampo.tip_arquivo_campo
                   , frk_formulario =             rArquivoTemplateCampo.frk_formulario
                   , frk_grupo =                  rArquivoTemplateCampo.frk_grupo
                   , frk_campo =                  rArquivoTemplateCampo.frk_campo
                   , num_pagina =                 rArquivoTemplateCampo.num_pagina
                   , num_posicao_x =              rArquivoTemplateCampo.num_posicao_x
                   , num_posicao_y =              rArquivoTemplateCampo.num_posicao_y
                   , num_largura =                rArquivoTemplateCampo.num_largura
                   , num_altura =                 rArquivoTemplateCampo.num_altura
                   , sts_arquivo_template_campo = pkg_constante.CONST_ATIVO
                   , frk_campo_opcao =            rArquivoTemplateCampo.frk_campo_opcao
        WHEN NOT MATCHED THEN
          INSERT (frk_arquivo_template, nom_arquivo_template_campo, tip_arquivo_campo, frk_formulario, frk_grupo, frk_campo, num_pagina, num_posicao_x, num_posicao_y, num_largura, num_altura, frk_campo_opcao)
          VALUES (rArquivoTemplate.prk_arquivo_template, rArquivoTemplateCampo.nom_campo, rArquivoTemplateCampo.tip_arquivo_campo, rArquivoTemplateCampo.frk_formulario, rArquivoTemplateCampo.frk_grupo, rArquivoTemplateCampo.frk_campo, rArquivoTemplateCampo.num_pagina, rArquivoTemplateCampo.num_posicao_x, rArquivoTemplateCampo.num_posicao_y, rArquivoTemplateCampo.num_largura, rArquivoTemplateCampo.num_altura, rArquivoTemplateCampo.frk_campo_opcao);
      END LOOP;
    END IF;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_GES_TEMPLATE, pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_code => SQLCODE, v_sql_error => SQLERRM);
  END fGerenciarArquivoTemplate;

  /**
  * Ativa/Desativa o Template;
  * @param O problema estava na que: Código do usuário;
  * @param v_frk_arquivo_template: Código do template;
  * @return: Status atual do registro;
  **/
  FUNCTION fAtivarDesativarArqTemplate(v_cod_usuario tab_usuario.des_matricula%TYPE
                                     , v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN pkg_dominio.recRetorno IS
    nStatus cfg_arquivo_template.sts_arquivo_template%TYPE;
  BEGIN
    UPDATE cfg_arquivo_template
       SET sts_arquivo_template = CASE sts_arquivo_template
                         WHEN 1 THEN 2
                         ELSE 1
                       END
         , dat_alteracao = SYSDATE
         , des_matricula_alteracao = v_cod_usuario
    WHERE prk_arquivo_template = v_frk_arquivo_template
    RETURNING sts_arquivo_template INTO nStatus;
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(NULL, 2, nStatus);
  END fAtivarDesativarArqTemplate;

  /**
   * função para buscar um template de um fluxo de assinatura
   * @param v_frk_registro_fluxo: Id do fluxo
   * @param v_rArquivoTemplateFluxo: Record com os dados do template
   **/
  FUNCTION fBuscarArquivoTemplateFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                     , v_rArquivoTemplateFluxo IN OUT recArquivoTemplateFluxo) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);

    --// Indica se é para assinar um arquivo digitalizado para o registro
    nIndAssinarArqDig NUMBER := pkg_dominio.fValidarFluxoFuncionalidade(rRegistroFila.frk_fluxo, pkg_constante.CONST_COD_FUNC_ASS_DIG);
  BEGIN

    SELECT prk_arquivo_template
         , prk_tipo_arquivo
         , nom_tipo_arquivo
         , CASE nIndAssinarArqDig
            WHEN pkg_constante.CONST_NAO THEN cat.cam_arquivo
            ELSE spa.cam_arquivo
           END cam_arquivo_template
         , spa.cam_arquivo cam_arquivo_preenchido
         , cod_fonte
         , num_fonte
         , cat.qtd_pagina
         , num_espessura_assinatura
         , cod_cor_assinatura
      INTO v_rArquivoTemplateFluxo
      FROM cfg_arquivo_template cat
      INNER JOIN cfg_tipo_arquivo cta
            ON prk_tipo_arquivo = frk_tipo_arquivo
      LEFT JOIN sph_arquivo spa
           ON (prk_tipo_arquivo = spa.frk_tipo_arquivo AND frk_registro = rRegistroFila.frk_registro)
      LEFT JOIN tab_fonte
           ON prk_fonte = frk_fonte
     WHERE cat.prk_arquivo_template = rRegistroFila.frk_arquivo_template
       AND ROWNUM = 1;
    RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem =>  pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA, v_sql_code => SQLCODE, v_sql_error => SQLERRM);
  END fBuscarArquivoTemplateFluxo;

  /**
   * Função que lista os campos preenchidos de um template, incluindo as assinaturas
   * @param v_frk_registro: Código do registro
   * @param v_frk_arquivo_template: Código do template
   **/
  FUNCTION fListarArqTemplateRegistro(v_frk_registro sph_registro.prk_registro%TYPE
                                    , v_frk_arquivo_template cfg_arquivo_template.prk_arquivo_template%TYPE) RETURN tArquivoTemplateCampoFluxo PIPELINED IS
  BEGIN
    FOR tab_temp IN(
      SELECT *
        FROM (
          SELECT prk_arquivo_template_campo
               , tip_arquivo_campo
               , catc.num_pagina
               , catc.num_posicao_x
               , catc.num_posicao_y
               , catc.num_largura
               , catc.num_altura
               , sri.val_indexador
            FROM cfg_arquivo_template_campo catc
           INNER JOIN cfg_arquivo_template cat
                 ON prk_arquivo_template = frk_arquivo_template
           INNER JOIN sph_registro_indexador sri
                 USING(frk_formulario, frk_grupo, frk_campo)
           WHERE cat.prk_arquivo_template = v_frk_arquivo_template
             AND tip_arquivo_campo = CONST_TIPTEMPL_CAMPO_FORM
             AND frk_registro = v_frk_registro
             AND val_indexador IS NOT NULL
             AND sri.ind_origem = pkg_indexacao.CONST_ORIGEM_FORM_CADASTRO
             AND catc.frk_campo_opcao IS NULL
           UNION ALL
          SELECT spra.frk_arquivo_template_campo
               , CONST_TIPTEMPL_CAMPO_ASS tip_arquivo_campo
               , spra.num_pagina
               , spra.num_posicao_x
               , spra.num_posicao_y
               , spra.num_largura
               , spra.num_altura
               , spra.cam_arquivo
            FROM sph_registro_assinatura spra
           INNER JOIN cfg_arquivo_template cat
                 ON prk_arquivo_template = frk_arquivo_template
           WHERE cat.prk_arquivo_template = v_frk_arquivo_template
             AND spra.frk_registro = v_frk_registro
             AND spra.sts_registro_assinatura = pkg_constante.CONST_ATIVO
           UNION ALL
  		    SELECT prk_arquivo_template_campo
               , tip_arquivo_campo
               , catc.num_pagina
               , catc.num_posicao_x
               , catc.num_posicao_y
               , catc.num_largura
               , catc.num_altura
               , 'X' val_indexador
            FROM cfg_arquivo_template_campo catc
           INNER JOIN cfg_arquivo_template cat
              ON prk_arquivo_template = frk_arquivo_template
           INNER JOIN sph_registro_indexador sri
              ON (sri.frk_formulario = catc.frk_formulario 
                  AND sri.frk_grupo = catc.frk_grupo
                  AND sri.frk_campo = catc.frk_campo 
                  AND sri.cod_indexador_valor = catc.frk_campo_opcao)
           WHERE cat.prk_arquivo_template = v_frk_arquivo_template
             AND tip_arquivo_campo = CONST_TIPTEMPL_CAMPO_FORM
             AND frk_registro = v_frk_registro
             AND val_indexador IS NOT NULL
             AND sri.ind_origem = pkg_indexacao.CONST_ORIGEM_FORM_CADASTRO
             AND catc.frk_campo_opcao IS NOT NULL	  
       )
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarArqTemplateRegistro;

  /**
   * Função para listar os campos do template no fluxo
   * @param v_frk_registro_fluxo: Fluxo do template
   * @param v_num_pagina: página do template
   **/
  FUNCTION fBuscarArqTemplateCampoFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                      , v_num_pagina cfg_arquivo_template_campo.num_pagina%TYPE DEFAULT NULL) RETURN tArquivoTemplateCampoFluxo PIPELINED IS
   rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
  BEGIN
    FOR tab_temp IN(
      SELECT *
        FROM TABLE(fListarArqTemplateRegistro(rRegistroFila.frk_registro, rRegistroFila.frk_arquivo_template))
       WHERE num_pagina = NVL(v_num_pagina, num_pagina)
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fBuscarArqTemplateCampoFluxo;

  /**
   * Função para listar as assintaturas pendentes no fluxo
   * @param v_frk_registro_fluxo: Código do fluxo
   **/
  FUNCTION fListarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tArquivoTemplateCampoFluxo PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
  BEGIN
    FOR tab_temp IN(
       SELECT catc.prk_arquivo_template_campo
           , tip_arquivo_campo
           , catc.num_pagina
           , catc.num_posicao_x
           , catc.num_posicao_y
           , catc.num_largura
           , catc.num_altura
           , NULL
        FROM cfg_arquivo_template_campo catc
       INNER JOIN cfg_fluxo_assinatura
             ON prk_arquivo_template_campo = frk_arquivo_template_campo
       WHERE catc.frk_arquivo_template = rRegistroFila.frk_arquivo_template
         AND frk_fluxo = rRegistroFila.frk_fluxo
         AND tip_arquivo_campo = CONST_TIPTEMPL_CAMPO_ASS
         AND NOT EXISTS(
                   SELECT NULL
                     FROM sph_registro_assinatura sra
                    WHERE sra.frk_arquivo_template_campo = catc.prk_arquivo_template_campo
                      AND sra.sts_registro_assinatura = pkg_constante.CONST_ATIVO
                      AND frk_registro = rRegistroFila.frk_registro
                 )
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarAssinaturaFluxo;

  /**
   * Função para salvar a assinatura de um arquivo
   * @param v_frk_registro_fluxo: fila da assinatura
   * @param v_rRegistroAssinatura: Record com os dados da assinatura
   **/
  FUNCTION fSalvarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                , v_rRegistroAssinatura sph_registro_assinatura%ROWTYPE) RETURN pkg_dominio.recRetorno IS
   rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
   rArquivoTemplateCampo cfg_arquivo_template_campo%ROWTYPE;
  BEGIN
    IF v_frk_registro_fluxo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -2);
    ELSIF v_rRegistroAssinatura.cam_arquivo IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -3);
    END IF;

    rArquivoTemplateCampo := fDadosArquivoTemplateCampo(v_rRegistroAssinatura.frk_arquivo_template_campo);
    IF rArquivoTemplateCampo.frk_arquivo_template IS NULL THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -4);
    END IF;

    MERGE INTO sph_registro_assinatura target
      USING(SELECT rRegistroFila.frk_registro frk_registro
                 , v_rRegistroAssinatura.frk_arquivo_template_campo frk_arquivo_template_campo
              FROM dual) base
         ON(base.frk_registro = target.frk_registro
            AND base.frk_arquivo_template_campo = target.frk_arquivo_template_campo
            AND target.sts_registro_assinatura = pkg_constante.CONST_ATIVO)
      WHEN MATCHED THEN
        UPDATE SET
          frk_registro_fluxo = v_frk_registro_fluxo,
          num_pagina  = rArquivoTemplateCampo.num_pagina,
          num_posicao_x = rArquivoTemplateCampo.num_posicao_x,
          num_posicao_y = rArquivoTemplateCampo.num_posicao_y,
          num_largura = rArquivoTemplateCampo.num_largura,
          num_altura = rArquivoTemplateCampo.num_altura,
          cam_arquivo = v_rRegistroAssinatura.cam_arquivo
      WHEN NOT MATCHED THEN
        INSERT (frk_registro, frk_registro_fluxo, frk_arquivo_template, frk_arquivo_template_campo, num_pagina, num_posicao_x, num_posicao_y, num_largura, num_altura, cam_arquivo)
          VALUES (rRegistroFila.frk_registro, v_frk_registro_fluxo, rArquivoTemplateCampo.frk_arquivo_template, v_rRegistroAssinatura.frk_arquivo_template_campo, rArquivoTemplateCampo.num_pagina, rArquivoTemplateCampo.num_posicao_x, rArquivoTemplateCampo.num_posicao_y, rArquivoTemplateCampo.num_largura, rArquivoTemplateCampo.num_altura, v_rRegistroAssinatura.cam_arquivo);
      COMMIT;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA,  pkg_constante.CONST_SUCESSO);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(v_cod_mensagem => pkg_constante.CONST_FALHA);
  END fSalvarAssinaturaFluxo;

  FUNCTION fExisteAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN BOOLEAN IS
    nTotal NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO nTotal
      FROM TABLE(fListarAssinaturaFluxo(v_frk_registro_fluxo));
    IF nTotal = 0 THEN
      RETURN FALSE;
    END IF;
    RETURN TRUE;
  END fExisteAssinaturaFluxo;

  /**
   * Finaliza uma fila de assinatura
   * @param v_frk_registro_fluxo: código da fila do registro
   * @param v_lArquivo: Lista de arquivos a serem arquivados
   **/
  FUNCTION fFinalizarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE
                                  ,  v_lArquivo PKG_DIGITALIZACAO_TMP.tArquivo DEFAULT PKG_DIGITALIZACAO_TMP.tArquivo()
                                  ,  v_tip_assinatura sph_registro_analise.tip_assinatura%TYPE) RETURN pkg_dominio.recRetorno IS

    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rUsuario tab_usuario%ROWTYPE := pkg_dominio.fDadosUsuario(v_frk_usuario => rRegistroFila.frk_usuario_analise) ;
    rArquivo sph_arquivo%ROWTYPE;
    rRetorno pkg_dominio.recRetorno;
    EXCEPT_ASS EXCEPTION;

    nIndAssinarUnica NUMBER := pkg_dominio.fValidarFluxoFuncionalidade(rRegistroFila.frk_fluxo, pkg_constante.CONST_COD_FUNC_ASSINATURA_UNIC);
  BEGIN
    IF rRegistroFila.sts_registro_fluxo <> pkg_constante.CONST_ANALISE_EM_AVALIACAO THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_REGISTRO, 1);
    END IF;

    IF nIndAssinarUnica = pkg_constante.CONST_NAO AND fExisteAssinaturaFluxo(v_frk_registro_fluxo)  THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -5);
    ELSIF (nIndAssinarUnica = pkg_constante.CONST_SIM OR v_tip_assinatura = CONST_TIPASSINAT_CERTIFICADO) AND v_lArquivo.COUNT = 0 THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -6);
    END IF;
    IF v_lArquivo.COUNT <> 0 THEN
      FOR nIndex IN 1..v_lArquivo.COUNT
      LOOP
        rArquivo := v_lArquivo(nIndex);
        rArquivo.frk_registro := rRegistroFila.frk_registro;

        UPDATE sph_arquivo spa
           SET sts_arquivo = pkg_constante.CONST_INATIVO
         WHERE frk_registro = rArquivo.frk_registro
           AND spa.frk_tipo_arquivo = rArquivo.frk_tipo_arquivo;

        rRetorno := PKG_DIGITALIZACAO_TMP.fDigitalizarArquivo(rUsuario.des_matricula, rArquivo);
        IF rRetorno.prk_retorno < 0 THEN
           RAISE EXCEPT_ASS;
        END IF;
      END LOOP;
    END IF;

    UPDATE sph_registro_analise sra
       SET tip_assinatura = v_tip_assinatura
     WHERE sra.prk_registro_fluxo = v_frk_registro_fluxo
       AND sra.frk_registro = rArquivo.frk_registro;

    pkg_registro.pConcluirFilaRegistro(v_frk_registro_fluxo);
    COMMIT;
    RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, 2);
  EXCEPTION
    WHEN EXCEPT_ASS THEN
      ROLLBACK;
      RETURN rRetorno;
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, pkg_constante.CONST_FALHA);
  END fFinalizarAssinaturaFluxo;

  /**
   * Verifica se ainda existem assinaturas ou etapas do mesmo fluxo das filas
   * @param v_frk_registro_fluxo: Código da fila atual
   **/
  FUNCTION fVerificarAssinaturaFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN pkg_dominio.recRetorno IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
  BEGIN
    IF fExisteAssinaturaFluxo(v_frk_registro_fluxo) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, -5);
    END IF;
    IF NOT pkg_registro.fExisteFilaRegistro(rRegistroFila.frk_registro, rRegistroFila.frk_fluxo, rRegistroFila.prk_registro_fluxo) THEN
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, 3);
    ELSE
      RETURN pkg_dominio.fBuscarMensagemRetorno(pkg_constante.CONST_COD_OR_ASSINATURA, 2);
    END IF;
  END fVerificarAssinaturaFluxo;

  /**
   *
   **/
  FUNCTION fListarArquivoTemplateFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tArquivoTemplateFluxo PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    --// Indica se é para assinar um arquivo digitalizado para o registro
    nIndAssinarArqDig NUMBER := pkg_dominio.fValidarFluxoFuncionalidade(rRegistroFila.frk_fluxo, pkg_constante.CONST_COD_FUNC_ASS_DIG);
  BEGIN
    FOR tab_temp IN(
            SELECT prk_arquivo_template
               , prk_tipo_arquivo
               , nom_tipo_arquivo
               , CASE nIndAssinarArqDig
                   WHEN pkg_constante.CONST_SIM THEN arq.cam_arquivo
                   ELSE cat.cam_arquivo
                 END cam_arquivo_template
               , NULL cam_arquivo
               , cod_fonte
               , num_fonte
               , cat.qtd_pagina
               , num_espessura_assinatura
               , cod_cor_assinatura
        FROM cfg_arquivo_template cat
       INNER JOIN tab_fonte
             ON frk_fonte = prk_fonte
       INNER JOIN cfg_tipo_arquivo
             ON prk_tipo_arquivo = frk_tipo_arquivo
        LEFT JOIN viw_arquivo arq
             ON (nIndAssinarArqDig = pkg_constante.CONST_SIM
                 AND arq.frk_tipo_arquivo = cat.frk_tipo_arquivo
                 AND frk_registro = rRegistroFila.frk_registro)
       INNER JOIN (
                SELECT frk_arquivo_template, srf.prk_registro_fluxo
                  FROM vw_registro_fluxo srf
                 INNER JOIN cfg_fluxo
                       ON prk_fluxo = srf.frk_fluxo
                 WHERE frk_registro = rRegistroFila.frk_registro
                   AND prk_fluxo = rRegistroFila.frk_fluxo
                   AND (sts_registro_fluxo = pkg_constante.CONST_ANALISE_FECHADO OR prk_registro_fluxo = rRegistroFila.prk_registro_fluxo)
             ) ON prk_arquivo_template = frk_arquivo_template
    )
    LOOP
      PIPE ROW(tab_temp);
    END LOOP;
  END fListarArquivoTemplateFluxo;

  /**
   * Função para retornar a lista de mensagens/destinatários a serem enviados no termino da etapa de assinatura
   * @param v_frk_registro_fluxo: Código da fila atual
   **/
  FUNCTION fListarAssinaturaEmailFluxo(v_frk_registro_fluxo sph_registro_fluxo.prk_registro_fluxo%TYPE) RETURN tDadosEmail PIPELINED IS
    rRegistroFila pkg_registro.recRegistroFluxo := pkg_registro.fDadosRegistroFluxo(v_frk_registro_fluxo);
    rFluxo cfg_fluxo%ROWTYPE := pkg_registro.fDadosFluxo(rRegistroFila.frk_fluxo);
    rRegistro sph_registro%ROWTYPE := pkg_registro.fDadosRegistro(rRegistroFila.frk_registro);
    rUsuario tab_usuario%ROWTYPE :=pkg_dominio.fDadosUsuario(v_cod_usuario => rRegistro.des_matricula_registro);
    rDadosEmail recDadosEmail;
    nPermissao NUMBER;
  BEGIN
    rDadosEmail.des_assunto := 'Assinatura de Contrato';

    nPermissao := pkg_dominio.fValidarControleAcesso(v_frk_fluxo => rRegistroFila.frk_fluxo
                                                   , v_frk_modulo => pkg_constante.CONST_MODL_ASSINATURA
                                                   , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_ASS_EMAIL_REG);
    IF nPermissao = pkg_constante.CONST_SIM THEN
      rDadosEmail.des_nome := rUsuario.nom_usuario;
      rDadosEmail.des_email := rUsuario.des_matricula;
      rDadosEmail.des_mensagem := pkg_registro.fProcessarMensagemRegistro(rRegistroFila.frk_registro, rFluxo.des_mensagem_email, rDadosEmail.des_nome, rDadosEmail.des_email );
      PIPE ROW(rDadosEmail);
    END IF;
    nPermissao := pkg_dominio.fValidarControleAcesso(v_frk_fluxo => rRegistroFila.frk_fluxo
                                                   , v_frk_modulo => pkg_constante.CONST_MODL_ASSINATURA
                                                   , v_frk_funcionalidade => pkg_constante.CONST_COD_FUNC_ASS_EMAIL_CLI);

    IF nPermissao = pkg_constante.CONST_SIM THEN
      FOR tab_temp IN(
        SELECT des_email
             , NVL(des_nome, des_email) des_nome
          FROM (
            SELECT frk_registro, val_indexador, frk_tipo
              FROM sph_registro_indexador
             INNER JOIN idx_campo
                   ON prk_campo = frk_campo
            WHERE frk_registro = rRegistroFila.frk_registro
              AND ( frk_tipo = 'email' OR cod_campo = 'nom_nome')
          )
          PIVOT (
            MAX(val_indexador)
            FOR frk_tipo IN ('email' AS des_email
                            ,'texto' AS des_nome)
          )
        WHERE des_email IS NOT NULL
      )
      LOOP
        rDadosEmail.des_nome := tab_temp.des_nome;
        rDadosEmail.des_email := tab_temp.des_email;
        rDadosEmail.des_mensagem := pkg_registro.fProcessarMensagemRegistro(rRegistroFila.frk_registro, rFluxo.des_mensagem_email, rDadosEmail.des_nome, rDadosEmail.des_email );
        PIPE ROW(rDadosEmail);
      END LOOP;

    END IF;
  END fListarAssinaturaEmailFluxo;
  
  /**
   * Função para expurgar um arquivo
   * @param v_cod_usuario: Usuário do sistema
   * @param v_frk_arquivo: Código do arquivo
   **/
 /* FUNCTION fExpurgarArquivo(v_frk_arquivo sph_arquivo.prk_arquivo%TYPE) RETURN sph_arquivo.prk_arquivo%TYPE IS
    nArquivo sph_arquivo.prk_arquivo%TYPE;
  BEGIN
    UPDATE sph_arquivo
       SET sts_arquivo = pkg_constante.CONST_ARQUIVO_EXPURGADO
     WHERE prk_arquivo = v_frk_arquivo
    RETURNING prk_arquivo INTO nArquivo;
    RETURN nArquivo;
  END fExpurgarArquivo;*/
  
END PKG_DIGITALIZACAO_TMP;
/
