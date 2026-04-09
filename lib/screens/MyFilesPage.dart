import 'package:flutter/material.dart';
import 'package:untitled3333333/widgets/MyFile.dart';
import 'package:untitled3333333/widgets/FileSelectionDialog.dart';
import 'package:untitled3333333/widgets/FileSortDialog.dart';

class MyFilesPage extends StatefulWidget {
  final Map<String, String> files;
  const MyFilesPage({super.key, required this.files});

  @override
  createState() => MyFilesPageState();
}

class MyFilesPageState extends State<MyFilesPage> {

  /*
  List<String> files = List.filled(8, "bobs", growable: true);
  List<String> extensions = List.filled(8, ".jpg", growable: true);
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leadingWidth: 56*2,
          leading: Row(children: [const SizedBox(width: 5),
            IconButton(
              padding: EdgeInsets.only(left:10),
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {Navigator.pop(context);},
              ),
            const SizedBox(width: 5),
            IconButton(
              icon: Icon(Icons.sync_alt),
              onPressed: () async {
                final SortType? sortType = await showDialog<SortType>(
                  context: context,
                  builder: (context) => FileSortDialog(),
                );
                if (sortType != null) {
                  setState(() {

                  });
                }
              },
            ),
            ],
          ),
            actions: [
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {},
              ),
              const SizedBox(width: 5,)
            ],
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.primary,
            ),

        body: ListView.builder(
            padding: EdgeInsets.all(14),
            itemCount: widget.files.length,
            itemBuilder: (context, index) {
              final fileName = widget.files.keys.elementAt(index);
              final fileExt = widget.files.values.elementAt(index);
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: MyFile(fileName, fileExt),
              );
            }),

        floatingActionButton: FloatingActionButton(
          onPressed: () async {},
          tooltip: 'Добавить файл',
          child: const Icon(Icons.upload),
        )
    );
  }
}
