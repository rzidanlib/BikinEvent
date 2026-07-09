import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/checkout_service.dart';
import '../widgets/ticket_list_card.dart';
import '../widgets/ticket_detail_modal.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final _checkoutService = CheckoutService();
  List<MyTicketItem> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rawData = await _checkoutService.getMyTickets();
      setState(() {
        _tickets = rawData.map((json) => MyTicketItem.fromJson(json)).toList();
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Saya')),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _isLoading
            ? const LoadingView()
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadTickets)
            : _tickets.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  EmptyView(
                    message: 'Kamu belum punya tiket',
                    icon: Icons.confirmation_number_outlined,
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final ticket = _tickets[index];
                  return TicketListCard(
                    ticket: ticket,
                    onTap: () => showTicketDetailModal(context, ticket),
                  );
                },
              ),
      ),
    );
  }
}
