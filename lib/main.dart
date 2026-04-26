import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const App());
const _ch = MethodChannel('com.mydev.superwidget/ch');

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Super Widget',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const Home(),
    debugShowCheckedModeBanner: false,
  );
}

class Album { final String id, name; Album(this.id, this.name); }
class AppInfo { final String name, pkg; AppInfo(this.name, this.pkg); }
class Folder {
  final String id, name; final List<String> apps;
  Folder({required this.id, required this.name, required this.apps});
  Map toJson() => {'id': id, 'name': name, 'apps': apps};
  factory Folder.from(Map j) => Folder(id: j['id'], name: j['name'], apps: List<String>.from(j['apps'] ?? []));
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Album> albums = []; List<AppInfo> apps = []; List<Folder> folders = [];
  Set<String> allowed = {};
  int nr=30,ng=30,nb=46,na=204, fr=26,fg=26,fb=46,fa=200;
  int photoCount=0; String? selAlbum;
  bool hasOverlay=false, hasNL=false, loading=true;
  String search='';

  @override
  void initState() { super.initState(); _tab=TabController(length:4,vsync:this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final d=jsonDecode(await _ch.invokeMethod('init') as String) as Map;
      setState(() {
        albums=(d['albums'] as List).map((a)=>Album(a['id'],a['name'])).toList();
        apps=(d['apps'] as List).map((a)=>AppInfo(a['n'],a['p'])).toList();
        folders=(d['folders'] as List).map((f)=>Folder.from(Map.from(f))).toList();
        allowed=Set<String>.from(d['allowed']??[]);
        nr=d['nr']??30;ng=d['ng']??30;nb=d['nb']??46;na=d['na']??204;
        fr=d['fr']??26;fg=d['fg']??26;fb=d['fb']??46;fa=d['fa']??200;
        photoCount=d['photoCount']??0; hasOverlay=d['hasOverlay']??false; hasNL=d['hasNL']??false;
        loading=false;
      });
    } catch(e){setState(()=>loading=false);}
  }

  Future<void> _saveFolder() => _ch.invokeMethod('saveFolder',{'folders':jsonEncode(folders.map((f)=>f.toJson()).toList()),'a':fa,'r':fr,'g':fg,'b':fb});
  Future<void> _saveNotif() => _ch.invokeMethod('saveNotif',{'allowed':allowed.toList(),'r':nr,'g':ng,'b':nb,'a':na});

  Widget _sl(String l,int v,Color c,Function(int) f,Future<void> Function() save)=>Row(children:[
    SizedBox(width:20,child:Text(l,style:TextStyle(color:c,fontWeight:FontWeight.bold,fontSize:12))),
    Expanded(child:Slider(value:v.toDouble(),min:0,max:255,activeColor:c,onChanged:(x){setState(()=>f(x.toInt()));save();})),
    SizedBox(width:30,child:Text('$v',style:const TextStyle(fontSize:11))),
  ]);

