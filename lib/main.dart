import 'package:flutter/material.dart';

import 'models/transaction.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const ControleFinanceiroApp());
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Financeiro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();

  List<Transaction> movimentacoes = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
  }

  Future<void> _carregarMovimentacoes() async {
    try {
      final movimentacoesSalvas = await _storageService.loadTransactions();

      movimentacoesSalvas.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) {
        return;
      }

      setState(() {
        movimentacoes = movimentacoesSalvas;
        carregando = false;
      });

      debugPrint('Movimentações carregadas: ${movimentacoes.length}');
    } catch (e) {
      debugPrint('Erro ao carregar movimentações: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });
    }
  }

  double get saldo {
    double total = 0;

    for (final movimentacao in movimentacoes) {
      if (movimentacao.isIncome) {
        total += movimentacao.amount;
      } else {
        total -= movimentacao.amount;
      }
    }

    return total;
  }

  Future<void> _salvarMovimentacoes() async {
    try {
      await _storageService.saveTransactions(movimentacoes);

      debugPrint('Movimentações salvas: ${movimentacoes.length}');
    } catch (e) {
      debugPrint('Erro ao salvar movimentações: $e');
    }
  }

  Future<DateTime?> _selecionarData(
    BuildContext context,
    DateTime dataInicial,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  void _abrirDialogEntrada() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();

    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Entrada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Salário',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        hintText: 'Ex: 2000,00',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        final novaData = await _selecionarData(
                          context,
                          dataSelecionada,
                        );

                        if (novaData == null) {
                          return;
                        }

                        setDialogState(() {
                          dataSelecionada = novaData;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_formatarData(dataSelecionada)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final descricao = descricaoController.text.trim();

                    final valorTexto = valorController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final valor = double.tryParse(valorTexto);

                    if (descricao.isEmpty || valor == null || valor <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe uma descrição e um valor válido.',
                          ),
                        ),
                      );

                      return;
                    }

                    final novaMovimentacao = Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description: descricao,
                      amount: valor,
                      type: 'income',
                      date: dataSelecionada,
                    );

                    setState(() {
                      movimentacoes.add(novaMovimentacao);

                      movimentacoes.sort((a, b) => b.date.compareTo(a.date));
                    });

                    await _salvarMovimentacoes();

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Entrada salva com sucesso!'),
                      ),
                    );
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirDialogSaida() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();

    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Saída'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Mercado',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        hintText: 'Ex: 150,00',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        final novaData = await _selecionarData(
                          context,
                          dataSelecionada,
                        );

                        if (novaData == null) {
                          return;
                        }

                        setDialogState(() {
                          dataSelecionada = novaData;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_formatarData(dataSelecionada)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final descricao = descricaoController.text.trim();

                    final valorTexto = valorController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final valor = double.tryParse(valorTexto);

                    if (descricao.isEmpty || valor == null || valor <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe uma descrição e um valor válido.',
                          ),
                        ),
                      );

                      return;
                    }

                    final novaMovimentacao = Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description: descricao,
                      amount: valor,
                      type: 'expense',
                      date: dataSelecionada,
                    );

                    setState(() {
                      movimentacoes.add(novaMovimentacao);

                      movimentacoes.sort((a, b) => b.date.compareTo(a.date));
                    });

                    await _salvarMovimentacoes();

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saída salva com sucesso!')),
                    );
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirDialogEditarMovimentacao(Transaction movimentacao) {
    final descricaoController = TextEditingController(
      text: movimentacao.description,
    );

    final valorController = TextEditingController(
      text: movimentacao.amount.toStringAsFixed(2).replaceAll('.', ','),
    );

    String tipoSelecionado = movimentacao.type;

    DateTime dataSelecionada = movimentacao.date;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Movimentação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Entrada'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Saída'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) {
                          return;
                        }

                        setDialogState(() {
                          tipoSelecionado = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        final novaData = await _selecionarData(
                          context,
                          dataSelecionada,
                        );

                        if (novaData == null) {
                          return;
                        }

                        setDialogState(() {
                          dataSelecionada = novaData;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_formatarData(dataSelecionada)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final descricao = descricaoController.text.trim();

                    final valorTexto = valorController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final valor = double.tryParse(valorTexto);

                    if (descricao.isEmpty || valor == null || valor <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe uma descrição e um valor válido.',
                          ),
                        ),
                      );

                      return;
                    }

                    final movimentacaoAtualizada = Transaction(
                      id: movimentacao.id,
                      description: descricao,
                      amount: valor,
                      type: tipoSelecionado,
                      date: dataSelecionada,
                    );

                    final index = movimentacoes.indexWhere(
                      (item) => item.id == movimentacao.id,
                    );

                    if (index == -1) {
                      return;
                    }

                    setState(() {
                      movimentacoes[index] = movimentacaoAtualizada;

                      movimentacoes.sort((a, b) => b.date.compareTo(a.date));
                    });

                    await _salvarMovimentacoes();

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Movimentação atualizada com sucesso!'),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatarValor(double valor) {
    return 'R${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool saldoPositivo = saldo >= 0;

    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              'Saldo atual',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 10),

            Text(
              _formatarValor(saldo),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: saldoPositivo ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _abrirDialogEntrada,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Registrar Entrada',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _abrirDialogSaida,
                icon: const Icon(Icons.remove),
                label: const Text(
                  'Registrar Saída',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Movimentações',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: movimentacoes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma movimentação registrada.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: movimentacoes.length,
                      itemBuilder: (context, index) {
                        final movimentacao = movimentacoes[index];

                        final bool ehEntrada = movimentacao.isIncome;

                        return Dismissible(
                          key: Key(movimentacao.id),

                          direction: DismissDirection.endToStart,

                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),

                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Excluir movimentação?',
                                      ),
                                      content: Text(
                                        'Deseja realmente excluir '
                                        '"${movimentacao.description}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(false);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(true);
                                          },
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                          },

                          onDismissed: (direction) async {
                            final movimentacaoRemovida = movimentacoes[index];

                            setState(() {
                              movimentacoes.removeAt(index);
                            });

                            final messenger = ScaffoldMessenger.of(context);

                            await _salvarMovimentacoes();

                            if (!mounted) {
                              return;
                            }

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${movimentacaoRemovida.description} '
                                  'foi excluída.',
                                ),
                                action: SnackBarAction(
                                  label: 'OK',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },

                          child: Card(
                            child: ListTile(
                              onTap: () {
                                _abrirDialogEditarMovimentacao(movimentacao);
                              },

                              leading: CircleAvatar(
                                child: Icon(
                                  ehEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: ehEntrada ? Colors.green : Colors.red,
                                ),
                              ),

                              title: Text(movimentacao.description),

                              subtitle: Text(_formatarData(movimentacao.date)),

                              trailing: Text(
                                '${ehEntrada ? '+' : '-'} '
                                '${_formatarValor(movimentacao.amount)}',
                                style: TextStyle(
                                  color: ehEntrada ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
