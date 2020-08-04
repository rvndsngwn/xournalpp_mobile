import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xournalpp/generated/l10n.dart';
import 'package:xournalpp/layer_contents/XppStroke.dart';
import 'package:xournalpp/src/XppFile.dart';
import 'package:xournalpp/widgets/MainDrawer.dart';
import 'package:xournalpp/widgets/PointerListener.dart';
import 'package:xournalpp/widgets/XppPageStack.dart';
import 'package:xournalpp/widgets/XppPagesListView.dart';
import 'package:zoom_widget/zoom_widget.dart';

class CanvasPage extends StatefulWidget {
  CanvasPage({Key key, this.file}) : super(key: key);

  final XppFile file;

  @override
  _CanvasPageState createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  XppFile _file;
  double padding = 16;

  int currentPage = 0;

  double _currentZoom = 1;

  /// used fro parent-child communication
  final GlobalKey<XppPageStackState> _pageStackKey = GlobalKey();

  @override
  void initState() {
    _setMetadata();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 0;
    _file.pages.forEach((element) {
      if (element.pageSize.width > width) width = element.pageSize.width;
    });
    width += 2 * padding;

    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: S.of(context).doubleTapToChange,
          child: GestureDetector(
            onDoubleTap: _showTitleDialog,
            child: Text(widget.file?.title ?? S.of(context).newDocument),
          ),
        ),
      ),
      drawer: MainDrawer(),
      body: Stack(children: [
        Hero(
          tag: 'ZoomArea',
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.surface.withOpacity(.5),
                BlendMode.darken),
            child: PointerListener(
              onNewContent: (newContent) {
                print('NEW CONTENT');
                setState(() {
                  /// TODO: manage layers
                  _file.pages[currentPage].layers[0].content =
                      new List.from(_file.pages[currentPage].layers[0].content)
                        ..add(newContent);
                  _file.pages[currentPage].layers[0].content.forEach((content) {
                    if (content.runtimeType is XppStroke)
                      (content as XppStroke).points.toList().forEach((element) {
                        //print(element.x);
                        //print(element.y);
                        //print(element.width);
                      });
                  });
                });
                _pageStackKey.currentState
                    .setPageData(_file.pages[currentPage]);
              },
              child: Zoom(
                width: _file.pages[currentPage].pageSize.width * 5,
                height: _file.pages[currentPage].pageSize.height * 5,
                initZoom: _currentZoom,
                child: Center(
                  child: SizedBox(
                    width: _file.pages[currentPage].pageSize.width,
                    height: _file.pages[currentPage].pageSize.height,
                    child: Transform.scale(
                      scale: 5,
                      child: XppPageStack(
                        /// to communicate from [PointerListener] to [XppPageStack]
                        key: _pageStackKey,
                        page: _file.pages[currentPage],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Tooltip(
            message: S.of(context).notWorkingYet,
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  IconButton(
                      icon: Icon(Icons.add),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        _currentZoom += .1;
                        if (_currentZoom > 1) _currentZoom = 1;
                      }),
                  SizedBox(
                    height: 128,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        min: 0,
                        max: 1,
                        label: '${_currentZoom * 100} %',
                        value: _currentZoom,
                        onChanged: (newZoom) =>
                            setState(() => _currentZoom = newZoom),
                      ),
                    ),
                  ),
                  IconButton(
                      icon: Icon(Icons.remove),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        _currentZoom -= .1;
                        if (_currentZoom < 0) _currentZoom = 0;
                      }),
                ],
              ),
            ),
          ),
        )
      ]),
      bottomNavigationBar: BottomAppBar(
        shape: kIsWeb ? null : CircularNotchedRectangle(),
        child: Container(
            color: Theme.of(context).colorScheme.surface,
            constraints: BoxConstraints(maxHeight: 100),
            child: XppPagesListView(
              pages: _file.pages,
              onPageChange: (newPage) => setState(() => currentPage = newPage),
            )),
      ),
      floatingActionButtonLocation: kIsWeb
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).toolboxNotImplementedYet),
          )),
          tooltip: S.of(context).tools,
          child: Icon(Icons.format_paint),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _setMetadata() {
    _file = widget.file ?? XppFile.empty();
  }

  void _showTitleDialog() {
    showDialog(
        context: context,
        builder: (context) {
          TextEditingController titleController =
              TextEditingController(text: _file.title);
          return AlertDialog(
            title: Text(S.of(context).setDocumentTitle),
            content: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: TextField(
                  autofocus: true,
                  controller: titleController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: S.of(context).newTitle)),
            ),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).cancel),
              ),
              FlatButton(
                onPressed: () {
                  setState(() {
                    _file.title = titleController.text;
                  });
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).apply),
              ),
            ],
          );
        });
  }
}
