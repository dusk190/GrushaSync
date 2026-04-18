import 'dart:io';
import 'package:flutter/material.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:untitled3333333/widgets/LeaveFilesDialog.dart';
import 'package:untitled3333333/widgets/MyFile.dart';
import 'package:untitled3333333/widgets/FileSortDialog.dart';
import 'package:file_picker/file_picker.dart';

class MyFilesPage extends StatefulWidget {
  final String _devicename;
  const MyFilesPage(this._devicename, {super.key});


  @override
  createState() => MyFilesPageState();
}

class MyFilesPageState extends State<MyFilesPage> {
  List<PlatformFile> files = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leadingWidth: 56*2,
          leading: Row(children: [const SizedBox(width: 5),
            IconButton(
              padding: EdgeInsets.only(left:10),
              icon: Icon(Icons.arrow_back_ios),
              onPressed: files.isEmpty ? () {Navigator.pop(context);} : () async {
                  final bool? sortType = await showDialog<bool>(
                    context: context,
                    builder: (context) => LeaveFilesDialog(),
                  );
                  if (sortType == true) {
                    Navigator.pop(context);
                  }
                },
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
            title: Text(widget._devicename),
            actions: [
              IconButton(
                icon: Icon(Icons.send),
                onPressed: getFiles,
                //onPressed: () {},
              ),
              const SizedBox(width: 5,)
            ],
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                height: 2,
              ),)
        ),

        body: ListView.builder(
            padding: EdgeInsets.all(14),
            itemCount: files.length,
            itemBuilder: (context, index) {
              String? ex = files[index].extension;
              final fileExt = ".${ex ?? "-"}";
              final fileName = files[index].name.replaceFirst('$fileExt', '');
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: MyFile(fileName, fileExt),
              );
            }),

        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.pickFiles(
              allowMultiple: true,
            );

            if (result != null) {
              for (PlatformFile fileData in result.files) {
                String? path = fileData.path;

                if (path != null) {
                  //File file = File(path);
                  setState(() {
                    files.add(fileData);
                  });
                }
              }
            }
          },
          tooltip: 'Добавить файлы',
          child: const Icon(Icons.upload),
        )
    );
  }
  // пусть тут пока полежит
  void getFiles() async {
    Directory? dir = await getDownloadDirectory();
    print(dir);
    // дальше код обращения к беку??
  }

}
