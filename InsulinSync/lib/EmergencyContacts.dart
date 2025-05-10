import 'package:flutter/material.dart';
import 'package:insulin_sync/EmergencyEdit.dart';
import 'package:insulin_sync/Setting.dart';
import '../models/contact_model.dart';
import '../services/user_service.dart';
import 'EmergencyAdd.dart';
import 'MainNavigation.dart';

class EmergencyContacts extends StatefulWidget {
  @override
  _EmergencyContactsState createState() => _EmergencyContactsState();
}

class _EmergencyContactsState extends State<EmergencyContacts> {
  final UserService _userService = UserService();

// Method to show Delete confirmation dialog
  void _showDeleteDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(41, 248, 77, 117),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 80,
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Are You Sure?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Clicking "Delete" Will Remove This Contact From Your Emergency Contacts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
// buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), // Make buttons the same size
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _userService.deleteContact(contact.id);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 30.0),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MainNavigation(index: 3)),
              (Route<dynamic> route) => false,
            );
          },
        ),
        elevation: 0.0,
      ),
      body: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                color: Color(0xFF023B96),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emergency_rounded,
                  color: Colors.white, size: 80.0),
            ),
            SizedBox(height: 16.0),
            Text(
              'Emergency Contacts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3.0,
                        color: Color(0x33000000),
                        offset: Offset(0.0, -1.0),
                      )
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<Contact>>(
                            stream: _userService.getContactsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text("Error loading contacts"));
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text(
                                        "There are no added contacts yet!"));
                              }

                              final contacts = snapshot
                                  .data!; ////////////////////////////////////

                              return ListView.builder(
                                itemCount: contacts.length,
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return _buildContactCard(contact);
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16.0),
                        _buildAddButton(
                            context), // Add button inside the container
                        SizedBox(height: 10.0),
                        _buildInfoText(), // Info text inside the container
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    // Determine the status label and color
    String statusLabel;
    Color statusColor;

    if (contact.status == 'pending') {
      statusLabel = 'Pending Approval';
      statusColor = Colors.grey;
    } else if (contact.status == 'rejected') {
      statusLabel = 'Rejected';
      statusColor = Theme.of(context).colorScheme.error;
    } else if (contact.status == 'ready' && contact.sendNotifications) {
      statusLabel = 'Alerts On';
      statusColor = Colors.green;
    } else if (contact.status == 'ready' && !contact.sendNotifications) {
      statusLabel = 'Alerts Off';
      statusColor = Colors.brown;
    } else {
      statusLabel = 'Unknown';
      statusColor = Colors.black;
    }

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 4.0,
              color: const Color(0x32000000),
              offset: const Offset(0.0, 2.0),
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(19.0, 15.0, 10.0, 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF023B96),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Row(
                            children: [
                              // Colored status circle
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color.fromARGB(255, 51, 51, 51), size: 25.0),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmergencyEdit(contact: contact),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 25.0),
                      onPressed: () {
                        _showDeleteDialog(context, contact);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      width: 50.0,
      height: 50.0,
      child: IconButton(
        onPressed: () async {
          final newContact = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => EmergencyAdd()));
          if (newContact != null) {
            // Firestore Stream updates automatically
          }
        },
        icon: Icon(Icons.add, color: Colors.white, size: 30.0),
        tooltip: 'Add Contact',
      ),
    );
  }

  Widget _buildInfoText() {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 30.0),
        child: Text(
          'Add emergency contacts to automatically alert them when your blood glucose readings are outside the safe range.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15.0, color: Colors.grey),
        ),
      ),
    );
  }
}
