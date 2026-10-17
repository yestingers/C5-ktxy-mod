// Read-only diagnostic host for the already installed Firaxis/Nexus Buddy libraries.
using System;
using System.Reflection;
using Firaxis.Framework;
using Firaxis.Framework.Granny;
class InspectGr2 {
 static string HashFile(string path) {
  using(var sha=System.Security.Cryptography.SHA256.Create())
   return BitConverter.ToString(sha.ComputeHash(System.IO.File.ReadAllBytes(path))).Replace("-","").ToLowerInvariant();
 }
 [STAThread, System.Runtime.ExceptionServices.HandleProcessCorruptedStateExceptions] static int Main(string[] args) {
  try {
   if(args[0]=="reflect") {
    foreach(var t in typeof(Available).Assembly.GetTypes()) if(t.Name.Contains("Virtual") || t.Name=="Available" || t.Name.Contains("Context") || t.Name.Contains("Space")) {
     Console.WriteLine("TYPE "+t.FullName);
     foreach(var p in t.GetConstructors()) Console.WriteLine(p);
     foreach(var p in t.GetMethods(BindingFlags.Public|BindingFlags.Static|BindingFlags.Instance|BindingFlags.DeclaredOnly)) Console.WriteLine(p);
    }
    return 0;
   }
   Console.WriteLine("STARTUP");
   // Diagnostic: initialize only the required Granny context.
   Context.Add(new VirtualSpace());
   Console.WriteLine("CONTEXT");
   var context = new GrannyContext();
   Context.Add(context); Context.Add(new ProjectConfig());
   var strings=System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"..","reference","unitmodels_stringdatabase.gsd");
   if(System.IO.File.Exists(strings)) context.LoadStringDatabase(strings);
   Console.WriteLine("LOAD");
   var file = context.LoadGrannyFile(args[0]);
   Console.WriteLine("FILE "+file.Filename);
   Console.WriteLine("MODELS "+file.Models.Count+" MESHES "+file.Meshes.Count+" MATERIALS "+file.Materials.Count+" ANIMATIONS "+file.Animations.Count);
   foreach(var model in file.Models) {
    Console.WriteLine("MODEL "+model.Name+" BONES "+model.Skeleton.Bones.Count+" MESHES "+model.MeshBindings.Count);
    if(model.Skeleton.Bones.Count<100) foreach(var bone in model.Skeleton.Bones) Console.WriteLine("BONE "+bone.Name+" PARENT "+bone.ParentIndex+" POS "+string.Join(",",bone.LocalTransform.Position));
   }
   foreach(var material in file.Materials) {
    Console.WriteLine("MATERIAL "+material.Name);
    foreach(var p in typeof(IGrannyMaterial).GetProperties()) Console.WriteLine("PROP "+p.Name+" "+p.PropertyType);
   }
   foreach(var anim in file.Animations) Console.WriteLine("ANIMATION "+anim.Name+" DURATION "+anim.Duration);
   if(args.Length>1 && args[1]=="br2") {
    var asm=Assembly.LoadFrom(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"NexusBuddy2.exe"));
    asm.GetType("NexusBuddy.FileOps.BR2Importer").GetMethod("br2Export",BindingFlags.Static|BindingFlags.Public).Invoke(null,new object[]{file,0});
   }
   if(args.Length>2 && args[1]=="na2") {
    var asm=Assembly.LoadFrom(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"NexusBuddy2.exe"));
    var anim=context.LoadGrannyFile(args[2]).Animations[0];
    var dest=System.IO.Path.ChangeExtension(args[2],"na2");
    // Serialized float durations such as 25/30 can fall just below the frame.
    int count=(int)Math.Floor((double)anim.Duration*30+0.0001)+1;
    using(var writer=new System.IO.StreamWriter(dest)) {
     writer.WriteLine("// Firaxis SampleBone; retry each frame without dropping timestamps");
     writer.WriteLine("FrameSets: 1\nFrameCount: "+count+"\nFirstFrame: 1\nLastFrame: "+count+"\nFPS: 30\nBones: "+file.Models[0].Skeleton.Bones.Count);
     foreach(var bone in file.Models[0].Skeleton.Bones) {
      writer.WriteLine(bone.Name);
      for(int i=0;i<count;i++) {
       float[] matrix=null;
       for(int retry=0;retry<100 && matrix==null;retry++) {try {matrix=anim.SampleBone(file.Models[0],bone.Name,i/30f);}catch(Exception) {if(retry==99)throw;}}
       writer.WriteLine(string.Join(" ",Array.ConvertAll(matrix,x=>x.ToString("F8",System.Globalization.CultureInfo.InvariantCulture))));
      }
     }
    }
    System.IO.File.WriteAllText(dest+".source.json","{\"animation_sha256\":\""+HashFile(args[2])+"\",\"model_sha256\":\""+HashFile(args[0])+"\",\"sample_sha256\":\""+HashFile(dest)+"\"}");
    Console.WriteLine("EXPORTED "+dest);
   }
   return 0;
  } catch(Exception e) {Console.Error.WriteLine(e);return 1;}
 }
}