  Future<void> _editFolder([Folder? f]) async {
    final r=await Navigator.push<Folder>(context,MaterialPageRoute(builder:(_)=>FolderEdit(apps:apps,folder:f)));
    if(r!=null){setState((){if(f==null)folders.add(r);else{final i=folders.indexWhere((x)=>x.id==f.id);if(i>=0)folders[i]=r;}});await _saveFolder();}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Super Widget', style: TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
      actions: [
        IconButton(icon:const Icon(Icons.photo_outlined,color:Colors.white),tooltip:'Photo Widget',onPressed:()=>_ch.invokeMethod('pinPhoto')),
        IconButton(icon:const Icon(Icons.folder_outlined,color:Colors.white),tooltip:'Folder Widget',onPressed:()=>_ch.invokeMethod('pinFolder')),
        IconButton(icon:const Icon(Icons.calculate_outlined,color:Colors.white),tooltip:'Calc Widget',onPressed:()=>_ch.invokeMethod('pinCalc')),
        IconButton(icon:const Icon(Icons.refresh,color:Colors.white),onPressed:_load),
      ],
      bottom: TabBar(controller:_tab,labelColor:Colors.white,unselectedLabelColor:Colors.white38,indicatorColor:Colors.indigo,isScrollable:true,tabs:const[
        Tab(icon:Icon(Icons.photo),text:'Photos'),Tab(icon:Icon(Icons.folder),text:'Folders'),
        Tab(icon:Icon(Icons.notifications),text:'Popups'),Tab(icon:Icon(Icons.calculate),text:'Calc'),
      ]),
    ),
    body: loading?const Center(child:CircularProgressIndicator())
        :TabBarView(controller:_tab,children:[_photoTab(),_folderTab(),_notifTab(),_calcTab()]),
    floatingActionButton: ListenableBuilder(listenable:_tab,builder:(_,__)=>_tab.index==1
        ?FloatingActionButton.extended(onPressed:()=>_editFolder(),icon:const Icon(Icons.create_new_folder_outlined),label:const Text('New Folder'))
        :const SizedBox.shrink()),
  );

  Widget _photoTab()=>ListView(padding:const EdgeInsets.all(14),children:[
    Card(color:photoCount>0?const Color(0xFF1E3A1E):const Color(0xFF3A1E1E),child:ListTile(
      leading:Icon(photoCount>0?Icons.check_circle:Icons.photo_library_outlined,color:photoCount>0?Colors.green:Colors.orange,size:36),
      title:Text(photoCount>0?'$photoCount photos active':'No photos',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
      subtitle:Text(photoCount>0?'Changes every 5 min${selAlbum!=null?" · $selAlbum":""}':'Select an album below',style:const TextStyle(color:Colors.white54,fontSize:12)),
    )),
    const SizedBox(height:10),
    Row(children:[
      Expanded(child:FilledButton.icon(onPressed:()=>_ch.invokeMethod('pinPhoto'),icon:const Icon(Icons.add_to_home_screen),label:const Text('Add Widget'))),
      const SizedBox(width:8),
      Expanded(child:OutlinedButton.icon(onPressed:()async{await _ch.invokeMethod('pickPhotos');await Future.delayed(const Duration(seconds:2));_load();},icon:const Icon(Icons.add_photo_alternate),label:const Text('Add Photos'),style:OutlinedButton.styleFrom(foregroundColor:Colors.white))),
    ]),
    const SizedBox(height:14),
    const Text('Albums',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    albums.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(24),child:Column(children:[Icon(Icons.photo_library_outlined,size:56,color:Colors.grey),SizedBox(height:8),Text('No albums',style:TextStyle(color:Colors.grey))])))
    :GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:1.2),
      itemCount:albums.length,
      itemBuilder:(_,i){
        final a=albums[i]; final sel=selAlbum==a.name;
        return GestureDetector(onTap:()async{
          showDialog(context:context,barrierDismissible:false,builder:(_)=>const AlertDialog(content:Row(children:[CircularProgressIndicator(),SizedBox(width:16),Text('Loading...')])));
          try{final n=await _ch.invokeMethod('selectAlbum',{'id':a.id})as int;if(mounted)Navigator.pop(context);setState((){selAlbum=a.name;photoCount=n;});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${a.name}: $n photos'),backgroundColor:Colors.green));}catch(e){if(mounted)Navigator.pop(context);}
        },child:Card(clipBehavior:Clip.antiAlias,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10),side:BorderSide(color:sel?Colors.indigo:Colors.transparent,width:3)),child:Stack(children:[
          Container(color:const Color(0xFF1E1E3A),child:const Center(child:Icon(Icons.photo_album,size:48,color:Colors.indigo))),
          Positioned(bottom:0,left:0,right:0,child:Container(color:Colors.black54,padding:const EdgeInsets.all(6),child:Text(a.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold),maxLines:1,overflow:TextOverflow.ellipsis))),
          if(sel)Positioned(top:6,right:6,child:Container(decoration:const BoxDecoration(color:Colors.indigo,shape:BoxShape.circle),padding:const EdgeInsets.all(3),child:const Icon(Icons.check,color:Colors.white,size:14))),
        ])));
      }),
  ]);

  Widget _folderTab()=>Column(children:[
    Expanded(child:folders.isEmpty?const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.folder_open,size:64,color:Colors.grey),SizedBox(height:12),Text('No folders',style:TextStyle(color:Colors.grey)),Text('Tap + to create',style:TextStyle(color:Colors.grey))]))
    :ListView.builder(padding:const EdgeInsets.all(8),itemCount:folders.length,itemBuilder:(_,i){
      final f=folders[i];
      return Card(color:const Color(0xFF1E1E2E),child:ListTile(leading:const Icon(Icons.folder,size:36,color:Colors.indigo),title:Text(f.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),subtitle:Text('${f.apps.length} apps',style:const TextStyle(color:Colors.white54)),onTap:()=>_editFolder(f),trailing:IconButton(icon:const Icon(Icons.delete_outline,color:Colors.red),onPressed:(){setState(()=>folders.removeWhere((x)=>x.id==f.id));_saveFolder();})));
    })),
    Card(color:const Color(0xFF1E1E2E),margin:const EdgeInsets.all(8),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Widget Color',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      _sl('R',fr,Colors.red,(v)=>fr=v,_saveFolder),
      _sl('G',fg,Colors.green,(v)=>fg=v,_saveFolder),
      _sl('B',fb,Colors.blue,(v)=>fb=v,_saveFolder),
      _sl('A',fa,Colors.grey,(v)=>fa=v,_saveFolder),
      Container(height:24,decoration:BoxDecoration(color:Color.fromARGB(fa,fr,fg,fb),borderRadius:BorderRadius.circular(6),border:Border.all(color:Colors.white24))),
    ]))),
  ]);

  Widget _notifTab()=>ListView(padding:const EdgeInsets.all(14),children:[
    if(!hasOverlay||!hasNL)Card(color:Colors.red.shade900,child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
      if(!hasOverlay)ListTile(leading:const Icon(Icons.warning,color:Colors.orange),title:const Text('Overlay Permission',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),trailing:TextButton(onPressed:()=>_ch.invokeMethod('requestOverlay'),child:const Text('Grant',style:TextStyle(color:Colors.orange)))),
      if(!hasNL)ListTile(leading:const Icon(Icons.notifications_off,color:Colors.orange),title:const Text('Notification Access',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),trailing:TextButton(onPressed:()=>_ch.invokeMethod('requestNL'),child:const Text('Grant',style:TextStyle(color:Colors.orange)))),
    ]))),
    const SizedBox(height:10),
    Card(color:const Color(0xFF1E1E2E),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
      Container(width:12,height:12,decoration:BoxDecoration(color:hasOverlay&&hasNL?Colors.green:Colors.orange,shape:BoxShape.circle)),
      const SizedBox(width:10),
      Expanded(child:Text(hasOverlay&&hasNL?'Active - Popups enabled':'Inactive',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600))),
      if(hasOverlay&&hasNL)OutlinedButton(onPressed:()=>_ch.invokeMethod('testPopup'),child:const Text('Test',style:TextStyle(color:Colors.white))),
    ]))),
    const SizedBox(height:10),
    Card(color:const Color(0xFF1E1E2E),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Popup Color',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:15)),
      const SizedBox(height:8),
      _sl('R',nr,Colors.red,(v)=>nr=v,_saveNotif),
      _sl('G',ng,Colors.green,(v)=>ng=v,_saveNotif),
      _sl('B',nb,Colors.blue,(v)=>nb=v,_saveNotif),
      _sl('A',na,Colors.grey,(v)=>na=v,_saveNotif),
      const SizedBox(height:8),
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Color.fromARGB(na,nr,ng,nb),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white24)),child:const Row(children:[
        Icon(Icons.android,color:Colors.white,size:38),SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('App Name',style:TextStyle(color:Colors.white70,fontSize:11)),
          Text('Notification Title',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:14)),
          Text('Message preview',style:TextStyle(color:Colors.white,fontSize:12)),
        ])),
      ])),
      const SizedBox(height:10),
      Row(children:[
        const Text('Apps',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
        const Spacer(),
        TextButton(onPressed:(){setState(()=>allowed=apps.map((a)=>a.pkg).toSet());_saveNotif();},child:const Text('All')),
        TextButton(onPressed:(){setState(()=>allowed.clear());_saveNotif();},child:const Text('None')),
      ]),
      Text(allowed.isEmpty?'All apps':'${allowed.length} selected',style:const TextStyle(color:Colors.grey,fontSize:12)),
      const SizedBox(height:6),
      TextField(style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'Search...',hintStyle:const TextStyle(color:Colors.grey),prefixIcon:const Icon(Icons.search,color:Colors.grey),border:OutlineInputBorder(borderRadius:BorderRadius.circular(10)),filled:true,fillColor:const Color(0xFF0F0F1A)),onChanged:(v)=>setState(()=>search=v)),
      const SizedBox(height:6),
      ConstrainedBox(constraints:const BoxConstraints(maxHeight:300),child:ListView.builder(shrinkWrap:true,itemCount:apps.where((a)=>search.isEmpty||a.name.toLowerCase().contains(search.toLowerCase())).length,itemBuilder:(_,i){
        final filtered=apps.where((a)=>search.isEmpty||a.name.toLowerCase().contains(search.toLowerCase())).toList();
        final app=filtered[i];
        return CheckboxListTile(dense:true,title:Text(app.name,style:const TextStyle(color:Colors.white,fontSize:13)),subtitle:Text(app.pkg,style:const TextStyle(color:Colors.grey,fontSize:10)),value:allowed.contains(app.pkg),activeColor:Colors.indigo,onChanged:(v){setState((){if(v==true)allowed.add(app.pkg);else allowed.remove(app.pkg);});_saveNotif();});
      })),
    ]))),
  ]);

  Widget _calcTab()=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.calculate,size:72,color:Colors.indigo),
    const SizedBox(height:16),
    const Text('Calculator Widget',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:Colors.white)),
    const SizedBox(height:8),
    const Text('A fully functional calculator on your home screen',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54)),
    const SizedBox(height:24),
    FilledButton.icon(onPressed:()=>_ch.invokeMethod('pinCalc'),icon:const Icon(Icons.add_to_home_screen),label:const Text('Add to Home Screen')),
    const SizedBox(height:12),
    const Text('Long press home screen → Widgets → Super Widget → Calculator',textAlign:TextAlign.center,style:TextStyle(color:Colors.white38,fontSize:12)),
  ])));
}

