import 'package:dr_ai/utils/helper/extention.dart';
import 'package:dr_ai/logic/maps/maps_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';


class MyFloatingSearchBar extends StatefulWidget {
  const MyFloatingSearchBar({
    super.key,
  });

  @override
  MyFloatingSearchBarState createState() => MyFloatingSearchBarState();
}

class MyFloatingSearchBarState extends State<MyFloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search places',
          border: OutlineInputBorder(),
        ),
        onChanged: (query) {
          final sessionToken = const Uuid().v4();
          context.bloc<MapsCubit>().getPlaceSuggetions(
              place: query.trim(), sessionToken: sessionToken);
        },
      ),
    );
  }
}
