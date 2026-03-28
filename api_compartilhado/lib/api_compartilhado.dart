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
export 'models/estoque_model.dart';
export 'models/movimento_estoque_model.dart';
export 'models/pedido_request.dart';
export 'models/pedido_model.dart';
 
// 3. Exporta todos os Services
export 'services/sessao_service.dart';
export 'services/usuario_service.dart';
export 'services/servico_autenticacao.dart';
export 'services/pedido_service.dart';
export 'services/estoque_service.dart';
export 'services/produto_service.dart';
export 'services/impressora_service.dart';
export 'services/pdf_service.dart';

// 4. Exceptions
export 'exceptions/produto_exceptions.dart';

// 5. Utils
export 'utils/app_logger.dart';

// 6. Providers
export 'providers/produto_provider.dart';
export 'providers/estoque_provider.dart';
export 'providers/pedido_provider.dart';








