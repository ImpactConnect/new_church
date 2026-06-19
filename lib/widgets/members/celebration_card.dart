import 'package:flutter/material.dart';
import 'package:church_mobile/models/member.dart';
import 'package:church_mobile/widgets/members/member_details_dialog.dart';

class CelebrationCard extends StatelessWidget {
  final Member member;
  final bool isBirthday;

  const CelebrationCard({
    Key? key,
    required this.member,
    required this.isBirthday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => MemberDetailsDialog(member: member),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage:
                member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
            child: member.imageUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(member.name),
          subtitle:
              Text(isBirthday ? 'Birthday Today!' : 'Wedding Anniversary'),
          trailing: Icon(
            isBirthday ? Icons.cake : Icons.celebration,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
