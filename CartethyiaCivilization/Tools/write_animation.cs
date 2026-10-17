// Native curve layout independently checked against LSLib's DaK32fC32f and
// the installed Firaxis runtime. All writes are to a newly saved animation file.
using System;using System.IO;using System.Linq;using System.Reflection;
using System.Runtime.InteropServices;using System.Web.Script.Serialization;
using Firaxis.Framework;using Firaxis.Framework.Granny;
public class AnimData { public float duration; public float[] times; public TrackData[] tracks; }
public class TrackData { public string name; public float[] position; public float[] orientation; public float[] scale; }
class WriteAnimation {
 static IntPtr Alloc(int n){var p=Marshal.AllocHGlobal(n);Marshal.Copy(new byte[n],0,p,n);return p;}
 static IntPtr Floats(float[] a){var p=Alloc(a.Length*4);Marshal.Copy(a,0,p,a.Length);return p;}
 static unsafe IntPtr Ptr(object o,string field){return (IntPtr)Pointer.Unbox(o.GetType().GetField(field,BindingFlags.Instance|BindingFlags.NonPublic).GetValue(o));}
 static void Def(IntPtr p,int i,int type,string name,IntPtr reference,int width){p+=32*i;Marshal.WriteInt32(p,type);Marshal.WriteIntPtr(p,4,Marshal.StringToHGlobalAnsi(name));Marshal.WriteIntPtr(p,8,reference);Marshal.WriteInt32(p,12,width);}
 static IntPtr CurveType(){var head=Alloc(96);Def(head,0,12,"Format",IntPtr.Zero,0);Def(head,1,12,"Degree",IntPtr.Zero,0);var real=Alloc(64);Def(real,0,10,"Real32",IntPtr.Zero,0);var type=Alloc(160);Def(type,0,1,"CurveDataHeader_DaK32fC32f",head,0);Def(type,1,15,"Padding",IntPtr.Zero,0);Def(type,2,3,"Knots",real,0);Def(type,3,3,"Controls",real,0);return type;}
 static void Replace(IGrannyCurve curve,IntPtr type,float[] times,float[] values,int dim){
  if(values.Length!=times.Length*dim||values.Any(x=>float.IsNaN(x)||float.IsInfinity(x)))throw new Exception("Invalid curve samples");
  var data=Alloc(20);Marshal.WriteByte(data,0,1);Marshal.WriteByte(data,1,1);Marshal.WriteInt32(data,4,times.Length);Marshal.WriteIntPtr(data,8,Floats(times));Marshal.WriteInt32(data,12,values.Length);Marshal.WriteIntPtr(data,16,Floats(values));
  var ptr=Ptr(curve,"m_pkCurve");Marshal.WriteIntPtr(ptr,type);Marshal.WriteIntPtr(ptr,4,data);
 }
 [STAThread] static int Main(string[] args){try{
  if(args.Length!=4)throw new Exception("Usage: write_animation strings.gsd template.gr2 curves.json output.gr2");
  Context.Add(new VirtualSpace());var c=new GrannyContext();Context.Add(c);Context.Add(new ProjectConfig());c.LoadStringDatabase(args[0]);
  var input=c.LoadGrannyFile(args[1]);var a=input.Animations.Single();var d=new JavaScriptSerializer{MaxJsonLength=int.MaxValue}.Deserialize<AnimData>(File.ReadAllText(args[2]));
  if(d.times.Length<2||d.times[0]!=0||Math.Abs(d.times.Last()-d.duration)>0.001)throw new Exception("Invalid timeline");
  for(int i=1;i<d.times.Length;i++)if(d.times[i]<=d.times[i-1])throw new Exception("Unordered timeline");
  var tracks=a.TrackGroups.Single().TransformTracks;var type=CurveType();
  if(d.tracks.Length!=tracks.Count)throw new Exception("Incomplete tracks");
  foreach(var t in tracks){var v=d.tracks.Single(x=>x.name==t.Name);Replace(t.PositionCurve,type,d.times,v.position,3);Replace(t.OrientationCurve,type,d.times,v.orientation,4);Replace(t.ScaleShearCurve,type,d.times,v.scale,9);}
  a.Name=Path.GetFileNameWithoutExtension(args[3]);var ap=Ptr(a,"m_pkAnimation");Marshal.Copy(new[]{d.duration,1f/30f,1f},0,ap+4,3);
  var output=c.CreateEmptyGrannyFile(Path.GetFullPath(args[3]));output.AddAnimationReference(a);output.AddArtToolAndExporterReference(input);output.Source="Tool";output.Save();Console.WriteLine("SAVED "+args[3]+" frames "+d.times.Length);return 0;
 }catch(Exception e){Console.Error.WriteLine(e);return 1;}}
}
