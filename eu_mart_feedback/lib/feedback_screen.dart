import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _receiptController = TextEditingController();
  final _messageController = TextEditingController();

  String _feedbackType = 'Service';
  int _rating = 0;
  bool _submitting = false;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('customer_feedback').add({
        'customerName': _nameController.text.trim(),
        'contactInfo': _contactController.text.trim(),
        'receiptNumber': _receiptController.text.trim(),
        'feedbackType': _feedbackType,
        'rating': _rating,
        'message': _messageController.text.trim(),
        'status': 'Pending',
        'source': 'Receipt QR Code',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 10),
                Expanded(child: Text('Feedback Submitted')),
              ],
            ),
            content: const Text(
              'Thank you for sharing your experience with EÜ MART.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      _formKey.currentState!.reset();
      _nameController.clear();
      _contactController.clear();
      _receiptController.clear();
      _messageController.clear();

      setState(() {
        _feedbackType = 'Service';
        _rating = 0;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit feedback: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _ratingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;

        return IconButton(
          onPressed: _submitting
              ? null
              : () {
                  setState(() {
                    _rating = starNumber;
                  });
                },
          icon: Icon(
            starNumber <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 38,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/eu_mart_logo.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store,
                            size: 80,
                            color: Color(0xFF1565C0),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'EÜ MART Customer Feedback',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us about your shopping experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 28),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number or Email (Optional)',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _receiptController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Number (Optional)',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Overall Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _ratingStars(),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _feedbackType,
                        decoration: const InputDecoration(
                          labelText: 'Feedback Type',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Service',
                            child: Text('Service'),
                          ),
                          DropdownMenuItem(
                            value: 'Product',
                            child: Text('Product'),
                          ),
                          DropdownMenuItem(
                            value: 'Suggestion',
                            child: Text('Suggestion'),
                          ),
                          DropdownMenuItem(
                            value: 'Complaint',
                            child: Text('Complaint'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _feedbackType = value ?? 'Service';
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _messageController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Feedback Message',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.message_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your feedback.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _submitting ? 'SUBMITTING...' : 'SUBMIT FEEDBACK',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'No login is required. Your feedback will be sent directly to EÜ MART.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _receiptController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
