import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:latlong2/latlong.dart';
import '../models/service_model.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import 'map_picker_screen.dart';

const kPrimaryPurple = Color(0xFF6C5CE7);
const kLightPurple = Color(0xFFF3F1FE);

class BookingScreen extends StatefulWidget {
  final ServiceModel service;
  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  LatLng? _selectedLocation;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _selectedLocation?.latitude,
          initialLng: _selectedLocation?.longitude,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null) return _showError("Please select a date");
    if (_selectedTime == null) return _showError("Please select a time");
    if (_addressController.text.trim().isEmpty) return _showError("Please enter service address");
    if (_phoneController.text.trim().isEmpty) return _showError("Please enter your phone number");

    setState(() => _isSubmitting = true);

    final timeStr = _selectedTime!.format(context);

    final result = await BookingService.createBooking(
      serviceId: widget.service.id,
      appointmentDate: _selectedDate!,
      appointmentTime: timeStr,
      serviceAddress: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
    );

    if (result["sessionExpired"] == true) return;

    if (result["success"] != true) {
      setState(() => _isSubmitting = false);
      _showError(result["message"]?.toString() ?? "Booking failed");
      return;
    }

    debugPrint("createBooking -> data: ${result["data"]}");

    try {
      final data = result["data"];
      final bookingData = data is Map && data["booking"] != null ? data["booking"] : data;
      final bookingId = bookingData["id"];
      if (bookingId == null) {
        throw Exception("No booking id in response: $data");
      }

      final paymentResult = await PaymentService.createPaymentIntent(bookingId);

      if (paymentResult["sessionExpired"] == true) return;

      debugPrint("createPaymentIntent -> data: ${paymentResult["data"]}");

      if (paymentResult["success"] != true) {
        setState(() => _isSubmitting = false);
        _showError(paymentResult["message"]?.toString() ?? "Could not initiate payment");
        return;
      }

      final clientSecret = paymentResult["data"]["clientSecret"];
      if (clientSecret == null) {
        throw Exception("No clientSecret in response: ${paymentResult["data"]}");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Service Booking App",
        ),
      );

      setState(() => _isSubmitting = false);

      await Stripe.instance.presentPaymentSheet();

      await PaymentService.confirmPayment(bookingId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful! Booking confirmed.")),
        );
      }
    } on StripeException catch (e) {
      setState(() => _isSubmitting = false);
      _showError("Payment cancelled or failed: ${e.error.localizedMessage}");
    } catch (e) {
      debugPrint("Booking/payment flow error: $e");
      setState(() => _isSubmitting = false);
      _showError("Something went wrong: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: SingleChildScrollView(child: SelectableText(msg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text("Book Service", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kLightPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.service.imageUrl.isNotEmpty
                        ? Image.network(widget.service.imageUrl,
                            height: 60, width: 60, fit: BoxFit.cover)
                        : Container(height: 60, width: 60, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.service.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("by ${widget.service.providerName}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("₹${widget.service.startingPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                                color: kPrimaryPurple, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Appointment Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kLightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: kPrimaryPurple, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate == null
                          ? "Select date"
                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: TextStyle(
                          color: _selectedDate == null ? Colors.grey : Colors.black87, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Appointment Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kLightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: kPrimaryPurple, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _selectedTime == null ? "Select time" : _selectedTime!.format(context),
                      style: TextStyle(
                          color: _selectedTime == null ? Colors.grey : Colors.black87, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Service Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _field(_addressController, "Enter full address", maxLines: 2),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kLightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: kPrimaryPurple, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _selectedLocation == null
                          ? "Pin exact location on map"
                          : "Location selected ✓ (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})",
                      style: TextStyle(
                        color: _selectedLocation == null ? Colors.grey : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _field(_phoneController, "Your contact number", keyboardType: TextInputType.phone),

            const SizedBox(height: 20),
            const Text("Additional Notes (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _field(_notesController, "Any special instructions...", maxLines: 3),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _isSubmitting ? null : _confirmBooking,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: kLightPurple,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
