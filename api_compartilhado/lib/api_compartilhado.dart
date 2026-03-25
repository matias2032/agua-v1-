library api_compartilhado;

// 1. Exporta a configuração da API
export 'api_config.dart';

// 2. Exporta todos os Models (ajuste os nomes conforme seus arquivos reais)

export 'models/usuario_model.dart';
export 'models/resultado_autenticacao.dart';
export 'models/api_response.dart';
export 'models/produto_model.dart';
export 'models/produto_request.dart';
export 'models/disponibilidade_produto_model.dart';
export 'models/operacao_model.dart';
export 'models/preco_produto_model.dart';
 

  

// 3. Exporta todos os Services


export 'services/sessao_service.dart';
export 'services/usuario_service.dart';

export 'services/servico_autenticacao.dart';



// Services
export 'services/produto_service.dart';
 
// Exceptions
export 'exceptions/produto_exceptions.dart';

//utils
export 'utils/app_logger.dart';

//config
// export 'config/env.dart';

//providers
export 'providers/produto_provider.dart';