class FolderEdit extends StatefulWidget {
  final List<AppInfo> apps; final Folder? folder;
  const FolderEdit({super.key,required this.apps,this.folder});
  @override State<FolderEdit> createState()=>_FolderEditState();
}

class _FolderEditState extends State<FolderEdit> {
  late TextEditingController _ctrl;
  late Set<String> _sel;
  String _q='';
  @override
  void initState(){super.initState();_ctrl=TextEditingController(text:widget.folder?.name??'');_sel=Set.from(widget.folder?.apps??[]);}
  @override
  void dispose(){_ctrl.dispose();super.dispose();}
  void _save(){final n=_ctrl.text.trim();if(n.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter folder name')));return;}Navigator.pop(context,Folder(id:widget.folder?.id??'${DateTime.now().millisecondsSinceEpoch}',name:n,apps:_sel.toList()));}
  @override
  Widget build(BuildContext context){
    final list=widget.apps.where((a)=>a.name.toLowerCase().contains(_q.toLowerCase())||a.pkg.toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      backgroundColor:const Color(0xFF0F0F1A),
      appBar:AppBar(backgroundColor:const Color(0xFF1A1A2E),title:Text(widget.folder==null?'New Folder':'Edit Folder',style:const TextStyle(color:Colors.white)),actions:[TextButton.icon(onPressed:_save,icon:const Icon(Icons.check,color:Colors.white),label:const Text('Save',style:TextStyle(color:Colors.white)))]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,12,12,6),child:TextField(controller:_ctrl,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'Folder name',labelStyle:TextStyle(color:Colors.white54),border:OutlineInputBorder(),prefixIcon:Icon(Icons.folder,color:Colors.white54)))),
        Padding(padding:const EdgeInsets.fromLTRB(12,6,12,6),child:TextField(style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'Search apps...',hintStyle:TextStyle(color:Colors.grey),prefixIcon:Icon(Icons.search,color:Colors.grey),border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_q=v))),
        Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:4),child:Row(children:[
          Text('${_sel.length} selected',style:const TextStyle(color:Colors.indigo,fontWeight:FontWeight.w600)),
          const Spacer(),
          TextButton(onPressed:()=>setState(()=>_sel=widget.apps.map((a)=>a.pkg).toSet()),child:const Text('All')),
          TextButton(onPressed:()=>setState(()=>_sel.clear()),child:const Text('Clear')),
        ])),
        const Divider(color:Colors.white12),
        Expanded(child:ListView.builder(itemCount:list.length,itemBuilder:(_,i){
          final a=list[i];
          return CheckboxListTile(dense:true,title:Text(a.name,style:const TextStyle(color:Colors.white,fontSize:13)),subtitle:Text(a.pkg,style:const TextStyle(color:Colors.grey,fontSize:10)),value:_sel.contains(a.pkg),activeColor:Colors.indigo,onChanged:(v)=>setState((){if(v==true)_sel.add(a.pkg);else _sel.remove(a.pkg);}));
        })),
      ]),
    );
  }
}
